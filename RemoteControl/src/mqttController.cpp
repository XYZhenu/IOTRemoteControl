#include "mqttController.h"
#include "mcuController.h"
#include <ArduinoJson.h>
#include <FS.h>

MQTTController::MQTTController(/* args */)
{
  client = new MQTTClient();
}

MQTTController::~MQTTController()
{
  delete client;
}

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

void MQTTController::connect()
{
  Serial.print("\nmqtt connecting...");
  while (!client->connect("arduino", "xykit", "xykit."))
  {
    Serial.print(".");
    delay(1000);
  }

  Serial.println("\nmqtt connected!");
}

void MQTTController::setup()
{
  mcuSetup();
  this->connect();

  client->subscribe("reset");
  client->subscribe("direction");
  client->onMessage(messageReceived);
}

void MQTTController::loop()
{
  client->loop();
  if (!client->connected())
  {
    this->connect();
  }
}