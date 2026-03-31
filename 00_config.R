# =========================================
# CONFIGURACIÓN GLOBAL DEL PROYECTO
# =========================================

# ---- Directorios base (portables) ----

base_dir <- getwd()

data_dir    <- file.path(base_dir, "data")
results_dir <- file.path(base_dir, "results")
out_dir     <- results_dir

# Crear carpetas si no existen
dir.create(data_dir, showWarnings = FALSE)
dir.create(results_dir, showWarnings = FALSE)

# ---- Archivos de entrada ----

pisco_dpr_path <- file.path(data_dir, "pisco_dpr_v2.1.nc")
dem_path       <- file.path(data_dir, "dem_peru_recortado.tif")
dept_shp_path  <- file.path(data_dir, "DEPARTAMENTOS.shp")

# ---- Parámetros del modelo ----

umbrales <- c(10, 15, 20)

meses_sel <- c(1,2,3)

anio_ini <- 1981
anio_fin <- 2016

limite_dia_seco <- 1
altitud_umbral <- 3600

suma_asegurada_departamental <- 1e6