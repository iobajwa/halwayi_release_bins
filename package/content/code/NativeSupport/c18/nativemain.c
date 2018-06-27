
#include <p18f46k80.h>
#include <stdio.h>
#include <unity.h>


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
	
	PIE1bits.RC1IE = PIE1bits.TX1IE = 0;
	TXSTA = 0x22;
	BAUDCON1 = 0;
	SPBRG1 = 8;					//	115.2K Baud Rate
	RCSTA1bits.SPEN = 1;

	putchar('{'); putchar('{'); putchar('{'); putchar('{'); putchar('!'); putchar('@'); putchar('#'); putchar('$');
		test_main(); 
	putchar('$'); putchar('#'); putchar('@'); putchar('!'); putchar('}'); putchar('}'); putchar('}'); putchar('}');

	__nm_signal_test_over();

	while(1);
}

void __nm_signal_test_over()
{
	putchar('}');
	__nm_test_over_flag = 1;
}
 
void putchar(char c)
{
	while(PIR1bits.TX1IF == 0);
	TXREG1 = c;
}

