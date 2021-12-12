#include <Arduino.h>
#include "mcuController.h"
#undef NODEMCU
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

void mcuSetup()
{
  // pinMode(nodemcuA1, OUTPUT);
  // pinMode(nodemcuA2, OUTPUT);
  pinMode(nodemcuB1, OUTPUT);
  pinMode(nodemcuB2, OUTPUT);
  int result = myservo.attach(nodemcuD5);
  myservo.write(90);
  Serial.println("attach result ");
  Serial.println(result);
}

void processYpwm(int pwm)
{
  if (pwm > 25)
  {
    int speed = map(pwm, 0, 100, 0, 767); 
    analogWrite(nodemcuB1, speed+256);
    digitalWrite(nodemcuB2, HIGH);
  }
  else if (pwm < -25)
  {
    int speed = map(-pwm, 0, 100, 0, 767); 
    analogWrite(nodemcuB1, speed+256);
    digitalWrite(nodemcuB2, LOW);
  }
  else
  {
    digitalWrite(nodemcuB1, LOW);
  }
}

void processXpwm(int pwm)
{
  Serial.println(angle);
  if (pwm > 15)
  {
    int angle = map(pwm, 0, 100, 0, 90); 
    myservo.write(angle);
    delay(15);
  }
  else if (pwm < -15)
  {
    int angle = map(-pwm, 0, 100, 0, 90); 
    myservo.write(-angle);
    delay(15);
  }
  else
  {
    myservo.write(90);
    delay(15);
  }
}

void reset()
{
  // digitalWrite(nodemcuA1, LOW);
  digitalWrite(nodemcuB1, LOW);
  myservo.write(90);
}
void adjustXstep(int step) {}
void adjustYstep(int step) {}
void resetServo() {}
void mcuLoop() {}
#endif





#ifdef ESP8266
#include <Ticker.h>

int driv1A1 = 16;
int driv1A2 = 14;
int driv1B1 = 12;
int driv1B2 = 13;
int drive[4] = {driv1A1,driv1A2,driv1B1,driv1B2};
int driveStep = 0;
bool driveForward = true;
void driveTick();
Ticker driveTimer(driveTick, 1000, 0, MILLIS);

int servoA1 = 5;
int servoA2 = 4;
int servoB1 = 0;
int servoB2 = 2;
int servo[4] = {servoA1,servoA2,servoB1,servoB2};
int servoStep = 0;
int servoTarget = 0;
void servoTick();
Ticker servoTimer(servoTick, 10, 0, MILLIS);

void resetPins(int pins[10]);

void tick1(int pins[4]){
  digitalWrite(pins[0], HIGH);
  digitalWrite(pins[1], LOW);
  digitalWrite(pins[2], HIGH);
  digitalWrite(pins[3], LOW);
  delay(4);
}
void tick2(int pins[4]){
  digitalWrite(pins[0], LOW);
  digitalWrite(pins[1], HIGH);
  digitalWrite(pins[2], HIGH);
  digitalWrite(pins[3], LOW);
  delay(4);
}
void tick3(int pins[4]){
  digitalWrite(pins[0], LOW);
  digitalWrite(pins[1], HIGH);
  digitalWrite(pins[2], LOW);
  digitalWrite(pins[3], HIGH);
  delay(4);
}
void tick4(int pins[4]){
  digitalWrite(pins[0], HIGH);
  digitalWrite(pins[1], LOW);
  digitalWrite(pins[2], LOW);
  digitalWrite(pins[3], HIGH);
  delay(4);
}

void tickOne(int pins[4], int * step, bool forward) {
  int switchint = 0;
  switchint = servoStep%4;
  switchint = switchint >= 0 ? switchint : switchint+4;
  switch (switchint)
  {
    case 1: tick1(pins); break;
    case 2: tick2(pins); break;
    case 3: tick3(pins); break;
    default: tick4(pins); break;
  }
  *step += forward ? 1 : -1;
}

void driveTick()
{
  tickOne(drive, &driveStep, driveForward);
}

void servoTick()
{
  if (servoTarget == servoStep) {
    Serial.printf("\nservoTick stop %d",servoStep);
    servoTimer.pause();
    resetPins(servo);
    return;
  }
  tickOne(servo, &servoStep, servoTarget > servoStep);
}

void resetPins(int pins[4]){
  digitalWrite(pins[0], LOW);
  digitalWrite(pins[1], LOW);
  digitalWrite(pins[2], LOW);
  digitalWrite(pins[3], LOW);
}

void mcuSetup()
{
  pinMode(driv1A1, OUTPUT);
  pinMode(driv1A2, OUTPUT);
  pinMode(driv1B1, OUTPUT);
  pinMode(driv1B2, OUTPUT);

  pinMode(servoA1, OUTPUT);
  pinMode(servoA2, OUTPUT);
  pinMode(servoB1, OUTPUT);
  pinMode(servoB2, OUTPUT);

  reset();
}


void processYpwm(int pwm)
{
  
  if (pwm > 15)
  {
    int speed = 100-pwm; 
    driveTimer.resume();
    driveTimer.interval(speed);
    driveForward = true;
  }
  else if (pwm < -15)
  {
    int speed = 100+pwm; 
    driveTimer.resume();
    driveTimer.interval(speed);
    driveForward = false;
  }
  else
  {
    driveTimer.pause();
    resetPins(drive);
  }
}


void processXpwm(int pwm)
{
  servoTarget = pwm*4;
  Serial.printf("\nservoTarget %d",servoTarget);
  if (pwm > 15)
  {
    servoTimer.resume();
  }
  else if (pwm < -15)
  {
    servoTimer.resume();
  }
  else
  {
    servoTarget = 0;
    servoTimer.resume();
  }
}

void adjustXstep(int step) 
{
  if (step == 0) {
    return;
  }
  else if (step>0)
  {
    for (int i = 0; i < step; i++)
    {
      tickOne(servo, &servoStep, true);
    }
  }else{
    for (int i = 0; i < -step; i++)
    {
      tickOne(servo, &servoStep, false);
    }
  }
  resetPins(servo);
}

void adjustYstep(int step)
{
  if (step == 0) {
    return;
  }
  else if (step>0)
  {
    for (int i = 0; i < step; i++)
    {
      tickOne(drive, &driveStep, true);
    }
  }else{
    for (int i = 0; i < -step; i++)
    {
      tickOne(drive, &driveStep, false);
    }
  }
  resetPins(drive);
}

void reset()
{
  servoTarget = 0;
  servoTimer.resume();
}

void resetServo() 
{
  servoTimer.pause();
  servoStep = 0;
}

void mcuLoop() 
{
  driveTimer.update();
  servoTimer.update();
}
#endif