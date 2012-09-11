#include "gpio.h"

/* 	Each loop iteration takes 4 cycles.
* 	It runs at 100MHz.
* 	Sleep 0.2 second.
*/
#define LED_DELAY (100000000/4/5)
//#define LED_DELAY 100000000

/* Placeholder for IRQ vector */
void _irq_entry(void){}

int main(void)
{
	int i, j;
	gpio_t leds = (volatile struct GPIO_WB *) BASE_LEDS_ADDR;
	gpio_t buttons = (volatile struct GPIO_WB *) BASE_BUTTONS_ADDR;
	//volatile unsigned int* leds = (unsigned int*) BASE_LEDS_ADDR;

	//gpio_out(leds, 4, 1);
  
	/*while (1) {
		/* Rotate the LEDs 
		for (i = 0; i < 8; ++i) {
			*leds = 1 << i;
		  
		  /* Each loop iteration takes 4 cycles.
		   * It runs at 125MHz.
		   * Sleep 0.2 second.
		   
			for (j = 0; j < LED_DELAY; ++j) {
				asm("# noop"); /* no-op the compiler can't optimize away 
			}
		}
	}*/

	while (1) {
		/* Rotate the LEDs  */
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

	return 0;
}
