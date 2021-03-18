#include <Arduino.h>


char NODEMCU[] = "NODEMCU";
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