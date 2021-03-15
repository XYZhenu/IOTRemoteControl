#include <Arduino.h>
#include <WiFi.h>
#include <MQTT.h>
#include <WString.h>
char ssid[] = "CMCC-kP6g";
char pass[] = "p7bbkh3c";
char ipadd[] = "192.168.1.13";
char NODEMCU[] = "NODEMCU";
WiFiClient net;
MQTTClient client;

void connect() {
  Serial.print("checking wifi...");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(1000);
  }

  Serial.print("\nconnecting...");
  while (!client.connect("arduino", "xykit", "xykit.")) {
    Serial.print(".");
    delay(1000);
  }

  Serial.println("\nconnected!");

  client.subscribe("reset");
  client.subscribe("direction");
}

int nodemcuA1 = 5;
int nodemcuA2 = 0;
int nodemcuB1 = 4;
int nodemcuB2 = 2;

void mcuSetup()
{


  if (BOARD == NODEMCU)
  {
    pinMode(nodemcuA1, OUTPUT);
    pinMode(nodemcuA2, OUTPUT);
    pinMode(nodemcuB1, OUTPUT);
    pinMode(nodemcuB2, OUTPUT);
  }
}

void processYpwm(int pwm) {
  if (BOARD == NODEMCU)
  {
    if (pwm > 0)
    {
      digitalWrite(nodemcuA1, LOW);
      digitalWrite(nodemcuA2, HIGH);
    } else {
      digitalWrite(nodemcuA1, HIGH);
      digitalWrite(nodemcuA2, LOW);
    }
  }
  
}

void processXpwm(int pwm) {
  if (BOARD == NODEMCU)
  {
    if (pwm > 0)
    {
      digitalWrite(nodemcuB1, LOW);
      digitalWrite(nodemcuB2, HIGH);
    } else {
      digitalWrite(nodemcuB1, HIGH);
      digitalWrite(nodemcuB2, LOW);
    }
  }
  
}

void reset() {
  if (BOARD == NODEMCU)
  {
    digitalWrite(nodemcuA1, LOW);
    digitalWrite(nodemcuA2, LOW);
    digitalWrite(nodemcuB1, LOW);
    digitalWrite(nodemcuB2, LOW);
  }
}

void messageReceived(String &topic, String &payload) {
  Serial.println("incoming: " + topic + " - " + payload);
  if (topic == "reset" && payload == "direction")
  {
    reset();
  } else if (topic == "direction") {
    int index = payload.indexOf(",");
    String xstring = payload.substring(0,index);
    String ystring = payload.substring(index+1,(int)payload.length());
    int x = xstring.toInt();
    int y = ystring.toInt();
    processXpwm(x);
    processYpwm(y);
  }
}








void setup() {

  Serial.begin(115200);
  mcuSetup();
  WiFi.begin(ssid, pass);

  // Note: Local domain names (e.g. "Computer.local" on OSX) are not supported by Arduino.
  // You need to set the IP address directly.
  client.begin(ipadd, net);
  client.onMessage(messageReceived);

  connect();

}

void loop() {
  client.loop();

  if (!client.connected()) {
    connect();
  }
}
