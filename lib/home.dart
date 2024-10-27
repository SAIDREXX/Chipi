import 'dart:math';
import 'package:chipibot/constants/colors.dart';
import 'package:chipibot/constants/welcome_phrases.dart';
import 'package:flutter/material.dart';
import './utils/tts_stt_service.dart';
import 'Bluetooth/bluetooth_connection.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BluetoothConnectionManager _bluetoothManager = BluetoothConnectionManager();
  final String chipiBotAddress = "98:DA:60:03:A8:8C"; // LA DIRECCION MAC DEL MODULO HC-06


  @override
  void initState() {
    super.initState();
   // SpeechRecognitionService().startListening(phrases, responses);
    /
    _bluetoothManager.checkPermissions(); //verifica si tiene permisos de bluetooth si no lo tiene le paarecera la invitaticon de permitirlo
    _bluetoothManager.connectToDevice(chipiBotAddress); //se sincroniza al modulo de bluetooth de HC-06 que tiene una direccion
  }
  @override
  void dispose() {
    _bluetoothManager.disconnect();
    super.dispose();
  }

  void sayRandomPhrase() async {
    final random = Random();
    final welcomePhrase = phrases[random.nextInt(phrases.length)];
    await _flutterTts.speak(welcomePhrase);
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          sayRandomPhrase();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment
              .spaceAround, // Distribuye el espacio horizontalmente
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Centra verticalmente
                children: [
                  ElevatedButton(
                    onPressed: () {
                      //se envia al modulo el dato 1
                      _bluetoothManager.sendData("1"); // Enviar "1" al CHIPI-BOT
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: ColorConstants.redColor,
                      iconColor: Colors.white,
                      padding: const EdgeInsets.all(10),
                    ),
                    child: const Icon(
                      Icons.lunch_dining_outlined,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 100), // Espaciado entre botones
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: ColorConstants.blueColor,
                      iconColor: Colors.white,
                      padding: const EdgeInsets.all(10),
                    ),
                    child: const Icon(
                      Icons.local_bar_outlined,
                      size: 60,
                    ),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/blinking_face.gif',
              width: 500,
              height: 500,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Centra verticalmente
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: ColorConstants.pinkColor,
                      iconColor: Colors.white,
                      padding: const EdgeInsets.all(10),
                    ),
                    child: const Icon(
                      Icons.cake_outlined,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 100), // Espaciado entre botones
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: ColorConstants.greenColor,
                      iconColor: Colors.white,
                      padding: const EdgeInsets.all(10),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
