# Perfiles ocupacionales: el Gráfico 1 del documento de trabajo, con los bloques
# del universo prendiéndose y apagándose.
#
# Los datos vienen sin normalizar (casos ponderados por país, perfil y bloque),
# así que al sacar un bloque las participaciones se recalculan sobre el universo
# que queda.
#
# OJO (jul-2026): los valores por defecto ya NO reproducen el
# g_perfiles_ocupacionales.png del documento. El script del documento pasó a
# excluir del universo a los independientes sin calificación, a los asalariados
# sin tamaño o sin calificación y al tamaño ambiguo europeo; acá los tres siguen
# adentro por defecto, porque el punto de la app es poder verlos. Para acercarse
# a la figura hay que apagar los dos interruptores de "sin dato"; el tamaño
# ambiguo no se puede excluir desde acá (sólo mandarlo a Mediano, a Grande o
# mostrarlo aparte).

perfilesUI <- function(id) {
  ns <- NS(id)

  card(
    full_screen = TRUE,
    card_header("Perfiles ocupacionales"),
    layout_sidebar(
      sidebar = sidebar(
        width = 330, title = "Universo",

        p(class = "text-muted-pm mb-2", style = "font-size:.82rem;",
          "Los cuentapropistas y los asalariados privados con dato de tamaño y ",
          "calificación están siempre. Prendé o apagá los demás bloques: las ",
          "participaciones se recalculan sobre el universo que quede."),

        input_switch(ns("pub"), "Empleo público", value = FALSE),
        input_switch(ns("sd"),  "Servicio doméstico", value = TRUE),
        input_switch(ns("cpsd"), "Cuentapropistas y patrones sin dato de calificación",
                     value = TRUE),
        input_switch(ns("asd"),  "Asalariados sin dato de tamaño o calificación",
                     value = TRUE),

        uiOutput(ns("resumen")),

        hr(),
        radioButtons(
          ns("ambiguo"),
          "Tamaño ambiguo (Europa)",
          choiceNames  = c("Contar como Mediano", "Contar como Grande", "Mostrar aparte"),
          choiceValues = c("Mediano", "Grande", "aparte"),
          selected = "Mediano"),
        div(class = "pie-fig mb-2",
            "La encuesta europea tiene una respuesta \"no sabe, pero más de 10 ",
            "personas\", que no se puede repartir entre mediano (11 a 49) y ",
            "grande (50 o más). Pesa hasta 19% de los asalariados en Bulgaria, ",
            "16% en Rumanía y 13% en Grecia. El gráfico del documento la cuenta ",
            "como mediano."),

        hr(),
        input_switch(ns("etiquetas"), "Mostrar porcentajes", value = TRUE),

        div(class = "pie-fig mt-2",
            "El servicio doméstico y el empleo público se presentan sin ",
            "desagregar por tamaño ni calificación. A los cuentapropistas se los ",
            "clasifica por calificación y no por tamaño, e incluyen a los ",
            "patrones: las fuentes europeas no los distinguen. Los dos bloques ",
            "grises son los casos que no se pueden ubicar en una barra y van en ",
            "los extremos: arriba los independientes sin calificación, abajo los ",
            "asalariados a los que les falta tamaño o calificación (el faltante ",
            "de tamaño es el más frecuente). Quedan fuera del universo los ",
            "familiares no remunerados, otras categorías no asalariadas y los ",
            "asalariados sin dato de sector.")),

      girafeOutput(ns("g")))
  )
}

perfilesServer <- function(id, dark) {
  moduleServer(id, function(input, output, session) {

    bloques <- reactive({
      c("cp", "priv",
        if (isTRUE(input$sd))   "sd",
        if (isTRUE(input$pub))  "pub",
        if (isTRUE(input$cpsd)) "cp_sindato",
        if (isTRUE(input$asd))  "asal_sindato")
    })

    # el tamaño ambiguo de la LFS europea ("no sabe, pero más de 10"): se puede
    # mandar a Mediano, a Grande, o dejarlo como familia propia. El default
    # reproduce el PNG del documento.
    datos <- reactive({
      d <- filter(D$perfiles, bloque %in% bloques())

      destino <- input$ambiguo %||% "Mediano"
      if (!identical(destino, "aparte")) {
        niveles <- levels(D$perfiles$perfil)
        d <- d |>
          mutate(perfil = as.character(perfil),
                 perfil = if_else(startsWith(perfil, LEV_AMBIGUO),
                                  sub(LEV_AMBIGUO, destino, perfil, fixed = TRUE),
                                  perfil),
                 perfil = factor(perfil, levels = niveles))
      }

      d |>
        group_by(region, PAIS, Orden, perfil) |>
        summarise(casos = sum(casos), .groups = "drop") |>
        group_by(PAIS) |>
        mutate(share = casos / sum(casos)) |>
        ungroup()
    })

    universo <- reactive(if (isTRUE(input$pub)) "empleo total" else "empleo privado")

    output$resumen <- renderUI({
      partes <- c("cuentapropistas y patrones", "asalariados privados",
                  if (isTRUE(input$sd))   "servicio doméstico",
                  if (isTRUE(input$pub))  "empleo público",
                  if (isTRUE(input$cpsd)) "independientes sin calificación",
                  if (isTRUE(input$asd))  "asalariados sin dato")
      nota(strong(str_to_sentence(universo())), tags$br(),
           tags$span(style = "font-size:.82rem;",
                     "Incluye: ", paste(partes, collapse = ", "), "."))
    })

    output$g <- renderGirafe({
      extras <- c(if (isTRUE(input$sd))   "el servicio doméstico",
                  if (isTRUE(input$pub))  "el empleo público",
                  if (isTRUE(input$cpsd)) "los independientes sin calificación",
                  if (isTRUE(input$asd))  "los asalariados sin dato")

      subt <- paste0(
        "Participación de cada perfil ocupacional asalariado (tamaño del ",
        "establecimiento y calificación del puesto) y de los cuentapropistas y ",
        "patrones según calificación, en el ", universo(), ".",
        if (length(extras)) paste0(" Incluye ", enumerar(extras), ".") else "")

      cap <- paste0(
        "Fuente: elaboración propia en base al repositorio precariedad-laboral-internacional ",
        "(CEPED-IIEP-UBA). Ocupados de áreas urbanas, c. 2019 (Europa, EE.UU. y ",
        "China, 2018). Ponderado por WEIGHT. Se excluyen Bolivia, Rumanía y ",
        "Bulgaria por cobertura insuficiente. La categoría cuentapropista ",
        "incluye a los patrones; quedan fuera del universo los familiares no ",
        "remunerados, otras categorías no asalariadas y los asalariados sin ",
        "dato de sector.",
        if (isTRUE(input$asd))
          paste0(" El bloque de asalariados sin dato reúne a los que no tienen ",
                 "tamaño o calificación; el faltante de tamaño es el más ",
                 "frecuente.")
        else "",
        # de dónde sale la familia ambigua y qué se hizo con ella
        switch(input$ambiguo %||% "Mediano",
          Mediano = paste0(" La respuesta \"no sabe, pero más de 10 personas\" de ",
                           "la encuesta europea se cuenta como establecimiento ",
                           "mediano, igual que en el documento."),
          Grande  = paste0(" La respuesta \"no sabe, pero más de 10 personas\" de ",
                           "la encuesta europea se cuenta como establecimiento ",
                           "grande."),
          aparte  = paste0(" La respuesta \"no sabe, pero más de 10 personas\" de ",
                           "la encuesta europea va como familia propia ",
                           "(\"mediano o grande\"), sin repartir.")))

      fig(fig_perfiles(datos(), dark(), subt, cap, isTRUE(input$etiquetas)),
          dark(), alto = 7.4, ancho = 13.5)
    })
  })
}
