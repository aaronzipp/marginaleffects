#' Marginal Means
#'
#' @description
#' Marginal means are adjusted predictions, averaged across a grid of categorical predictors,
#' holding other numeric predictors at their means. To learn more, read the marginal means vignette, visit the
#' package website, or scroll down this page for a full list of vignettes:
#' 
#' * <https://vincentarelbundock.github.io/marginaleffects/articles/marginalmeans.html>
#' * <https://vincentarelbundock.github.io/marginaleffects/>
#'
#' @param variables character vector Categorical predictors over which to
#' compute marginal means. `NULL` calculates marginal means for all logical,
#' character, or factor variables in the dataset used to fit `model`. Set
#' `cross=TRUE` to compute marginal means at combinations of the
#' predictors specified in the `variables` argument.
#' @param variables_grid character vector Categorical predictors used to
#' construct the prediction grid over which adjusted predictions are averaged
#' (character vector). `NULL` creates a grid with all combinations of all
#' categorical predictors. This grid can be very large when there are many
#' variables and many response levels, so it is advisable to select a limited
#' number of variables in the `variables` and `variables_grid` arguments.
#' @param type string indicates the type (scale) of the predictions used to
#' compute marginal effects or contrasts. This can differ based on the model
#' type, but will typically be a string such as: "response", "link", "probs",
#' or "zero". When an unsupported string is entered, the model-specific list of
#' acceptable values is returned in an error message. When `type` is `NULL`, the
#' default value is used. This default is the first model-related row in
#' the `marginaleffects:::type_dictionary` dataframe. If `type` is `NULL` and
#' the default value is "response", the function tries to compute marginal means
#' on the link scale before backtransforming them using the inverse link function.
#' @param wts character value. Weights to use in the averaging.
#' + "equal": each combination of variables in `variables_grid` gets an equal weight.
#' + "cells": each combination of values for the variables in the `variables_grid` gets a weight proportional to its frequency in the original data.
#' + "proportional": each combination of values for the variables in the `variables_grid` -- except for those in the `variables` argument -- gets a weight proportional to its frequency in the original data.
#' @param cross TRUE or FALSE
#' * `FALSE` (default): Marginal means are computed for each predictor individually.
#' * `TRUE`: Marginal means are computed for each combination of predictors specified in the `variables` argument.
#' @param by Collapse marginal means into categories. Data frame with a `by` column of group labels, and merging columns shared by `newdata` or the data frame produced by calling the same function without the `by` argument.
#' @inheritParams slopes
#' @inheritParams predictions
#' @inheritParams comparisons
#' @details
#'   This function begins by calling the `predictions` function to obtain a
#'   grid of predictors, and adjusted predictions for each cell. The grid
#'   includes all combinations of the categorical variables listed in the
#'   `variables` and `variables_grid` arguments, or all combinations of the
#'   categorical variables used to fit the model if `variables_grid` is `NULL`.
#'   In the prediction grid, numeric variables are held at their means.
#'
#'   After constructing the grid and filling the grid with adjusted predictions,
#'   `marginal_means` computes marginal means for the variables listed in the
#'   `variables` argument, by average across all categories in the grid.
#'
#'   `marginal_means` can only compute standard errors for linear models, or for
#'   predictions on the link scale, that is, with the `type` argument set to
#'   "link".
#'
#'   The `marginaleffects` website compares the output of this function to the
#'   popular `emmeans` package, which provides similar but more advanced
#'   functionality: https://vincentarelbundock.github.io/marginaleffects/
#'
#' @template model_specific_arguments
#' @template bayesian
#'
#' @return Data frame of marginal means with one row per variable-value
#' combination.
#' @export
#' @examples
#' library(marginaleffects)
#'
#' # simple marginal means for each level of `cyl`
#' dat <- mtcars
#' dat$carb <- factor(dat$carb)
#' dat$cyl <- factor(dat$cyl)
#' dat$am <- as.logical(dat$am)
#' mod <- lm(mpg ~ carb + cyl + am, dat)
#' 
#' marginal_means(
#'   mod,
#'   variables = "cyl")
#' 
#' # collapse levels of cyl by averaging
#' by <- data.frame(
#'   cyl = c(4, 6, 8),
#'   by = c("4 & 6", "4 & 6", "8"))
#' marginal_means(mod,
#'   variables = "cyl",
#'   by = by)
#' 
#' # pairwise differences between collapsed levels
#' marginal_means(mod,
#'   variables = "cyl",
#'   by = by,
#'   hypothesis = "pairwise")
#' 
#' # cross
#' marginal_means(mod,
#'   variables = c("cyl", "carb"),
#'   cross = TRUE)
#' 
#' # collapsed cross
#' by <- expand.grid(
#'   cyl = unique(mtcars$cyl),
#'   carb = unique(mtcars$carb))
#' by$by <- ifelse(
#'   by$cyl == 4,
#'   paste("Control:", by$carb),
#'   paste("Treatment:", by$carb))
#' 
#' 
#' # Convert numeric variables to categorical before fitting the model
#' dat <- mtcars
#' dat$am <- as.logical(dat$am)
#' dat$carb <- as.factor(dat$carb)
#' mod <- lm(mpg ~ hp + am + carb, data = dat)
#'
#' # Compute and summarize marginal means
#' marginal_means(mod)
#'
#' # Contrast between marginal means (carb2 - carb1), or "is the 1st marginal means equal to the 2nd?"
#' # see the vignette on "Hypothesis Tests and Custom Contrasts" on the `marginaleffects` website.
#' lc <- c(-1, 1, 0, 0, 0, 0)
#' marginal_means(mod, variables = "carb", hypothesis = "b2 = b1")
#'
#' marginal_means(mod, variables = "carb", hypothesis = lc)
#'
#' # Multiple custom contrasts
#' lc <- matrix(c(
#'     -2, 1, 1, 0, -1, 1,
#'     -1, 1, 0, 0, 0, 0
#'     ),
#'   ncol = 2,
#'   dimnames = list(NULL, c("A", "B")))
#' marginal_means(mod, variables = "carb", hypothesis = lc)
#' 
marginal_means <- function(model,
                           variables = NULL,
                           variables_grid = NULL,
                           vcov = TRUE,
                           conf_level = 0.95,
                           type = NULL,
                           transform_post = NULL,
                           cross = FALSE,
                           hypothesis = NULL,
                           df = Inf,
                           wts = "equal",
                           by = NULL,
                           ...) {


    # if type is NULL, we backtransform if relevant
    if (is.null(type)) {
        type <- sanitize_type(model = model, type = type, calling_function = "marginalmeans")
        linv <- tryCatch(
            insight::link_inverse(model),
            error = function(e) NULL)
        if (type == "response" &&
            is.null(transform_post) &&
            class(model)[1] %in% type_dictionary$class &&
            isTRUE("link" %in% subset(type_dictionary, class == class(model)[1])$base) &&
            is.function(linv)) {
            type <- "link"
            transform_post <- linv
        }
    } else {
        type <- sanitize_type(model = model, type = type, calling_function = "marginalmeans")
    }

    modeldata <- newdata <- get_modeldata(model)

    transform_post <- sanitize_transform_post(transform_post)
    cross <- sanitize_cross(cross, variables, model)
    conf_level <- sanitize_conf_level(conf_level, ...)
    model <- sanitize_model(model, vcov = vcov, calling_function = "marginalmeans")
    checkmate::assert_choice(wts, choices = c("equal", "cells", "proportional"))

    tmp <- sanitize_hypothesis(hypothesis, ...)
    hypothesis <- tmp$hypothesis
    hypothesis_null <- tmp$hypothesis_null

    # by: usual tests + only data frames
    checkmate::assert(
        checkmate::check_data_frame(by),
        checkmate::check_false(by),
        checkmate::check_null(by)
    )
    sanity_by(by, newdata)

    # fancy vcov processing to allow strings like "HC3"
    vcov_false <- isTRUE(vcov == FALSE)
    vcov <- get_vcov(model, vcov = vcov, ...)

    # sanity
    sanity_dots(model = model, ...)
    if (inherits(model, "brmsfit")) {
        insight::format_error(c(
            "`brmsfit` objects are yet not supported by the `marginal_means` function.  Follow this link to track progress:",
            "https://github.com/vincentarelbundock/marginaleffects/issues/137"))
    }

    checkmate::assert_character(variables, min.len = 1, null.ok = TRUE)
    if (!is.null(variables)) {
        bad <- setdiff(variables, colnames(newdata))
        if (length(bad) > 0) {
            msg <- sprintf(
                "Elements of the `variables` argument were not found as column names in the data used to fit the model: %s",
                paste(bad, collapse = ", "))
            insight::format_error(msg)
        }
    }
    if (any(variables %in% insight::find_response(model))) {
        insight::format_error("The `variables` vector cannot include the response.")
    }

    checkmate::assert_character(variables_grid, min.len = 1, null.ok = TRUE)
    if (!is.null(variables_grid)) {
        bad <- setdiff(variables_grid, colnames(newdata))
        if (length(bad) > 0) {
            msg <- sprintf(
                "Elements of the `variables_grid` argument were not found as column names in the data used to fit the model: %s",
                paste(bad, collapse = ", "))
            insight::format_error(msg)
        }
    }

    # categorical variables, excluding response
    variables_categorical <- insight::find_variables(model, flatten = TRUE)
    idx <- sapply(variables_categorical, function(x) get_variable_class(newdata, x, "categorical"))
    variables_categorical <- setdiff(
        unique(variables_categorical[idx]),
        insight::find_response(model, flatten = TRUE))
    if (length(variables_categorical) == 0) {
        msg <- insight::format_error("No logical, factor, or character variable was found in the dataset used to fit the `model` object. This error is often raised when users convert variables to factor in the model formula (e.g., `lm(y ~ factor(x)`). If this is the case, you may consider converting variables in the dataset before fitting the model.")
    }

    # subset variables and grid
    if (is.null(variables)) {
        variables <- variables_categorical
    } else {
        variables <- intersect(variables, variables_categorical)
    }

    if (is.null(variables_grid)) {
        variables_grid <- variables_categorical
    } else {
        variables_grid <- intersect(variables_grid, variables_categorical)
    }

    variables_grid <- unique(c(variables, variables_grid))

    if (isTRUE(checkmate::check_character(by))) {
        if (!all(by %in% variables_grid)) {
            msg <- sprintf(
                "All elements of `by` must be part of: %s",
                paste(variables_grid, collapse = ", "))
            insight::format_warning(msg)
        }
        variables <- setdiff(variables, by)
    }

    # marginal means grid
    args <- lapply(variables_grid, function(x) unique(newdata[[x]]))
    args <- stats::setNames(args, variables_grid)
    args[["newdata"]] <- newdata
    newgrid <- do.call("datagrid", args)

    # weights
    wtsgrid <- copy(data.table(newdata)[, ..variables_grid])
    if (identical(wts, "equal")) {
        newgrid[["wts"]] <- 1

    } else if (identical(wts, "cells")) {
        idx <- variables_grid
        wtsgrid[, N := .N]
        wtsgrid[, "wts" := .N / N, by = idx]
        # sometimes datagrid() converts to factors when there is a transformation
        # in the model formula, so we need to standardize the data
        for (v in colnames(newgrid)) {
            if (v %in% colnames(wtsgrid) && is.factor(newgrid[[v]])) {
                wtsgrid[[v]] <- factor(wtsgrid[[v]], levels = levels(newgrid[[v]]))
            }
        }
        wtsgrid <- unique(wtsgrid)
        newgrid <- merge(newgrid, wtsgrid, all.x = TRUE)
        newgrid[["wts"]][is.na(newgrid[["wts"]])] <- 0

    } else if (identical(wts, "proportional")) {
    # https://stackoverflow.com/questions/66748520/what-is-the-difference-between-weights-cell-and-weights-proportional-in-r-pa
        idx <- setdiff(variables_grid, variables)
        if (length(idx) == 0) {
            newgrid[["wts"]] <- 1
            return(newgrid)
        } else {
            wtsgrid <- data.table(newdata)[
                , .(wts = .N), by = idx][
                , wts := wts / sum(wts)]
            # sometimes datagrid() converts to factors when there is a transformation
            # in the model formula, so we need to standardize the data
            for (v in colnames(newgrid)) {
                if (v %in% colnames(wtsgrid) && is.factor(newgrid[[v]])) {
                    wtsgrid[[v]] <- factor(wtsgrid[[v]], levels = levels(newgrid[[v]]))
                 }
            }
            wtsgrid <- unique(wtsgrid)
            newgrid <- merge(newgrid, wtsgrid, all.x = TRUE)
            newgrid[["wts"]][is.na(newgrid[["wts"]])] <- 0

        }
    }

    # `equivalence` should not be passed to predictions() at this stage
    args <- list(
        model = model,
        newdata = newgrid,
        type = type,
        variables = variables,
        cross = cross,
        hypothesis = hypothesis,
        by = by,
        modeldata = modeldata)
    args <- c(args, list(...))
    args[["equivalence"]] <- NULL
    mm <- do.call(get_marginalmeans, args)

    # we want consistent output, regardless of whether `data.table` is installed/used or not
    out <- as.data.frame(mm)

    # standard errors via delta method
    if (!vcov_false) {
        args <- list(
            model,
            vcov = vcov,
            type = type,
            FUN = get_se_delta_marginalmeans,
            index = NULL,
            variables = variables,
            newdata = newgrid,
            cross = cross,
            modeldata = modeldata,
            hypothesis = hypothesis,
            by = by)
        args <- c(args, list(...))
        args[["equivalence"]] <- NULL
        se <- do.call(get_se_delta, args)

        # get rid of attributes in column
        out[["std.error"]] <- as.numeric(se)
        J <- attr(se, "jacobian")
    } else {
        J <- NULL
    }

    lin <- tryCatch(insight::model_info(model)$is_linear, error = function(e) FALSE)
    if (isTRUE(type == "link") || isTRUE(lin)) {
        out <- get_ci(
            out,
            conf_level = conf_level,
            vcov = vcov,
            null_hypothesis = hypothesis_null,
            df = df,
            model = model,
            ...)
    }

    # equivalence tests
    out <- equivalence(out, df = df, ...)

    # after assign draws
    out <- backtransform(out, transform_post)

    # column order
    cols <- c("rowid", "type", "group", colnames(by), "term", "hypothesis", "value", variables, "estimate", "std.error", "statistic", "p.value", "conf.low", "conf.high", sort(colnames(out)))
    cols <- unique(cols)
    cols <- intersect(cols, colnames(out))
    out <- out[, cols, drop = FALSE]

    # attributes
    class(out) <- c("marginalmeans", class(out))
    attr(out, "model") <- model
    attr(out, "jacobian") <- J
    attr(out, "type") <- type
    attr(out, "model_type") <- class(model)[1]
    attr(out, "variables") <- variables
    attr(out, "call") <- match.call()
    attr(out, "conf_level") <- conf_level
    attr(out, "transform_post_label") <- names(transform_post)[1]

    if (isTRUE(cross)) {
        attr(out, "variables_grid") <- setdiff(variables_grid, variables)
    } else {
        attr(out, "variables_grid") <- unique(c(variables_grid, variables))
    }

    if (inherits(model, "brmsfit")) {
        insight::check_if_installed("brms")
        attr(out, "nchains") <- brms::nchains(model)
    }

    return(out)
}


#' Workhorse function for `marginal_means`
#'
#' Needs to be separate because we also need it in `delta_method`
#' @inheritParams marginalmeans
#' @inheritParams predictions
#' @param ... absorb useless arguments from other get_* workhorse functions
#' @noRd
get_marginalmeans <- function(model,
                              newdata,
                              type,
                              variables,
                              cross,
                              modeldata,
                              hypothesis = NULL,
                              by = NULL,
                              ...) {

    if ("wts" %in% colnames(newdata)) {
        wts <- "wts"
    } else {
        wts <- NULL
    }

    # predictions for each cell of all categorical data, but not the response
    if (isTRUE(cross) || length(variables) == 1) {
        out <- predictions(
            model = model,
            newdata = newdata,
            type = type,
            vcov = FALSE,
            modeldata = modeldata,
            wts = wts,
            by = c("group", variables),
            ...)
        if (length(variables) == 1) {
            out$term <- variables
            out$value <- out[[variables]]
        }

    # predictions for each variable individual, then bind
    } else {
        pred_list <- draw_list <- list()
        for (v in variables) {
            tmp <- predictions(
                model = model,
                newdata = newdata,
                type = type,
                vcov = FALSE,
                modeldata = modeldata,
                wts = wts,
                by = c("group", v),
                ...)
            draw_list[[v]] <- attr(tmp, "posterior_draws")
            tmp$term <- v
            data.table::setnames(tmp, old = v, new = "value")
            pred_list[[v]] <- tmp
        }
        # try to preserve term-value class, but convert to character if needed to bind
        classes <- sapply(pred_list, function(x) class(x$value)[1])
        if (length(unique(classes)) > 1) {
            for (i in seq_along(pred_list)) {
                pred_list[[i]]$value <- as.character(pred_list[[i]]$value)
            }
        }
        out <- rbindlist(pred_list)
        data.table::setorderv(out, c("term", "value"))
    }

    data.table::setDT(out)
    keys <- intersect(colnames(out), c("term", "value", variables))
    data.table::setorderv(out, keys)

    if (isTRUE(checkmate::check_data_frame(by))) {
        # warnings for factor vs numeric vs character. merge.data.table usually still works.
        bycols <- intersect(colnames(out), colnames(by))
        if (length(bycols) == 0) {
            msg <- "There is no common columns in `by` and in the output of `marginal_means()`. Make sure one of the entries in the `variables` argument corresponds to one of the columns in `by`."
            insight::format_error(msg)
        }
        for (b in bycols) {
            if (is.factor(out[[b]]) && is.numeric(by[[b]])) {
                out[[b]] <- as.numeric(as.character(out[[b]]))
            } else if (is.numeric(out[[b]]) && is.factor(by[[b]])) {
                by[[b]] <- as.numeric(as.character(by[[b]]))
            } else if (is.factor(out[[b]]) && is.character(by[[b]])) {
                out[[b]] <- as.character(out[[b]])
            } else if (is.character(out[[b]]) && is.factor(by[[b]])) {
                by[[b]] <- as.character(by[[b]])
            }
        }
        out <- merge(out, by)
        out <- out[, .(estimate = mean(estimate)), by = "by"]
    }

    if (!is.null(hypothesis)) {
        out <- get_hypothesis(out, hypothesis, by = by)
    }

    return(out)
}



#' `marginal_means()` is an alias to `marginal_means()`
#' 
#' This alias is kept for backward compatibility and because some users may prefer that name.
#'
#' @inherit marginal_means
#' @keywords internal
#' @export
marginalmeans <- marginal_means