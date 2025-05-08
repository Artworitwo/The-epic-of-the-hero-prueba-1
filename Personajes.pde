class Stella {
    PImage[] correrFrames;
    PImage[] saltoFrames;
    PImage[] caerFrames;
    int totalFramesRun = 8;
    int totalFramesJump = 3;
    int totalFramesFall = 3;
    int frameActual = 0;
    int frameDelay = 5;
    int frameCount = 0;

    float x = 200;
    float y = 400;
    float ancho = 64;
    float alto = 64;
    float velocidadY = 0;
    float gravedad = 0.8;
    float fuerzaSalto = -16;
    boolean enElSuelo = false;
    boolean estaCayendo = false;

    void inicializar() {
        println("=== Inicializando Stella ===");
        correrFrames = new PImage[totalFramesRun];
        for (int i = 0; i < totalFramesRun; i++) {
            correrFrames[i] = loadImage("Personajes/Stella/Run/Stella_Run_" + (i + 1) + ".png");
            if (correrFrames[i] == null) {
                println("❌ Error cargando Stella_Run_" + (i + 1) + ".png");
            } else {
                println("✅ Cargado Stella_Run_" + (i + 1) + ".png correctamente");
            }
        }

        saltoFrames = new PImage[totalFramesJump];
        for (int i = 0; i < totalFramesJump; i++) {
            saltoFrames[i] = loadImage("Personajes/Stella/Jump/Stella_Jump_" + (i + 1) + ".png");
            if (saltoFrames[i] == null) {
                println("❌ Error cargando Stella_Jump_" + (i + 1) + ".png");
            } else {
                println("✅ Cargado Stella_Jump_" + (i + 1) + ".png correctamente");
            }
        }

        caerFrames = new PImage[totalFramesFall];
        for (int i = 0; i < totalFramesFall; i++) {
            caerFrames[i] = loadImage("Personajes/Stella/Fall/Stella_Fall_" + (i + 1) + ".png");
            if (caerFrames[i] == null) {
                println("❌ Error cargando Stella_Fall_" + (i + 1) + ".png");
            } else {
                println("✅ Cargado Stella_Fall_" + (i + 1) + ".png correctamente");
            }
        }
        println("=== Finalizada la inicialización ===");
    }

void actualizar(ArrayList<Colisionable> colisiones) {
    float velocidadAnteriorY = velocidadY;
    velocidadY += gravedad;
    float nuevaPosicionY = y + velocidadY;
    enElSuelo = false;

    boolean colisionDetectada = false;
    float yPlataforma = Float.MAX_VALUE;

    // === 🚀 Recorremos las colisiones para buscar el "piso" más cercano
    for (Colisionable c : colisiones) {
        if (c instanceof RectanguloColision) {
            RectanguloColision rect = (RectanguloColision) c;

            // 🚀 Sincronización con el movimiento del scroll infinito
            float rectPosX = (rect.x - cameraX);

            // === 🚀 Raycast por debajo de Stella
            if (rectPosX + rect.w > x && rectPosX < x + ancho) {
                if (nuevaPosicionY + alto >= rect.y && y + alto <= rect.y + rect.h) {
                    if (rect.y < yPlataforma) {
                        yPlataforma = rect.y;
                        colisionDetectada = true;
                    }
                }
            } 
        } else if (c instanceof PoligonoColision) {
            PoligonoColision poly = (PoligonoColision) c;
            if (poly.colisionaCon(x, nuevaPosicionY, ancho, alto)) {
                poly.ajustarPosicion(this);
                colisionDetectada = true;
            }
        }
    }

    // === 🚀 Si detectó un piso, se ajusta la posición
    if (colisionDetectada) {
        y = yPlataforma - alto;
        velocidadY = 0;
        enElSuelo = true;
        estaCayendo = false;
        println("✅ Colisión sólida detectada con plataforma en Y: " + yPlataforma);
    } else {
        y = nuevaPosicionY;
        estaCayendo = true;

        // 🚀 Evitar que caiga al vacío
        if (y > height + 50) {
            println("⚠️ Stella cayó al vacío, reiniciando posición");
            y = 100;
            velocidadY = 0;
        }
    }

  // Animación de frames
        frameCount++;
        if (frameCount >= frameDelay) {
            frameCount = 0;
            if (enElSuelo) {
                frameActual = (frameActual + 1) % totalFramesRun;
            } else if (estaCayendo) {
                frameActual = (frameActual + 1) % totalFramesFall;
            } else {
                frameActual = (frameActual + 1) % totalFramesJump;
            }
        }
    }
    void saltar() {
        if (enElSuelo) {
            velocidadY = fuerzaSalto;
            enElSuelo = false;
        }
    }

    void dibujar() {
        if (!enElSuelo && estaCayendo) {
            if (frameActual >= 0 && frameActual < caerFrames.length && caerFrames[frameActual] != null) {
                image(caerFrames[frameActual], x, y, ancho, alto);
            }
        } else if (!enElSuelo) {
            if (frameActual >= 0 && frameActual < saltoFrames.length && saltoFrames[frameActual] != null) {
                image(saltoFrames[frameActual], x, y, ancho, alto);
            }
        } else {
            if (frameActual >= 0 && frameActual < correrFrames.length && correrFrames[frameActual] != null) {
                image(correrFrames[frameActual], x, y, ancho, alto);
            }
        }
    }
   
}  
  void renderizarStella() {
      stella.actualizar(colisiones);
      stella.dibujar();
  
      if (keyPressed && key == ' ') {
          stella.saltar();
      }
    }
