# Get Cytoscape Template

Copies the bundled PGDCM Cytoscape template file to the current working
directory.

## Usage

``` r
get_Cyto_template(dest_dir = getwd(), overwrite = FALSE)
```

## Arguments

- dest_dir:

  Character. The destination directory to copy the template to. Defaults
  to the current working directory.

- overwrite:

  Logical. Whether to overwrite the file if it already exists. Defaults
  to FALSE.

## Value

Logical. TRUE if successful, FALSE otherwise.
