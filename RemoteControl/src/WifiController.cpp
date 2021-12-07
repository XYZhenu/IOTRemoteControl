#include "utils.h"
#include <ESP8266WiFi.h> //https://github.com/esp8266/Arduino
//needed for library
#include <DNSServer.h>
#include <ESP8266WebServer.h>
#include <WiFiManager.h> //https://github.com/tzapu/WiFiManager

#include <ArduinoJson.h> //https://github.com/bblanchon/ArduinoJson
#include <Arduino.h>
//define your default values here, if there are different values in config.json, they are overwritten.
int paramCount = 4;
const char *params[4] = {"mqtt_server", "mqtt_clientid", "mqtt_username", "mqtt_password"};

bool shouldSaveConfig = false;

//callback notifying us of the need to save config
void saveConfigCallback()
{
    Serial.println("Should save config");
    shouldSaveConfig = true;
}

void wifiSetup(bool reset)
{
    WiFiManager wifiManager;
    wifiManager.setSaveConfigCallback(saveConfigCallback);
    wifiManager.setBreakAfterConfig(true);

    const String *config[paramCount];
    WiFiManagerParameter *mamagerParam[paramCount];

    if (paramCount > 0)
    {
        if (configJson(params, paramCount, config))
        {
            for (int i = 0; i < paramCount; i++)
            {
                WiFiManagerParameter *custom_param = new WiFiManagerParameter(*(params + i), *(params + i), config[i]->c_str(), 40);
                mamagerParam[i] = custom_param;
                wifiManager.addParameter(custom_param);
            }
        }
        else
        {
            for (int i = 0; i < paramCount; i++)
            {
                WiFiManagerParameter *custom_param = new WiFiManagerParameter(*(params + i), *(params + i), "", 40);
                mamagerParam[i] = custom_param;
                wifiManager.addParameter(custom_param);
            }
        }
    }

    if (reset)
    {
        if (!wifiManager.startConfigPortal("AutoConnectAP"))
        {
            Serial.println("failed to connect and hit timeout");
            delay(3000);
            //reset and try again, or maybe put it to deep sleep
            ESP.reset();
            delay(5000);
        }
    }
    else
    {
        if (!wifiManager.autoConnect("AutoConnectAP"))
        {
            Serial.println("failed to connect and hit timeout");
            delay(3000);
            //reset and try again, or maybe put it to deep sleep
            ESP.reset();
            delay(5000);
        }
    }

    //if you get here you have connected to the WiFi
    Serial.println("connected...yeey :)");
    Serial.println("local ip");
    Serial.println(WiFi.localIP());
    if (!shouldSaveConfig)
    {
        return;
    }
    if (paramCount > 0)
    {
        const char *tempConfig[paramCount];
        for (int i = 0; i < paramCount; i++)
        {
            tempConfig[i] = mamagerParam[i]->getValue();
            Serial.println(String(params[i]) + " : " + *tempConfig[i]);
        }
        saveConfig(paramCount, params, tempConfig);
        if (sizeof(config) > 0)
        {
            for (int i = 0; i < paramCount; i++)
            {
                delete mamagerParam[i];
                delete config[i];
            }
        }
        else
        {
            for (int i = 0; i < paramCount; i++)
            {
                delete mamagerParam[i];
            }
        }
    }
}
