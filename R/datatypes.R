#' Internal function - get column types for a data frame
#' @keywords internal
.get_columns <- function(dataframe) {
  # We need to send the column types so that we can parse the avatar CSV with the proper R types
  columns <- lapply(names(dataframe), function(name) {
    return(list(
      label = name,
      type = .r_to_common_types(class(dataframe[[name]]))
    ))
  })
  return(columns)
}

#' Internal function - apply column types to dataframe
#' @keywords internal
.apply_types <- function(dataframe, columns) {
  for (i in seq_len(ncol(dataframe))) {
    r_class <- .common_to_r_class(columns[[i]]$type)

    if (r_class == "logical") {
      dataframe[[i]] <- as.logical(dataframe[[i]])
    } else if (r_class == "factor") {
      dataframe[[i]] <- as.factor(dataframe[[i]])
    }
  }

  return(dataframe)
}

#' Internal function - return abstract type from R type
#' @keywords internal
.r_to_common_types <- function(r_class) {
  if (r_class == "numeric") {
    return("float")
  }
  if (r_class == "integer") {
    return("int")
  }
  if (r_class == "logical") {
    return("bool")
  }
  if (r_class == "character" || r_class == "factor") {
    return("category")
  }

  stop(paste0("Unable to get abstract type from type ", r_class))
}

#' Internal function - return R type from abstract type
#' @keywords internal
.common_to_r_class <- function(common_type) {
  if (common_type == "float" || common_type == "int") {
    return("numeric")
  }
  if (common_type == "category") {
    return("factor")
  }
  if (common_type == "boolean") {
    return("logical")
  }

  stop(paste0("Unable to get R type from abstract type ", common_type))
}
