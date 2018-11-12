/**********************************************
 Deep Space mit durchgehendem Screen
 Wand:3030x1914
 Boden: 3030x1798 
 Gesamt: 3030x3712
 beides mit 30 Hz angesteuert. Vertikal erweiterter Desktop, Wand oberhalb vom Boden.
 DeepSpace 14,9x8,39m -> 202px/m  20px/dm  1px = 0,5cm
 **********************************************/

//*********** Bibliotheken
import TUIO.*;
TuioProcessing tuioClient;
import java.util.List;
import processing.sound.*;

SoundFile file; //for loading the file
Sound sound; //for controlling audio output

ArrayList<TuioCursor> tuioCursorList; //Cursor List

//*********** Auflösung des DeepSpace und Skalierungsfaktor
int dsWidth = 3030;
int dsHeightFloor = 1798;
int dsHeightWall = 1914;
int indent = (dsHeightWall - dsHeightFloor)/2;
float sf = 1.0; // Scalefactor


//************ globale Variable
XML xml;
float radius;
int deviceId;

//************ background image floor
PImage bgf; // background image

//************ background image wall
PImage bgw; // background image

//************ fingerprint 
PImage fp_original; // fingerprint image from reader (source)
PImage fp_filtered; // fingerprint image after filtering (destination)

//************ fp-canvas
PGraphics fp_canvas; // canvas containing the fp image

List<Integer> fp_path_pixels; // white pixels path

float fp_canvas_x0; //fingerprint canvas initial x
float fp_canvas_y0f; //fingerprint canvas initial y floor
float fp_canvas_y0w; //fingerprint canvas initial y wall


boolean isLastEnteredPixelBlack = false;

//************ "falg"-colors for painting on canvas
color red         = #FF0000; 
color blue        = #0000FF;  
color light_blue  = #99FFFF;  
color dark_blue   = #330066;  
color green       = #006600;  
color light_green = #00CC00;  
color gold        = #FFD700;  
color yellow      = #FFFF66;  
color orange      = #FF9900; 
color grey        = #CCCCCC;  
color purple      = #CC99FF; 
color murrey      = #660066;

color[] myColors  = {  
  red, blue, light_blue, dark_blue, green, light_green, gold, 
  yellow, orange, grey, purple, murrey
};

int rand = int(random(myColors.length));

//************ cursor image
//PImage cursorImg;

void setup() {
  //*********** DeepSpace Auflösung mit Scalefaktor 
  //size(3030, 3712);  // sf = 1.0
  //size(1515, 1856);  // sf = 0.5
  //size(757, 928);    // sf = 0.25
  fullScreen(P2D, SPAN);  // für den Deep Space !!!!! eventuell nur fullScreen(SPAN);
  
  //*********** Einlesen der Paramter aus XML-Datei
  xml = loadXML("testDeepSpace.xml");
  radius = xml.getFloat("radius");
  deviceId = xml.getInt("deviceId");
  
  file = new SoundFile(this, "river.mp3");
  sound = new Sound(this);  
  PrintWriter outputFile = createWriter("data/soundfile.txt");
  for(int i = 0 ; i < Sound.list().length; i++) {
    outputFile.println(i + " " + Sound.list()[i]);
  }
  
  outputFile.flush();
  outputFile.close();  
  
  //*********** TUIO initialisieren
  tuioClient = new TuioProcessing(this);
  
  //*********** path pixels
  fp_path_pixels = new ArrayList<Integer>(); // create a new list for collecting path pixels
  
  //*********** background wall
  bgw = loadImage("water.png");
  image(bgw, 0, 0, dsWidth*sf, dsHeightWall*sf);
  
  //*********** background floor
  bgf = loadImage("water.png");
  image(bgf, 0, dsHeightWall*sf, dsWidth*sf, dsHeightFloor*sf);
  
  //*********** fingerprint / canvas
  fp_original = loadImage("fingerprint.jpg");
  // scaling (you can only resize PImage, but not PGraphics (you would need to duplicate with get() and new. and then resize)!)
  fp_original.resize(int(dsWidth*sf/2), int(dsHeightFloor*sf));
  // I did not yet scaled it into the acurate size, but maybe you want to work on it
  // but I think it is better to do the scaling here, because functionality works fine!
  fp_filtered = createImage(fp_original.width, fp_original.height, ARGB);
  filterByBrightness(240); // from source to destination with filter threshold - here should go the "cleaning code"
          
  fp_canvas = createGraphics(fp_original.width, fp_original.height);

  fp_canvas_x0 = (dsWidth*sf - fp_canvas.width) / 2;
  fp_canvas_y0f = dsHeightWall*sf + ((dsHeightFloor*sf - fp_canvas.height) / 2);
  fp_canvas_y0w = (dsHeightWall*sf - fp_canvas.height) / 2;
  
  image(fp_canvas, fp_canvas_x0, fp_canvas_y0f);
  image(fp_canvas, fp_canvas_x0, fp_canvas_y0w);
  //************ cursor image
  //cursorImg = loadImage("cursor.png");
  //image(cursorImg, mouseX, mouseY, 120*sf, 120*sf);
  //imageMode(CENTER);
}

void draw() {
  tuioCursorList = tuioClient.getTuioCursorList();
  
  if(tuioCursorList.size() == 0) { // client not entered yet    
    fp_canvas.smooth(2);
    fp_canvas.beginDraw();
    fp_canvas.image(fp_filtered, 0, 0);
    fp_canvas.endDraw();
    
    image(fp_canvas, fp_canvas_x0, fp_canvas_y0f);
    image(fp_canvas, fp_canvas_x0, fp_canvas_y0w);
  
  } else {
    //*********** Cursor for 1 single person
    TuioCursor tc = tuioCursorList.get(0);    
    //*********** Calculate relative mouse position inside PGraphics instance and relative location
    float pg_x = tc.getScreenX(width) - fp_canvas_x0;
    float pg_yf = (dsHeightWall+tc.getScreenY(dsHeightFloor))*sf - fp_canvas_y0f;
    float pg_yw = (dsHeightWall+tc.getScreenY(dsHeightFloor))*sf - fp_canvas_y0w;

    fp_canvas.smooth(2);
    fp_canvas.beginDraw(); // begin - PGraphics
    fp_canvas.noStroke();
    fp_canvas.fill(0, 0, 0, 0); // change fill color to transparent
    fp_canvas.image(fp_filtered, 0, 0);
    
      if ((pg_x > 0 && pg_x <= fp_canvas.width) && pg_yf > 0 && pg_yf <= fp_canvas.height) {
        int loc = (int) (pg_x + pg_yf * fp_canvas.width);
     
        if (fp_path_pixels.contains(loc)) { // is current mouse location on white pixel ?
            if (isLastEnteredPixelBlack) {
              rand = int(random(myColors.length));
              println(rand);
            }
            // set default fill color
            fp_canvas.fill(myColors[rand]);
            isLastEnteredPixelBlack = false;
        } else {
            isLastEnteredPixelBlack = true;
        }
    }

    fp_canvas.ellipse(pg_x, pg_yf, 10, 10); // draw ellipse on current mouse position on the floor
    fp_canvas.ellipse(pg_x, pg_yw, 10, 10); // draw ellipse on current mouse position on the wall
    fp_canvas.endDraw(); // end - PGraphics
    image(fp_canvas, fp_canvas_x0, fp_canvas_y0f);
    image(fp_canvas, fp_canvas_x0, fp_canvas_y0w);
  }

   //************ Trennline zwischen Boden und Wand
  stroke(0,0,255);
  line(0, dsHeightWall*sf, width, dsHeightWall*sf);

  //************ Einrückungslinien zur Einschränkung auf die Bodenfläche
  stroke(255,0,0);
  line(0, indent*sf, dsWidth*sf, indent*sf);
  line(0, (dsHeightWall-indent)*sf, dsWidth*sf, (dsHeightWall-indent)*sf);
}

void keyPressed() {
  xml.setFloat("radius", map(mouseX, 0, width, 50, 500));
  saveXML(xml, "data/testDeepSpace.xml");
}

String pixelColor(int[] locations, float threshold) {
  int nr_White_pixels = 0;
  int nr_Black_pixels = 1;
  for (int i = 0; i < locations.length; i++) {
    if((brightness(fp_original.pixels[locations[i]])) > threshold) {
      nr_White_pixels ++;
    }
    else {
      nr_Black_pixels ++;
    }
  } 
  if(nr_White_pixels > nr_Black_pixels) {
    return "White";
  }
  else {
    return "Black";
  }  
}

void filterByBrightness(float threshold) {
   fp_original.loadPixels();
   fp_filtered.loadPixels();  

   for (int x = 1; x < fp_original.width - 1; x++) {
        for (int y = 1; y < fp_original.height - 1; y++) {
            int loc = x + y * fp_filtered.width;
            int leftLoc = (x - 1) + y * fp_filtered.width;
            int rightLoc = (x + 1) + y * fp_filtered.width;
            int upperLoc = x + (y + 1) * fp_filtered.width;
            int lowerLoc = x + (y - 1) * fp_filtered.width;
            String finalColor = pixelColor(new int[]{loc, leftLoc, rightLoc, upperLoc, lowerLoc}, threshold);            
 
            if (finalColor.equals("White")) {
                fp_filtered.pixels[loc] = color(0, 0, 0, 0);   // transparent
                fp_path_pixels.add(loc); // add pixel as path pixel to list
            } else {
                fp_filtered.pixels[loc] = color(0); // fp_original pixel black
            }
 
            //if (brightness(fp_original.pixels[loc]) > threshold) {
            //    fp_filtered.pixels[loc] = color(0, 0, 0, 0);   // transparent
            //    fp_path_pixels.add(loc); // add pixel as path pixel to list
            //} else {
            //    fp_filtered.pixels[loc] = color(0); // fp_original pixel black
            //}
        }
    }
    fp_filtered.updatePixels();
}
  
