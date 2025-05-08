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
    return pointInPolygon(centro, vertices); // 👈 Corrección aquí
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


      void ajustarPosicion(Stella stella) {
    float margen = 0.5;          // 🔥 Margen de error
    float posicionY = Float.MAX_VALUE;

    // === 🚀 Recorremos cada segmento del polígono
    for (int i = 0; i < vertices.size() - 1; i++) {
        PVector v1 = vertices.get(i);
        PVector v2 = vertices.get(i + 1);

        // 🔥 Detectar si Stella está dentro del rango del segmento
        if ((stella.x > v1.x && stella.x < v2.x) || (stella.x > v2.x && stella.x < v1.x)) {
            float pendiente = (v2.y - v1.y) / (v2.x - v1.x);
            float yCalculada = pendiente * (stella.x - v1.x) + v1.y;

            // 🔥 Solo actualizar si la nueva Y es más baja que la actual
            if (yCalculada < posicionY) {
                posicionY = yCalculada;
            }
        }
    }

    // === 🚀 Movimiento suave hacia la posición calculada
    if (posicionY != Float.MAX_VALUE) {
        float diferencia = posicionY - stella.y;

        // 🔥 Movimiento suave, no directo
        if (abs(diferencia) > margen) {
            stella.y += diferencia * 0.2;  // 🔥 Ajuste suave (20%)
        } else {
            stella.y = posicionY;
        }

        // 🔥 Ajustes de estado de Stella
        stella.velocidadY = 0;
        stella.enElSuelo = true;
        stella.estaCayendo = false;
    }
}
  float lerp(float start, float stop, float amt) {
    return start + amt * (stop - start);
}
}
