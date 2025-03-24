section .text
global _start

_start:

    mov rsi, 10235
    mov rdi, proc_b    ;dint db "%d$"
    mov rax, 0

    jmp _printf_push
    back_pr_push:

    jmp _rep_check_params
    back_rep_check_params:

    call printf_buf
    call next_line

    call dtor_buffer
    call _global_xor

    mov rax, 0x3C
    xor rdi, rdi
    syscall

;-------------------------------------------------

_rep_check_params:

get_next_arg:

    mov bl, byte [rdi]
    cmp byte [rdi], "$" ;% - d - $
    jz args_end

    cmp byte [rdi], "%"
    jne not_procent

    inc rdi
    cmp byte [rdi], "%"
    je not_back_slash_n

    call check_param
    inc rdi
    jmp get_next_arg

    not_procent:
    cmp byte [rdi], "\" ;back slash
    jne not_back_slash_n

    inc rdi
    cmp byte [rdi], "n"
    jne not_back_slash_n

    mov bl, 0x0A
    mov [buffer + r15], bl
    inc r15
    inc rdi

    jmp get_next_arg

    not_back_slash_n:

    mov bl, byte [rdi]
    mov [buffer + r15], bl
    inc rdi
    inc r15

    jmp get_next_arg

    args_end:

    jmp back_rep_check_params

;-------------------------------------------------

check_param:

    pop r9
    pop rax
    push rdi

    cmp byte [rdi], "s"
    je read_string

    cmp byte [rdi], "c"
    je read_char

    cmp byte [rdi], "d"
    je read_int

    cmp byte [rdi], "b"
    je read_binary

    cmp byte [rdi], "o"
    je read_octal

    cmp byte [rdi], "h"
    je read_hex

    cmp byte [rdi], "b"
    je read_binary

    end_check_param:

    pop rdi
    push r9
    ret

;---------------------------------------------------

read_string:

    call _length
    call _compare_buffer_string_

    mov rdi, r15
    call _str_copy
    add r15, rdi

    jmp end_check_param

read_binary:

    mov rbx, 2d

    mov rdi, r15

    call itoa

    add r15, rdi

    jmp end_check_param

read_hex:

    mov rbx, 10h

    mov rdi, r15

    call itoa

    add r15, rdi

    jmp end_check_param

read_octal:

    mov rbx, 10o

    mov rdi, r15

    call itoa

    add r15, rdi

    jmp end_check_param

read_char:

    mov [buffer + r15], rax
    inc r15

    call check_buffer

    jmp end_check_param

read_int:

    mov rbx, 10d

    mov rdi, r15

    call itoa

    add r15, rdi

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

    pop rcx

    ret

;---------------------------------------------------

_length:

    xor rcx, rcx
    dec rax
    mov rsi, -1

    next_symbol:
    inc rax
    inc rsi

    mov cl, byte [rax]
    cmp cl, 0
    je str_end

    jmp next_symbol

    str_end:

    sub rax, rsi

    ;add rsi, "0"
    ;mov [buffer + r15], rsi
    ;inc r15
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
    xor rdx, rdx

    mov rbx, rax         ;str1 address
    mov rcx, rsi         ;length of str1
    add rdi, buffer      ;current position of free element
    xor rax, rax

    next_symbol_pr_s:

    mov al, byte [rbx + rdx]   ;rax = [str1 + num_repeat]
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

_printf_push:

    ;pop rax ;занесли адрес возврата в rbp

    push r9
    push r8
    push rcx
    push rdx
    push rsi

    ;push rax ;вернули адрес возврата в стек для ret
    jmp back_pr_push

;---------------------------------------------

section .data

    symbol db 10          ;aski \n
    str1   db "dgs", 0
    str2   db "hahdr", 0
    dint db "%d hyi %d - %d:%d$", 0
    new_str db "%s\n%s %%%c||||%o\n\n\n%%$"
    proc_b db "%b$"
    procent equ 25h

    RESET_THE_BUF equ 77

    buffer_size equ 100

section .bss

    buffer db 100 dup(?)



