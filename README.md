
# The `marginaleffects` package for `R` <img src="https://user-images.githubusercontent.com/987057/134899484-e3392510-2e94-4c39-9830-53356fa5feed.png" align="right" alt="" width="120" />

<!--
[![Codecov test coverage](https://codecov.io/gh/vincentarelbundock/marginaleffects/branch/main/graph/badge.svg)](https://app.codecov.io/gh/vincentarelbundock/marginaleffects?branch=main)
[![R-CMD-check](https://github/To cl.com/vincentarelbundock/marginaleffects/workflows/R-CMD-check/badge.svg)](https://github.com/vincentarelbundock/marginaleffects/actions)
[![CRAN status](https://www.r-pkg.org/badges/version/marginaleffects)](https://CRAN.R-project.org/package=marginaleffects)
[![status](https://tinyverse.netlify.com/badge/marginaleffects)](https://CRAN.R-project.org/package=marginaleffects)
-->

Compute and plot predictions, slopes, marginal means, and comparisons
(contrasts, risk ratios, odds ratios, etc.) for over 70 classes of
statistical models in R. Conduct linear and non-linear hypothesis tests,
as well as equivalence tests using the delta method.

[The `marginaleffects`
website](https://vincentarelbundock.github.io/marginaleffects/) includes
a [“Get
started”](https://vincentarelbundock.github.io/marginaleffects/articles/marginaleffects.html)
tutorial and 25+ [vignettes, case studies, and technical
notes.](https://vincentarelbundock.github.io/marginaleffects/articles/index.html)

# Installation

Install the latest CRAN release:

``` r
install.packages("marginaleffects")
```

Install the development version:

``` r
install.packages(
    c("marginaleffects", "insight"),
    repos = c("https://vincentarelbundock.r-universe.dev", "https://easystats.r-universe.dev"))
```

*Restart `R` completely before moving on.*

# Why?

Parameter estimates are often hard to interpret substantively,
especially when they are generated by complex models with non-linear
components or transformations. Many applied researchers would rather
focus on simple quantities of interest, which have straightforward
scientific interpretations. Unfortunately, these estimands (and their
standard errors) are tedious to compute. Moreover, the different
modeling packages in `R` often produce inconsistent objects that require
special treatment.

`marginaleffects` offers a single point of entry to easily interpret the
results of over 73 classes of models, using a simple and consistent user
interface.

Benefits of `marginaleffects` include:

  - *Powerful:* It can compute predictions, comparisons (contrasts, risk
    ratios, etc.), slopes, and conduct hypothesis tests for 73 different
    classes of models in `R`.
  - *Simple:* All functions share a simple and unified interface.
  - *Documented*: Each function is thoroughly documented with abundant
    examples. The website includes 20,000+ words of vignettes and case
    studies.
  - *Efficient:* [Some
    operations](https://vincentarelbundock.github.io/marginaleffects/articles/performance.html)
    are orders of magnitude faster than with the `margins` package, and
    the memory footprint is much smaller.
  - *Valid:* When possible, [numerical results are
    checked](https://vincentarelbundock.github.io/marginaleffects/articles/supported_models.html)
    against alternative software like `Stata` or other `R` packages.
  - *Thin:* Few dependencies.
  - *Standards-compliant:* `marginaleffects` follows “tidy” principles
    and returns objects that work with standard functions like `plot`,
    `summary()`, `tidy()`, and `glance()`. These objects are easy to
    program with and feed to [other packages like
    `modelsummary`.](https://vincentarelbundock.github.io/marginaleffects/)
  - *Extensible:* Adding support for new models is very easy, often
    requiring less than 10 lines of new code. Please submit [feature
    requests on
    Github.](https://github.com/vincentarelbundock/marginaleffects/issues)
  - *Active development*: Bugs are fixed promptly.

# What?

The `marginaleffects` package allows `R` users to compute and plot three
principal quantities of interest: (1) predictions, (2) comparisons, and
(3) slopes. In addition, the package includes a convenience function to
compute a fourth estimand, “marginal means”, which is a special case of
averaged predictions. `marginaleffects` can also average (or
“marginalize”) unit-level (or “conditional”) estimates of all those
quantities, and conduct hypothesis tests on them.

[Predictions:](https://vincentarelbundock.github.io/marginaleffects/articles/predictions.html)

> The outcome predicted by a fitted model on a specified scale for a
> given combination of values of the predictor variables, such as their
> observed values, their means, or factor levels. a.k.a. Fitted values,
> adjusted predictions. `predictions()`, `avg_predictions()`,
> `plot_predictions()`.

[Comparisons:](https://vincentarelbundock.github.io/marginaleffects/articles/comparisons.html)

> Compare the predictions made by a model for different regressor values
> (e.g., college graduates vs. others): contrasts, differences, risk
> ratios, odds, etc. `comparisons()`, `avg_comparisons()`,
> `plot_comparisons()`.

[Slopes:](https://vincentarelbundock.github.io/marginaleffects/articles/slopes.html)

> Partial derivative of the regression equation with respect to a
> regressor of interest. a.k.a. Marginal effects, trends. `slopes()`,
> `avg_slopes()`, `plot_slopes()`.

[Marginal
Means:](https://vincentarelbundock.github.io/marginaleffects/articles/marginalmeans.html)

> Predictions of a model, averaged across a “reference grid” of
> categorical predictors. `marginalmeans()`.

<table>

<thead>

<tr>

<th style="text-align:left;">

Goal

</th>

<th style="text-align:left;">

Function

</th>

</tr>

</thead>

<tbody>

<tr>

<td style="text-align:left;">

Predictions

</td>

<td style="text-align:left;">

[`predictions()`](https://vincentarelbundock.github.io/marginaleffects/reference/comparisons.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

[`avg_predictions()`](https://vincentarelbundock.github.io/marginaleffects/reference/comparisons.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

[`plot_predictions()`](https://vincentarelbundock.github.io/marginaleffects/reference/plot_comparisons.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

Comparisons

</td>

<td style="text-align:left;">

[`comparisons()`](https://vincentarelbundock.github.io/marginaleffects/reference/comparisons.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

[`avg_comparisons()`](https://vincentarelbundock.github.io/marginaleffects/reference/comparisons.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

[`plot_comparisons()`](https://vincentarelbundock.github.io/marginaleffects/reference/plot_comparisons.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

Slopes

</td>

<td style="text-align:left;">

[`slopes()`](https://vincentarelbundock.github.io/marginaleffects/reference/slopes.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

[`avg_slopes()`](https://vincentarelbundock.github.io/marginaleffects/reference/slopes.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

[`plot_slopes()`](https://vincentarelbundock.github.io/marginaleffects/reference/plot_slopes.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

Marginal Means

</td>

<td style="text-align:left;">

[`marginal_means()`](https://vincentarelbundock.github.io/marginaleffects/reference/marginal_means.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

Grids

</td>

<td style="text-align:left;">

[`datagrid()`](https://vincentarelbundock.github.io/marginaleffects/reference/datagrid.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

[`datagridcf()`](https://vincentarelbundock.github.io/marginaleffects/reference/datagrid.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

Hypothesis & Equivalence

</td>

<td style="text-align:left;">

[`hypotheses()`](https://vincentarelbundock.github.io/marginaleffects/reference/hypotheses.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

Bayes, Bootstrap, Simulation

</td>

<td style="text-align:left;">

[`posterior_draws()`](https://vincentarelbundock.github.io/marginaleffects/reference/inferences.html)

</td>

</tr>

<tr>

<td style="text-align:left;">

</td>

<td style="text-align:left;">

[`inferences()`](https://vincentarelbundock.github.io/marginaleffects/reference/inferences.html)

</td>

</tr>

</tbody>

</table>
