void setAdr(uint16_t addr){
  for(int i=0; i<13; i++){
    digitalWrite(22+i*2, addr & 0x0001);
    addr >>= 1;
  }
}
void datin(){
  for(int i=0; i<8; i++) pinMode(39+i*2, INPUT);
}
void datout(){
  for(int i=0; i<8; i++) pinMode(39+i*2, OUTPUT);
}

void writeByt(uint8_t byt, uint16_t addr){
  digitalWrite(25, HIGH); //OE' pin
  digitalWrite(23, HIGH);
  datout();
  setAdr(addr);
  for(int i=0; i<8; i++){
    if(byt & 0x0001) digitalWrite(39+i*2, HIGH);
    else digitalWrite(39+i*2, LOW);
    byt >>= 1;
  }
  digitalWrite(23, LOW);
  delayMicroseconds(500);
  digitalWrite(23, HIGH);
  delayMicroseconds(250);
}

uint8_t readByt(uint16_t addr){
  digitalWrite(23, HIGH); //WE' pin
  digitalWrite(25, HIGH);
  datin();
  setAdr(addr);
  uint8_t tmp = 0;
  digitalWrite(25, LOW);
  delayMicroseconds(250);
  for(int i=0; i<8; i++){
    tmp >>= 1;
    if(digitalRead(39+i*2)) tmp |= 0x80;
  }
  digitalWrite(25, HIGH);
  return tmp;
}

void setup(){
  Serial.begin(115200);
  pinMode(13, OUTPUT);
  for(int i=0; i<13; i++){ //address pins
    pinMode(22+i*2, OUTPUT);
    digitalWrite(22+i*2, LOW);
  }
  for(int i=0; i<8; i++){ //data pins
    pinMode(39+i*2, OUTPUT);
    digitalWrite(39+i*2, LOW);
  }
  pinMode(23, OUTPUT); //WE' pin
  digitalWrite(23, HIGH);
  pinMode(25, OUTPUT); //OE' pin
  digitalWrite(25, HIGH);

  while(!Serial.available()); //wait for serial
  Serial.println("Serial Link Established...");
  uint16_t plen = 0;
  while(!Serial.available());
  plen |= Serial.read() & 0xff;
  while(!Serial.available());
  plen |= (Serial.read() & 0xff) << 8;
  Serial.print("Size Of Program: ");
  Serial.print(plen);
  Serial.println(" bytes");
  
  delay(100);
  digitalWrite(13, HIGH);
  uint8_t bty, byt2;
  for(int i=0; i<plen; i++){
    while(!Serial.available());
    bty = Serial.read();
    writeByt(bty,i);
    byt2 = readByt(i);
    for(int j=0; j<100; j++){
      if(bty == byt2) break;
      if(j >= 99){
        Serial.println("\nWrite Error In Byte ");
        Serial.print((uint16_t)i, HEX);
        Serial.println("\n");
      }
      writeByt(bty,i);
      byt2 = readByt(i);
    }
    Serial.print((int)byt2, HEX);
    Serial.print(" ");
  }
  Serial.println(" ");
  Serial.println("Done...");
  digitalWrite(13, LOW);
}

void loop(){}

/*
 * 13 address pins
 * 8 data io pins
 * WE' write enable
 * OE' output enable
 */
