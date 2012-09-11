volatile unsigned int* leds = (unsigned int*)0x100400;

void _irq_entry(void) {
  /* Currently only triggered by DMA completion */
}

void main(void) {
  int i, j;
  
  while (1) {
    /* Rotate the LEDs */
    for (i = 0; i < 8; ++i) {
      *leds = 1 << i;
      
      /* Each loop iteration takes 4 cycles.
       * It runs at 125MHz.
       * Sleep 0.2 second.
       */
      for (j = 0; j < 125000000/4/5; ++j) {
        asm("# noop"); /* no-op the compiler can't optimize away */
      }
    }
  }
}
