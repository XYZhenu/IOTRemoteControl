#include <Arduino.h>
bool configJson(const char **keys, int count, const String **outvalues);
void saveConfig(int count, const char **keys, const char **values);