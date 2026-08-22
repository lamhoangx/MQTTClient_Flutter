import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_client/mqtt_server_client.dart' as mqtt;

class SendMessageDialog extends StatefulWidget {
  final mqtt.MqttServerClient? client;

  const SendMessageDialog({super.key, required this.client});

  @override
  State<SendMessageDialog> createState() => _SendMessageDialogState();
}

class _SendMessageDialogState extends State<SendMessageDialog> {
  bool _hasMessage = false;
  bool _hasTopic = false;
  bool _retainValue = false;
  bool _saveNeeded = false;
  int _qosValue = 0;
  String _messageContent = '';
  String _topicContent = '';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New message'),
        actions: <Widget>[
          TextButton(
            child: Text(
              'SEND',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                _sendMessage();
              }
            },
          ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) {
            return;
          }
          _onWillPop();
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                alignment: Alignment.bottomLeft,
                child: TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Message', filled: true),
                  style: theme.textTheme.headlineSmall,
                  maxLines: 2,
                  validator: (String? value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  onSaved: (String? value) {
                    setState(() {
                      _hasMessage = value?.isNotEmpty ?? false;
                      if (_hasMessage) {
                        _messageContent = value!;
                      }
                    });
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                alignment: Alignment.bottomLeft,
                child: TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Topic', filled: true),
                  validator: (String? value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  onSaved: (String? value) {
                    setState(() {
                      _hasTopic = value?.isNotEmpty ?? false;
                    });
                    if (_hasTopic) {
                      _topicContent = value!;
                    }
                  },
                ),
              ),
              _buildQosChoiceChips(),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Checkbox(
                      value: _retainValue,
                      onChanged: (bool? value) {
                        setState(() {
                          _retainValue = value ?? false;
                          _saveNeeded = true;
                        });
                      },
                    ),
                    const Text('Retained'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQosChoiceChips() {
    return Wrap(
      spacing: 4.0,
      children: List<Widget>.generate(
        3,
        (int index) {
          return ChoiceChip(
            label: Text('QoS level $index'),
            selected: _qosValue == index,
            onSelected: (bool selected) {
              setState(() {
                _qosValue = selected ? index : _qosValue;
              });
            },
          );
        },
      ),
    );
  }

  Future<void> _onWillPop() async {
    _saveNeeded = _hasTopic || _hasMessage || _saveNeeded;

    if (!_saveNeeded) {
      Navigator.of(context).pop();
      return;
    }

    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle = theme.textTheme.titleMedium!
        .copyWith(color: theme.textTheme.bodySmall!.color);

    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text('Discard message?', style: dialogTextStyle),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                // Pops the confirmation dialog but not the page.
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('DISCARD'),
              onPressed: () {
                // Returning true will pop the page as well.
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (discard ?? false) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _sendMessage() {
    final mqtt.MqttClientPayloadBuilder builder =
        mqtt.MqttClientPayloadBuilder();

    builder.addString(_messageContent);
    widget.client?.publishMessage(
      _topicContent,
      mqtt.MqttQos.values[_qosValue],
      builder.payload!,
      retain: _retainValue,
    );
    Navigator.pop(context);
  }
}
