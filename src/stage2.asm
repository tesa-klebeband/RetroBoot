dw "BR"

mov [drive_number], dl

mov si, ok_msg
call print_string

mov si, integrity_check_msg
call print_string

cmp [end_sig], word 0x1234
jne fail

mov si, ok_msg
call print_string

mov si, load_part_msg
call print_string

mov ah, 08h
int 13h
jc fail
and cl, 0x3F
xor ch, ch
mov [sectors_per_track], cx
inc dh
mov [heads], dh

call load_root
mov si, ok_msg
call print_string

mov si, welcome_msg
call print_string

search_options:
    mov di, root_buffer
    xor bx, bx
    xor dx, dx

.search_opt:
    mov cx, 3
    mov si, filename + 8
    push di
    add di, 8
    repe cmpsb
    pop di
    je .found_opt
    add di, 32
    inc bx
    cmp bx, [volume_boot_record + 0x11]
    jl .search_opt

    cmp [option_buffer], word 0
    je .no_options
    jmp get_choice

.found_opt:
    push bx
    mov bx, option_buffer
    add bx, dx
    mov [bx], di
    pop bx

    mov si, newline
    call print_string

    push dx
    shr dx, 1
    mov ah, 0xE
    mov al, '1'
    add al, dl
    int 0x10
    mov al, '.'
    int 0x10
    mov al, ' '
    int 0x10
    pop dx

    mov si, di
    mov [si + 8], byte '$'
    call print_string

    add di, 32
    add dx, 2
    jmp .search_opt

.no_options:
    mov si, no_options_msg
    call print_string

    cli
    hlt

get_choice:
    mov si, enter_choice_msg
    call print_string

    xor ah, ah
    int 0x16
    mov ah, 0xE
    int 0x10

    sub al, '1'
    xor ah, ah
    mov bx, option_buffer
    shl ax, 1
    add bx, ax
    cmp [bx], word 0
    je .invalid_option
    mov di, [bx]
    jmp load_option

.invalid_option:
    mov si, invalid_option_msg
    call print_string
    jmp get_choice

load_option:
    mov bx, config_buffer
    call load_file

    cmp [config_buffer], byte 0
    je chainload

    mov si, config_buffer
    mov di, filename
    mov cx, 11
    rep movsb

    mov si, file_loading_msg    
    call print_string
    call search_file
    mov bx, 0x1000
    mov es, bx
    xor bx, bx
    call load_file

    mov si, ok_msg
    call print_string

    push es
    pop ds
    xor si, si
    mov es, [cs:config_buffer + 11]
    mov di, [cs:config_buffer + 13]
    mov cx, [cs:config_buffer + 15]
    rep movsb

    push word [cs:config_buffer + 11]
    push word [cs:config_buffer + 13]
    mov dl, [cs:config_buffer + 17]
    retf

chainload:
    mov si, chainload_msg
    call print_string

    mov bx, 0x1000
    mov es, bx
    xor bx, bx
    xor ax, ax
    mov cl, 1
    call read_disk

    mov si, ok_msg
    call print_string
    mov si, newline
    call print_string

    push es
    pop ds
    xor si, si
    mov es, si
    mov di, 0x7c00
    mov cx, 512
    rep movsb

    mov dl, [cs:drive_number]

    jmp 0:0x7c00

load_root:
    xor ax, ax
    mov cl, 1
    mov bx, volume_boot_record
    call read_disk

    xor ax, ax
    xor bx, bx

    mov ax, [volume_boot_record + 0x16]
    mov bl, [volume_boot_record + 0x10]
    mul bx
    add ax, [volume_boot_record + 0xE]
    push ax

    xor ax, ax
    xor bx, bx

    mov ax, [volume_boot_record + 0x11]
    mov bl, 32
    mul bx

    div word [volume_boot_record + 0xB]

    mov cl, al
    mov [root_size], cl
    pop ax

    mov bx, root_buffer

    call read_disk

    ret

search_file:
    mov di, root_buffer
    xor bx, bx

.search_file:
    mov cx, 11
    mov si, filename
    push di
    repe cmpsb
    pop di
    je .found_file
    add di, 32
    inc bx
    cmp bx, [volume_boot_record + 0x11]
    jl .search_file

    jmp fail

.found_file:
    ret

load_file:
    push bx
    push es

    xor bx, bx
    mov es, bx

    mov ax, [di + 26]           ; First cluster field
    mov [file_cluster], ax
    
    mov ax, [volume_boot_record + 0xE]
    mov cl, [volume_boot_record + 0x16]
    mov bx, buffer
    
    call read_disk

    pop es
    pop bx

    mov ax, [volume_boot_record + 0x16]
    mul byte [volume_boot_record + 0x10]
    add ax, [volume_boot_record + 0xE]
    add al, [root_size]
    mov [start_sector], ax

.load_loop:
    ; Read next cluster
    mov ax, [file_cluster]
    sub ax, 2
    mul byte [volume_boot_record + 0xD]
    add ax, [start_sector]
    mov cl, [volume_boot_record + 0xD]
    call read_disk

    mov ax, [volume_boot_record + 0xB]
    xor ch, ch
    mov cl, [volume_boot_record + 0xD]
    mul cx

    add bx, ax
    
    ; compute location of next cluster
    mov ax, [file_cluster]
    mov cx, 2
    mul cx

    mov si, buffer
    add si, ax
    mov ax, [ds:si]                     ; read entry from FAT table at index ax

    cmp ax, 0xFFF8                      ; end of chain
    jae .read_finish

    mov [file_cluster], ax
    jmp .load_loop

.read_finish:
    ret

lba_to_chs:
    push ax
    push dx
    
    xor dx, dx
    div word [sectors_per_track]
    inc dx
    mov [sector], dx
    xor dx, dx
    div word [heads]
    mov [cylinder], ax
    mov [head], dx
    
    pop dx
    pop ax

    mov ch, [cylinder]
    mov cl, [sector]
    mov dh, [head]

    ret

read_disk:
    push ax
    push bx
    push cx
    push dx
    push di

    push cx
    add ax, [part_0 + 8]
    call lba_to_chs
    pop ax
    mov dl, [drive_number]
    mov ah, 0x2

    int 0x13
    jc fail

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

welcome_msg:
    db 0xA, 0xD
    db 0xA, 0xD, "==========================================="
    db 0xA, 0xD, "Welcome to RetroBoot v1.0 by tesa_klebeband"
    db 0xA, 0xD, "==========================================="
    db 0xA, 0xD, '$'
integrity_check_msg: db 0xA, 0xD, "Checking stage 2...    $"
load_part_msg: db 0xA, 0xD, "Opening partition 1... $"
no_options_msg: db 0xA, 0xD, "No boot options found! System Halted$"
chainload_msg: db 0xA, 0xD, "Chainloading partition 1... $"
enter_choice_msg: db 0xA, 0xD, 0xA, 0xD, "Enter boot option number to load [1-10]: $"
invalid_option_msg: db 0xA, 0xD, "Invalid option!$"
file_loading_msg: db 0xA, 0xD, "Loading "
filename: db "        RBO"
db "... $"
newline: db 0xA, 0xD, "$"

drive_number: db 0
sectors_per_track:       dw 0x20
heads:                   dw 2

cylinder: dw 0
head: dw 0
sector: dw 0

file_cluster: dw 0
start_sector: dw 0

root_size: db 0

end_sig: dw 0x1234

volume_boot_record:

option_buffer equ volume_boot_record + 512
config_buffer equ option_buffer + 20
root_buffer equ config_buffer+2048
buffer equ root_buffer+16384