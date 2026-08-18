# Precariedad laboral internacional

Este es el repositorio de datos de la línea de trabajo sobre precariedad
laboral del Centro de Estudios sobre Población, Empleo y Desarrollo
(CEPED - IIEP – UBA). El proyecto tiene como objetivo aportar argumentos
y evidencias empíricas sobre la incidencia de la precariedad laboral a lo
largo del mundo, como también fomentar el intercambio sobre criterios y
enfoques para procesar estadísticas laborales. Acá ponemos a disposición
un conjunto homogéneo de bases de datos con variables socio-laborales,
construido a partir del procesamiento de microdatos de encuestas de
hogares de institutos de estadística oficiales de distintos países del
mundo.

Si utilizás información de este proyecto, agradecemos que cites alguna de
nuestras publicaciones:

-   [*La calidad del empleo en la Argentina reciente: un análisis sobre
    su relación con la calificación y el tamaño de las unidades
    productivas en perspectiva comparada* J Graña, G Weksler, F Lastra
    *Trabajo y Sociedad 38,
    423-446*](https://www.unse.edu.ar/trabajoysociedad/38%20GRANA%20ET%20ALT%20La%20calidad%20del%20empleo%20en%20la%20Argentina.pdf)

-   [*Calidad del empleo y estructura del mercado de trabajo en América
    Latina desde una perspectiva comparada* S Fernández-Franco, JM Graña,
    F Lastra, G Weksler *Ensayos de Economía 32 (61),
    124-151*](https://doi.org/10.15446/ede.v32n61.100343)

## Metodología

Los criterios con los que se construyó cada variable de la base
homogeneizada están explicados en el documento de trabajo del CEPED.

<!-- TODO: agregar título, autores y enlace del documento de trabajo -->

El diccionario de variables, con sus valores y referencias, está en
`Metadata.xlsx`. En `docs/` hay además una página con [aclaraciones
metodológicas](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/blob/main/docs/aclaraciones_metodologicas.Rmd) y otra con [ejemplos
de uso](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/blob/main/docs/ejemplos_de_uso.Rmd), escritas para una versión anterior de
la base.

## Encuestas procesadas

El siguiente cuadro presenta las bases disponibles, con un enlace de
descarga para cada país y año.

| País | Encuesta | Años disponibles |
|------------------|------------------|-------------------------------------|
| Argentina | Encuesta Permanente de Hogares (EPH) | [2017](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/argentina_2017.rds), [2018](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/argentina_2018.rds), [2019](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/argentina_2019.rds), [2020](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/argentina_2020.rds), [2021](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/argentina_2021.rds), [2022](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/argentina_2022.rds), [2023](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/argentina_2023.rds), [2024](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/argentina_2024.rds), [2025](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/argentina_2025.rds) |
| Bolivia | Encuesta Continua de Empleo | [2019](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/bolivia_2019.rds) |
| Brasil | Pesquisa Nacional por Amostra de Domicílios Contínua (PNAD Contínua) | [2019](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/brasil_2019.rds), [2024](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/brasil_2024.rds) |
| Chile | Encuesta Nacional de Empleo (ENE) – módulo Encuesta Suplementaria de Ingresos (ESI) | [2019](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/chile_2019.rds), [2024](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/chile_2024.rds) |
| China | Chinese Household Income Project (CHIP), muestra urbana | [2018](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/china_2019.rds) |
| Colombia | Gran Encuesta Integrada de Hogares (GEIH) | [2015](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/colombia_2015.rds), [2019](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/colombia_2019.rds), [2021](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/colombia_2021.rds), [2022](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/colombia_2022.rds), [2024](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/colombia_2024.rds) |
| Costa Rica | Encuesta Nacional de Hogares | [2019](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/costa_rica_2019.rds) |
| Ecuador | Encuesta Nacional de Empleo, Desempleo y Subempleo (ENEMDU) | [2019](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/ecuador_2019.rds), [2024](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/ecuador_2024.rds) |
| El Salvador | Encuesta de Hogares de Propósitos Múltiples (EHPM) | [2019](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/el_salvador_2019.rds) |
| Estados Unidos | Current Population Survey (CPS), suplemento ASEC | [2018](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/estados_unidos_2019.rds) |
| Europa | Eurostat Labour Force Survey (LFS) | [2018](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/europa_2019.rds) |
| Guatemala | Encuesta Nacional de Empleo e Ingresos (ENEI) | [2019](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/guatemala_2019.rds) |
| México | Encuesta Nacional de Ocupación y Empleo (ENOE) | [2019](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/mexico_2019.rds) |
| Paraguay | Encuesta Permanente de Hogares Continua | [2019](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/paraguay_2019.rds) |
| Perú | Encuesta Nacional de Hogares | [2019](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/peru_2019.rds) |
| Uruguay | Encuesta Continua de Hogares | [2019](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/uruguay_2019.rds), [2024](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/bases_por_pais/uruguay_2024.rds) |

El año del enlace es el de referencia de la encuesta y no siempre
coincide con el nombre del archivo: los datos de China, Estados Unidos y
Europa son de 2018 pero se guardan como `_2019.rds`. En el caso de
Estados Unidos, el suplemento ASEC pregunta por el año anterior al del
relevamiento. La base de Europa reúne quince países en un solo archivo
(Alemania, Austria, Bulgaria, Dinamarca, España, Francia, Grecia, Italia,
Noruega, Países Bajos, Polonia, Portugal, Reino Unido, Rumanía y Suecia)
y por lo tanto tiene varios valores de `PAIS`; Alemania es la única con
año de referencia 2017.

Además de las bases por país, se publica una base completa con todos los
países y años apilados en una sola tabla, en formato parquet:
[base_completa.parquet](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases/download/base_completa/base_completa.parquet).

## Cómo bajar las bases

Los archivos no están en el repositorio: se distribuyen como assets de
los [releases](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases). Se pueden bajar uno por uno con los
enlaces del cuadro, o todos juntos desde R con `bajar_piggyback.R`:

``` r
source("bajar_piggyback.R")
```

Mientras el repositorio sea privado, tanto los enlaces como la descarga
desde R requieren una cuenta de GitHub con acceso.

## Descripción de la base

Las encuestas de cada país son filtradas para obtener información del
total del empleo urbano. Cada base por país y la base completa tienen las
siguientes columnas:

-   **PAIS**: País de la encuesta.
-   **ANO**: Año de referencia de la encuesta.
-   **PERIODO**: Período de referencia de la encuesta (trimestre, cuando
    la encuesta lo permite).
-   **WEIGHT**: Ponderador.
-   **WEIGHT_W**: Ponderador de los ingresos de la ocupación principal
    (sólo para Argentina).
-   **SEXO**: Sexo.
-   **EDAD**: Edad.
-   **COND**: Condición de actividad.
-   **CATOCUP**: Categoría ocupacional (Asalariados, Cuenta Propia,
    Patrón, Resto).
-   **SECTOR**: Sector (Pub, Priv, SD para servicio doméstico).
-   **EDUC**: Máximo nivel educativo terminado (Primaria, Secundaria,
    Terciaria).
-   **TAMA**: Tamaño del establecimiento.
-   **CALIF**: Calificación del puesto (Baja, Media, Alta).
-   **ING**: Ingreso de la ocupación principal en moneda local.
-   **HORAS_PPAL**: Horas trabajadas en la ocupación principal.
-   **HORAS_OTRAS**: Horas trabajadas en otras ocupaciones.
-   **PRECAPT**: Precariedad por trabajo part-time involuntario.
-   **PRECAREG**: Precariedad por no registro de la relación laboral.
-   **PRECATEMP**: Precariedad por trabajo temporario.
-   **PRECATEMP_INV**: Trabajo temporario involuntario: el asalariado
    temporario que declara no haber encontrado un empleo permanente, la
    misma definición que usa Eurostat en `lfsa_etgar`. Sólo Europa.
-   **PRECASALUD**: Precariedad por falta de cobertura de salud.
-   **PRECASEG**: Precariedad por falta de aportes a la seguridad social.
-   **PRECAPLURI**: Precariedad por pluriempleo.

No todas las encuestas permiten construir todas las variables: las que no
están disponibles quedan en `NA`, y la disponibilidad puede cambiar de un
año a otro dentro de un mismo país. Las ausencias más importantes son las
de `PRECAREG` y `PRECASEG` en Europa y Estados Unidos (Uruguay tampoco
tiene `PRECAREG`) y la de `PRECATEMP` en Estados Unidos. `PRECASALUD`,
`PRECAPLURI` y las horas trabajadas están disponibles sólo en algunos
países.

## Estructura del repositorio

-   **bajar_piggyback.R**: baja todas las bases desde los releases.
-   **bases_por_pais/**: carpeta donde quedan las bases al bajarlas. No
    se versiona.
-   **Metadata.xlsx**: diccionario de la base y criterios de
    homogeneización por país.
-   **app/**: aplicación Shiny para explorar la base. Ver su
    [README](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/blob/main/app/README.md).
-   **docs/**: aclaraciones metodológicas y ejemplos de uso.
-   **fuentes_complementarias/**: archivos auxiliares que usan los
    documentos de `docs/` y la app (coeficientes de paridad de poder
    adquisitivo, series de productividad y salarios).

Los scripts que procesan los microdatos originales de cada país y
producen estas bases se mantienen aparte, junto con los microdatos
crudos.

¡Gracias por utilizar nuestro repositorio! Si tenés alguna pregunta o
sugerencia, no dudes en contactarnos. También podés proponer
modificaciones mediante un issue.

# International labour precariousness

This is the data repository of the research line on labour precariousness
of the Center for Studies on Population, Employment and Development
(CEPED - IIEP – UBA). The project aims to provide arguments and empirical
evidence on the incidence of labour precariousness around the world, and
to encourage exchange on criteria and approaches for processing labour
statistics. Here we make available a homogeneous set of databases with
socio-labour variables, built from the microdata of household surveys
conducted by official statistical institutes in different countries.

If you use information from this project, we appreciate citing one of our
publications:

-   [**La calidad del empleo en la Argentina reciente: un análisis sobre
    su relación con la calificación y el tamaño de las unidades
    productivas en perspectiva comparada** J Graña, G Weksler, F Lastra
    *Trabajo y Sociedad 38,
    423-446*](https://www.unse.edu.ar/trabajoysociedad/38%20GRANA%20ET%20ALT%20La%20calidad%20del%20empleo%20en%20la%20Argentina.pdf)

-   [**Calidad del empleo y estructura del mercado de trabajo en América
    Latina desde una perspectiva comparada** S Fernández-Franco, JM
    Graña, F Lastra, G Weksler *Ensayos de Economía 32 (61),
    124-151*](https://doi.org/10.15446/ede.v32n61.100343)

## How to download the data

The files are not stored in the repository: they are distributed as
assets of the [releases](https://github.com/ceped-fce-uba/precariedad-laboral-internacional/releases). Each country and year can be
downloaded from the table above, or all of them at once from R with
`bajar_piggyback.R`. A complete database stacking every country and year
into a single parquet table is also available.

While the repository is private, both the links and the download from R
require a GitHub account with access.

## Description of the data

Surveys from each country are filtered to obtain information for total
urban employment. Each country file, and the complete database, include
the following columns:

-   **PAIS**: Country of the survey.
-   **ANO**: Survey reference year.
-   **PERIODO**: Survey reference period (quarter, where available).
-   **WEIGHT**: Weight.
-   **WEIGHT_W**: Weight related to main job income (only for Argentina).
-   **SEXO**: Sex.
-   **EDAD**: Age.
-   **COND**: Activity condition.
-   **CATOCUP**: Occupational category.
-   **SECTOR**: Sector (public, private, paid domestic workers).
-   **EDUC**: Highest level of education completed.
-   **TAMA**: Establishment size.
-   **CALIF**: Job qualification.
-   **ING**: Principal occupation income in local currency.
-   **HORAS_PPAL**: Hours worked in the main occupation.
-   **HORAS_OTRAS**: Hours worked in other occupations.
-   **PRECAPT**: Precariousness due to involuntary part-time work.
-   **PRECAREG**: Precariousness due to lack of registration of the
    employment relationship.
-   **PRECATEMP**: Precariousness due to temporary work.
-   **PRECATEMP_INV**: Involuntary temporary work: temporary employees
    who report not having been able to find a permanent job, the same
    definition Eurostat uses in `lfsa_etgar`. Europe only.
-   **PRECASALUD**: Precariousness due to lack of health coverage.
-   **PRECASEG**: Precariousness due to lack of social security
    contributions.
-   **PRECAPLURI**: Precariousness due to holding multiple jobs.

Not every survey allows all variables to be built: those unavailable are
left as `NA`, and availability may change from one year to another within
the same country.

Thank you for using our repository! If you have any questions or
suggestions, please feel free to contact us. You can also propose changes
through an issue.
