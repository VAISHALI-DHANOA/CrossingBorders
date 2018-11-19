PGraphics pg, pgMask, pgDrawing;
PImage drawing, mask, maskInv;
color c;

void setup() {
  size (600, 600, P2D);
  c = color(255, 0, 0);
  pg = createGraphics(600, 600, P2D);
  pg.beginDraw();
  pg.background(255, 255, 0);
  pg.noFill();
  pg.stroke(c);
  pg.strokeWeight(10);
  pg.endDraw();
  drawing = loadImage("drawing-white.png");
  mask = loadImage("mask-white.png");
  pgMask = createGraphics(600, 600, P2D);
  pgMask.beginDraw();
  pgMask.background(mask);
  pgMask.endDraw();
  maskInv = loadImage("mask-white-inv.png");
  pgDrawing = createGraphics(600, 600, P2D);
  pgDrawing.beginDraw();
  pgDrawing.image(drawing, 0, 0);
  pgDrawing.image(maskInv, 0, 0);
  pgDrawing.endDraw();
}

void draw() {
  background(255, 255, 0);
  float b = brightness(drawing.get(mouseX, mouseY));
  if (b < 20) c = color(random(255), 0, 0);
  pg.beginDraw();
  pg.stroke(c);
  pg.line(pmouseX, pmouseY, mouseX, mouseY);
  pg.endDraw();
  pg.mask(mask);
  image(pg, 0, 0);
  blendMode(DARKEST);
  image(pgDrawing, 0, 0);
  blendMode(BLEND);
}
