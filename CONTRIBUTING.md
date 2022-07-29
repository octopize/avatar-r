# How to contribute ?

This is a guide intended for developers wanting to lend a hand.
It contains detailed instructions on how to setup your development environment and
the prerequisites needed to work on this project.

## Prerequisites

Make sure you have R installed. On macOS:

```bash
# libgit2 is required by devtools
brew install r libgit2
brew install --cask rstudio  # recommended

R --version  # make sure you have 4.1.2, the latest as of writing
```

If you have never created an R package before, it is good idea to follow the tutorial here: https://r-pkgs.org/whole-game.html

## Installing deps

```bash
make install
```

Make sure things are properly installed:

```text
> library(devtools)
Loading required package: usethis
> has_devel()
Your system is ready to build packages!
```

## Quickstart

Install with:

```R
# type="source" prevents a warning about R version
install.packages("...", repos=NULL, type="source")
```

See `vignettes/tutorial.Rmd`

If you make modifications to the library, you need to reload it with:

```R
devtools::load_all()
```

RStudio is pretty useful for some stuff - its installation is recommended.

### Checking the documentation

After having installed the current library:

```r
help(set_server)
browseVignettes(package="avatar")
```

### Generate a PDF tutorial

- Uncomment "output: pdf_document" and "always_allow_html: true", comment "output: rmarkdown::html_vignette".
- Open `tutorial.Rmd` in RStudio
- Knit the tutorial vignette

## Releasing a new version

1. Update version in `DESCRIPTION`
2. `git add DESCRIPTION`
3. `git commit -m "chore: release $VERSION"`
4. `git tag -as $VERSION -m "Release version $VERSION"`
5. `git push --tags && git push`

A GitHub action will then take care of checking the source code and creating a release.

## Useful resources

- `httr` and `curl`
  - [Upload data directly from R session](https://github.com/r-lib/httr/issues/650)
  - https://github.com/jeroen/curl/blob/master/R/form.R
- Writing an R package
  - https://kbroman.org/pkg_primer/
