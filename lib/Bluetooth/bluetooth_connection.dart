import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class BluetoothConnectionManager {
  BluetoothConnection? _connection;

  Future<void> checkPermissions() async {
    final bluetoothScanStatus = await Permission.bluetoothScan.request();
    final bluetoothConnectStatus = await Permission.bluetoothConnect.request();

    if (bluetoothScanStatus.isGranted && bluetoothConnectStatus.isGranted) {
      print("Bluetooth permisos concedido");
    } else {
      if (!bluetoothScanStatus.isGranted) {
        print("Bluetooth scan denegado.");
      }
      if (!bluetoothConnectStatus.isGranted) {
        print("Bluetooth conexion denegado");
      }
    }
  }

  Future<void> connectToDevice(String address) async {
    try {
      _connection = await BluetoothConnection.toAddress(address);
      print("Conectado a CHIPI-BOT en $address");
    } catch (exception) {
      print("No se pudo conectar: $exception");
    }
  }

  void sendData(String data) {
    if (_connection != null) {
      _connection!.output.add(utf8.encode(data + "\r\n"));
      print("Datos enviados: $data");
    } else {
      print("No conectado.");
    }
  }

  void disconnect() {
    if (_connection != null) {
      _connection!.dispose();
      _connection = null;
      print("Desconexión de CHIPI-BOT.");
    }
  }
}
