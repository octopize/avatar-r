SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

PKGNAME := $(shell sed -n "s/Package: *\([^ ]*\)/\1/p" DESCRIPTION)
PKGVERS := $(shell sed -n "s/Version: *\([^ ]*\)/\1/p" DESCRIPTION)
PKG_BUILT := $(PKGNAME)_$(PKGVERS).tar.gz
PKGSRC  := $(shell basename `pwd`)
R := R --no-save --no-restore

build: docs build/r_tutorial.md  ## Build the R package
	cd ..;\
	${R} CMD build $(PKGSRC)
.PHONY: build

docs:  ## Build documentation
	Rscript -e 'devtools::document()'
.PHONY: docs

build/r_tutorial.md: vignettes/tutorial.Rmd  ## Generate for public-docs
	-mkdir -p build/
	Rscript -e "rmarkdown::render('$<', output_format=rmarkdown::github_document(), output_file='../$@')"
.PHONY: build/r_tutorial.md

tutorial-open: install-package  ## Open vignette tutorial
	Rscript -e 'browseVignettes(package="avatar"); Sys.sleep(24 * 3600)'
.PHONY: tutorial-open

check-build:  ## Check the built package
	cd ..;\
	${R} CMD check $(PKG_BUILT)
.PHONY: check-build

install:  ## Install the deps
	echo "Installing dev packages"
	Rscript -e 'install.packages(c("devtools", "roxygen2", "testthat", "knitr", "rmarkdown", "prettydoc", "styler", "lintr"), repos="https://cloud.r-project.org")'
	echo "Installing direct dependencies"
	Rscript -e 'install.packages(c("tibble", "magrittr", "httr"), repos="https://cloud.r-project.org")'
	echo "Installing optional tutorial packages"
	Rscript -e 'install.packages(c("dplyr", "ade4", "ggplot2", "plotly", "gridExtra", "corrplot"), repos="https://cloud.r-project.org")'
.PHONY: install

install-package:   ## Install the current version
	@# We need to use a custom script because Rscript does return non-0 exit code on failure
	./bin/install_avatar.R ../$(PKG_BUILT)
.PHONY: install-package

##@ Tests

test: ## Run tests
	Rscript -e 'devtools::test()'
.PHONY: test

test-integration: ## Run integration tests
	Rscript integration_test/run_simple.R
.PHONY: integration-test

ci: lint test build check-build test-integration  ## Run all tests
.PHONY: ci

lci: lint-fix ci ## Run all tests
.PHONY: lci

# lintr requires a version of the package to be installed
lint: install-package  ## Lint code
	Rscript -e "lintr::lint_package(commandArgs(trailingOnly = TRUE))" .
.PHONY: lint

lint-fix:  ## Format code
	Rscript -e 'library("styler"); style_dir(".")'
.PHONY: lint-fix

.DEFAULT_GOAL := help
help: Makefile
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[\/\.a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
