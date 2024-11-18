import 'dart:async';
import 'dart:convert';
import 'package:chipibot/bluetooth/bluetooth_connection.dart';
import 'package:chipibot/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BluetoothConnectionManager _bluetoothManager =
      BluetoothConnectionManager();
  final String chipiBotAddress =
      "98:DA:20:07:F0:45"; // LA DIRECCION DEL MODULO HC-06
  //azul "98:DA:60:03:A8:8C"
  //naranja "00:21:13:00:15:3B"

  late stt.SpeechToText _speech; // Speech-to-Text para reconocimiento de voz
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false; // Estado de escucha
  String _command = ""; // Texto reconocido
  Map<String, List<Map<String, dynamic>>> menu = {};
  int orderNum = 0;
  List<int> precioOrdenGlobal = [];
  Map<String, dynamic> ordenFinalGlobal = {
    "platillos": [],
    "bebidas": [],
    "postres": [],
  };

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Mantener la pantalla encendida
    _speech = stt.SpeechToText(); // Inicialización del SpeechToText
    _tts.setLanguage('es-MX'); // Establecer idioma español
    _loadMenu();
    _bluetoothManager.checkPermissions();
    _bluetoothManager.connectToDevice(chipiBotAddress);
  }

  @override
  void dispose() {
    super.dispose();
    _tts.stop();
    _speech.stop();
    _bluetoothManager.disconnect();
  }

  void _setupTTS(Map<String, dynamic> ordenFinal, List<int> precioOrden) {
    _tts.setCompletionHandler(() {
      _startConfirmationListening(ordenFinal, precioOrden);
    });
  }

  Future<void> enviarCorreo({
    required String nombre,
    required String email,
    required String mensaje,
  }) async {
    const serviceId = 'service_xxw6ppg'; // Reemplaza con tu Service ID
    const templateId = 'template_h7gwr4e'; // Reemplaza con tu Template ID
    const publicKey = 'pYwocbx0uRr88L-Ri'; // Reemplaza con tu Public Key

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'user_name': nombre,
          'user_email': email,
          'user_message': mensaje,
        },
      }),
    );

    if (response.statusCode == 200) {
      print("Correo enviado exitosamente");
    } else {
      print("Error al enviar correo: ${response.body}");
    }
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
            });

            if (_command.contains("cancelar") ||
                _command.contains("salir") ||
                _command.contains("cerrar")) {
              _speech.stop();
              _tts.speak(
                  "Entendido, toca la pantalla cuando estés listo para ordenar");
              _tts.setCompletionHandler(() {
                _tts.stop();
              });
            } else {
              _processCommand(_command);
            }
          },
        );
      }
    }
  }

  Future<void> _startConfirmationListening(
      Map<String, dynamic> ordenFinal, List<int> precioOrden) async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        _speech.listen(
          localeId: 'es_MX', // Idioma español
          onResult: (result) {
            setState(
              () {
                _command = result.recognizedWords;
                _processConfirmationCommand(_command, ordenFinal, precioOrden);
              },
            );
          },
        );
      }
    }
  }

  void _addOrderToCart(Map<String, dynamic> ordenFinal) async {
    // Cargar el archivo JSON con los menús
    final String response =
        await DefaultAssetBundle.of(context).loadString('assets/recipes.json');
    final menu = json.decode(response);

    // Resultado con detalles
    List<Map<String, dynamic>> detallesOrden = [];

    // Buscar detalles de los platillos seleccionados
    for (var platillo in ordenFinal["platillos"]) {
      var platilloItem = menu['platillos'].firstWhere(
        (element) => element['nombre'] == platillo['nombre'],
        orElse: () => null,
      );
      if (platilloItem != null) {
        detallesOrden.add({
          'nombre': platilloItem['nombre'],
          'imagen': platilloItem['imagen'],
          'precio': platilloItem['precio']
        });
      }
    }

    // Buscar detalles de las bebidas seleccionadas
    for (var bebida in ordenFinal["bebidas"]) {
      var bebidaItem = menu['bebidas'].firstWhere(
        (element) => element['nombre'] == bebida['nombre'],
        orElse: () => null,
      );
      if (bebidaItem != null) {
        detallesOrden.add({
          'nombre': bebidaItem['nombre'],
          'imagen': bebidaItem['imagen'],
          'precio': bebidaItem['precio']
        });
      }
    }

    // Buscar detalles de los postres seleccionados
    for (var postre in ordenFinal["postres"]) {
      var postreItem = menu['postres'].firstWhere(
        (element) => element['nombre'] == postre['nombre'],
        orElse: () => null,
      );
      if (postreItem != null) {
        detallesOrden.add({
          'nombre': postreItem['nombre'],
          'imagen': postreItem['imagen'],
          'precio': postreItem['precio']
        });
      }
    }

    // Obtener la ruta del directorio donde se guardarán los datos
    final Directory? directory = await getDownloadsDirectory();
    final filePath = '${directory!.path}/ordenes.json';
    final file = File(filePath);

    // Leer el archivo existente (si existe)
    List<dynamic> ordenesExistentes = [];
    if (await file.exists()) {
      String content = await file.readAsString();
      ordenesExistentes = json.decode(content);
    }

    // Agregar la nueva orden a las órdenes existentes
    ordenesExistentes.add({
      'detalles': detallesOrden,
    });

    // Guardar las órdenes actualizadas en el archivo
    await file.writeAsString(json.encode(ordenesExistentes),
        mode: FileMode.write);

    // Mostrar la orden agregada (o hacer algo más con ella)
  }

  void _processConfirmationCommand(
      String command, Map<String, dynamic> ordenFinal, List<int> precioOrden) {
    if (command.contains("sí") || command.contains("correcto")) {
      if (_speech.isNotListening) {
        _tts.speak(
            "¡Pedido confirmado! Vaya a su carrito para realizar su orden");
        _tts.setCompletionHandler(() {
          _tts.stop();
        });
      }

      _tts.setCompletionHandler(() async {
        _tts.stop();
        setState(() {
          ordenFinalGlobal = ordenFinal;
          precioOrdenGlobal = precioOrden;
        });
        _addOrderToCart(ordenFinal);
      });
    } else if (command.contains("no") || command.contains("incorrecto")) {
      if (_speech.isNotListening) {
        _tts.speak("¡Pedido cancelado! Inténtalo de nuevo.");
        _tts.setCompletionHandler(() {
          _tts.stop();
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
    List<String> complementosIncluidosBebidas = [];
    List<String> complementosExcluidosBebidas = [];
    List<String> toppingsSeleccionados = [];
    List<int> precioOrden = [];
    List<Map<String, dynamic>> platillosSeleccionados = [];
    List<Map<String, dynamic>> bebidasSeleccionadas = [];
    List<Map<String, dynamic>> postresSeleccionados = [];
    Map<String, dynamic> ordenFinal = {
      "platillos": [],
      "bebidas": [],
      "postres": [],
    };

    // Buscar en cada categoría
    if (menu['platillos'] != null) {
      for (var platillo in menu['platillos']!) {
        if (command.contains(platillo['nombre'])) {
          platilloSeleccionado = platillo['nombre'];
          precioOrden.add(platillo['precio']);

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
          precioOrden.add(bebida['precio']);

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
              if (command.contains("sin $complemento") ||
                  command.contains("no $complemento") ||
                  command.contains("ni $complemento")) {
                complementosExcluidosBebidas.add(complemento);
              } else if (command.contains(complemento)) {
                complementosIncluidosBebidas.add(complemento);
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
          precioOrden.add(postre['precio']);

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
      // Confirmación de salsa
      if (salsaSeleccionada != null && salsaSeleccionada.isNotEmpty) {
        elementosConfirmacion.add("con salsa $salsaSeleccionada");
      }

      // Confirmación de complementos incluidos
      if (complementosIncluidos.isNotEmpty) {
        elementosConfirmacion.add("con ${complementosIncluidos.join(", ")}");
      }

      // Confirmación de complementos excluidos
      if (complementosExcluidos.isNotEmpty) {
        elementosConfirmacion.add("sin ${complementosExcluidos.join(", ni ")}");
      }

      // Confirmación de proteína
      if (proteinaSeleccionada != null && proteinaSeleccionada.isNotEmpty) {
        elementosConfirmacion.add("con proteína de $proteinaSeleccionada");
      }
      // Confirmación de bebida
      if (bebidaSeleccionada != null && bebidaSeleccionada.isNotEmpty) {
        elementosConfirmacion
            .add("${articuloPara(bebidaSeleccionada)} $bebidaSeleccionada");
      }
      // Confirmación de tipo de bebida
      if (tipoSeleccionado != null && tipoSeleccionado.isNotEmpty) {
        elementosConfirmacion.add("de tipo $tipoSeleccionado");
      }
      // Confirmación de complementos incluidos
      if (complementosIncluidosBebidas.isNotEmpty) {
        elementosConfirmacion
            .add("con ${complementosIncluidosBebidas.join(", ")}");
      }

      if (complementosExcluidosBebidas.isNotEmpty) {
        elementosConfirmacion
            .add("sin ${complementosExcluidosBebidas.join(", ")}");
      }

      // Confirmación del tamaño de la bebida
      if (tamanioSeleccionado != null && tamanioSeleccionado.isNotEmpty) {
        elementosConfirmacion.add("en tamaño $tamanioSeleccionado");
      }

      // Confirmación de postre
      if (postreSeleccionado != null && postreSeleccionado.isNotEmpty) {
        elementosConfirmacion
            .add("${articuloPara(postreSeleccionado)} $postreSeleccionado");
      }

      // Confirmación de toppings seleccionados
      if (toppingsSeleccionados.isNotEmpty) {
        elementosConfirmacion
            .add("con toppings de ${toppingsSeleccionados.join(", ")}");
      }

      // Construcción de platillos
      if (platilloSeleccionado != null && platilloSeleccionado.isNotEmpty) {
        platillosSeleccionados.add({
          "nombre": platilloSeleccionado,
          if (tipoPlatillo != null && tipoPlatillo.isNotEmpty)
            "tipo": tipoPlatillo,
          if (salsaSeleccionada != null && salsaSeleccionada.isNotEmpty)
            "salsa": salsaSeleccionada,
          if (proteinaSeleccionada != null && proteinaSeleccionada.isNotEmpty)
            "proteína": proteinaSeleccionada,
          if (complementosIncluidos.isNotEmpty)
            "complementos_incluidos": complementosIncluidos,
          if (complementosExcluidos.isNotEmpty)
            "complementos_excluidos": complementosExcluidos,
        });
      }

      // Construcción de bebidas
      if (bebidaSeleccionada != null && bebidaSeleccionada.isNotEmpty) {
        bebidasSeleccionadas.add({
          "nombre": bebidaSeleccionada,
          if (tipoSeleccionado != null && tipoSeleccionado.isNotEmpty)
            "tipo": tipoSeleccionado,
          if (tamanioSeleccionado != null && tamanioSeleccionado.isNotEmpty)
            "tamaño": tamanioSeleccionado,
          if (complementosIncluidosBebidas.isNotEmpty)
            "complementos_incluidos": complementosIncluidosBebidas,
          if (complementosExcluidosBebidas.isNotEmpty)
            "complementos_excluidos": complementosExcluidosBebidas,
        });
      }

      // Construcción de postres
      if (postreSeleccionado != null && postreSeleccionado.isNotEmpty) {
        postresSeleccionados.add({
          "nombre": postreSeleccionado,
          if (toppingsSeleccionados.isNotEmpty)
            "toppings": toppingsSeleccionados,
        });
      }

      // JSON Final
      ordenFinal = {
        "platillos": platillosSeleccionados,
        "bebidas": bebidasSeleccionadas,
        "postres": postresSeleccionados,
      };

      // Construir el mensaje final de confirmación
      String mensajeConfirmacion =
          "¿Es correcto el pedido de ${elementosConfirmacion.join(", ")}?. De ser así, el precio sería de ${precioOrden.fold(0, (a, b) => a + b)} pesos. ¿Desea confirmar su pedido?";
      print("La orden final es: $ordenFinal");
      print("el total es: ${precioOrden.fold(0, (a, b) => a + b)}");
      if (_speech.isNotListening) {
        Timer(const Duration(seconds: 1), () async {
          await _tts.speak(mensajeConfirmacion);
          _setupTTS(ordenFinal, precioOrden);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () async {
          _bluetoothManager.sendData("1");
          _tts.speak("¡Hola! ¡Bienvenido! ¿Quiere ordenar algo?");
          _tts.setCompletionHandler(() {
            _startListening();
          });
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
                    onPressed: () {
                      _showCartDialog(context);
                    }, // Puedes añadir más funciones aquí
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
                height: 300,
                child: ListView.builder(
                  itemCount: platillos.length,
                  itemBuilder: (context, index) {
                    final platillo = platillos[index];
                    return GestureDetector(
                      onTap: () {
                        // Crear una orden con el elemento seleccionado
                        Map<String, dynamic> ordenSeleccionada = {
                          "platillos": [
                            {
                              "nombre": platillo['nombre'],
                            }
                          ],
                          "bebidas": [],
                          "postres": [],
                        };
                        setState(() {
                          precioOrdenGlobal.add(platillo['precio']);
                          ordenFinalGlobal["platillos"].add({
                            "nombre": platillo['nombre'],
                          });
                        });

                        // Llamar a _addOrderToCart
                        _addOrderToCart(ordenSeleccionada);

                        // Cerrar el diálogo
                        Navigator.pop(context);
                      },
                      child: Padding(
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
                height: 300,
                child: ListView.builder(
                  itemCount: bebidas.length,
                  itemBuilder: (context, index) {
                    final bebida = bebidas[index];
                    return GestureDetector(
                      onTap: () {
                        // Crear una orden con la bebida seleccionada
                        Map<String, dynamic> ordenSeleccionada = {
                          "platillos": [],
                          "bebidas": [
                            {
                              "nombre": bebida['nombre'],
                            }
                          ],
                          "postres": [],
                        };
                        setState(() {
                          precioOrdenGlobal.add(bebida['precio']);
                          ordenFinalGlobal["bebidas"].add({
                            "nombre": bebida['nombre'],
                          });
                        });

                        // Llamar a _addOrderToCart
                        _addOrderToCart(ordenSeleccionada);

                        // Cerrar el diálogo
                        Navigator.pop(context);
                      },
                      child: Padding(
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
                height: 300,
                child: ListView.builder(
                  itemCount: postres.length,
                  itemBuilder: (context, index) {
                    final postre = postres[index];
                    return GestureDetector(
                      onTap: () {
                        // Crear una orden con el postre seleccionado
                        Map<String, dynamic> ordenSeleccionada = {
                          "platillos": [],
                          "bebidas": [],
                          "postres": [
                            {
                              "nombre": postre['nombre'],
                            }
                          ],
                        };
                        setState(() {
                          precioOrdenGlobal.add(postre['precio']);
                          ordenFinalGlobal["postres"].add({
                            "nombre": postre['nombre'],
                          });
                        });

                        // Llamar a _addOrderToCart
                        _addOrderToCart(ordenSeleccionada);

                        // Cerrar el diálogo
                        Navigator.pop(context);
                      },
                      child: Padding(
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

  void _showCartDialog(BuildContext context) async {
    // Función para leer el archivo JSON con las órdenes guardadas
    Future<List<dynamic>> cargarOrdenes() async {
      final Directory? directory = await getDownloadsDirectory();
      final filePath = '${directory!.path}/ordenes.json';
      final file = File(filePath);

      // Verificar si el archivo existe
      if (await file.exists()) {
        // Si existe, leer el contenido y decodificarlo
        String content = await file.readAsString();
        return json.decode(content);
      } else {
        // Si no existe, retornar una lista vacía
        return [];
      }
    }

    // Función para vaciar el archivo de órdenes
    Future<void> vaciarOrdenes() async {
      final totalOrden = precioOrdenGlobal.fold(0, (a, b) => a + b);
      // Lista para construir la salida
      List<String> resultadoFinal = [];

      // Procesar platillos
      if (ordenFinalGlobal["platillos"] != null) {
        resultadoFinal.add("Platillos:");
        for (var platillo in ordenFinalGlobal["platillos"]) {
          String detalle = "   ${platillo["nombre"]}";
          if (platillo.containsKey("tipo")) {
            detalle += "\n    Tipo: ${platillo["tipo"]}";
          }

          if (platillo.containsKey("salsa")) {
            detalle += "\n    Salsa: ${platillo["salsa"]}";
          }

          if (platillo.containsKey("proteína")) {
            detalle += "\n    Proteína: ${platillo["proteína"]}";
          }

          if (platillo.containsKey("complementos_incluidos")) {
            detalle +=
                "\n    Con: ${platillo["complementos_incluidos"].join(", ")}";
          }
          if (platillo.containsKey("complementos_excluidos")) {
            detalle +=
                "\n    Sin: ${platillo["complementos_excluidos"].join(", ")}";
          }
          resultadoFinal.add(detalle);
        }
      }

      // Procesar bebidas
      if (ordenFinalGlobal["bebidas"] != null) {
        resultadoFinal.add("Bebidas:");
        for (var bebida in ordenFinalGlobal["bebidas"]) {
          String detalle = "  -${bebida["nombre"]}";
          if (bebida.containsKey("tipo")) {
            detalle += "\n    Tipo: ${bebida["tipo"]}";
          }

          if (bebida.containsKey("tamaño")) {
            detalle += "\n    Tamaño: ${bebida["tamaño"]}";
          }

          if (bebida.containsKey("complementos_incluidos")) {
            detalle +=
                "\n    Con: ${bebida["complementos_incluidos"].join(", ")}";
          }
          if (bebida.containsKey("complementos_excluidos")) {
            detalle +=
                "\n    Sin: ${bebida["complementos_excluidos"].join(", ")}";
          }
          resultadoFinal.add(detalle);
        }
      }

      // Procesar postres
      if (ordenFinalGlobal["postres"] != null) {
        resultadoFinal.add("Postres:");
        for (var postre in ordenFinalGlobal["postres"]) {
          String detalle = "   ${postre["nombre"]}";
          if (postre.containsKey("toppings")) {
            detalle += "\n    Toppings: ${postre["toppings"].join(", ")}";
          }
          resultadoFinal.add(detalle);
        }
      }

      enviarCorreo(
        nombre: "Encargados de Cocina",
        email: "cocina@example.com",
        mensaje: """
          ¡Hola equipo de cocina!

          Han recibido una nueva orden para preparar. A continuación, los detalles:

          Detalles de la Orden:
          ${resultadoFinal.join("\n- ")}

          Total de la Orden: $totalOrden MXN

          Por favor, preparen esta orden lo más pronto posible y confirmen cuando esté lista.

          Gracias por su dedicación.

          Saludos,
          ChipiBot
          """,
      );
      final Directory? directory = await getDownloadsDirectory();
      final filePath = '${directory!.path}/ordenes.json';
      final file = File(filePath);

      // Sobrescribir el archivo con una lista vacía
      if (await file.exists()) {
        await file.writeAsString(json.encode([]));
        setState(() {
          ordenFinalGlobal = {
            "platillos": [],
            "bebidas": [],
            "postres": [],
          };
          precioOrdenGlobal = [];
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<dynamic>>(
          future: cargarOrdenes(),
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
                content: Text("Error al cargar el carrito."),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              // Si no hay datos en el carrito, mostrar mensaje vacío
              return const AlertDialog(
                content: Text("Carrito Vacío"),
              );
            }

            // Si hay datos, construir la lista de órdenes
            final ordenes = snapshot.data!;

            return AlertDialog(
              backgroundColor: ColorConstants.greenColor,
              title: const Text(
                "Carrito de Compras",
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300, // Altura ajustada para que sea scrollable
                child: ListView.builder(
                  itemCount: ordenes.length,
                  itemBuilder: (context, index) {
                    final orden = ordenes[index];
                    final detalles = orden['detalles'] as List<dynamic>;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          // Listar los detalles de la orden
                          ...detalles.map(
                            (detalle) {
                              return Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(9999),
                                    child: Image.asset(
                                      detalle['imagen'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      detalle['nombre'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "\$${detalle['precio']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                // Botón Pagar
                TextButton(
                  onPressed: () async {
                    // Vaciar el archivo de órdenes
                    await vaciarOrdenes();
                    // Cerrar el diálogo
                    Navigator.of(context).pop();
                    // Mostrar un mensaje de confirmación (opcional)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Orden enviada a cocina exitosamente."),
                      ),
                    );
                  },
                  child: const Text(
                    "Confirmar Orden",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
