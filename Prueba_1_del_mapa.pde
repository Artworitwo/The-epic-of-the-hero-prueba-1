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

// === Interfaz para colisiones ===
interface Colisionable {
  boolean colisionaCon(float px, float py, float pw, float ph);
}

class RectanguloColision implements Colisionable {
  float x, y, w, h;

  RectanguloColision(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  public boolean colisionaCon(float px, float py, float pw, float ph) {
    return px < x + w && px + pw > x && py < y + h && py + ph > y;
  }
}

class PoligonoColision implements Colisionable {
  ArrayList<PVector> vertices;

  PoligonoColision(ArrayList<PVector> v) {
    vertices = v;
  }

  public boolean colisionaCon(float px, float py, float pw, float ph) {
    PVector centro = new PVector(px + pw / 2, py + ph / 2);
    return pointInPolygon(centro, vertices);
  }

  boolean pointInPolygon(PVector point, ArrayList<PVector> polygon) {
    int i, j;
    boolean inside = false;
    for (i = 0, j = polygon.size() - 1; i < polygon.size(); j = i++) {
      if (((polygon.get(i).y > point.y) != (polygon.get(j).y > point.y)) &&
        (point.x < (polygon.get(j).x - polygon.get(i).x) * (point.y - polygon.get(i).y) /
         (polygon.get(j).y - polygon.get(i).y) + polygon.get(i).x)) {
        inside = !inside;
      }
    }
    return inside;
  }
}



// === SETUP optimizado ===
void setup() {
  size(1280, 720);
  frameRate(60);
  noSmooth();

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

  stella = new Stella();
}

// === DRAW optimizado ===
void draw() {
  background(0);

  image(fondoEstatico, 0, 0, width, height);
  float parallaxOffset = parallaxX % fondoParallax.width;
  image(fondoParallax, -parallaxOffset, 0, width, height);
  image(fondoParallax, -parallaxOffset + fondoParallax.width, 0, width, height);
  parallaxX += parallaxSpeed;

  int cameraX = 0;
  int cameraY = 0;
  int minCol = max(0, cameraX / tileWidth);
  int maxCol = min(mapWidth, (cameraX + width) / tileWidth + 1);
  int minRow = max(0, cameraY / tileHeight);
  int maxRow = min(mapHeight, (cameraY + height) / tileHeight + 1);

  String[] capasVisibles = {
    "Capa del terreno 1",
    "Capa de rejas",
    "Arbustos",
    "Capa arbustos y piedras",
    "Capa de estatuas",
    "Estatua 2",
    "Capa de fondo 1"
  };

  for (int l = 0; l < layers.size(); l++) {
    JSONObject layer = layers.getJSONObject(l);
    if (!layer.getString("type").equals("tilelayer")) continue;

    String nombreCapa = layer.getString("name");
    boolean debeDibujar = false;

    for (String capa : capasVisibles) {
      if (nombreCapa.equals(capa)) {
        debeDibujar = true;
        break;
      }
    }

    if (!debeDibujar) continue;

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

        PImage tile = tilesetImages[tilesetIndex].get(sx, sy, tileWidth, tileHeight);
        image(tile, col * tileWidth, row * tileHeight);
      }
    }
  }

  stella.actualizar(colisiones);
  stella.dibujar();

  fill(255);
  text("FPS: " + int(frameRate), 10, 20);
}
