# Portada: de qué se trata el proyecto, qué hay en el dataset y cómo citarlo.

infoUI <- function(id) {
  ns <- NS(id)

  tagList(
    layout_columns(
      col_widths = c(8, 4), class = "mb-3",
      div(
        h1("Proyecto Precariedad Mundial", class = "mb-1"),
        p(class = "text-muted-pm mb-3",
          "Centro de Estudios sobre Población, Empleo y Desarrollo",
          "(CEPED · IIEP · UBA)"),
        p(class = "lead-narrow",
          "El proyecto aporta evidencia empírica sobre las estructuras de los",
          "mercados de trabajo y la incidencia de la precariedad laboral en",
          "distintos países. Se homogeneizan microdatos de encuestas de hogares",
          "oficiales en un dataset unificado, orientado a producir estadísticas",
          "comparables entre países."),
        p(class = "lead-narrow text-muted-pm",
          "Esta aplicación sintetiza la metodología de construcción del dataset",
          "y permite explorar las estadísticas que se derivan de él.")),
      div(class = "d-flex align-items-center justify-content-center p-3",
          img(src = "logo_ceped.png", alt = "CEPED", style = "max-width: 190px;"))),

    layout_columns(
      col_widths = c(3, 3, 3, 3), class = "mb-3",
      value_box("Países", length(PAISES), showcase = bs_icon("globe-americas"),
                theme = value_box_theme(bg = "#2166ac", fg = "white")),
      value_box("Dimensiones de precariedad", length(VARS_PRECA),
                showcase = bs_icon("exclamation-triangle"),
                theme = value_box_theme(bg = "#b2182b", fg = "white")),
      value_box("Encuestas de hogares", "16", showcase = bs_icon("clipboard-data"),
                theme = value_box_theme(bg = "#d99441", fg = "white")),
      value_box("Año de referencia", "c. 2019", showcase = bs_icon("calendar3"),
                theme = value_box_theme(bg = "#2f6d6a", fg = "white"))),

    navset_card_underline(
      title = "Documentación",

      nav_panel(
        "El dataset",
        layout_columns(
          col_widths = c(6, 6),
          div(
            h5("Características"),
            tags$ul(
              tags$li(strong("Cobertura: "), "30 países — 13 de América Latina, ",
                      "15 de Europa, China y Estados Unidos"),
              tags$li(strong("Período: "), "2018-2019"),
              tags$li(strong("Población objetivo: "), "empleo urbano"),
              tags$li(strong("Ocupación de referencia: "), "la principal")),
            h5("Variables de precariedad", class = "mt-4"),
            tags$ul(
              tags$li(strong("PRECAPT: "), "part-time involuntario"),
              tags$li(strong("PRECAREG: "), "no registro de la relación laboral"),
              tags$li(strong("PRECATEMP: "), "trabajo temporario"),
              tags$li(strong("PRECASEG: "), "sin aportes a la seguridad social"))),
          div(
            h5("Variables estructurales"),
            tags$ul(
              tags$li(strong("CATOCUP: "), "categoría ocupacional"),
              tags$li(strong("SECTOR: "), "público, privado, servicio doméstico"),
              tags$li(strong("TAMA: "), "tamaño del establecimiento — pequeño (≤10), ",
                      "mediano (11-49), grande (≥50)"),
              tags$li(strong("CALIF: "), "calificación del puesto, según los skill ",
                      "levels de la CIUO-08"),
              tags$li(strong("EDUC: "), "máximo nivel educativo alcanzado"),
              tags$li(strong("SEXO"), ", ", strong("EDAD"))),
            h5("Ingresos y ponderadores", class = "mt-4"),
            tags$ul(
              tags$li(strong("ING: "), "ingreso laboral en moneda local"),
              tags$li(strong("WEIGHT: "), "ponderador principal")))),
        nota(
          "Los ingresos que muestra la app están convertidos a dólares de ",
          "paridad de poder adquisitivo con el benchmark del Banco Mundial ",
          "(ICP, PPPGlob) de 2017, extrapolado a 2018-2019 por IPC contra ",
          "Estados Unidos.")),

      nav_panel(
        "Encuestas por país",
        p(class = "text-muted-pm",
          "Cada país entra con la encuesta de hogares oficial de su sistema ",
          "estadístico. Europa entra como un bloque único, a partir de la EU-LFS."),
        DTOutput(ns("encuestas"))),

      nav_panel(
        "Metodología",
        h5("Qué entendemos por empleo precario"),
        p(class = "lead-narrow",
          "La noción de empleo precario no es unívoca en la literatura. En la ",
          "base recogemos cuatro expresiones que pueden evaluarse en la mayoría ",
          "de los países:"),
        tags$ol(
          tags$li(strong("Part-time involuntario: "),
                  "personas que quieren trabajar más horas y no consiguen hacerlo."),
          tags$li(strong("No registro de la relación laboral: "),
                  "ausencia de formalización del vínculo."),
          tags$li(strong("Trabajo de duración determinada: "),
                  "contratos temporarios."),
          tags$li(strong("Falta de aportes a la seguridad social: "),
                  "sin protección social asociada al empleo.")),

        h5("Criterios de homogeneización", class = "mt-4"),
        tags$ul(
          tags$li("Sólo áreas urbanas, para ganar comparabilidad."),
          tags$li("Sólo personas ocupadas, y su ocupación principal."),
          tags$li("Las tasas de precariedad se calculan sobre asalariados."),
          tags$li(sprintf(paste("Un país entra en un indicador sólo si la variable",
                                "tiene cobertura de al menos %s."),
                          pct(META$cob_min, 1)))),

        layout_columns(
          col_widths = c(6, 6), class = "mt-3",
          nota(strong("Europa (EU-LFS). "),
               "Los cuentapropistas incluyen patrones. La información de ingresos ",
               "se complementa con la Structure of Earnings Survey y tiene ",
               "carácter exploratorio. Alemania corresponde a 2017."),
          nota(strong("Límites generales. "),
               "No todas las variables están disponibles en todos los países, y ",
               "algunos cortes de tamaño del establecimiento no son exactos. ",
               "Los años de referencia difieren entre encuestas."))),

      nav_panel(
        "Publicaciones",
        p("Si usás información de este proyecto, te pedimos que cites alguna de ",
          "estas publicaciones:"),
        tags$ul(
          tags$li(strong("La calidad del empleo en la Argentina reciente. "),
                  "J. Graña, G. Weksler y F. Lastra. ",
                  em("Trabajo y Sociedad"), " 38, 423-446."),
          tags$li(strong(paste("Calidad del empleo y estructura del mercado de",
                               "trabajo en América Latina. ")),
                  "S. Fernández-Franco, J. M. Graña, F. Lastra y G. Weksler. ",
                  em("Ensayos de Economía"), " 32 (61), 124-151.")),
        layout_columns(
          col_widths = c(6, 6), class = "mt-3",
          nota(strong("Repositorio. "),
               a(href = "https://github.com/ceped-fce-uba/precariedad-laboral-internacional",
                 target = "_blank", rel = "noopener",
                 "github.com/ceped-fce-uba/precariedad-laboral-internacional")),
          nota(strong("Contacto. "),
               "Para consultas, sugerencias o propuestas de colaboración, ",
               "abrí un issue en el repositorio."))))
  )
}

infoServer <- function(id) {
  moduleServer(id, function(input, output, session) {

    encuestas <- tibble(
      País = c("Argentina", "Bolivia", "Brasil", "Chile", "China", "Colombia",
               "Costa Rica", "Ecuador", "El Salvador", "Estados Unidos",
               "Europa (15 países)", "Guatemala", "México", "Paraguay", "Perú",
               "Uruguay"),
      Encuesta = c("EPH", "ECE", "PNAD Contínua", "ENE-ESI", "CHIP", "GEIH",
                   "ENH", "ENEMDU", "ENH", "CPS", "Eurostat EU-LFS", "ENEI",
                   "ENOE", "EPHC", "ENAHO", "ECH"),
      Año = c(2019, 2019, 2019, 2019, 2018, 2019, 2019, 2019, 2019, 2018, 2018,
              2019, 2019, 2019, 2019, 2019))

    output$encuestas <- renderDT({
      datatable(encuestas, rownames = FALSE, selection = "none",
                options = list(dom = "t", pageLength = 20, ordering = TRUE,
                               columnDefs = list(list(className = "dt-center",
                                                      targets = 2))))
    })
  })
}
