/* ###################################################################
**     Filename    : main.c
**     Project     : Projecto2
**     Processor   : MC9S08QE128CLK
**     Version     : Driver 01.12
**     Compiler    : CodeWarrior HCS08 C Compiler
**     Date/Time   : 2019-06-18, 16:02, # CodeGen: 0
**     Abstract    :
**         Main module.
**         This module contains user's application code.
**     Settings    :
**     Contents    :
**         No public methods
**
** ###################################################################*/
/*!
** @file main.c
** @version 01.12
** @brief
**         Main module.
**         This module contains user's application code.
*/         
/*!
**  @addtogroup main_module main module documentation
**  @{
*/         
/* MODULE main */


/* Including needed modules to compile this module/procedure */
#include "Cpu.h"
#include "Events.h"
#include "AD1.h"
#include "AS1.h"
#include "TI1.h"
#include "KB1.h"
#include "Bit1.h"
#include "Bit2.h"
#include "Bit3.h"
#include "Bit4.h"
#include "Bit5.h"
/* Include shared modules, which are used for whole project */
#include "PE_Types.h"
#include "PE_Error.h"
#include "PE_Const.h"
#include "IO_Map.h"

/* User includes (#include below this line is not maintained by Processor Expert) */

char flag_KB; 		// flag para la interrupcion de teclado
char flag_Ti; 	 	// flag para la interrupcion de timer
char flag_filter;   // flag para indicar que el filtro esta activo
char adc[1];   		// variable donde se va a guardar el resultado del ADC
char block[3];		// variable donde se guardara el stream a enviar por puerto serial
char *DirSB;   		// apuntador usado para el envio de bloques por puerto serial
char product[2];
//char coef[17] = {14,25,-16,13,-13,13,-14,14,127,14,-14,13,-13,13,-16,25,14}; // Coeficientes de distintos filtros pasabajos
char coef[17] = {-42,-55,0,15,10,-32,1,75,127,75,1,-32,10,15,0,-55,-42};
//char coef[17] = {0,-70,0,18,0,-28,0,81,127,81,0,-28,0,18,0,-69,0};

char muestra[17] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};  // Aqui se guarda la data que va llegando

int multi;   // variable que guarda la data filtrada o no adquirida del acelerometro
int i = 0;   // variable que sirve para ir moviendo el indice para guardar la data de muestra y para el Filtro

void Filtrado()       // funcion que realiza el proceso de filtrado cuando el filtro esta activado
{
	int j;            // variable usada para moverme en los coeficientes del filtro
	multi = 0;        // condicion inicial de la variable
	
	if(i > 16)        // cuando el indice de muestras llega a 16 (ultima posicion) se reinicia a 0
		i = 0;
	
	muestra[i] = adc[0];  // las muestras recibidas por el adc se van guardando
	
	for (j = 0; j < 17; j++){	                 // recorro el arreglo de coeficientes del filtro
		multi = multi + (muestra[i-j]*coef[j]);  // el valor de multi sera su actual mas la suma de la muestra*coeficiente
		if((i-j)== 0)                            
			i = 17 + j ;                         // como el arreglo de muestras se recorres apuesto al de coeficientes, al llegar a 0
	}                                            // hago que vaya al final del arreglo
	
	i = i + 1;                                   // voy sumando el indice del arreglo de muestras

}

void filtro()                 // esta funcion permite determinar si esta o no activo el filtro
{
	
	if((flag_KB == 1))           // compruebo si se presiono el boton del demoque para activar el filtro
	{
		if (flag_filter == 0)    // con esto activo o desactivo la bandera de activacion del filtro
		{
			flag_filter = 1;	
		}else
		{
			flag_filter = 0;
		}
		
		flag_KB = 0;              // reinicio el flag del boton de activacion de filtro
		Bit3_NegVal();            // prendo un led para indicar que se activo o desactivo el filtro
	}	
	
		if(flag_filter == 1)      // si la bandera de filtro esta activa se filtra y se prende otro led (redundante, pero hubo problemas)
		{                         // por lo que se tomo esta medida en el proceso de debugging
			Bit5_ClrVal();
			Filtrado();
		}
		else if(flag_filter == 0)	// si la bandera de filtro no esta activa se prende otro led (redundante, pero hubo problemas)
		{                         	// por lo que se tomo esta medida en el proceso de debugging
			Bit5_SetVal();
			multi = adc[0]*0b100000000;  // amplifico el valor obtenido del ADC ya que este es de 8bits y el envio de data es de 16 bits
		}                                // ya que al usar un filtro el valor de salida pasa de ser de 8 bits a uno de 16 bits

	product[0] = multi>>8;               // 8 bits mas significativos que se empaquetaran
	product[1] = multi & 0b11111111;     // 8 bits menos significativos que se empaquetaran
}

void Empaquetado()                            // funcion encargada del empaquetamiento de la data que sera transmitida
{
	block[0] = product[0]>>2;                 
	block[1] = (product[0]<<3) & 0b00011000;
	block[1] = block[1] | (product[1]>>5);
	block[2] = product[1] & 0b00011111;
	
	if (Bit1_GetVal() == 1)                   // si hay un cana digital activo le asigno un 1 a su posicion correnpodiente
		block[1] = block[1] | 0b1000000;
	
	if (Bit2_GetVal() == 1)                   // / si hay un cana digital activo le asigno un 1 a su posicion correnpodiente
		block[1] = block[1] | 0b100000;
	
}

void main(void)
{
  /* Write your local variable definition here */
  flag_KB = 0;
  flag_Ti = 0;
  flag_filter = 0;

  /*** Processor Expert internal initialization. DON'T REMOVE THIS CODE!!! ***/
  PE_low_level_init();
  /*** End of Processor Expert internal initialization.                    ***/

  /* Write your code here */

  do
  {
	  if(flag_Ti == 1)                        // se comienza el proceso de envio de data cuando la bandera de la interrupcion temporal
	  	{                                     // se activa
	  		AD1_Measure(1);
	  		AD1_GetValue(adc);	              // adquiero los datos del adc y los guardo en la variable adc (poca creatividad lo se)
	  		
	  		filtro();                         // compruebo el estado de actividad o no del filtro
	  		Empaquetado();                    // empaqueto la data a transmitir
	  		block[0] = block[0] | 0b10000000; // con esto defino la cabecera de la cadena de data a enviar
	  
	  		//block[0] = 0b10101010; // 170 Dec  - Esta seccion fue usada para testear la recepcion de la data
	  		//block[1] = 0b11111; // 32 Dec
	  		//block[2] = 0b10000; // 16 Dec
	  		
	  		AS1_SendBlock(block, 3, &DirSB);  // envio la data por puerto serial
	  		flag_Ti = 0;                      // reinicio la bandera de interrupcion por tiempo
	  		Bit4_NegVal();                    // cambio el estado del pin de salida, esto se uso para testear si estabamos enviando data a 
	  	}                                     // 2kHz

  } while(1);
  /* For example: for(;;) { } */

  /*** Don't write any code pass this line, or it will be deleted during code generation. ***/
  /*** RTOS startup code. Macro PEX_RTOS_START is defined by the RTOS component. DON'T MODIFY THIS CODE!!! ***/
  #ifdef PEX_RTOS_START
    PEX_RTOS_START();                  /* Startup of the selected RTOS. Macro is defined by the RTOS component. */
  #endif
  /*** End of RTOS startup code.  ***/
  /*** Processor Expert end of main routine. DON'T MODIFY THIS CODE!!! ***/
  for(;;){}
  /*** Processor Expert end of main routine. DON'T WRITE CODE BELOW!!! ***/
} /*** End of main routine. DO NOT MODIFY THIS TEXT!!! ***/

/* END main */
/*!
** @}
*/
/*
** ###################################################################
**
**     This file was created by Processor Expert 10.3 [05.09]
**     for the Freescale HCS08 series of microcontrollers.
**
** ###################################################################
*/
