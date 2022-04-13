library(avatar)

test_that("get_columns returns the right types for iris columns", {
  expected <- list(
    list(label = "Sepal.Length", type = "float"),
    list(label = "Sepal.Width", type = "float"),
    list(label = "Petal.Length", type = "float"),
    list(label = "Petal.Width", type = "float"),
    list(label = "Species", type = "category")
  )
  expect_equal(.get_columns(iris), expected)
})

test_that("get_columns returns the right types for mtcars columns", {
  df <- data.frame(mtcars)
  df$am <- as.factor(df$am)
  df$gear <- as.integer(df$gear)
  expected <- list(
    list(label = "mpg", type = "float"),
    list(label = "cyl", type = "float"),
    list(label = "disp", type = "float"),
    list(label = "hp", type = "float"),
    list(label = "drat", type = "float"),
    list(label = "wt", type = "float"),
    list(label = "qsec", type = "float"),
    list(label = "vs", type = "float"),
    list(label = "am", type = "category"),
    list(label = "gear", type = "int"),
    list(label = "carb", type = "float")
  )
  expect_equal(.get_columns(df), expected)

  # Ensure we can apply types without exceptions
  .apply_types(df, expected)
})
