import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_client/mqtt_server_client.dart' as mqtt;
import 'package:mqtt_client_example/dialogs/send_message.dart';
import 'package:mqtt_client_example/models/message.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PageController _pageController = PageController();
  int _page = 0;

  static const String titleBar = 'MQTT';

  // Default broker environment for testing (see README).
  String broker = 'm15.cloudmqtt.com';
  int port = 14375;
  String username = 'wbpwjaso';
  String passwd = 'eO-kjpnhyvrI';
  String clientIdentifier = 'lamhx';

  mqtt.MqttServerClient? client;

  StreamSubscription<List<mqtt.MqttReceivedMessage<mqtt.MqttMessage>>>?
      subscription;

  final TextEditingController brokerController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwdController = TextEditingController();
  final TextEditingController identifierController = TextEditingController();

  final TextEditingController topicController = TextEditingController();
  final Set<String> topics = <String>{};

  final List<Message> messages = <Message>[];
  final ScrollController messageController = ScrollController();

  /// Single source of truth for the connection state, read straight from the
  /// client so it can never go stale.
  bool get isConnected =>
      client?.connectionStatus?.state == mqtt.MqttConnectionState.connected;

  @override
  Widget build(BuildContext context) {
    final IconData connectionStateIcon =
        _iconForState(client?.connectionStatus?.state);

    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(titleBar),
              const SizedBox(width: 8.0),
              Icon(connectionStateIcon),
            ],
          ),
        ),
        floatingActionButton: _page == 2
            ? FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<String>(
                      builder: (BuildContext context) =>
                          SendMessageDialog(client: client),
                      fullscreenDialog: true,
                    ),
                  );
                },
              )
            : null,
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int page) {
            _pageController.animateToPage(
              page,
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          },
          selectedIndex: _page,
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.cloud_outlined),
              selectedIcon: Icon(Icons.cloud),
              label: 'Broker',
            ),
            NavigationDestination(
              icon: Icon(Icons.playlist_add_outlined),
              selectedIcon: Icon(Icons.playlist_add),
              label: 'Subscriptions',
            ),
            NavigationDestination(
              icon: Icon(Icons.message_outlined),
              selectedIcon: Icon(Icons.message),
              label: 'Messages',
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (int page) {
            setState(() {
              _page = page;
            });
          },
          children: <Widget>[
            _buildBrokerPage(connectionStateIcon),
            _buildSubscriptionsPage(),
            _buildMessagesPage(),
          ],
        ),
      ),
    );
  }

  IconData _iconForState(mqtt.MqttConnectionState? state) {
    switch (state) {
      case mqtt.MqttConnectionState.connected:
        return Icons.cloud_done;
      case mqtt.MqttConnectionState.connecting:
        return Icons.cloud_upload;
      case mqtt.MqttConnectionState.disconnecting:
        return Icons.cloud_download;
      case mqtt.MqttConnectionState.faulted:
        return Icons.error;
      case mqtt.MqttConnectionState.disconnected:
      case null:
        return Icons.cloud_off;
    }
  }

  Widget _buildBrokerPage(IconData connectionStateIcon) {
    return Form(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 280.0,
                child: TextField(
                  controller: brokerController,
                  decoration: const InputDecoration(labelText: 'Input broker'),
                ),
              ),
              SizedBox(
                width: 280.0,
                child: TextField(
                  controller: portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Port'),
                ),
              ),
              SizedBox(
                width: 280.0,
                child: TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
              ),
              SizedBox(
                width: 280.0,
                child: TextField(
                  controller: passwdController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Passwd'),
                ),
              ),
              SizedBox(
                width: 280.0,
                child: TextField(
                  controller: identifierController,
                  decoration:
                      const InputDecoration(labelText: 'Client Identifier'),
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                '$broker:$port',
                style: const TextStyle(fontSize: 24.0),
              ),
              const SizedBox(height: 8.0),
              Icon(connectionStateIcon),
              const SizedBox(height: 16.0),
              FilledButton(
                child: Text(isConnected ? 'Disconnect' : 'Connect'),
                onPressed: () {
                  if (brokerController.value.text.isNotEmpty) {
                    broker = brokerController.value.text;
                  }

                  final int? parsedPort =
                      int.tryParse(portController.value.text);
                  if (parsedPort != null) {
                    port = parsedPort;
                  }
                  if (usernameController.value.text.isNotEmpty) {
                    username = usernameController.value.text;
                  }
                  if (passwdController.value.text.isNotEmpty) {
                    passwd = passwdController.value.text;
                  }

                  clientIdentifier = identifierController.value.text;
                  if (clientIdentifier.isEmpty) {
                    final Random random = Random();
                    clientIdentifier = 'lamhx_${random.nextInt(100)}';
                  }

                  if (isConnected) {
                    _disconnect();
                  } else {
                    _connect();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesPage() {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            controller: messageController,
            children: _buildMessageList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: OutlinedButton(
            child: const Text('Clear'),
            onPressed: () {
              setState(() {
                messages.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 280.0,
                child: TextField(
                  controller: topicController,
                  decoration: const InputDecoration(
                    labelText: 'Please enter a topic',
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              FilledButton(
                child: const Text('Add topic'),
                onPressed: () {
                  _subscribeToTopic(topicController.value.text);
                },
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            alignment: WrapAlignment.start,
            children: _buildTopicList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    subscription?.cancel();
    _pageController.dispose();
    messageController.dispose();
    brokerController.dispose();
    portController.dispose();
    usernameController.dispose();
    passwdController.dispose();
    identifierController.dispose();
    topicController.dispose();
    super.dispose();
  }

  List<Widget> _buildMessageList() {
    return messages
        .map((Message message) => Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListTile(
                trailing: CircleAvatar(
                  radius: 14.0,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'QoS',
                        style: TextStyle(fontSize: 8.0),
                      ),
                      Text(
                        message.qos.index.toString(),
                        style: const TextStyle(fontSize: 8.0),
                      ),
                    ],
                  ),
                ),
                title: Text(message.topic),
                subtitle: Text(message.message),
                dense: true,
              ),
            ))
        .toList()
        .reversed
        .toList();
  }

  List<Widget> _buildTopicList() {
    // Sort topics
    final List<String> sortedTopics = topics.toList()
      ..sort((String a, String b) {
        return compareNatural(a, b);
      });
    return sortedTopics
        .map((String topic) => Chip(
              label: Text(topic),
              onDeleted: () {
                _unsubscribeFromTopic(topic);
              },
            ))
        .toList();
  }

  Future<void> _connect() async {
    /// Create a client with a broker name, client identifier and port.
    /// MqttServerClient is the TCP/TLS client; use MqttClient for websockets.
    /// The client identifier should be unique per broker — the broker uses it
    /// to identify the client and its state.
    final mqtt.MqttServerClient newClient =
        mqtt.MqttServerClient(broker, clientIdentifier)
          ..port = port
          ..logging(on: false)

          /// Keep alive period, must agree with the connect message below.
          ..keepAlivePeriod = 30

          /// Unsolicited disconnection callback.
          ..onDisconnected = _onDisconnected
          ..onConnected = _onConnected;

    /// Connection message: clean (non persistent) session, will message.
    /// The keep alive period is set on the client above.
    final mqtt.MqttConnectMessage connMess = mqtt.MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean()
        .withWillTopic('test/test')
        .withWillMessage('lamhx message test')
        .withWillQos(mqtt.MqttQos.atMostOnce);
    newClient.connectionMessage = connMess;

    debugPrint('MQTT client connecting to $broker:$port...');
    try {
      await newClient.connect(username, passwd);
    } catch (e) {
      debugPrint('MQTT client connection error: $e');
      newClient.disconnect();
    }

    if (!mounted) {
      newClient.disconnect();
      return;
    }

    if (newClient.connectionStatus?.state ==
        mqtt.MqttConnectionState.connected) {
      debugPrint('MQTT client connected');
      setState(() {
        client = newClient;
      });
      subscription = newClient.updates!.listen(_onMessage);
    } else {
      debugPrint('ERROR: MQTT client connection failed - '
          'state is ${newClient.connectionStatus?.state}');
      setState(() {
        client = null;
      });
    }
  }

  void _disconnect() {
    client?.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    if (!mounted) {
      return;
    }
    setState(() {
      subscription?.cancel();
      subscription = null;
      topics.clear();
      client = null;
    });
    debugPrint('MQTT client disconnected');
  }

  void _onConnected() {
    debugPrint('MQTT client connected callback');
    if (mounted) {
      setState(() {});
    }
  }

  void _onMessage(List<mqtt.MqttReceivedMessage<mqtt.MqttMessage>> events) {
    final mqtt.MqttReceivedMessage<mqtt.MqttMessage> event = events[0];
    final mqtt.MqttPublishMessage recMess =
        event.payload as mqtt.MqttPublishMessage;
    final String message =
        mqtt.MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    debugPrint('MQTT message: topic is <${event.topic}>, '
        'payload is <-- $message -->');
    if (!mounted) {
      return;
    }
    setState(() {
      messages.add(Message(
        topic: event.topic,
        message: message,
        qos: recMess.header?.qos ?? mqtt.MqttQos.atMostOnce,
      ));
      // Scroll to the top where the newest message is shown, once this frame
      // has attached the controller to the list view.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (messageController.hasClients) {
          messageController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _subscribeToTopic(String topic) {
    final String trimmed = topic.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (isConnected) {
      setState(() {
        if (topics.add(trimmed)) {
          debugPrint('Subscribing to $trimmed');
          client?.subscribe(trimmed, mqtt.MqttQos.exactlyOnce);
        }
      });
    }
  }

  void _unsubscribeFromTopic(String topic) {
    if (isConnected) {
      setState(() {
        if (topics.remove(topic.trim())) {
          debugPrint('Unsubscribing from ${topic.trim()}');
          client?.unsubscribe(topic.trim());
        }
      });
    }
  }
}
