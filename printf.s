section .text
global _start

_start:

    ;разложение сишного printf("%d", 12525);
    mov rsi, 12525        ;аргумент принтфа
    lea rdi, integer      ;%d
    mov rax, 0

    call check_param

    call printf_buf
    call next_line

    call _global_xor

    mov rax, 0x3C
    xor rdi, rdi
    syscall

check_param:

    mov rbx, rdi
    xor rdi, rdi
    mov rax, rsi

    cmp rbx, string
    je read_string

    cmp rbx, char
    je read_char

    cmp rbx, integer
    je read_int

    cmp rbx, binar
    je read_binary

    cmp rbx, octal
    je read_octal

    cmp rbx, hexx
    je read_hex

    end_check_param:

    ret

;---------------------------------------------------

read_string:

    call _length
    call _compare_buffer_string_
    call _str_copy

    jmp end_check_param

read_binary:

    jmp end_check_param

read_hex:

    mov rbx, 10h

    call itoa

    jmp end_check_param

read_octal:

    mov rbx, 10o

    call itoa

    jmp end_check_param

read_char:

    mov [buffer + rdi], rax
    inc rdi

    call check_buffer

    jmp end_check_param

read_int:

    mov rbx, 10d

    call itoa

    jmp end_check_param

;----------------------------------------------------

itoa:

    push rcx

    xor rdx, rdx
    xor rsi, rsi
    xor rcx, rcx

next_digit:

    ;mov ebx, 10d    ; eax = 4, edx = 7
    div rbx         ; eax - частное, edx - остаток

    push rdx        ; запомнил остаток от деления
    inc rsi

    cmp rax, 0      ; number = 0
    je atoi_end

    xor rdx, rdx

    jmp next_digit

    atoi_end:

    mov rcx, rsi
    ;mov rcx, 3h
put_number:

    pop rax
    add rax, "0"
    mov [buffer + rdi], rax
    xor rax, rax
    inc rdi
    call check_buffer

    cmp rbp, RESET_THE_BUF
    jne next_iteration

    call dtor_buffer

    next_iteration:

    loop put_number

    ;xor rbp, rbp
    pop rcx

    ret

;---------------------------------------------------

_length:

    mov rsi, -1

    next_symbol:

    inc rsi
    mov rcx, [rax + rsi]

    cmp rcx, 0
    je str_end

    jmp next_symbol

    str_end:

    ;add rsi, "0"
    ;mov [buffer + rdi], rsi
    ;inc rdi
    ;sub rsi, "0"
    ret

;---------------------------------------------------

_compare_buffer_string_:

    cmp rsi, buffer_size
    jb end_compare

    push rdi

    mov rdx, rsi
    mov rsi, rax
    mov rax, 0x01
    mov rdi, 1
    syscall

    pop rdi
    pop rbp ;забираем адрес возврата из стека
    jmp end_check_param

    end_compare:
    ret

;---------------------------------------------------

_str_copy:

    push rdx
    push rbx
    xor rbx, rbx
    xor rdx, rdx

    mov rbx, rax         ;str1 address
    mov rcx, rsi         ;length of str1
    add rdi, buffer      ;current position of free element

    next_symbol_pr_s:

    mov rax, [rbx + rdx]   ;rax = [str1 + num_repeat]
    inc rdx                ;num_repeat++

    call cycle_checker

    stosb                  ;[rdi++] = rax
    loop next_symbol_pr_s

    sub rdi, buffer
    pop rbx
    pop rdx

    ret

;---------------------------------------------------

cycle_checker:

    push rdi

    sub rdi, buffer

    call check_buffer

    cmp rbp, RESET_THE_BUF
    jne work_with_current_buf

    call dtor_buffer

    pop rdi

    mov rdi, buffer
    jmp end_func

    work_with_current_buf:

    pop rdi

    end_func:

    ret

;---------------------------------------------------

printf_buf:

    call _global_push

    mov rax, 0x01
    mov rdi, 1
    mov rsi, buffer
    mov rdx, buffer_size
    syscall

    call _global_pop
    ret

;---------------------------------------------

check_buffer:

    cmp rdi, buffer_size
    jb _back

    call printf_buf
    mov rbp, RESET_THE_BUF

    _back:
    ret

;---------------------------------------------

next_line:

    call _global_push

    mov rax, 0x01
    mov rdi, 1
    mov rsi, symbol
    mov rdx, 1
    syscall

    call _global_pop
    ret

;----------------------------------------------

dtor_buffer:

    call _global_push

    mov rax, 0
    mov rcx, buffer_size
    mov rdi, 0
    erase_next:

    mov [buffer + rdi], rax
    inc rdi

    loop erase_next

    xor rdi, rdi

    call _global_pop

    ret

;----------------------------------------------

_global_push:

    pop rbp ;занесли адрес возврата в rbp

    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    push rbp ;вернули адрес возврата в стек для ret
    ret

;----------------------------------------------

_global_pop:

    pop rbp ;занесли адрес возврата в rbp

    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax

    push rbp ;вернули адрес возврата в стек для ret
    ret
;---------------------------------------------

_global_xor:

    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    xor rdi, rdi
    xor rsi, rsi

    ret

;---------------------------------------------

section .data

    symbol db 10          ;aski \n
    str1   db "qwertyu", 0

    procent equ 25h

    string  equ "%s"
    char    equ "%c"
    integer equ "%d"
    hexx    equ "%x"
    octal   equ "%o"
    binar   equ "%b"

    RESET_THE_BUF equ 77

    buffer_size equ 100

section .bss

    buffer db 100 dup(?)


