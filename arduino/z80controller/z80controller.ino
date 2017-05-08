const int outPin = 12;
const int clkPin = 11;
const int rstPin = 10;

bool ioreq = false;
bool reqstage = true;
char inp;
bool clockstage = true;

void setup(){
  pinMode(outPin, INPUT);
  //pinMode(clkPin, OUTPUT);
  pinMode(rstPin, OUTPUT);
  pinMode(13, OUTPUT);
  
  digitalWrite(rstPin, LOW); //reset processor

  Serial.begin(115200);
  for(int i=2; i<10; i++) pinMode(i, INPUT);
  
  //analogWrite(clkPin, 128); //start clock at around 500hz
  delay(100);
  digitalWrite(rstPin, HIGH);
}

void loop(){
  ioreq = !digitalRead(outPin);
  digitalWrite(13, ioreq); //show io req

  if(ioreq){
    if(reqstage){ //read data from bus
      inp = 0;
      for(int i=2; i<10; i++){
        inp >>= 1;
        if(digitalRead(i)) inp |= 0x80;
        else inp &= 0x7f;
      }
      if(inp != 0) Serial.print(inp);
      reqstage = false;
    } else{ //write data to bus
      if(Serial.available()) inp = Serial.read();
      else inp = 0;
      for(int i=2; i<10; i++){
        pinMode(i, OUTPUT);
        digitalWrite(i, inp & 0x01);
        inp >>= 1;
      }
      reqstage = true;
    }
    while(!digitalRead(outPin)); //wait for ioreq to stop
    for(int i=2; i<10; i++) pinMode(i, INPUT); //set bus pins to high impedance
  }
}
