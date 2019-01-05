import processing.serial.*;
import org.firmata.*;
import cc.arduino.*;
Arduino arduino;

import oscP5.*;
OscP5 oscP5;

import controlP5.*;
ControlP5 cp5;

int heartBpm=0;

int motorCount=3;
Knob[] bpm=new Knob[6];
Slider[] rpm=new Slider[3];
Motor[] motors=new Motor[motorCount];
float radps[] =new float[motorCount];
float ang[] =new float[motorCount];
float freq[]=new float[6];
int beatState[]=new int[6];
float offset;

float speed =0;
int fanState=0;
int minBpm=30;
int avgBpm=80;
int maxBpm=120;
int delayPin[]={22, 25, 26, 29, 30, 33};
int dimmerPin=7;
int count=0;
int adj=16;
void setup() {
  frameRate(30);
  size(600, 600);
  println(Arduino.list());
  arduino = new Arduino(this, "/dev/cu.usbmodem1421", 57600);
  for (int i=0; i<6; i++) {
    arduino.pinMode(delayPin[i], Arduino.OUTPUT);
    arduino.digitalWrite(delayPin[i], Arduino.LOW);
  }

  offset=width/motorCount;
  oscP5=new OscP5(this, 12000);
  cp5=new ControlP5(this);
  rpm[0]=cp5.addSlider("slider1")
    .setPosition(offset/4-10, 320)
    .setSize(20, 250)
    .setRange(0, 300)
    ;
  rpm[1]=cp5.addSlider("slider2")
    .setPosition(offset*6/5-10, 320)
    .setSize(20, 250)
    .setRange(0, 300)
    ;
  rpm[2]=cp5.addSlider("slider3")
    .setPosition(offset*43/20-10, 320)
    .setSize(20, 250)
    .setRange(0, 300)
    ;

  bpm[0]=cp5.addKnob("Metro1-R")
    .setRange(0, 1)
    .setValue(0)
    .setPosition(offset/4+40, 320)
    .setRadius(50)
    .setDragDirection(Knob.VERTICAL)
    ;
  bpm[1]=cp5.addKnob("Metro2-R")
    .setRange(0, 1)
    .setValue(0.5)
    .setPosition(offset*6/5+40, 320)
    .setRadius(50)
    .setDragDirection(Knob.VERTICAL)
    ;
  bpm[2]=cp5.addKnob("Metro3-R")
    .setRange(0, 1)
    .setValue(0)
    .setPosition(offset*43/20+40, 320)
    .setRadius(50)
    .setDragDirection(Knob.VERTICAL)
    ;
  bpm[3]=cp5.addKnob("Metro1-L")
    .setRange(0, 1)
    .setValue(0)
    .setPosition(offset/4+40, 450)
    .setRadius(50)
    .setDragDirection(Knob.VERTICAL)
    ;
  bpm[4]=cp5.addKnob("Metro2-L")
    .setRange(0, 1)
    .setValue(0)
    .setPosition(offset*6/5+40, 450)
    .setRadius(50)
    .setDragDirection(Knob.VERTICAL)
    ;
  bpm[5]=cp5.addKnob("Metro3-L")
    .setRange(0, 1)
    .setValue(0)
    .setPosition(offset*43/20+40, 450)
    .setRadius(50)
    .setDragDirection(Knob.VERTICAL)
    ;

  for (int i=0; i<motors.length; i++) {
    float posX=offset/2+i*offset;
    float posY=offset*0.3;
    motors[i]=new Motor(posX, posY);
    ang[i]=0;
  }
  noStroke();
  fill(0);
  rect(0, height/5, width, 0.3*height);
}

void draw() {
  drawWindows();
  drawAnimation();
  for (int i=0; i<6; i++) {
    if (abs(sin(frameCount*freq[i]))>0.5&&count==0) {
      arduino.digitalWrite(delayPin[i], Arduino.HIGH);
      delay(20);
      //beatState[i]=1;
    } else {
      count++;
      if (count%adj==0&&adj<250) {
        count=0;
        //if (adj<60) {
          //bpm[int(random(0, 6))].setValue(random(0, 2));
        //}
      }
      arduino.digitalWrite(delayPin[i], Arduino.LOW);
      //beatState[i]=0;
    }
  }
  delayBeat();

  switch(fanState) {
  case 3:
    adj=16;
    break;

  case 2:
    adj=64;
    break;

  case 1:
    adj=128;
    break;

  case 0:
    adj=256;
    for (int i=0; i<6; i++) {
      arduino.digitalWrite(delayPin[i], Arduino.LOW);
    }
    break;
  }
}

void drawAnimation() {
  for (int i=0; i<3; i++) {
    radps[i]=(rpm[i].getValue()*2*PI)/60;
    freq[i]=bpm[i].getValue();
    //freq[i]=random(0,1.0);
    freq[i+3]=bpm[i+3].getValue();
    //freq[i+3]=random(0,1.0);
    motors[i].show(ang[i]+=radps[i], sin(frameCount*freq[i]), sin(frameCount*freq[i+3]));
  }
}

void delayBeat() {
  for (int i=0; i<6; i++) {
    switch(beatState[i]) {
    case 1:
      arduino.digitalWrite(delayPin[i], Arduino.HIGH);//ON
      delay(30);
      break;

    default:
      arduino.digitalWrite(delayPin[i], Arduino.LOW);//OFF
      break;
    }
  }
}

void oscEvent(OscMessage theOscMessage) {
  String addrPattern=theOscMessage.addrPattern();
  //println(addrPattern);
  if (addrPattern.equals("/bpm")) {
    heartBpm=theOscMessage.get(0).intValue();
    //bpm[int(random(6))].setValue(int(random(0,2)));
    if (heartBpm>minBpm&&heartBpm<avgBpm) {
      fanState=1;
    } else if (heartBpm>avgBpm&&heartBpm<maxBpm) {
      fanState=2;
    } else if (heartBpm>maxBpm&&heartBpm<160) {
      fanState=3;
    } else if (heartBpm>=160) {
      println("no data");
      fanState=0;
      for (int i=0; i<6; i++) {
        arduino.digitalWrite(delayPin[i], Arduino.LOW);
      }
    }
  } else {
    println("no data");
    fanState=0;
  }
}

void drawWindows() {
  fill(0);
  noStroke();
  rect(0, 0, width, height*1/5);

  fill(125);
  noStroke();
  rect(0, height*0.5, width, height*0.5);

  fill(0);
  noStroke();
  rect(0, height/5, width, height*0.3);
  textSize(60);
  fill(255);
  textAlign(CENTER);
  text(heartBpm, width/2, height*0.4);
}
//void keyPressed(){
//  switch(keyCode){
//    case '1':
//    adj=8;
//    break;

//    case '2':
//    adj=16;
//    break;

//    case '3':
//    adj=32;
//    break;

//    case '4':
//    adj=64;
//    break;
//  }
//}