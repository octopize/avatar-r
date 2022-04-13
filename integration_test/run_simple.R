library(devtools)
devtools::load_all()

print("starting integration test")
httr::set_config(httr::config(ssl_verifypeer = 0L))
set_server("http://localhost:8000")

authenticate("user_integration", "password_integration")

dataset_id <- avatar::upload_dataset(iris)

parameters <- list(k = 20)

job <- avatar::start_job(dataset_id, parameters)
print(paste0("got job id: ", job$id))

avatars <- avatar::get_avatars(job$id)
print("got avatars")
head(avatars)

result <- avatar::get_job_result(job$id)
print("local_cloaking")
print(result$metrics$local_cloaking)
print("hidden_rate")
print(result$metrics$hidden_rate)

print("success")
