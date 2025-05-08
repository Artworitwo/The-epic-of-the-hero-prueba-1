// === Atributos globales requeridos ===
PImage[] tilesetImages;
int[] tilesPerRow;
int[] firstgids;
int[][] tileMap;
int tileWidth, tileHeight, mapWidth, mapHeight;
PImage fondoEstatico, fondoParallax;
float parallaxX = 0;
float parallaxSpeed = 0.2;
JSONArray layers;
JSONObject map;
ArrayList<Colisionable> colisiones = new ArrayList<Colisionable>();
PGraphics fondoRender;
Stella stella;

int cameraX = 0;
int cameraY = 0;
int velocidadScroll = 3;
int duracionJuego = 100 * 60;
int frameActual = 0;

int incrementoVelocidad = 1;          
int tiempoIntervalo = 15 * 60;       
int tiempoTranscurrido = 0;  



// === SETUP optimizado ===
void setup() {
  size(1280, 720);
  frameRate(60);
  noSmooth();

  map = loadJSONObject("Escenarios/Nivel01_Necropolis_de_Luna/Nivel_1_Terminado_V7.tmj");

  tileWidth = map.getInt("tilewidth");
  tileHeight = map.getInt("tileheight");
  mapWidth = map.getInt("width");
  mapHeight = map.getInt("height");
  
  int mapaTotalPixeles = mapWidth * tileWidth;
  duracionJuego = mapaTotalPixeles / velocidadScroll;

  println("Duración calculada del juego (frames): " + duracionJuego);  
  println("Duración calculada del juego (segundos): " + duracionJuego / 60);

  JSONArray tilesets = map.getJSONArray("tilesets");
  tilesetImages = new PImage[tilesets.size()];
  tilesPerRow = new int[tilesets.size()];
  firstgids = new int[tilesets.size()];

  String rutaBase = "Escenarios/Nivel01_Necropolis_de_Luna/Imagenes/";
  for (int i = 0; i < tilesets.size(); i++) {
    JSONObject ts = tilesets.getJSONObject(i);
    String imgName = ts.getString("image");
    imgName = imgName.substring(imgName.lastIndexOf("/") + 1);

    tilesetImages[i] = loadImage(rutaBase + imgName);
    tilesPerRow[i] = ts.getInt("imagewidth") / ts.getInt("tilewidth");
    firstgids[i] = ts.getInt("firstgid");
  }
  

  fondoEstatico = loadImage("Escenarios/Nivel01_Necropolis_de_Luna/Imagenes/Background_0.png");
  fondoParallax = loadImage("Escenarios/Nivel01_Necropolis_de_Luna/Imagenes/Background_1.png");

  layers = map.getJSONArray("layers");
  String[] capasVisibles = {
    "Capa del terreno 1",
    "Capa de rejas",
    "Arbustos",
    "Capa arbustos y piedras",
    "Capa de estatuas",
    "Estatua 2",
    "Capa de fondo 1"
  };

  for (int i = 0; i < layers.size(); i++) {
    JSONObject l = layers.getJSONObject(i);
    if (l.getString("type").equals("objectgroup") && l.getString("name").equals("Colisiones")) {
      JSONArray objetos = l.getJSONArray("objects");

      for (int j = 0; j < objetos.size(); j++) {
        JSONObject objeto = objetos.getJSONObject(j);

        if (objeto.hasKey("polygon")) {
          JSONArray puntos = objeto.getJSONArray("polygon");
          ArrayList<PVector> vertices = new ArrayList<PVector>();
          float x = objeto.getFloat("x");
          float y = objeto.getFloat("y");

          for (int p = 0; p < puntos.size(); p++) {
            JSONObject punto = puntos.getJSONObject(p);
            float px = punto.getFloat("x");
            float py = punto.getFloat("y");
            vertices.add(new PVector(x + px, y + py));
          }

          colisiones.add(new PoligonoColision(vertices));

        } else if (objeto.hasKey("width") && objeto.hasKey("height")) {
          float x = objeto.getFloat("x");
          float y = objeto.getFloat("y");
          float w = objeto.getFloat("width");
          float h = objeto.getFloat("height");

          colisiones.add(new RectanguloColision(x, y, w, h));
        }
      }
    }
  }
  int umbralReinicio = int(mapWidth * tileWidth * 0.8);

    // Imprimir para depurar
  println("Umbral de Reinicio calculado: " + umbralReinicio);

  stella = new Stella();
  stella.inicializar();
  
 
}


public void draw() {
    actualizarScrollInfinito();
    actualizarVelocidad();
    renderizarFondo();
    renderizarMapa();
    renderizarStella();
    renderizarHUD();

    cameraX += velocidadScroll;
    frameActual++;
}

void renderizarFondo() {
    background(0);

    image(fondoEstatico, 0, 0, width, height);

    float parallaxOffset = parallaxX % fondoParallax.width;
    image(fondoParallax, -parallaxOffset, 0, width, height);
    image(fondoParallax, -parallaxOffset + fondoParallax.width, 0, width, height);
    parallaxX += parallaxSpeed;
}

void actualizarScrollInfinito() {
    int mapaTotalPixeles = mapWidth * tileWidth;
    int ciclosNecesarios = (100 * 60) / (mapaTotalPixeles / velocidadScroll);

    if (frameActual >= ciclosNecesarios * mapaTotalPixeles / velocidadScroll) {
        println("=== Ciclo infinito completado, fin del juego ===");
        noLoop();
    } else if (cameraX >= mapaTotalPixeles - 500) {
        println("=== Precargando el siguiente ciclo del mapa ===");
        preCargarColisiones(mapaTotalPixeles);
    } 

    // 🚀 Aquí forzamos el reinicio de colisiones en cada vuelta completa
    if (cameraX >= mapaTotalPixeles) {
        cameraX = 0;
        println("=== Reiniciando ciclo del mapa ===");
        reiniciarColisiones();
    }
}


void renderizarMapa() {
    int minCol = max(0, cameraX / tileWidth);
    int maxCol = min(mapWidth * 5, (cameraX + width) / tileWidth + 1);
    int minRow = max(0, cameraY / tileHeight);
    int maxRow = min(mapHeight, (cameraY + height) / tileHeight + 1);

    // 🚀 Invertimos el orden para que las capas más al fondo se dibujen primero
    for (int k = capasVisibles.length - 1; k >= 0; k--) {
        String nombreCapa = capasVisibles[k];
        JSONObject layer = findLayerByName(nombreCapa);

        if (layer == null) continue;

        JSONArray data = layer.getJSONArray("data");

        for (int row = minRow; row < maxRow; row++) {
            for (int col = minCol; col < maxCol; col++) {
                int mapCol = col % mapWidth;
                int index = row * mapWidth + mapCol;
                if (index >= data.size()) continue;

                int globalID = data.getInt(index);
                if (globalID == 0) continue;

                int tilesetIndex = 0;
                for (int t = 0; t < firstgids.length; t++) {
                    if (t == firstgids.length - 1 || globalID < firstgids[t + 1]) {
                        tilesetIndex = t;
                        break;
                    }
                }

                int localID = globalID - firstgids[tilesetIndex];
                int sx = (localID % tilesPerRow[tilesetIndex]) * tileWidth;
                int sy = (localID / tilesPerRow[tilesetIndex]) * tileHeight;

                PImage tile = tilesetImages[tilesetIndex].get(sx, sy, tileWidth, tileHeight);

                // 🚀 Renderizado continuo y sincronizado
                image(tile, (col * tileWidth - cameraX) % (mapWidth * tileWidth), row * tileHeight);
            }
        }
    }
}
  JSONObject findLayerByName(String name) {
      for (int i = 0; i < layers.size(); i++) {
          JSONObject layer = layers.getJSONObject(i);
          if (layer.getString("name").equals(name)) {
              return layer;
          }
      }
      return null; // 🔥 Si no lo encuentra, retorna null
}

void actualizarVelocidad() {
    int tiempoIntervalo = 15 * 60;  // 15 segundos en frames
    if (frameActual % tiempoIntervalo == 0 && frameActual > 0) {
        velocidadScroll += 1;
        println("🚀 Velocidad aumentada a: " + velocidadScroll);
    }
}

void renderizarHUD() {
    fill(255);
    text("FPS: " + parseInt(frameRate), 10, 20);
    text("Velocidad: " + velocidadScroll, 10, 40);
}
