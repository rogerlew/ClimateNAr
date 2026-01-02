library(RestRserve)

source("/srv/app/helpers.R")

app <- Application$new(content_type = "application/json")

app$add_get("/v1/health", function(request, response) {
  list(status = "ok", version = "v1")
})

app$add_get("/v1/models", function(request, response) {
  refresh <- tolower(.get_query_param(request, "refresh", "false")) == "true"
  models <- .list_models(refresh = refresh)

  type <- .get_query_param(request, "type")
  scenario <- .get_query_param(request, "scenario")
  model <- .get_query_param(request, "model")

  if (!is.null(type)) {
    models <- Filter(function(x) x$type == type, models)
  }
  if (!is.null(scenario)) {
    models <- Filter(function(x) !is.na(x$scenario) && x$scenario == scenario, models)
  }
  if (!is.null(model)) {
    models <- Filter(function(x) x$model == model, models)
  }

  list(count = length(models), models = models)
})

app$add_post("/v1/monthly", function(request, response) {
  period <- .get_query_param(request, "period", "Normal_1961_1990.nrm")
  format <- tolower(.get_query_param(request, "format", "json"))

  models <- .list_models()
  model_ids <- vapply(models, function(x) x$id, character(1))
  if (!period %in% model_ids) {
    return(.handle_error(response, 404, "unknown_period", "period is not available."))
  }

  max_rows <- as.integer(Sys.getenv("MAX_ROWS", "10000"))

  df <- tryCatch({
    .read_csv_body(request)
  }, error = function(e) {
    return(.handle_error(response, 400, "invalid_input", conditionMessage(e)))
  })
  if (inherits(df, "list") && !is.data.frame(df)) {
    return(df)
  }

  df <- tryCatch({
    .validate_locations(df)
  }, error = function(e) {
    return(.handle_error(response, 400, "invalid_input", conditionMessage(e)))
  })
  if (inherits(df, "list") && !is.data.frame(df)) {
    return(df)
  }

  if (nrow(df) > max_rows) {
    return(.handle_error(response, 413, "too_many_rows", "row limit exceeded"))
  }

  prep <- tryCatch({
    .prepare_locations(df)
  }, error = function(e) {
    return(.handle_error(response, 400, "invalid_input", conditionMessage(e)))
  })
  if (inherits(prep, "list") && !is.data.frame(prep$data)) {
    return(prep)
  }

  result <- tryCatch({
    .run_climatenar_monthly(prep$data, period)
  }, error = function(e) {
    return(.handle_error(response, 500, "internal_error", conditionMessage(e)))
  })
  if (inherits(result, "list") && !is.data.frame(result)) {
    return(result)
  }

  if (prep$trim < nrow(result)) {
    result <- result[seq_len(prep$trim), , drop = FALSE]
  }

  month_map <- tryCatch({
    .extract_monthly_arrays(result)
  }, error = function(e) {
    return(.handle_error(response, 500, "internal_error", conditionMessage(e)))
  })
  if (inherits(month_map, "list") && !is.null(month_map$error)) {
    return(month_map)
  }

  if (format == "csv") {
    csv_df <- .format_csv_output(result, period, month_map)
    response$set_content_type("text/csv")
    return(.to_csv_text(csv_df))
  }

  .format_json_output(result, period, month_map)
})

port <- as.integer(Sys.getenv("PORT", "8000"))
app$run(host = "0.0.0.0", port = port)
