import org.apache.commons.lang3.*; //<>//
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
//Amplitude   amp;
BeatDetect beat;

import java.util.*; 

int spectrumScale;
int startHeight;

Soundscape soundscape;

void setup()
{
  size(1000, 1000, P3D);
  background(0);
  spectrumScale = 3;
  
  minim = new Minim(this);

  // specify that we want the audio buffers of the AudioPlayer
  // to be 1024 samples long because our FFT needs to have 
  // a power-of-two buffer size and this is a good size.
  song = minim.loadFile("flashy_flashy.mp3", 1024);
  // loop the file indefinitely
  song.play();
  beat = new BeatDetect();
  
  fft = new FFT( song.bufferSize(), song.sampleRate());
  //fft.linAverages( 100 );

  // calculate log averages
  // first param indicates minimum bandwidth
  // second param dictates how many bands to split it into
  //fft.logAverages( 100, 10 );
  fft.logAverages( 10, 5 );

  soundscape = new Soundscape();

}

void draw() {
  background(0);
  noStroke();
  strokeWeight(1);
  
  fill(0, 100);

  
  rect(0, 0, width, height);
  
  // perform a forward FFT on the samples in jingle's mix buffer,
  // which contains the mix of both the left and right channels of the file
  fft.forward( song.left );
  //amp = new Amplitude(this);

  soundscape.addFrame();
  soundscape.render();
  //soundscape.drawStartLine();
  
  //if (frameCount < 10) {
  //println(soundscape.soundscapeVectors.toString());
  //}
}

class Soundscape {

  //public Soundscape() {
  //}

  ArrayList<ArrayList<PVector>> soundscapeVectors = new ArrayList<ArrayList<PVector>>(); 
  ArrayList<PVector> lastFrame = new ArrayList<PVector>(); 
  
  //interval per frequency band when averaged
  int interval = int((width / 2 ) / fft.avgSize());  
  
  void render() {
    
    strokeWeight(1);
    stroke(255);
    
     //translate(width/2, height/2+50);
      //rotateX(PI/3);
      //translate(width/2, height/2);
      
      // center in the middle
    translate(width / 2 - 100, height / 2 - 200, 0);
        
    rotateX(PI/2.5);
  //translate(-width/2, -height/12);
    
    //if (frameCount < 6) {
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
  
  
  void addFrame() {
    ArrayList<PVector> fftFrame = new ArrayList<PVector>();
    for (int i = 0; i < fft.avgSize(); i++) {
      PVector vector = new PVector(
        i * 4,
        frameCount * 4,
        fft.getAvg(i) * i / 10
      );
      fftFrame.add(vector);
      lastFrame.add(vector);
    }
    soundscapeVectors.add(fftFrame);
  }
  
  // this might have to take the value of every last item.
  void drawStartLine() {
     for (int i = 0; i < lastFrame.size() - 1; i++) {
       strokeWeight(5);
       stroke(0, 255, 255);
       line(
         lastFrame.get(i).x,
         lastFrame.get(i).y,
         lastFrame.get(i).z,
         lastFrame.get(i + 1).x,
         lastFrame.get(i + 1).y,
         lastFrame.get(i + 1).y
       );
     }
  }
  
}