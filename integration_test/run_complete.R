# Integration test running all of our methods

library(devtools)
devtools::load_all()

print("starting complete integration test")
httr::set_config(httr::config(ssl_verifypeer = 0L))
set_server("http://localhost:8000")
authenticate("user_integration", "password_integration")

run_single <- function(df, label) {
  dataset_id <- avatar::upload_dataset(df)
  head(mtcars)
  parameters <- list(k = 20, ncp = 4, imputation = list(k = 5))

  job <- avatar::start_job(dataset_id, parameters)
  avatars <- avatar::get_avatars(job$id)
  result <- avatar::get_job_result(job$id)
  res <- get_variable_contributions(job$id, dataset_id)
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
