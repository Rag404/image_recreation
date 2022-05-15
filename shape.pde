class Shape {
  int x;  int sizeX;
  int y;  int sizeY;
  float rotation;
  float alpha;
  color c;
  float score = 0;
  
  
  Shape(float x, float y, float sizeX, float sizeY, float rotation, float alpha) {
    this.x = int(x);
    this.y = int(y);
    this.sizeX = int(sizeX);
    this.sizeY = int(sizeY);
    if(do_rotate) this.rotation = rotation; else this.rotation = 0;
    this.alpha = alpha;
    loadColor();
  }
  
  
  PGraphics pg() {
    PGraphics _pg = createGraphics(img.width, img.height);
    _pg.beginDraw();
    _pg.noStroke();
    _pg.rectMode(CENTER);
    _pg.fill(c);
    _pg.rotate(rotation);
    _pg.rect(x, y, sizeX, sizeY);
    _pg.endDraw();
    return _pg;
  }
  
  
  float loadScore() {
    float new_score = 0;
    PGraphics pg = pg();
    PGraphics new_pg = createGraphics(img.width, img.height);
    
    new_pg.beginDraw();
    new_pg.image(new_img, 0, 0);
    new_pg.image(pg, 0, 0);
    new_pg.endDraw();
    
    new_pg.loadPixels();
    img.loadPixels();
    
    for(int i=0; i < img.pixels.length; i++){
       color c_pg = new_pg.pixels[i];
       color c_img = img.pixels[i];
       float a1 = alpha(c_pg)/255;  float r1 = red(c_pg)*a1;  float g1 = green(c_pg)*a1;  float b1 = blue(c_pg)*a1;
       float a2 = alpha(c_img)/255; float r2 = red(c_img)*a2;  float g2 = green(c_img)*a2;  float b2 = blue(c_img)*a2;
       new_score += colorDistance(r1, g1, b1, r2, g2, b2);
    }
    
    this.score = new_score;
    return new_score;
  }
  
  
  Shape loadColor() {
    int areaX = constrain(x-sizeX, 0, img.width);
    int areaY = constrain(y-sizeY, 0, img.height);
    int areaW = constrain(areaX+sizeX*2, 0, img.width) - areaX;
    int areaH = constrain(areaY+sizeY*2, 0, img.height) - areaY;
    
    PImage area;
    
    if(!do_rotate || rotation == 0 || abs(rotation) == 180) {
      area = img.get(areaX, areaY, areaW, areaH);
    }
    else if(abs(rotation) == 90) {
      areaX = constrain(x-sizeY, 0, img.width);
      areaY = constrain(y-sizeX, 0, img.height);
      areaW = constrain(areaX+sizeY*2, 0, img.width) - areaX;
      areaH = constrain(areaY+sizeX*2, 0, img.height) - areaY;
      area = img.get(areaX, areaY, areaH, areaW);
    }
    else {
      PGraphics temp = createGraphics(img.width, img.height);
      temp.beginDraw();
      temp.translate(x, y);
      temp.rotate(radians(rotation));
      temp.image(img, -x, -y);
      temp.endDraw();
      temp.loadPixels();
      area = temp.get(areaX, areaY, areaW, areaH);
    }
    
    float avg_r = 0;  float avg_g = 0;  float avg_b = 0;
    int area_pixel_count = area.pixels.length;
    area.loadPixels();
    
    for(color c: area.pixels) {
      avg_r += red(c) / area_pixel_count;
      avg_g += green(c) / area_pixel_count;
      avg_b += blue(c) / area_pixel_count;
      this.score += abs(red(c)-avg_r) + abs(green(c)-avg_g) + abs(blue(c)-avg_b);
    }
    
    this.c = color(avg_r, avg_g, avg_b, alpha);
    return this;
  }
}



Shape randomShape() {
  int x = int(random(img.width+1));
  int y = int(random(img.height+1));
  int sizeX = int(random(min_size, max_size));
  int sizeY = int(random(min_size, max_size));
  float rotation = random(-180, 180);
  float alpha = random(random(256));
  return new Shape(x, y, sizeX, sizeY, rotation, alpha);
}

/*
float med(float[] list) {
  list = sort(list);
  float median;
  if(list.length%2 == 0) median = (list[list.length/2] + list[list.length/2-1]) / 2;
  else median = list[list.length/2];
  return median;
}
*/

float colorDistance(float r1, float b1, float g1, float r2, float g2, float b2) {
  return sqrt(pow(r2-r1, 2) + pow(g2-g1, 2) + pow(b2-b1, 2));
}
