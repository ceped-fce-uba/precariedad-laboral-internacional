# Ingresos laborales en dólares PPA: el explorador por categoría, más las
# brechas por calificación y los niveles del documento de trabajo.

ingresosUI <- function(id) {
  ns <- NS(id)

  navset_card_underline(
    title = "Ingresos laborales",

    nav_panel(
      "Explorador",
      layout_sidebar(
        sidebar = sidebar(
          width = 310, title = "Filtros",
          selectInput(ns("corte"), "Abrir por",
                      c("Total (sin abrir)" = "Total", OPCIONES_CORTE),
                      selected = "CALIF"),
          selectInput(ns("corte2"), "Cruzar con",
                      c("— ninguna —" = "", OPCIONES_CORTE), selected = ""),
          radioButtons(ns("estimacion"), "Estimación",
                       c("Media ponderada" = "prom", "Mediana" = "median"),
                       selected = "median"),
          hr(),
          paisesUI(ns("paises")),
          hr(),
          uiOutput(ns("aviso"))),
        girafeOutput(ns("g")))),

    nav_panel(
      "Brechas por calificación",
      layout_sidebar(
        sidebar = sidebar(
          width = 310, title = "Opciones",
          radioButtons(ns("ambito"), "Ámbito",
                       c("América Latina" = "amlat", "Todos los países" = "todos"),
                       selected = "amlat"),
          nota("La brecha es el cociente entre los ingresos medios de dos ",
               "calificaciones. Al ser un cociente dentro de cada país, ",
               strong("no depende de la PPA"), " ni del tipo de cambio.")),
        girafeOutput(ns("g_brechas")))),

    nav_panel(
      "Niveles en PPA",
      layout_sidebar(
        sidebar = sidebar(
          width = 310, title = "Opciones",
          radioButtons(ns("vista"), "Ver",
                       c("Mediana por país" = "mediana",
                         "Media por calificación" = "calif"),
                       selected = "mediana"),
          nota("Ingreso laboral mensual convertido a dólares PPA con el ",
               "benchmark del Banco Mundial de 2017, extrapolado por IPC.")),
        girafeOutput(ns("g_niveles"))))
  )
}

ingresosServer <- function(id, dark) {
  moduleServer(id, function(input, output, session) {

    # igual que en estructura: descarto el cruce inválido acá y no sólo en el
    # input, para no depender de que vuelva el update del cliente
    cruce <- reactive(nzchar(input$corte2 %||% "") && input$corte != "Total" &&
                        !identical(input$corte2, input$corte))

    observeEvent(input$corte, {
      if (identical(input$corte, input$corte2) || input$corte == "Total")
        updateSelectInput(session, "corte2", selected = "")
    })

    base <- reactive({
      req(input$corte)
      if (cruce()) buscar_cruce(D$sal2, input$corte, input$corte2)
      else filter(D$sal1, corte == input$corte)
    })

    listo <- reactive({
      d <- base()
      if (input$corte == "Total") {
        d$categoria <- factor("Total")
        list(d = d, pal = setNames("#2166ac", "Total"))
      } else {
        preparar_categorias(d, input$corte, if (cruce()) input$corte2 else NULL)
      }
    })

    paises <- paisesServer("paises", reactive(sort(unique(base()$PAIS))))

    output$aviso <- renderUI({
      ex <- META$excluidos_ing
      div(class = "pie-fig",
          "Asalariados urbanos con ingreso positivo. Quedan afuera los países ",
          "sin dato de ingreso o con cobertura menor a ", pct(META$cob_min, 1),
          if (length(ex)) paste0(" (", paste(ex, collapse = ", "), ")") else "", ".")
    })

    output$g <- renderGirafe({
      d <- listo()$d |> filter(PAIS %in% paises())
      d$valor <- d[[input$estimacion]]
      d <- filter(d, !is.na(valor))
      if (!nrow(d)) return(fig(fig_vacia(SIN_PAISES, dark()), dark(), alto = 2.4))

      orden <- d |> group_by(PAIS) |> summarise(m = median(valor)) |>
        arrange(m) |> pull(PAIS)
      d <- mutate(d, PAIS = factor(PAIS, levels = orden))

      titulo <- if (input$corte == "Total")
        "Ingreso laboral mensual en dólares PPA"
      else if (cruce())
        sprintf("Ingreso laboral según %s y %s",
                tolower(LAB_CORTE[[input$corte]]), tolower(LAB_CORTE[[input$corte2]]))
      else
        sprintf("Ingreso laboral según %s", tolower(LAB_CORTE[[input$corte]]))

      subt <- paste(if (input$estimacion == "prom") "media ponderada" else "mediana ponderada",
                    "· asalariados urbanos · dólares PPA de 2017")

      g <- fig_salarios(d, listo()$pal, dark(), titulo, subt, FUENTE)
      fig(g, dark(), alto = alto_paises(n_distinct(d$PAIS)))
    })

    # ---- figuras del documento de trabajo -----------------------------------

    output$g_brechas <- renderGirafe({
      amlat <- input$ambito == "amlat"
      d <- D$brechas
      if (amlat) d <- filter(d, region == "América Latina")

      if (amlat) {
        # agrego el promedio simple de los países como referencia regional
        reg <- d |> group_by(par) |> summarise(gap = mean(gap), .groups = "drop") |>
          mutate(PAIS = "Regional", region = "América Latina")
        ord <- d |> filter(par == "Baja–Alta") |> arrange(desc(gap)) |> pull(PAIS)
        d <- bind_rows(reg, d) |>
          mutate(PAIS = factor(PAIS, levels = c("Regional", ord)))
      } else {
        ord <- d |> filter(par == "Baja–Alta") |> arrange(region, gap) |> pull(PAIS)
        d <- mutate(d, PAIS = factor(PAIS, levels = ord))
      }

      cap <- paste(FUENTE, "El cociente no depende de la PPA.",
                   if (amlat) "Regional = promedio simple de los países." else "")
      g <- fig_brechas(d, dark(), facetar = !amlat,
                       "Brechas de ingreso medio entre calificaciones",
                       "cociente entre ingresos medios por calificación · asalariados",
                       cap)
      fig(g, dark(), alto = 5.6, ancho = if (amlat) 10 else 13)
    })

    output$g_niveles <- renderGirafe({
      cap <- paste(FUENTE, "Ingreso laboral mensual convertido a dólares PPA",
                   "(benchmark 2017 extrapolado por IPC).")
      if (input$vista == "mediana")
        fig(fig_mediana_ing(D$mediana_ing, dark(), cap), dark(),
            alto = alto_paises(n_distinct(D$mediana_ing$PAIS)))
      else
        fig(fig_niveles_ing(D$niveles_ing, dark(), cap), dark(),
            alto = 6, ancho = 13)
    })
  })
}
