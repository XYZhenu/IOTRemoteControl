#include "mqttController.h"
#include "mcuController.h"
#include "utils.h"
#include <Arduino.h>
#include <MQTT.h>
#include <ESP8266WiFi.h>

MQTTClient *client = new MQTTClient();
WiFiClient net;

void messageReceived(String &topic, String &payload)
{
  Serial.println("incoming: " + topic + " - " + payload);
  if (topic == "reset" && payload == "direction")
  {
    reset();
  }
  else if (topic == "direction")
  {
    int index = payload.indexOf(",");
    String xstring = payload.substring(0, index);
    String ystring = payload.substring(index + 1, (int)payload.length());
    int x = xstring.toInt();
    int y = ystring.toInt();
    processXpwm(x);
    processYpwm(y);
  }
}

bool connect()
{
  Serial.println("mqtt connecting...");
  String const *config[4];
  const char *keys[4] = {"mqtt_server", "mqtt_clientid", "mqtt_username", "mqtt_password"};
  bool haveconfig = configJson(keys, 4, config);
  if (!haveconfig)
  {
    return false;
  }
  
  client->begin(config[0]->c_str(), net);

  int retry = 3;
  while (!client->connect(config[1]->c_str(), config[2]->c_str(), config[3]->c_str()) && retry > 0)
  {
    retry--;
    Serial.print(".");
    delay(1000);
  }
  for (int i = 0; i < 4; i++)
  {
    delete config[i];
  }
  if (client->connected())
  {
    client->subscribe("reset", 1);
    client->subscribe("direction", 0);
    Serial.println("mqtt connected!");
    return true;
  }
  Serial.println("mqtt connected failed!");
  return false;
}

bool mqttSetup()
{
  mcuSetup();
  client->onMessage(messageReceived);
  return connect();
}

void mqttLoop()
{
  client->loop();
  if (!client->connected())
  {
    connect();
  }
}