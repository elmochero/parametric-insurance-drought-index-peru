# ============================================================
# FASE 13 — Activación del índice paramétrico (ANUAL)
# Puno | >3600 msnm | SEP–DIC | Ventana móvil 60 días
# ============================================================

message("📊 Fase 13: activación índice P90 / P95")

library(terra)
library(sf)
library(dplyr)
library(openxlsx)
library(ggplot2)

# ------------------------------------------------------------
# 1. CARGA BASE
# ------------------------------------------------------------

pisco <- rast(pisco_dpr_path)

fechas <- seq(as.Date("1981-01-01"),
              as.Date("2016-12-31"),
              by="day")

meses_validos <- which(as.numeric(format(fechas,"%m")) %in% c(9,10,11,12))

pisco <- pisco[[meses_validos]]
fechas <- fechas[meses_validos]

dem   <- rast(dem_path)

dept_sf <- st_read(dept_shp_path, quiet = TRUE) |>
  dplyr::filter(DEPARTAMEN == "PUNO")

crs(dem) <- crs(pisco)
dept_sf  <- st_transform(dept_sf, crs(pisco))

dem_aligned <- resample(dem, pisco[[1]])
mask_alt <- dem_aligned >= altitud_umbral
mask_puno <- rasterize(vect(dept_sf), pisco[[1]], field=1)

mask_final <- mask_alt * mask_puno
mask_bin   <- mask_final == 1

pix_tot <- global(mask_bin, "sum", na.rm=TRUE)[1,1]

# ------------------------------------------------------------
# 2. CLIMATOLOGÍA
# ------------------------------------------------------------

clim <- rast(file.path(
  out_dir,
  "climatologia_runs_multi_ventanas_percentiles_Puno.tif"
))

clim_p90 <- clim[["W60_P90"]]
clim_p95 <- clim[["W60_P95"]]

# ------------------------------------------------------------
# 2.B MAPA CLIMATOLOGÍA (RUNS SECOS)
# ------------------------------------------------------------

clim_raster <- mask(clim_p90, mask_final)

df_clim <- as.data.frame(clim_raster, xy = TRUE, na.rm = TRUE)
colnames(df_clim) <- c("x","y","runs")

bbox <- st_bbox(dept_sf)

mapa_clim <- ggplot() +
  
  geom_raster(
    data=df_clim,
    aes(x=x, y=y, fill=runs)
  ) +
  
  geom_sf(
    data=dept_sf,
    fill=NA,
    color="black",
    linewidth=0.5
  ) +
  
  scale_fill_viridis_c(
    option="C",
    name="Días secos\nconsecutivos"
  ) +
  
  coord_sf(
    xlim=c(bbox["xmin"], bbox["xmax"]),
    ylim=c(bbox["ymin"], bbox["ymax"]),
    expand=FALSE
  ) +
  
  labs(
    title="Climatología de Runs Secos (P90)",
    subtitle="Máximo número de días secos consecutivos (ventana 60 días)\nPuno > 3600 msnm | 1981–2016",
    x="Longitud",
    y="Latitud"
  ) +
  
  theme_minimal() +
  
  theme(
    plot.title=element_text(size=14,face="bold",hjust=0.5),
    plot.subtitle=element_text(size=11,hjust=0.5),
    legend.position="right",
    panel.grid=element_blank()
  )

ggsave(
  file.path(results_dir,"Mapa_Climatologia_P90_Puno.png"),
  mapa_clim,
  width=8,
  height=10,
  dpi=300
)

message("🌡 Mapa de climatología exportado")

# ------------------------------------------------------------
# 3. FUNCIÓN: Max run anual (ventana móvil)
# ------------------------------------------------------------

calc_max_run_year <- function(v){
  
  limite <- 1   # definición de día seco
  
  n <- length(v)
  W <- 60
  
  if(n < W) return(NA_real_)
  
  runs <- sapply(1:(n-W+1), function(j){
    
    x <- v[j:(j+W-1)]
    
    if(all(is.na(x))) return(NA_real_)
    
    dry <- x <= limite
    
    if(!any(dry, na.rm=TRUE)) return(0)
    
    r <- rle(dry)
    max(r$lengths[r$values==TRUE], na.rm=TRUE)
  })
  
  if(length(runs)==0 || all(is.na(runs))) return(0)
  
  max(runs, na.rm=TRUE)
}

# ------------------------------------------------------------
# 4. EVALUACIÓN ANUAL
# ------------------------------------------------------------

años <- 1981:2016

resultados <- data.frame(
  año = años,
  prop_p90 = NA,
  prop_p95 = NA,
  pago_p90 = NA,
  pago_p95 = NA
)

lista_eventos_p90 <- list()
lista_eventos_p95 <- list()

for(i in seq_along(años)){
  
  yy <- años[i]
  message("Procesando año ", yy)
  
  idx_year <- which(format(fechas,"%Y")==as.character(yy) &
                      as.numeric(format(fechas,"%m")) %in% c(9,10,11,12))
  
  pisco_year <- pisco[[idx_year]]
  
  r_obs_year <- app(pisco_year, calc_max_run_year, cores=parallel::detectCores()-1)
  r_obs_year <- mask(r_obs_year, mask_final)
  
  evento_p90 <- r_obs_year >= clim_p90
  evento_p95 <- r_obs_year >= clim_p95
  
  lista_eventos_p90[[i]] <- evento_p90
  lista_eventos_p95[[i]] <- evento_p95
  
  pix_evt_p90 <- global(evento_p90 & mask_bin, "sum", na.rm=TRUE)[1,1]
  pix_evt_p95 <- global(evento_p95 & mask_bin, "sum", na.rm=TRUE)[1,1]
  
  prop_p90 <- pix_evt_p90 / pix_tot
  prop_p95 <- pix_evt_p95 / pix_tot
  
  resultados$prop_p90[i] <- prop_p90
  resultados$prop_p95[i] <- prop_p95
  resultados$pago_p90[i] <- prop_p90 * suma_asegurada_departamental
  resultados$pago_p95[i] <- prop_p95 * suma_asegurada_departamental
}


# ------------------------------------------------------------
# 5. FRECUENCIA ESPACIAL
# ------------------------------------------------------------

# ------------------------------------------------------------
# 5. FRECUENCIA ESPACIAL (versión eficiente)
# ------------------------------------------------------------

freq_p90 <- lista_eventos_p90[[1]] * 0
freq_p95 <- lista_eventos_p95[[1]] * 0

for(i in 1:length(lista_eventos_p90)){
  
  freq_p90 <- freq_p90 + lista_eventos_p90[[i]]
  freq_p95 <- freq_p95 + lista_eventos_p95[[i]]
  
}

freq_p90 <- freq_p90 / length(lista_eventos_p90)
freq_p95 <- freq_p95 / length(lista_eventos_p95)

writeRaster(freq_p90,
            file.path(out_dir, "Mapa_Frecuencia_P90_Puno.tif"),
            overwrite=TRUE)

writeRaster(freq_p95,
            file.path(out_dir, "Mapa_Frecuencia_P95_Puno.tif"),
            overwrite=TRUE)

message("🗺 Mapas de frecuencia exportados")

# ------------------------------------------------------------
# 5.B. MAPA PÉRDIDA ESPERADA ESPACIAL
# ------------------------------------------------------------

loss_cost_pixel <- freq_p90 * mean(resultados$prop_p90)

loss_cost_crop <- crop(loss_cost_pixel, vect(dept_sf))

writeRaster(loss_cost_crop,
            file.path(out_dir,
                      "Mapa_LossCost_P90_Puno.tif"),
            overwrite = TRUE)

png(file.path(out_dir,
              "Mapa_LossCost_P90_Puno.png"),
    width=2200, height=1800, res=300)

plot(loss_cost_crop,
     col = hcl.colors(20,"Reds"),
     main = "Pérdida Esperada Espacial (Loss Cost)\nÍndice Paramétrico P90")

plot(vect(dept_sf), add=TRUE)

dev.off()

message("💰 Mapa de pérdida esperada exportado")


# ------------------------------------------------------------
# 6. MÉTRICAS ACTUARIALES
# ------------------------------------------------------------

frecuencia_p90 <- mean(resultados$prop_p90 > 0)
frecuencia_p95 <- mean(resultados$prop_p95 > 0)

pago_prom_p90 <- mean(resultados$pago_p90)
pago_prom_p95 <- mean(resultados$pago_p95)

tasa_pura_p90 <- pago_prom_p90 / suma_asegurada_departamental
tasa_pura_p95 <- pago_prom_p95 / suma_asegurada_departamental

print(resultados)
print(frecuencia_p90)
print(frecuencia_p95)
print(tasa_pura_p90)
print(tasa_pura_p95)

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

save(freq_p90,
     freq_p95,
     tasa_pura_p90,
     tasa_pura_p95,
     mask_final,
     dept_sf,
     resultados,
     file=file.path(out_dir, "resultados_fase13_Puno.RData"))

# =========================================
# MAPAS FINALES - FRECUENCIA DE ACTIVACIÓN
# =========================================

library(ggplot2)
library(sf)
library(terra)
library(ggspatial)

puno <- dept_sf

# bounding box
bbox <- st_bbox(puno)
xmin <- bbox["xmin"]
xmax <- bbox["xmax"]
ymin <- bbox["ymin"]
ymax <- bbox["ymax"]

# -------------------------------
# FUNCIÓN PARA CREAR MAPAS
# -------------------------------

crear_mapa_freq <- function(freq_raster, titulo, tasa_pura, percentil){
  
  freq_raster <- mask(freq_raster, mask_final)
  freq_raster[freq_raster <= 0] <- NA
  
  df <- as.data.frame(freq_raster, xy = TRUE, na.rm = TRUE)
  colnames(df) <- c("x","y","freq")
  
  tasa_texto <- paste0("Tasa pura P",percentil," = ", round(tasa_pura*100,2),"%")
  
  ggplot() +
    
    geom_raster(
      data=df,
      aes(x=x, y=y, fill=freq)
    ) +
    
    geom_sf(
      data=puno,
      fill=NA,
      color="black",
      linewidth=0.5
    ) +
    
    scale_fill_distiller(
      palette="YlOrRd",
      direction=1,
      limits=c(0,0.5),
      oob=scales::squish,
      name="Frecuencia"
    ) +
    
    coord_sf(
      xlim=c(xmin, xmax),
      ylim=c(ymin, ymax),
      expand=FALSE
    ) +
    
    annotation_scale(location="bl", width_hint=0.4) +
    
    annotation_north_arrow(
      location="tl",
      which_north="true",
      style=north_arrow_fancy_orienteering
    ) +
    
    annotate(
      "label",
      x=xmin+0.3,
      y=ymin+0.3,
      label=tasa_texto,
      size=4
    ) +
    
    labs(
      title=titulo,
      subtitle="Puno > 3600 msnm | SEP–DIC | 1981–2016",
      x="Longitud",
      y="Latitud"
    ) +
    
    theme_minimal() +
    
    theme(
      plot.title=element_text(size=14,face="bold",hjust=0.5),
      plot.subtitle=element_text(size=12,hjust=0.5),
      legend.position="right",
      panel.grid=element_blank(),
      plot.margin=margin(20,20,20,20)
    )
}

# -------------------------------
# MAPA P90
# -------------------------------

mapa_p90 <- crear_mapa_freq(
  freq_p90,
  "Frecuencia de Activación del Índice (P90)",
  tasa_pura_p90,
  90
)

ggsave(
  file.path(results_dir,"Mapa_Frecuencia_P90_Puno_Final.png"),
  mapa_p90,
  width=8,
  height=10,
  dpi=300
)

# -------------------------------
# MAPA P95
# -------------------------------

mapa_p95 <- crear_mapa_freq(
  freq_p95,
  "Frecuencia de Activación del Índice (P95)",
  tasa_pura_p95,
  95
)

ggsave(
  file.path(results_dir,"Mapa_Frecuencia_P95_Puno_Final.png"),
  mapa_p95,
  width=8,
  height=10,
  dpi=300
)

message("🗺 Mapas finales P90 y P95 exportados correctamente")

# ------------------------------------------------------------
# 8. EXPORTACIÓN EXCEL
# ------------------------------------------------------------

resumen <- data.frame(
  Indicador = c("Frecuencia activación P90",
                "Frecuencia activación P95",
                "Pago promedio P90",
                "Pago promedio P95",
                "Tasa pura P90",
                "Tasa pura P95"),
  Valor = c(frecuencia_p90,
            frecuencia_p95,
            pago_prom_p90,
            pago_prom_p95,
            tasa_pura_p90,
            tasa_pura_p95)
)

wb <- createWorkbook()

addWorksheet(wb, "Resultados_Anuales")
writeData(wb, "Resultados_Anuales", resultados)

addWorksheet(wb, "Resumen_Actuarial")
writeData(wb, "Resumen_Actuarial", resumen)

archivo_excel <- file.path(
  out_dir,
  "Resultados_Indice_Parametrico_Puno_W60_SEP_DIC.xlsx"
)

saveWorkbook(wb, archivo_excel, overwrite = TRUE)

message("📁 Excel exportado correctamente")

# ------------------------------------------------------------
# 9. GRÁFICO DE PAGOS
# ------------------------------------------------------------

grafico <- ggplot(resultados, aes(x = factor(año), y = pago_p90)) +
  geom_bar(stat = "identity") +
  geom_line(aes(y = pago_p95, group = 1), color = "red", linewidth = 1) +
  labs(
    title = "Pagos Anuales del Índice Paramétrico\nPuno (>3600 msnm) | Ventana 60 días | SEP–DIC",
    x = "Año",
    y = "Pago estimado (S/.)",
    caption = "Barras: Umbral P90 | Línea roja: Umbral P95"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, size = 7))

archivo_png <- file.path(
  out_dir,
  "Grafico_Pagos_Indice_Parametrico_Puno_W60.png"
)

ggsave(archivo_png, grafico, width = 12, height = 6, dpi = 300)

message("📊 Gráfico exportado correctamente")

message("✅ Fase 13 anual completada")

if(!exists("mapa_clim") | !exists("mapa_p90") | !exists("mapa_p95")){
  stop("❌ Debes ejecutar primero todo el script antes de crear la figura multipanel")
}

# ----------------------------------------
# FIGURA MULTIPANEL
# ----------------------------------------

library(patchwork)

figura_final <- 
  (mapa_clim + plot_spacer() + mapa_p90 + plot_spacer() + mapa_p95) + plot_layout(widths = c(1,0.1,1,0.1,1)) +
  plot_annotation(
    title = "Activación Espacial del Índice Paramétrico de Sequía",
    subtitle = "Puno > 3600 msnm | Ventana 60 días | SEP–DIC | 1981–2016",
    theme = theme(
      plot.title = element_text(size=18, face="bold", hjust=0.5),
      plot.subtitle = element_text(size=12, hjust=0.5)
    )
  )

# exportar
ggsave(
  file.path(results_dir, "Figura_Multipanel_Indice_Puno.png"),
  figura_final,
  width = 16,
  height = 6,
  dpi = 300
)

message("🧩 Figura multipanel exportada correctamente")

# ----------------------------------------
# 10. ANÁLISIS ESTADÍSTICO DEL ÍNDICE
# ----------------------------------------

# P90
mean_p90 <- mean(resultados$pago_p90)
sd_p90   <- sd(resultados$pago_p90)
cv_p90   <- sd_p90 / mean_p90

# P95
mean_p95 <- mean(resultados$pago_p95)
sd_p95   <- sd(resultados$pago_p95)
cv_p95   <- sd_p95 / mean_p95

cat("\n📊 --- ESTABILIDAD DEL ÍNDICE ---\n")
cat("P90:\n")
cat("Media:", mean_p90, "\n")
cat("Desv.Est:", sd_p90, "\n")
cat("Coef. Variación:", cv_p90, "\n\n")

cat("P95:\n")
cat("Media:", mean_p95, "\n")
cat("Desv.Est:", sd_p95, "\n")
cat("Coef. Variación:", cv_p95, "\n")


# ----------------------------------------
# 11. DISTRIBUCIÓN DE PAGOS
# ----------------------------------------

png(file.path(out_dir, "Histograma_Pagos_P90.png"),
    width=1200, height=800)

hist(resultados$pago_p90,
     breaks=15,
     col="skyblue",
     main="Distribución de Pagos - P90",
     xlab="Pago anual (S/.)")

dev.off()


png(file.path(out_dir, "Histograma_Pagos_P95.png"),
    width=1200, height=800)

hist(resultados$pago_p95,
     breaks=15,
     col="salmon",
     main="Distribución de Pagos - P95",
     xlab="Pago anual (S/.)")

dev.off()

# percentiles clave

quantile(resultados$pago_p90, probs = c(0.75, 0.9, 0.95, 0.99))
quantile(resultados$pago_p95, probs = c(0.75, 0.9, 0.95, 0.99))


# ============================================================
# 10. MONTE CARLO – SIMULACIÓN DE PÉRDIDAS
# ============================================================

set.seed(123)

n_sim <- 10000

sim_p90 <- sample(resultados$pago_p90, n_sim, replace = TRUE)
sim_p95 <- sample(resultados$pago_p95, n_sim, replace = TRUE)

# ------------------------------------------------------------
# MÉTRICAS DE RIESGO
# ------------------------------------------------------------

metricas_mc <- function(x){
  
  c(
    media = mean(x),
    sd = sd(x),
    CV = sd(x)/mean(x),
    P50 = quantile(x, 0.50),
    P75 = quantile(x, 0.75),
    P90 = quantile(x, 0.90),
    P95 = quantile(x, 0.95),
    P99 = quantile(x, 0.99),
    max = max(x)
  )
}

mc_p90 <- metricas_mc(sim_p90)
mc_p95 <- metricas_mc(sim_p95)

print("📊 Monte Carlo P90")
print(mc_p90)

print("📊 Monte Carlo P95")
print(mc_p95)


# ------------------------------------------------------------
# CURVA DE EXCEDENCIA
# ------------------------------------------------------------

df_ep <- data.frame(
  loss = sort(sim_p90, decreasing = TRUE),
  prob = (1:n_sim) / (n_sim + 1)
)

grafico_ep <- ggplot(df_ep, aes(x = loss, y = prob)) +
  geom_line() +
  scale_y_continuous(trans = "log10") +
  labs(
    title = "Curva de Excedencia (EP Curve) – P90",
    x = "Pérdida anual (S/.)",
    y = "Probabilidad de excedencia (escala log)"
  ) +
  theme_minimal()

ggsave(
  file.path(out_dir, "EP_Curve_P90.png"),
  grafico_ep,
  width = 8,
  height = 6,
  dpi = 300
)


# ------------------------------------------------------------
# VaR y TVaR
# ------------------------------------------------------------

VaR_95 <- quantile(sim_p90, 0.95)
VaR_99 <- quantile(sim_p90, 0.99)

TVaR_95 <- mean(sim_p90[sim_p90 >= VaR_95])
TVaR_99 <- mean(sim_p90[sim_p90 >= VaR_99])

cat("VaR 95:", VaR_95, "\n")
cat("VaR 99:", VaR_99, "\n")
cat("TVaR 95:", TVaR_95, "\n")
cat("TVaR 99:", TVaR_99, "\n")





