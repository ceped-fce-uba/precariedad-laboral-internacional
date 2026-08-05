# Tema de la app (Bootstrap 5 con modos claro/oscuro) y tema de los gráficos.

AZUL <- "#2166ac"

tema_app <- bs_theme(
  version = 5,
  preset  = "shiny",
  primary = AZUL,
  "font-size-base"    = "0.95rem",
  "border-radius"     = "0.55rem",
  "card-border-width" = "1px",
  base_font    = font_collection(font_google("IBM Plex Sans", local = FALSE),
                                 "system-ui", "sans-serif"),
  heading_font = font_collection(font_google("IBM Plex Serif", local = FALSE),
                                 "Georgia", "serif"),
  code_font    = font_collection(font_google("IBM Plex Mono", local = FALSE),
                                 "monospace")
) |>
  bs_add_rules(sass::sass_file("www/custom.scss"))

# ---- tema de los gráficos --------------------------------------------------
# Los colores siguen a los del CSS: en modo oscuro el fondo lo pone la card, así
# que el gráfico va transparente y sólo cambian los textos y la grilla.

tema_fig <- function(dark = FALSE, base = 12) {
  fg   <- if (dark) "#e8eaed" else "#1b1f24"
  mid  <- if (dark) "#aab2bd" else "#5a6169"
  soft <- if (dark) "#8b939d" else "#868e96"
  grid <- if (dark) "#2c333b" else "#ebedf0"

  theme_minimal(base_size = base, base_family = FUENTE_FIG) +
    theme(
      panel.grid.minor      = element_blank(),
      panel.grid.major      = element_line(color = grid, linewidth = 0.4),
      plot.background       = element_rect(fill = "transparent", colour = NA),
      panel.background      = element_rect(fill = "transparent", colour = NA),
      legend.background     = element_rect(fill = "transparent", colour = NA),
      legend.key            = element_rect(fill = "transparent", colour = NA),
      text                  = element_text(colour = fg),
      plot.title            = element_text(face = "bold", colour = fg, size = rel(1.05)),
      plot.subtitle         = element_text(colour = mid, size = rel(0.9)),
      plot.caption          = element_text(colour = soft, hjust = 0, size = rel(0.68)),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      strip.text            = element_text(face = "bold", colour = mid, size = rel(0.9)),
      # los facets de un solo país son más angostos que su etiqueta: prefiero
      # que el texto se desborde antes que quede cortado
      strip.clip            = "off",
      axis.text             = element_text(colour = mid, size = rel(0.85)),
      axis.title            = element_text(colour = mid, size = rel(0.85)),
      legend.title          = element_text(colour = mid, size = rel(0.85)),
      legend.text           = element_text(colour = mid, size = rel(0.85)),
      legend.position       = "bottom",
      plot.margin           = margin(6, 14, 6, 6))
}

# color de las etiquetas que van encima de las barras
col_etiqueta <- function(dark) if (dark) "#c9d1d9" else "#4a5157"

# ---- envoltorio de ggiraph -------------------------------------------------
# Todos los gráficos salen por acá para que compartan el mismo comportamiento
# de hover, tooltip y barra de herramientas.

fig <- function(g, dark = FALSE, alto = 5, ancho = 9) {
  girafe(
    ggobj = g, width_svg = ancho, height_svg = alto,
    options = list(
      opts_sizing(rescale = TRUE, width = 1),
      opts_hover(css = "filter: brightness(1.12); stroke: none;"),
      opts_hover_inv(css = "opacity: 0.25;"),
      opts_tooltip(
        css = sprintf(paste0(
          "background:%s; color:%s; border:1px solid %s; border-radius:6px;",
          "padding:6px 9px; font-family:sans-serif; font-size:12px;",
          "box-shadow:0 2px 10px rgba(0,0,0,.18);"),
          if (dark) "#20262e" else "#ffffff",
          if (dark) "#e8eaed" else "#1b1f24",
          if (dark) "#39414a" else "#dfe3e8"),
        opacity = 0.98, use_fill = FALSE),
      opts_toolbar(position = "topright", saveaspng = TRUE,
                   pngname = "precariedad-mundial"),
      opts_selection(type = "none")))
}

# alto en pulgadas según cuántos países entren en el eje
alto_paises <- function(n, min = 3.5, por_pais = 0.26, extra = 1.6)
  max(min, n * por_pais + extra)
