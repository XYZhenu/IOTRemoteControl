#include "mqttController.h"
#include "mcuController.h"
#include "utils.h"

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
  const char *config[4];
  const char *keys[4] = {"mqtt_server", "mqtt_clientid", "mqtt_username", "mqtt_password"};
  configJson(keys, 4, config);
  IPAddress add = IPAddress();
  add.fromString(config[0]);
  client->setHost(add);
  while (!client->connect(config[1], config[2], config[3]))
  {
    Serial.print(".");
    delay(1000);
  }

  Serial.println("\nmqtt connected!");
}

void MQTTController::setup()
{
  mcuSetup();
  client->subscribe("reset");
  client->subscribe("direction");
  client->onMessage(messageReceived);
  this->connect();
}

void MQTTController::loop()
{
  client->loop();
  if (!client->connected())
  {
    this->connect();
  }
}