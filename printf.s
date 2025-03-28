;/////////////////////////SystemV ABI\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
;In convention of function calls there are some rules:
;First 6 arguments are located in registers: RDI, RSI, RDC, RCX, R8, R9
;in exactly this order, next args are located in stack
;Registers RDB, RBX, R13-R15 - untouchable regs, they needed no convention,
;if you have to use it, before that - push it to stack
;
;main function of your program must be a default func for C calling like:
;-------------------------
;call my_darling_printf
; ...
; ret
;-------------------------
;you need return to C, so cause of that you have to remember return address
;when you get in asm
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\///////////////////////////////////////


;global _start
;TODO jump table godbolt. godbolt
;_start:

;========================================TEXT===============================================

section .text
global my_printf
my_printf:

    pop rax
    mov [adr_main_to_syka_C], rax
    ;push 13
    ;push 12
    ;push 11
    ;push 10
    ;push 99
    ;push 88
    ;push 77
    ;push 66
    ;mov r9,  55
    ;mov r8,  44
    ;mov rcx, 33
    ;mov rdx, 22
    ;mov rsi, 11
    ;mov rdi, new_str;"%d$"

    call _printf_push

    call _rep_check_params

    call printf_buf
    call next_line

    call dtor_buffer
    call _global_xor

    mov rax, 0
    mov rcx, [adr_main_to_syka_C]
    push rcx
    ret

    ;mov rax, 0x3C
    ;xor rdi, rdi
    ;syscall

;----------------------_REP_CHECK_PARAMS-----------------------------
;_rep_check_params is a function that in cycle go on a format string
;and take specificators and symbols in it
;entry: rdi - address of format string, [b_index] - index of the first free element in
;buffer for output, buffer - address of buffer for output
;exit:  rdi - address of current elem in format string
;--------------------------------------------------------------------

_rep_check_params:

    pop qword [adr_rep_ch_param]
    xor rcx, rcx

get_next_arg:

    cmp byte [rdi], "$" ;% - d - $
    jz args_end

    cmp byte [rdi], "%"
    jne not_procent

    inc rdi
    cmp byte [rdi], "%"
    je print_sym

    call check_param
    inc rdi
    jmp get_next_arg

    not_procent:
    cmp byte [rdi], "\" ;back slash
    jne print_sym

    inc rdi
    cmp byte [rdi], "n"
    jne print_sym

    mov al, 0x0A
    mov cx, [b_index]
    mov [buffer + rcx], al
    inc word [b_index]
    inc rdi

    jmp get_next_arg

    print_sym:

    mov bl, byte [rdi]
    mov cx, [b_index]
    mov [buffer + rcx], bl
    inc rdi
    inc word [b_index]

    jmp get_next_arg

    args_end:

    push qword [adr_rep_ch_param]
    ret

;-------------------------CHECK_PARAM-------------------------------
;check_param - checked concrete specificators and jump to funcs that
;put arguments into buffer
;entry: rdi - address of current elem in format string
;exit:  edx - notation
;-------------------------------------------------------------------

check_param:

    pop qword [adr_ch_param]
    pop rax
    push rdi

    cmp byte [rdi], "s"
    je read_string

    cmp byte [rdi], "c"
    je read_char

    cmp byte [rdi], "d"
    mov edx, 10d
    je read_number

    cmp byte [rdi], "o"
    mov edx, 10o
    je read_number

    cmp byte [rdi], "x"
    mov edx, 10h
    je read_number

    cmp byte [rdi], "b"
    mov edx, 2d
    je read_number

    end_check_param:

    pop rdi
    push qword [adr_ch_param]
    ret

;-------------------------READ_STRING-------------------------------
;read_string - process string arg by funcs: define_length, str_copy and
;_compare_buffer_string_
;entry: rdi - address of current free elem in buffer
;exit:  [b_index] - address of current free elem in buffer
;-------------------------------------------------------------------

read_string:

    call define_length
    call _compare_buffer_string_

    mov rdi, [b_index]
    call _str_copy
    add [b_index], rdi

    jmp end_check_param

;-------------------------READ_CHAR---------------------------------
;read_char - put symbol into buffer and checked bufferisation
;entry: rax - current symbol (argument)
;exit:  [b_index] - address of current elem in format string
;-------------------------------------------------------------------

read_char:

    mov rcx, [b_index]
    mov [buffer + rcx], rax
    inc word [b_index]

    call check_buffer

    jmp end_check_param

;-------------------------------------------------------------------

read_octal:

read_hex:

read_binary:

read_integer:

    mov edx, 10d
    mov [notation], edx
    call read_number

    jmp end_check_param

;-------------------------READ_NUMBER-------------------------------
;read_number - process number bu func itoa
;entry: edx - notation
;exit:  [b_index] - address of current elem in format string
;-------------------------------------------------------------------

read_number:

    mov [notation], edx
    xor rdi, rdi
    mov rdi, [b_index]

    call itoa

    mov [b_index], rdi

    jmp end_check_param
    ;ret

;--------------------------ITOA-------------------------------------
;itoa - convertation number -> string (15 -> "1, 5")
;entry: [notation] - system of notation (number on that we div),
;[buffer] - buffer for output, [buffer_overflow] - id of buffer_overflow
;exit:  rdi - address of current free elem in buffer
;-------------------------------------------------------------------

itoa:

    push rcx

    xor rdx, rdx
    xor rsi, rsi
    xor rcx, rcx

next_digit:

    ;mov ebx, 10d    ; eax = 4, edx = 7
    div dword [notation]         ; eax - частное, edx - остаток

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
    inc rdi
    call check_buffer

    cmp byte [buffer_overflow], RESET_THE_BUF
    jne next_iteration

    mov byte [buffer_overflow], 0
    call dtor_buffer
    ;mov [buffer + rdi], rax
    ;inc rdi

    next_iteration:

    loop put_number

    pop rcx

    ret

;-------------------------DEFINE_LENGHT-----------------------------
;define_lenght totally definds lenght of the string
;entry: rax - address of string - arg
;exit:  rsi - length of string - arg
;-------------------------------------------------------------------

define_length:

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

;---------------------COMPARE_BUFFER_STRING-------------------------
;_compare_buffer_string_ - compares lenghts of buffer for output and
;string-arg. If len_buf < len_str function will print string by a system call
;entry: rsi - length of string-arg
;exit:  none
;-------------------------------------------------------------------

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
    pop qword [adr] ;забираем адрес возврата из стека
    jmp end_check_param

    end_compare:
    ret

;--------------------------STR_COPY---------------------------------
;_str_copy - copy string-arg to buffer for output. In every iteration
;calls cycle_checker for check bufferisation
;entry: rax - address of string-arg, rsi - length of string-arg,
;rdi - current position of free element in buffer
;exit:  rdi - address of current free elem in buffer
;-------------------------------------------------------------------

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

;------------------------CYCLE_CHECKER------------------------------
;cycle_checker - calls check_buffer in every iterration of cycle and
;calculates current address of curr free elem in buffer
;entry: buffer - address of buffer for output
;exit:  none
;-------------------------------------------------------------------

cycle_checker:

    push rdi

    sub rdi, buffer

    call check_buffer

    cmp byte [buffer_overflow], RESET_THE_BUF
    jne work_with_current_buf

    call dtor_buffer
    mov byte [buffer_overflow], 0

    pop rdi

    mov rdi, buffer
    jmp end_func

    work_with_current_buf:

    pop rdi

    end_func:

    ret

;------------------------PRINTF_BUF---------------------------------
;printf_buf - printf the whole buffer in console
;entry: buffer - address of buffer for output, buffer_size - max num of buf elems
;exit:  none
;-------------------------------------------------------------------

printf_buf:

    call _global_push

    mov rax, 0x01
    mov rdi, 1
    mov rsi, buffer
    mov rdx, buffer_size
    syscall

    call _global_pop
    ret

;------------------------CHECK_BUFFER-------------------------------
;check_buffer - compares max num of buf elems and address of current
;free elem in buffer. If current elem > buffer_size, function will reset
;buffer and mov to buffer_overflow id of buffers overflowing
;entry: rdi - address of current free elem in buffer, buffer_size -
;max num of buf elems
;exit: [buffer_overflow] - id of buffers overflowing
;-------------------------------------------------------------------

check_buffer:

    cmp rdi, buffer_size
    jb _back

    call printf_buf
    mov byte [buffer_overflow], RESET_THE_BUF

    _back:
    ret

;---------------------------NEXT_LINE-------------------------------
;next_line - put "\n" in console
;entry: [b_index] - address of current free elem in buffer
;exit:  none
;-------------------------------------------------------------------

next_line:

    call _global_push

    mov rax, 0x01
    mov rdi, 1
    mov rsi, symbol
    mov rdx, 1
    syscall

    call _global_pop
    ret

;------------------------DTOR_BUFFER--------------------------------
;dtor_buffer - put 0 (aski = 0 ) symbols in the whole buffer
;entry: buffer - address of buffer for output
;exit:  none
;-------------------------------------------------------------------

dtor_buffer:

    call _global_push ;TODO pusha

    mov rax, 0
    mov rcx, buffer_size
    mov rdi, 0
    erase_next:

    mov [buffer + rdi], rax
    inc rdi

    loop erase_next

    call _global_pop

    xor rdi, rdi
    mov byte [b_index], 0
    ret

;-------------------------------------------------------------------

_global_push:

    pop qword [adr] ;занесли адрес возврата в rbp

    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi

    push qword [adr] ;вернули адрес возврата в стек для ret
    ret

;-------------------------------------------------------------------

_global_pop:

    pop qword [adr] ;занесли адрес возврата в rbp

    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax

    push qword [adr] ;вернули адрес возврата в стек для ret
    ret

;-------------------------------------------------------------------

_global_xor: ;TODO remove

    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    xor rdi, rdi
    xor rsi, rsi

    ret

;-------------------------_PRINTF_PUSH------------------------------
;_printf_push - pushs 5 registers into stack (registers for SystemV ABI)
;entry: none
;exit:  none
;-------------------------------------------------------------------

_printf_push:

    pop qword [adr]     ;TODO либо сбалансированный стек или стековый фрейм юзать

    push r9
    push r8
    push rcx
    push rdx
    push rsi

    push qword [adr] ;вернули адрес возврата в стек для ret
    ret

;----------------------------ERROR----------------------------------
;error - print error message in console
;entry: ErrorMessage - address of er_message, ErrorLen - it's lenghts
;exit:  none
;-------------------------------------------------------------------

error:

    mov rax, 0x01
    mov rdi, 1
    mov rsi, ErrorMessage
    mov rdx, ErrorLen
    syscall

    jmp end_check_param

;-------------------------------------------------------------------

;========================================DATA===============================================
section .data ;//TODO godbolt

JumpTable:

    dq 107 dup (error)
    dq read_binary
    dq read_char
    dq read_integer
    dq 10 dup (error)
    dq read_octal
    dq 3 dup (error)
    dq read_string
    dq 4 dup (error)
    dq read_hex
    dq 135 dup (error)

    adr_main_to_syka_C dq 0 ;TODO use time
    adr_rep_ch_param dq 0
    adr dq 0
    buffer_overflow dq 0
    b_index dq 0
    adr_ch_param dq 0

    notation dd 0

    symbol db 10          ;aski \n
    str1   db "dgs", 0
    str2   db "hahdr", 0
    dint db "%h ta++ ba/?<! {ca}\n%%: %d - %b %o$", 0
    my_few_int db "%s$"
    new_str db "%d %d %d %d %d %d %d %d %d %d %d %d %d\n$"
    proc_b db "%s$"
    procent equ 25h

    RESET_THE_BUF equ 77

    buffer_size equ 9

    ErrorMessage db "Your specificator doesn't exist!", 0x0A
    ErrorLen     equ $ - ErrorMessage

;=========================================BSS===============================================

section .bss

    buffer db 10 dup(?)

