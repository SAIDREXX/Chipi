import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:chipibot/constants/colors.dart';
import 'package:chipibot/constants/welcome_phrases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import './utils/tts_stt_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late stt.SpeechToText _speech; // Speech-to-Text para reconocimiento de voz
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false; // Estado de escucha
  String _command = ""; // Texto reconocido
  Map<String, List<Map<String, dynamic>>> menu = {};
  int orderNum = 0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Mantener la pantalla encendida
    _speech = stt.SpeechToText(); // Inicialización del SpeechToText
    _loadMenu();
  }

  @override
  void dispose() {
    super.dispose();
    _tts.stop();
    _speech.stop();
  }

  void _setupTTS() {
    _tts.setCompletionHandler(() {
      _startConfirmationListening();
    });
  }

  // Inicia el reconocimiento de voz
  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        _speech.listen(
            localeId: 'es_MX', // Idioma español
            onResult: (result) {
              setState(() {
                _command = result.recognizedWords;
                _processCommand(_command);
              });
            });
      }
    }
  }

  Future<void> _startConfirmationListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        _speech.listen(
          localeId: 'es_MX', // Idioma español
          onResult: (result) {
            setState(
              () {
                _command = result.recognizedWords;
                _processConfirmationCommand(_command);
              },
            );
          },
        );
      }
    }
  }

  void _processConfirmationCommand(String command) {
    if (command.contains("sí") || command.contains("correcto")) {
      _tts.speak("¡Pedido confirmado! ¡Buen provecho!");
      _tts.setCompletionHandler(() async {
        _tts.stop();
      });
    } else if (command.contains("no") || command.contains("incorrecto")) {
      _tts.speak("¡Pedido cancelado! Inténtalo de nuevo.");
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

  Future<void> _processCommand(String command) async {
    String? platilloSeleccionado;
    String? tipoPlatillo;
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
          if (platillo['tipo'] != null) {
            for (var tipo in platillo['tipo']) {
              if (command.contains(tipo)) {
                tipoPlatillo = tipo;
                break;
              }
            }
          }

          // Procesar complementos
          if (platillo['ingredientes'] != null) {
            for (var complemento in platillo['ingredientes']) {
              if (command.contains("sin $complemento") ||
                  command.contains("no $complemento") ||
                  command.contains("ni $complemento")) {
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
    setState(() async {
      List<String> elementosConfirmacion = [];

      // Analizar artículos según género y terminar con 'a'
      String articuloPara(String item) {
        if (item.endsWith("s")) {
          return item.split(" ")[0].endsWith("as") ? "unas" : "unos";
        } else {
          return item.split(" ")[0].endsWith("a") ? "una" : "un";
        }
      }

      // Confirmación de platillo
      if (platilloSeleccionado != null && platilloSeleccionado.isNotEmpty) {
        elementosConfirmacion
            .add("${articuloPara(platilloSeleccionado)} $platilloSeleccionado");
      }

      // Confirmación del tipo de platillo
      if (tipoPlatillo != null && tipoPlatillo.isNotEmpty) {
        elementosConfirmacion.add(tipoPlatillo);
      }

      // Confirmación de bebida
      if (bebidaSeleccionada != null && bebidaSeleccionada.isNotEmpty) {
        elementosConfirmacion
            .add("${articuloPara(bebidaSeleccionada)} $bebidaSeleccionada");
      }

      // Confirmación de postre
      if (postreSeleccionado != null && postreSeleccionado.isNotEmpty) {
        elementosConfirmacion
            .add("${articuloPara(postreSeleccionado)} $postreSeleccionado");
      }

      // Confirmación de salsa
      if (salsaSeleccionada != null && salsaSeleccionada.isNotEmpty) {
        elementosConfirmacion.add("con salsa $salsaSeleccionada");
      }

      // Confirmación de tipo de bebida
      if (tipoSeleccionado != null && tipoSeleccionado.isNotEmpty) {
        elementosConfirmacion.add("de tipo $tipoSeleccionado");
      }

      // Confirmación de proteína
      if (proteinaSeleccionada != null && proteinaSeleccionada.isNotEmpty) {
        elementosConfirmacion.add("con proteína de $proteinaSeleccionada");
      }

      // Confirmación del tamaño de la bebida
      if (tamanioSeleccionado != null && tamanioSeleccionado.isNotEmpty) {
        elementosConfirmacion.add("en tamaño $tamanioSeleccionado");
      }

      // Confirmación de complementos incluidos
      if (complementosIncluidos.isNotEmpty) {
        elementosConfirmacion.add("con ${complementosIncluidos.join(", ")}");
      }

      // Confirmación de complementos excluidos
      if (complementosExcluidos.isNotEmpty) {
        elementosConfirmacion.add("sin ${complementosExcluidos.join(", ni ")}");
      }

      // Confirmación de toppings seleccionados
      if (toppingsSeleccionados.isNotEmpty) {
        elementosConfirmacion
            .add("con toppings de ${toppingsSeleccionados.join(", ")}");
      }

      // Construir el mensaje final de confirmación
      String mensajeConfirmacion =
          "¿Es correcto el pedido de " + elementosConfirmacion.join(", ") + "?";

      if (_speech.isNotListening) {
        Timer(const Duration(seconds: 1), () async {
          await _tts.speak(mensajeConfirmacion);
          _setupTTS();
        });
      }
    });
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
                    onPressed: () {
                      _showFoodDialog(context);
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
                  const SizedBox(height: 100),
                  ElevatedButton(
                    onPressed: () {
                      _showDrinksDialog(context);
                    },
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
                    onPressed: () {
                      _showDessertDialog(context);
                    }, // Puedes añadir más funciones aquí
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

  void _showFoodDialog(BuildContext context) {
    Future<Map<String, dynamic>> cargarJson(BuildContext context) async {
      final String response = await DefaultAssetBundle.of(context)
          .loadString('assets/recipes.json');
      return jsonDecode(response);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: cargarJson(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (snapshot.hasError) {
              return const AlertDialog(
                content: Text("Error al cargar los datos."),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const AlertDialog(
                content: Text("No hay platillos disponibles."),
              );
            }

            final platillos = snapshot.data!['platillos'] as List<dynamic>;

            return AlertDialog(
              backgroundColor: ColorConstants.redColor,
              title: const Text(
                "Platillos",
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300, // Altura ajustada para que sea scrollable
                child: ListView.builder(
                  itemCount: platillos.length,
                  itemBuilder: (context, index) {
                    final platillo = platillos[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9999),
                            child: Image.asset(
                              platillo['imagen'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              platillo['nombre'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            "\$${platillo['precio']}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDrinksDialog(BuildContext context) {
    Future<Map<String, dynamic>> cargarJson(BuildContext context) async {
      final String response = await DefaultAssetBundle.of(context)
          .loadString('assets/recipes.json');
      return jsonDecode(response);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: cargarJson(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (snapshot.hasError) {
              return const AlertDialog(
                content: Text("Error al cargar los datos."),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const AlertDialog(
                content: Text("No hay bebidas disponibles."),
              );
            }

            final bebidas = snapshot.data!['bebidas'] as List<dynamic>;

            return AlertDialog(
              backgroundColor: ColorConstants.blueColor,
              title: const Text(
                "Bebidas",
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300, // Altura ajustada para que sea scrollable
                child: ListView.builder(
                  itemCount: bebidas.length,
                  itemBuilder: (context, index) {
                    final bebida = bebidas[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9999),
                            child: Image.asset(
                              bebida['imagen'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bebida['nombre'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            "\$${bebida['precio']}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDessertDialog(BuildContext context) {
    Future<Map<String, dynamic>> cargarJson(BuildContext context) async {
      final String response = await DefaultAssetBundle.of(context)
          .loadString('assets/recipes.json');
      return jsonDecode(response);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: cargarJson(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (snapshot.hasError) {
              return const AlertDialog(
                content: Text("Error al cargar los datos."),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const AlertDialog(
                content: Text("No hay postres disponibles."),
              );
            }

            final postres = snapshot.data!['postres'] as List<dynamic>;

            return AlertDialog(
              backgroundColor: ColorConstants.pinkColor,
              title: const Text(
                "Postres",
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300, // Altura ajustada para que sea scrollable
                child: ListView.builder(
                  itemCount: postres.length,
                  itemBuilder: (context, index) {
                    final postre = postres[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9999),
                            child: Image.asset(
                              postre['imagen'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              postre['nombre'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            "\$${postre['precio']}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              /* actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Cerrar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ], */
            );
          },
        );
      },
    );
  }
}
