# Carga de datos, paletas y formateadores. Shiny hace source() de todo R/ al
# arrancar, así que acá va lo que necesitan todos los módulos.

suppressMessages({
  library(shiny)
  library(bslib)
  library(bsicons)
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(forcats)
  library(stringr)
  library(purrr)
  library(scales)
  library(ggiraph)
  library(DT)
})

# ---- datos -----------------------------------------------------------------
# los rds los genera app/data-raw/01_prep_datos.R

D <- local({
  f <- list.files("data", pattern = "\\.rds$", full.names = TRUE)
  if (!length(f))
    stop("No hay datos en app/data/. Correr antes: Rscript app/data-raw/01_prep_datos.R")
  setNames(lapply(f, readRDS), tools::file_path_sans_ext(basename(f)))
})

META      <- D$meta
PAISES    <- META$paises$PAIS
REGIONES  <- META$regiones
REGION_DE <- setNames(META$paises$region, META$paises$PAIS)

# ---- etiquetas -------------------------------------------------------------

LAB_CORTE <- META$etiquetas_corte
LAB_NIVEL <- META$etiquetas_nivel
VARS_PRECA <- META$vars_preca

# vector nombrado listo para los selectInput: c("Sexo" = "SEXO", ...)
OPCIONES_CORTE <- setNames(names(LAB_CORTE), unname(LAB_CORTE))
OPCIONES_PRECA <- setNames(names(VARS_PRECA), unname(VARS_PRECA))

etiquetar <- function(x) {
  y <- LAB_NIVEL[as.character(x)]
  out <- ifelse(is.na(y), as.character(x), y)
  if (is.factor(x)) factor(out, levels = unname(ifelse(
    is.na(LAB_NIVEL[levels(x)]), levels(x), LAB_NIVEL[levels(x)]))) else out
}

SIN_PAISES <- "Elegí al menos un país para ver el gráfico."

FUENTE <- paste(
  "Fuente: elaboración propia en base al repositorio precariedad-laboral-internacional",
  "(CEPED-IIEP-UBA). Ocupados de áreas urbanas, 2019 (Europa, EE.UU. y China, 2018).",
  "Ponderado por WEIGHT.")

# ---- tipografía ------------------------------------------------------------

FUENTE_FIG <- if ("IBM Plex Serif" %in% systemfonts::system_fonts()$family)
  "IBM Plex Serif" else "sans"

# ---- paletas ---------------------------------------------------------------

PAL_REGION <- c("América Latina" = "#2166ac", "Europa" = "#d99441",
                "Estados Unidos" = "#2f6d6a", "China" = "#b2182b")

# los facets de una sola columna no tienen ancho para el nombre completo
REG_CORTO <- c("América Latina" = "América Latina", "Europa" = "Europa",
               "Estados Unidos" = "EE.UU.", "China" = "China")

PAL_CORTE <- list(
  SEXO    = c(Varon = "#4292c6", Mujer = "#d99441"),
  SECTOR  = c(Priv = "#2166ac", Pub = "#2f6d6a", SD = "#7a52a8"),
  CATOCUP = c(Asalariado = "#2166ac", `Cuenta propia` = "#b2182b",
              Patron = "#d99441", Resto = "#999999"),
  CALIF   = c(Baja = "#9ecae1", Media = "#4292c6", Alta = "#08519c"),
  TAMA    = c(Pequeño = "#fdd0a2", Mediano = "#f16913",
              `Mediano o Grande` = "#d94801", Grande = "#8c2d04"),
  EDUC    = c(Primaria = "#d99441", Secundaria = "#bdbdbd", Terciaria = "#2166ac"))

# tamaño ambiguo de la LFS europea (SIZEFIRM 15, "no sabe, pero más de 10
# personas"): abarca Mediano y Grande y no se puede repartir. mod_perfiles deja
# elegir a dónde mandarlo
LEV_AMBIGUO <- "Mediano o Grande"

PAL_CUENTAPROPIA <- c("No profesional" = "#b2182b", "Profesional" = "#2f6d6a",
                      "Sin dato" = "#bdbdbd")

PAL_PAR <- c(`Baja–Media` = "#66c2a5", `Media–Alta` = "#fc8d62", `Baja–Alta` = "#8da0cb")

PAL_TEMP <- c("América Latina" = "#2166ac", "China" = "#b2182b",
              "Europa: temporario involuntario" = "#d99441",
              "Europa: temporario voluntario u otros" = "#bdbdbd")

# Perfiles ocupacionales: 4 familias x 3 tonos, el color se oscurece a medida
# que sube la calificación. Los bloques que van sin desagregar tienen color
# propio; los tres grises se distinguen por luminancia (0.74 / 0.27 / 0.54).
PAL_PERFIL <- local({
  tonos <- function(col, niveles)
    setNames(c(colorspace::lighten(col, 0.60), colorspace::lighten(col, 0.30), col),
             niveles)
  calif <- c("Baja", "Media", "Alta")
  c("Cuentapropistas y patrones sin dato de calificación" = "#d4d4d4",
    tonos("#b2182b", paste("Cuentapropista", calif, sep = " - ")),
    "Servicio doméstico"        = "#7a52a8",
    tonos("#2166ac", paste("Pequeño", calif, sep = " - ")),
    tonos("#d99441", paste("Mediano", calif, sep = " - ")),
    # el tamaño ambiguo de la LFS europea: verde oliva, a mitad de camino entre
    # el naranja de Mediano y el verde azulado de Grande
    tonos("#7f8c45", paste("Mediano o Grande", calif, sep = " - ")),
    tonos("#2f6d6a", paste("Grande",  calif, sep = " - ")),
    "Empleo público" = "#454545",
    "Asalariados sin dato de tamaño o calificación" = "#8a8a8a")
})

# si algún nivel se queda sin color, mejor enterarse al arrancar que ver barras
# grises en producción
local({
  faltan <- setdiff(levels(D$perfiles$perfil), names(PAL_PERFIL))
  if (length(faltan))
    stop("PAL_PERFIL no cubre estos perfiles: ", paste(faltan, collapse = ", "))
})

# en modo oscuro levanto un poco los colores para que no se pierdan contra el fondo
aclarar <- function(pal, dark) if (dark) colorspace::lighten(pal, 0.18) else pal

# ---- formateadores ---------------------------------------------------------

# "a", "a y b", "a, b y c"
enumerar <- function(x) {
  if (length(x) < 2) return(paste(x, collapse = ""))
  paste(paste(head(x, -1), collapse = ", "), "y", tail(x, 1))
}

pct  <- function(x, acc = 0.1) percent(x, accuracy = acc, decimal.mark = ",", suffix = "%")
num0 <- function(x) number(x, accuracy = 1, big.mark = ".", decimal.mark = ",")
num1 <- function(x) number(x, accuracy = 0.1, decimal.mark = ",")

# ---- utilidades de datos ---------------------------------------------------

# Deja `categoria` como factor ya etiquetado y devuelve la paleta con los mismos
# nombres, para una variable de corte o para el cruce de dos. En el cruce el
# color lo pone la primera variable y el tono, la segunda.
preparar_categorias <- function(d, v1, v2 = NULL) {
  lab <- function(x) unname(LAB_NIVEL[as.character(x)])

  if (is.null(v2) || !nzchar(v2)) {
    niv  <- META$niveles_corte[[v1]]
    labs <- lab(niv)
    pal  <- setNames(unname(PAL_CORTE[[v1]][niv]), labs)
    d$categoria <- factor(lab(d$categoria), levels = labs)
  } else {
    c1 <- META$niveles_corte[[v1]]
    c2 <- META$niveles_corte[[v2]]
    base <- PAL_CORTE[[v1]][c1]
    amt  <- if (length(c2) == 1) 0 else seq(0.62, 0, length.out = length(c2))
    pal <- unlist(lapply(seq_along(c1), function(i)
      setNames(vapply(amt, function(a) colorspace::lighten(base[[i]], a), character(1)),
               paste(lab(c1[i]), lab(c2), sep = " · "))))
    d$categoria <- factor(paste(lab(d$cat1), lab(d$cat2), sep = " · "),
                          levels = names(pal))
  }

  list(d = filter(d, !is.na(categoria)), pal = pal)
}

# pesos2/sal2 guardan cada par una sola vez y en orden canónico; si el usuario
# lo pide al revés, doy vuelta las columnas
buscar_cruce <- function(d, v1, v2) {
  x <- filter(d, corte1 == v1, corte2 == v2)
  if (nrow(x)) return(x)
  filter(d, corte1 == v2, corte2 == v1) |>
    mutate(a = cat2, b = cat1) |>
    select(-cat1, -cat2) |>
    rename(cat1 = a, cat2 = b) |>
    mutate(corte1 = v1, corte2 = v2,
           categoria = paste(cat1, cat2, sep = " · "))
}
