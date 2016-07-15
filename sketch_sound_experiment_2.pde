// open sound control  //<>//
// OSC p5.
// maxmsp
// http://chuck.cs.princeton.edu/


import de.voidplus.leapmotion.*;
import org.apache.commons.lang3.*;
import org.apache.commons.lang3.builder.*;
import org.apache.commons.lang3.concurrent.*;
import org.apache.commons.lang3.event.*;
import org.apache.commons.lang3.exception.*;
import org.apache.commons.lang3.math.*;
import org.apache.commons.lang3.mutable.*;
import org.apache.commons.lang3.reflect.*;
import org.apache.commons.lang3.text.*;
import org.apache.commons.lang3.text.translate.*;
import org.apache.commons.lang3.time.*;
import org.apache.commons.lang3.tuple.*;

//import processing.sound.*;
import ddf.minim.analysis.*;
import ddf.minim.*;


Minim       minim;
AudioPlayer song;
ddf.minim.analysis.FFT fft;
BeatDetect beat;

import java.util.*; 

LeapMotion leap;
int spectrumScale;
int startHeight;
float yScale = 2;
int xScale;
float clearThreshold;
float yIncrement = 0;
float zMuffle = 15;

Soundscape soundscape;

void setup() {
  //size(1000, 800, P3D);
  fullScreen(P3D, 2);
  background(0);
  
  minim = new Minim(this);

  // specify that we want the audio buffers of the AudioPlayer
  // to be 1024 samples long because our FFT needs to have 
  // a power-of-two buffer size and this is a good size.
  song = minim.loadFile("flashy_flashy.mp3", 1024);
  // loop the file indefinitely
  song.play(); //<>//
  beat = new BeatDetect(); //<>//
  
  fft = new FFT( song.bufferSize(), song.sampleRate());
  //fft.linAverages( 100 );

  // calculate log averages
  // first param indicates minimum bandwidth
  // second param dictates how many bands to split it into
  fft.logAverages( 10, 5 );
  xScale = int((width / 4 ) / fft.avgSize());

  soundscape = new Soundscape();
  
  // the threshold at which to start clearing the front of the FFT array to make the things in back "disapear"
  clearThreshold = height - (height * 0.55);
  
  
  leap = new LeapMotion(this);

}

void draw() {
  background(0);
  noStroke();
  strokeWeight(1);
  
  fill(0, 100);
  rect(0, 0, width, height);
  
  // perform a forward FFT on the samples in jingle's mix buffer,
  // which contains the mix of both the left and right channels of the file
  fft.forward( song.mix );
  //amp = new Amplitude(this);
  soundscape.addFrame();
  
  if (soundscape.lastFrame.get(soundscape.lastFrame.size() - 1).y >= clearThreshold) {
    yIncrement -= yScale;
    soundscape.soundscapeVectors.remove(0);
    soundscape.shiftBackward();
  }
  
  soundscape.render();
  soundscape.drawStartLine();
  
  soundscape.lastFrame.clear();
  yIncrement += yScale;
  
}

class Soundscape {

  ArrayList<ArrayList<PVector>> soundscapeVectors = new ArrayList<ArrayList<PVector>>(); 
  ArrayList<PVector> lastFrame = new ArrayList<PVector>(); 
  boolean initialYShift = false;
  
  void render() {
    
    strokeWeight(1);
    stroke(255, 40);
    
    // center in the middle
    translate(width / 2, (height / 2) - (height * 0.15), 0);
    rotateX(PI/3);
    rotateY(radians(-5));
    rotateZ(radians(35));

    int soundscapeVectorsIndex = 0;
    for (ArrayList<PVector> fftFrame : soundscapeVectors) {
      if (soundscapeVectorsIndex >= soundscapeVectors.size() - 1) {
        continue;
      }
      int fftFrameIndex = 0;
      beginShape(TRIANGLE_STRIP);
      for (PVector fftVector : fftFrame) {
        if (fftFrameIndex >= fftFrame.size() - 1) {
          continue;
        }
        vertex(fftVector.x, fftVector.y, fftVector.z);
        vertex(soundscapeVectors.get(soundscapeVectorsIndex + 1).get(fftFrameIndex + 1).x, 
               soundscapeVectors.get(soundscapeVectorsIndex + 1).get(fftFrameIndex + 1).y,
               soundscapeVectors.get(soundscapeVectorsIndex + 1).get(fftFrameIndex + 1).z
        );
        fftFrameIndex++;
      }
      endShape();
      soundscapeVectorsIndex++;
    }
    
  }
  
  void shiftBackward() {

    // to sync up the next y-axis start, we must shift back just once
    //if (!initialYShift) {
    //   yIncrement -= yScale;
    //   initialYShift = true;
    //}
    
    for (ArrayList<PVector> fftFrame : soundscapeVectors) {
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
        // multiply by i to somewhat undo the logaritmic pattern, then muffle how big the peaks are
        fft.getAvg(i) * i / zMuffle 
      );
      fftFrame.add(vector);
      lastFrame.add(vector);
    }
    soundscapeVectors.add(fftFrame);
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