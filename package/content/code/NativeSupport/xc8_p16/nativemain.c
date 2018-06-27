
#include <htc.h>
#include <stdio.h>


#pragma config BOREN = OFF, IESO = OFF, FOSC = ECM, FCMEN = OFF, MCLRE = OFF, WDTE = OFF, CP = OFF, PWRTE = OFF, CLKOUTEN = OFF
 
 

int test_main(void);
void __nm_signal_test_over(void);

unsigned volatile char __nm_test_over_flag;


void main(void)
{
	OSCCON = 0xf0;
	BAUDCON = 0x00;
	SPBRG = 12;
	TXSTA = 0x20;
	RCSTA = 0x80;
	
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
	while ( TXSTAbits.TRMT == 0 );
	TXREG = c;
}
 

