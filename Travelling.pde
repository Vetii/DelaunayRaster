class Travelling {
  PVector position;
  PImage img;
  PVector start;
  PVector stop;
  float amt;
  int maxX, maxY, minX, minY;

  Travelling(PImage i, int w, int h) {
    position = new PVector();
    start    = new PVector();
    stop     = new PVector();
    
    img = i;
    maxX = max(0, w - img.width);
    maxY = max(0, h - img.height);
    minX = min(0, w - img.width);
    minY = min(0, h - img.height);

    amt = 0.0;
    chooseStartStp(10);    
  }

  void wander(float factor) {
    float angle = noise(position.x * 0.0001, position.y * 0.0001, millis() * 0.001) * TWO_PI;
    position.x += cos(angle) * factor;
    position.y += sin(angle) * factor;
  }

  void alongLine(float amount) {    
    amt = constrain(amt + amount, 0.0, 1.0);
    // reset if the end of the line is reached.
    if (amt == 1.0) {
      chooseStartStp(20);
      amt = 0.0;
    }
    position.x = lerp(start.x, stop.x, amt);
    position.y = lerp(start.y, stop.y, amt);
  }

  void chooseStartStp (int nbSamples) {
    // this is a bit wierd but anyway.
    PVector p1, p2;
    float maxDist = 0.0;

    for (int i = 0; i < nbSamples; ++i) {
      p1 = new PVector(random(minX, maxX), random(minY, maxY));
      p2 = new PVector(random(minX, maxX), random(minY, maxY));
      if (p1.dist(p2) > maxDist) {
        start = p1.get();
        stop  = p2.get();
        maxDist = p1.dist(p2);
      }
    }
  }

  float linearRepulsion(float val, float min, float max) {
    float x = val;
    x = constrain(x, min + 1, max - 1);
    float w = max - min;
    w /= 2;
    float minToX = x - min; // always positive (will increase x)
    float maxToX = x - max; // always negative (will decrease x)
    x += w / minToX;
    x += w / maxToX;
    return x;
  }

  void maintainInFrame() {
    //position.x = constrain(position.x, minX, maxX);
    position.x = linearRepulsion(position.x, minX, maxX);
    //position.y = constrain(position.y, minY, maxY);
    position.y = linearRepulsion(position.y, minY, maxY);
  }
}

