#include <Arduino.h>
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
  int speed = map(pwm, 0, 100, 0, 1024); 
#ifdef NODEMCU
  if (pwm > 25)
  {
    analogWrite(nodemcuA1, speed);
    digitalWrite(nodemcuA2, LOW);
  }
  else if (pwm < -25)
  {
    analogWrite(nodemcuA1, -speed);
    digitalWrite(nodemcuA2, HIGH);
  }
  else
  {
    digitalWrite(nodemcuA1, LOW);
  }
#endif
}

void processXpwm(int pwm)
{
#ifdef NODEMCU
  if (pwm > 25)
  {
    digitalWrite(nodemcuB1, HIGH);
    digitalWrite(nodemcuB2, HIGH);
  }
  else if (pwm < -25)
  {
    digitalWrite(nodemcuB1, HIGH);
    digitalWrite(nodemcuB2, LOW);
  }
  else
  {
    digitalWrite(nodemcuB1, LOW);
  }
#endif
}

void reset()
{
#ifdef NODEMCU
  digitalWrite(nodemcuA1, LOW);
  digitalWrite(nodemcuB1, LOW);
#endif
}