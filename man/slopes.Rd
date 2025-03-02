% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/slopes.R
\name{slopes}
\alias{slopes}
\alias{avg_slopes}
\title{Slopes (aka Partial derivatives, Marginal Effects, or Trends)}
\usage{
slopes(
  model,
  newdata = NULL,
  variables = NULL,
  type = NULL,
  by = FALSE,
  vcov = TRUE,
  conf_level = 0.95,
  slope = "dydx",
  wts = NULL,
  hypothesis = NULL,
  df = Inf,
  eps = NULL,
  ...
)

avg_slopes(
  model,
  newdata = NULL,
  variables = NULL,
  type = NULL,
  by = TRUE,
  vcov = TRUE,
  conf_level = 0.95,
  slope = "dydx",
  wts = NULL,
  hypothesis = NULL,
  df = Inf,
  eps = NULL,
  ...
)
}
\arguments{
\item{model}{Model object}

\item{newdata}{\code{NULL}, data frame, string, or \code{datagrid()} call. Determines the predictor values for which to compute slopes.
\itemize{
\item \code{NULL} (default): Unit-level slopes each observed value in the original dataset.
\item data frame: Unit-level slopes for each row of the \code{newdata} data frame.
\item \code{\link[=datagrid]{datagrid()}} call to specify a custom grid of regressors. For example:
\itemize{
\item \code{newdata = datagrid(cyl = c(4, 6))}: \code{cyl} variable equal to 4 and 6 and other regressors fixed at their means or modes.
\item See the Examples section and the \code{\link[=datagrid]{datagrid()}} documentation.
}
\item string:
\itemize{
\item "mean": Marginal Effects at the Mean. Slopes when each predictor is held at its mean or mode.
\item "median": Marginal Effects at the Median. Slopes when each predictor is held at its median or mode.
\item "marginalmeans": Marginal Effects at Marginal Means. See Details section below.
\item "tukey": Marginal Effects at Tukey's 5 numbers.
\item "grid": Marginal Effects on a grid of representative numbers (Tukey's 5 numbers and unique values of categorical predictors).
}
}}

\item{variables}{\code{NULL} or character vector. The subset of variables for which to compute slopes.
\itemize{
\item \code{NULL}: compute contrasts for all the variables in the model object (can be slow).
\item Character vector: subset of variables (usually faster).
}}

\item{type}{string indicates the type (scale) of the predictions used to
compute contrasts or slopes. This can differ based on the model
type, but will typically be a string such as: "response", "link", "probs",
or "zero". When an unsupported string is entered, the model-specific list of
acceptable values is returned in an error message. When \code{type} is \code{NULL}, the
default value is used. This default is the first model-related row in
the \code{marginaleffects:::type_dictionary} dataframe.}

\item{by}{Aggregate unit-level estimates (aka, marginalize, average over). Valid inputs:
\itemize{
\item \code{FALSE}: return the original unit-level estimates.
\item \code{TRUE}: aggregate estimates for each term.
\item Character vector of column names in \code{newdata} or in the data frame produced by calling the function without the \code{by} argument.
\item Data frame with a \code{by} column of group labels, and merging columns shared by \code{newdata} or the data frame produced by calling the same function without the \code{by} argument.
\item See examples below.
}}

\item{vcov}{Type of uncertainty estimates to report (e.g., for robust standard errors). Acceptable values:
\itemize{
\item FALSE: Do not compute standard errors. This can speed up computation considerably.
\item TRUE: Unit-level standard errors using the default \code{vcov(model)} variance-covariance matrix.
\item String which indicates the kind of uncertainty estimates to return.
\itemize{
\item Heteroskedasticity-consistent: \code{"HC"}, \code{"HC0"}, \code{"HC1"}, \code{"HC2"}, \code{"HC3"}, \code{"HC4"}, \code{"HC4m"}, \code{"HC5"}. See \code{?sandwich::vcovHC}
\item Heteroskedasticity and autocorrelation consistent: \code{"HAC"}
\item Mixed-Models degrees of freedom: "satterthwaite", "kenward-roger"
\item Other: \code{"NeweyWest"}, \code{"KernHAC"}, \code{"OPG"}. See the \code{sandwich} package documentation.
}
\item One-sided formula which indicates the name of cluster variables (e.g., \code{~unit_id}). This formula is passed to the \code{cluster} argument of the \code{sandwich::vcovCL} function.
\item Square covariance matrix
\item Function which returns a covariance matrix (e.g., \code{stats::vcov(model)})
}}

\item{conf_level}{numeric value between 0 and 1. Confidence level to use to build a confidence interval.}

\item{slope}{string indicates the type of slope or (semi-)elasticity to compute:
\itemize{
\item "dydx": dY/dX
\item "eyex": dY/dX * Y / X
\item "eydx": dY/dX * Y
\item "dyex": dY/dX / X
}}

\item{wts}{string or numeric: weights to use when computing average
contrasts or slopes. These weights only affect the averaging in
\verb{avg_*()} or with the \code{by} argument, and not the unit-level estimates themselves.
\itemize{
\item string: column name of the weights variable in \code{newdata}. When supplying a column name to \code{wts}, it is recommended to supply the original data (including the weights variable) explicitly to \code{newdata}.
\item numeric: vector of length equal to the number of rows in the original data or in \code{newdata} (if supplied).
}}

\item{hypothesis}{specify a hypothesis test or custom contrast using a numeric value, vector, or matrix, a string, or a string formula.
\itemize{
\item Numeric:
\itemize{
\item Single value: the null hypothesis used in the computation of Z and p (before applying \code{transform_post}).
\item Vector: Weights to compute a linear combination of (custom contrast between) estimates. Length equal to the number of rows generated by the same function call, but without the \code{hypothesis} argument.
\item Matrix: Each column is a vector of weights, as describe above, used to compute a distinct linear combination of (contrast between) estimates. The column names of the matrix are used as labels in the output.
}
\item String formula to specify linear or non-linear hypothesis tests. If the \code{term} column uniquely identifies rows, terms can be used in the formula. Otherwise, use \code{b1}, \code{b2}, etc. to identify the position of each parameter. Examples:
\itemize{
\item \code{hp = drat}
\item \code{hp + drat = 12}
\item \code{b1 + b2 + b3 = 0}
}
\item String:
\itemize{
\item "pairwise": pairwise differences between estimates in each row.
\item "reference": differences between the estimates in each row and the estimate in the first row.
\item "sequential": difference between an estimate and the estimate in the next row.
\item "revpairwise", "revreference", "revsequential": inverse of the corresponding hypotheses, as described above.
}
\item See the Examples section below and the vignette: https://vincentarelbundock.github.io/marginaleffects/articles/hypothesis.html
}}

\item{df}{Degrees of freedom used to compute p values and confidence intervals. A single numeric value between 1 and \code{Inf}. When \code{df} is \code{Inf}, the normal distribution is used. When \code{df} is finite, the \code{t} distribution is used. See \link[insight:get_df]{insight::get_df} for a convenient function to extract degrees of freedom. Ex: \code{slopes(model, df = insight::get_df(model))}}

\item{eps}{NULL or numeric value which determines the step size to use when
calculating numerical derivatives: (f(x+eps)-f(x))/eps. When \code{eps} is
\code{NULL}, the step size is 0.0001 multiplied by the difference between
the maximum and minimum values of the variable with respect to which we
are taking the derivative. Changing \code{eps} may be necessary to avoid
numerical problems in certain models.}

\item{...}{Additional arguments are passed to the \code{predict()} method
supplied by the modeling package.These arguments are particularly useful
for mixed-effects or bayesian models (see the online vignettes on the
\code{marginaleffects} website). Available arguments can vary from model to
model, depending on the range of supported arguments by each modeling
package. See the "Model-Specific Arguments" section of the
\code{?marginaleffects} documentation for a non-exhaustive list of available
arguments.}
}
\value{
A \code{data.frame} with one row per observation (per term/group) and several columns:
\itemize{
\item \code{rowid}: row number of the \code{newdata} data frame
\item \code{type}: prediction type, as defined by the \code{type} argument
\item \code{group}: (optional) value of the grouped outcome (e.g., categorical outcome models)
\item \code{term}: the variable whose marginal effect is computed
\item \code{dydx}: slope of the outcome with respect to the term, for a given combination of predictor values
\item \code{std.error}: standard errors computed by via the delta method.
}
}
\description{
Partial derivative of the regression equation with respect to a regressor of interest.
\itemize{
\item \code{slopes()}: unit-level (conditional) estimates.
\item \code{avg_slopes()}: average (marginal) estimates.
}

The \code{newdata} argument and the \code{datagrid()} function can be used to control where statistics are evaluated in the predictor space: "at observed values", "at the mean", "at representative values", etc.

See the slopes vignette and package website for worked examples and case studies:
\itemize{
\item \url{https://vincentarelbundock.github.io/marginaleffects/articles/slopes.html}
\item \url{https://vincentarelbundock.github.io/marginaleffects/}
}
}
\details{
A "slope" or "marginal effect" is the partial derivative of the regression equation
with respect to a variable in the model. This function uses automatic
differentiation to compute slopes for a vast array of models,
including non-linear models with transformations (e.g., polynomials).
Uncertainty estimates are computed using the delta method.

Numerical derivatives for the \code{slopes} function are calculated
using a simple epsilon difference approach: \eqn{\partial Y / \partial X = (f(X + \varepsilon) - f(X)) / \varepsilon}{dY/dX = (f(X + e) - f(X)) / e},
where f is the \code{predict()} method associated with the model class, and
\eqn{\varepsilon}{e} is determined by the \code{eps} argument.

Warning: Some models are particularly sensitive to \code{eps}, so it is good
practice to try different values of this argument.

Standard errors for the slopes are obtained using the Delta
method. See the "Standard Errors" vignette on the package website for
details (link above).
}
\section{Functions}{
\itemize{
\item \code{avg_slopes()}: Average slopes

}}
\section{Model-Specific Arguments}{


Some model types allow model-specific arguments to modify the nature of
marginal effects, predictions, marginal means, and contrasts.\tabular{llll}{
   Package \tab Class \tab Argument \tab Documentation \cr
   \code{brms} \tab \code{brmsfit} \tab \code{ndraws} \tab \link[brms:posterior_predict.brmsfit]{brms::posterior_predict} \cr
    \tab  \tab \code{re_formula} \tab  \cr
   \code{lme4} \tab \code{merMod} \tab \code{include_random} \tab \link[insight:get_predicted]{insight::get_predicted} \cr
    \tab  \tab \code{re.form} \tab \link[lme4:predict.merMod]{lme4::predict.merMod} \cr
    \tab  \tab \code{allow.new.levels} \tab \link[lme4:predict.merMod]{lme4::predict.merMod} \cr
   \code{glmmTMB} \tab \code{glmmTMB} \tab \code{re.form} \tab \link[glmmTMB:predict.glmmTMB]{glmmTMB::predict.glmmTMB} \cr
    \tab  \tab \code{allow.new.levels} \tab \link[glmmTMB:predict.glmmTMB]{glmmTMB::predict.glmmTMB} \cr
    \tab  \tab \code{zitype} \tab \link[glmmTMB:predict.glmmTMB]{glmmTMB::predict.glmmTMB} \cr
   \code{mgcv} \tab \code{bam} \tab \code{exclude} \tab \link[mgcv:predict.bam]{mgcv::predict.bam} \cr
   \code{robustlmm} \tab \code{rlmerMod} \tab \code{re.form} \tab \link[robustlmm:rlmerMod-class]{robustlmm::predict.rlmerMod} \cr
    \tab  \tab \code{allow.new.levels} \tab \link[robustlmm:rlmerMod-class]{robustlmm::predict.rlmerMod} \cr
}
}

\section{Bayesian posterior summaries}{


By default, credible intervals in bayesian models are built as equal-tailed
intervals. This can be changed to a highest density interval by setting a global
option:

\code{options("marginaleffects_posterior_interval" = "eti")}

\code{options("marginaleffects_posterior_interval" = "hdi")}

By default, the center of the posterior distribution in bayesian models is
identified by the median. Users can use a different summary function by setting a
global option:

\code{options("marginaleffects_posterior_center" = "mean")}

\code{options("marginaleffects_posterior_center" = "median")}

When estimates are averaged using the \code{by} argument, the \code{tidy()} function, or
the \code{summary()} function, the posterior distribution is marginalized twice over.
First, we take the average \emph{across} units but \emph{within} each iteration of the
MCMC chain, according to what the user requested in \code{by} argument or
\code{tidy()/summary()} functions. Then, we identify the center of the resulting
posterior using the function supplied to the
\code{"marginaleffects_posterior_center"} option (the median by default).
}

\examples{
\dontshow{if (interactive()) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
\dontshow{\}) # examplesIf}

# Unit-level (conditional) Marginal Effects
mod <- glm(am ~ hp * wt, data = mtcars, family = binomial)
mfx <- slopes(mod)
head(mfx)

# Average Marginal Effect (AME)
avg_slopes(mod, by = TRUE)


# Marginal Effect at the Mean (MEM)
slopes(mod, newdata = datagrid())

# Marginal Effect at User-Specified Values
# Variables not explicitly included in `datagrid()` are held at their means
slopes(mod, newdata = datagrid(hp = c(100, 110)))

# Group-Average Marginal Effects (G-AME)
# Calculate marginal effects for each observation, and then take the average
# marginal effect within each subset of observations with different observed
# values for the `cyl` variable:
mod2 <- lm(mpg ~ hp * cyl, data = mtcars)
avg_slopes(mod2, variables = "hp", by = "cyl")

# Marginal Effects at User-Specified Values (counterfactual)
# Variables not explicitly included in `datagrid()` are held at their
# original values, and the whole dataset is duplicated once for each
# combination of the values in `datagrid()`
mfx <- slopes(mod,
              newdata = datagrid(hp = c(100, 110),
              grid_type = "counterfactual"))
head(mfx)

# Heteroskedasticity robust standard errors
mfx <- slopes(mod, vcov = sandwich::vcovHC(mod))
head(mfx)

# hypothesis test: is the `hp` marginal effect at the mean equal to the `drat` marginal effect
mod <- lm(mpg ~ wt + drat, data = mtcars)

slopes(
    mod,
    newdata = "mean",
    hypothesis = "wt = drat")

# same hypothesis test using row indices
slopes(
    mod,
    newdata = "mean",
    hypothesis = "b1 - b2 = 0")

# same hypothesis test using numeric vector of weights
slopes(
    mod,
    newdata = "mean",
    hypothesis = c(1, -1))

# two custom contrasts using a matrix of weights
lc <- matrix(c(
    1, -1,
    2, 3),
    ncol = 2)
colnames(lc) <- c("Contrast A", "Contrast B")
slopes(
    mod,
    newdata = "mean",
    hypothesis = lc)

}
