# Selector de países, con atajos por región. Lo usan los tres exploradores.

paisesUI <- function(id, label = "Países") {
  ns <- NS(id)
  tagList(
    tags$label(label, class = "form-label mb-1"),
    div(class = "atajos d-flex gap-1 flex-wrap mb-2",
        actionButton(ns("todos"),  "Todos",      class = "btn btn-outline-secondary"),
        actionButton(ns("amlat"),  "Am. Latina", class = "btn btn-outline-secondary"),
        actionButton(ns("europa"), "Europa",     class = "btn btn-outline-secondary"),
        actionButton(ns("nada"),   "Limpiar",    class = "btn btn-outline-secondary")),
    selectizeInput(ns("paises"), NULL, choices = NULL, multiple = TRUE,
                   width = "100%",
                   options = list(plugins = list("remove_button"),
                                  placeholder = "Elegí uno o más países"))
  )
}

# `disponibles` es un reactive con los países que tienen dato en la vista actual
paisesServer <- function(id, disponibles) {
  moduleServer(id, function(input, output, session) {

    fijar <- function(v) {
      updateSelectizeInput(session, "paises",
                           selected = intersect(v, isolate(disponibles())))
    }

    # cuando cambia el universo, conservo lo que el usuario ya había elegido
    observeEvent(disponibles(), {
      d   <- disponibles()
      sel <- intersect(isolate(input$paises), d)
      if (!length(sel)) sel <- d
      updateSelectizeInput(session, "paises", choices = d, selected = sel)
    }, ignoreNULL = FALSE)

    observeEvent(input$todos,  fijar(disponibles()))
    observeEvent(input$amlat,  fijar(names(REGION_DE)[REGION_DE == "América Latina"]))
    observeEvent(input$europa, fijar(names(REGION_DE)[REGION_DE == "Europa"]))
    observeEvent(input$nada,
                 updateSelectizeInput(session, "paises", selected = character(0)))

    reactive(input$paises)
  })
}

# ---- piezas de UI que se repiten -------------------------------------------

# bloque de texto explicativo, con la barrita de color a la izquierda
nota <- function(...) div(class = "nota", ...)
