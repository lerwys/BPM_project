
main.elf:     file format elf32-lm32


Disassembly of section .boot:

00000000 <_reset_handler>:
   0:	98 00 00 00 	xor r0,r0,r0
   4:	d0 00 00 00 	wcsr IE,r0
   8:	d0 20 00 00 	wcsr IM,r0
   c:	78 01 00 00 	mvhi r1,0x0
  10:	38 21 00 00 	ori r1,r1,0x0
  14:	d0 e1 00 00 	wcsr EBA,r1
  18:	f8 00 00 3a 	calli 100 <_crt0>
  1c:	34 00 00 00 	nop
	...

000000c0 <_interrupt_handler>:
  c0:	5b 9d 00 00 	sw (sp+0),ra
  c4:	f8 00 00 20 	calli 144 <_save_all>
  c8:	34 01 00 02 	mvi r1,2
  cc:	f8 00 00 41 	calli 1d0 <_ftext_rom>
  d0:	e0 00 00 30 	bi 190 <_restore_all_and_return>
  d4:	34 00 00 00 	nop
  d8:	34 00 00 00 	nop
  dc:	34 00 00 00 	nop
	...

00000100 <_crt0>:
 100:	98 00 00 00 	xor r0,r0,r0
 104:	78 1c 00 00 	mvhi sp,0x0
 108:	3b 9c ff fc 	ori sp,sp,0xfffc
 10c:	78 1a 00 00 	mvhi gp,0x0
 110:	3b 5a 83 30 	ori gp,gp,0x8330
 114:	78 01 00 00 	mvhi r1,0x0
 118:	38 21 03 38 	ori r1,r1,0x338
 11c:	34 02 00 00 	mvi r2,0
 120:	78 03 00 00 	mvhi r3,0x0
 124:	38 63 03 38 	ori r3,r3,0x338
 128:	c8 61 18 00 	sub r3,r3,r1
 12c:	f8 00 00 40 	calli 22c <memset>
 130:	34 01 00 00 	mvi r1,0
 134:	34 02 00 00 	mvi r2,0
 138:	34 03 00 00 	mvi r3,0
 13c:	f8 00 00 26 	calli 1d4 <main>

00000140 <loopf>:
 140:	e0 00 00 00 	bi 140 <loopf>

00000144 <_save_all>:
 144:	37 9c ff c4 	addi sp,sp,-60
 148:	5b 81 00 04 	sw (sp+4),r1
 14c:	5b 82 00 08 	sw (sp+8),r2
 150:	5b 83 00 0c 	sw (sp+12),r3
 154:	5b 84 00 10 	sw (sp+16),r4
 158:	5b 85 00 14 	sw (sp+20),r5
 15c:	5b 86 00 18 	sw (sp+24),r6
 160:	5b 87 00 1c 	sw (sp+28),r7
 164:	5b 88 00 20 	sw (sp+32),r8
 168:	5b 89 00 24 	sw (sp+36),r9
 16c:	5b 8a 00 28 	sw (sp+40),r10
 170:	5b 9e 00 34 	sw (sp+52),ea
 174:	5b 9f 00 38 	sw (sp+56),ba
 178:	2b 81 00 3c 	lw r1,(sp+60)
 17c:	5b 81 00 30 	sw (sp+48),r1
 180:	bb 80 08 00 	mv r1,sp
 184:	34 21 00 3c 	addi r1,r1,60
 188:	5b 81 00 2c 	sw (sp+44),r1
 18c:	c3 a0 00 00 	ret

00000190 <_restore_all_and_return>:
 190:	2b 81 00 04 	lw r1,(sp+4)
 194:	2b 82 00 08 	lw r2,(sp+8)
 198:	2b 83 00 0c 	lw r3,(sp+12)
 19c:	2b 84 00 10 	lw r4,(sp+16)
 1a0:	2b 85 00 14 	lw r5,(sp+20)
 1a4:	2b 86 00 18 	lw r6,(sp+24)
 1a8:	2b 87 00 1c 	lw r7,(sp+28)
 1ac:	2b 88 00 20 	lw r8,(sp+32)
 1b0:	2b 89 00 24 	lw r9,(sp+36)
 1b4:	2b 8a 00 28 	lw r10,(sp+40)
 1b8:	2b 9d 00 30 	lw ra,(sp+48)
 1bc:	2b 9e 00 34 	lw ea,(sp+52)
 1c0:	2b 9f 00 38 	lw ba,(sp+56)
 1c4:	2b 9c 00 2c 	lw sp,(sp+44)
 1c8:	34 00 00 00 	nop
 1cc:	c3 c0 00 00 	eret

Disassembly of section .text:

000001d0 <_irq_entry>:
 1d0:	c3 a0 00 00 	ret

000001d4 <main>:
 1d4:	78 02 00 00 	mvhi r2,0x0
 1d8:	38 42 03 30 	ori r2,r2,0x330
 1dc:	28 43 00 00 	lw r3,(r2+0)
 1e0:	34 01 00 00 	mvi r1,0
 1e4:	34 07 00 01 	mvi r7,1
 1e8:	34 06 ff ff 	mvi r6,-1
 1ec:	34 05 00 07 	mvi r5,7
 1f0:	bc e1 20 00 	sl r4,r7,r1
 1f4:	78 08 00 00 	mvhi r8,0x0
 1f8:	39 08 03 34 	ori r8,r8,0x334
 1fc:	58 64 00 04 	sw (r3+4),r4
 200:	29 02 00 00 	lw r2,(r8+0)
 204:	e0 00 00 02 	bi 20c <main+0x38>
 208:	34 00 00 00 	nop
 20c:	34 42 ff ff 	addi r2,r2,-1
 210:	5c 46 ff fe 	bne r2,r6,208 <main+0x34>
 214:	34 21 00 01 	addi r1,r1,1
 218:	ec a1 10 00 	cmpge r2,r5,r1
 21c:	58 64 00 00 	sw (r3+0),r4
 220:	c8 02 10 00 	sub r2,r0,r2
 224:	a0 22 08 00 	and r1,r1,r2
 228:	e3 ff ff f2 	bi 1f0 <main+0x1c>

0000022c <memset>:
 22c:	20 25 00 03 	andi r5,r1,0x3
 230:	b8 20 20 00 	mv r4,r1
 234:	44 a0 00 0b 	be r5,r0,260 <memset+0x34>
 238:	44 60 00 2c 	be r3,r0,2e8 <memset+0xbc>
 23c:	34 63 ff ff 	addi r3,r3,-1
 240:	20 46 00 ff 	andi r6,r2,0xff
 244:	e0 00 00 03 	bi 250 <memset+0x24>
 248:	44 60 00 28 	be r3,r0,2e8 <memset+0xbc>
 24c:	34 63 ff ff 	addi r3,r3,-1
 250:	30 86 00 00 	sb (r4+0),r6
 254:	34 84 00 01 	addi r4,r4,1
 258:	20 85 00 03 	andi r5,r4,0x3
 25c:	5c a0 ff fb 	bne r5,r0,248 <memset+0x1c>
 260:	34 05 00 03 	mvi r5,3
 264:	50 a3 00 1a 	bgeu r5,r3,2cc <memset+0xa0>
 268:	20 45 00 ff 	andi r5,r2,0xff
 26c:	3c a6 00 08 	sli r6,r5,8
 270:	34 0a 00 0f 	mvi r10,15
 274:	b8 c5 28 00 	or r5,r6,r5
 278:	3c a6 00 10 	sli r6,r5,16
 27c:	b8 80 40 00 	mv r8,r4
 280:	b8 c5 30 00 	or r6,r6,r5
 284:	b8 60 38 00 	mv r7,r3
 288:	b8 80 28 00 	mv r5,r4
 28c:	34 09 00 0f 	mvi r9,15
 290:	54 6a 00 17 	bgu r3,r10,2ec <memset+0xc0>
 294:	34 04 00 00 	mvi r4,0
 298:	34 07 00 03 	mvi r7,3
 29c:	b5 04 28 00 	add r5,r8,r4
 2a0:	34 84 00 04 	addi r4,r4,4
 2a4:	58 a6 00 00 	sw (r5+0),r6
 2a8:	c8 64 28 00 	sub r5,r3,r4
 2ac:	54 a7 ff fc 	bgu r5,r7,29c <memset+0x70>
 2b0:	34 63 ff fc 	addi r3,r3,-4
 2b4:	00 64 00 02 	srui r4,r3,2
 2b8:	20 63 00 03 	andi r3,r3,0x3
 2bc:	34 84 00 01 	addi r4,r4,1
 2c0:	3c 84 00 02 	sli r4,r4,2
 2c4:	b5 04 40 00 	add r8,r8,r4
 2c8:	b9 00 20 00 	mv r4,r8
 2cc:	44 60 00 07 	be r3,r0,2e8 <memset+0xbc>
 2d0:	20 42 00 ff 	andi r2,r2,0xff
 2d4:	34 05 00 00 	mvi r5,0
 2d8:	b4 85 30 00 	add r6,r4,r5
 2dc:	30 c2 00 00 	sb (r6+0),r2
 2e0:	34 a5 00 01 	addi r5,r5,1
 2e4:	5c 65 ff fd 	bne r3,r5,2d8 <memset+0xac>
 2e8:	c3 a0 00 00 	ret
 2ec:	58 a6 00 00 	sw (r5+0),r6
 2f0:	58 a6 00 04 	sw (r5+4),r6
 2f4:	58 a6 00 08 	sw (r5+8),r6
 2f8:	58 a6 00 0c 	sw (r5+12),r6
 2fc:	34 e7 ff f0 	addi r7,r7,-16
 300:	34 a5 00 10 	addi r5,r5,16
 304:	54 e9 ff fa 	bgu r7,r9,2ec <memset+0xc0>
 308:	34 63 ff f0 	addi r3,r3,-16
 30c:	00 68 00 04 	srui r8,r3,4
 310:	20 63 00 0f 	andi r3,r3,0xf
 314:	35 08 00 01 	addi r8,r8,1
 318:	3d 08 00 04 	sli r8,r8,4
 31c:	b4 88 40 00 	add r8,r4,r8
 320:	34 04 00 03 	mvi r4,3
 324:	54 64 ff dc 	bgu r3,r4,294 <memset+0x68>
 328:	b9 00 20 00 	mv r4,r8
 32c:	e3 ff ff e8 	bi 2cc <memset+0xa0>
