get_contrasts <- function(model,
                          newdata,
                          type,
                          variables,
                          original,
                          lo,
                          hi,
                          wts = NULL,
                          marginalmeans,
                          by = NULL,
                          hypothesis = NULL,
                          cross = FALSE,
                          verbose = TRUE,
                          deltamethod = FALSE,
                          ...) {

    settings_init()

    # some predict() methods need data frames and will convert data.tables
    # internally, which can be very expensive if done many times. we do it once
    # here.
    setDF(lo)
    setDF(hi)
    setDF(original)

    # brms models need to be combined to use a single seed when sample_new_levels="gaussian"
    if (inherits(model, "brmsfit")) {

        if (!"rowid" %in% colnames(lo)) {
            lo$rowid <- hi$rowid <- seq_len(nrow(lo))
        }

        both <- rbindlist(list(lo, hi))

        pred_both <- myTryCatch(get_predict(
            model,
            type = type,
            vcov = FALSE,
            newdata = both,
            ...))[["value"]]

        idx_lo <- 1:(nrow(pred_both) / 2)
        idx_hi <- (nrow(pred_both) / 2 + 1):nrow(pred_both)
        pred_lo <- pred_both[idx_lo, , drop = FALSE]
        pred_hi <- pred_both[idx_hi, , drop = FALSE]
        attr(pred_lo, "posterior_draws") <- attr(pred_both, "posterior_draws")[idx_lo, , drop = FALSE]
        attr(pred_hi, "posterior_draws") <- attr(pred_both, "posterior_draws")[idx_hi, , drop = FALSE]

    } else {
        pred_lo <- myTryCatch(get_predict(
            model,
            type = type,
            vcov = FALSE,
            newdata = lo,
            ...))[["value"]]

        pred_hi <- myTryCatch(get_predict(
            model,
            type = type,
            vcov = FALSE,
            newdata = hi,
            ...))[["value"]]
    }

    # predict() takes up 2/3 of the wall time. This call is only useful when we
    # compute elasticities, or for the main estimate, not for standard errors,
    # so we probably save 1/3 of that 2/3.
    elasticities <- c(
        # "dydx", # useless and expensive
        "eyex",
        "eydx",
        "dyex",
        # "dydxavg", # useless and expensive
        "eyexavg",
        "eydxavg",
        "dyexavg")
    fun <- function(x) {
        out <- checkmate::check_choice(x$transform_pre, choices = elasticities)
        isTRUE(out)
    }
    tmp <- Filter(fun, variables)
    if (!isTRUE(deltamethod) || length(tmp) > 0) {
        pred_or <- myTryCatch(get_predict(
            model,
            type = type,
            vcov = FALSE,
            newdata = original,
            ...))[["value"]]
    } else {
        pred_or <- NULL
    }

    # lots of indexing later requires a data.table
    setDT(original)

    if (!inherits(pred_hi, "data.frame") || !inherits(pred_lo, "data.frame") || !inherits(pred_or, c("data.frame", "NULL"))) {
        insight::format_error("Unable to compute predicted values with this model. You can try to supply a different dataset to the `newdata` argument. If this does not work, you can file a report on the Github Issue Tracker: https://github.com/vincentarelbundock/marginaleffects/issues")
    }

    # output data.frame
    out <- pred_lo
    setDT(out)

    # univariate outcome:
    # original is the "composite" data that we constructed by binding terms and
    # compute predictions. It includes a term column, which we need to
    # replicate for each group.
    out[, "marginaleffects_eps" := NA_real_] # default (probably almost always overwritten)
    out[, "marginaleffects_wts_internal" := NA_real_] # default (probably almost always overwritten)
    mult <- nrow(out) / nrow(original)
    regex <- "^term$|^group$|^contrast|^marginaleffects_eps$|^marginaleffects_wts_internal$"
    if (isTRUE(mult == 1)) {
        for (v in grep(regex, colnames(original), value = TRUE)) {
            out[, (v) := original[[v]]]
        }

    # group or multivariate outcomes
    } else if (isTRUE(mult > 1)) {
        for (v in grep(regex, colnames(original), value = TRUE)) {
            out[, (v) := rep(original[[v]], times = mult)]
        }

    # cross-contrasts or weird cases
    } else {
        out <- merge(out, newdata, by = "rowid", all.x = TRUE)
        if (isTRUE(nrow(out) == nrow(lo))) {
            tmp <- data.table(lo)[, .SD, .SDcols = patterns("^contrast|marginaleffects_eps|marginaleffects_wts_internal")]
            out <- cbind(out, tmp)
            idx <- c("rowid", grep("^contrast", colnames(out), value = TRUE), colnames(out))
            idx <- unique(idx)
            out <- out[, ..idx]
        }
    }

    if (!"term" %in% colnames(out)) {
        out[, "term" := "cross"]
    }


    # by
    if (isTRUE(checkmate::check_data_frame(by))) {
        bycols <- "by"
        setDT(by)
        tmp <- setdiff(intersect(colnames(out), colnames(by)), "by")

        if (length(tmp) == 0) {
            if (all(colnames(by) %in% c("by", colnames(newdata)))) {
                nd <- c("rowid", setdiff(colnames(by), "by"))
                nd <- newdata[, nd, drop = FALSE]
                out <- merge(out, nd, by = "rowid")
                tmp <- setdiff(intersect(colnames(out), colnames(by)), "by")
            } else {
                insight::format_error("The column in `by` must be present in `newdata`.")
            }
        }

        # harmonize column types
        for (v in colnames(by)) {
            if (isTRUE(is.character(out[[v]])) && isTRUE(is.numeric(by[[v]]))) {
                by[[v]] <- as.character(by[[v]])
            } else if (isTRUE(is.numeric(out[[v]])) && isTRUE(is.character(by[[v]]))) {
                by[[v]] <- as.numeric(by[[v]])
            }
        }
        out[by, by := by, on = tmp]
        by <- "by"

    } else if (isTRUE(checkmate::check_character(by))) {
        regex <- "^term$|^contrast_?|^group$"
        by <- c(by, grep(regex, colnames(out), value = TRUE))
        by <- unique(by)
    }

    # transform_pre function could be different for different terms
    # sanitize_variables() ensures all functions are identical when there are cross
    fun_list <- sapply(names(variables), function(x) variables[[x]][["function"]])
    fun_list[["cross"]] <- fun_list[[1]]

    # elasticity requires the original (properly aligned) predictor values
    # this will discard factor variables which are duplicated, so in principle
    # it should be the "correct" size
    elasticities <- Filter(
        function(x) is.character(x$transform_pre) && x$transform_pre %in% elasticities,
        variables)
    elasticities <- lapply(elasticities, function(x) x$name)
    if (length(elasticities) > 0) {
        for (v in names(elasticities)) {
            idx2 <- c("rowid", "term", "type", "group", grep("^contrast", colnames(out), value = TRUE))
            idx2 <- intersect(idx2, colnames(out))
            # discard other terms to get right length vector
            idx2 <- out[term == v, ..idx2]
            # original is NULL when cross=TRUE
            if (!is.null(original)) {
                idx1 <- c(v, "rowid", "rowidcf", "term", "type", "group", grep("^contrast", colnames(original), value = TRUE))
                idx1 <- intersect(idx1, colnames(original))
                idx1 <- original[, ..idx1]
                setnames(idx1, old = v, new = "elast")
                on_cols <- intersect(colnames(idx1), colnames(idx2))
                idx2[idx1, elast := elast, on = on_cols]
            }
            elasticities[[v]] <- idx2$elast
        }
    }

    draws <- attr(pred_lo, "posterior_draws")

    # frequentist
    if (is.null(draws)) {
        draws_lo <- draws_hi <- draws_or <- NULL

    # bayes
    } else {
        draws_lo <- attr(pred_lo, "posterior_draws")
        draws_hi <- attr(pred_hi, "posterior_draws")
        draws_or <- attr(pred_or, "posterior_draws")
    }

    out[, predicted_lo := pred_lo[["estimate"]]]
    out[, predicted_hi := pred_hi[["estimate"]]]

    if (!is.null(pred_or)) {
        out[, predicted := pred_or[["estimate"]]]
    } else {
        out[, predicted := NA_real_]
    }

    idx <- grep("^contrast|^group$|^term$|^type$|^transform_pre_idx$", colnames(out), value = TRUE)

    # when `by` is a character vector, we sometimes modify the transform_pre
    # function on the fly to use the `avg` version.  this is important and
    # convenient because some of the statistics are non-collapsible, so we can't
    # average them at the very end.  when `by` is a data frame, we do this only
    # at the very end.
    # TODO: What is the UI for this? Doesn't make sense to have different functions.
    if (isTRUE(checkmate::check_character(by))) {
        tmp <- intersect(colnames(newdata), c(by, colnames(out)))
        if (length(tmp) > 1) {
            tmp <- subset(newdata, select = tmp)
            out <- merge(out, tmp, all.x = TRUE, sort = FALSE)
            idx <- unique(c(idx, by))
        }
    }

    # we feed these columns to safefun(), even if they are useless for categoricals
    if (!"marginaleffects_eps" %in% colnames(out)) out[, "marginaleffects_eps" := NA]
    if (!"marginaleffects_wts_internal" %in% colnames(out))  out[, "marginaleffects_wts_internal" := NA]

    if (isTRUE(marginalmeans)) {
        out <- out[, .(
            predicted_lo = mean(predicted_lo),
            predicted_hi = mean(predicted_hi),
            predicted = mean(predicted),
            marginaleffects_eps = mean(marginaleffects_eps),
            marginaleffects_wts_internal = mean(marginaleffects_wts_internal)),
        by = idx]
    }

    # safe version of transform_pre
    # unknown arguments
    # singleton vs vector
    # different terms use different functions
    safefun <- function(hi, lo, y, n, term, cross, eps, wts) {
        # when cross=TRUE, sanitize_transform_pre enforces a single function
        if (isTRUE(cross)) {
            fun <- fun_list[[1]]
        } else {
            fun <- fun_list[[term[1]]]
        }
        args <- list(
            "hi" = hi,
            "lo" = lo,
            "y" = y,
            "eps" = eps,
            "w" = wts,
            "x" = elasticities[[term[1]]])
        args <- args[names(args) %in% names(formals(fun))]
        con <- try(do.call("fun", args), silent = TRUE)
        if (!isTRUE(checkmate::check_numeric(con, len = n)) && !isTRUE(checkmate::check_numeric(con, len = 1))) {
            msg <- sprintf("The function supplied to the `transform_pre` argument must accept two numeric vectors of predicted probabilities of length %s, and return a single numeric value or a numeric vector of length %s, with no missing value.", n, n) #nolint
            insight::format_error(msg)
        }
        if (length(con) == 1) {
            con <- c(con, rep(NA_real_, length(hi) - 1))
            settings_set("marginaleffects_safefun_return1", TRUE)
        }
        return(con)
    }

    # drop missing otherwise get_averages() fails when trying to take a simple mean
    idx_na <- !is.na(out$predicted_lo)
    out <- out[idx_na, , drop = FALSE]

    # bayesian
    if (!is.null(draws)) {
        # TODO: performance is probably terrrrrible here, but splitting is
        # tricky because grouping rows are not always contiguous, and the order
        # of rows is **extremely** important because draws don't have the
        # indices that would allow us to align them back with `out`
        draws <- draws[idx_na, , drop = FALSE]

        if (isTRUE(checkmate::check_character(by, min.len = 1))) {
            by_idx <- subset(out, select = intersect(by, colnames(out)))
            by_idx <- apply(by_idx, 1, paste, collapse = "|")
        } else {
            by_idx <- out$term
        }

        # loop over columns (draws) and term names because different terms could use different functions 
        for (tn in unique(by_idx)) {
            for (i in seq_len(ncol(draws))) {
                idx <- by_idx == tn
                draws[idx, i] <- safefun(
                    hi = draws_hi[idx, i],
                    lo = draws_lo[idx, i],
                    y = draws_or[idx, i],
                    n = sum(idx),
                    term = out$term[idx],
                    cross = cross,
                    wts = out$marginaleffects_wts_internal[idx],
                    eps = out$marginaleffects_eps[idx])
            }
        }

        # function returns unique value
        idx <- !is.na(draws[, 1])
        draws <- draws[idx, , drop = FALSE]

        # if transform_pre returns a single value, then we padded with NA. That
        # also means we don't want `rowid` otherwise we will merge and have
        # useless duplicates.
        if (any(!idx)) {
            if (settings_equal("marginaleffects_safefun_return1", TRUE)) {
                out[, "rowid" := NULL]
            }
            out <- out[idx, , drop = FALSE]
        }

        FUN_CENTER <- getOption("marginaleffects_posterior_center", default = stats::median)
        out[, "estimate" := apply(draws, 1, FUN_CENTER)]

    # frequentist
    } else {
        # We want to write the "estimate" column in-place because it safer
        # than group-merge; there were several bugs related to this in the past.
        # safefun() returns 1 value and NAs when the function retunrs a
        # singleton.
        idx <- intersect(idx, colnames(out))
        out[, "estimate" := safefun(
            hi = predicted_hi,
            lo = predicted_lo,
            y = predicted,
            n = .N,
            term = term,
            cross = cross,
            wts = marginaleffects_wts_internal,
            eps = marginaleffects_eps),
        by = idx]

        # if transform_pre returns a single value, then we padded with NA. That
        # also means we don't want `rowid` otherwise we will merge and have
        # useless duplicates.
        if (any(is.na(out$estimate))) {
            if (settings_equal("marginaleffects_safefun_return1", TRUE)) {
                out[, "rowid" := NULL]
            }
        }
        out <- out[!is.na(estimate)]
    }


    # averaging by groups
    # sometimes this work is already done
    # if `by` is a column name, then we have merged-in a data frame earlier
    if (nrow(out) > 1 && !(is.null(by) || isFALSE(by)) &&
        any(grepl("^contrast[_]?", colnames(out))) &&
        !any(grepl("^mean\\(", out$contrast))) {
        out <- get_by(
            out,
            draws = draws,
            newdata = newdata,
            by = by,
            verbose = verbose)

        draws <- attr(out, "posterior_draws")
    }

    # issue #531: uncertainty estimates from get_predict() sometimes get retained, but they are not overwritten later by get_ci()
    # drop by reference for speed
    bad <- intersect(
        colnames(out),
        c("conf.low", "conf.high", "std.error", "statistic", "p.value"))
    if (length(bad) > 0) {
        out[, (bad) := NULL]
    }

    # before get_hypothesis
    attr(out, "posterior_draws") <- draws

    # hypothesis tests using the delta method
    out <- get_hypothesis(out, hypothesis, by = by)

    # reset settings
    settings_rm("marginaleffects_safefun_return1")

    # output
    attr(out, "original") <- original
    return(out)
}