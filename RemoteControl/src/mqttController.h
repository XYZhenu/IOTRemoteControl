#include <MQTT.h>
#include <WString.h>

class MQTTController
{
private:
    MQTTClient *client = nullptr;
    void connect(void);

public:
    MQTTController(/* args */);
    ~MQTTController();
    void setup(void);
    void loop(void);
};