ASM = nasm -f bin
CPP = g++
EMULATOR = qemu-system-x86_64

all: prep retroboot image mkconfig run

prep:
	mkdir -p build

retroboot: src/boot.asm
	$(ASM) $^ -o build/$@

partition: src/partition.asm
	$(ASM) $^ -o build/$@

image:
	dd if=/dev/zero of=retroboot.img bs=4M count=8
	dd if=build/retroboot of=retroboot.img conv=notrunc
	sudo losetup --partscan /dev/loop10 retroboot.img
	sudo mkfs.fat -F 16 /dev/loop10p1
	sudo losetup -d /dev/loop10

mkconfig: src/*.cpp
	$(CPP) $^ -o build/$@

run: retroboot.img
	$(EMULATOR) $^