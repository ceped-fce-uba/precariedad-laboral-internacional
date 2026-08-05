# Precariedad Mundial — explorador del dataset homogeneizado del CEPED.
#
# Shiny hace source() de todo lo que hay en R/ antes de arrancar, así que acá
# sólo queda el armado de la navegación. Los datos salen de data/, que genera
# app/data-raw/01_prep_datos.R.
#
# Correr con:  shiny::runApp("app")

ui <- page_navbar(
  title = span(class = "d-flex align-items-center gap-2",
               bs_icon("globe-americas"), "Precariedad Mundial"),
  window_title = "Precariedad Mundial · CEPED",
  theme = tema_app,
  id = "nav",
  fillable = FALSE,
  navbar_options = navbar_options(underline = TRUE),

  nav_panel("Información",  infoUI("info")),
  nav_panel("Estructura",   estructuraUI("estructura")),
  nav_panel("Perfiles",     perfilesUI("perfiles")),
  nav_panel("Precariedad",  precariedadUI("precariedad")),
  nav_panel("Ingresos",     ingresosUI("ingresos")),
  nav_panel("Metadatos",    metadatosUI("metadatos")),

  nav_spacer(),
  # sin `mode`, arranca con la preferencia de color del sistema de quien visita
  nav_item(input_dark_mode(id = "modo")),
  nav_item(
    tags$a(class = "nav-link", target = "_blank", rel = "noopener",
           href = "https://github.com/ceped-fce-uba/precariedad-laboral-internacional",
           title = "Repositorio del proyecto",
           bs_icon("github")))
)

server <- function(input, output, session) {

  # los gráficos se redibujan al cambiar de modo, así que el flag viaja a todos
  # los módulos como reactive
  dark <- reactive(identical(input$modo, "dark"))

  infoServer("info")
  estructuraServer("estructura", dark)
  perfilesServer("perfiles", dark)
  precariedadServer("precariedad", dark)
  ingresosServer("ingresos", dark)
  metadatosServer("metadatos")
}

shinyApp(ui, server)
