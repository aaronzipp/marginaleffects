source("helpers.R")
using("marginaleffects")

exit_if_not(requiet("margins"))
exit_if_not(requiet("emmeans"))
exit_if_not(requiet("broom"))
exit_if_not(requiet("survey"))

# survey: marginaleffects vs. margins vs. emtrends
data("fpc", package = "survey")
svyd <- survey::svydesign(
    weights = ~weight,
    ids = ~psuid,
    strata = ~stratid,
    fpc = ~Nh,
    variables = ~ x + nh,
    data = fpc,
    nest = TRUE)
mod <- survey::svyglm(x ~ nh, design = svyd)
res <- slopes(mod)
mar <- suppressMessages(data.frame(margins(mod, unit_ses = TRUE)))
expect_equivalent(res$estimate, as.numeric(mar$dydx_nh))
expect_equivalent(res$std.error, as.numeric(mar$SE_dydx_nh), tolerance = 0.0001)
# emtrends
em <- emtrends(mod, ~nh, "nh", at = list(nh = 4))
em <- tidy(em)
mfx <- slopes(mod, type = "link", newdata = data.frame(nh = 4))
expect_equivalent(mfx$estimate, em$nh.trend, tolerance = .001) # CRAN tolerance
expect_equivalent(mfx$std.error, em$std.error, tolerance = .001)
