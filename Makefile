ASM = nasm -f bin
EMULATOR = qemu-system-x86_64

all: prep retroboot image run

prep:
	mkdir -p build

retroboot: src/boot.asm
	$(ASM) $^ -o build/$@

partition: src/partition.asm
	$(ASM) $^ -o build/$@

image:
	dd if=/dev/zero of=retroboot.img bs=4M count=8
	dd if=build/retroboot of=retroboot.img conv=notrunc
	sudo losetup --partscan /dev/loop1 retroboot.img
	sudo mkfs.fat -F 16 /dev/loop1p1
	sudo losetup -d /dev/loop1

run: retroboot.img
	$(EMULATOR) $^