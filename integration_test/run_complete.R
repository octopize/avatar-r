#!/usr/bin/env Rscript

# Integration test running all of our methods
library(devtools)
devtools::load_all()

username <- .get_env("AVATAR_USERNAME")
password <- .get_env("AVATAR_PASSWORD")
base_url <- .get_env("AVATAR_BASE_URL")

print("starting complete integration test")
httr::set_config(httr::config(ssl_verifypeer = 0L))


set_server(base_url)
authenticate(username, password)

run_single <- function(df, label) {
  dataset_id <- avatar::upload_dataset(df)
  head(mtcars)
  parameters <- list(k = 20, ncp = 4)

  job <- avatar::start_job(dataset_id, parameters)
  avatars <- avatar::get_avatars(job$id, get_result_timeout = 50)
  result <- avatar::get_job_result(job$id, timeout = 50)

  # Download the unshuffled dataset
  columns <- result$sensitive_unshuffled_avatars_datasets$columns
  download_url <- result$sensitive_unshuffled_avatars_datasets$download_url
  sensitive_unshuffled_avatars <- get_dataset(download_url, columns)
  print(sensitive_unshuffled_avatars)

  # Get metrics of the avatarization
  res <- get_variable_contributions(job$id)
  res <- get_projections(job$id)
  res <- get_explained_variance(job$id)

  print(paste0("######## ", label, " ########"))
  print(paste0("local_cloaking : ", result$privacy_metrics$local_cloaking))
  print(paste0("hidden_rate : ", result$privacy_metrics$hidden_rate))
  print("success")
}

# PCA
df <- as.data.frame(mtcars)
run_single(df, "PCA")

# FAMD
df <- as.data.frame(mtcars)
df$vs <- as.factor(df$vs)
df$am <- as.factor(df$am)
df$gear <- as.factor(df$gear)
df$carb <- as.factor(df$carb)
run_single(df, "FAMD")

# MCA
df <- as.data.frame(mtcars[, c("vs", "am", "gear", "carb")])
df$vs <- as.factor(df$vs)
df$am <- as.factor(df$am)
df$gear <- as.factor(df$gear)
df$carb <- as.factor(df$carb)
run_single(df, "MCA")
