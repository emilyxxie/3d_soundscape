import de.voidplus.leapmotion.*; //<>//
import java.awt.Frame;
import ddf.minim.analysis.*;
import ddf.minim.*;
import java.util.*; 
//import processing.sound.*;

//AudioInput song; // >>>>>> use whatever is playing on computer
AudioPlayer            song;
Minim                  minim;
ddf.minim.analysis.FFT fft;
BeatDetect             beat;
LeapMotion             leap;
Soundscape             soundscape;

int     startHeight;
float   yScale = 2.5;
int     xScale;
float   removalThreshold;
float   yIncrement = 0;
float   zMuffle = 15; // how much to mute the z scale by
PVector hCoordinates = new PVector(1, 1, 1); // default for absent LeapMotion

void setup() {
  fullScreen(P3D, 2);
  background(0);
  
  //song = minim.getLineIn();  // >>>>>>>> when using computer audio input
  minim = new Minim(this);
  song = minim.loadFile("flashy_flashy.mp3", 1024);
  song.play();
  
  fft = new FFT( song.bufferSize(), song.sampleRate());
  
  // calculate log averages
  // first param indicates minimum bandwidth
  // second param dictates how many bands to split it into
  fft.logAverages( 10, 5 );
  xScale = int((width / 3.5 ) / fft.avgSize());

  //leap = new LeapMotion(this);
  soundscape = new Soundscape();
  // point to start clearing back of fftFrames to create the illusion of movement
  removalThreshold = height - (height * 0.45);
}

void draw() {
  //for(Hand hand : leap.getHands()){
  //  hCoordinates = hand.getPosition();//-1*hand.getPitch();     
  //}
 
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
    stroke(255, 40);

    // center in the middle-ish for 16:9 aspect ratio
    translate(width / 2 - (width * 0.02), (height / 2) - (height * 0.25), 0);
    // slightly better translate option for Macs
    //translate(width / 2 + (width * 0.05), height / 2 - (height * 0.20));
    
    rotateX(PI/3);
    rotateY(radians(-5));
    rotateZ(radians(35));

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
          yIncrement * yScale, 
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