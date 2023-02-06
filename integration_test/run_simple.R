library(devtools)
devtools::load_all()

print("starting integration test")

username <- .get_env("AVATAR_USERNAME")
password <- .get_env("AVATAR_PASSWORD")
base_url <- .get_env("AVATAR_BASE_URL")

httr::set_config(httr::config(ssl_verifypeer = 0L))

set_server(base_url)
authenticate(username, password)

dataset_id <- avatar::upload_dataset(iris)

parameters <- list(k = 20, imputation = list(k = 5))

job <- avatar::start_job(dataset_id, parameters)
print(paste0("got job id: ", job$id))

avatars <- avatar::get_avatars(job$id)
print("got avatars")
head(avatars)

result <- avatar::get_job_result(job$id)
print("local_cloaking")
print(result$privacy_metrics$local_cloaking)
print("hidden_rate")
print(result$privacy_metrics$hidden_rate)

print("success")
