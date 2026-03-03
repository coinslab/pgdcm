# Generate Posterior/Prior Predictive Plots

Creates diagnostic PDF plots comparing simulated vs observed statistics
including global means, score distributions, item difficulties, and
co-occurrences.

## Usage

``` r
generate_ppc_plots(
  filename,
  title_suffix,
  simMeans,
  simRowMeans,
  simColMeans,
  avgSimM2,
  obsColMeans,
  obsRowMeans,
  obsMean,
  M2_obs
)
```

## Arguments

- filename:

  Character. Output path for the PDF file.

- title_suffix:

  Character. Title suffix appended to plot titles.

- simMeans:

  Numeric vector. Simulated global means.

- simRowMeans:

  Numeric matrix. Simulated row (participant) means.

- simColMeans:

  Numeric matrix. Simulated column (item) means.

- avgSimM2:

  Numeric matrix. Simulated average second-order moments.

- obsColMeans:

  Numeric vector. Observed column means.

- obsRowMeans:

  Numeric vector. Observed row means.

- obsMean:

  Numeric. Observed global mean.

- M2_obs:

  Numeric matrix. Observed second-order moments.

## Value

NULL. Saves a PDF file to the specified path.
