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
ArrayList<RectanguloColision> colisiones = new ArrayList<RectanguloColision>();
PGraphics fondoRender;
Stella stella;

// === SETUP optimizado ===
void setup() {
  size(1280, 720);
  //size(960, 540); 
  //size(640,360); 
  //size(426, 240);
  frameRate(60);

  map = loadJSONObject("Escenarios/Nivel01_Necropolis_de_Luna/Nivel_1_Terminado_V3.tmj");

  tileWidth = map.getInt("tilewidth");
  tileHeight = map.getInt("tileheight");
  mapWidth = map.getInt("width");
  mapHeight = map.getInt("height");

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

  fondoRender = createGraphics(width, height);
  fondoRender.beginDraw();

  layers = map.getJSONArray("layers");
  for (int l = 0; l < layers.size(); l++) {
    JSONObject layer = layers.getJSONObject(l);
    if (!layer.getString("type").equals("tilelayer")) continue;

    String nombreCapa = layer.getString("name");
    if (nombreCapa.equals("Tiles de entorno suelo") || nombreCapa.equals("Tilesdeviga en diagonal")) {
      continue; // no renderizar aquí, se dibujan en draw
    }

    JSONArray data = layer.getJSONArray("data");

    for (int row = 0; row < mapHeight; row++) {
      for (int col = 0; col < mapWidth; col++) {
        int index = row * mapWidth + col;
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

        fondoRender.image(tilesetImages[tilesetIndex], col * tileWidth, row * tileHeight, tileWidth, tileHeight,
                          sx, sy, tileWidth, tileHeight);
      }
    }
  }
  fondoRender.endDraw();

  // Cargar colisiones rectangulares (sin polígonos)
  for (int i = 0; i < layers.size(); i++) {
    JSONObject l = layers.getJSONObject(i);
    if (l.getString("type").equals("objectgroup") && l.getString("name").equals("Colisiones")) {
      JSONArray objetos = l.getJSONArray("objects");

      for (int j = 0; j < objetos.size(); j++) {
        JSONObject objeto = objetos.getJSONObject(j);
        if (objeto.hasKey("width") && objeto.hasKey("height")) {
          float x = objeto.getFloat("x");
          float y = objeto.getFloat("y");
          float w = objeto.getFloat("width");
          float h = objeto.getFloat("height");

          colisiones.add(new RectanguloColision(x, y, w, h));
        }
      }
    }
  }

  stella = new Stella();
}

// === DRAW optimizado ===
void draw() {
  background(0);
  int cameraX = 0;
  int cameraY = 0;

  image(fondoRender, -cameraX, -cameraY);
  image(fondoEstatico, 0, 0, width, height);
  float parallaxOffset = parallaxX % fondoParallax.width;
  image(fondoParallax, -parallaxOffset, 0, width, height);
  image(fondoParallax, -parallaxOffset + fondoParallax.width, 0, width, height);
  parallaxX += parallaxSpeed;

  int minCol = max(0, cameraX / tileWidth);
  int maxCol = min(mapWidth, (cameraX + width) / tileWidth + 1);
  int minRow = max(0, cameraY / tileHeight);
  int maxRow = min(mapHeight, (cameraY + height) / tileHeight + 1);

  for (int l = 0; l < layers.size(); l++) {
    JSONObject layer = layers.getJSONObject(l);
    if (!layer.getString("type").equals("tilelayer")) continue;

    String nombreCapa = layer.getString("name");
    if (!nombreCapa.equals("Tiles de entorno suelo") && !nombreCapa.equals("Tilesdeviga en diagonal")) continue;

    JSONArray data = layer.getJSONArray("data");

    for (int row = minRow; row < maxRow; row++) {
      for (int col = minCol; col < maxCol; col++) {
        int index = row * mapWidth + col;
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

        image(tilesetImages[tilesetIndex], col * tileWidth, row * tileHeight, tileWidth, tileHeight,
              sx, sy, tileWidth, tileHeight);
      }
    }
  }

  stella.actualizar(colisiones);
  stella.dibujar();

  fill(255);
  text("FPS: " + int(frameRate), 10, 20);
}

class RectanguloColision {
  float x, y, w, h;

  RectanguloColision(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }
}
