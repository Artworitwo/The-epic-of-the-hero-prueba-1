class Stella {
  PImage[] correrFrames;
  int totalFrames = 8;
  int frameActual = 0;
  int frameDelay = 5;
  int frameCounter = 0;

  float x = 200;
  float y = 0;
  float ancho = 32;
  float alto = 32;

  float velocidadY = 0;
  float gravedad = 0.6;
  boolean enElSuelo = false;

  Stella() {
    correrFrames = new PImage[totalFrames];
    for (int i = 0; i < totalFrames; i++) {
      correrFrames[i] = loadImage("Personajes/Stella/Run/Stella_Run_" + (i + 1) + ".png");
    }
  }

  void actualizar(ArrayList<RectanguloColision> colisiones) {
    // Animación
    frameCounter++;
    if (frameCounter >= frameDelay) {
      frameCounter = 0;
      frameActual = (frameActual + 1) % totalFrames;
    }

    // Física
    velocidadY += gravedad;
    y += velocidadY;
    enElSuelo = false;

    // Colisión con suelo
    for (RectanguloColision r : colisiones) {
      if (colisionaCon(r)) {
        if (velocidadY > 0) { // solo si cae
          y = r.y - alto;
          velocidadY = 0;
          enElSuelo = true;
        }
      }
    }
  }

  void dibujar() {
    image(correrFrames[frameActual], x, y, ancho, alto);
  }

  boolean colisionaCon(RectanguloColision r) {
    return x + ancho > r.x && x < r.x + r.w && y + alto > r.y && y < r.y + r.h;
  }
}
