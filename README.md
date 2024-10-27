
# 🤖 ChipiBot - Your Friendly Robotic Waiter

## English

Welcome to **ChipiBot**, a revolutionary service robot designed to assist waitstaff in restaurants! ChipiBot is a **voice-controlled waiter** that takes your food orders using **speech recognition** and **text-to-speech (TTS)** technologies, sending them directly to the kitchen. A human waiter will then bring the food to your table. This project is developed with **Flutter** and will be presented at **InnovaTec** competition. 🚀

### Features ✨
- **Voice Recognition**: ChipiBot listens to your food orders.
- **TTS (Text-to-Speech)**: ChipiBot speaks back to confirm the order.
- **Order Management**: Orders are seamlessly sent to the kitchen.
- **Friendly User Interface**: Built with Flutter for cross-platform use.
  
### How it works ⚙️
1. **ChipiBot** listens when you tell it your order.
2. It confirms the order with **TTS**.
3. Sends the order to the kitchen.
4. A human waiter will deliver the food to you. 🍽️

### Installation 📲
To get started with **ChipiBot**, follow these steps:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/saidrexx/Chipi.git
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the app**:
   ```bash
   flutter run
   ```

### Tech Stack 💻
- **Flutter**: Frontend framework.
- **Voice Recognition API**: For processing voice commands.
- **TTS API**: To convert text into speech.

---

## Español

Bienvenido a **ChipiBot**, un robot de servicio revolucionario diseñado para ayudar al personal de restaurantes. ChipiBot es un **mesero controlado por voz** que toma tus órdenes de comida utilizando tecnologías de **reconocimiento de voz** y **texto a voz (TTS)**, enviándolas directamente a la cocina. Luego, un mesero humano te traerá la comida a la mesa. Este proyecto está desarrollado con **Flutter** y será presentado en la competencia **InnovaTec**. 🚀

### Funcionalidades ✨
- **Reconocimiento de voz**: ChipiBot escucha tus órdenes de comida.
- **TTS (Texto a voz)**: ChipiBot confirma tu orden hablándote.
- **Gestión de órdenes**: Las órdenes se envían directamente a la cocina.
- **Interfaz amigable**: Desarrollada con Flutter para uso multiplataforma.

### ¿Cómo funciona? ⚙️
1. **ChipiBot** escucha cuando le dices tu orden.
2. Confirma la orden usando **TTS**.
3. Envía la orden a la cocina.
4. Un mesero humano te trae la comida. 🍽️

### Instalación 📲
Para comenzar con **ChipiBot**, sigue estos pasos:

1. **Clona el repositorio**:
   ```bash
   git clone https://github.com/saidrexx/ChipiBot.git
   ```
2. **Instala las dependencias**:
   ```bash
   flutter pub get
   ```
3. **Ejecuta la app**:
   ```bash
   flutter run
   ```

### Stack Tecnológico 💻
- **Flutter**: Framework de frontend.
- **API de reconocimiento de voz**: Para procesar comandos de voz.
- **API de TTS**: Para convertir texto a voz.


### Conexion de la libreria bluetooth
   1. **Instala la dependencias **:
   ```bash
         Modulo de bluetooth
     flutter pub add flutter_bluetooth_serial
     Link-documentacion: https://pub.dev/packages/flutter_bluetooth_serial/install
        Permisos de aplicaciones
     flutter pub add permission_handler
     Link-documentacion: https://pub.dev/packages/permission_handler
  ```


### ¿Cómo funciona? ⚙️
1.- primero se tiene que configurar los xml de android para pedir los permisos y se pone que permisos va a pedir en android\app\src adentro hay tres carpetas y cada una tiene un xml y ahi se pone los permisos
2.- se configura el grandle para evitar conflitos al hora de copilarlo en android\build.gradle

de ahi ya se puede pedir permisos en y que funcione correctamente.

### ¿Cómo funciona la transferencia de datos? ⚙️

   La para detener el servomotor se programa en el arduino para que cuando reciba el dato numero 1 
   se detenga entonces en la aplicacion movil se conecta  y se programa para sincronizar el modulo 
   con el telefono con una direccion MAC  y poder enviar los datos en este caso el modulo de 
   bleuetooth esta en modo de exclavo (solo va recibir informacion) al hora que el telefono envia 
   el valor de "1" el modulo lo va recibir y va detener por 5 minutos.