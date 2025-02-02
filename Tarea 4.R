# Carga de paqutes
library(dplyr)
library(DT)
library(leaflet)
library(leaflet.extras)
library(leafem)
library(raster)
library(sf)
library(spData)

# Carga de capas de orqu�deas
orquideas <-
  sf::st_read(
    "https://raw.githubusercontent.com/gf0604-procesamientodatosgeograficos/2021i-datos/main/gbif/orchidaceae-cr-registros.csv",
    options = c(
      "X_POSSIBLE_NAMES=decimalLongitude",
      "Y_POSSIBLE_NAMES=decimalLatitude"
    ),
    quiet = TRUE
  )

# Carga de capa de las Areas Silvestres Protegidas (ASP)
asp <-
  sf::st_read(
    "https://raw.githubusercontent.com/gf0604-procesamientodatosgeograficos/2021i-datos/main/sinac/asp/asp-wgs84.geojson",
    quiet = TRUE
  )

# Asignaci�n de proyecciones
sf::st_crs(asp) = 4326
sf::st_crs(orquideas) = 4326

# Limpieza de valores de alta incerdidumbre (Mayorea a 1000) y valores NA

# Asignar a los NA a una variable
orquideas$species[orquideas$species == ""] <- "orquideas"

# Conversion de los valores
orquideas <- 
  orquideas %>%
  mutate(coordinateUncertaintyInMeters = as.numeric(coordinateUncertaintyInMeters)) %>%
  mutate(eventDate = as.Date(eventDate, "%Y-%m-%d"))

cat("Cantidad original de registros:", nrow(orquideas))

# Limpieza de los valores de alta incertidumbre
orquideas <-
  orquideas %>%
  filter(!is.na(coordinateUncertaintyInMeters) & coordinateUncertaintyInMeters <= 1000)

cat("Cantidad de registros despues de limpiar los valores de alta incertidumbre:", nrow(orquideas))

# Limpieza de los NA en los registros de presencia
orquideas <-
  orquideas %>%
  filter(species!= "orquideas")

cat("Cantidad de registros despues de limpiar los valores de alta incertidumbre NA:", nrow(orquideas))

# Limpieza del data asp
asp <-
  asp %>%
  filter(descripcio!="Area Marina de Manejo" & descripcio!="Area marina protegida")

# Mapa de la cantidad de registros por �rea Silvestre Protegia (ASP)

# Creaci�n de un conjunto de datos con la cantidad de registros por �rea Silvestre Protegia

# Creaci�n del conjunto de datos
registros_asp <-
  asp %>%
  sf::st_make_valid() %>%
  sf::st_join(orquideas) %>%
  group_by(nombre_asp) %>%
  summarize(especies = n())

# Asignaci�n de crs al conjunto
sf::st_crs(registros_asp) = 4326

# Asignaci�n de una paleta de colores
colores <-
  colorNumeric(palette = "YlGnBu",
               domain = registros_asp$especies,
               na.color = "transparent")
# Mapeo
leaflet() %>%
  addProviderTiles(providers$Esri.WorldGrayCanvas, 
                   group = "Esri.WorldGrayCanvas") %>%
  addTiles(group = "OMS") %>%
  addPolygons(
    data = registros_asp,
    fillColor = ~ colores (registros_asp$especies),
    fillOpacity = 1,
    stroke = TRUE,
    color = "black",
    weight = 1,
    popup = paste(
      paste(
        "<strong>�rea Silvestre Protegida:</strong>",
        registros_asp$nombre_asp
      ),
      paste(
        "<strong>Cantidad de orqu�deas:</strong>",
        registros_asp$especies
        
      ),
      sep = '<br/>'
    ),
    group = "Cantidad de registros"
  ) %>%
  addLayersControl(baseGroups = c("Esri.WorldGrayCanvas", "OMS"),
                   overlayGroups = c("Cantidad de registros")) %>%
  addSearchOSM() %>%
  addMouseCoordinates() %>%
  addScaleBar(position = "bottomleft", options = scaleBarOptions(imperial = FALSE)) %>%
  addLegend(
    position = "bottomleft",
    pal = colores,
    values = registros_asp$especies,
    group = "Cantidad de registros",
    title = "Cantidad orqu�deas")