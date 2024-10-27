#include <Servo.h>            // Incluye la librería Servo para controlar servomotores
#include <SoftwareSerial.h>  // Incluye la librería SoftwareSerial para comunicación serial en pines digitales

Servo servoMotor;             // Crea un objeto para controlar el servomotor
SoftwareSerial blue(2, 3);   // Inicializa SoftwareSerial: Pin 2 conectado a TX del módulo Bluetooth, Pin 3 a RX

// Configuración de nombre, baud rate y PIN para el módulo Bluetooth
char NOMBRE[21] = "CHIPI-BOT";  
char bps[] = "4";  
char pass[5] = "1234";  

String estado;                // Variable para almacenar el estado recibido
int currentAngle = 0;        // Ángulo actual del servomotor
bool isRunning = true;       // Indica si el servomotor está en movimiento
bool movingForward = true;   // Indica si el servomotor se mueve hacia adelante
unsigned long pauseStartTime = 0;  // Tiempo cuando se inicia la pausa
const unsigned long pauseDuration = 300000; // Duración de la pausa en milisegundos (5 minutos)
bool paused = false;         // Indica si el movimiento está en pausa

void setup() {  
  blue.begin(9600);          // Inicia la comunicación con el módulo Bluetooth a 9600 bps
  Serial.begin(9600);       // Inicia la comunicación serie a 9600 bps para el monitor serie
  servoMotor.attach(6);     // Conecta el servomotor al pin 6
  servoMotor.write(currentAngle); // Establece la posición inicial del servomotor
  
  //--IMPORTANTE ESTE CODIGO NADA MAS SE EJECUTA UNA VEZ POR LA MISMA RAZON QUE UTILIZAMOS EL MODULO DE BLUETOOTH POR SOFTWARE 
  // Configuración del módulo Bluetooth
  //blue.print("AT");          // Envía el comando AT para comprobar la conexión
  //delay(1000);  
  //blue.print("AT+NAME=");    // Establece el nombre del dispositivo Bluetooth
  //blue.print(NOMBRE);  
  //delay(1000);  
  //blue.print("AT+BAUD=");    // Establece la velocidad de baudios
  //blue.print(bps);  
  //delay(1000);  
  //blue.print("AT+PIN=");      // Establece el PIN para el emparejamiento
  //blue.print(pass);  
  //delay(1000);  
}

void loop() {  
  delay(10);  // Espera un breve momento para no saturar el bucle
  
  // Comprueba si hay datos disponibles desde el módulo Bluetooth
  while (blue.available()) {    
    char valor = blue.read();  // Lee el valor recibido
    int valorint = valor - '0'; // Convierte el carácter a entero
    
    // Si el valor recibido es '1', inicia la pausa
    if (valorint == 1) {      
      isRunning = false;      
      paused = true;  // Inicia la pausa
      pauseStartTime = millis(); // Guarda el tiempo actual
      servoMotor.write(currentAngle); // Mantiene la posición actual del servomotor
    } else {      
      estado += valor;  // Acumula el estado recibido
    }  
  }  

  // Verifica si está en pausa
  if (paused) {
    // Verifica si ha pasado el tiempo de pausa
    if (millis() - pauseStartTime >= pauseDuration) {
      paused = false;  // Termina la pausa
      isRunning = true; // Reinicia el movimiento del servomotor
    }
  } else if (isRunning) {    
    // Controla el movimiento del servomotor
    if (movingForward) {      
      currentAngle++;      // Incrementa el ángulo
      if (currentAngle >= 180) movingForward = false;  // Cambia de dirección al alcanzar el límite
    } else {      
      currentAngle--;      // Decrementa el ángulo
      if (currentAngle <= 0) movingForward = true;     // Cambia de dirección al alcanzar el límite
    }    
    servoMotor.write(currentAngle);  // Establece la nueva posición del servomotor
    delay(15);  // Espera para permitir que el servomotor se mueva
  }
}

