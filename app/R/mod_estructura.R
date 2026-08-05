# Estructura del empleo: el explorador de distribuciones, más las figuras de
# perfiles ocupacionales, cuentapropismo y educación del documento de trabajo.

estructuraUI <- function(id) {
  ns <- NS(id)

  navset_card_underline(
    title = "Estructura del empleo",

    nav_panel(
      "Explorador",
      layout_sidebar(
        sidebar = sidebar(
          width = 310, title = "Filtros",
          selectInput(ns("corte"), "Variable", OPCIONES_CORTE, selected = "CALIF"),
          selectInput(ns("corte2"), "Cruzar con",
                      c("— ninguna —" = "", OPCIONES_CORTE), selected = ""),
          radioButtons(ns("modo"), "Barras",
                       c("Apiladas" = "apilado", "Agrupadas" = "agrupado"),
                       selected = "apilado", inline = TRUE),
          selectInput(ns("orden"), "Ordenar países por", choices = NULL),
          hr(),
          paisesUI(ns("paises"))),
        girafeOutput(ns("g")))),

    nav_panel(
      "Cuentapropismo",
      div(class = "p-3", girafeOutput(ns("g_cp")))),

    nav_panel(
      "Educación",
      div(class = "p-3", girafeOutput(ns("g_educ"))))
  )
}

estructuraServer <- function(id, dark) {
  moduleServer(id, function(input, output, session) {

    # cruzar una variable consigo misma no tiene sentido: lo descarto acá y no
    # sólo en el input, para no depender de que vuelva el update del cliente
    cruce <- reactive(nzchar(input$corte2 %||% "") &&
                        !identical(input$corte2, input$corte))

    observeEvent(input$corte, {
      if (identical(input$corte, input$corte2))
        updateSelectInput(session, "corte2", selected = "")
    })

    # con dos variables las barras sólo tienen sentido apiladas
    observeEvent(cruce(), {
      if (cruce()) updateRadioButtons(session, "modo", selected = "apilado")
    })

    base <- reactive({
      req(input$corte)
      if (cruce()) buscar_cruce(D$pesos2, input$corte, input$corte2)
      else filter(D$pesos1, corte == input$corte)
    })

    # ojo: la condición tiene que ser la misma que usa base(), si no se pide el
    # cruce sobre datos de una sola variable
    listo <- reactive(preparar_categorias(base(), input$corte,
                                          if (cruce()) input$corte2 else NULL))

    paises <- paisesServer("paises", reactive(sort(unique(base()$PAIS))))

    # las opciones de orden son las categorías de la vista actual
    observeEvent(listo(), {
      cats <- levels(listo()$d$categoria)
      updateSelectInput(session, "orden",
                        choices = c("Alfabético" = "__abc", setNames(cats, cats)),
                        selected = isolate(input$orden) %||% "__abc")
    })

    datos <- reactive({
      d <- listo()$d |> filter(PAIS %in% paises())
      if (!nrow(d)) return(NULL)
      ord <- input$orden %||% "__abc"
      if (identical(ord, "__abc") || !ord %in% levels(d$categoria))
        mutate(d, PAIS = factor(PAIS, levels = rev(sort(unique(PAIS)))))
      else
        mutate(d, PAIS = fct_reorder(PAIS, if_else(categoria == ord, share, 0), sum))
    })

    output$g <- renderGirafe({
      d <- datos()
      if (is.null(d)) return(fig(fig_vacia(SIN_PAISES, dark()), dark(), alto = 2.4))

      titulo <- if (cruce())
        sprintf("Distribución del empleo según %s y %s",
                tolower(LAB_CORTE[[input$corte]]), tolower(LAB_CORTE[[input$corte2]]))
      else
        sprintf("Distribución del empleo según %s", tolower(LAB_CORTE[[input$corte]]))

      subt <- if (input$modo == "apilado")
        "participación de cada categoría en el empleo urbano total"
      else
        "participación de cada categoría en el empleo urbano total, barras comparables"

      g <- fig_distribucion(d, listo()$pal, dark(), input$modo, titulo, subt, FUENTE)
      fig(g, dark(), alto = alto_paises(n_distinct(d$PAIS)))
    })

    # ---- figuras del documento de trabajo -----------------------------------

    output$g_cp <- renderGirafe({
      fig(fig_cuentapropismo(D$cuentapropismo, dark(), FUENTE), dark(),
          alto = alto_paises(n_distinct(D$cuentapropismo$PAIS), extra = 2.2))
    })

    output$g_educ <- renderGirafe({
      fig(fig_educacion(D$educacion, dark(), FUENTE), dark(),
          alto = alto_paises(n_distinct(D$educacion$PAIS)))
    })
  })
}
