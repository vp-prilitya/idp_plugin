// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:usb_serial_for_android/transaction.dart';
import 'package:usb_serial_for_android/usb_device.dart';
import 'package:usb_serial_for_android/usb_port.dart';
import 'package:usb_serial_for_android/usb_serial_for_android.dart';

class IdpSandbox {
  final _connectPort = StreamController<bool>();
  Stream<bool> get connectPort => _connectPort.stream;

  final _status = StreamController<String>();
  Stream<String> get status => _status.stream;

  UsbPort? _port;
  Transaction<String>? _transaction;
  Timer? _time;
  String id = '190';
  var lineData = [];

  Future<void> initial() async {
    print("initial...");
    List<UsbDevice> devices = await UsbSerial.listDevices();

    for (var element in devices) {
      if (element.productName == 'USB-Serial Controller D') {
        print(element.productName);
        _connectTo(element);
      }
    }
  }

  Future<bool> _connectTo(UsbDevice? device) async {
    if (_transaction != null) {
      _transaction!.dispose();
      _transaction = null;
    }

    if (_port != null) {
      _port!.close();
      _port = null;
    }

    if (device == null) {
      _connectPort.add(false);
      return true;
    }

    // You can customize your driver and the port number
    _port = await device.create();
    if (await (_port!.open()) != true) {
      _connectPort.add(false);
    }
    // _device = device;

    await _port!.setDTR(true);
    await _port!.setRTS(true);
    await _port!.setPortParameters(
        9600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    await _port!.connect();

    _transaction = Transaction.stringTerminated(
        _port!.inputStream as Stream<Uint8List>, Uint8List.fromList([13, 10]));

    _transaction!.stream.listen((String line) async {
      if (line == '0000000010') {
        _status.add("ready");
      }
      if (line == 'ERROR') {
        _status.add("error");

        if (_time != null) {
          _time!.cancel();
        }
      }

      // var data = line.split(' ');

      // if (data[0] == '%UTC:') {
      //   utc.value = '${data[1]} ${data[2]}';
      // }

      var response = line.split(':');
      if (response[0] == '%MGRS') {
        var msg = response[1].split(',');
        if (msg[4] == '5') {
          _status.add('sending');
        } else if (msg[4] == '6') {
          if (_time != null) {
            _time!.cancel();
          }
          _status.add('complete');
          await Future.delayed(const Duration(seconds: 4));
          _status.add('ready');
        } else {
          _status.add('failed');
          if (_time != null) {
            _time!.cancel();
          }
        }
      }

      lineData.add(line);
    });

    _connectPort.add(true);
    print('connect Port');

    _write('AT');
    _write('ATI');
    _write('AT%UTC');
    _write('ATS90=3 S91=1 S92=1 S122?');

    return true;
  }

  Future<void> _write(String command) async {
    lineData.clear();
    String data = "$command\r\n";
    await _port!.write(Uint8List.fromList(data.codeUnits));
  }

  void sendMessage({required String message}) {
    _write('AT%MGRT="$id",1,144.2,1,"$message"');

    _time = Timer.periodic(const Duration(seconds: 1), (timer) {
      _write('AT%MGRS="$id"');
    });
  }

  void dispose() {
    _connectTo(null);
  }
}
