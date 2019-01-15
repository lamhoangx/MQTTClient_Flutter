#include <ESP8266WiFi.h>
#include <PubSubClient.h>

 //Network setting
const char* ssid      = "Lamhx"; //YourNetworkName
const char* password  =  ""; //

//MQTT setting
const char* mqttServer    = "m15.cloudmqtt.com";
const int   mqttPort      = 14375;
const char* mqttUser      = "wbpwjaso";
const char* mqttPassword  = "eO-kjpnhyvrI";
const char* mqttClientID  = "ESP8266Client";

const char* mqttPublish   = "";
const char* mqttSubscribe = "1";
 
WiFiClient espClient;
PubSubClient client(espClient);
 
void setup() 
{
 
  Serial.begin(115200);
 
  WiFi.begin(ssid, password);
 
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.println("Connecting to WiFi..");
  }

  Serial.println("Connected to the WiFi network");
 
  client.setServer(mqttServer, mqttPort);
  client.setCallback(callback);
 
  while (!client.connected())
  {
    Serial.println("Connecting to MQTT...");
 
    if (client.connect(mqttClientID, mqttUser, mqttPassword )) 
    {
      Serial.println("Connected");  
    } 
    else 
    {
 
      Serial.print("Failed with state: ");
      Serial.println(client.state());
      
      delay(2000);
 
    }
   }
  delay(2000);
  client.publish(mqttSubscribe, "Hello from ESP8266");
  client.subscribe(mqttSubscribe);

}
 
void callback(char* topic, byte* payload, unsigned int length) {
 
  Serial.print("Message arrived in topic: ");
  Serial.println(topic);
 
  Serial.print("Message:");
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }

  Serial.println();
  Serial.println("-----------------------");
}

void loop() {
  client.loop();
}
