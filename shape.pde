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
    PGraphics new_pg = createGraphics(img.width, img.height);
    
    float radius = sqrt(pow(sizeX, 2) + pow(sizeY, 2));
    int areaX = int(constrain(x-radius, 0, img.width));
    int areaY = int(constrain(y-radius, 0, img.height));
    int size = int(radius * 2);
    
    float new_score;
    
    if(size*size < img.width*img.height) {
      PImage img_area = img.get(areaX, areaY, size, size);
      PImage last_shape_area = new_img.get(areaX, areaY, size, size);
      PImage shape_area;
      
      new_pg.beginDraw();
      new_pg.image(new_img, 0, 0);
      new_pg.image(pg(), 0, 0);
      shape_area = new_pg.get(areaX, areaY, size, size);
      new_pg.endDraw();
      
      float last_area_score = calculateScore(last_shape_area, img_area);
      float _score = calculateScore(shape_area, img_area);
      new_score = abs(last_area_score - _score);
      //println(last_area_score, _score, new_score);
    }
    else {
      new_pg.beginDraw();
      new_pg.image(new_img, 0, 0);
      new_pg.image(pg(), 0, 0);
      new_pg.endDraw();
      
      float last_area_score = calculateScore(new_pg, img);
      new_score = abs(last_area_score - calculateScore(new_pg, img));
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
    
    if(!do_rotate || rotation % 180 == 0) {
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
      float radius = sqrt(pow(sizeX, 2) + pow(sizeY, 2));
      int cut_areaX = int(constrain(x-radius, 0, img.width));
      int cut_areaY = int(constrain(y-radius, 0, img.height));
      int cut_size = int(radius * 2);
      PImage cut_area = img.get(cut_areaX, cut_areaY, cut_size, cut_size);
      
      PGraphics temp = createGraphics(img.width, img.height);
      temp.beginDraw();
      temp.translate(x, y);
      temp.rotate(radians(-rotation));
      temp.image(cut_area, -x, -y);
      temp.endDraw();
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


float calculateScore(PImage area, PImage original) {
  float score = 0;
  area.loadPixels();
  for(int i=0; i < area.pixels.length; i++){
     color c_area = area.pixels[i];
     color c_img = original.pixels[i];
     float a1 = alpha(c_area)/255;  float r1 = red(c_area)*a1;  float g1 = green(c_area)*a1;  float b1 = blue(c_area)*a1;
     float a2 = alpha(c_img)/255; float r2 = red(c_img)*a2;  float g2 = green(c_img)*a2;  float b2 = blue(c_img)*a2;
     score += colorDistance(r1, g1, b1, r2, g2, b2);
  }
  return score;
}

float calculateScore(PGraphics area, PImage original) {
  float score = 0;
  area.loadPixels();
  for(int i=0; i < area.pixels.length; i++){
     color c_area = area.pixels[i];
     color c_img = original.pixels[i];
     float a1 = alpha(c_area)/255;  float r1 = red(c_area)*a1;  float g1 = green(c_area)*a1;  float b1 = blue(c_area)*a1;
     float a2 = alpha(c_img)/255; float r2 = red(c_img)*a2;  float g2 = green(c_img)*a2;  float b2 = blue(c_img)*a2;
     score += colorDistance(r1, g1, b1, r2, g2, b2);
  }
  return score;
}


float colorDistance(float r1, float b1, float g1, float r2, float g2, float b2) {
  return sqrt(pow(r2-r1, 2) + pow(g2-g1, 2) + pow(b2-b1, 2));
}
