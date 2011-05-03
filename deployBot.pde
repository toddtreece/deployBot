#include <SPI.h>
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <NewSoftSerial.h>

int relay_pin = 7;
int rx_pin = 8;
int tx_pin = 9;
int last_song = 47;

byte mac[] = {  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte server[] = { 192,168,0,59 };
//byte server[] = { 10,0,1,3 } ;
int port = 6667;

unsigned long lastmillis = 0;

String channel = "#it";
String nickname = "deployBot";
String hal = "HALbot";
String default_action = "alerts meatbags";
String default_message = "robacarp, stilldavid, mike, ross, erik, brennen, ben, caseyd, todd, christoph: ready for deploy?";
String dammit_rob = "http://dammitrob.com";
String hal_action = "looks at stilldavid";
String hal_reply = "I'm sorry, Dave. I'm afraid I can't do that.";

Client client(server, port);
NewSoftSerial mp3 = NewSoftSerial(rx_pin, tx_pin);

void setup() {
  EthernetDHCP.begin(mac, 1);
  pinMode(relay_pin, OUTPUT);
  digitalWrite(relay_pin, LOW);
  Serial.begin(9600);
  delay(1000);
  check_dhcp();
  connect();
}

void loop() {
  mp3.begin(38400);
  check_dhcp();
  if(client.available()) {
    String data;
    data = "";
    while(true) {
      char c = client.read();
      Serial.print(c);
      if (c == '\n'){ break; }
      data.concat(c);
    }
    parse_data(data);
  }
  if (!client.connected()) {
    Serial.println();
    Serial.println("Disconnecting...");
    client.stop();
    while(true);
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

void connect() {
  Serial.println("Connecting to the SparkFun IRC server...");
  if(client.connect()) {
    Serial.println("deployBot connected");
    client.print("NICK ");
    client.println(nickname);
    client.print("USER ");
    client.print(nickname);
    client.print(" ");
    client.print(nickname);
    client.print(" ");
    client.print(nickname);
    client.print(" ");
    client.println(":deployBot - sparkfun.com");
    client.println();
    client.print("JOIN ");
    client.println(channel);
  } else {
    Serial.println("Connection Failed");
  }
}

void parse_data(String &data) {
  if(data.startsWith("PING")) {
    send_pong(data);
  } else if(data.indexOf("PRIVMSG deployBot") != -1) {
    if(data.startsWith(":stilldavid!") != false) {
      client.print("NICK ");
      client.println(hal);
      send_action(hal_action);
      send_message(hal_reply);
      delay(5000);
      client.print("NICK ");
      client.println(nickname);
    } else {
      if(data.indexOf("test on") != -1) {
        deploy(false);
      } else if(data.indexOf("test off") != -1) {
        deployed();
      }
    }
  } else if(data.indexOf("PRIVMSG") != -1) {
    if(data.indexOf("meatbags") != -1) {
      if(data.indexOf("deploy?") != -1) {
        deploy(true);
      } else if(data.indexOf("deployed") != -1) {
        deployed();
      }
    }
  }
}

void deploy(boolean alert) {
  mp3.print("t");
  mp3.println(random(1,last_song),BYTE);

  if(alert == true) {
    send_action(default_action);
    send_message(default_message);
  }
  delay(1000);
  digitalWrite(relay_pin, HIGH);
}

void deployed() {
  mp3.println("O");
  digitalWrite(relay_pin, LOW);
}

void send_pong(String &response) {
  client.print("PONG ");
  client.println(response.substring(6));
}

void send_action(String &action) {
  client.print("PRIVMSG ");
  client.print(channel);
  client.print(" :");
  client.print(1,BYTE);
  client.print("ACTION ");
  client.print(action);
  client.println(1,BYTE);
}

void send_message(String &message) {
  client.print("PRIVMSG ");
  client.print(channel);
  client.print(" :");
  client.println(message);
}
