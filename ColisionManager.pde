// === Método para reiniciar las colisiones del mapa ===
String[] capasVisibles = {
    "Capa del terreno 1",
    "Capa de rejas",
    "Arbustos",
    "Capa arbustos y piedras",
    "Capa de estatuas",
    "Estatua 2",
    "Capa de fondo 1"
};

String capaColisiones = "Colisiones";

// === Método para reiniciar las colisiones del mapa ===
void reiniciarColisiones() {
    println("=== Reiniciando colisiones para el siguiente ciclo ===");
    colisiones.clear(); // 🔥 Limpiamos para evitar duplicados

    // 🚀 Precargamos las nuevas colisiones en su posición inicial
    preCargarColisiones(0);

    // 🚀 Precargamos las siguientes iteraciones
    int mapaTotalPixeles = mapWidth * tileWidth;
    preCargarColisiones(mapaTotalPixeles);
    preCargarColisiones(mapaTotalPixeles * 2);

    println("=== Colisiones regeneradas correctamente ===");
}
void preCargarColisiones(int offsetX) {
        println("=== Precargando colisiones para el siguiente ciclo ===");

    // 🚀 Limpiamos solo las colisiones que están en ese ciclo
    ArrayList<Colisionable> nuevasColisiones = new ArrayList<Colisionable>();

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
                        vertices.add(new PVector(x + px + offsetX, y + py));
                    }

                    nuevasColisiones.add(new PoligonoColision(vertices));
                } else if (objeto.hasKey("width") && objeto.hasKey("height")) {
                    float x = objeto.getFloat("x");
                    float y = objeto.getFloat("y");
                    float w = objeto.getFloat("width");
                    float h = objeto.getFloat("height");

                    nuevasColisiones.add(new RectanguloColision(x + offsetX, y, w, h));
                }
            }
        }
    }

    // 🚀 Remplazamos las colisiones del ciclo actual
    sincronizarColisiones(nuevasColisiones);

    println("=== Colisiones precargadas correctamente ===");
}
void sincronizarColisiones(ArrayList<Colisionable> nuevasColisiones) {
    ArrayList<Colisionable> colisionesFiltradas = new ArrayList<Colisionable>();

    for (Colisionable nueva : nuevasColisiones) {
        boolean existe = false;
        for (Colisionable actual : colisiones) {
            if (nueva instanceof RectanguloColision && actual instanceof RectanguloColision) {
                RectanguloColision r1 = (RectanguloColision) nueva;
                RectanguloColision r2 = (RectanguloColision) actual;

                if (r1.x == r2.x && r1.y == r2.y && r1.w == r2.w && r1.h == r2.h) {
                    existe = true;
                    break;
                }
            } else if (nueva instanceof PoligonoColision && actual instanceof PoligonoColision) {
                PoligonoColision p1 = (PoligonoColision) nueva;
                PoligonoColision p2 = (PoligonoColision) actual;

                if (p1.vertices.equals(p2.vertices)) {
                    existe = true;
                    break;
                }
            }
        }

        if (!existe) {
            colisionesFiltradas.add(nueva);
        }
    }

    // 🚀 Actualizamos la lista de colisiones solo con las nuevas
    colisiones.addAll(colisionesFiltradas);
}


// === Método para reiniciar el juego completo ===
void reiniciarJuego() {
    println("=== Reiniciando Juego ===");

    // Reiniciar cámara y variables de scroll
    cameraX = 0;
    cameraY = 0;
    parallaxX = 0;
    frameActual = 0;

    // Reiniciar Stella a su posición inicial
    stella = new Stella();
    stella.inicializar();
    
    // Reiniciar colisiones
    reiniciarColisiones();
    
    // Volver a correr el bucle principal
    loop();
}
