class Shape {
  // Attributes of a shape
  int x;  int sizeX;
  int y;  int sizeY;
  float rotation = 0;
  float alpha;
  color c;
  float score = 0;
  
  // Constructor of the class
  Shape(float x, float y, float sizeX, float sizeY, float rotation, float alpha) {
    this.x = int(x);
    this.y = int(y);
    this.sizeX = int(sizeX);
    this.sizeY = int(sizeY);
    if(do_rotate) this.rotation = rotation;  // Apply rotation or not if specified in the config
    this.alpha = alpha;
    loadColor();
  }
  
  
  // Return an empty PGraphic with only the shape
  PGraphics pg() {
    PGraphics _pg = createGraphics(img.width, img.height);
    _pg.beginDraw();
    _pg.noStroke();
    _pg.rectMode(CENTER);
    _pg.fill(c);
    _pg.rotate(radians(rotation));
    _pg.rect(x, y, sizeX, sizeY);
    _pg.endDraw();
    return _pg;
  }
  
  
  float loadScore() {
    // Determine the area of the shape inside the reproduction
    float radius = sqrt(pow(sizeX, 2) + pow(sizeY, 2));
    int areaX = int(constrain(x-radius, 0, img.width));
    int areaY = int(constrain(y-radius, 0, img.height));
    int size = int(radius * 2);
    
    // Get a new image of only the shape area inside the original image (img_area) and the reproduction (last_shape_area)
    PImage img_area = img.get(areaX, areaY, size, size);
    PImage last_shape_area = new_img.get(areaX, areaY, size, size);
    
    // Create a temporary PGraphic with the shape and the reproduction combined
    PGraphics shape_in_img = createGraphics(img.width, img.height);
    shape_in_img.beginDraw();
    shape_in_img.image(new_img, 0, 0);
    shape_in_img.image(pg(), 0, 0);
    PImage shape_area = shape_in_img.get(areaX, areaY, size, size);  // Get the shape area in the temporary PGraphic
    shape_in_img.endDraw();
    
    // Calculate the score of the reproduction with and without the shape
    float last_area_score = calculateScore(last_shape_area, img_area);
    float new_score = calculateScore(shape_area, img_area);
    
    // Since "last_area_score" and "new_score" are inverted scores (low score = good) the difference between them is "(-new_score) - (-last_area_score)" which is equivalent to "last_area_score - new_score"
    float final_score = last_area_score - new_score;
    
    this.score = final_score;
    return final_score;
  }
  
  
  color loadColor() {
    // Determine the area the shape occupies and initialize its image
    int areaX = constrain(x-sizeX, 0, img.width);
    int areaY = constrain(y-sizeY, 0, img.height);
    int areaW = constrain(areaX+sizeX*2, 0, img.width) - areaX;
    int areaH = constrain(areaY+sizeY*2, 0, img.height) - areaY;
    PImage area;
    
    if(!do_rotate || rotation % 180 == 0) {
      // If the rotation is disabled or the shape rotation is a multiple of 180 (which is equivalent to no rotation), simply get the shape area in the original image
      area = img.get(areaX, areaY, areaW, areaH);
    }
    else if(abs(rotation) == 90) {
      // If the image is rotated at 90°, recalculate the area but swap the shape width and height, and get the area in the original image
      areaX = constrain(x-sizeY, 0, img.width);
      areaY = constrain(y-sizeX, 0, img.height);
      areaW = constrain(areaX+sizeY*2, 0, img.width) - areaX;
      areaH = constrain(areaY+sizeX*2, 0, img.height) - areaY;
      area = img.get(areaX, areaY, areaH, areaW);
    }
    else {
      // Cut a small area of the original image as it is faster to process a rotation with a smaller image
      float radius = sqrt(pow(sizeX, 2) + pow(sizeY, 2));
      int cut_areaX = int(constrain(x-radius, 0, img.width));
      int cut_areaY = int(constrain(y-radius, 0, img.height));
      int cut_size = int(radius * 2);
      PImage cut_area = img.get(cut_areaX, cut_areaY, cut_size, cut_size);
      
      // Turn the cut part by the oposite rotation of the shape so it is like the shape area is not rotated
      PGraphics temp = createGraphics(img.width, img.height);
      temp.beginDraw();
      temp.translate(x, y);
      temp.rotate(radians(-rotation));
      temp.image(cut_area, -x, -y);
      temp.endDraw();
      area = temp.get(areaX, areaY, areaW, areaH);
    }
    
    // Initialize the average RGB values of the shape area, get the number of pixels in 
    float avg_r = 0;  float avg_g = 0;  float avg_b = 0;
    int area_pixel_count = area.pixels.length;
    area.loadPixels();
    
    for(color c: area.pixels) {
      // Add current RGB to the average color
      avg_r += red(c) / area_pixel_count;
      avg_g += green(c) / area_pixel_count;
      avg_b += blue(c) / area_pixel_count;
    }
    
    /*
    // If the average color has a high range between the "smallest" and "bigger" color then the shape should have a worse score
    for(color c: area.pixels) {
      // Add the difference between the current color and the average color to the score
      this.score += colorDistance(red(c), green(c), blue(c), avg_r, avg_g, avg_b);
    }
    */
    
    // Set the new color
    this.c = color(avg_r, avg_g, avg_b, alpha);
    return this.c;
  }
}



Shape randomShape() {
  // Return a shape with random propreties
  int x = int(random(img.width+1));
  int y = int(random(img.height+1));
  int sizeX = int(random(min_size, max_size));
  int sizeY = int(random(min_size, max_size));
  float rotation = random(-180, 180);
  float alpha = random(random(256));
  return new Shape(x, y, sizeX, sizeY, rotation, alpha);
}


float calculateScore(PImage area, PImage original) {
  // Return a score based on the difference between all the area pixels and the original pixels
  float score = 0;
  area.loadPixels();
  for(int i=0; i < area.pixels.length; i++) {
     color c_area = area.pixels[i];
     color c_img = original.pixels[i];
     float a1 = alpha(c_area)/255;  float r1 = red(c_area)*a1;  float g1 = green(c_area)*a1;  float b1 = blue(c_area)*a1;
     float a2 = alpha(c_img)/255; float r2 = red(c_img)*a2;  float g2 = green(c_img)*a2;  float b2 = blue(c_img)*a2;
     score += colorDistance(r1, g1, b1, r2, g2, b2);
  }
  return score;
}

// Same as above but handles PGraphics instead of PImage
float calculateScore(PGraphics area, PImage original) {
  float score = 0;
  area.loadPixels();
  for(int i=0; i < area.pixels.length; i++) {
     color c_area = area.pixels[i];
     color c_img = original.pixels[i];
     float a1 = alpha(c_area)/255;  float r1 = red(c_area)*a1;  float g1 = green(c_area)*a1;  float b1 = blue(c_area)*a1;
     float a2 = alpha(c_img)/255; float r2 = red(c_img)*a2;  float g2 = green(c_img)*a2;  float b2 = blue(c_img)*a2;
     score += colorDistance(r1, g1, b1, r2, g2, b2);
  }
  return score;
}


float colorDistance(float r1, float b1, float g1, float r2, float g2, float b2) {
  // Return the distance between 2 colors
  return sqrt(pow(r2-r1, 2) + pow(g2-g1, 2) + pow(b2-b1, 2));
}
