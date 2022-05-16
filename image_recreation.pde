// Natural selection
final int shape_count = 500;
final int gen_count = 10;
final int survivor_count = 100;
final int child_count = shape_count/survivor_count;

// Genetic
final int min_size = 5;
final int max_size = 300;
final int position_variation = 35;
final int size_variation = 20;
final int rotation_variation = 10;
final int alpha_variation = 30;

// Performances
final int thread_count = 1;
final boolean do_rotate = false;

// Display
final float bar_size = -200;

// Image stuff
PImage img;
PGraphics new_img;
PGraphics[] buffer = {};
float last_score = 0;

// Thread stuff
float[] percentages = new float[thread_count];
int count = 0;
int thread_index;


void settings() {
  size(1440, 451, P2D);
}


void setup() {
  img = loadImage("wallpaper3_resized.jpg");
  img.loadPixels();
  image(img, width/2, 0);
  
  new_img = createGraphics(img.width, img.height);
  new_img.beginDraw();
  new_img.background(0);
  new_img.endDraw();
  
  for(int i=0; i < thread_count; i++) {
    thread_index = i;
    thread("selection");
    delay(10);
  }
}


void draw() {
  if(buffer.length > 0) {
    image(buffer[buffer.length-1], 0, 0);
    buffer = (PGraphics[]) shorten(buffer);
    thread_index = (thread_index+1)%thread_count;
    thread("selection");
    println(count, "-", calculateScore(new_img, img));
  }
  
  
  for(int i=0; i < thread_count; i++) {
    noStroke();
    fill(255);
    rect(width-5, 5+20*i, bar_size, 15, 5);
    fill(#117EF0);
    rect(width-6, 5+20*i+1, bar_size*percentages[i]/100+2, 13, 5);
  }
}



void selection() {
  int _thread_index = int(thread_index);
  Shape[] shapes = new Shape[shape_count];
  
  for(int gen=0; gen < gen_count; gen++){
    Shape[] bestShapes = {};
    
    for(int s=0; s < shape_count; s++) {
      if(gen == 0) shapes[s] = randomShape();
      float score = shapes[s].loadScore();
      Shape shape = shapes[s];
      
      if(bestShapes.length == 0)  bestShapes = (Shape[]) append(bestShapes, shape);
      else {
        for(int j=0; j <= bestShapes.length; j++) {
          if(j == bestShapes.length) {
            bestShapes = (Shape[]) append(bestShapes, shape);
            break;
          }
          else if(score > bestShapes[j].score) {
            bestShapes = (Shape[]) splice(bestShapes, shape, j);
            break;
          }
        }
      }
    }
    
    if(gen == gen_count-1) {
      shapes = bestShapes;
      percentages[_thread_index] = 0;
      break;
    }
    
    Shape[] survivors = (Shape[]) subset(bestShapes, 0, survivor_count);
    Shape[] children = new Shape[0];
    for(Shape shape: survivors) {
      for(int child=0; child < child_count; child++) {
        children = (Shape[]) append(children, createChild(shape));
      }
    }
    shapes = (Shape[]) concat(survivors, children);
    
    percentages[_thread_index] += 100/gen_count;
  }
  
  last_score = shapes[0].score;
  
  new_img.beginDraw();
  new_img.image(shapes[0].pg(), 0, 0);
  new_img.endDraw();
  
  buffer = (PGraphics[]) append(buffer, new_img);
  count++;
}


Shape createChild(Shape shape) {
  float x = randomVar(shape.x, position_variation, 0, img.width);
  float y = randomVar(shape.y, position_variation, 0, img.height);
  float sizeX = randomVar(shape.sizeX, size_variation, min_size, max_size);
  float sizeY = randomVar(shape.sizeY, size_variation, min_size, max_size);
  float rotation = randomVar(shape.rotation, rotation_variation, -180, 180);
  float alpha = randomVar(alpha(shape.c), alpha_variation, 0, 255);
  return new Shape(x, y, sizeX, sizeY, rotation, alpha);
}


float randomVar(float original, float range, float min, float max) {
  return constrain(original + random(-range, range+1), min, max);
}
