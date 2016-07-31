import de.voidplus.leapmotion.*; //<>//
import java.awt.Frame;
import ddf.minim.analysis.*;
import ddf.minim.*;
import java.util.*; 
//import processing.sound.*;

AudioInput song; // >>>>>> use whatever is playing on computer
//AudioPlayer            song;
Minim                  minim;
ddf.minim.analysis.FFT fft;
BeatDetect             beat;
LeapMotion             leap;
Soundscape             soundscape;

float   yScaleDefault = 5;
float   yScaleHand = 15;
float   yScale;

int     xScale;
float   removalThreshold;
float   yIncrement = 0;
float   zMuffle = 20; // factor to shrink the z scale by
PVector hCoordinates = new PVector(1, 1, 1); // default for absent LeapMotion

// camera configurations for default mode
float xRotateDefault;
float yRotateDefault;
float zRotateDefault;

// when user hand is in play
float xRotateHand;
float yRotateHand;
float zRotateHand;

float xRotate;
float yRotate;
float zRotate;

// translation config for default mode
float xTranslateDefault;
float yTranslateDefault;
float zTranslateDefault;

// when user hand is in play
float xTranslateHand;
float yTranslateHand;
float zTranslateHand;

float xTranslate;
float yTranslate;
float zTranslate;

float translateChangeScale = 3;
float rotateChangeScale = 0.6;

void setup() {
  fullScreen(P3D);  // to do: make it look nicer on full screen
  //size(1200, 675, P3D); 
  background(0);
  
  minim = new Minim(this);
  // when using computer audio input
  song = minim.getLineIn();
  
  // // when using pre-loaded songs
  //song = minim.loadFile("gone_too_soon.mp3", 1024);
  //song.play();
  
  fft = new FFT( song.bufferSize(), song.sampleRate());
  // first param indicates minimum bandwidth
  // second dictates how many bands to split it into
  fft.logAverages( 20, 7 );
  
  xScale = int((width / 3 ) / fft.avgSize());
  yScale = yScaleDefault;
  
  xRotateDefault = 60;
  yRotateDefault = -5;
  zRotateDefault = 35;

  xRotateHand = 88;
  yRotateHand = 0;
  zRotateHand = 180;

  // TODO: 
  // for a 3.5 x grid. will want to try to adapt for x conversion from 3.5 to 4 with camera change for a greater effect...
  // this will involve using an "if" in the loop and multiplying across the x axis
  //xTranslateDefault = width / 2 + (width * 0.05); 
  //yTranslateDefault = (height / 2) - (height * 0.30);

  zTranslateDefault = 0;
  xTranslateHand = ((width - xScale * fft.avgSize()) / 2) * 2; 
  yTranslateHand = height * 0.60;
  
  float screen = (float)width / height;
  float aspectRatio = 16.00 / 9.00;
  
  if (Math.abs(screen - aspectRatio) == 0) {   
    // optimal configurations for a 16:9 aspect ratio
    xTranslateDefault = width / 2 - (width * 0.01);
    yTranslateDefault = (height / 2) - (height * 0.28);
    zTranslateHand    = 530;
  } else {
    // macbook pro, 16:10
    //zTranslateHand = 780;
    xTranslateDefault = width / 2 - (width * 0.01);
    yTranslateDefault = (height / 2) - (height * 0.25);
    zTranslateHand    = 700;
  }
  
  xRotate = xRotateDefault;
  yRotate = yRotateDefault;
  zRotate = zRotateDefault;
  
  xTranslate = xTranslateDefault;
  yTranslate = yTranslateDefault;
  zTranslate = zTranslateDefault;
  
  // point to start clearing back of fftFrames 
  // to create the illusion movement within landscape "slice"
  removalThreshold = height - (height * 0.45);

  leap = new LeapMotion(this);
  soundscape = new Soundscape();
}

void draw() {
 
  //float handHeight = map(hCoordinates.y, -1000, 1000, 0.00001, 4);
 
  float handHeight = 1;
  background(0);
  noStroke();
  strokeWeight(1);

  fill(0, 100);
  rect(0, 0, width, height);

  // perform a forward FFT on the samples in jingle's mix buffer,
  // which contains the mix of both the left and right channels of the file
  fft.forward(song.mix);
  soundscape.addFrame();

  // start shifting items backwards once y reaches the removal threshold
  if (soundscape.lastFrame.get(soundscape.lastFrame.size() - 1).y >= removalThreshold) {
    soundscape.soundscapeFrames.remove(0);
    soundscape.shiftBackward();
    yIncrement -= yScale; // halt the y-axis in place
  }
  
  soundscape.render(handHeight);
  soundscape.drawStartLine();
  
  soundscape.lastFrame.clear();
  yIncrement += yScale;
  
}

class Soundscape {

  ArrayList<ArrayList<PVector>> soundscapeFrames = new ArrayList<ArrayList<PVector>>(); 
  ArrayList<PVector> lastFrame = new ArrayList<PVector>(); 
  boolean shiftForward = false;

  void render(float handHeight) {

    strokeWeight(1);
    stroke(255, 50);
    
    renderCamera();
    
    // if all variables are equal to hand settings, this means the leapmotion is in play,
    // and full transition on all camera angles are complete
    if (
        (xRotate == xRotateHand) && (yRotate == yRotateHand) && (zRotate == zRotateHand)
         && (xTranslate == xTranslateHand) && (yTranslate == yTranslateHand) 
         && (zTranslate == zTranslateHand)
      ) {
      Hand hand = leap.getHands().get(0);
      PVector handPosition = hand.getPosition();
      println(handPosition);
    }

    int soundscapeFramesIndex = 0;
    for (ArrayList<PVector> fftFrame : soundscapeFrames) {
      if (soundscapeFramesIndex >= soundscapeFrames.size() - 1) {
        continue;
      }
      int fftFrameIndex = 0;
      beginShape(TRIANGLE_STRIP);
      for (PVector fftVector : fftFrame) {
        if (fftFrameIndex >= fftFrame.size() - 1) {
          continue;
        }
        vertex(fftVector.x, fftVector.y, fftVector.z * handHeight);
        vertex(
          soundscapeFrames.get(soundscapeFramesIndex + 1).get(fftFrameIndex + 1).x, 
          soundscapeFrames.get(soundscapeFramesIndex + 1).get(fftFrameIndex + 1).y, 
          soundscapeFrames.get(soundscapeFramesIndex + 1).get(fftFrameIndex + 1).z * handHeight
        );
        fftFrameIndex++;
      }
      endShape();
      soundscapeFramesIndex++;
    }
  }
  
  void renderCamera() {
     translate(
      xTranslate,
      yTranslate,
      zTranslate
    );

    rotateX(radians(xRotate));
    rotateY(radians(yRotate));
    rotateZ(radians(zRotate));
    
    //translate(
    //  xTranslateHand,
    //  yTranslateHand,
    //  zTranslateHand
    //);
    
    //rotateX(radians(xRotateHand));
    //rotateY(radians(yRotateHand));
    //rotateZ(radians(zRotateHand));

    if (leap.getHands().size() > 0) {
      
      if (xRotate < xRotateHand) {
        xRotate += rotateChangeScale;
      }
      
      if (yRotate < yRotateHand) {
        yRotate += rotateChangeScale;
      }
      
      if (zRotate < zRotateHand) {
        zRotate += rotateChangeScale;
      }
      
      if (xTranslate < xTranslateHand) {
        xTranslate += translateChangeScale;
        xTranslate = constrain(xTranslate, 0, xTranslateHand);
      }
      
      if (yTranslate < yTranslateHand) {
        yTranslate += translateChangeScale;
        yTranslate = constrain(yTranslate, 0, yTranslateHand);
      }
      
      if (zTranslate < zTranslateHand) {
        zTranslate += translateChangeScale;
        zTranslate = constrain(zTranslate, 0, zTranslateHand);
      }
      
      if (yScale < yScaleHand) {
        yScale += 0.5;
      }
       
    } else {
     
      if (xRotate > xRotateDefault) {
        xRotate -= rotateChangeScale;
      }
      
      if (yRotate > yRotateDefault) {
        yRotate -= rotateChangeScale;
      }
      
      if (zRotate > zRotateDefault) {
        zRotate -= rotateChangeScale;
      }
      
      if (xTranslate > xTranslateDefault) {
        xTranslate -= translateChangeScale;
        xTranslate = constrain(xTranslate, xTranslateDefault, 100000);
      }

      if (yTranslate > yTranslateDefault) {
        yTranslate -= translateChangeScale;
        yTranslate = constrain(yTranslate, yTranslateDefault, 100000);
      }
      
      if (zTranslate > zTranslateDefault) {
        zTranslate -= translateChangeScale;
        zTranslate = constrain(zTranslate, zTranslateDefault, 100000);
      }
      
      if (yScale > yScaleDefault) {
        yScale -= 0.5;
        yScale = constrain(yScale, yScaleDefault, 100);
      }
    }
  }

  void shiftBackward() {
    for (ArrayList<PVector> fftFrame : soundscapeFrames) {
      for (PVector fftVector : fftFrame) {
        fftVector.y -= yScale;
      }
    }
  }
 
  void addFrame() {
    ArrayList<PVector> fftFrame = new ArrayList<PVector>();
    for (int i = 0; i < fft.avgSize(); i++) {
      PVector vector = new PVector(
          i * xScale, 
          yIncrement + yScale, 
          // multiply by i to somewhat undo the logarithmic curve
          fft.getAvg(i) * i / zMuffle
        );
      fftFrame.add(vector);
      lastFrame.add(vector);
    }
    soundscapeFrames.add(fftFrame);
  }

  void drawStartLine() {
    for (int i = 0; i < lastFrame.size() - 1; i++) {
      strokeWeight(3);
      stroke(0, 255, 255);
      line(
        lastFrame.get(i).x, 
        lastFrame.get(i).y, 
        lastFrame.get(i).z, 
        lastFrame.get(i + 1).x, 
        lastFrame.get(i + 1).y, 
        lastFrame.get(i + 1).z
      );
    }
  }
}