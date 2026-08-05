# Constructores de gráficos. Todos devuelven un ggplot con geoms interactivos de
# ggiraph; el módulo se encarga de pasarlo por fig().

envolver <- function(x, w = 120) str_wrap(x, width = w)

# color de texto que contrasta con el relleno de la barra, para las etiquetas
# que van adentro de los segmentos
texto_sobre <- function(cols) {
  v <- col2rgb(cols) / 255
  lum <- 0.2126 * v[1, ] + 0.7152 * v[2, ] + 0.0722 * v[3, ]
  setNames(ifelse(lum < 0.55, "white", "grey15"), names(cols))
}

# data_id sólo sirve para vincular elementos al pasar el mouse. ggiraph lo
# escribe en el svg sin respetar el encoding del texto, así que los acentos
# terminan en latin1 y rompen el UTF-8 del documento: lo dejo en ASCII.
id_seguro <- function(...) {
  x <- iconv(paste(...), to = "ASCII//TRANSLIT")
  gsub("[^A-Za-z0-9]+", "_", x)
}

# placeholder para cuando el usuario se queda sin países seleccionados
fig_vacia <- function(msg, dark) {
  ggplot() +
    annotate("text", x = 0, y = 0, label = msg, family = FUENTE_FIG, size = 4,
             colour = if (dark) "#8b939d" else "#868e96") +
    theme_void()
}

# ---- explorador: distribución del empleo -----------------------------------

fig_distribucion <- function(d, pal, dark, modo = "apilado", titulo, subt, caption) {
  d <- mutate(d, .tip = sprintf("<b>%s</b><br/>%s<br/><b>%s</b> del empleo",
                                PAIS, categoria, pct(share)))
  pal <- aclarar(pal, dark)

  g <- ggplot(d, aes(share, PAIS, fill = categoria, group = categoria))

  if (modo == "apilado") {
    g <- g +
      geom_col_interactive(aes(tooltip = .tip, data_id = id_seguro(PAIS, categoria)),
                           width = 0.76, position = position_stack(reverse = TRUE)) +
      geom_text(aes(label = if_else(share >= 0.09, pct(share, 1), ""),
                    colour = categoria),
                position = position_stack(vjust = 0.5, reverse = TRUE),
                size = 2.3, family = FUENTE_FIG, show.legend = FALSE) +
      scale_colour_manual(values = texto_sobre(pal), guide = "none") +
      scale_x_continuous(labels = pct, expand = c(0, 0))
  } else {
    g <- g +
      geom_col_interactive(aes(tooltip = .tip, data_id = id_seguro(PAIS, categoria)),
                           width = 0.76, position = position_dodge(0.8)) +
      scale_x_continuous(labels = pct, expand = expansion(mult = c(0, 0.05)))
  }

  g +
    scale_fill_manual(values = pal, name = NULL, drop = FALSE) +
    labs(title = titulo, subtitle = subt, x = NULL, y = NULL,
         caption = envolver(caption)) +
    tema_fig(dark) +
    theme(panel.grid.major.y = element_blank()) +
    guides(fill = guide_legend(nrow = if (length(pal) > 6) 3 else 1))
}

# ---- explorador: tasas de precariedad --------------------------------------

fig_preca_explora <- function(d, pal, dark, titulo, subt, caption) {
  d <- mutate(d, .tip = sprintf("<b>%s</b><br/>%s<br/>tasa: <b>%s</b>",
                                PAIS, categoria, pct(tasa)))
  pal <- aclarar(pal, dark)

  ggplot(d, aes(tasa, PAIS, fill = categoria, group = categoria)) +
    geom_col_interactive(aes(tooltip = .tip, data_id = id_seguro(PAIS, categoria)),
                         width = 0.75, position = position_dodge(0.82)) +
    scale_fill_manual(values = pal, name = NULL, drop = FALSE) +
    scale_x_continuous(labels = pct, expand = expansion(mult = c(0, 0.06))) +
    labs(title = titulo, subtitle = subt, x = NULL, y = NULL,
         caption = envolver(caption)) +
    tema_fig(dark) +
    theme(panel.grid.major.y = element_blank())
}

# ---- explorador: salarios ---------------------------------------------------

fig_salarios <- function(d, pal, dark, titulo, subt, caption) {
  d <- mutate(d, .tip = sprintf("<b>%s</b><br/>%s<br/><b>%s</b> USD PPA / mes",
                                PAIS, categoria, num0(valor)))
  pal <- aclarar(pal, dark)

  ggplot(d, aes(valor, PAIS, fill = categoria, group = categoria)) +
    geom_col_interactive(aes(tooltip = .tip, data_id = id_seguro(PAIS, categoria)),
                         width = 0.75, position = position_dodge(0.82)) +
    scale_fill_manual(values = pal, name = NULL, drop = FALSE) +
    scale_x_continuous(labels = num0, expand = expansion(mult = c(0, 0.06))) +
    labs(title = titulo, subtitle = subt, x = "USD PPA / mes", y = NULL,
         caption = envolver(caption)) +
    tema_fig(dark) +
    theme(panel.grid.major.y = element_blank())
}

# ---- documento de trabajo: ranking de precariedad --------------------------

fig_ranking_preca <- function(d, dark, titulo, subt, caption, por_region = TRUE) {
  d <- d |>
    mutate(PAIS = fct_reorder(PAIS, tasa),
           .tip = sprintf("<b>%s</b><br/>%s<br/>tasa: <b>%s</b>",
                          PAIS, region, pct(tasa)))
  pal <- aclarar(PAL_REGION, dark)

  g <- ggplot(d, aes(tasa, PAIS))

  g <- if (por_region)
    g + geom_col_interactive(aes(fill = region, tooltip = .tip, data_id = id_seguro(PAIS)),
                             width = 0.7) +
        scale_fill_manual(values = pal, name = NULL, drop = TRUE)
  else
    g + geom_col_interactive(aes(tooltip = .tip, data_id = id_seguro(PAIS)),
                             width = 0.7, fill = aclarar("#b2182b", dark))

  g +
    geom_text(aes(label = pct(tasa)), hjust = -0.18, size = 2.6,
              colour = col_etiqueta(dark), family = FUENTE_FIG) +
    scale_x_continuous(labels = pct, expand = expansion(mult = c(0, 0.14))) +
    labs(title = titulo, subtitle = subt, x = NULL, y = NULL,
         caption = envolver(caption)) +
    tema_fig(dark) +
    theme(panel.grid.major.y = element_blank(),
          legend.position = if (por_region) "bottom" else "none")
}

# ---- documento de trabajo: empleo temporario con desglose Eurostat ---------

fig_temp_total <- function(d, dark, caption) {
  d <- mutate(d, PAIS = fct_reorder(PAIS, total, max),
              .tip = sprintf("<b>%s</b><br/>%s<br/><b>%s</b>", PAIS, seg, pct(val)))
  pal <- aclarar(PAL_TEMP, dark)

  ggplot(d, aes(val, PAIS)) +
    geom_col_interactive(aes(fill = seg, group = seg, tooltip = .tip, data_id = id_seguro(PAIS, seg)),
                         width = 0.7, position = position_stack(reverse = TRUE)) +
    scale_fill_manual(values = pal, name = NULL, drop = TRUE) +
    geom_text(data = distinct(d, PAIS, total),
              aes(x = total, label = pct(total)), hjust = -0.18, size = 2.6,
              colour = col_etiqueta(dark), family = FUENTE_FIG) +
    scale_x_continuous(labels = pct, expand = expansion(mult = c(0, 0.14))) +
    labs(title = "Empleo temporario",
         subtitle = "% de asalariados con contrato de duración predeterminada",
         x = NULL, y = NULL, caption = envolver(caption)) +
    tema_fig(dark) +
    theme(panel.grid.major.y = element_blank()) +
    guides(fill = guide_legend(nrow = 2))
}

# ---- documento de trabajo: cuentapropismo y educación ----------------------

fig_cuentapropismo <- function(d, dark, caption) {
  d <- d |>
    mutate(PAIS = fct_reorder(PAIS, share, sum),
           .tip = sprintf("<b>%s</b><br/>Cuentapropista %s<br/><b>%s</b> del empleo",
                          PAIS, tolower(grp), pct(share)))

  ggplot(d, aes(share, PAIS, fill = grp, group = grp)) +
    geom_col_interactive(aes(tooltip = .tip, data_id = id_seguro(PAIS, grp)),
                         width = 0.72, position = position_stack(reverse = TRUE)) +
    facet_grid(region ~ ., scales = "free_y", space = "free_y") +
    scale_x_continuous(labels = pct, expand = expansion(mult = c(0, 0.04))) +
    scale_fill_manual(values = aclarar(PAL_CUENTAPROPIA, dark), name = NULL) +
    labs(title = "En América Latina el cuentapropismo es de subsistencia; en Europa, más profesional",
         subtitle = "Cuentapropistas según calificación, como % del empleo urbano total",
         x = NULL, y = NULL, caption = envolver(caption)) +
    tema_fig(dark) +
    theme(panel.grid.major.y = element_blank())
}

fig_educacion <- function(d, dark, caption) {
  d <- d |>
    group_by(PAIS) |>
    mutate(ter = sum(share[EDUC == "Terciaria"])) |>
    ungroup() |>
    mutate(PAIS = fct_reorder(PAIS, ter),
           .tip = sprintf("<b>%s</b><br/>%s<br/><b>%s</b> del empleo",
                          PAIS, EDUC, pct(share)))

  ggplot(d, aes(share, PAIS, fill = EDUC, group = EDUC)) +
    geom_col_interactive(aes(tooltip = .tip, data_id = id_seguro(PAIS, EDUC)),
                         width = 0.75, position = position_stack(reverse = TRUE)) +
    geom_text(aes(label = if_else(share >= 0.08, pct(share, 1), ""), colour = EDUC),
              position = position_stack(vjust = 0.5, reverse = TRUE),
              size = 2.2, family = FUENTE_FIG, show.legend = FALSE) +
    scale_colour_manual(values = texto_sobre(aclarar(PAL_CORTE$EDUC, dark)),
                        guide = "none") +
    scale_x_continuous(labels = pct, expand = c(0, 0)) +
    scale_fill_manual(values = aclarar(PAL_CORTE$EDUC, dark), name = NULL) +
    labs(title = "Más allá de los títulos: la base educativa del empleo urbano",
         subtitle = "Ocupados según máximo nivel educativo, ordenados por peso del terciario",
         x = NULL, y = NULL, caption = envolver(caption)) +
    tema_fig(dark) +
    theme(panel.grid.major.y = element_blank())
}

# ---- documento de trabajo: perfiles ocupacionales --------------------------

fig_perfiles <- function(d, dark, subt, caption, etiquetas = TRUE) {
  pal <- aclarar(PAL_PERFIL, dark)
  # los países van por Orden, y las regiones por el Orden más chico que
  # contienen: así los facets quedan América Latina, China, Europa, EE.UU.,
  # que es el gradiente con el que se lee la figura del documento de trabajo
  d <- d |>
    mutate(PAIS   = fct_reorder(PAIS, Orden),
           region = fct_reorder(region, Orden, .fun = min),
           .tip = sprintf("<b>%s</b><br/>%s<br/><b>%s</b>", PAIS, perfil, pct(share)))

  ggplot(d, aes(PAIS, share, fill = perfil, group = perfil)) +
    geom_col_interactive(aes(tooltip = .tip, data_id = id_seguro(PAIS, perfil)),
                         width = 0.8, linewidth = 0.12,
                         colour = if (dark) "#1a1f26" else "white") +
    geom_text(aes(label = if_else(etiquetas & share >= 0.04, pct(share), ""),
                  colour = perfil),
              position = position_stack(vjust = 0.5), size = 2.1, family = FUENTE_FIG,
              show.legend = FALSE) +
    facet_grid(cols = vars(region), space = "free_x", scales = "free_x",
               labeller = labeller(region = REG_CORTO)) +
    scale_fill_manual(values = pal, name = "Perfil ocupacional", drop = TRUE) +
    scale_colour_manual(values = texto_sobre(pal), guide = "none") +
    scale_y_continuous(labels = pct, expand = c(0, 0)) +
    labs(title = paste("Distribución del empleo según calificación del puesto y",
                       "tamaño del establecimiento"),
         subtitle = envolver(subt, 130), x = NULL, y = NULL, caption = envolver(caption)) +
    tema_fig(dark) +
    theme(legend.position = "right",
          legend.title = element_text(face = "bold", size = rel(0.82)),
          legend.key.size = unit(0.85, "lines"),
          axis.text.x = element_text(angle = 45, hjust = 1),
          panel.grid.major.x = element_blank(),
          # espacio de sobra: las etiquetas de los facets de un país se desbordan
          panel.spacing.x = unit(1.4, "lines"))
}

# ---- documento de trabajo: ingresos ----------------------------------------

fig_brechas <- function(d, dark, facetar, titulo, subt, caption) {
  d <- mutate(d, .tip = sprintf("<b>%s</b><br/>brecha %s<br/><b>%s</b> veces",
                                PAIS, par, num1(gap)))

  g <- ggplot(d, aes(PAIS, gap, fill = par, group = par)) +
    geom_col_interactive(aes(tooltip = .tip, data_id = id_seguro(PAIS, par)),
                         position = position_dodge(0.8), width = 0.75) +
    geom_text(aes(label = num1(gap)), position = position_dodge(0.8),
              vjust = -0.35, size = 2.1, colour = col_etiqueta(dark),
              family = FUENTE_FIG) +
    scale_fill_manual(values = aclarar(PAL_PAR, dark), name = NULL) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.12)))

  if (facetar)
    g <- g + facet_grid(cols = vars(region), space = "free_x", scales = "free_x",
               labeller = labeller(region = REG_CORTO))

  g +
    labs(title = titulo, subtitle = subt, x = NULL,
         y = "cociente de ingresos medios", caption = envolver(caption)) +
    tema_fig(dark) +
    theme(panel.grid.major.x = element_blank(),
          panel.spacing.x = unit(0.4, "lines"),
          axis.text.x = element_text(angle = 45, hjust = 1))
}

fig_niveles_ing <- function(d, dark, caption) {
  d <- d |>
    group_by(PAIS) |> mutate(ord = mean(m)) |> ungroup() |>
    mutate(PAIS = fct_reorder(PAIS, ord),
           .tip = sprintf("<b>%s</b><br/>calificación %s<br/><b>%s</b> USD PPA / mes",
                          PAIS, tolower(CALIF), num0(m)))

  ggplot(d, aes(PAIS, m, fill = CALIF, group = CALIF)) +
    geom_col_interactive(aes(tooltip = .tip, data_id = id_seguro(PAIS, CALIF)),
                         position = position_dodge(0.8), width = 0.78) +
    facet_grid(cols = vars(region), space = "free_x", scales = "free_x",
               labeller = labeller(region = REG_CORTO)) +
    scale_fill_manual(values = aclarar(PAL_CORTE$CALIF, dark), name = "Calificación") +
    scale_y_continuous(labels = num0, expand = expansion(mult = c(0, 0.05))) +
    labs(title = "Niveles de ingreso por calificación",
         subtitle = "ingreso laboral mensual medio en dólares PPA · asalariados",
         x = NULL, y = "USD PPA / mes", caption = envolver(caption)) +
    tema_fig(dark) +
    theme(panel.grid.major.x = element_blank(),
          panel.spacing.x = unit(0.4, "lines"),
          axis.text.x = element_text(angle = 45, hjust = 1))
}

fig_mediana_ing <- function(d, dark, caption) {
  d <- mutate(d, PAIS = fct_reorder(PAIS, med),
              .tip = sprintf("<b>%s</b><br/>mediana: <b>%s</b> USD PPA / mes",
                             PAIS, num0(med)))

  ggplot(d, aes(med, PAIS, fill = region)) +
    geom_col_interactive(aes(tooltip = .tip, data_id = id_seguro(PAIS)), width = 0.72) +
    geom_text(aes(label = num0(med)), hjust = -0.18, size = 2.6,
              colour = col_etiqueta(dark), family = FUENTE_FIG) +
    scale_fill_manual(values = aclarar(PAL_REGION, dark), name = NULL) +
    scale_x_continuous(labels = num0, expand = expansion(mult = c(0, 0.16))) +
    labs(title = "Ingreso laboral mensual en dólares PPA",
         subtitle = "mediana ponderada por país · asalariados",
         x = "USD PPA / mes", y = NULL, caption = envolver(caption)) +
    tema_fig(dark) +
    theme(panel.grid.major.y = element_blank())
}
