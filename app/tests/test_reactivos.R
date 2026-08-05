# Ejercita la lógica reactiva de cada módulo sin navegador, con testServer.
setwd(file.path(here::here(), "app"))
for (f in list.files("R", full.names = TRUE)) source(f)
library(shiny)

ok <- 0; fallo <- 0
chk <- function(nombre, cond) {
  if (isTRUE(cond)) { ok <<- ok + 1; cat(sprintf("  ok   %s\n", nombre)) }
  else { fallo <<- fallo + 1; cat(sprintf("  FALLA %s\n", nombre)) }
}

cat("\n== estructura ==\n")
testServer(estructuraServer, args = list(dark = reactive(FALSE)), {
  session$setInputs(corte = "CALIF", corte2 = "", modo = "apilado", orden = "__abc")
  chk("base() trae las 3 calificaciones", n_distinct(base()$categoria) == 3)
  chk("listo() etiqueta y arma paleta", length(listo()$pal) == 3)
  chk("suma de shares por país ~ 1",
      all(abs(tapply(listo()$d$share, listo()$d$PAIS, sum) - 1) < 1e-8))

  # cruce en el orden canónico y en el inverso deben dar lo mismo
  session$setInputs(corte = "SECTOR", corte2 = "CALIF")
  a <- listo()$d |> arrange(PAIS, cat1, cat2)
  session$setInputs(corte = "CALIF", corte2 = "SECTOR")
  b <- listo()$d |> arrange(PAIS, cat2, cat1)
  chk("el cruce invertido da los mismos shares",
      isTRUE(all.equal(a$share, b$share, tolerance = 1e-10)))
  chk("el cruce invertido arma 9 combinaciones", length(listo()$pal) == 9)

  # elegir la misma variable dos veces se corrige solo
  session$setInputs(corte = "SECTOR", corte2 = "CALIF")
  session$setInputs(corte = "CALIF")
  chk("cruzar consigo misma no se toma como cruce", isFALSE(cruce()))
  chk("y cae a la vista de una sola variable", length(listo()$pal) == 3)
})

cat("\n== precariedad ==\n")
testServer(precariedadServer, args = list(dark = reactive(FALSE)), {
  session$setInputs(indicador = "PRECAREG", corte = "Total", rank_ind = "PRECAPT")
  chk("no registro sólo trae países con cobertura", nrow(base()) > 0)
  chk("las tasas están entre 0 y 1", all(base()$tasa >= 0 & base()$tasa <= 1))

  session$setInputs(indicador = "PRECAREG", corte = "SEXO")
  # Ecuador queda con una sola categoría: PRECAREG no llega a la cobertura
  # mínima entre las mujeres (56% de NA), así que el filtro la descarta
  chk("abrir por sexo da a lo sumo 2 categorías por país",
      all(table(base()$PAIS) <= 2))
  chk("casi todos los países traen las dos",
      mean(table(base()$PAIS) == 2) > 0.9)

  session$setInputs(rank_ind = "PRECASEG")
  chk("seguridad social se restringe a Am. Latina", isTRUE(solo_amlat()))
  session$setInputs(rank_ind = "PRECATEMP")
  chk("temporario no se restringe", isFALSE(solo_amlat()))
})

cat("\n== ingresos ==\n")
testServer(ingresosServer, args = list(dark = reactive(FALSE)), {
  session$setInputs(corte = "Total", corte2 = "", estimacion = "median",
                    ambito = "amlat", vista = "mediana")
  chk("total trae una fila por país", all(table(base()$PAIS) == 1))
  chk("los ingresos PPA son positivos", all(base()$median > 0, na.rm = TRUE))

  session$setInputs(corte = "CALIF")
  d <- listo()$d
  chk("alta gana más que baja en todos los países",
      {w <- tidyr::pivot_wider(d, id_cols = PAIS, names_from = categoria,
                               values_from = median)
       all(w$Alta > w$Baja, na.rm = TRUE)})

  session$setInputs(corte = "CALIF", corte2 = "SEXO")
  chk("con dos variables hay cruce", isTRUE(cruce()))
  session$setInputs(corte = "Total")
  chk("volver a Total desactiva el cruce", isFALSE(cruce()))
})

cat("\n== perfiles ocupacionales ==\n")
testServer(perfilesServer, args = list(dark = reactive(FALSE)), {
  session$setInputs(pub = FALSE, sd = TRUE, cpsd = TRUE, asd = TRUE, etiquetas = TRUE)
  chk("por defecto el universo es el privado", identical(universo(), "empleo privado"))
  chk("por defecto están los dos bloques sin dato",
      setequal(bloques(), c("cp", "priv", "sd", "cp_sindato", "asal_sindato")))
  priv <- datos()
  chk("las participaciones suman 1", all(abs(tapply(priv$share, priv$PAIS, sum) - 1) < 1e-9))

  session$setInputs(pub = TRUE)
  chk("prender público cambia el universo a total", identical(universo(), "empleo total"))
  chk("los asalariados sin dato siguen adentro", "asal_sindato" %in% bloques())
  session$setInputs(asd = FALSE)
  chk("y salen sólo con su propio interruptor", !"asal_sindato" %in% bloques())
  chk("apagarlos no toca a los independientes sin calificación",
      "cp_sindato" %in% bloques())
  session$setInputs(cpsd = FALSE)
  chk("cada gris tiene su interruptor", !"cp_sindato" %in% bloques())
  session$setInputs(asd = TRUE, cpsd = TRUE)
  tot <- datos()
  chk("las participaciones vuelven a sumar 1", all(abs(tapply(tot$share, tot$PAIS, sum) - 1) < 1e-9))
  chk("con público adentro baja el peso de los cuentapropistas", {
    f <- function(d) sum(d$share[d$PAIS == "Argentina" & grepl("^Cuentapropista", d$perfil)])
    f(tot) < f(priv)
  })

  # el tamaño ambiguo de la LFS europea ("no sabe, pero más de 10")
  amb <- "Mediano o Grande"
  hay_amb <- function(d) any(startsWith(as.character(d$perfil), amb))
  peso <- function(d, pais, fam)
    sum(d$share[d$PAIS == pais & startsWith(as.character(d$perfil), fam)])

  session$setInputs(pub = FALSE, sd = TRUE, cpsd = TRUE, asd = TRUE, ambiguo = "Mediano")
  med <- datos()
  chk("por defecto el tamaño ambiguo no se muestra aparte", !hay_amb(med))

  session$setInputs(ambiguo = "aparte")
  ap <- datos()
  chk("con 'aparte' aparece como familia propia", hay_amb(ap))
  chk("y las participaciones siguen sumando 1",
      all(abs(tapply(ap$share, ap$PAIS, sum) - 1) < 1e-9))

  session$setInputs(ambiguo = "Grande")
  gra <- datos()
  chk("con 'Grande' tampoco se muestra aparte", !hay_amb(gra))
  chk("mandarlo a Grande sube Grande y baja Mediano (Grecia)",
      peso(gra, "Grecia", "Grande") > peso(med, "Grecia", "Grande") &&
      peso(gra, "Grecia", "Mediano") < peso(med, "Grecia", "Mediano"))
  chk("el total de las dos familias no cambia según el destino",
      abs((peso(gra, "Grecia", "Mediano") + peso(gra, "Grecia", "Grande")) -
          (peso(med, "Grecia", "Mediano") + peso(med, "Grecia", "Grande"))) < 1e-9)
  chk("no toca a los países sin casos ambiguos (Argentina)",
      abs(peso(gra, "Argentina", "Grande") - peso(med, "Argentina", "Grande")) < 1e-9)

  session$setInputs(ambiguo = "Mediano")
  session$setInputs(pub = FALSE, sd = FALSE, cpsd = FALSE, asd = FALSE)
  chk("apagar los cuatro deja sólo cp y priv", setequal(bloques(), c("cp", "priv")))
})

cat("\n== selector de países ==\n")
testServer(paisesServer, args = list(disponibles = reactive(PAISES)), {
  session$setInputs(paises = c("Argentina", "Brasil"))
  chk("devuelve lo seleccionado", identical(session$getReturned()(),
                                            c("Argentina", "Brasil")))
})

cat(sprintf("\n%d ok, %d fallas\n", ok, fallo))
if (fallo > 0) quit(status = 1)
