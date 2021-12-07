#include "utils.h"
#include <FS.h> //this needs to be first, or it all crashes and burns...
#include <ArduinoJson.h>
using namespace std;
bool configJson(const char **keys, int count, const String **outvalues)
{
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

                    for (int i = 0; i < count; i++)
                    {
                        const char *value = json[keys[i]];
                        String* v = new String(value);
                        outvalues[i] = v;
                    }
                }
                else
                {
                    Serial.println("failed to load json config");
                }
                configFile.close();
                return true;
            }
        }
    }
    else
    {
        Serial.println("failed to mount FS");
    }
    return false;
}

void saveConfig(int count, const char **keys, const char **values)
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

    for (int i = 0; i < count; i++)
    {
        const char *key = keys[i];
        const char *value = values[i];
        json[key] = value;
    }

#ifdef ARDUINOJSON_VERSION_MAJOR >= 6
    serializeJson(json, Serial);
    serializeJson(json, configFile);
#else
    json.printTo(Serial);
    json.printTo(configFile);
#endif
    configFile.close();
}