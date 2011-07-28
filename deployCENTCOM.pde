#include <SPI.h>
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <NewSoftSerial.h>

byte mac[] = {  0xDE, 0xA1, 0xBE, 0xEF, 0xFB, 0xED };
byte server[] = { 192,168,0,59 };

int port = 6667;

unsigned long lastmillis = 0;

char *channel = "#it";
char *nickname = "deployCENTCOM";
char *readyText = "ready... waiting for command.";
char *armedText = "armed";
char *disarmedText = "disarmed";
char *deployText = "meatbags, deploy?";
char *deployedText = "meatbags, deployed.";

int keySwitch = 4;
int armSwitch = 7;
int deploySwitch = 2;

int keyLight = 3;
int armLight = 5;
int deployLight = 6;

int fadeDelay = 30;
int fadeStep = 5;

/**
 *
 * Modifiers:
 * use XOR to toggle
 *
 * 0x1 = connection
 * 0x2 = key
 * 0x4 = arm switch
 * 0x8 = deploy switch
 *
 **/
byte connection = 0x1;
byte key = 0x2;
byte arm = 0x4;
byte deploy = 0x8;

/**
 *
 * States:
 * 0x0 = key off/disconnected
 * 0x1 = key off/connected
 * 0x2 = key on/disconnected
 * 0x3 = key on/connected
 * 0x7 = armed
 * 0xF = deploying
 *
 **/
byte state = 0x0;
byte previous_state = 0x0;

Client client(server, port);

void setup() {
  
  EthernetDHCP.begin(mac, 1);
  
  pinMode(keySwitch, INPUT);
  pinMode(armSwitch, INPUT);
  pinMode(deploySwitch, INPUT);
  
  pinMode(keyLight, OUTPUT);
  pinMode(armLight, OUTPUT);
  pinMode(deployLight, OUTPUT);
  
  Serial.begin(9600);
  delay(1000);
  check_dhcp();
  
}

void loop() {

  if(client.available()) {
    String data;
    data = "";
    while(true) {
      char c = client.read();
      //Serial.print(c);
      if (c == '\n'){ break; }
      data.concat(c);
    }
    parse_data(data);
  }

  checkState();
}

void connect() {
  Serial.println("Connecting to the SparkFun IRC server...");
  if(client.connect()) {
    Serial.println("deployCENTCOM connected");
    client.print("NICK ");
    client.println(nickname);
    client.print("USER ");
    client.print(nickname);
    client.print(" ");
    client.print(nickname);
    client.print(" ");
    client.print(nickname);
    client.print(" ");
    client.println(":deployCENTCOM - sparkfun-dep.com");
    client.println();
    client.print("JOIN ");
    client.println(channel);
  } else {
    Serial.println("Connection Failed");
  }
}

void check_dhcp(){
  if (EthernetDHCP.poll() < DhcpStateLeased){
    Serial.println("Seeking DHCP.");
    while(EthernetDHCP.poll() < DhcpStateLeased){
      if (millis() - lastmillis > 100){
        lastmillis = millis();
        Serial.print(".");
      }
    }
    Serial.println("DHCP Leased.");
  }
}

void disconnect() {
  client.print("QUIT");
  client.print(" :");
  client.println("shutting down");
  client.stop();  
}

void parse_data(String &data) {
  if(data.startsWith("PING")) {
    send_pong(data);
  }
}

void send_pong(String &response) {
  client.print("PONG ");
  client.println(response.substring(6));
}

void send_action(char *action) {
  client.print("PRIVMSG ");
  client.print(channel);
  client.print(" :");
  client.print(1,BYTE);
  client.print("ACTION ");
  client.print(action);
  client.println(1,BYTE);
}

void send_message(char *message) {
  client.print("PRIVMSG ");
  client.print(channel);
  client.print(" :");
  client.println(message);
}

void checkState() {
  
  previous_state = state;
  state = 0x0;

  modifyState(client.connected(),connection);
  modifyState(digitalRead(keySwitch),key);
  modifyState(digitalRead(armSwitch),arm);
  modifyState(digitalRead(deploySwitch),deploy);
    
  switch(state) {
    case 0x0: //disconnected key off
      break;
    case 0x1: //connected key off
      disconnect();
      break;
    case 0x2: //disconnected key on
      if(previous_state == 0x0)
        connect();
      break;
    case 0x3: //connected key on (ready)
      if(previous_state == 0x2)
        send_action(readyText);
      else if(previous_state == 0x7)
        send_action(disarmedText);
      else if(previous_state == 0xF)
        send_message(deployedText);

      pulse(keyLight);

      break;
    case 0x7: //armed
      if(previous_state == 0x3)
        send_action(armedText);
      else if(previous_state == 0xF)
        send_message(deployedText);
      
      pulse(armLight);      

      break;
    case 0xF: //deploying
      if(previous_state == 0x7)
        send_message(deployText);

      pulse(deployLight);      

      break;
    default:
      break;
  }
}

void modifyState(int reading, byte modifier) {
  if(reading == HIGH) {
    state ^= modifier;
  }
}

void pulse(int pin) {

  for(int brightness = 0; brightness <= 255; brightness +=fadeStep) { 
    analogWrite(pin, brightness);         
    delay(fadeDelay);                            
  } 

  for(int brightness = 255; brightness >= 0; brightness -=fadeStep) { 
    analogWrite(pin, brightness);
    delay(fadeDelay);                            
  }
  
}
