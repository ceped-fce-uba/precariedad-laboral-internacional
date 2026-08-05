# App Precariedad Mundial

Explorador del dataset homogeneizado del CEPED. Es la traducción a Shiny de la
app de Streamlit que estaba en `precariedad.mundial/app/`, más las figuras del
documento de trabajo, que se arman en `precariedad-2026` bajo
`scripts/analisis/dt_precariedad_2019/`.

## Correrla

```r
shiny::runApp("app")
```

## Estructura

```
app/
  app.R                    navegación y wiring de los módulos
  R/
    00_setup.R             carga de datos, paletas, etiquetas, formateadores
    01_theme.R             tema bslib (claro/oscuro) y tema de los gráficos
    02_plots.R             un constructor por figura, todos devuelven un ggplot
    03_paises.R            selector de países + piezas de UI que se repiten
    mod_info.R             portada y documentación
    mod_estructura.R       distribución del empleo, cuentapropismo, educación
    mod_perfiles.R         Gráfico 1 del DT, con los bloques del universo conmutables
    mod_precariedad.R      tasas por categoría y rankings por país
    mod_ingresos.R         salarios PPA, brechas por calificación, niveles
    mod_metadatos.R        diccionario y homogeneización
  data/                    los rds que consume la app (chicos, van al repo)
  data-raw/01_prep_datos.R los genera a partir de los microdatos
  tests/                   chequeos sin navegador
  www/                     scss propio y logo
```

Shiny hace `source()` de todo `R/` al arrancar, así que las funciones y objetos
que se definen ahí quedan disponibles en toda la app. (Si el editor marca
"no symbol named ...", es eso: los archivos no se ven entre sí hasta que corre.)

## Datos

La app **no** lee microdatos: lee los agregados de `data/`, que ocupan unos
180 KB en total. Para regenerarlos:

```sh
Rscript app/data-raw/01_prep_datos.R
```

Ese script lee las 16 bases homogéneas c. 2019 (30 países, contando los quince
que trae `europa_2019.rds`) de `bases_por_pais/`, que no están en el repo: hay
que bajarlas antes con `source("bajar_piggyback.R")`. El diccionario sale de
`Metadata.xlsx` y el resto de los insumos —PPA y los agregados de Eurostat— de
`fuentes_complementarias/`.

Criterios que aplica, todos heredados de los scripts del documento de trabajo:

- Ocupados de áreas urbanas, ocupación principal, ponderado por `WEIGHT`.
- Las tasas de precariedad y los ingresos van sobre **asalariados**.
- Un país entra en un indicador sólo si la variable tiene cobertura ≥ 50%.
  Por eso, por ejemplo, Ecuador aparece sólo con varones en el no registro
  abierto por sexo: entre las mujeres `PRECAREG` es NA en el 56% de los casos.
- Los ingresos se pasan a dólares PPA con el benchmark del Banco Mundial de
  2017, extrapolado a 2018-2019 por IPC contra Estados Unidos.
- En `PRECATEMP`, Europa se abre con `PRECATEMP_INV`, que marca al temporario
  que declara no haber encontrado un empleo permanente (`TEMPREAS == 2`), la
  misma definición que Eurostat usa en `lfsa_etgar`. El otro segmento sale por
  diferencia, e incluye el voluntario declarado, la formación, el período de
  prueba, "otro" y la no respuesta del motivo, que es 29% de los temporarios en
  Alemania, 31% en Países Bajos y 34% en Reino Unido. Por eso ese segmento va
  como "voluntario u otros" y no como "voluntario" a secas: es un residuo, no
  una categoría declarada.

## Tests

```sh
Rscript app/tests/test_figuras.R      # que las figuras se construyan bien
Rscript app/tests/test_reactivos.R    # la lógica reactiva, con testServer
```

Valen la pena porque ya agarraron dos cosas que no se ven a simple vista:

1. **El orden de apilado.** `ggiraph` pasa `tooltip` y `data_id` como aesthetics
   discretos y ggplot los mete adentro del `group`. Sin fijar `group` a mano,
   las barras se apilan en el orden de las filas mientras que las etiquetas
   (que no llevan esos aesthetics) se ubican por el orden del factor: quedaban
   sobre el segmento equivocado. Por eso todas las figuras apiladas o en dodge
   fijan `group` explícitamente.

2. **El encoding del svg.** `ggiraph` escribe `data_id` sin respetar el encoding
   del texto, así que un `data_id` con acentos dejaba el svg como UTF-8
   inválido. Los `data_id` se generan con `id_seguro()`, que los pasa a ASCII.

## Perfiles ocupacionales

`data/perfiles.rds` guarda los casos ponderados **sin normalizar**, con el
bloque al que pertenece cada perfil (`cp`, `priv`, `sd`, `pub`, `sin_sector`).
La app filtra bloques según los interruptores y recalcula las participaciones
sobre el universo que queda, así que las barras siempre suman 100%.

`sin_sector` son los asalariados con categoría ocupacional pero sin dato de
`SECTOR` (Chile, Colombia, Costa Rica, Ecuador, El Salvador y México). El script
original los mezclaba con los privados en el universo total; acá van como bloque
aparte, **"Asalariados sin dato de sector"** en gris medio (`#8a8a8a`), para que
se vea cuánto pesan. Los tres grises de la paleta se distinguen por luminancia:
`#bdbdbd` (cuentapropista sin dato, 0.74), `#8a8a8a` (sin dato de sector, 0.54)
y `#454545` (empleo público, 0.27); hay un test que verifica que se mantengan
separados.

El bloque va en los **dos** universos, privado y total: como no lo abrimos por
sector, no importa si adentro hay algún asalariado público. El único bloque que
separa privado de total es el empleo público. Donde más pesa es El Salvador
(14,8% del empleo privado) y Ecuador (7,2%); en Chile, México y Costa Rica no
llega al 1%.

Ojo con la asignación de bloques: es tentador cerrarla con un `TRUE ~
"sin_sector"`, pero eso barre también las filas que no tienen **ni** categoría
ocupacional **ni** sector (Paraguay tiene 5) y las etiqueta mal. La última rama
pide `!is.na(CATOCUP)` y lo que no entra se descarta.

Los valores por defecto de los interruptores (empleo público apagado, los otros
dos prendidos) dan el mismo universo que `g_perfiles_ocupacionales.png`, y
prendiendo el público se llega a `g_perfiles_ocupacionales_total.png`. Hay un
test que chequea esos defaults contra el HTML de la UI, porque es fácil que se
desincronicen del script sin que nada falle.

Los mismos PNG los genera `05_perfiles_ocupacionales.R`, que vive en el repo
`precariedad-2026` bajo `scripts/analisis/dt_precariedad_2019/` y comparte los
criterios con la app. Ojo con eso: son dos implementaciones de la misma figura
en repos distintos, así que es fácil que se desincronicen.

## Modo claro / oscuro

Lo maneja Bootstrap 5.3 con `data-bs-theme`; el toggle es `input_dark_mode()`,
sin `mode`, así que arranca con la preferencia de color del sistema de quien
visita y el botón sólo la sobreescribe.

Los colores de los dos modos están en `www/custom.scss`. Los gráficos no los
heredan solos, así que `app.R` pasa un reactive `dark` a cada módulo y
`tema_fig(dark)` ajusta textos y grilla. La paleta se levanta un poco en oscuro
con `aclarar()` para que no se pierda contra el fondo.
