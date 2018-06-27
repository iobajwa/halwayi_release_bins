#define	USE_OR_MASKS
#include <htc.h>
#include <plib\usart.h>
#include <stdio.h>


#pragma config FOSC     = INTIO2
// PLLCFG does not work when using Internal Oscillators (p53 of datasheet)
#pragma config PLLCFG	= ON

#pragma config WDTEN    = OFF
#pragma config WDTPS    = 32768
#pragma config MCLRE    = ON
#pragma config XINST	= OFF
#pragma config CANMX	= PORTC
 
 

int test_main(void);
void __nm_signal_test_over(void);

unsigned volatile char __nm_test_over_flag;


void main(void)
{
	OSCCON = 0xf0;
	OSCTUNE = 0xC0;
	
	Open1USART(USART_TX_INT_OFF | USART_RX_INT_OFF | USART_EIGHT_BIT | USART_BRGH_HIGH, 8);
	
	putch('{'); putch('{'); putch('{'); putch('{'); putch('!'); putch('@'); putch('#'); putch('$');
		test_main(); 
	putch('$'); putch('#'); putch('@'); putch('!'); putch('}'); putch('}'); putch('}'); putch('}');

	__nm_signal_test_over();
	
	while(1);
}

void __nm_signal_test_over()
{
	putchar('}');
	__nm_test_over_flag = 1;
}

void putch(char c)
{
	while ( Busy1USART() );
	Write1USART(c);
}
 

