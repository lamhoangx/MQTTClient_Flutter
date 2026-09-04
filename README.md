# MQTT Connection Sample 

Mobile's App is written by Flutter.
Demonstrates how to use [mqtt_client](https://pub.dev/packages/mqtt_client) with [Flutter](https://flutter.dev/).
<br>
Extends from https://github.com/shamblett/mqtt_client/tree/master/example/flutter

## Features

- Connect to any MQTT 3.1 broker, over plain TCP (`1883`) or TLS (`8883`), with username/password authentication. TLS is enabled automatically when the port is `8883`.
- Subscribe/unsubscribe to topics (QoS 1).
- Live list of incoming messages, newest on top.
- Publish messages to any topic from the Messages tab (`+` button).
- Connection state shown live in the app bar icon.

## Getting Started

Requires Flutter 3.x (Dart 3). Install packages from the command line:
    `$ flutter pub get`
Then run on a connected device or emulator:
    `$ flutter run`

## Screenshots
<img src="screenshots/full.png" height="400" alt="Screenshots"/>

## Video
https://youtu.be/ZDa0UNjTGzw

## Using the app

The app has three tabs:

- **Broker** — enter broker host, port, username, password and client identifier, then tap `Connect`. Empty fields keep the defaults from the code; a random client identifier is generated if left blank.
- **Subscriptions** — type a topic and tap `Add topic` to subscribe. Remove a topic by tapping the ✕ on its chip.
- **Messages** — shows received messages with topic, payload and QoS, newest on top. The `+` button opens a dialog to publish a message; `Clear` empties the list.

## Broker setup

You can setup a server through [CloudAMQP](https://www.cloudamqp.com) (see the [MQTT docs](https://www.cloudamqp.com/docs/mqtt.html)) or use the public [mosquitto](https://test.mosquitto.org/) test broker.

### CloudAMQP

1. Create an account at [cloudamqp.com](https://www.cloudamqp.com) and create a new instance — pick **LavinMQ** (MQTT is served by LavinMQ instances, not RabbitMQ ones).
2. Open the instance details page and copy the host (e.g. `your-instance.lmq.us-east-1.aws.cloudamqp.com`), the default username and the password.
3. In the app, connect with:
   - **Broker**: your instance host
   - **Port**: `8883` (MQTT over TLS) or `1883` (plain MQTT)
   - **Username**: `vhost:username` — the vhost must be prepended to the username; on shared plans the vhost is the same as the username, e.g. `my-user:my-user`
   - **Password**: your instance password

By default in code, information environment for testing is (replace with your own instance's values):
```dart
    String broker           = 'your-instance.lmq.us-east-1.aws.cloudamqp.com';
    int    port             = 8883;
    String username         = 'your-username:your-username';
    String passwd           = 'your-password';
    String clientIdentifier = 'lamhx';
```

Notes:
- MQTT 3.1 only, and only QoS 0 and 1 are supported — QoS 2 subscriptions are downgraded to QoS 1 by the broker.

### Public mosquitto test broker

No account needed: connect to `test.mosquitto.org` on port `1883` (plain MQTT). See [test.mosquitto.org](https://test.mosquitto.org/) for the current list of open listeners.

-------

Hope doing well and happy testing!
