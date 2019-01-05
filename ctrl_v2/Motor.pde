class Motor {
  float x;
  float y;
  float z;
  float ang=90;
  int r=45;
  int[]delay={0, 1};

  Motor(float _x, float _y) {
    x=_x;
    y=_y;
  }

  void show(float _ang,float spR,float spL) {
    ang=_ang;

    pushMatrix();
    strokeWeight(5);
    stroke(125);
    line(x-r*cos(radians(_ang)), y-r*sin(radians(_ang)), x+r*cos(radians(_ang)), y+r*sin(radians(_ang)));
    popMatrix();

    pushMatrix();
    noStroke();
    fill(255*spR);
    //println(sp);    
    ellipse(x-r*cos(radians(_ang)), y-r*sin(radians(_ang)), 6, 6);
    popMatrix();
    
    pushMatrix();
    noStroke();
    fill(255*spL);
    ellipse(x+r*cos(radians(_ang)), y+r*sin(radians(_ang)), 6, 6);
    popMatrix();
  }
}