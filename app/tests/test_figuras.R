# Chequea que cada figura se construya en claro y en oscuro, y que el orden de
# apilado siga a los niveles del factor.
#
# Correr con:  Rscript app/tests/test_figuras.R

setwd(file.path(here::here(), "app"))
for (f in list.files("R", full.names = TRUE)) source(f)

ok <- 0; fallo <- 0
chk <- function(nombre, cond) {
  if (isTRUE(cond)) { ok <<- ok + 1; cat(sprintf("  ok    %s\n", nombre)) }
  else { fallo <<- fallo + 1; cat(sprintf("  FALLA %s\n", nombre)) }
}

# ---- todas las figuras renderizan, en los dos modos ------------------------

cat("\n== construcción de figuras ==\n")

# arma el universo de perfiles como lo hace mod_perfiles
perfiles_universo <- function(pub, sd, cpsd = FALSE, asd = FALSE) {
  bl <- c("cp", "priv", if (sd) "sd", if (pub) "pub",
          if (cpsd) "cp_sindato", if (asd) "asal_sindato")
  D$perfiles |>
    filter(bloque %in% bl) |>
    group_by(region, PAIS, Orden, perfil) |>
    summarise(casos = sum(casos), .groups = "drop") |>
    group_by(PAIS) |> mutate(share = casos / sum(casos)) |> ungroup()
}

render_ok <- function(g) {
  tmp <- tempfile(fileext = ".png")
  on.exit(unlink(tmp))
  isTRUE(tryCatch({ ggsave(tmp, g, width = 10, height = 7, dpi = 72); TRUE },
                  error = function(e) FALSE))
}

figuras <- list(
  distribucion = function(dk) {
    p <- preparar_categorias(filter(D$pesos1, corte == "CALIF"), "CALIF")
    fig_distribucion(p$d, p$pal, dk, "apilado", "t", "s", FUENTE) },
  cruce = function(dk) {
    p <- preparar_categorias(buscar_cruce(D$pesos2, "SECTOR", "CALIF"), "SECTOR", "CALIF")
    fig_distribucion(p$d, p$pal, dk, "apilado", "t", "s", FUENTE) },
  precariedad = function(dk) {
    p <- preparar_categorias(filter(D$preca, indicador == "PRECAREG", corte == "SEXO"), "SEXO")
    fig_preca_explora(p$d, p$pal, dk, "t", "s", FUENTE) },
  salarios = function(dk) {
    p <- preparar_categorias(filter(D$sal1, corte == "CALIF"), "CALIF")
    p$d$valor <- p$d$median
    fig_salarios(p$d, p$pal, dk, "t", "s", FUENTE) },
  ranking = function(dk)
    fig_ranking_preca(filter(D$preca, indicador == "PRECAPT", corte == "Total"),
                      dk, "t", "s", FUENTE, TRUE),
  temporario    = function(dk) fig_temp_total(D$temp_total, dk, FUENTE),
  cuentapropismo = function(dk) fig_cuentapropismo(D$cuentapropismo, dk, FUENTE),
  educacion     = function(dk) fig_educacion(D$educacion, dk, FUENTE),
  perfiles      = function(dk) fig_perfiles(perfiles_universo(TRUE, TRUE, TRUE), dk,
                                            "sub", FUENTE),
  brechas       = function(dk) fig_brechas(D$brechas, dk, TRUE, "t", "s", FUENTE),
  niveles       = function(dk) fig_niveles_ing(D$niveles_ing, dk, FUENTE),
  mediana       = function(dk) fig_mediana_ing(D$mediana_ing, dk, FUENTE),
  vacia         = function(dk) fig_vacia(SIN_PAISES, dk))

for (nm in names(figuras))
  for (dk in c(FALSE, TRUE))
    chk(sprintf("%s (%s)", nm, if (dk) "oscuro" else "claro"),
        render_ok(figuras[[nm]](dk)))

# ---- el apilado respeta el orden de los niveles ----------------------------
#
# ggiraph pasa tooltip y data_id como aesthetics discretos, y ggplot los mete en
# el `group`. Si no fijamos group a mano, el apilado sale en el orden de las
# filas y las etiquetas (que no llevan esos aesthetics) quedan sobre el
# segmento equivocado. Este chequeo es la red contra esa regresión.

cat("\n== orden de apilado ==\n")

orden_apilado <- function(g, pal) {
  b <- ggplot_build(g)$data[[1]]
  b <- b[order(b$xmin), ]
  names(pal)[match(b$fill, unname(pal))]
}

p <- preparar_categorias(filter(D$pesos1, corte == "CALIF"), "CALIF")
d1 <- filter(p$d, PAIS == "Alemania")
chk("distribución apila en orden Baja-Media-Alta",
    identical(orden_apilado(fig_distribucion(d1, p$pal, FALSE, "apilado", "t", "s", FUENTE),
                            p$pal),
              c("Baja", "Media", "Alta")))

chk("los anchos coinciden con los shares", {
  g <- fig_distribucion(d1, p$pal, FALSE, "apilado", "t", "s", FUENTE)
  b <- ggplot_build(g)$data[[1]]; b <- b[order(b$xmin), ]
  esperado <- d1$share[order(d1$categoria)]
  all(abs((b$xmax - b$xmin) - esperado) < 1e-9)
})

pe <- aclarar(PAL_CORTE$EDUC, FALSE)
chk("educación apila en orden Primaria-Secundaria-Terciaria",
    identical(orden_apilado(fig_educacion(filter(D$educacion, PAIS == "Alemania"),
                                          FALSE, FUENTE), pe),
              c("Primaria", "Secundaria", "Terciaria")))

# ---- los interruptores del universo de perfiles ----------------------------

cat("\n== universo de perfiles ==\n")

for (nm in c("privado (por defecto)", "total", "privado sin SD", "total sin SD")) {
  args <- switch(nm,
    "privado (por defecto)" = c(FALSE, TRUE), "total" = c(TRUE, TRUE),
    "privado sin SD" = c(FALSE, FALSE),       "total sin SD" = c(TRUE, FALSE))
  d <- perfiles_universo(args[1], args[2])
  chk(sprintf("%s: las participaciones suman 1 en cada país", nm),
      all(abs(tapply(d$share, d$PAIS, sum) - 1) < 1e-9))
}

chk("por defecto no aparece el empleo público",
    !"Empleo público" %in% as.character(perfiles_universo(FALSE, TRUE)$perfil))
lev_asd <- "Asalariados sin dato de tamaño o calificación"
chk("apagado, el bloque de asalariados sin dato no aparece",
    !lev_asd %in% as.character(perfiles_universo(FALSE, TRUE)$perfil))
chk("prendido, aparece como bloque propio",
    lev_asd %in% as.character(perfiles_universo(FALSE, TRUE, FALSE, TRUE)$perfil))
chk("apagado, los independientes sin calificación tampoco aparecen",
    !"Cuentapropistas y patrones sin dato de calificación" %in% as.character(perfiles_universo(FALSE, TRUE)$perfil))
chk("y con su propio interruptor sí",
    "Cuentapropistas y patrones sin dato de calificación" %in%
      as.character(perfiles_universo(FALSE, TRUE, TRUE)$perfil))
# van en los dos universos: el único bloque que separa privado de total es el público
chk("el bloque gris de asalariados está en el privado y en el total",
    all(sapply(list(c(FALSE, TRUE), c(TRUE, TRUE)), function(a)
      lev_asd %in%
        as.character(perfiles_universo(a[1], a[2], FALSE, TRUE)$perfil))))
chk("los tres grises son colores distintos",
    length(unique(PAL_PERFIL[c("Cuentapropistas y patrones sin dato de calificación", "Empleo público",
                               lev_asd)])) == 3)
chk("y se separan bien en luminancia (>= 0.15)", {
  lum <- function(h) { v <- col2rgb(h)/255; 0.2126*v[1,]+0.7152*v[2,]+0.0722*v[3,] }
  L <- sort(lum(PAL_PERFIL[c("Cuentapropistas y patrones sin dato de calificación", "Empleo público", lev_asd)]))
  all(diff(L) >= 0.15)
})
# el universo son asalariados e independientes: "Resto" no entra por ningún lado
chk("la categoría Resto queda fuera del universo",
    nrow(D$perfiles) > 0 &&
      !any(D$perfiles$bloque == "resto", na.rm = TRUE))
chk("los dos bloques grises van en los extremos de la barra", {
  lv <- levels(D$perfiles$perfil)
  lv[1] == "Cuentapropistas y patrones sin dato de calificación" && lv[length(lv)] == lev_asd
})
# el tamaño ambiguo de la LFS europea tiene familia propia, con color propio y
# ubicada entre Mediano y Grande para que el apilado siga el gradiente de tamaño
chk("la familia ambigua existe y tiene los tres tonos de calificación",
    all(paste("Mediano o Grande", c("Baja","Media","Alta"), sep = " - ")
        %in% levels(D$perfiles$perfil)))
chk("y está entre Mediano y Grande en el orden de apilado", {
  lv  <- levels(D$perfiles$perfil)
  pos <- function(f) which(startsWith(lv, f))
  max(pos("Mediano - ")) < min(pos("Mediano o Grande")) &&
    max(pos("Mediano o Grande")) < min(pos("Grande - "))
})
chk("no comparte color con Mediano ni con Grande", {
  fam <- function(f) unname(PAL_PERFIL[paste(f, c("Baja","Media","Alta"), sep = " - ")])
  !any(fam("Mediano o Grande") %in% c(fam("Mediano"), fam("Grande")))
})
chk("sólo Europa tiene casos ambiguos", {
  p <- D$perfiles[startsWith(as.character(D$perfiles$perfil), "Mediano o Grande"), ]
  nrow(p) > 0 && all(p$region == "Europa")
})
chk("con el interruptor prendido sí aparece",
    "Empleo público" %in% as.character(perfiles_universo(TRUE, TRUE)$perfil))
chk("apagar servicio doméstico lo saca",
    !"Servicio doméstico" %in% as.character(perfiles_universo(FALSE, FALSE)$perfil))
chk("sacar un bloque sube la participación de los que quedan", {
  a <- perfiles_universo(FALSE, TRUE) |> filter(PAIS == "Brasil", perfil == "Grande - Media")
  b <- perfiles_universo(FALSE, FALSE) |> filter(PAIS == "Brasil", perfil == "Grande - Media")
  b$share > a$share
})
chk("los cuentapropistas están en todos los universos",
    all(sapply(list(c(FALSE,TRUE), c(TRUE,TRUE), c(FALSE,FALSE), c(TRUE,FALSE)),
               function(a) any(grepl("^Cuentapropista",
                                     perfiles_universo(a[1], a[2])$perfil)))))

# los valores por defecto de la UI tienen que dar el universo del PNG del
# documento: empleo público afuera, los otros dos adentro
cat("\n== valores por defecto de los interruptores ==\n")
local({
  html <- as.character(perfilesUI("p"))
  prendido <- function(id)
    grepl(sprintf('id="p-%s"[^>]*checked', id), html) ||
    grepl(sprintf('checked[^>]*id="p-%s"', id), html)
  chk("empleo público arranca apagado", !prendido("pub"))
  chk("servicio doméstico arranca prendido", prendido("sd"))
  chk("independientes sin calificación arranca prendido", prendido("cpsd"))
  chk("asalariados sin dato arranca prendido", prendido("asd"))
})

# ---- el svg que sale de girafe es UTF-8 válido -----------------------------
#
# data_id se escribe sin respetar el encoding, así que los acentos lo rompían.

cat("\n== encoding del svg ==\n")
for (nm in c("mediana", "perfiles", "temporario", "distribucion")) {
  h <- fig(figuras[[nm]](FALSE), FALSE, alto = 7)$x$html
  chk(sprintf("%s produce svg UTF-8 válido", nm),
      !is.na(iconv(h, "UTF-8", "UTF-8")))
}

cat(sprintf("\n%d ok, %d fallas\n", ok, fallo))
if (fallo > 0) quit(status = 1)
