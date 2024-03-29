#include <Arduino.h>
#include <Ticker.h>
#include "mqttController.h"
#include "WifiController.h"

void tick()
{
  //toggle state
  int state = digitalRead(LED_BUILTIN); // get the current state of GPIO1 pin
  digitalWrite(LED_BUILTIN, !state);    // set pin to the opposite state
}
Ticker ticker(tick, 1000, 0, MILLIS);
#define FLASH_PIN 0

#define TRIGGER_PIN 10

void resetConnection(bool reset)
{
  ticker.interval(1000);
  wifiSetup(reset);
  ticker.interval(500);
  while (!mqttSetup())
  {
    Serial.println("Restart configuration!");
    wifiSetup(true);
  }
  ticker.pause();
  digitalWrite(LED_BUILTIN, LOW);
}
void setup()
{
  // put your setup code here, to run once:
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
Serial.begin(115200);           
  Serial.println("Starting");
  resetConnection(false);
  pinMode(TRIGGER_PIN, INPUT_PULLUP);
}

void loop()
{

  if (digitalRead(TRIGGER_PIN) == LOW)
  {
    resetConnection(true);
  }
  else
  {
    mqttLoop();
  }
}