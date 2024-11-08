import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:chipibot/constants/colors.dart';
import 'package:chipibot/constants/welcome_phrases.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import './utils/tts_stt_service.dart';
import 'Bluetooth/bluetooth_connection.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BluetoothConnectionManager _bluetoothManager =
      BluetoothConnectionManager();
  final String chipiBotAddress =
      "98:DA:60:03:A8:8C"; // LA DIRECCION MAC DEL MODULO HC-06

  late stt.SpeechToText _speech; // Speech-to-Text para reconocimiento de voz
  bool _isListening = false; // Estado de escucha
  String _command = ""; // Texto reconocido
  Map<String, List<Map<String, dynamic>>> menu = {};

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Mantener la pantalla encendida
    _speech = stt.SpeechToText(); // Inicialización del SpeechToText
    _loadMenu();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    await _bluetoothManager
        .checkPermissions(); // Verifica permisos de Bluetooth
    await _bluetoothManager
        .connectToDevice(chipiBotAddress); // Conexión al módulo HC-06
  }

  @override
  void dispose() {
    _bluetoothManager.disconnect();
    super.dispose();
  }

  Future<void> sayRandomPhrase() async {
    final random = Random();
    final welcomePhrase = phrases[random.nextInt(phrases.length)];
    await SpeechRecognitionService().speak(welcomePhrase);
  }

  // Inicia el reconocimiento de voz
  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        _speech.listen(
            localeId: 'es_MX',
            onResult: (result) {
              setState(() {
                _command = result.recognizedWords;
                _processCommand(_command);
              });
            });
      }
    }
  }

  Future<void> _loadMenu() async {
    final String response = await DefaultAssetBundle.of(context).loadString(
        'assets/recipes.json'); // Carga el menú desde un archivo JSON
    final data = json.decode(response);
    setState(() {
      menu = {
        'platillos': List<Map<String, dynamic>>.from(data['platillos']),
        'bebidas': List<Map<String, dynamic>>.from(data['bebidas']),
        'postres': List<Map<String, dynamic>>.from(data['postres']),
      };
    });
  }

  void _processCommand(String command) {
    String? platilloSeleccionado;
    String? bebidaSeleccionada;
    String? postreSeleccionado;
    String? salsaSeleccionada;
    String? tipoSeleccionado;
    String? proteinaSeleccionada;
    String? tamanioSeleccionado;
    List<String> complementosIncluidos = [];
    List<String> complementosExcluidos = [];
    List<String> toppingsSeleccionados = [];

    // Buscar en cada categoría
    if (menu['platillos'] != null) {
      for (var platillo in menu['platillos']!) {
        if (command.contains(platillo['nombre'])) {
          platilloSeleccionado = platillo['nombre'];

          // Procesar salsas
          if (platillo['salsas'] != null) {
            for (var salsa in platillo['salsas']) {
              if (command.contains(salsa)) {
                salsaSeleccionada = salsa;
                break;
              }
            }
          }

          // Procesar complementos
          if (platillo['complementos'] != null) {
            for (var complemento in platillo['complementos']) {
              if (command.contains("sin $complemento")) {
                complementosExcluidos.add(complemento);
              } else if (command.contains(complemento)) {
                complementosIncluidos.add(complemento);
              }
            }
          }

          // Procesar proteínas
          if (platillo['proteínas'] != null) {
            for (var proteina in platillo['proteínas']) {
              if (command.contains(proteina)) {
                proteinaSeleccionada = proteina;
                break;
              }
            }
          }
          break;
        }
      }
    }

    if (menu['bebidas'] != null) {
      for (var bebida in menu['bebidas']!) {
        if (command.contains(bebida['nombre'])) {
          bebidaSeleccionada = bebida['nombre'];

          // Procesar tipo de bebida
          if (bebida['tipo'] != null) {
            for (var tipo in bebida['tipo']) {
              if (command.contains(tipo)) {
                tipoSeleccionado = tipo;
                break;
              }
            }
          }

          // Procesar complementos de bebida
          if (bebida['complementos'] != null) {
            for (var complemento in bebida['complementos']) {
              if (command.contains(complemento)) {
                complementosIncluidos.add(complemento);
              }
            }
          }

          // Procesar tamaños de bebida
          if (bebida['size'] != null) {
            for (var size in bebida['size']) {
              if (command.contains(size)) {
                tamanioSeleccionado = size;
                break;
              }
            }
          }
          break;
        }
      }
    }

    if (menu['postres'] != null) {
      for (var postre in menu['postres']!) {
        if (command.contains(postre['nombre'])) {
          postreSeleccionado = postre['nombre'];

          // Procesar toppings del postre
          if (postre['toppings'] != null) {
            for (var topping in postre['toppings']) {
              if (command.contains(topping)) {
                toppingsSeleccionados.add(topping);
              }
            }
          }
          break;
        }
      }
    }

    // Muestra el resultado en pantalla o realiza una acción
    setState(() {
      _command = """
      Platillo: ${platilloSeleccionado ?? "No especificado"}
      Bebida: ${bebidaSeleccionada ?? "No especificado"}
      Postre: ${postreSeleccionado ?? "No especificado"}
      Salsa: ${salsaSeleccionada ?? "No especificado"}
      Tipo: ${tipoSeleccionado ?? "No especificado"}
      Proteína: ${proteinaSeleccionada ?? "No especificado"}
      Tamaño: ${tamanioSeleccionado ?? "No especificado"}
      Con complementos: ${complementosIncluidos.join(", ")}
      Sin complementos: ${complementosExcluidos.join(", ")}
      Toppings: ${toppingsSeleccionados.join(", ")}
      """;
    });
    print(_command);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () async {
          _startListening();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _bluetoothManager.sendData("1"),
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
                  const SizedBox(height: 100),
                  ElevatedButton(
                    onPressed: () => _bluetoothManager.sendData("2"),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {}, // Puedes añadir más funciones aquí
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
                  const SizedBox(height: 100),
                  ElevatedButton(
                    onPressed: () {}, // Puedes añadir más funciones aquí
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
