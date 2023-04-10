import 'package:flutter/material.dart';

import 'package:idp_sandbox/idp_sandbox.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _idpSandboxPlugin = IdpSandbox();
  var connectPort = false;
  var status = 'not available';
  TextEditingController message = TextEditingController();

  @override
  void initState() {
    super.initState();
    _idpSandboxPlugin.connectPort.listen(statusPort);
    _idpSandboxPlugin.status.listen(transaction);
  }

  void statusPort(bool event) {
    setState(() {
      connectPort = event;
    });
  }

  void transaction(String message) {
    setState(() {
      status = message;
    });
  }

  void sendMessage() {
    _idpSandboxPlugin.sendMessage(message: message.text);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: connectPort
                          ? null
                          : () {
                              _idpSandboxPlugin.initial();
                            },
                      child: const Text("Connect")),
                  const SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                      onPressed: !connectPort
                          ? null
                          : () {
                              _idpSandboxPlugin.dispose();
                            },
                      child: const Text("Disconnect"))
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Text("Status : $status"),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: message,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                  onPressed: status == 'ready' || status == 'failed'
                      ? () {
                          sendMessage();
                        }
                      : null,
                  child: const Text("Send Message"))
            ],
          )),
    );
  }
}
