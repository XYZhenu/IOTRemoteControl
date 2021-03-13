#include <Arduino.h>
#include <WiFi.h>
#include <MQTT.h>
#include <WString.h>
char ssid[] = "CMCC-kP6g";
char pass[] = "p7bbkh3c";
char ipadd[] = "192.168.1.13";
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

void messageReceived(String &topic, String &payload) {
  Serial.println("incoming: " + topic + " - " + payload);
  if (topic == "reset" && payload == "direction")
  {
    
  } else if (topic == "direction")
  {
    int index = payload.indexOf(",");
    String xstring = payload.substring(0,index);
    String ystring = payload.substring(index+1,(int)payload.length());
    int x = xstring.toInt();
    int y = ystring.toInt();

  }
}


void mcuSetup()
{
  //初始化电机驱动IO为输出方式
  // pinMode(Left_motor_front, OUTPUT);
  // pinMode(Left_motor_back, OUTPUT);
  // digitalWrite(Right_motor_en, LOW);
  // digitalWrite(Left_motor_en, LOW);

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
