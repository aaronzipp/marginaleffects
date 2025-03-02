bootstrap_boot <- function(model, FUN, ...) {

    # attached by `inferences()`
    conf_type <- attr(model, "inferences_conf_type")
    checkmate::assert_choice(conf_type, choices = c("perc", "norm", "basic", "bca"))

    # bootstrap using the original data and call
    modcall <- insight::get_call(model)
    modeldata <- get_modeldata(model)

    # evaluate the {marginaleffects} call to get output without inferences()
    # use ... because arguments are not the same for different {marginaleffects} functions
    dots <- list(...)
    dots[["vcov"]] <- FALSE

    # avoid recursion
    attr(model, "inferences_method") <- NULL
    out <- do.call(FUN, c(list(model), dots))

    # default confidence level may be implicit in original call, but we need numeric
    if (is.null(dots[["conf_level"]])) {
        conf_level <- 0.95
    } else {
        conf_level <- dots[["conf_level"]]
    }

    bootfun <- function(data, indices) {
        d <- data[indices, , drop = FALSE]
        modcall[["data"]] <- d
        modboot <- eval(modcall)
        modboot <- eval(modboot)
        args <- c(list(modboot), dots)
        out <- do.call(FUN, args)$estimate
        return(out)
    }
    args <- list("data" = modeldata, "statistic" = bootfun)
    args <- c(args, attr(model, "inferences_dots"))
    args <- args[unique(names(args))]
    B <- do.call(boot::boot, args)

    # print.boot prints an ugly nested call
    B$call <- match.call()

    # HACK: boot::boot() output is non-standard. There must be a better way!
    # NG: just compute them manually as the SD of the bootstrap distribution
    pr <- utils::capture.output(print(B))
    pr <- pr[(grep("^Bootstrap Statistics :", pr) + 1):length(pr)]
    pr <- gsub("std. error", "std.error", pr)
    pr <- paste(pr, collapse = "\n")
    pr <- utils::read.table(text = pr, header = TRUE)
    out$std.error <- pr$std.error

    # extract from weird boot.ci() list (inspired from `broom::tidy.broom` under MIT)
    ci_list <- lapply(seq_along(B$t0),
                      boot::boot.ci,
                      boot.out = B,
                      conf = conf_level,
                      type = conf_type)
    pos <- pmatch(conf_type, names(ci_list[[1]]))
    if (conf_type == "norm") {
        cols <- 2:3
    } else {
        cols <- 4:5
    }
    ci <- lapply(ci_list, function(x) x[[pos]])
    ci <- do.call("rbind", ci)[, cols]

    # add CI to original {marginaleffects} call
    if (is.matrix(ci)) {
        out$conf.low <- ci[, 1]
        out$conf.high <- ci[, 2]
    } else {
        out$conf.low <- ci[1]
        out$conf.high <- ci[2]
    }

    attr(out, "inferences") <- B
    attr(out, "posterior_draws") <- t(B$t)
    return(out)
}
