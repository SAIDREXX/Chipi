import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

//Clase de conexion con el modulo de HC-06
class BluetoothConnectionManager {
  BluetoothConnection? connection;
  //se verifica si se ha consedido los permisos de bluetooth de la libreria de permission_handler
  Future<void> checkPermissions() async {
    if (await Permission.bluetoothScan.request().isGranted) {
      if (await Permission.bluetoothConnect.request().isGranted) {
        print("Bluetooth permisos concedido");
      } else {
        print("Bluetooth conexion denegado");
      }
    } else {
      print("Bluetooth scan onexion denegado.");
    }
  }
  //si se conecta al dispositivo HC-06
  Future<void> connectToDevice(String address) async {
    try {
      connection = await BluetoothConnection.toAddress(address);
      print("conectado to CHIPI-BOT at $address");



    } catch (exception) {
      print("Could not connect: $exception");
    }
  }
  //se envia los datos a modulo de bluetooth
  void sendData(String data) {
    if (connection != null) {
      connection!.output.add(utf8.encode(data + "\r\n"));
      print("Datos a: $data");
    } else {
      print("no conectado.");
    }
  }
//desconexion del modulo de bluetooth
  void disconnect() {
    if (connection != null) {
      connection!.dispose();
      print("Desconeccion de CHIPI-BOT.");
    }
  }
}
