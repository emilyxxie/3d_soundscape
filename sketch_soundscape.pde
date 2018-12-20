// Caveat: this is pretty terrible code written far too quickly

import de.voidplus.leapmotion.*;
import java.awt.Frame;
import ddf.minim.analysis.*;
import ddf.minim.*;
import java.util.*;
import java.io.*;

import processing.sound.*;
AudioIn in; // attempt 2


AudioInput             song; // use whatever is playing on computer
//AudioPlayer            song; // use pre-loaded song
Minim                  minim;
ddf.minim.analysis.FFT fft;
BeatDetect             beat;
LeapMotion             leap;
Soundscape             soundscape;
AudioPlayer            song2;

float   yScaleDefault = 5;
float   yScaleHand = 12;
float   yScale;
float   yScaleChange = 0.3;

int     xScale;
float   removalThreshold;
float   yIncrement = 0;
float   zMuffle = 25;// 20; // factor to shrink the z scale by

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

float pitch = 0; // rotation around x-axis
float yaw = 0; // rotation around y-axis
float roll = 0; // rotation around z-axis

float translateChangeScale = 3;
float rotateChangeScale = 0.6;
float handChangeScale = 0.5;

float handPitch;
float handYaw;
float handRoll;
float handGrab;
float handMuffle;

float handPitchMultiplier = 0.5;
float handRollMultiplier = 0.2;
float handYawMultiplier = 0.5;

boolean volumeDefault = false;

// grab strength affects volume

void setup() {
  //fullScreen(P3D);  // to do: make it look nicer on full screen
  size(1280, 800, P3D);
  //size(1200, 675, P3D);
  background(0);
  noCursor();

  minim = new Minim(this);
  // when using computer audio input
  song = minim.getLineIn();

  // // when using pre-loaded songs
  //song2 = minim.loadFile("gone_too_soon.mp3", 1024);
  //song.play();


  fft = new ddf.minim.analysis.FFT( song.bufferSize(), song.sampleRate());
  // first param indicates minimum bandwidth
  // second dictates how many bands to split it into

  fft.logAverages( 25, 10);

  xScale = int((width / 3 ) / fft.avgSize());
  yScale = yScaleDefault;

  // point to start clearing back of fftFrames
  // to create the illusion movement within landscape "slice"
  removalThreshold = height - (height * 0.45);

  setCameraVariables();

  leap = new LeapMotion(this);
  soundscape = new Soundscape();
}

void setCameraVariables () {

  xRotateDefault = 60;
  yRotateDefault = -5;
  zRotateDefault = 35;

  xRotateHand = 88;
  yRotateHand = 0;
  zRotateHand = 180;

  // TODO:
  // for a 3.5 x grid. will want to try to adapt for x conversion from 3.5 to 4 with camera change for a greater effect...
  // this will involve using an "if" in the loop and multiplying across the x axis in the render function
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
    zTranslateHand    = 780;
    xTranslateDefault = width / 2 + (width * 0.02);
    yTranslateDefault = (height / 2) - (height * 0.25);
    zTranslateHand    = 700;
  }

  xRotate = xRotateDefault;
  yRotate = yRotateDefault;
  zRotate = zRotateDefault;

  xTranslate = xTranslateDefault;
  yTranslate = yTranslateDefault;
  zTranslate = zTranslateDefault;

}

void draw() {
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

   // if all variables are equal to hand settings, this means the leapmotion is in play,
   // and the full transition for all camera angles is complete
   if (
      (leap.getHands().size() > 0) && (xRotate == xRotateHand)
       && (yRotate == yRotateHand) && (zRotate == zRotateHand)
       && (xTranslate == xTranslateHand) && (yTranslate == yTranslateHand)
       && (zTranslate == zTranslateHand)
   ) {

      Hand hand = leap.getHands().get(0);
      handPitch = hand.getPitch();
      handYaw   = hand.getYaw();
      handRoll  = hand.getRoll();
      handGrab  = hand.getGrabStrength();

      // automatically change music back to full volume
      if (handGrab <= 0.10 && volumeDefault == false) {
        changeVolume(handGrab);
        volumeDefault = true;
      }

      // only allow changing sound every 10 frames to avoid overwhelming
      if (frameCount % 15 == 0 && handGrab > 0.10) {
        volumeDefault = false;
        changeVolume(handGrab);
      }
      handMuffle = map(handGrab, 0, 1, 1, 0.2);
  } else {
    handMuffle = 1;
  }

  soundscape.render();
  soundscape.drawStartLine();

  soundscape.lastFrame.clear();
  yIncrement += yScale;

}

class Soundscape {

  ArrayList<ArrayList<PVector>> soundscapeFrames = new ArrayList<ArrayList<PVector>>();
  ArrayList<PVector> lastFrame = new ArrayList<PVector>();
  boolean shiftForward = false;

  void render() {

    strokeWeight(1);
    stroke(255, 50);

    adjustCamera();

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
        // TODO: connect the first triangle too to straighten the edge
        vertex(fftVector.x, fftVector.y, fftVector.z);
        ArrayList<PVector> nextFrame = soundscapeFrames.get(soundscapeFramesIndex + 1);
        vertex(
          soundscapeFrames.get(soundscapeFramesIndex + 1).get(fftFrameIndex + 1).x,
          soundscapeFrames.get(soundscapeFramesIndex + 1).get(fftFrameIndex + 1).y,
          soundscapeFrames.get(soundscapeFramesIndex + 1).get(fftFrameIndex + 1).z
        );
        //print(soundscapeFrames);
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
      float zVal = 0;
      if (i <= 5 || i >= fft.avgSize() - 5 || soundscapeFrames.size() <= 6) {
        zVal = (fft.getAvg(i) * i / zMuffle) * handMuffle;
      } else {
        int prevFramesTracker = soundscapeFrames.size();

        // add some crazy-janky smoothing.
        zVal += 0.18 * soundscapeFrames.get(prevFramesTracker - 1).get(i).z;
        zVal += 0.10 * soundscapeFrames.get(prevFramesTracker - 2).get(i).z;
        zVal += 0.08 * soundscapeFrames.get(prevFramesTracker - 3).get(i).z;
        zVal += 0.06 * soundscapeFrames.get(prevFramesTracker - 4).get(i).z;
        zVal += 0.04 * soundscapeFrames.get(prevFramesTracker - 5).get(i).z;

        zVal += .26 * (fft.getAvg(i) * i / zMuffle);

        zVal += .08 * (fft.getAvg(i + 1) * i / zMuffle);
        zVal += .04 * (fft.getAvg(i - 1) * i / zMuffle);

        zVal += .04 * (fft.getAvg(i + 2) * i / zMuffle);
        zVal += .04 * (fft.getAvg(i - 2) * i / zMuffle);

        zVal += .02 * (fft.getAvg(i + 3) * i / zMuffle);
        zVal += .02 * (fft.getAvg(i - 3) * i / zMuffle);

        zVal += .01 * (fft.getAvg(i + 4) * i / zMuffle);
        zVal += .01 * (fft.getAvg(i - 4) * i / zMuffle);

        zVal += .01 * (fft.getAvg(i + 5) * i / zMuffle);
        zVal += .01 * (fft.getAvg(i - 5) * i / zMuffle);
      }
      PVector vector = new PVector(
          i * xScale,
          yIncrement + yScale,
          // 1) multiply by i to somewhat undo the logarithmic curve
          // 2) how you adjust via osx doesn't technically change volume of piped music through iShowYou
          // so, we have to "fake" the visual result by by shrinking the landscape according to the hand clench
          zVal * handMuffle
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

void adjustCamera() {
     translate(
      xTranslate,
      yTranslate,
      zTranslate
    );

    // TODO: constrain the roll so that it does not get into the negatives
    rotateX(radians(xRotate + (-handPitch * handPitchMultiplier)));
    rotateY(radians(yRotate + (handRoll * handRollMultiplier)));
    rotateZ(radians(zRotate + (handYaw * handYawMultiplier)));

    // TODO : Remove. This is for debugging
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
        xRotate = constrain(xRotate, 0, xRotateHand);
      }

      if (yRotate < yRotateHand) {
        yRotate += rotateChangeScale;
        yRotate = constrain(yRotate, 0, yRotateHand);
      }

      if (zRotate < zRotateHand) {
        zRotate += rotateChangeScale;
        zRotate = constrain(zRotate, 0, zRotateHand);
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
        yScale += yScaleChange;
      }

    } else {
      // gradually reset hand variables
      if (handPitch > 0 ) {
        handPitch -= handChangeScale;
        handPitch = constrain(handPitch, 0, 1000);
      } else {
        handPitch += handChangeScale;
        handPitch = constrain(handPitch, -1000, 0);
      }

      if (handYaw > 0 ) {
        handYaw -= handChangeScale;
        handYaw = constrain(handYaw, 0, 10000);
      } else {
        handYaw += handChangeScale;
        handYaw = constrain(handYaw, -1000, 0);
      }

      if (handRoll > 0 ) {
        handRoll -= handChangeScale;
        handRoll = constrain(handRoll, 0, 10000);
      } else {
        handRoll += handChangeScale;
        handRoll = constrain(handRoll, -1000, 0);
      }

      if (xRotate > xRotateDefault) {
        xRotate -= rotateChangeScale;
        xRotate = constrain(xRotate, xRotateDefault, 10000);
      }

      if (yRotate > yRotateDefault) {
        yRotate -= rotateChangeScale;
        yRotate = constrain(yRotate, yRotateDefault, 10000);
      }

      if (zRotate > zRotateDefault) {
        zRotate -= rotateChangeScale;
        zRotate = constrain(zRotate, zRotateDefault, 10000);
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
        yScale -= yScaleChange;
        yScale = constrain(yScale, yScaleDefault, 100);
      }
    }
  }

void changeVolume(float handGrab) {

  handGrab = map(handGrab, 0.20, 1, 10, 4);
  // can't manipulate volume from minim library
  // so exec-ing osascript instead
  // this will only work on mac
  // this is hacky---need to clean this up
  // seems like it needs to be a number from 1- 10 for osascript
  String volume = String.format("set volume %f", handGrab);
  String[] cmd = {"osascript", "-e", volume};
  File workingDir = new File("/Users/Emily/Code/Processing/examples/sketch_test");

  try {
    // command, null = inherit porcessing environment, where to execute command
    Process p = Runtime.getRuntime().exec(cmd, null, workingDir);
  } catch (Exception e) {
    println("Error running command!");
    println(e);
  }


}
