[ORG 0x7c00]
[BITS 16]

xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00


mov si, stage_2_msg
call print_string

mov ah, 0x2
mov al, 2
xor ch, ch
mov cl, 0x2
xor dh, dh
mov bx, 0x7e00
int 13h
jc fail

cmp [0x7e00], word "BR"
jne fail

jmp 0x7e02

fail:
    mov si, failed_msg
    call print_string

    cli
    hlt

print_string:
	mov ah, 0x0E

.loop:
	lodsb
	cmp al, '$'
	je .done
	int 0x10
	jmp .loop

.done:
	ret

stage_2_msg: db 0xA, 0xD, "Loading stage 2...     $"
failed_msg: db "FAILED$"
ok_msg: db "OK$"

times 440-($-$$) db 0
dd 0x5F69AB5C           ; Disk Identifier
dw 0
part_0:
    db 0                ; Not bootable
    dw 0x2120           ; CHS to LBA adress 2048
    db 0
    db 4                ; FAT16
    dw 0x292A
    db 2                ; 16MiB size
    dd 0x0800           ; LBA representive of above values
    dd 0x8001

resb 48
dw 0xAA55

%include "src/stage2.asm"