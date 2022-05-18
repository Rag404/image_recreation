// Natural selection config
final int max_shape_count = 100;
final int gen_count = 5;
final int max_survivor_count = 20;
final int max_children_count = 5;
final int min_score = 0;
final boolean do_limit_children_count = false;
final boolean do_limit_score = true;

// Genetic config
final int min_size = 5;
final int max_size = 300;
final int position_variation = 35;
final int size_variation = 20;
final int rotation_variation = 10;
final int alpha_variation = 30;
final boolean do_rotate = true;

// Image config
final String recreated_image = "wallpaper3_resized.jpg";
final int resize_x = 1080;
final int resize_y = 720;
final boolean do_resize = false;
final boolean do_keep_ration = true;


// Image stuff
PImage img;
PGraphics new_img;
float last_score = 0;

// Thread stuff
float percentage = 0;
int count = 0;
boolean thread_finished = false;


void settings() {
  // Idk if P2D renderer is faster lmao
  size(1440, 451, P2D);
}


void setup() {
  img = loadImage(recreated_image);
  
  // Resize the image and keep the ratio if specified in config
  int ratio_y = resize_y;
  if(do_keep_ration) ratio_y = img.height * img.width/resize_x;
  if(do_resize) img.resize(resize_x, ratio_y);
  
  // Load the recreated image pixels (for later in the code) and print the image on the screen
  img.loadPixels();
  image(img, width/2, 0);
  
  // Create the field where the reproduction will be
  new_img = createGraphics(img.width, img.height);
  new_img.beginDraw();
  new_img.background(0);
  new_img.endDraw();
  
  // Start a selection
  thread("selection");
}


void draw() {
  // If thread finished display the reproduction with the new shape and start a new selection
  if(thread_finished) {
    thread_finished = false;
    image(new_img, 0, 0);
    thread("selection");
    println(count, "-", calculateScore(new_img, img));
  }
  
  // Display the percentage bar
  noStroke();
  fill(255);
  rect(width-5, 5, -200, 15, 5);
  fill(#117EF0);
  rect(width-6, 6, -200*percentage/100+2, 13, 5);
}



void selection() {
  // Create a bunch of shapes (number specified in config)
  Shape[] shapes = new Shape[max_shape_count];
  
  for(int gen=0; gen < gen_count; gen++){
    // Initialize values used in this generation
    int shape_count = shapes.length;
    Shape[] best_shapes = {};
    
    for(int s=0; s < shape_count; s++) {
      if(gen == 0) shapes[s] = randomShape();  // If it is the first generation generate a random shape
      Shape shape = shapes[s];  // Create a value to improve code readability
      float score = shape.loadScore();  // Get the score of the shape
      
      
      if(best_shapes.length == 0)  best_shapes = (Shape[]) append(best_shapes, shape);  // If it is the first shape being sorted, just add it at the start of the scoreboard
      else {
        // Search for the place to put the shape inside the scoreboard
        for(int j=0; j <= best_shapes.length; j++) {
          if(j == best_shapes.length) {
            // If it is the end of the scoreboard, just add the shape at the end of it
            best_shapes = (Shape[]) append(best_shapes, shape);
            break;
          }
          else if(score < min_score) break;  // If the score is bellow limit, skip the shape
          else if(score > best_shapes[j].score) {
            // If the score is better than the current one checked in the scoreboard place the shape at this location in the scoreboard and end the loop
            best_shapes = (Shape[]) splice(best_shapes, shape, j);
            break;
          }
        }
      }
    }
    
    
    // If no shapes have passed the sorting, skip everything to start a whole new selection
    if(best_shapes.length == 0) {
      percentage = 0;
      thread_finished = true;
      return;
    }
    
    // If it is the last generation, no need to select survivors and make childs
    if(gen == gen_count-1) {
      shapes = best_shapes;
      percentage = 0;
      thread_finished = true;
      break;
    }
    
    
    // Select the survivors and initialize the children list
    Shape[] survivors = (Shape[]) subset(best_shapes, 0, constrain(max_survivor_count, 0, best_shapes.length));
    Shape[] children = new Shape[0];
    
    // Calculate the number of children and limit it if specified in the config
    int children_count = (shape_count - survivors.length) / survivors.length;
    if(do_limit_children_count) children_count = constrain(children_count, 0, max_children_count);
    
    // For each survivor create its children
    for(Shape shape: survivors) {
      for(int child=0; child < children_count; child++) {
        children = (Shape[]) append(children, createChild(shape));
      }
    }
    
    // The new list of shapes is the survivors and children
    shapes = (Shape[]) concat(survivors, children);
    
    // Update the percentage bar
    percentage += 100/gen_count;
  }
  
  // The new last score is now the current best score
  last_score = shapes[0].score;
  
  // Update the reproduction
  new_img.beginDraw();
  new_img.image(shapes[0].pg(), 0, 0);
  new_img.endDraw();
  
  // Increase the total shape count on the reproduction
  count++;
}


Shape createChild(Shape shape) {
  // Generate random values in the ranges specified in the config and generate a new shape
  float x = randomVar(shape.x, position_variation, 0, img.width);
  float y = randomVar(shape.y, position_variation, 0, img.height);
  float sizeX = randomVar(shape.sizeX, size_variation, min_size, max_size);
  float sizeY = randomVar(shape.sizeY, size_variation, min_size, max_size);
  float rotation = randomVar(shape.rotation, rotation_variation, -180, 180);
  float alpha = randomVar(alpha(shape.c), alpha_variation, 0, 255);
  return new Shape(x, y, sizeX, sizeY, rotation, alpha);
}


float randomVar(float original, float range, float min, float max) {
  // Return a random variation of the original with in the range, min and max specified
  return constrain(original + random(-range, range+1), min, max);
}
