#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

print(paste("Installing", args[1]))
install.packages(args[1], repos = NULL, type = "source")
if (!library("avatar", character.only = TRUE, logical.return = TRUE)) {
  quit(status = 1, save = "no")
}
