//#include <stdio.h>
#include "gpio.h"

/* 	Each loop iteration takes 4 cycles.
* 	It runs at 100MHz.
* 	Sleep 0.2 second.
*/
#define LED_DELAY (100000000/4/5)

/* Placeholder for IRQ vector */
void _irq_entry(){}

int main(void)
{
	int i;
	gpio_t leds = BASE_LEDS_ADDR;
	gpio_t buttons = BASE_BUTTONS_ADDR;

	while (1) {
		/* Rotate the LEDs */
		for (i = 0; i < 8; ++i) {
			// Set led at position i
			gpio_out(leds, i, 1);
		  	//*leds = 1 << i;
		  
			/* Each loop iteration takes 4 cycles.
			* It runs at 100MHz.
			* Sleep 0.2 second.
			*/
			delay(LED_DELAY);
			//for (j = 0; j < 100000000/4/5; ++j) {
			//asm("# noop"); /* no-op the compiler can't optimize away */

			// Clear led at position i
			gpio_out(leds, i, 0);
		}
 	}
}
