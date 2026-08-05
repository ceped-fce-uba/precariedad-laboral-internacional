# Metadatos: el diccionario de variables y el mapeo de homogeneización por país,
# tal como salen de Metadata.xlsx.

metadatosUI <- function(id) {
  ns <- NS(id)

  navset_card_underline(
    title = "Metadatos",

    nav_panel(
      "Diccionario de variables",
      div(class = "p-3 pb-0",
          p(class = "text-muted-pm lead-narrow",
            "Todas las variables de la base homogeneizada, con su tipo, ",
            "descripción y valores posibles."),
          layout_columns(
            col_widths = c(6, 6),
            selectInput(ns("tipo"), "Tipo de variable", choices = NULL),
            selectInput(ns("variable"), "Variable", choices = NULL))),
      div(class = "p-3 pt-0", DTOutput(ns("diccionario")))),

    nav_panel(
      "Homogeneización por país",
      div(class = "p-3 pb-0",
          p(class = "text-muted-pm lead-narrow",
            "Cómo se reclasificaron las preguntas y categorías originales de ",
            "cada encuesta nacional para llegar a las variables comparables."),
          layout_columns(
            col_widths = c(4, 4, 4),
            selectInput(ns("h_pais"), "País", choices = NULL),
            selectInput(ns("h_var"), "Variable del dataset", choices = NULL),
            selectInput(ns("h_enc"), "Encuesta", choices = NULL))),
      div(class = "p-3 pt-0", DTOutput(ns("homogeneizacion"))))
  )
}

metadatosServer <- function(id) {
  moduleServer(id, function(input, output, session) {

    dicc  <- D$diccionario
    homog <- D$homogeneizacion

    opciones <- function(x, todas = "Todas") {
      v <- sort(unique(na.omit(as.character(x))))
      setNames(c("", v), c(todas, v))
    }

    updateSelectInput(session, "tipo",     choices = opciones(dicc$tipo))
    updateSelectInput(session, "variable", choices = opciones(dicc$variable))
    updateSelectInput(session, "h_pais",   choices = opciones(homog$Pais, "Todos"))
    updateSelectInput(session, "h_var",    choices = opciones(homog$`Variable.dataframe`))
    updateSelectInput(session, "h_enc",    choices = opciones(homog$Encuesta))

    # filtra sólo si el usuario eligió algo
    aplicar <- function(d, col, val) {
      if (is.null(val) || !nzchar(val)) d else d[!is.na(d[[col]]) & d[[col]] == val, ]
    }

    tabla <- function(d, ...) {
      datatable(d, rownames = FALSE, selection = "none", filter = "none",
                extensions = "Buttons",
                options = list(pageLength = 15, scrollX = TRUE,
                               dom = "Bfrtip", buttons = list("copy", "csv"),
                               language = list(
                                 search = "Buscar:",
                                 lengthMenu = "Mostrar _MENU_ filas",
                                 info = "_START_ a _END_ de _TOTAL_",
                                 paginate = list(previous = "Anterior",
                                                 `next` = "Siguiente"),
                                 emptyTable = "Sin registros para estos filtros")),
                ...)
    }

    output$diccionario <- renderDT({
      d <- dicc |> aplicar("tipo", input$tipo) |> aplicar("variable", input$variable)
      tabla(d)
    })

    output$homogeneizacion <- renderDT({
      cols <- intersect(c("Pais", "Encuesta", "Variable.original", "Etiqueta",
                          "Variable.dataframe", "Reclasificación"), names(homog))
      d <- homog |>
        aplicar("Pais", input$h_pais) |>
        aplicar("Variable.dataframe", input$h_var) |>
        aplicar("Encuesta", input$h_enc)
      tabla(d[, cols, drop = FALSE])
    })
  })
}
