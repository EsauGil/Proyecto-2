import processing.serial.*;  // Libreria para el uso del puerto serial
//import processing.sound.*;   // Libreria para el uso de archivos .mp3, wav, entre otros

//SoundFile sonido;    // variable que guarda el directorio del archivo de sonido a usar - no usado por problemas de lentitud con la app

boolean pulso = false;   // booleano que permite indicar si hay o no un pulso (se activa con flancos de subida y se resetea con flancos de bajada)
boolean luz = false;     // booleano indicativo de si la luz esta o no activada en la habitacion del paciente
boolean boton = false;   // booleano que permite indicar si hay o no un pulso (se activa con flancos de subida y se resetea con flancos de bajada), se usa para el switch de luz
boolean caido;           // booleano que permite que el estado de caido del paciente de ser positivo se mantenga aun cuando el acelerometro se estabilice

int ReX, ReY;          // variable de la posicion boton de reset
int ReSize = 30;       // variable del tamano del boton de reset
int Recolor;           // variable del color del boton de reset
int HRe;               // variable del color del boton reset cuando el puntero del raton se situa sobre este
boolean Reover;        // booleano indicativo si el boton ha sido o no presionado


byte[] leer;        // arreglo donde se va a guardar la data recibida por puerto serial
int[] canal;        // arreglo que va a guardar la data desempaquetada.
int [] analog1;     // arreglo respectivo al canal analogico 1
int [] digital1;    // arreglo respectivo al canal digital 1
int [] digital2;    // arreglo respectivo al canal digital 2

int habitacion;     // variable usada para determinar si dentro de los parametros asignados hay un paciente o no en la habitacion
int caida;          // variable usada para determinar si dentro de los parametros el paciente sufrio o no una caida
int i = 0;          // variable usada como indice del espacio de lso arreglos a ser llenado
int j = 0;          // variable de control que nos indica cuando ya la data acomulada esta lista para mostrar y permite habilitar o inhabilitar la recepciop por puerto serial
int k = 0;          // variable que permite determinar el ancho del pulso de sensor del ultra sonido usado para determinar distancias

PImage screen;              // variable que guarda una imagen en este caso la pantalla de la aplicacion
PFont mono, mono1, mono2;   // variable de tipo de letra usado en la interfaz de usuario de la app

Serial myPort;  // Crea un objeto de clase serial

void setup() {
  
  //sonido = new SoundFile(this, "MARCH-MT.WAV");
  
  mono = loadFont("Arial-Black-20.vlw");       // se carga el tipo de letra a la variable
  mono1 = loadFont("Arial-Black-12.vlw");      // se carga el tipo de letra a la variable
  mono2 = loadFont("Arial-Black-15.vlw");      // se carga el tipo de letra a la variable
  
  size(500, 600);      // Tamano de la pantalla de la app anchoxlargo
  background(#FFFFFF); // Fondo color blanco
  pantalla();          // llamado a la funcion pantalla
  
  ReX = 250;
  ReY = 500;

  Recolor = color(255,50,50);     // Color del boton de reset
  HRe = color(150);               // Color del boton cuando el cursor esta encima de este
  
  fill(#2088C6);
  textFont(mono);
  text("Medical Security",160,30);  
 
  fill(#2088C6);
  textFont(mono1);
  text("Acompañante médico - 01",320,585); 
  
  fill(#2088C6);
  textFont(mono1);
  text("ER instruments",10,585);
  
  fill(#2088C6);
  textFont(mono2);
  text("Luces habitación:",50,350);

  fill(#2088C6);
  textFont(mono2);
  text("Paciente sufrió caida:",50,400);
  
  fill(#2088C6);
  textFont(mono2);
  text("Habitación ocupada:",50,450);
  screen = get(0,0,500,600); 
  
                                     // Aqui se define el tamano de los arreglos a usar
  leer = new byte[3]; 
  canal = new int[3];
  analog1 = new int[500];
  digital1 = new int[500];
  digital2 = new int[500];
                                     
                                     // Se define las caracteristicas del receptor de puerto serial y su tasa de baudios
                                     
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 115200);
  myPort.buffer(50);                 // se le asigna un buffer a la variable del puerto serial, con el fin de que se tenga en todo momento data para procesar
  image(screen,0,0);                 // imprimo la pantalla
  
  sensor_swith();                 // Pongo en pantalla el estado del sensor del switch (digital 2)
  sensor_acelerometro();          // Pongo en pantalla el estado del sensor del switch (analogico 1) 
  sensor_ultrasonido();           // Pongo en pantalla el estado del sensor del switch (digital 1)
  
}

void draw(){                      // main del processing, esta funcion cicla indefinidamente cada vez que llega al final
  
  if(j == 1){                     // condicion que activa la graficacion de la data del canala analogico y detiene la recepcion de data de puerto serial
    
    image(screen,0,0);            // Limpia la pantalla
    
    sensor_swith();                 // Pongo en pantalla el estado del sensor del switch (digital 2)
    sensor_acelerometro();          // Pongo en pantalla el estado del sensor del switch (analogico 1) 
    sensor_ultrasonido();           // Pongo en pantalla el estado del sensor del switch (digital 1)
    
    Analog1();                     // grafico la senal del acelerometro
    //Digital1();                  // grafico la senal digital 1 - no usado para este projecto
    //Digital2();                  // grafico la senal digital 2 - no usado para este projecto
    
    // print(" pulso = "+ k +" "); // print de prueba para poder saber la anchura del pulso que nos permite determinar la distancia del obstaculo que tenga en frente
    
    i = 0;                         // reinicio de la variable de control i
    j = 0;                         // reinicio de la variable de control j
    k = 0;                         // reinicio de la variable de control k
  }
}

void serialEvent(Serial myPort) {              // Funcion de interrupcion por puerto serial - cada vez que llega data nueva entra a esta interrupcion

 if ((myPort.available() > 0) && (j == 0)) {   // Determinacion de que myPort tiene data disponible, lo deshabilito cuando ya tengo data para mostrar
    do {
    leer[0] = byte(myPort.read());             // Confirmo que la data actual sea la cabecera al compararlo con 10000000 (127 en decimal)
    } while (int(leer[0]) < 127);
    leer[1] = byte(myPort.read());             // Al cumplirse lo anterior los dos bytes siguientes de data son los que le siguen en la cadena del protocolo de comunicacion
    leer[2] = byte(myPort.read());             
 } 
 if (j == 0){
    Desempaquetado();                          // Llamado a la funcion de desempaquetado
    //print(" ( "+ int(leer[0]) + " "+ int(leer[1]) +" "+ int(leer[2]) +" ) ");  // print de prueba que nos permitio ver que nos llegaba bien la data (se usaron valore constantes desde el DEMOQE
 } 
 
}

void mousePressed() {            // Funcion que comprueba que boton ha sido presionado y su efecto
  
  if (Reover) {                  // Comprobacion de que el boton del mouse fue presionado encima del boton del canal analogico 1
      caido = false;             // con esto se reinicia la bandera de caido
  }
}

boolean overCircle(int x, int y, int diameter) {    //  Funcion que le permite identificar si el puntero esta sobre uno de los botones
  float disX = x - mouseX;
  float disY = y - mouseY;
  if (sqrt(sq(disX) + sq(disY)) < diameter/2 ) {
    return true;
  } else {
    return false;
  }
}

void update(int x, int y) {                      // Funcion que permite comprobar la posicion del puntero del raton respecto al area de los botones
  if ( overCircle(ReX, ReY, ReSize) ) {
    Reover = true;
  } else
    Reover = false;
}  

void Estatus_botones_puntero(){

  update(mouseX, mouseY);       // Comprueba el estado de la posicion del puntero respecto a los botones
  
 // seccion para el dibujo de los botones
  
  if (Reover) {                                  // condicion que verifica si el puntero del raton esta sobre el boton o no, para determinar si usar el color del boton estandar o el highligthed
    fill(HRe);
  } else {
    fill(Recolor);
  }
  stroke(0);
  ellipse(ReX, ReY, ReSize, ReSize);
}


void Desempaquetado() {                         // funcion que nos permite desempaquetar la data recibida del puerto serial, para su posterior uso
  
  int[] aux = new int[2];                       // defino una variable auxiliar para el proceso desempaquetado
  
  aux[0] = int(leer[0]);                        // aux[0] = leer[0] en valor entero, ya que leer[i] es una variable tipo char
  aux[0] = int(byte(aux[0]) << byte(10));       // aux[0] = aux[0] shifteado a la izquierda 10 bits
  aux[0] = aux[0] & 64512;                      // hago un AND de aux[0] con 111111000000000, para aislar la data del canal y hacer lo demas 0
  aux[1] = int(leer[1] << byte(5)) & byte(992); // aux[1] = leer[1] en valor entero, shifteado 5 bytes a la izquierda y con un AND de 1111100000 (992 en decimal)
  aux[0] = aux[0] | aux[1];                     // aux[0] = aux[0] con un OR con aux[1]
  aux[0] = aux[0] | leer[2];                    // aux[0] = aux[0] con un OR con leer[2]
  canal[0] = aux[0]/655;                        // con esto escalo el valor de aux que y lo guardo en la variable canal[0] que tiene la data del cana analogico
  
  aux[0] = int(leer[1] & byte(64))/64;   // aux[0] = leer[1] en entero y con un AND con 1000000 (64 en decimal)
  canal[1] = aux[0]*75;                  // Canal Digital 1 listo
  
  aux[0] = int(leer[1] & byte(32))/32;   // aux[0] = leer[1] en entero y con un AND con 100000 (32 en decimal)
  canal[2] = aux[0]*75;                  // Canal Digital 2 listo
  
  analog1[i] = canal[0];                 // Guardo los datos desempaquetados en sus respectivas variables para graficar 
  digital1[i] = canal[1]; 
  digital2[i] = canal[2]; 
  
  // print(" ( "+ int(canal[0])*2 +" ) ");  // print para determinar que el valor desempaquetado del canal analogico era el correcto enviando valores constantes desde el DEMOQE
  
  i = i + 1;                                
  
  caida = canal[0]*2;                       // caida guarda los que llegan del acelerometro
  
//////////////////////////////////////////////////////  
  if((canal[1] == 0) && (pulso == false)){  // verifico si ha habido un cambio de flanco de subida del canal digital 1 
    k = k + 1;                              // esta variable me permite determinar el ancho del pulso
    pulso = true;                           // activo la condicion de que ha llegado un pulso
  } 
  
  if((canal[1] == 0) && (pulso == true)){   // sigue en la parte alta el canal digital 1
    k = k + 1;
  }
  
  if((canal[1] == 75) && (pulso == true)){  // con esto determino que hay un flanco de bajada y por ende un fin del pulso
    pulso = false;                          // desactivo la condicion de pulso
    habitacion = k;                         // la variable habitacion obtiene el tamano del pulso usado para determinar la distancia del obtaculo (de haber)
  }
//////////////////////////////////////////////////  
  if((canal[2] == 75) && (boton == false)){ // verifico si ha habido un cambio de flanco de subida del canal digital 2 
    boton = true;                           // activo la condicion de que ha llegado un pulso
  } 
  
  if((canal[2] == 0) && (boton == true)){   // condicion que me determina el flanco de bajada o fin del pulso
    boton = false;                          // desactivo la condicion de que ha llegado un pulso
    if(luz == false){                       // cambio el estado de luz
      luz = true;
    }else if(luz == true){
      luz = false;
    }
  }
//////////////////////////////////////////////////  
  
  if (i > 499) {                         // Condicion que define cuando ya este lleno el vector para graficar
     j = 1;                              // Variable de control que me permite graficar en pantalla los canales activos y detiene la recepcion de datos 
   }
  
}

void pantalla() {                       // funcion que disena la pantalla donde se planea graficar las senales a usar en el projecto
  stroke(255);
  fill(0);
  rect(0,50,500,200);
  
  for (int y = 50; y <= 250; y += 25) {
      stroke(50);
      line(0,y,500,y);
  }   

  for (int x = 0; x <= 500; x += 50) {
      stroke(50);
      line(x,50,x,250);
  } 
  
  stroke(150);
  line(250,50,250,250);
  
  stroke(150);
  line(0,200,500,200); 
}

void Analog1() {                                                   // funcion encargada de graficar el canal analogico con los valores guardados en el arreglo
  for (int x = 0; x < 499; x += 1)  {
       stroke(color(200,0,0));
       if (x < 500)
        line(x, 200 - analog1[x]*2, (x+1), 200 - analog1[(x+1)]*2); 
           }
}    

void Digital1() {                                                  // funcion encargada de graficar el canal digital 1 con los valores guardados en el arreglo - no se uso para este projecto
  for (int x = 0; x < 499; x += 1)  {
       stroke(color(200,0,200));
       if (x < 500)
       line(x, 200 - digital1[x], (x+1), 200 - digital1[(x+1)]); 
           }
}

void Digital2() {                                                  // funcion encargada de graficar el canal digital 2 con los valores guardados en el arreglo - no se uso para este projecto
  for (int x = 0; x < 499; x += 1)  {
       stroke(color(0,200,200));
       if (x < 500)
       line(x, 200 - digital2[x], (x+1), 200 - digital2[(x+1)]); 
           }
}

/////////////////////////////////

void sensor_swith(){          // funcion usada para determinar el estado de las luces de la habitacion del paciente, dicha informacion se muestra en la app

  if(luz == true){
    fill(#2CFF7E);
    textFont(mono2);
    text("On",300,350);
    luz = true;
  }

  if(luz == false){ 
    fill(#F72020);
    textFont(mono2);
    text("Off",300,350); 
    luz = false;
  }
 
}

void sensor_acelerometro(){

  if((caida < 63) || (caido == true)){  // funcion que determina el estado de caido o no del paciente, el 63 representa un valor de referencia obtenido experimentalmente
    fill(0xffF72020);
    textFont(mono2);
    text("Si",300,400);
    if(caido == false)                  
      //sonido.play();                  // funcion usada para reproducir un sonido de alarma cuando el paciente de cayera, fue deshabilitada por la lentitud que presentaba la app
    caido = true;                       // la bandera de caido es usada para que el estatus de caido quede mostrado aun si los valores del acelerometro vuelven a la normalidad (mayor a 63)
  }
  else if((caida > 63) && (caido == false)){  
  fill(0xff2CFF7E);
  textFont(mono2);
  text("No",300,400); 
  }

}


void sensor_ultrasonido(){       // funcion que verifica el estado del ultra sonido para determinar si hay o no presencia (si hay un obtaculo a menos de 2m o no)
  if(habitacion < 24){           // comprueba el ancho del pulso con el valor de 24, donde 24 representa aproximadamente 2m
    fill(#2CFF7E);               // la formula de la distancia es ancho del pulso*500/5800, el resultado obtenido esta en metros
    textFont(mono2);
    text("Si",300,450);
  }
  else if (habitacion > 24){  
  fill(#F72020);
  textFont(mono2);
  text("No",300,450); 
  }
 
}
