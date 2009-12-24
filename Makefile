Z80ASM=z80asm
KC2TAP=kc2tap
KC2WAV=kc2wav

all:	kcc tap wav

kcc:
	$(Z80ASM) snake.asm -o snake.kcc

tap:	kcc
	$(KC2TAP) snake.kcc snake.tap

wav:	tap
	$(KC2WAV) snake.tap snake.wav

clean:
	-rm *wav *kcc *tap

