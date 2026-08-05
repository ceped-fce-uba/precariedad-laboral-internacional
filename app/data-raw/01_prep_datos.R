# Prepara todo lo que consume la app. Lee las bases homogéneas c. 2019 de
# bases_por_pais/ y deja en app/data/ una serie de rds chicos, para que la app
# arranque rápido y no tenga que tocar los microdatos.
#
# Las bases no están en el repo: se bajan antes con source("bajar_piggyback.R").
#
# Correr con:  Rscript app/data-raw/01_prep_datos.R

suppressMessages({
  library(tidyverse)
  library(openxlsx)
})

repo    <- here::here()
fuentes <- file.path(repo, "fuentes_complementarias")
out_dir <- file.path(repo, "app", "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

cob_min <- 0.50   # cobertura mínima de la variable para que el país entre

guardar <- function(x, nombre) {
  saveRDS(x, file.path(out_dir, paste0(nombre, ".rds")), compress = "xz")
  cat(sprintf("==> %-22s %6d filas\n", nombre, nrow(x)))
}

# ---- bases -----------------------------------------------------------------

vars <- c("PAIS", "ANO", "WEIGHT", "SEXO", "SECTOR", "CATOCUP", "CALIF",
          "TAMA", "EDUC", "ING", "PRECAPT", "PRECAREG", "PRECATEMP", "PRECASEG",
          "PRECATEMP_INV")   # sólo Europa; el resto entra en NA

leer <- function(f) {
  b <- as_tibble(readRDS(f))
  b[setdiff(vars, names(b))] <- NA        # no todos los países tienen todo
  b |>
    transmute(PAIS = as.character(PAIS), ANO = as.numeric(ANO),
              WEIGHT = as.numeric(WEIGHT),
              across(c(SEXO, SECTOR, CATOCUP, CALIF, TAMA, EDUC), as.character),
              ING = suppressWarnings(as.numeric(ING)),
              across(c(PRECAPT, PRECAREG, PRECATEMP, PRECASEG, PRECATEMP_INV),
                     ~ suppressWarnings(as.numeric(as.character(.x)))))
}

bases_dir <- file.path(repo, "bases_por_pais")
if (!dir.exists(bases_dir))
  stop("No encuentro bases_por_pais/. Bajalas con source(\"bajar_piggyback.R\")")

files <- list.files(bases_dir, pattern = "_2019.*\\.rds$", full.names = TRUE)
files <- files[!grepl("uruguay_2019_imputada\\.rds$", files)]   # base sin imputar

cat("Leyendo", length(files), "bases...\n")

reg_levels <- c("América Latina", "Europa", "Estados Unidos", "China")

paises_meta <- read.xlsx(file.path(fuentes, "Prod y Salarios.xlsx"),
                         sheet = "Paises") |>
  transmute(PAIS   = recode(nombre.pais, "Peru" = "Perú"),
            COD.OCDE, Orden,
            region = recode(region, "AmLat" = "América Latina",
                            "USA" = "Estados Unidos"))

# CATOCUP viene con dos ortografías según el país, así que unifico
B <- map_dfr(files, leer) |>
  mutate(CATOCUP = recode(CATOCUP, "Asalariados" = "Asalariado",
                          "Cuenta Propia" = "Cuenta propia", "Patrón" = "Patron"),
         PAIS    = recode(PAIS, "Peru" = "Perú"),
         CALIF   = na_if(CALIF, "Ns/Nc")) |>
  left_join(paises_meta, by = "PAIS") |>
  filter(!is.na(region)) |>
  mutate(region = factor(region, levels = reg_levels))

cat("  ", nrow(B), "registros,", n_distinct(B$PAIS), "países\n")

# ---- helpers ---------------------------------------------------------------

wmean <- function(x, w) {
  i <- !is.na(x) & !is.na(w) & w > 0
  if (!any(i)) return(NA_real_)
  sum(x[i] * w[i]) / sum(w[i])
}

wquant <- function(x, w, p = 0.5) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  x <- x[ok]; w <- w[ok]
  if (!length(x)) return(NA_real_)
  if (length(x) < 2) return(x[1])       # approx() necesita al menos dos puntos
  o <- order(x); x <- x[o]; w <- w[o]
  cw <- (cumsum(w) - 0.5 * w) / sum(w)
  approx(cw, x, xout = p, rule = 2, ties = "ordered")$y
}

# tasa sobre los casos con dato válido (0/1), y su cobertura
tasa <- function(x, w) wmean(x == 1, ifelse(x %in% c(0, 1), w, NA))
cobertura <- function(x) mean(x %in% c(0, 1))

# ---- niveles de cada variable de corte -------------------------------------

vars_corte <- c("SEXO", "SECTOR", "CATOCUP", "CALIF", "TAMA", "EDUC")

niveles_corte <- list(
  SEXO    = c("Varon", "Mujer"),
  SECTOR  = c("Priv", "Pub", "SD"),
  CATOCUP = c("Asalariado", "Cuenta propia", "Patron", "Resto"),
  CALIF   = c("Baja", "Media", "Alta"),
  # "Mediano o Grande" es el tamaño ambiguo de la LFS europea (SIZEFIRM 15,
  # "no sabe, pero más de 10 personas"): no se puede repartir entre Mediano
  # (11-49) y Grande (50+), así que va como categoría propia
  TAMA    = c("Pequeño", "Mediano", "Mediano o Grande", "Grande"),
  EDUC    = c("Primaria", "Secundaria", "Terciaria"))

# etiquetas lindas para la app
etiquetas_corte <- c(SEXO = "Sexo", SECTOR = "Sector", CATOCUP = "Categoría ocupacional",
                     CALIF = "Calificación del puesto", TAMA = "Tamaño del establecimiento",
                     EDUC = "Nivel educativo")

etiquetas_nivel <- c(Varon = "Varón", Mujer = "Mujer",
                     Priv = "Privado", Pub = "Público", SD = "Servicio doméstico",
                     Asalariado = "Asalariado", `Cuenta propia` = "Cuenta propia",
                     Patron = "Patrón", Resto = "Resto",
                     Baja = "Baja", Media = "Media", Alta = "Alta",
                     Pequeño = "Pequeño", Mediano = "Mediano", Grande = "Grande",
                     Primaria = "Primaria", Secundaria = "Secundaria",
                     Terciaria = "Terciaria")

ordenar <- function(d, col, corte) {
  d[[col]] <- factor(d[[col]], levels = niveles_corte[[corte]])
  filter(d, !is.na(.data[[col]]))
}

# ---- 1. distribución del empleo, una variable ------------------------------

pesos1 <- map_dfr(vars_corte, function(v) {
  B |>
    filter(!is.na(.data[[v]]), !is.na(WEIGHT)) |>
    count(region, PAIS, categoria = .data[[v]], wt = WEIGHT, name = "casos") |>
    group_by(PAIS) |>
    mutate(share = casos / sum(casos)) |>
    ungroup() |>
    mutate(corte = v) |>
    ordenar("categoria", v)
})

guardar(pesos1, "pesos1")

# ---- 2. distribución del empleo, cruce de dos variables --------------------

pares <- combn(vars_corte, 2, simplify = FALSE)

pesos2 <- map_dfr(pares, function(p) {
  B |>
    filter(!is.na(.data[[p[1]]]), !is.na(.data[[p[2]]]), !is.na(WEIGHT)) |>
    count(region, PAIS, cat1 = .data[[p[1]]], cat2 = .data[[p[2]]],
          wt = WEIGHT, name = "casos") |>
    group_by(PAIS) |>
    mutate(share = casos / sum(casos)) |>
    ungroup() |>
    mutate(corte1 = p[1], corte2 = p[2]) |>
    ordenar("cat1", p[1]) |>
    ordenar("cat2", p[2]) |>
    mutate(categoria = paste(cat1, cat2, sep = " · "))
})

guardar(pesos2, "pesos2")

# ---- 3. tasas de precariedad ------------------------------------------------

vars_preca <- c(PRECAPT   = "Part-time involuntario",
                PRECATEMP = "Empleo temporario",
                PRECAREG  = "Empleo no registrado",
                PRECASEG  = "Sin aportes a la seguridad social")

asal <- filter(B, CATOCUP == "Asalariado")

cortes_preca <- c("Total", setdiff(vars_corte, "CATOCUP"))

preca <- expand_grid(cc = cortes_preca, ind = names(vars_preca)) |>
  pmap_dfr(function(cc, ind) {
    d <- if (cc == "Total") mutate(asal, categoria = "Total")
         else asal |> filter(!is.na(.data[[cc]])) |> mutate(categoria = .data[[cc]])
    d |>
      group_by(region, PAIS, categoria) |>
      summarise(tasa = tasa(.data[[ind]], WEIGHT),
                cob  = cobertura(.data[[ind]]), .groups = "drop") |>
      mutate(corte = cc, indicador = ind)
  }) |>
  filter(cob >= cob_min, !is.na(tasa)) |>
  # México sale de PRECAPT: la ENOE mide subocupación (necesidad + disponibilidad),
  # más estricta y no comparable con el "¿desea más horas?" del resto (sub-estima).
  filter(!(PAIS == "México" & indicador == "PRECAPT")) |>
  mutate(categoria = factor(categoria,
                            levels = c("Total", unlist(niveles_corte, use.names = FALSE))))

guardar(preca, "preca")

# ---- 4. ingresos en dólares PPA --------------------------------------------

# La PPA sale del benchmark del Banco Mundial (PPPGlob) hasta 2017; 2018 y 2019
# los extrapolo con IPC contra EE.UU., que queda en PPA = 1.
xlsx <- file.path(fuentes, "Prod y Salarios.xlsx")

IPC <- read.xlsx(xlsx, sheet = "IPC (2005)") |>
  rename(ANO4 = X1) |>
  pivot_longer(-ANO4, names_to = "PAIS", values_to = "IPC") |>
  # openxlsx trae los nombres de columna con puntos donde había espacios, y esta
  # hoja escribe "Peru" sin tilde: lo alineo con el resto de las bases
  mutate(PAIS = str_replace_all(PAIS, "[[:punct:] ]+", " "),
         PAIS = recode(PAIS, "Peru" = "Perú"))

PPA_WB <- read.csv(file.path(fuentes, "PPA.csv")) |>
  rename(COD.OCDE = Country.Code) |>
  filter(Classification.Code == "PPPGlob", Series.Code == 9020000) |>
  pivot_longer(7:last_col(), names_to = "A", values_to = "PPA") |>
  mutate(ANO4 = as.numeric(str_extract(A, "[0-9]{4}")),
         PPA  = suppressWarnings(as.numeric(PPA)))

ppa_tab <- IPC |>
  left_join(select(paises_meta, PAIS, COD.OCDE), by = "PAIS") |>
  left_join(select(PPA_WB, COD.OCDE, ANO4, PPA), by = c("COD.OCDE", "ANO4")) |>
  group_by(ANO4) |>
  mutate(IPC_USA = IPC[PAIS == "Estados Unidos"]) |>
  group_by(PAIS) |>
  mutate(PPA = if_else(!is.na(PPA), PPA,
                       PPA[ANO4 == 2017] * (IPC / IPC[ANO4 == 2017]) /
                         (IPC_USA / IPC_USA[ANO4 == 2017]))) |>
  ungroup() |>
  transmute(PAIS, ANO = ANO4, PPA)

# la cobertura del ingreso hay que medirla antes de filtrar, si no da siempre 1
cob_ing <- asal |>
  group_by(PAIS) |>
  summarise(cob = mean(ING > 0 & !is.na(ING)), .groups = "drop")

paises_ing <- filter(cob_ing, cob >= cob_min)$PAIS
excluidos_ing <- cob_ing |> filter(cob > 0, cob < cob_min) |> arrange(cob) |> pull(PAIS)

ASAL_ING <- asal |>
  filter(ING > 0, !is.na(WEIGHT)) |>
  left_join(ppa_tab, by = c("PAIS", "ANO")) |>
  mutate(ING_PPA = ING / PPA)

# salarios por categoría (lo que explora el usuario)
sal1 <- map_dfr(c("Total", vars_corte), function(v) {
  d <- if (v == "Total") mutate(ASAL_ING, categoria = "Total")
       else ASAL_ING |> filter(!is.na(.data[[v]])) |> mutate(categoria = .data[[v]])
  d |>
    filter(PAIS %in% paises_ing) |>
    group_by(region, PAIS, categoria) |>
    summarise(prom   = wmean(ING_PPA, WEIGHT),
              median = wquant(ING_PPA, WEIGHT, 0.5),
              .groups = "drop") |>
    mutate(corte = v)
}) |>
  mutate(categoria = factor(categoria,
                            levels = c("Total", unlist(niveles_corte, use.names = FALSE))))

guardar(sal1, "sal1")

pares_sal <- combn(vars_corte, 2, simplify = FALSE)

sal2 <- map_dfr(pares_sal, function(p) {
  ASAL_ING |>
    filter(PAIS %in% paises_ing, !is.na(.data[[p[1]]]), !is.na(.data[[p[2]]])) |>
    group_by(region, PAIS, cat1 = .data[[p[1]]], cat2 = .data[[p[2]]]) |>
    summarise(prom   = wmean(ING_PPA, WEIGHT),
              median = wquant(ING_PPA, WEIGHT, 0.5),
              n      = n(), .groups = "drop") |>
    filter(n >= 30) |>                        # celdas muy chicas no informan
    mutate(corte1 = p[1], corte2 = p[2]) |>
    ordenar("cat1", p[1]) |>
    ordenar("cat2", p[2]) |>
    mutate(categoria = paste(cat1, cat2, sep = " · "))
})

guardar(sal2, "sal2")

# ---- 5. figuras del documento de trabajo -----------------------------------

# 5a. empleo temporario, con Europa abierta entre involuntario y el resto.
#
# PRECATEMP capta todo contrato de duración determinada y PRECATEMP_INV marca el
# involuntario en el sentido de Eurostat (TEMPREAS == 2, "no encontró empleo
# permanente", sólo Europa), así que el otro segmento sale por diferencia. Ahí
# caen el voluntario declarado, la formación, el período de prueba, otros motivos
# y la no respuesta de TEMPREAS, que es 29% de los temporarios en Alemania, 31%
# en Países Bajos y 34% en Reino Unido: por eso el rótulo del residuo dice
# "voluntario u otros" y no "voluntario".
temp_resto <- preca |>
  filter(indicador == "PRECATEMP", corte == "Total", region != "Europa") |>
  transmute(PAIS, total = tasa, seg = as.character(region), val = tasa)

temp_eur <- asal |>
  filter(region == "Europa") |>
  group_by(PAIS) |>
  summarise(total = tasa(PRECATEMP, WEIGHT),
            inv   = tasa(PRECATEMP_INV, WEIGHT), .groups = "drop") |>
  transmute(PAIS, total,
            `Europa: temporario involuntario`       = inv,
            `Europa: temporario voluntario u otros` = total - inv) |>
  pivot_longer(-c(PAIS, total), names_to = "seg", values_to = "val")

temp_total <- bind_rows(temp_resto, temp_eur) |>
  mutate(seg = factor(seg, levels = c("América Latina", "China",
                                      "Europa: temporario involuntario",
                                      "Europa: temporario voluntario u otros")))

guardar(temp_total, "temp_total")

# 5b. cuentapropistas por calificación, sobre el empleo total
cuentapropismo <- B |>
  filter(CATOCUP %in% c("Asalariado", "Cuenta propia", "Patron", "Resto"),
         region %in% c("América Latina", "Europa")) |>
  mutate(grp = case_when(
    CATOCUP == "Cuenta propia" & CALIF %in% c("Baja", "Media") ~ "No profesional",
    CATOCUP == "Cuenta propia" & CALIF == "Alta"               ~ "Profesional",
    CATOCUP == "Cuenta propia"                                 ~ "Sin dato",
    TRUE ~ "resto")) |>
  group_by(region, PAIS, grp) |>
  summarise(w = sum(WEIGHT[!is.na(WEIGHT)]), .groups = "drop") |>
  group_by(PAIS) |> mutate(share = w / sum(w)) |> ungroup() |>
  filter(grp != "resto") |>
  mutate(grp = factor(grp, levels = c("No profesional", "Profesional", "Sin dato")))

guardar(cuentapropismo, "cuentapropismo")

# 5c. estructura educativa
educacion <- B |>
  group_by(PAIS) |> mutate(cob = mean(!is.na(EDUC))) |> ungroup() |>
  filter(EDUC %in% niveles_corte$EDUC, cob >= cob_min) |>
  group_by(region, PAIS, EDUC) |>
  summarise(w = sum(WEIGHT[!is.na(WEIGHT)]), .groups = "drop") |>
  group_by(PAIS) |> mutate(share = w / sum(w)) |> ungroup() |>
  mutate(EDUC = factor(EDUC, levels = niveles_corte$EDUC))

guardar(educacion, "educacion")

# 5d. perfiles ocupacionales: tamaño del establecimiento x calificación.
# A los independientes los clasifico por CALIF y no por TAMA. Servicio doméstico
# y empleo público van como bloque único, sin pedirles TAMA ni CALIF.
#
# Guardo los casos ponderados SIN normalizar, junto con el bloque de cada
# perfil, para que la app pueda prender y apagar bloques y recalcular las
# participaciones sobre el universo que queda.
#
# Universo (jul-2026), igual que en el script del documento
# (scripts/analisis/dt_precariedad_2019/05_perfiles_ocupacionales.R):
#   - los PATRONES van con los cuentapropistas: la base europea no los
#     distingue (no existe la categoría), así que separarlos rompía la
#     comparación con América Latina.
#   - "Resto" (familiares no remunerados y otros) queda AFUERA: no es un perfil
#     asalariado y cada script de país lo trataba distinto.
#   - los dos bloques sin dato son toggleables y van en los extremos de la
#     barra: arriba "cp_sindato", abajo "asal_sindato".
ord_calif <- c("Baja", "Media", "Alta")
# el tamaño ambiguo va entre Mediano y Grande para que el apilado siga siendo
# monótono; la app decide si mostrarlo aparte o mandarlo a uno de los dos
ord_tama  <- c("Pequeño", "Mediano", "Mediano o Grande", "Grande")
lev_cpsd  <- "Cuentapropistas y patrones sin dato de calificación"
lev_sd    <- "Servicio doméstico"
lev_pub   <- "Empleo público"
lev_asd   <- "Asalariados sin dato de tamaño o calificación"
niveles_perfil <- c(lev_cpsd,
                    paste("Cuentapropista", ord_calif, sep = " - "),
                    lev_sd,
                    as.vector(t(outer(ord_tama, ord_calif, paste, sep = " - "))),
                    lev_pub, lev_asd)

perfiles <- B |>
  # asalariados e independientes; "Resto" y las filas sin categoría, afuera
  filter(CATOCUP %in% c("Asalariado", "Cuenta propia", "Patron")) |>
  mutate(bloque = case_when(
    CATOCUP %in% c("Cuenta propia", "Patron") &
      CALIF %in% ord_calif                    ~ "cp",
    CATOCUP %in% c("Cuenta propia", "Patron") ~ "cp_sindato",
    SECTOR %in% "SD"                          ~ "sd",
    SECTOR %in% "Pub"                         ~ "pub",
    # sólo a los asalariados privados les pido tamaño y calificación: los demás
    # bloques se muestran sin desagregar, así que no los necesitan
    SECTOR %in% "Priv" &
      !is.na(TAMA) & CALIF %in% ord_calif     ~ "priv",
    # asalariado privado al que le falta tamaño o calificación: no entra en
    # ninguna barra (el faltante de tamaño es el más frecuente)
    SECTOR %in% "Priv"                        ~ "asal_sindato",
    # sin dato de SECTOR no se sabe si es privado o público: se descarta
    TRUE                                      ~ NA_character_)) |>
  filter(!is.na(bloque)) |>
  mutate(perfil = case_when(
    bloque == "cp"           ~ paste0("Cuentapropista - ", CALIF),
    bloque == "cp_sindato"   ~ lev_cpsd,
    bloque == "sd"           ~ lev_sd,
    bloque == "pub"          ~ lev_pub,
    bloque == "asal_sindato" ~ lev_asd,
    TRUE                     ~ paste0(TAMA, " - ", CALIF))) |>
  group_by(region, PAIS, Orden, bloque, perfil) |>
  summarise(casos = sum(WEIGHT, na.rm = TRUE), .groups = "drop") |>
  filter(!PAIS %in% c("Bolivia", "Rumanía", "Bulgaria")) |>   # cobertura insuficiente
  mutate(perfil = factor(perfil, levels = niveles_perfil))

guardar(perfiles, "perfiles")

# 5e. brechas de ingreso entre calificaciones. Son cocientes de ingreso medio,
# así que van con ING crudo, sin PPA.
medias <- ASAL_ING |>
  filter(PAIS %in% paises_ing, CALIF %in% ord_calif) |>
  group_by(region, PAIS, CALIF) |>
  summarise(m = wmean(ING, WEIGHT), .groups = "drop")

brechas <- medias |>
  pivot_wider(names_from = CALIF, values_from = m) |>
  transmute(region, PAIS,
            `Baja–Media` = Media / Baja,
            `Media–Alta` = Alta  / Media,
            `Baja–Alta`  = Alta  / Baja) |>
  pivot_longer(-c(region, PAIS), names_to = "par", values_to = "gap") |>
  mutate(par = factor(par, levels = c("Baja–Media", "Media–Alta", "Baja–Alta")))

guardar(brechas, "brechas")

# 5f. niveles de ingreso en PPA
niveles_ing <- ASAL_ING |>
  filter(PAIS %in% paises_ing, CALIF %in% ord_calif) |>
  group_by(region, PAIS, CALIF) |>
  summarise(m = wmean(ING_PPA, WEIGHT), .groups = "drop") |>
  mutate(CALIF = factor(CALIF, levels = ord_calif))

guardar(niveles_ing, "niveles_ing")

mediana_ing <- ASAL_ING |>
  filter(PAIS %in% paises_ing) |>
  group_by(region, PAIS) |>
  summarise(med = wquant(ING_PPA, WEIGHT, 0.5), .groups = "drop")

guardar(mediana_ing, "mediana_ing")

# ---- 6. metadatos y diccionarios de la app ---------------------------------

meta <- list(
  paises          = paises_meta |> filter(PAIS %in% unique(B$PAIS)) |> arrange(PAIS),
  regiones        = reg_levels,
  vars_corte      = vars_corte,
  niveles_corte   = niveles_corte,
  etiquetas_corte = etiquetas_corte,
  etiquetas_nivel = etiquetas_nivel,
  vars_preca      = vars_preca,
  cob_min         = cob_min,
  excluidos_ing   = excluidos_ing,
  anos_pais       = B |> distinct(PAIS, ANO) |> arrange(PAIS),
  generado        = Sys.Date())

saveRDS(meta, file.path(out_dir, "meta.rds"))
cat("==> meta\n")

# el diccionario y la homogeneización salen tal cual del Metadata.xlsx
metadata_xlsx <- file.path(repo, "Metadata.xlsx")
diccionario <- read.xlsx(metadata_xlsx, sheet = "Diccionario")
homogeneizacion <- read.xlsx(metadata_xlsx, sheet = "Homogeneizacion")

guardar(as_tibble(diccionario), "diccionario")
guardar(as_tibble(homogeneizacion), "homogeneizacion")

cat("\nListo. Datos en", out_dir, "\n")
