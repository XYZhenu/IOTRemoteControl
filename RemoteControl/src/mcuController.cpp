#include <Arduino.h>

#ifdef NODEMCU
#include "Servo.h"
Servo myservo;
// int nodemcuD1 = 5;
int nodemcuD2 = 4;
// int nodemcuD3 = 0;
int nodemcuD4 = 2;
int nodemcuD5 = 14;
// int nodemcuD6 = 12;
// int nodemcuA1 = nodemcuD1;
// int nodemcuA2 = nodemcuD3;
int nodemcuB1 = nodemcuD2;
int nodemcuB2 = nodemcuD4;
#endif

#ifdef ESP8266
int driv1A1 = 0;
int driv1A2 = 0;
int driv1B1 = 0;
int driv1B2 = 0;

int servoA1 = 0;
int servoA2 = 0;
int servoB1 = 0;
int servoB2 = 0;
#endif

void mcuSetup()
{
#ifdef NODEMCU
  // pinMode(nodemcuA1, OUTPUT);
  // pinMode(nodemcuA2, OUTPUT);
  pinMode(nodemcuB1, OUTPUT);
  pinMode(nodemcuB2, OUTPUT);
  int result = myservo.attach(nodemcuD5);
  myservo.write(90);
  Serial.println("attach result ");
  Serial.println(result);
#endif

#ifdef ESP8266
  pinMode(driv1A1, OUTPUT);
  pinMode(driv1A2, OUTPUT);
  pinMode(driv1B1, OUTPUT);
  pinMode(driv1B2, OUTPUT);
  pinMode(servoA1, OUTPUT);
  pinMode(servoA2, OUTPUT);
  pinMode(servoB1, OUTPUT);
  pinMode(servoB2, OUTPUT);
#endif
}

void processYpwm(int pwm)
{
  int speed = map(pwm, 0, 100, 0, 767); 
#ifdef NODEMCU
  if (pwm > 25)
  {
    analogWrite(nodemcuB1, speed+256);
    digitalWrite(nodemcuB2, HIGH);
  }
  else if (pwm < -25)
  {
    analogWrite(nodemcuB1, -speed+256);
    digitalWrite(nodemcuB2, LOW);
  }
  else
  {
    digitalWrite(nodemcuB1, LOW);
  }
#endif

#ifdef ESP8266

#endif
}

void processXpwm(int pwm)
{
  int angle = 90 - map(pwm, 0, 100, 0, 90); 
  Serial.println(angle);
#ifdef NODEMCU
  if (pwm > 15)
  {
    myservo.write(angle);
    delay(15);
  }
  else if (pwm < -15)
  {
    myservo.write(angle);
    delay(15);
  }
  else
  {
    myservo.write(90);
    delay(15);
  }
#endif

#ifdef ESP8266

#endif
}

void reset()
{
#ifdef NODEMCU
  // digitalWrite(nodemcuA1, LOW);
  digitalWrite(nodemcuB1, LOW);
  myservo.write(90);
#endif

#ifdef ESP8266
  
#endif
}