#include <Arduino.h>
#define NODEMCU;
int nodemcuD1 = 5;
int nodemcuD2 = 4;
int nodemcuD3 = 0;
int nodemcuD4 = 2;
int nodemcuD5 = 14;
int nodemcuD6 = 12;

int nodemcuA1 = nodemcuD1;
int nodemcuA2 = nodemcuD3;
int nodemcuB1 = nodemcuD2;
int nodemcuB2 = nodemcuD4;

void mcuSetup()
{
#ifdef NODEMCU
  pinMode(nodemcuA1, OUTPUT);
  pinMode(nodemcuA2, OUTPUT);
  pinMode(nodemcuB1, OUTPUT);
  pinMode(nodemcuB2, OUTPUT);
#endif
}

void processYpwm(int pwm)
{
#ifdef NODEMCU
  if (pwm > 0)
  {
    digitalWrite(nodemcuA1, HIGH);
    digitalWrite(nodemcuA2, LOW);
  }
  else
  {
    digitalWrite(nodemcuA1, HIGH);
    digitalWrite(nodemcuA2, HIGH);
  }
#endif
}

void processXpwm(int pwm)
{
#ifdef NODEMCU
  if (pwm > 0)
  {
    digitalWrite(nodemcuB1, HIGH);
    digitalWrite(nodemcuB2, HIGH);
  }
  else
  {
    digitalWrite(nodemcuB1, HIGH);
    digitalWrite(nodemcuB2, LOW);
  }
#endif
}

void reset()
{
#ifdef NODEMCU
  digitalWrite(nodemcuA1, LOW);
  digitalWrite(nodemcuA2, LOW);
  digitalWrite(nodemcuB1, LOW);
  digitalWrite(nodemcuB2, LOW);
#endif
}