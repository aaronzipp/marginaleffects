% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/datagrid.R
\name{datagrid}
\alias{datagrid}
\alias{datagridcf}
\title{Data grids}
\usage{
datagrid(
  ...,
  model = NULL,
  newdata = NULL,
  grid_type = "typical",
  FUN_character = get_mode,
  FUN_factor = get_mode,
  FUN_logical = get_mode,
  FUN_numeric = function(x) mean(x, na.rm = TRUE),
  FUN_integer = function(x) round(mean(x, na.rm = TRUE)),
  FUN_other = function(x) mean(x, na.rm = TRUE)
)

datagridcf(..., model = NULL, newdata = NULL)
}
\arguments{
\item{...}{named arguments with vectors of values or functions for user-specified variables.
\itemize{
\item Functions are applied to the variable in the \code{model} dataset or \code{newdata}, and must return a vector of the appropriate type.
\item Character vectors are automatically transformed to factors if necessary.
+The output will include all combinations of these variables (see Examples below.)
}}

\item{model}{Model object}

\item{newdata}{data.frame (one and only one of the \code{model} and \code{newdata} arguments}

\item{grid_type}{character
\itemize{
\item "typical": variables whose values are not explicitly specified by the user in \code{...} are set to their mean or mode, or to the output of the functions supplied to \code{FUN_type} arguments.
\item "counterfactual": the entire dataset is duplicated for each combination of the variable values specified in \code{...}. Variables not explicitly supplied to \code{datagrid()} are set to their observed values in the original dataset.
}}

\item{FUN_character}{the function to be applied to character variables.}

\item{FUN_factor}{the function to be applied to factor variables.}

\item{FUN_logical}{the function to be applied to factor variables.}

\item{FUN_numeric}{the function to be applied to numeric variables.}

\item{FUN_integer}{the function to be applied to integer variables.}

\item{FUN_other}{the function to be applied to other variable types.}
}
\value{
A \code{data.frame} in which each row corresponds to one combination of the named
predictors supplied by the user via the \code{...} dots. Variables which are not
explicitly defined are held at their mean or mode.
}
\description{
Generate a data grid of user-specified values for use in the \code{newdata} argument of the \code{predictions()}, \code{comparisons()}, and \code{slopes()} functions. This is useful to define where in the predictor space we want to evaluate the quantities of interest. Ex: the predicted outcome or slope for a 37 year old college graduate.
\itemize{
\item \code{datagrid()} generates data frames with combinations of "typical" or user-supplied predictor values.
\item \code{datagridcf()} generates "counter-factual" data frames, by replicating the entire dataset once for every combination of predictor values supplied by the user.
}
}
\details{
If \code{datagrid} is used in a \code{predictions()}, \code{comparisons()}, or \code{slopes()} call as the
\code{newdata} argument, the model is automatically inserted in the \code{model} argument of \code{datagrid()}
call, and users do not need to specify either the \code{model} or \code{newdata} arguments.

If users supply a model, the data used to fit that model is retrieved using
the \code{insight::get_data} function.
}
\section{Functions}{
\itemize{
\item \code{datagridcf()}: Counterfactual data grid

}}
\examples{
# The output only has 2 rows, and all the variables except `hp` are at their
# mean or mode.
datagrid(newdata = mtcars, hp = c(100, 110))

# We get the same result by feeding a model instead of a data.frame
mod <- lm(mpg ~ hp, mtcars)
datagrid(model = mod, hp = c(100, 110))

# Use in `marginaleffects` to compute "Typical Marginal Effects". When used
# in `slopes()` or `predictions()` we do not need to specify the
#`model` or `newdata` arguments.
slopes(mod, newdata = datagrid(hp = c(100, 110)))

# datagrid accepts functions
datagrid(hp = range, cyl = unique, newdata = mtcars)
comparisons(mod, newdata = datagrid(hp = fivenum))

# The full dataset is duplicated with each observation given counterfactual
# values of 100 and 110 for the `hp` variable. The original `mtcars` includes
# 32 rows, so the resulting dataset includes 64 rows.
dg <- datagrid(newdata = mtcars, hp = c(100, 110), grid_type = "counterfactual")
nrow(dg)

# We get the same result by feeding a model instead of a data.frame
mod <- lm(mpg ~ hp, mtcars)
dg <- datagrid(model = mod, hp = c(100, 110), grid_type = "counterfactual")
nrow(dg)
}
