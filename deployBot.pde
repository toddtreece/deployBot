#include <SPI.h>
#include <Ethernet.h>
#include <EthernetDHCP.h>

byte mac[] = {  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte server[] = { 192,168,0,59 };
int port = 6667;
String channel = "#it";
String nickname = "deployBot";
String default_action = "alerts meatbags";
String default_message = "robacarp, stilldavid, judd, Brad, ross, erik, brennen, ben, caseyd, todd, christoph: ready for deploy?";
String dammit_rob = "http://dammitrob.com";
unsigned long lastmillis = 0;
Client client(server, port);

void setup() {
  EthernetDHCP.begin(mac, 1);
  Serial.begin(9600);
  delay(1000);
  check_dhcp();
  connect();
}

/*** check_dhcp() stolen from https://github.com/robacarp/Arduino-IRC-Bot ***/
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

void loop() {
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
    if(data.indexOf(":stilldavid!~dave") != -1) {
      if(data.indexOf("dammit rob") != -1) {
        send_message(dammit_rob);
      }
    }
  } else if(data.indexOf("PRIVMSG") != -1) {
    if(data.indexOf("meatbags") != -1) {
      if(data.indexOf("deploy?") != -1) {
        send_action(default_action);
        send_message(default_message);
      }
    }
  }
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
