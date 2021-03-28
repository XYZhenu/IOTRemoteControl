#include <Arduino.h>
#include <Ticker.h>
#include "mqttController.h"
#include "WifiController.h"
// MQTTController mqtt;
Ticker ticker;
void tick()
{
  //toggle state
  int state = digitalRead(LED_BUILTIN); // get the current state of GPIO1 pin
  digitalWrite(LED_BUILTIN, !state);    // set pin to the opposite state
}
#define FLASH_PIN 0

#define TRIGGER_PIN 10
void setup()
{
  // put your setup code here, to run once:
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  Serial.begin(115200);
  Serial.println("\n Starting");
  ticker.attach(1, tick);
  wifiSetup(false);
  ticker.attach(0.5, tick);
  // mqtt.setup();
  ticker.detach();
  digitalWrite(LED_BUILTIN, LOW);
  pinMode(TRIGGER_PIN, INPUT_PULLUP);
}

void loop()
{

  if (digitalRead(TRIGGER_PIN) == LOW)
  {
    ticker.attach(1, tick);
    wifiSetup(true);
    ticker.attach(0.5, tick);
    // mqtt.setup();
    ticker.detach();
    digitalWrite(LED_BUILTIN, LOW);
  }
  else
  {
    // mqtt.loop();
  }
}