#include <Arduino.h>
#include "mqttController.h"
#include "WifiController.h"
#include <Ticker.h>
Ticker ticker;
void tick()
{
  //toggle state
  int state = digitalRead(LED_BUILTIN);  // get the current state of GPIO1 pin
  digitalWrite(LED_BUILTIN, !state);     // set pin to the opposite state
}

#define TRIGGER_PIN 0
void setup() {
  // put your setup code here, to run once:
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  Serial.begin(115200);
  Serial.println("\n Starting");
  ticker.attach(0.5, tick);
  wifiSetup(false);
  ticker.detach();
  digitalWrite(LED_BUILTIN, LOW);
  pinMode(TRIGGER_PIN, INPUT_PULLUP);
}


void loop() {
  
  if ( digitalRead(TRIGGER_PIN) == LOW ) {
    ticker.attach(0.5, tick);
    wifiSetup(true);
    ticker.detach();
    digitalWrite(LED_BUILTIN, LOW);
  } else {
    delay(1000);
  }
}