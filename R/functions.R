.avatar_env <- new.env()

.time_to_sleep <- 0.5
.health_check_timeout <- 1
.default_timeout <- 5

#' Internal function - get environment variable
#' @keywords internal
#' @examples
#' \dontrun{
#' get_env("AVATAR_BASE_URL")
#' }
.get_env <- function(variable, default = "") {
  if (Sys.getenv(variable) != "") {
    return(Sys.getenv(variable))
  }

  if (default != "") {
    return(default)
  }
  stop("environment variable '", variable, "' is not set, and no default was passed")
}

#' Configure the HTTP endpoint
#'
#' @param server avatars API host
#'
#' @return Nothing
#' @export
#'
#' @examples
#' \dontrun{
#' set_server("http://localhost")
#' }
set_server <- function(server) {
  .avatar_env$server <- server
  return(healthcheck())
}

#' Authenticate
#'
#' @param username Your username
#' @param password Your password (minimum 12 characters)
#'
#' @return Nothing
#' @export
#'
#' @examples
#' \dontrun{
#' authenticate("username", "long-password-with-hyphens")
#' }
authenticate <- function(username, password) {
  res <- .do_http("POST", "/login", body = list(username = username, password = password))
  .avatar_env$token <- res$access_token
}

#' Check that the API is up and running
#'
#' @return Nothing
#' @export
#'
#' @examples
#' \dontrun{
#' healthcheck()
#' }
healthcheck <- function() {
  .do_http("GET", "/health", timeout = .health_check_timeout)
}

#' Check if client version is compatible with the API
is_client_compatible <- function() {
  r <- .do_http("GET", "/check_client", timeout = .default_timeout)
  return(r)
}

#' Internal function - get headers
#' @keywords internal
.get_headers <- function() {
  headers <- list("User-Agent" = paste0("avatar_r/", utils::packageDescription("avatar")$Version))
  if (!is.null(.avatar_env$token)) {
    headers <- c(headers, "Authorization" = paste("Bearer", .avatar_env$token))
  }

  return(headers)
}

#' Internal function - issue HTTP request
#' @keywords internal
.do_http <- function(method, endpoint, body = NULL, encode = NULL, timeout = NULL) {
  if (is.null(.avatar_env$server)) {
    stop("set_server has not been called, existing")
  }

  func <- switch(tolower(method),
    "post" = httr::POST,
    "patch" = httr::PATCH,
    httr::GET
  )

  # There should always be a timeout for all requests
  if (is.null(timeout)) {
    timeout <- httr::timeout(.default_timeout)
  } else {
    timeout <- httr::timeout(timeout)
  }

  r <- func(paste0(.avatar_env$server, endpoint),
    body = body,
    encode = encode,
    do.call(httr::add_headers, .get_headers()),
    timeout
  )

  if (r$status_code != 200) {
    stop("got error in HTTP request: ", method, " ", endpoint, " ", httr::content(r, "parsed"), call. = FALSE)
  }

  httr::content(r, "parsed")
}

#' Upload dataset to the avatarization API
#'
#' @param dataframe The original data
#'
#' @return A dataset id
#' @export
#'
#' @examples
#' \dontrun{
#' dataset_id <- upload_dataset(df)
#' }
upload_dataset <- function(dataframe) {
  csv <- readr::format_csv(dataframe)
  columns <- .get_columns(dataframe)

  r <- .do_http("POST", "/datasets/inline", body = list("file" = curl::form_data(csv, "application/csv")))
  r <- .do_http("PATCH", paste0("/datasets/", r$id), body = list("columns" = columns), encode = "json")

  return(r$id)
}

#' Start the avatarization job
#'
#' @param dataset_id An identifier for the uploaded dataset
#' @param parameters A list with avatarization parameters (see main tutorial)
#'
#' @return A job description (in particular with an id)
#' @export
#'
#' @examples
#' \dontrun{
#' start_job(dataset_id, list(k = 20))
#' start_job(dataset_id, list(k = 20, imputation = list(k = 5)))
#' start_job(dataset_id, list(k = 20, seed = 42, ncp = 3, column_weights = list("var_a" = 0.2)))
#' }
start_job <- function(dataset_id, parameters) {
  object <- list(
    parameters = append(parameters, list(dataset_id = dataset_id))
  )

  r <- .do_http(
    "POST",
    "/jobs",
    body = object,
    encode = "json"
  )

  # We repeat the returned value here for documentation purposes
  return(list(id = r$id))
}

#' Get job result given a job id (blocking until the job is done)
#'
#' It can be safely retried multiple times until the job is done.
#'
#' @param job_id The avatarization job id
#' @param timeout The time to wait for a result in seconds
#'
#' @return A list containing the job response
#' \itemize{
#'   \item{privacy_metrics}{a list containg privacy metrics, with names 'local_cloaking' and 'hidden_rate'}
#'   \item{avatars_dataset}{a list containing the avatars dataset metadata}
#' }
#' @export
#'
#' @examples
#' \dontrun{
#' get_job_result(job_id)$metrics$local_cloaking
#' }
get_job_result <- function(job_id, timeout = 10) {
  if (is.null(job_id)) {
    stop("expected valid job_id, got null instead")
  }

  n_attempts <- 0

  # total time is third item
  start_time <- proc.time()[[3]]

  while (TRUE) {
    n_attempts <- n_attempts + 1
    job_response <- .do_http("GET", paste0("/jobs/", job_id))

    if (job_response$status == "success") {
      # TODO: document this
      return(job_response$result)
    }

    if (job_response$status == "failure") {
      stop(paste0("Job failed with the following message : ", job_response$error_message))
    }

    elapsed <- proc.time()[[3]] - start_time
    if (elapsed > timeout) {
      stop(paste0(
        "timeout: did not get successful job result after ",
        elapsed,
        " seconds - this function can be safely retried.",
        " The avatarization job might still be running."
      ))
    }

    Sys.sleep(.time_to_sleep)
  }
}

#' Get a dataset given a download_url and its columns
#'
#'
#' @param download_url The url to download the dataset
#' @param columns The types to apply to the dataset
#' @param download_timeout The time to wait for the download in seconds
#'
#' @return dataset
#' @export
#'
#' @examples
#' \dontrun{
#' result <- get_job_result(job_id, timeout = get_result_timeout)
#' columns <- result$avatars_dataset$columns
#' download_url <- result$avatars_dataset$download_url
#' avatars <- get_dataset(download_url, columns)
#' }
get_dataset <- function(download_url, columns, download_timeout = 100) {
  res <- httr::GET(download_url, do.call(httr::add_headers, .get_headers()), httr::timeout(download_timeout))

  if (res$status_code != 200) {
    stop("got error in HTTP request: GET ", download_url, " ", httr::content(res, "parsed"), call. = FALSE)
  }

  # parse the CSV
  dataset <- httr::content(res, "parsed", show_col_types = FALSE)

  if (!is.null(columns)) {
    dataset <- .apply_types(dataset, columns)
  }

  return(dataset)
}

#' Get avatars as a dataframe given a job id
#'
#' The order of the lines have been shuffled, which means
#' that the link between original and avatar individuals cannot
#' be made.
#'
#' Any further processing on the server will however use
#' the same avatar dataset as the one returned here.
#'
#' @param job_id The job id for this avatarization
#' @param get_result_timeout The time to wait for the job result in seconds
#' @param download_timeout The time to wait for the download in seconds
#'
#' @return Avatars dataframe
#' @export
#'
#' @examples
#' \dontrun{
#' get_avatars(job_id)
#' }
get_avatars <- function(job_id, get_result_timeout = 10, download_timeout = 100) {
  if (is.null(job_id)) {
    stop("expected valid job_id, got null instead")
  }

  result <- get_job_result(job_id, timeout = get_result_timeout)

  columns <- result$avatars_dataset$columns
  the_url <- result$avatars_dataset$download_url

  avatars <- get_dataset(the_url, columns, download_timeout)

  return(avatars)
}

#' Get contributions of the dataset variables within the fitted space
#'
#' @param job_id The job id for this avatarization
#' @param dataset_id An identifier for the uploaded dataset
#'
#' @return contributions dataframe
#' @export
#'
#' @examples
#' \dontrun{
#' get_variable_contributions(job_id, dataset_id) # for original dataset
#' get_variable_contributions(job_id, job_result$avatars_dataset$id) # for avatars dataset
#' }
get_variable_contributions <- function(job_id, dataset_id) {
  if (is.null(job_id)) {
    stop("expected valid job_id, got null instead")
  }

  if (is.null(dataset_id)) {
    stop("expected valid dataset_id, got null instead")
  }

  endpoint <- paste0("/contributions?job_id=", job_id, "&dataset_id=", dataset_id)

  response <- .do_http("GET", endpoint)

  contributions <- as.data.frame(do.call(cbind, response$data))
  # Convert column to numeric type
  for (i in seq_len(ncol(contributions))) {
    contributions[[i]] <- as.numeric(contributions[[i]])
  }

  return(contributions)
}

#' Get projections of the original and avatars in original space.
#'
#' @param job_id The job id for this avatarization
#'
#' @return named list of original and avatar projection dataframes
#' @export
#'
#' @examples
#' \dontrun{
#' get_projections(job_id)
#' }
get_projections <- function(job_id) {
  if (is.null(job_id)) {
    stop("expected valid job_id, got null instead")
  }

  response <- .do_http("GET", paste0("/projections/", job_id))
  original_projections <- as.data.frame(do.call(rbind, response$records))
  avatar_projections <- as.data.frame(do.call(rbind, response$avatars))

  return(list(original = original_projections, avatars = avatar_projections))
}

#' Get explained variance of the original records.
#'
#' @param job_id The job id for this avatarization
#'
#' @return named list of the explained variance and the ratio
#' @export
#'
#' @examples
#' \dontrun{
#' get_explained_variance(job_id)
#' }
get_explained_variance <- function(job_id) {
  if (is.null(job_id)) {
    stop("expected valid job_id, got null instead")
  }

  response <- .do_http("GET", paste0("/variance/", job_id))

  explained_variance <- as.data.frame(do.call(cbind, response$raw))
  explained_variance_ratio <- as.data.frame(do.call(cbind, response$ratio))
  return(list(explained_variance = explained_variance, explained_variance_ratio = explained_variance_ratio))
}


#' Create a user
#'
#' @param username The user's name
#' @param password The user's password
#'
#' @return Nothing
#' @export
#'
#' @examples
#' \dontrun{
#' create_user("username", "the-password")
#' }
create_user <- function(username, password) {
  .do_http("POST", "/users", body = list(username = username, password = password), encode = "json")
}

#' Request a password reset
#'
#' @param email The user's email
#'
#' @return Nothing
#' @export
#'
#' @examples
#' \dontrun{
#' forgotten_password("my.email@octopize.io")
#' }
forgotten_password <- function(email) {
  endpoint <- "/login/forgotten_password"
  response <- .do_http("POST", endpoint, body = list(email = email), encode = "json")

  print(response$message)
}

#' Reset the password of an account
#'
#' @param email The user's email
#' @param new_password The new password
#' @param new_password_repeated The new password repeated
#' @param token A token received on the email of the account
#'
#' @return Nothing
#' @export
#'
#' @examples
#' \dontrun{
#' reset_password(
#'   email = "my.email@octopize.io",
#'   new_password = "b43b233a5e602b5a52ecab67cdf8",
#'   new_password_repeated = "b43b233a5e602b5a52ecab67cdf8",
#'   token = "8c85cf5a-809f-4b27-ba10-2495d5cfda5a"
#' )
#' }
reset_password <- function(email, new_password, new_password_repeated, token) {
  endpoint <- "/login/reset_password"

  response <- .do_http("POST", endpoint,
    body =
      list(
        email = email,
        new_password = new_password,
        new_password_repeated = new_password_repeated,
        token = token
      ),
    encode = "json"
  )

  print(paste0(response$message))
}
