library(RestRserve)

source("/srv/app/helpers.R")

# Configure content type handlers to accept text/csv
encode_decode_mw <- EncodeDecodeMiddleware$new()
encode_decode_mw$ContentHandlers$set_decode("text/csv", identity)
encode_decode_mw$ContentHandlers$set_encode("text/csv", identity)

app <- Application$new(content_type = "application/json", middleware = list(encode_decode_mw))

app$add_get("/v1/health", function(request, response) {
  response$set_body(list(status = "ok", version = "v1"))
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

  response$set_body(list(count = length(models), models = models))
})

app$add_post("/v1/monthly", function(request, response) {
  period <- .get_query_param(request, "period", "Normal_1961_1990.nrm")
  format <- tolower(.get_query_param(request, "format", "json"))

  models <- .list_models()
  model_ids <- vapply(models, function(x) x$id, character(1))
  if (!period %in% model_ids) {
    .handle_error(response, 404, "unknown_period", "period is not available.")
    return()
  }

  max_rows <- as.integer(Sys.getenv("MAX_ROWS", "10000"))

  df <- tryCatch({
    .read_csv_body(request)
  }, error = function(e) {
    .handle_error(response, 400, "invalid_input", conditionMessage(e))
    NULL
  })
  if (is.null(df)) return()

  df <- tryCatch({
    .validate_locations(df)
  }, error = function(e) {
    .handle_error(response, 400, "invalid_input", conditionMessage(e))
    NULL
  })
  if (is.null(df)) return()

  if (nrow(df) > max_rows) {
    .handle_error(response, 413, "too_many_rows", "row limit exceeded")
    return()
  }

  prep <- tryCatch({
    .prepare_locations(df)
  }, error = function(e) {
    .handle_error(response, 400, "invalid_input", conditionMessage(e))
    NULL
  })
  if (is.null(prep)) return()

  result <- tryCatch({
    .run_climatenar_monthly(prep$data, period)
  }, error = function(e) {
    .handle_error(response, 500, "internal_error", conditionMessage(e))
    NULL
  })
  if (is.null(result)) return()

  if (prep$trim < nrow(result)) {
    result <- result[seq_len(prep$trim), , drop = FALSE]
  }

  month_map <- tryCatch({
    .extract_monthly_arrays(result)
  }, error = function(e) {
    .handle_error(response, 500, "internal_error", conditionMessage(e))
    NULL
  })
  if (is.null(month_map)) return()

  if (format == "csv") {
    csv_df <- .format_csv_output(result, period, month_map)
    response$set_content_type("text/csv")
    response$set_body(.to_csv_text(csv_df))
    return()
  }

  response$set_body(.format_json_output(result, period, month_map))
})

port <- as.integer(Sys.getenv("PORT", "8000"))
backend <- BackendRserve$new()
backend$start(app, http_port = port)
