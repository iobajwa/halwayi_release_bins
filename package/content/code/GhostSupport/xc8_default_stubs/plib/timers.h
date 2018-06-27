#ifndef __TIMERS_H
#define __TIMERS_H


/******************************************************************************
 	                  TIMERS PERIPHERAL LIBRARY HEADER FILE

 		stub. Borrowed from xc8 lib\plib\
 
 *****************************************************************************/
//#include <pconfig.h>

/* PIC18 timers peripheral library. */

/* used to hold 16-bit timer value */
union Timers
{
  unsigned int lt;
  char bt[2];
};


/* Interrupt bit mask to be 'anded' with the other configuration masks and
 * passed as the 'config' parameter to the 'open' routines. */

#ifndef USE_OR_MASKS
#define TIMER_INT_OFF  0b01111111  //Disable TIMER Interrupt
#define TIMER_INT_ON   0b11111111  //Enable TIMER Interrupt

/* ***** TIMER0 ***** */
/* TIMER0 configuration masks -- to be 'anded' together and passed to the
 * 'open' routine. */
 
#define T0_16BIT       0b10111111  //Timer0 is configured as an 16-bit timer/counter
#define T0_8BIT        0b11111111  //Timer0 is configured as an 8-bit timer/counter

#define T0_SOURCE_INT  0b11011111  //Internal instruction cycle clock (CLKO) acts as source of clock
#if defined (TMR_V7_4)
#define T0_SOURCE_INTOSC  0b11001111  //INTOSC
#else
#define T0_SOURCE_EXT  0b11111111  //Transition on TxCKI pin acts as source of clock
#endif

#define T0_EDGE_RISE   0b11101111  //Increment on low-to-high transition on TxCKI pin
#define T0_EDGE_FALL   0b11111111  //Increment on high-to-low transition on TxCKI pin

#define T0_PS_1_1      0b11111111  //1:1 Prescale value (NO Prescaler)
#define T0_PS_1_2      0b11110000  //1:2 Prescale value
#define T0_PS_1_4      0b11110001  //1:4 Prescale value
#define T0_PS_1_8      0b11110010  //1:8 Prescale value
#define T0_PS_1_16     0b11110011  //1:16 Prescale value
#define T0_PS_1_32     0b11110100  //1:32 Prescale value
#define T0_PS_1_64     0b11110101  //1:64 Prescale value
#define T0_PS_1_128    0b11110110  //1:128 Prescale value
#define T0_PS_1_256    0b11110111  //1:256 Prescale value

#else //!USE_OR_MASKS

#define TIMER_INT_OFF  		0b00000000  //Disable TIMER Interrupt
#define TIMER_INT_ON   		0b10000000  //Enable TIMER Interrupt
#define TIMER_INT_MASK		(~TIMER_INT_ON)	//Mask Enable/Disable Timer Interrupt selection bit

/* ***** TIMER0 ***** */
/* TIMER0 configuration masks -- to be 'anded' together and passed to the
 * 'open' routine. */
 
#define T0_16BIT       		0b00000000  //Timer0 is configured as an 16-bit timer/counter
#define T0_8BIT       		0b01000000  //Timer0 is configured as an 8-bit timer/counter
#define T0_BIT_MASK			(~T0_8BIT)	//Mask Timer0 8-Bit/16-Bit Control bit

#define T0_SOURCE_INT  		0b00000000  //Internal instruction cycle clock (CLKO) acts as source of clock
#if defined (TMR_V7_4)
#define T0_SOURCE_INTOSC  	0b00000000  //INTOSC
#else
#define T0_SOURCE_EXT  		0b00100000  //Transition on TxCKI pin acts as source of clock
#endif
#define T0_SOURCE_MASK		(~T0_SOURCE_EXT)	//Mask Timer0 Clock Source Select bit

#define T0_EDGE_RISE   		0b00000000  //Increment on low-to-high transition on TxCKI pin
#define T0_EDGE_FALL   		0b00010000  //Increment on high-to-low transition on TxCKI pin
#define T0_EDGE_MASK		(~T0_EDGE_FALL)		//Mask Timer0 Source Edge Select bit

#define T0_PS_1_1      		0b00001000  //1:1 Prescale value (NO Prescaler)
#define	NO_T0_PS_MASK		(~T0_PS_1_1)		//Mask Timer0 Prescaler Assignment bit
		
#define T0_PS_1_2      		0b00000000  //1:2 Prescale value
#define T0_PS_1_4      		0b00000001  //1:4 Prescale value
#define T0_PS_1_8      		0b00000010  //1:8 Prescale value
#define T0_PS_1_16     		0b00000011  //1:16 Prescale value
#define T0_PS_1_32     		0b00000100  //1:32 Prescale value
#define T0_PS_1_64     		0b00000101  //1:64 Prescale value
#define T0_PS_1_128    		0b00000110  //1:128 Prescale value
#define T0_PS_1_256    		0b00000111  //1:256 Prescale value
#define T0_PS_MASK			(~T0_PS_1_256)	//Mask Timer0 Prescaler Select bits

#endif//USE_OR_MASKS

void OpenTimer0 ( unsigned char config);
void CloseTimer0 (void);
unsigned int ReadTimer0 (void);
void WriteTimer0 ( unsigned int timer0);

/* ***** TIMER1 ***** */

/* TIMER1 configuration masks -- to be 'anded' together and passed to the
 * 'open' routine. */
 
 	/*
#if defined (TMR_V6) || defined (TMR_V7) || defined (TMR_V7_1) || defined (TMR_V7_2)\
 || defined (TMR_V7_3) || defined (TMR_V7_4) || defined (TMR_V7_5)

#ifndef USE_OR_MASKS

#if defined (TMR_V7_4)
#define T1_SOURCE_INTOSC 	0b11111111  // Clock source is INTOSC
#endif
#define T1_SOURCE_PINOSC 	0b11011111  // Clock source T1OSCEN = 0 Ext clock, T1OSCEN=1 Crystal osc
#define T1_SOURCE_FOSC_4 	0b10011111  //Clock source is instruction clock (FOSC/4)
#define T1_SOURCE_FOSC   	0b10111111  //Closck source is system clock (FOSC)

#define T1_PS_1_1        	0b11100111  // 1:1 prescale value
#define T1_PS_1_2        	0b11101111  // 1:2 prescale value
#define T1_PS_1_4        	0b11110111  // 1:4 prescale value
#define T1_PS_1_8        	0b11111111  // 1:8 prescale value

#define T1_OSC1EN_OFF    	0b11111011  // Timer 1 oscilator enable off
#define T1_OSC1EN_ON     	0b11111111  // Timer 1 oscilator enable on

#define T1_SYNC_EXT_ON      0b11111101  // Synchronize external clock input
#define T1_SYNC_EXT_OFF     0b11111111  // Do not synchronize external clock input

#define T1_8BIT_RW          0b11111110  //Enables register read/write of Timer1 in two 8-bit operations
#define T1_16BIT_RW         0b11111111  //Enables register read/write of Timer1 in one 16-bit operation

#else

#if defined (TMR_V7_4)
#define T1_SOURCE_INTOSC 	0b00000000  // Clock source is INTOSC
#endif
#define T1_SOURCE_PINOSC 	0b01000000  // Clock source T1OSCEN = 0 Ext clock, T1OSCEN=1 Crystal osc
#define T1_SOURCE_FOSC_4 	0b00000000  //Clock source is instruction clock (FOSC/4)
#define T1_SOURCE_FOSC   	0b00100000  //Clock source is system clock (FOSC)
#define	T1_SOURCE_MASK	 	(~T1_SOURCE_FOSC)	//Mask Timer1 Clock Source Select bits

#define T1_PS_1_1        	0b00000000  // 1:1 prescale value
#define T1_PS_1_2        	0b00001000  // 1:2 prescale value
#define T1_PS_1_4        	0b00010000  // 1:4 prescale value
#define T1_PS_1_8        	0b00011000  // 1:8 prescale value
#define T1_PS_MASK		 	(~T1_PS_1_8)	//Mask Timer1 Input Clock Prescale Select bits

#define T1_OSC1EN_OFF    	0b00000000  // Timer 1 oscilator enable off
#define T1_OSC1EN_ON     	0b00000100  // Timer 1 oscilator enable on
#define	T1_OSC_MASK		 	(~T1_OSC1EN_ON)		//Mask Timer1 Oscillator Enable bit

#define T1_SYNC_EXT_ON      0b00000000  // Synchronize external clock input
#define T1_SYNC_EXT_OFF     0b00000010  // Do not synchronize external clock input
#define T1_SYNC_MASK	    (~T1_SYNC_EXT_OFF)	// Mask Timer1 External Clock Input Synchronization Select bit

#define T1_8BIT_RW          0b00000000  //Enables register read/write of Timer1 in two 8-bit operations
#define T1_16BIT_RW         0b00000001  //Enables register read/write of Timer1 in one 16-bit operation
#define T1_BIT_RW_MASK	    (~T1_16BIT_RW)		// Mask Timer1 16-Bit Read/Write Mode Enable bit

#endif


void OpenTimer1 ( unsigned char config,  unsigned char config1);
void CloseTimer1 (void);
unsigned int ReadTimer1 (void);
void WriteTimer1 ( unsigned int timer1);

#else 


#ifndef	USE_OR_MASKS

#define T1_8BIT_RW       0b10111111  //Enables register read/write of Timer1 in two 8-bit operations
#define T1_16BIT_RW      0b11111111  //Enables register read/write of Timer1 in one 16-bit operation
#define T1_PS_1_1        0b11001111  // 1:1 prescale value
#define T1_PS_1_2        0b11011111  // 1:2 prescale value
#define T1_PS_1_4        0b11101111  // 1:4 prescale value
#define T1_PS_1_8        0b11111111  // 1:8 prescale value
#define T1_OSC1EN_OFF    0b11110111  // Timer 1 oscilator enable off
#define T1_OSC1EN_ON     0b11111111  // Timer 1 oscilator enable on
#define T1_SYNC_EXT_ON   0b11111011  // Synchronize external clock input
#define T1_SYNC_EXT_OFF  0b11111111  // Do not synchronize external clock input
#define T1_SOURCE_INT    0b11111101  //Internal instruction cycle clock (CLKO) acts as source of clock
#define T1_SOURCE_EXT    0b11111111  //Transition on TxCKI pin acts as source of clock

#else //!USE_OR_MASKS

#define T1_8BIT_RW       0b00000000  //Enables register read/write of Timer1 in two 8-bit operations
#define T1_16BIT_RW      0b01000000  //Enables register read/write of Timer1 in one 16-bit operation
#define T1_BIT_RW_MASK	 (~T1_16BIT_RW)		// Mask Timer1 16-Bit Read/Write Mode Enable bit

#define T1_PS_1_1        0b00000000  // 1:1 prescale value
#define T1_PS_1_2        0b00010000  // 1:2 prescale value
#define T1_PS_1_4        0b00100000  // 1:4 prescale value
#define T1_PS_1_8        0b00110000  // 1:8 prescale value
#define T1_PS_MASK		 (~T1_PS_1_8)		//Mask Timer1 Input Clock Prescale Select bits
	
#define T1_OSC1EN_OFF    0b00000000  // Timer 1 oscilator enable off
#define T1_OSC1EN_ON     0b00001000  // Timer 1 oscilator enable on
#define	T1_OSC_MASK		 (~T1_OSC1EN_ON)	//Mask Timer1 Oscillator Enable bit

#define T1_SYNC_EXT_ON   0b00000000  // Synchronize external clock input
#define T1_SYNC_EXT_OFF  0b00000100  // Do not synchronize external clock input
#define T1_SYNC_MASK	 (~T1_SYNC_EXT_OFF)	// Mask Timer1 External Clock Input Synchronization Select bit

#define T1_SOURCE_INT    0b00000000  //Internal instruction cycle clock (CLKO) acts as source of clock
#define T1_SOURCE_EXT	 0b00000010  //Transition on TxCKI pin acts as source of clock
#define	T1_SOURCE_MASK	 (~T1_SOURCE_EXT)	//Mask Timer1 Clock Source Select bits



#endif //USE_OR_MASKS

void OpenTimer1 ( unsigned char config);
void CloseTimer1 (void);
unsigned int ReadTimer1 (void);
void WriteTimer1 ( unsigned int timer1);
#endif
	*/


#endif//__TIMERS_H

