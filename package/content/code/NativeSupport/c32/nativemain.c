#include <p32xxxx.h>
#include <stdio.h>
 
#define _UART1

void _mon_putc(char c);
int test_main(void);
void __nm_signal_test_over(void);

volatile unsigned int __nm_test_over_flag;

void main(void)
{
	U1MODEbits.UARTEN = 0x01;
	U1STAbits.UTXEN = 0x01;

	printf("{{{{!@#$\n");	 
  
	test_main(); 
	
	printf("\n$#@!}}}}");
  
	__nm_signal_test_over();
	while(1);
}

void __nm_signal_test_over()
{
	printf("\nover");
	__nm_test_over_flag = 1;
}

void _mon_putc(char c)
{
	while (U1STAbits.UTXBF);
	U1TXREG = c;
}
 
