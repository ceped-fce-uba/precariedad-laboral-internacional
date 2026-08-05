# baja las bases de los releases de este repo
# mientras el repo sea privado hace falta un token, ver la viñeta del paquete piggyback

library(piggyback)
library(here)

repo <- "ceped-fce-uba/precariedad-laboral-internacional"

dir.create(here("bases_por_pais"), showWarnings = FALSE)

pb_download(repo = repo, tag = "bases_por_pais", dest = here("bases_por_pais")) # un rds por país y por año
pb_download(repo = repo, tag = "base_completa", dest = here())                  # todos los países y años apilados
