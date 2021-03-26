#include "utils.h"
#include <FS.h> //this needs to be first, or it all crashes and burns...
#include <ArduinoJson.h>
using namespace std;
const char *configJson(int count, ...)
{
    const char *values[count];
    // put your setup code here, to run once:
    //clean FS, for testing
    //SPIFFS.format();

    //read configuration from FS json
    Serial.println("mounting FS...");

    if (SPIFFS.begin())
    {
        Serial.println("mounted file system");
        if (SPIFFS.exists("/config.json"))
        {
            //file exists, reading and loading
            Serial.println("reading config file");
            File configFile = SPIFFS.open("/config.json", "r");
            if (configFile)
            {
                Serial.println("opened config file");
                size_t size = configFile.size();
                // Allocate a buffer to store contents of the file.
                std::unique_ptr<char[]> buf(new char[size]);

                configFile.readBytes(buf.get(), size);

#if ARDUINOJSON_VERSION_MAJOR >= 6
                DynamicJsonDocument json(1024);
                auto deserializeError = deserializeJson(json, buf.get());
                serializeJson(json, Serial);
                if (!deserializeError)
                {
#else
                DynamicJsonBuffer jsonBuffer;
                JsonObject &json = jsonBuffer.parseObject(buf.get());
                json.printTo(Serial);
                if (json.success())
                {
#endif
                    Serial.println("\nparsed json");
                    //
                    //   strcpy(mqtt_port, json["mqtt_port"]);
                    //   strcpy(blynk_token, json["blynk_token"]);
                    va_list args;
                    const char *args1;
                    va_start(args, count);
                    for (int i = 0; i < count; i++)
                    {
                        auto key = va_arg(args, const char *);
                        values[i] = json[key];
                    }
                    va_end(args);
                }
                else
                {
                    Serial.println("failed to load json config");
                }
                configFile.close();
            }
        }
    }
    else
    {
        Serial.println("failed to mount FS");
    }

    return *values;
}

void saveConfig(int count, ...)
{
    File configFile = SPIFFS.open("/config.json", "w");
    if (!configFile)
    {
        Serial.println("failed to open config file for writing");
    }
#ifdef ARDUINOJSON_VERSION_MAJOR >= 6
    DynamicJsonDocument json(1024);
#else
    DynamicJsonBuffer jsonBuffer;
    JsonObject &json = jsonBuffer.createObject();
#endif

    va_list args;
    const char *args1;
    va_start(args, count);
    for (int i = 0; i < count; i++)
    {
        auto key = va_arg(args, const char *);
        auto value = va_arg(args, const char *);
        json[key] = value;
    }

    va_end(args);

#ifdef ARDUINOJSON_VERSION_MAJOR >= 6
    serializeJson(json, Serial);
    serializeJson(json, configFile);
#else
    json.printTo(Serial);
    json.printTo(configFile);
#endif
    configFile.close();
}