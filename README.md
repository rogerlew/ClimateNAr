# ClimateNAr

**ClimateNAr** is the R version of ClimateNA, a software package designed to provide high-resolution climate data for North America. This version is optimized for performance and flexibility in R environments.

## Overview

The R version of ClimateNA offers several advantages:
1.  **High Performance:** Runs significantly faster for large datasets (typically >5 times faster).
2.  **Modern Format Support:** Support for DEM rasters in TIFF format.
3.  **Customization:** Output variables can be fully customized.
4.  **Extended Functionality:** Includes functions for raster stacking, API access, desktop command-line integration, and variable scanning.

## Key Functions

*   **ClimateNAr:** Main function for climate data downscaling.
*   **ClimateNA_cmdLine:** Access ClimateNA through command-line interface.
*   **ClimateNA_API / ClimateNA_API2:** Access climate data via API.
*   **rasterDownload:** Tools for downloading climate rasters.
*   **rasterStack:** Functionality for stacking raster layers.
*   **tifToAsc:** Convert TIFF files to ASCII format.
*   **varScan:** Identify optimal climate variables for predictive modeling.

## Installation

Since ClimateNAr is not hosted on CRAN, you can install it locally using one of the following methods:

### Method 1: Using R Code
```r
install.packages('path/to/ClimateNAr.zip', repos=NULL)
```

### Method 2: Through RStudio
Go to **Tools** > **Install Packages** > **Install from:** Package Archive Files (.zip; .tar.gz).

### Method 3: Manual Installation
Unzip the `ClimateNAr.zip` file directly into your R library folder.

## System Requirements
*   **R:** Version 4.4.2 or higher.
*   **Dependencies:** `data.table`, `terra`, `readr`.
*   **ClimateBC or ClimateNA:** Must be installed for CMD Line access.

## License and Attribution

This software is licensed under the **Creative Commons Attribution (CC-BY)** license.

### Attribution
*   **Author:** Tongli Wang (Tongli.Wang@ubc.ca)
*   **Source:** [https://climatena.ca/](https://climatena.ca/)
*   **Maintenance:** [University of British Columbia](https://www.ubc.ca/)

When using this package, please attribute the work to Tongli Wang and the ClimateNA project.

---
*This repository was created to host the ClimateNAr package obtained from [climatena.ca](https://climatena.ca/).*
