import netP5.*;
import oscP5.*;
OscP5 oscP5;
NetAddress receiver;
String remoteAdr="10.254.22.172"; //CLIENT IP
import processing.serial.*;

Serial port;
// SERIAL PORT STUFF TO HELP YOU FIND THE CORRECT SERIAL PORT
String serialPort;
String[] serialPorts = new String[Serial.list().length];
boolean serialPortFound = false;
Radio[] button = new Radio[Serial.list().length*2];
int numPorts = serialPorts.length;
boolean refreshPorts = false;

int Sensor;      // HOLDS PULSE SENSOR DATA FROM ARDUINO
int IBI;         // HOLDS TIME BETWEN HEARTBEATS FROM ARDUINO
int BPM;         // HOLDS HEART RATE VALUE FROM ARDUINO
int[] RawY;      // HOLDS HEARTBEAT WAVEFORM DATA BEFORE SCALING
int[] ScaledY;   // USED TO POSITION SCALED HEARTBEAT WAVEFORM
int[] rate;      // USED TO POSITION BPM DATA WAVEFORM

int heart = 0;   // This variable times the heart image 'pulse' on screen
boolean beat = false;    // set when a heart beat is detected, then cleared when the BPM graph is advanced
PFont font;
PImage heartpic;

void setup() {
  //fullScreen();
  size(960, 540);
  frameRate(100);
  
  oscP5=new OscP5(this, 12345);
  receiver=new NetAddress(remoteAdr, 12000);
  
  font = createFont("MS Sans Serif Bold",22);
  textFont(font);
  textAlign(CENTER);
  rectMode(CENTER);
  ellipseMode(CENTER);
  heartpic=loadImage("heart.png");
  int PulseWindowWidth = width;
  int BPMWindowWidth = width*2/5;

  RawY = new int[PulseWindowWidth];          // initialize raw pulse waveform array
  ScaledY = new int[PulseWindowWidth];       // initialize scaled pulse waveform array
  rate = new int [BPMWindowWidth];           // initialize BPM waveform array

  // set the visualizer lines to 0
  resetDataTraces();

  background(2,37,31);
  // DRAW OUT THE PULSE WINDOW AND BPM WINDOW RECTANGLES
  drawDataWindows();
  drawHeart();

  // GO FIND THE ARDUINO
  fill(27, 194, 78);
  text("Select Your Serial Port", 150, height*2/3+30);
  listAvailablePorts();
}

void draw() {
  if (serialPortFound) {
    // ONLY RUN THE VISUALIZER AFTER THE PORT IS CONNECTED
    background(4,25,22);
    noStroke();
    drawDataWindows();
    drawPulseWaveform();
    drawBPMwaveform();
    drawHeart();
    // PRINT THE DATA AND VARIABLE VALUES
    //fill(255);
    //text(Sensor, width/2, height/2);
    fill(27, 194, 78,180);
    textSize(30);
    text("IBI " + IBI + "mS", width*2/7-20, height*24/25);                    // print the time between heartbeats in mS
    text(BPM + " BPM", width*11/14, height*24/25);     // print the Beats Per Minute
    if (BPM>0) {
      OscMessage msg=new OscMessage("/bpm");  
      //print(msg.add(str(BPM)));
      msg.add(BPM);
      try {
        oscP5.send(msg, receiver);
      } 
      catch(Exception e) {
        println("sending failed: " + e.getMessage());
      }
    }
  } else { // SCAN BUTTONS TO FIND THE SERIAL PORT

    autoScanPorts();

    if (refreshPorts) {
      refreshPorts = false;
      drawDataWindows();
      drawHeart();
      listAvailablePorts();
    }

    for (int i=0; i<numPorts+1; i++) {
      button[i].overRadio(mouseX, mouseY);
      button[i].displayRadio();
    }
  }
}  //end of draw loop


void drawDataWindows() {
  noFill();
  stroke(255, 50);
  for (int i=0; i<width; i+=60) {
    line(i, 30, i, height/3+240);
  }
  for (int j=30; j<=height/3+240; j+=60) {
    line(0, j, width, j);
  }
  stroke(2,37,31);
  strokeWeight(3);
  line(int(width/(2*60))*60+60,30,int(width/(2*60))*60+60,height/3+240);
  line(0,30+60*4,width,30+60*4);
  for(int m=30;m<height/3+240;m+=15){
    stroke(1,92,61, 125);
    strokeWeight(5);
    line(int(width/(2*60))*60+60-3,m,int(width/(2*60))*60+60+3,m);
  }
  for(int n=0;n<width;n+=15){
    stroke(1,92,61, 125);
    strokeWeight(5);
    line(n,30+60*4-3,n,30+60*4+3);
  }
  stroke(1,92,61, 125);
  strokeWeight(5);
  line(0,30,width,30);
  line(0,height/3+240,width,height/3+240);

}

void drawPulseWaveform() {
  // DRAW THE PULSE WAVEFORM
  // prepare pulse data points
  RawY[RawY.length-1] = (1023 - Sensor) - 212;   // place the new raw datapoint at the end of the array
  //RawY[RawY.length-1] =1023-Sensor;
  for (int i = 0; i < RawY.length-1; i++) {      // move the pulse waveform by
    RawY[i] = RawY[i+1];                         // shifting all raw datapoints one pixel left
    float dummy = RawY[i] * 0.5 + 150;    // adjust the raw data to the selected scale
    ScaledY[i] = constrain(int(dummy), height/6, height/2);   // transfer the raw data array to the scaled array
  }
  pushMatrix();
  stroke(27, 194, 78); 
  strokeWeight(3);
  noFill();
  beginShape();                               
  for (int x = 1; x < ScaledY.length-1; x++) {
    smooth();
    vertex(x+10, ScaledY[x]);                    //draw a line connecting the data points
  }
  endShape();
  popMatrix();
}

void drawBPMwaveform() {
  // DRAW THE BPM WAVE FORM
  // first, shift the BPM waveform over to fit then next data point only when a beat is found
  if (beat == true) {   // move the heart rate line over one pixel every time the heart beats
    beat = false;      // clear beat flag (beat flag waset in serialEvent tab)
    for (int i=0; i<rate.length-1; i++) {
      rate[i] = rate[i+1];                  // shift the bpm Y coordinates over one pixel to the left
    }
    // then limit and scale the BPM value
    BPM = min(BPM, 200);                     // limit the highest BPM value to 200
    //float dummy = map(BPM, 0, 200, 555, 215);   // map it to the heart rate window Y
    float dummy = map(BPM, 0, 200, height*6/7, height*4/5);
    rate[rate.length-1] = int(dummy);       // set the rightmost pixel to the new data point value
  }
  // GRAPH THE HEART RATE WAVEFORM
  pushMatrix();
  translate(0,30);
  stroke(27, 194, 78);                          // color of heart rate graph
  strokeWeight(2);                          // thicker line is easier to read
  noFill();
  beginShape();
  for (int i=60; i < rate.length-1; i++) {    // variable 'i' will take the place of pixel x position
    smooth();
    vertex(i+10, rate[i]);                 // display history of heart rate datapoints
  }
  endShape();
  popMatrix();
}

void drawHeart() {
  // DRAW THE HEART AND MAYBE MAKE IT BEAT
  fill(250, 0, 0);
  stroke(250, 0, 0);
  // the 'heart' variable is set in serialEvent when arduino sees a beat happen
  heart--;                    // heart is used to time how long the heart graphic swells when your heart beats
  heart = max(heart, 0);       // don't let the heart variable go into negative numbers
  if (heart > 0) {             // if a beat happened recently,
    imageMode(CENTER);
    image(heartpic, width*4/5-20, height*4/5, 120, 120);
    //strokeWeight(8);          // make the heart big
  } else {
    imageMode(CENTER);
    image(heartpic, width*4/5-20, height*4/5, 96, 96);
  }
}

void listAvailablePorts() {
  println(Serial.list());    // print a list of available serial ports to the console
  serialPorts = Serial.list();
  fill(27, 194, 78);
  textFont(font, 16);
  textAlign(LEFT);
  // set a counter to list the ports backwards
  for (int i=serialPorts.length-1; i>=0; i--) {
    button[i] = new Radio(width/30, height*3/4+20*i, 12, color(180), color(80), color(255), i, button);
    text(serialPorts[i], width/30+10, height*3/4+20*i+6);
  }
  int p = numPorts;
  fill(233, 0, 0);
  button[p] = new Radio(width/30, height*3/4+20*6, 12, color(180), color(80), color(255), p, button);
  text("Refresh Serial Ports List", width/30+10, height*3/4+20*6+6);
  textFont(font);
  textAlign(CENTER);
}

void autoScanPorts() {
  if (Serial.list().length != numPorts) {
    if (Serial.list().length > numPorts) {
      println("New Ports Opened!");
      int diff = Serial.list().length - numPorts;	// was serialPorts.length
      serialPorts = expand(serialPorts, diff);
      numPorts = Serial.list().length;
    } else if (Serial.list().length < numPorts) {
      println("Some Ports Closed!");
      numPorts = Serial.list().length;
    }
    refreshPorts = true;
    return;
  }
}

void resetDataTraces() {
  for (int i=0; i<rate.length; i++) {
    rate[i] = 555;      // Place BPM graph line at bottom of BPM Window
  }
  for (int i=0; i<RawY.length; i++) {
    RawY[i] = height/2; // initialize the pulse window data line to V/2
  }
}