library(ClimateNAr)
library(readr)

input <- data.frame(
  ID1 = c("siteA", "siteB"),
  ID2 = c("1", "2"),
  lat = c(48.98, 49.25),
  lon = c(-115.02, -115.10),
  elev = c(1000, 900)
)

period <- "Normal_1961_1990.nrm"

out_dir <- "/srv/app/out/"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

input_file <- file.path(out_dir, "locations.csv")
readr::write_csv(input, input_file)

result <- ClimateNAr(input_file, periodList = period, varList = "M", outDir = out_dir)

cat("ClimateNAr return class:", paste(class(result), collapse = ", "), "\n")

if (is.matrix(result) || is.array(result)) {
  result <- as.data.frame(result)
}

out_files <- list.files(out_dir, full.names = TRUE)
cat("Output directory contents:\n")
print(out_files)

csv_files <- list.files(out_dir, pattern = "\\.csv$", full.names = TRUE)
csv_files <- csv_files[normalizePath(csv_files) != normalizePath(input_file)]

if (!is.data.frame(result) || length(csv_files) > 0) {
  if (length(csv_files) == 0) {
    stop("No output CSV produced by ClimateNAr.")
  }
  out_file <- csv_files[which.max(file.info(csv_files)$mtime)]
  result <- readr::read_csv(out_file, show_col_types = FALSE, progress = FALSE)
}

cat("Monthly output columns:\n")
print(names(result))

output_path <- "/srv/app/smoke_output.csv"
write.csv(result, output_path, row.names = FALSE)
cat("Wrote sample output to:", output_path, "\n")
