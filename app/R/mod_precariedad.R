# Tasas de precariedad: el explorador por categoría, más los rankings por país
# del documento de trabajo.

precariedadUI <- function(id) {
  ns <- NS(id)

  navset_card_underline(
    title = "Precariedad laboral",

    nav_panel(
      "Explorador",
      layout_sidebar(
        sidebar = sidebar(
          width = 310, title = "Filtros",
          selectInput(ns("indicador"), "Dimensión", OPCIONES_PRECA,
                      selected = "PRECAREG"),
          selectInput(ns("corte"), "Abrir por",
                      c("Total (sin abrir)" = "Total",
                        OPCIONES_CORTE[OPCIONES_CORTE != "CATOCUP"]),
                      selected = "SEXO"),
          hr(),
          paisesUI(ns("paises")),
          hr(),
          div(class = "pie-fig",
              "Las tasas se calculan sobre asalariados urbanos. Un país aparece ",
              "sólo si la dimensión tiene cobertura suficiente en su encuesta.")),
        girafeOutput(ns("g")))),

    nav_panel(
      "Ranking por país",
      layout_sidebar(
        sidebar = sidebar(
          width = 310, title = "Opciones",
          radioButtons(ns("rank_ind"), "Dimensión", OPCIONES_PRECA,
                       selected = "PRECAPT"),
          uiOutput(ns("aviso_rank"))),
        girafeOutput(ns("g_rank")))),

    nav_panel(
      "Empleo temporario (comparable)",
      div(class = "p-3",
          nota(
            tags$code("PRECATEMP"), " capta todo contrato de duración ",
            "determinada. En Europa se abre con ", tags$code("PRECATEMP_INV"),
            ", que marca al temporario que declara ", strong("no haber encontrado"),
            " un empleo permanente — la misma definición que usa Eurostat en ",
            tags$code("lfsa_etgar"), ". El resto queda por diferencia e incluye ",
            "el voluntario declarado, la formación, el período de prueba, otros ",
            "motivos y la no respuesta del motivo, que llega a un tercio de los ",
            "temporarios en Alemania, Países Bajos y Reino Unido.")),
      girafeOutput(ns("g_temp")))
  )
}

precariedadServer <- function(id, dark) {
  moduleServer(id, function(input, output, session) {

    base <- reactive({
      req(input$indicador, input$corte)
      filter(D$preca, indicador == input$indicador, corte == input$corte)
    })

    paises <- paisesServer("paises", reactive(sort(unique(base()$PAIS))))

    output$g <- renderGirafe({
      d <- base() |> filter(PAIS %in% paises())
      if (!nrow(d)) return(fig(fig_vacia(SIN_PAISES, dark()), dark(), alto = 2.4))

      if (input$corte == "Total") {
        pal <- setNames("#b2182b", "Total")
        d$categoria <- factor("Total")
      } else {
        p <- preparar_categorias(d, input$corte)
        d <- p$d; pal <- p$pal
      }

      # ordeno por la tasa total del país, así el ranking se lee de un vistazo
      orden <- d |> group_by(PAIS) |> summarise(m = mean(tasa)) |> arrange(m) |> pull(PAIS)
      d <- mutate(d, PAIS = factor(PAIS, levels = orden))

      subt <- if (input$corte == "Total")
        "% de asalariados urbanos alcanzados por la dimensión"
      else
        sprintf("%% de asalariados urbanos alcanzados por la dimensión, según %s",
                tolower(LAB_CORTE[[input$corte]]))

      g <- fig_preca_explora(d, pal, dark(), VARS_PRECA[[input$indicador]],
                             subt, FUENTE)
      fig(g, dark(), alto = alto_paises(n_distinct(d$PAIS)))
    })

    # ---- figuras del documento de trabajo -----------------------------------

    # el no registro y la seguridad social sólo tienen sentido en América Latina
    solo_amlat <- reactive(input$rank_ind %in% c("PRECAREG", "PRECASEG"))

    output$aviso_rank <- renderUI({
      if (solo_amlat())
        nota("Se muestra sólo América Latina: en Europa, Estados Unidos y China ",
             "estas dimensiones no se relevan de forma comparable.")
      else if (input$rank_ind == "PRECAPT")
        nota("China y El Salvador quedan afuera por falta de dato.")
      else
        nota("Para una versión comparable con Europa, ver la solapa ",
             strong("Empleo temporario (comparable)"), ".")
    })

    output$g_rank <- renderGirafe({
      d <- D$preca |> filter(indicador == input$rank_ind, corte == "Total")
      if (solo_amlat()) d <- filter(d, region == "América Latina")
      req(nrow(d) > 0)

      subt <- switch(input$rank_ind,
        PRECAPT   = "% de asalariados urbanos con jornada parcial no deseada",
        PRECATEMP = "% de asalariados con contrato de duración predeterminada",
        PRECAREG  = "% de asalariados sin registro de la relación laboral",
        PRECASEG  = "% de asalariados sin aportes jubilatorios")
      if (solo_amlat()) subt <- paste(subt, "· América Latina")

      g <- fig_ranking_preca(d, dark(), VARS_PRECA[[input$rank_ind]], subt,
                             FUENTE, por_region = !solo_amlat())
      fig(g, dark(), alto = alto_paises(n_distinct(d$PAIS)))
    })

    output$g_temp <- renderGirafe({
      cap <- paste(
        FUENTE,
        "Europa: EU-LFS 2018 (Alemania 2017). Involuntario = declara no haber",
        "encontrado un empleo permanente, la misma definición que Eurostat",
        "(lfsa_etgar); el resto de los temporarios incluye el voluntario declarado,",
        "la formación, el período de prueba, otros motivos y la no respuesta del",
        "motivo. En México, El Salvador y China se computa como temporario al",
        "asalariado sin contrato escrito.")
      fig(fig_temp_total(D$temp_total, dark(), cap), dark(),
          alto = alto_paises(n_distinct(D$temp_total$PAIS), extra = 2.2))
    })
  })
}
