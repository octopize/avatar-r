#!/usr/bin/env Rscript

library(devtools)
devtools::load_all()

timeout <- 3600

args <- commandArgs(trailingOnly = TRUE)

httr::set_config(httr::config(ssl_verifypeer = 0L))
set_server("http://localhost:8000")

authenticate("user_integration", "password_integration")

run_test <- function(filename) {
  print("starting integration test")

  dataset <- read.csv(filename, header = TRUE)
  print("read CSV")
  dataset_id <- avatar::upload_dataset(dataset)
  print("uploaded CSV")

  parameters <- list(k = 20)

  job <- avatar::start_job(dataset_id, parameters)
  print(paste0("got job id: ", job$id))

  avatars <- avatar::get_avatars(job$id, timeout = timeout)
  print("got avatars")
  head(avatars)

  result <- avatar::get_job_result(job$id, timeout = timeout)
  print("local_cloaking")
  print(result$metrics$local_cloaking)
  print("hidden_rate")
  print(result$metrics$hidden_rate)

  print("success")
}

run_test(args[1])
