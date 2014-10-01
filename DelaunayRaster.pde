/* Toxiclibs (delaunay triangulation) */
import toxi.geom.Vec2D;
import toxi.geom.Vec3D;
import toxi.geom.Triangle2D;
import toxi.geom.Polygon2D;
import toxi.geom.mesh2d.Voronoi;

import processing.pdf.*;

import java.util.ArrayList;

/* General variables */
ArrayList<Triangle2D> triangles;
Voronoi vor;
PImage img = null;
int nbPoints;
int maxPoints;
Vec2D origin, xmax, ymax, bound;
float s;
PGraphics map;
PGraphics draw;
float outputRatio;
PVector position = new PVector(0, 0);// For moving the FBO.
Vec2D worst;
boolean recording;
Travelling travelling;

void setup() {
  selectInput("Select an image to process...", "fileSelected");
  maxPoints = 2500;
  nbPoints = maxPoints;
  s = 8;

  size(1280, 720);

  recording = false;
  noLoop();
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or user canceled");
    exit();
  } else {
    println("File selected: " + selection.getAbsolutePath());

    img = loadImage(selection.getAbsolutePath());
    //println(img.pixels.length);
    int x = img.width;
    int y = img.height;

    map     = createGraphics(x, y);
    draw    = createGraphics(x, y);

    outputRatio = 1.0; 

    triangles = new ArrayList<Triangle2D> ();
    vor = new Voronoi ();

    noStroke();

    map.beginDraw();
    map.background(0);
    map.endDraw();

    draw.beginDraw();
    draw.background(img);
    draw.endDraw();

    travelling = new Travelling(img, width, height);
    
    img.loadPixels();
    //loop();
  }
}

void cubism(int nbPoints, float percent) {
  for (int i = 0; i < nbPoints; ++i) {
    Vec2D v1 = new Vec2D(random(img.width), random(img.height));
    Vec2D v2 = new Vec2D(random(img.width), random(img.height));

    map.beginDraw();
    strokeWeight(s);
    stroke(255);
    line(v1.x, v1.y, v2.x, v2.y);
    map.endDraw();

    for (float p = 0.0; p < 1.0; p += percent) {
      vor.addPoint(v1.interpolateTo(v2, p));
    }
  }
}

Vec2D maxDInRandom(int nbSamples) {
  draw.loadPixels();
  map.loadPixels();
  Vec2D worst = new Vec2D();
  int bimg, bmap, b;
  bmap = 0;
  int worstIndex = 0;
  Vec3D diff = new Vec3D();
  float worstDiff = 0.0;
  /* Find the worst pixel error */
  //for (int i = 0; i < draw.pixels.length; ++i) {
  for (int n = 0; n < nbSamples; ++n) {
    int i = int(random(draw.pixels.length));
    bimg = img.pixels[i];
    bmap = map.pixels[i];
    b    = draw.pixels[i];
    diff.x = red(bimg) - red(b);
    diff.y = green(bimg) - green(b);
    diff.z = blue(bimg) - blue(b);
    if (diff.magSquared() > worstDiff && brightness(bmap) < 10) {
      worstDiff = diff.magSquared();
      worstIndex = i;
    }
  }
  worst.x = worstIndex % img.width;
  worst.y = (worstIndex - worst.x) / img.width;

  return worst;
}

Vec2D findWorstPixel() {
  draw.loadPixels();
  map.loadPixels();
  Vec2D worst = new Vec2D();
  int bimg, bmap, b;
  bmap = 0;
  int worstIndex = 0;
  Vec3D diff = new Vec3D();
  float worstDiff = 0.0;
  /* Find the worst pixel error */
  for (int i = 0; i < draw.pixels.length; ++i) {
    bimg = img.pixels[i];
    bmap = map.pixels[i];
    b    = draw.pixels[i];
    diff.x = red(bimg) - red(b);
    diff.y = green(bimg) - green(b);
    diff.z = blue(bimg) - blue(b);
    if (diff.magSquared() > worstDiff && brightness(bmap) < 10) {
      worstDiff = diff.magSquared();
      worstIndex = i;
    }
  }
  worst.x = worstIndex % img.width;
  worst.y = (worstIndex - worst.x) / img.width;

  return worst;
}

void keyPressed() {
  switch(key) {
  case 'd': 
    println("Injecting...");
    nbPoints = maxPoints;
    loop();
    break;
  case 'c':
    cubism(16, 0.02);
    loop();
    break;
  case 'b': 
    stroke(0); 
    break;
  case 'r': 
    recording = !recording; 
    break;
  case 'p': 
    beginRecord(PDF, "out.pdf");
    int x, y;
    color c;
    for (Triangle2D t : vor.getTriangles ()) {
      t.computeCentroid();
      x = int(constrain(t.centroid.x, 0, img.width  - 1));
      y = int(constrain(t.centroid.y, 0, img.height - 1));
      c = img.get(x, y);

      fill(c);
      noStroke();
      triangle(t.a.x, t.a.y, t.b.x, t.b.y, t.c.x, t.c.y);
    }
    endRecord();
    println("printed.");
    
    break;
  }
}

void draw() {
  if (img == null) { 
    return;
  }
  background(0);  
  int x, y;
  color c, ca, cb, cc;

  draw.beginDraw();
  for (Triangle2D t : vor.getTriangles ()) {
    t.computeCentroid();
    x = int(constrain(t.centroid.x, 0, img.width  - 1));
    y = int(constrain(t.centroid.y, 0, img.height - 1));
    c = img.get(x, y);
    draw.fill(c);
    draw.noStroke();
    draw.triangle(t.a.x, t.a.y, t.b.x, t.b.y, t.c.x, t.c.y);
  }
  draw.endDraw();

  if (nbPoints > 0) {
    //worst = findWorstPixel();
    worst = maxDInRandom(3000);

    map.beginDraw();
    map.noStroke();
    map.fill(255);
    map.ellipse(worst.x, worst.y, s, s);
    //map.point(worst.x, worst.y);
    map.endDraw();

    vor.addPoint(new Vec2D(worst.x, worst.y));

    --nbPoints;
  } else {
    println("done");
    noLoop();
  }
  travelling.alongLine(1.0/float(maxPoints));
  //travelling.wander(1.0);
  travelling.maintainInFrame();
  translate(travelling.position.x, travelling.position.y);
  
  image(draw, 0, 0);
  if (recording == true) {
    saveFrame("./video/screen-#####.png");
  }
}

