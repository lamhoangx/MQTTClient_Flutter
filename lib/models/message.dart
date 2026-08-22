import 'package:mqtt_client/mqtt_client.dart' as mqtt;

class Message {
  const Message({
    required this.topic,
    required this.message,
    required this.qos,
  });

  final String topic;
  final String message;
  final mqtt.MqttQos qos;
}
