# Package ‘ClimateNAr’

**Version:** 3.1.0  
**Date:** April 25, 2025  
**Title:** The R version of ClimateNA and some related functions  
**Author:** Tongli Wang <Tongli.Wang@ubc.ca>  
**Maintainer:** Tongli Wang <Tongli.Wang@ubc.ca>  
**URL:** https://climatena.ca/downloads/ClimateNAr.zip  
**System Requirements:** R 4.4.2 or higher (package built with R 4.4.2)  

## Description
The R version of ClimateNA has the following advantages:
1. Runs faster for big datasets (>5 times);
2. Can use DEM raster in TIFF format;
3. The output variables can be customized.

Several related functions are included, such as raster stacking, API version access, desktop CMDline, and variable scanning.

**System Requirements:** ClimateBC or ClimateNA installed for CMD Line access.

---

## R topics documented
* [Package installation](#package-installation)
* [ClimateNAr](#climatenar)
* [ClimateNA_cmdLine](#climatenacmdline)
* [ClimateNA_API](#climatenaapi)
* [ClimateNA_API2](#climatenaapi2)
* [rasterDownload](#rasterdownload)
* [rasterStack](#rasterstack)
* [tifToAsc](#tiftoasc)
* [varScan](#varscan)

---

## Package installation

The ClimateNAr R package is not registered in CRAN. It needs to be downloaded and installed locally. The package can be installed locally in one of the three options:

1.  **Through R console interface:** Packages => Install package(s) from local files.
2.  **Through RStudio:** Tools => Install Packages => Install from: Package Archive Files (.zip; .tar.gz)
3.  **Through R code:** `install.packages('path/ClimateNAr.zip', repos=NULL)`.
    For example:
    ```r
    install.packages('C:/temp/ClimateNAr.zip', repos=NULL)
    ```
4.  Simply unzip `ClimateNAr.zip` to the R library folder on your computer.

---

## R Functions

### ClimateNAr

**Description**
`ClimateNAr` is an R version of ClimateNA that generates scale-free climate data for historical and future periods. The input file can be a CSV file (or a data frame) or a DEM raster file (either in TIFF or ASCII format) in latitude and longitude projection. The output variables can be customized. A full list of the climate variables can be found on the [ClimateNA website](http://climatena.ca). `ClimateNAr` runs much faster but uses much more memory (RAM) than the desktop version. Thus, the size of the input file, which can be processed, depends on the size of your computer's memory.

**Usage**
```r
ClimateNAr(inputFile, periodList, varList, outDir)
```

**Arguments**
*   `inputFile`: The full name of the input file. It can be either in CSV or raster (.tif or .asc) format. The raster must be in latitude-longitude projection (WGS84). The inputFile can also be a data frame. A CSV file or a data frame must have five columns in the following order: ID1, ID2, lat, lon, and elevation in the given order.
*   `periodList`: A list of periods to generate climate variables. It can be a single period or a list of periods. They can be either historical or future, such as `periodList=c('Normal_1961_1990.nrm','Year_1902.ann','8GCMs_ensemble_ssp245_2041-2070.gcm')`. The periodList can also be a range, such as, `periodList=1941:1965` between 1941-1965. The periodList can be `periodList= '8GCM_ssp245_2031'` or `periodList= '8GCM_ssp245_2031:2041'`.
*   `varList`: A list of climate variables to generate, for example, `varList=c('MAT','MAP')`; or `varList='Y'` ('S' or 'M') for all annual variables (all seasonal or monthly variables), or `varList='YS'` for both annual and seasonal variables, `varList='YSM'` for all variables.
*   `outDir`: The folder to save the output files.

> [!IMPORTANT]
> **Requirement:** The input data (CSV or data frame) **must contain at least 2 rows**. If only 1 row is provided, the function will fail with the error: `object 'input_valid' not found`.

**Examples**
```r
library(ClimateNAr)

# using a CSV input file
inputFile = 'C:/temp/test.csv'
varList=c('MAT','MAP','DD5','Tmax_sm','Tmax01') # or varList='YS'
periodList=c('Normal_1961_1990.nrm','Year_1902.ann','8GCMs_ensemble_ssp245_2041-2070.gcm')
outDir= 'C:/temp/'
test <- ClimateNAr(inputFile,periodList,varList,outDir); test

# using a TIFF or ASCII DEM raster file
inputFile = 'C:/temp/na20k.tif'
varList=c('MAT','MAP','DD5','Tmax_sm','Tmax01') # or varList='YS'
periodList=c('Normal_1961_1990.nrm','Year_1902.ann','8GCMs_ensemble_ssp245_2041-2070.gcm')
outDir= 'C:/temp/'
test <- ClimateNAr(inputFile,periodList,varList,outDir); test
```

### ClimateNA_cmdLine

**Description**
`ClimateNA_cmdLine` is to run ClimateBC or ClimateNA using CMD Line feature in R, which allows integrating the climate models into a programming workflow. It can use most of the features of ClimateBC/NA. In addition, if this function is used to generate climate data in raster format (.asc), it also converts the .asc files into georeferenced .tif files with lat/lon projection (WGS84) and reduces the file size substantially.

**Usage**
```r
ClimateNA_cmdLine <- function(exe = "ClimateNA_v7.60.exe", wkDir, period = 'Normal_1961_1990.nrm', MSY = 'Y', inputFile, outputFile)
```

**Arguments**
*   `exe`: The .exe file. It can be "ClimateNA_v7.60.exe" or "ClimateBC_v7.60.exe" the default value is "ClimateNA_v7.60.exe".
*   `wkDir`: The root directory of ClimateNA or ClimateBC in a format of `"C:\\Climatena_v742\\"`. Please make sure to use double backslashes (`\\`) in the path.
*   `Period`: The period of the climate data. The default is "Normal_1961_1990.nrm". It can also be another historical normal (.nrm), decadal (e.g., "Decade_2001_2010.dcd"), annual (e.g., "Year_2021.ann"), and future period (.gcm).
*   `MSY`: The time scale of the climate variables. The default is 'Y' for annual variables. It can also be 'M' for monthly, 'S' for seasonal, 'SY' for annual and seasonal, or 'MSY' for all.
*   `inputFile`: The input file name and location. It can be either a .csv or .asc file, like: `'C:\\Climatena_v760\\InputFiles\\input_test.csv'` or `'C:\\ClimateModels\\Climatena_v760\\InputFiles\\na50k.asc'`.
*   `outputFile`: The output file name and location. It depends on the type of input file. If the input file is a .csv file, the output file should also be a .csv file, like: `'C:\\ClimateModels\\Climatena_v760\\test\\test_Normal_1961_1990.csv'`.
If the `inputFile` is an .asc file, the `outputFile` is a folder name like: `'C:\\Climatena_v760\\test\\'`.

**Examples**
```r
library(ClimateNAr)
wkDir = 'C:\\ClimateModels\\Climatena_v760\\'
exe <- "ClimateNA_v7.60.exe"

# Using a CSV file as the input file
inputFile = 'C:\\Climatena_v760\\InputFiles\\input_test.csv'
outputFile = 'C:\\ Climatena_v760\\test\\test_Normal_1961_1990.csv'
period = 'Normal_1961_1990.nrm'
ClimateNA_cmdLine(exe, wkDir, period, MSY='Y',inputFile, outputFile)

# Using an ASC raster file as the input file
inputFile = 'C:\\Climatena_v760\\InputFiles\\na50k.asc'
outputFile = 'C:\\Climatena_v760\\test\\'
period = 'Normal_1961_1990.nrm'
ClimateNA_cmdLine(exe,wkDir,period,MSY='SY',inputFile, outputFile)

# Using a loop to generate climate data for time-series
inputFile = 'C:\\Climatena_v760\\InputFiles\\na50k.asc'
outputFile = 'C:\\Climatena_v760\\test\\'
for(yr in 1961:1990){
  period = paste0('Year_', yr, '.ann')
  ClimateNA_cmdLine(exe,wkDir,period,MSY='SY',inputFile, outputFile)
}
```

### ClimateNA_API

**Description**
`ClimateNA_API` is to get climate variables for a single location from ClimateBC or ClimateNA web API.

**Usage**
```r
ClimateNA_API(ClimateBC_NA='NA', latLonEl, period='Normal_1961_1990.nrm', MSY='Y')
```

**Arguments**
*   `ClimateBC_NA`: To specify either to use ClimateBC or ClimateNA web API. The default is `ClimateBC_NA = 'NA'` for ClimateNA. It can also be `ClimateBC_NA = 'BC'` for ClimateBC.
*   `latLonEl`: Coordinates and elevation of a location, for example: `latLonEl <- c(48.98,-115.02,200)`.
*   `period`: The period of the climate data. The default is 'Normal_1961_1990.nrm'. It can also be another historical or future period. Most period options of the desktop version are available.
*   `MSY`: The time scale of the climate variables. The default is 'Y' for annual variables. It can also be 'M' for monthly, 'S' for seasonal, 'SY' for annual and seasonal, or 'MSY' for all.

**Limitations**
All computing process occurs on the server for requests from all users and can easily crash the server. To prevent from using this function loops, the number of requests cannot be more than 2 times per second.

**Examples**
```r
library(ClimateNAr)
latLonEl <- c(48.98,-115.02,1000)
clm <- ClimateNA_API(ClimateBC_NA='BC', latLonEl,period='Normal_1961_1990.nrm',MSY='Y');
clm <- ClimateNA_API(ClimateBC_NA='NA', latLonEl,period='Year_2011.ann',MSY='Y');
clm <- ClimateNA_API(ClimateBC_NA='BC', latLonEl,period='8GCMs_ensemble_ssp245_2041-2070.gcm',MSY='Y');
head(clm);dim(clm)
```

### ClimateNA_API2

**Description**
`ClimateNA_API2` is to get climate variables for multiple locations from ClimateBC or ClimateNA web API.

**Usage**
```r
ClimateNA_API2(ClimateBC_NA='NA', inputFile, period='Normal_1961_1990.nrm', MSY='Y');
```

**Arguments**
*   `ClimateBC_NA`: To specify either to use ClimateBC or ClimateNA web API. The default is `ClimateBC_NA = 'NA'` for ClimateNA. It can also be `ClimateBC_NA = 'BC'` for ClimateBC.
*   `inputFile`: An .CSV input file consists of coordinates and elevation of locations. It has the same format as the .CSV input file for desktop ClimateBC or ClimateNA.
*   `period`: The period of the climate data. The default is 'Normal_1961_1990.nrm'. It can also be another historical or future period. Most period options of the desktop version are available.
*   `MSY`: The time scale of the climate variables. The default is 'Y' for annual variables. It can also be 'M' for monthly, 'S' for seasonal, 'SY' for annual and seasonal, or 'MSY' for all.

**Limitations**
All computing process occurs on the server for requests from all users and can easily crash the server. To prevent this, a two-way throttling measure is implemented. First, the input file x cannot have more than 100 entries. Second, the number of requests cannot be more than 10 times per hour and 100 times per day.

**Examples**
```r
library(ClimateNAr)
input_file <- 'C:/temp/locations.csv'
clm <- ClimateNA_API2 (ClimateBC_NA='NA', inputFile=input_file, period='Normal_1961_1990.nrm',MSY='Y');
head(clm);dim(clm)
```

### rasterDownload

**Description**
`rasterDownload` is to download raster files for specific variables for BC, WNA, or NA generated by ClimateBC and ClimateNA (available for selected periods and climate change scenarios).

**Usage**
```r
rasterDownload(region='BC',res='800m',period='Normal_1961_1990',varList=varList,sDir='C:/temp')
```

**Arguments**
*   `region`: The region of interest. It can be 'BC', 'WNA' or 'NA'.
*   `res`: Spatial resolution. The default is '800m'. The '800m' is available for 'BC' and 'WNA', and the '4000m' is available for NA.
*   `period`: The period of the climate data. The default is "Normal_1961_1990". The available options include: "Normal_1971_2000", "Normal_1981_2010", and "Normal_1991_2020" for historical periods, all the 8GCMs_ensembles (for example: "8GCMs_ensemble_ssp126_2011-2040"). More options may be added later on.
*   `varList`: A list of climate variables to download.
*   `sDir`: The directory to be created to save the downloaded files.

**Examples**
```r
library(ClimateNAr)
varList <- c('mat', 'map','td')
rasterDownload(region='BC',res='800m', period='Normal_1961_1990',varList=varList,sDir='C:/temp')
```

### rasterStack

**Description**
`rasterStack` is to generate a raster stack from raster files for model spatial predictions.

**Usage**
```r
rasterStack(wd, varList, rType='tif')
```

**Arguments**
*   `wd`: The working directory where the raster files are located.
*   `varList`: A list of variables to be included in the stack.
*   `rType`: Raster type of the raster files. The default is Tiff files ('tif'). It can also be ArcGIS grid files ('grid').

**Examples**
```r
library(ClimateNAr)
wd <- 'C:/temp/Normal_1961_1990SY/'
varList <- c('mat', 'map', 'td')
stk <- rasterStack(wd,varList,rType='tif');stk
#Please check the file location to make sure the 'wd' is correctly specified.
```

### tifToAsc

**Description**
`tifToAsc` converts a DEM raster from TIFF to ASCII format that can be used as an input file for ClimateNA. The TIFF file must be in lat/lon projection.

**Usage**
```r
tifToAsc(tifFile, ascFile)
```

**Arguments**
*   `tifFile`: the full name of the tif raster, for example, 'C:/temp/bc80k.tif'.
*   `ascFile`: the full name of the ascii file, for example, 'C:/temp/bc80k.asc'

**Examples**
```r
library(ClimateNAr)
tifFile = 'C:/temp/bc80k.tif'
ascFile = 'C:/temp/bc80k.asc'
tifToAsc (tifFile, ascFile)
```

### varScan

**Description**
`varScan` is to identify the best climate variables, either individually or in combinations, as predictors in quadratic form for a dependent variable.

**Usage**
```r
varScan(x, y, varComb = 1, smVar = 0, IR = F, title = "3D chart")
```

**Arguments**
*   `x`: A dataframe comprising climate variables (in columns) to be scanned.
*   `y`: A vector for a dependent variable.
*   `varComb`: The number of variables combined. `varComb=1` for a single variable (default), `varComb=2` for a combination of 2 variables (up to 4 variables).
*   `smVar`: The number of top single variables selected for scanning multiple regressions. `smVar=0` to scan all variables (default); `smVar=5` to scan top 5 single variables.
*   `IR`: Considering interactions. `IR=False` for no interaction considered (Default)
*   `title`: The title of the output plot
*   `Value`: The model for the best climate variable combinations and a list of sorted variables based on their importance.

**Examples**
```r
library(ClimateNAr)
xy <- read.csv('C:/temp/Normal_1961_1990Y.csv');head(xy)
x <- xy[,1:24]; head(x)
y = xy$TD;y
bestMod <- varScan(x, y, varComb=1, smVar=10,IR=F,title='Y values');
head(bestMod$list,10)
bestMod <- varScan(x, y, varComb=2, smVar=10,IR=F,title='Y values');
head(bestMod$list,10)
```
