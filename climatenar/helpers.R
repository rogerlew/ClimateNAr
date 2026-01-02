library(ClimateNAr)
library(data.table)
library(readr)

`%||%` <- function(a, b) {
  if (!is.null(a)) {
    return(a)
  }
  b
}

.get_data_dir <- function() {
  system.file("data", package = "ClimateNAr")
}

.model_cache <- new.env(parent = emptyenv())

.build_model_id <- function(rel_path) {
  rel_path <- gsub("\\\\", "/", rel_path)
  parts <- strsplit(rel_path, "/", fixed = TRUE)[[1]]
  if (length(parts) >= 4 && parts[1] == "GCMs" && parts[2] == "Annual") {
    scenario <- parts[3]
    year <- sub("\\.gcm\\.rda$", "", parts[4])
    return(paste0(scenario, "_", year))
  }
  sub("\\.rda$", "", basename(rel_path))
}

.parse_model_info <- function(model_id) {
  type <- "unknown"
  scenario <- NA_character_
  model <- "historical"

  if (grepl("^Normal_", model_id)) {
    type <- "normal"
  } else if (grepl("^Year_", model_id)) {
    type <- "annual"
  } else if (grepl("^Decade_", model_id)) {
    type <- "decadal"
  }

  if (grepl("_ssp[0-9]{3}", model_id)) {
    scenario <- sub(".*_ssp([0-9]{3}).*", "ssp\\1", model_id)
    model <- sub("_ssp[0-9]{3}.*$", "", model_id)

    if (grepl("ensemble", model, ignore.case = TRUE) ||
        grepl("^8GCM", model, ignore.case = TRUE) ||
        grepl("^13GCM", model, ignore.case = TRUE)) {
      type <- "ensemble"
    } else {
      type <- "gcm"
    }
  }

  label <- gsub("_", " ", model_id)
  label <- gsub("\\.", " ", label)

  list(
    id = model_id,
    type = type,
    model = model,
    scenario = scenario,
    label = label
  )
}

.list_models <- function(refresh = FALSE) {
  if (!refresh && exists("models", envir = .model_cache)) {
    return(get("models", envir = .model_cache))
  }

  data_dir <- .get_data_dir()
  if (!nzchar(data_dir)) {
    stop("ClimateNAr data directory not found.")
  }

  files <- list.files(data_dir, recursive = TRUE, pattern = "\\.rda$", full.names = TRUE)
  rel_paths <- sub(paste0(normalizePath(data_dir, winslash = "/"), "/"), "", files)
  model_ids <- vapply(rel_paths, .build_model_id, character(1))
  model_ids <- unique(model_ids)

  models <- lapply(model_ids, .parse_model_info)
  assign("models", models, envir = .model_cache)
  models
}

.get_query_param <- function(request, key, default = NULL) {
  # Try RestRserve's get_param_query method first
  val <- tryCatch(request$get_param_query(key), error = function(e) NULL)
  if (!is.null(val)) return(val)

  # Fallback to parameters_query list
  if (!is.null(request$parameters_query) && !is.null(request$parameters_query[[key]])) {
    return(request$parameters_query[[key]])
  }

  default
}

.read_csv_body <- function(request) {
  body <- request$body
  if (is.raw(body)) {
    csv_text <- rawToChar(body)
  } else if (is.character(body) && length(body) == 1) {
    csv_text <- body
  } else {
    stop("Unsupported request body; expected text/csv.")
  }

  readr::read_csv(I(csv_text), show_col_types = FALSE, progress = FALSE)
}

.validate_locations <- function(df) {
  required <- c("ID1", "ID2", "lat", "lon", "elev")
  names_lower <- tolower(names(df))
  idx <- match(tolower(required), names_lower)
  if (any(is.na(idx))) {
    missing <- required[is.na(idx)]
    stop(paste("Missing required columns:", paste(missing, collapse = ", ")))
  }

  df <- df[, idx, drop = FALSE]
  names(df) <- required

  df$lat <- as.numeric(df$lat)
  df$lon <- as.numeric(df$lon)
  df$elev <- as.numeric(df$elev)

  if (any(is.na(df$lat)) || any(is.na(df$lon)) || any(is.na(df$elev))) {
    stop("lat, lon, elev must be numeric.")
  }
  if (any(df$lat < -90 | df$lat > 90)) {
    stop("lat must be between -90 and 90.")
  }
  if (any(df$lon < -180 | df$lon > 180)) {
    stop("lon must be between -180 and 180.")
  }

  df
}

.prepare_locations <- function(df) {
  if (nrow(df) < 1) {
    stop("CSV must include at least one data row.")
  }
  if (nrow(df) == 1) {
    df <- rbind(df, df)
    return(list(data = df, trim = 1))
  }
  list(data = df, trim = nrow(df))
}

.run_climatenar_monthly <- function(df, period) {
  tmp_dir <- tempdir()
  out_dir <- paste0(normalizePath(tmp_dir), "/")
  input_file <- file.path(tmp_dir, "locations.csv")
  readr::write_csv(df, input_file)

  result <- ClimateNAr(input_file, periodList = period, varList = "M", outDir = out_dir)
  if (is.matrix(result) || is.array(result)) {
    result <- as.data.frame(result)
  }

  # ClimateNAr may write output to CSV files - prefer reading those
  out_files <- list.files(tmp_dir, pattern = "\\.csv$", full.names = TRUE)
  out_files <- out_files[normalizePath(out_files) != normalizePath(input_file)]

  if (length(out_files) > 0) {
    out_file <- out_files[which.max(file.info(out_files)$mtime)]
    return(readr::read_csv(out_file, show_col_types = FALSE, progress = FALSE))
  }

  if (is.data.frame(result) && "Tmin01" %in% names(result)) {
    return(result)
  }

  stop("ClimateNAr returned no output files.")
}

.order_month_cols <- function(cols) {
  month <- as.integer(sub(".*?([0-1][0-9])$", "\\1", cols))
  cols[order(month)]
}

.extract_monthly_arrays <- function(df) {
  tmin_cols <- grep("^(Tmin|TMIN|tmin)[0-1][0-9]$", names(df), value = TRUE)
  tmax_cols <- grep("^(Tmax|TMAX|tmax)[0-1][0-9]$", names(df), value = TRUE)
  ppt_cols <- grep("^(PPT|ppt|Precip|precip)[0-1][0-9]$", names(df), value = TRUE)

  tmin_cols <- .order_month_cols(tmin_cols)
  tmax_cols <- .order_month_cols(tmax_cols)
  ppt_cols <- .order_month_cols(ppt_cols)

  if (length(tmin_cols) != 12 || length(tmax_cols) != 12 || length(ppt_cols) != 12) {
    stop(paste(
      "Monthly columns not found. Available columns:",
      paste(names(df), collapse = ", ")
    ))
  }

  list(
    tmin_cols = tmin_cols,
    tmax_cols = tmax_cols,
    ppt_cols = ppt_cols
  )
}

.format_csv_output <- function(df, period, month_map) {
  result <- df[, c("ID1", "ID2", "lat", "lon", "elev"), drop = FALSE]
  result$period <- period

  for (i in seq_along(month_map$tmin_cols)) {
    result[[sprintf("tmin_%02d_c", i)]] <- df[[month_map$tmin_cols[i]]]
    result[[sprintf("tmax_%02d_c", i)]] <- df[[month_map$tmax_cols[i]]]
    result[[sprintf("precip_%02d_mm", i)]] <- df[[month_map$ppt_cols[i]]]
  }

  result
}

.format_json_output <- function(df, period, month_map) {
  results <- vector("list", nrow(df))
  for (i in seq_len(nrow(df))) {
    results[[i]] <- list(
      id1 = as.character(df$ID1[i]),
      id2 = as.character(df$ID2[i]),
      lat = df$lat[i],
      lon = df$lon[i],
      elev_m = df$elev[i],
      tmin_c = as.numeric(df[i, month_map$tmin_cols]),
      tmax_c = as.numeric(df[i, month_map$tmax_cols]),
      precip_mm = as.numeric(df[i, month_map$ppt_cols])
    )
  }

  list(
    period = period,
    units = list(tmin = "C", tmax = "C", precip = "mm"),
    results = results
  )
}

.to_csv_text <- function(df) {
  lines <- character()
  con <- textConnection("lines", open = "w", local = TRUE)
  on.exit(close(con), add = TRUE)
  write.csv(df, con, row.names = FALSE)
  paste(lines, collapse = "\n")
}

.handle_error <- function(response, status, code, message, details = list()) {
  response$set_status_code(status)
  response$set_body(list(error = list(code = code, message = message, details = details)))
  invisible(NULL)
}
