CC      := lm32-elf-gcc
CFLAGS  := -Wall -mmultiply-enabled -mbarrel-shift-enabled -Os -ggdb -ffreestanding

blink.bin: blink.elf
	lm32-elf-objcopy -O binary $< $@

blink.elf: crt0.o main.o
	$(CC) $(CFLAGS) -o $@ -nostdlib -T linker.ld $^

clean:
	rm -f *.o *.elf *.bin
