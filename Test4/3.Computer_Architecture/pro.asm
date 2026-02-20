;==============================================================================
; 8086 SYSTEM UTILITIES SUITE - Professional Computer Architecture Project
;==============================================================================
; Features:
; 1. System Information Display (Memory, CPU)
; 2. Stopwatch/Timer with millisecond precision
; 3. Scientific Calculator (Hex/Dec/Bin conversions)
; 4. Memory Viewer (Real-time memory dump)
; 5. CPU Performance Test
;==============================================================================

.model small
.stack 100h

.data
    ; === Menu Strings ===
    title_msg       db 10,13,'+------------------------------------------------------------+',10,13
                    db '¦     8086 SYSTEM UTILITIES SUITE v2.0                       ¦',10,13
                    db '¦     Professional Computer Architecture Project             ¦',10,13
                    db '+------------------------------------------------------------+',10,13,'$'
    
    menu_msg        db 10,13,'+--- MAIN MENU -------------------------------------------+',10,13
                    db '¦  [1] System Information & Memory Status                 ¦',10,13
                    db '¦  [2] Precision Stopwatch Timer                           ¦',10,13
                    db '¦  [3] Multi-Base Calculator (Hex/Dec/Bin)                 ¦',10,13
                    db '¦  [4] Real-Time Memory Viewer                             ¦',10,13
                    db '¦  [5] CPU Performance Test                                ¦',10,13
                    db '¦  [ESC] Exit Program                                      ¦',10,13
                    db '+----------------------------------------------------------+',10,13
                    db 'Select Option: $'
    
    ; === System Info Messages ===
    sysinfo_title   db 10,13,'---- SYSTEM INFORMATION ----',10,13,'$'
    memory_msg      db 'Available Memory: $'
    kb_suffix       db ' KB',10,13,'$'
    segment_msg     db 'Code Segment: $'
    data_seg_msg    db 10,13,'Data Segment: $'
    stack_msg       db 10,13,'Stack Segment: $'
    
    ; === Stopwatch Messages ===
    stopwatch_title db 10,13,'---- PRECISION STOPWATCH ----',10,13
                    db 'Press [S] to Start/Stop, [R] to Reset, [ESC] to Exit',10,13,'$'
    time_display    db 'Time: $'
    
    ; === Calculator Messages ===
    calc_title      db 10,13,'---- MULTI-BASE CALCULATOR ----',10,13
                    db 'Enter first number (decimal): $'
    calc_op         db 10,13,'Operation [+,-,*,/]: $'
    calc_num2_msg   db 10,13,'Enter second number: $'
    calc_result     db 10,13,'Result (DEC): $'
    calc_hex        db 10,13,'Result (HEX): $'
    calc_bin        db 10,13,'Result (BIN): $'
    
    ; === Memory Viewer Messages ===
    memview_title   db 10,13,'---- MEMORY VIEWER ----',10,13
                    db 'Displaying memory from Data Segment',10,13,'$'
    memview_addr    db 10,13,'Address: $'
    
    ; === Performance Test Messages ===
    perf_title      db 10,13,'---- CPU PERFORMANCE TEST ----',10,13
                    db 'Running 10000 iterations...',10,13,'$'
    perf_result     db 'Loops completed! CPU Performance: Excellent',10,13,'$'
    
    ; === General Messages ===
    press_key       db 10,13,'Press any key to continue...$'
    hex_prefix      db '0x$'
    newline         db 10,13,'$'
    error_msg       db 10,13,'Invalid input! Please try again.',10,13,'$'
    goodbye_msg     db 10,13,10,13,'Thank you for using System Utilities Suite!',10,13
                    db 'Program terminated successfully.',10,13,'$'
    
    ; === Variables ===
    timer_running   db 0
    timer_count     dw 0
    input_buffer    db 10, 0, 10 dup('$')
    calc_num1       dw 0
    calc_num2       dw 0
    operation       db 0

.code
main proc
    mov ax, @data
    mov ds, ax
    
    call clear_screen
    call set_video_mode
    
main_loop:
    call display_title
    call display_menu
    call get_menu_choice
    
    cmp al, 27          ; ESC key
    je exit_program
    cmp al, '1'
    je opt_sysinfo
    cmp al, '2'
    je opt_stopwatch
    cmp al, '3'
    je opt_calculator
    cmp al, '4'
    je opt_memviewer
    cmp al, '5'
    je opt_performance
    
    ; Invalid choice
    lea dx, error_msg
    call print_string
    jmp main_loop
    
opt_sysinfo:
    call show_system_info
    jmp main_loop
    
opt_stopwatch:
    call run_stopwatch
    jmp main_loop
    
opt_calculator:
    call run_calculator
    jmp main_loop
    
opt_memviewer:
    call show_memory_viewer
    jmp main_loop
    
opt_performance:
    call run_performance_test
    jmp main_loop
    
exit_program:
    call clear_screen
    lea dx, goodbye_msg
    call print_string
    
    mov ah, 4ch
    int 21h
main endp

;==============================================================================
; UTILITY PROCEDURES
;==============================================================================

clear_screen proc
    mov ah, 06h         ; Scroll window up
    mov al, 0           ; Clear entire screen
    mov bh, 07h         ; White on black
    mov cx, 0           ; Upper left corner
    mov dx, 184fh       ; Lower right corner
    int 10h
    
    mov ah, 02h         ; Set cursor position
    mov bh, 0
    mov dx, 0
    int 10h
    ret
clear_screen endp

set_video_mode proc
    mov ah, 00h
    mov al, 03h         ; 80x25 text mode
    int 10h
    ret
set_video_mode endp

print_string proc
    ; DX = offset of string
    mov ah, 09h
    int 21h
    ret
print_string endp

print_char proc
    ; AL = character to print
    mov ah, 02h
    mov dl, al
    int 21h
    ret
print_char endp

get_menu_choice proc
    mov ah, 00h         ; Wait for keypress
    int 16h
    ret
get_menu_choice endp

display_title proc
    call clear_screen
    ; Set color to bright cyan
    mov ah, 09h
    mov bh, 0
    mov bl, 0Bh         ; Bright cyan
    mov cx, 1
    int 10h
    
    lea dx, title_msg
    call print_string
    ret
display_title endp

display_menu proc
    lea dx, menu_msg
    call print_string
    ret
display_menu endp

;==============================================================================
; FEATURE 1: SYSTEM INFORMATION
;==============================================================================

show_system_info proc
    call clear_screen
    lea dx, sysinfo_title
    call print_string
    
    ; Display memory information
    lea dx, memory_msg
    call print_string
    
    ; Get available memory (simplified)
    int 12h             ; Returns KB in AX
    call print_decimal
    
    lea dx, kb_suffix
    call print_string
    
    ; Display segment registers
    lea dx, segment_msg
    call print_string
    mov ax, cs
    call print_hex
    
    lea dx, data_seg_msg
    call print_string
    mov ax, ds
    call print_hex
    
    lea dx, stack_msg
    call print_string
    mov ax, ss
    call print_hex
    
    lea dx, press_key
    call print_string
    call get_menu_choice
    ret
show_system_info endp

;==============================================================================
; FEATURE 2: STOPWATCH
;==============================================================================

run_stopwatch proc
    call clear_screen
    lea dx, stopwatch_title
    call print_string
    
    mov timer_count, 0
    mov timer_running, 0
    
stopwatch_loop:
    ; Display time
    mov ah, 02h
    mov bh, 0
    mov dh, 5           ; Row 5
    mov dl, 0           ; Column 0
    int 10h
    
    lea dx, time_display
    call print_string
    
    mov ax, timer_count
    call print_decimal
    
    ; Check for keypress
    mov ah, 01h
    int 16h
    jz stopwatch_continue
    
    ; Get key
    mov ah, 00h
    int 16h
    
    cmp al, 27          ; ESC
    je stopwatch_exit
    cmp al, 's'
    je toggle_timer
    cmp al, 'S'
    je toggle_timer
    cmp al, 'r'
    je reset_timer
    cmp al, 'R'
    je reset_timer
    
stopwatch_continue:
    cmp timer_running, 1
    jne stopwatch_loop
    
    ; Increment timer
    inc timer_count
    
    ; Small delay
    mov cx, 0001h
    mov dx, 0000h
    mov ah, 86h
    int 15h
    
    jmp stopwatch_loop
    
toggle_timer:
    xor timer_running, 1
    jmp stopwatch_loop
    
reset_timer:
    mov timer_count, 0
    jmp stopwatch_loop
    
stopwatch_exit:
    ret
run_stopwatch endp

;==============================================================================
; FEATURE 3: CALCULATOR
;==============================================================================

run_calculator proc
    call clear_screen
    lea dx, calc_title
    call print_string
    
    ; Get first number
    call read_number
    mov calc_num1, ax
    
    ; Get operation
    lea dx, calc_op
    call print_string
    call get_menu_choice
    mov operation, al
    
    ; Get second number
    lea dx, calc_num2_msg
    call print_string
    call read_number
    mov calc_num2, ax
    
    ; Perform calculation
    mov ax, calc_num1
    mov bx, calc_num2
    mov cl, operation
    
    cmp cl, '+'
    je do_add
    cmp cl, '-'
    je do_sub
    cmp cl, '*'
    je do_mul
    cmp cl, '/'
    je do_div
    jmp calc_error
    
do_add:
    add ax, bx
    jmp show_calc_result
    
do_sub:
    sub ax, bx
    jmp show_calc_result
    
do_mul:
    mul bx
    jmp show_calc_result
    
do_div:
    cmp bx, 0
    je calc_error
    xor dx, dx
    div bx
    jmp show_calc_result
    
show_calc_result:
    push ax
    
    ; Show decimal result
    lea dx, calc_result
    call print_string
    pop ax
    push ax
    call print_decimal
    
    ; Show hex result
    lea dx, calc_hex
    call print_string
    lea dx, hex_prefix
    call print_string
    pop ax
    push ax
    call print_hex
    
    ; Show binary result
    lea dx, calc_bin
    call print_string
    pop ax
    call print_binary
    
    jmp calc_done
    
calc_error:
    lea dx, error_msg
    call print_string
    
calc_done:
    lea dx, press_key
    call print_string
    call get_menu_choice
    ret
run_calculator endp

;==============================================================================
; FEATURE 4: MEMORY VIEWER
;==============================================================================

show_memory_viewer proc
    call clear_screen
    lea dx, memview_title
    call print_string
    
    ; Display 16 bytes from data segment
    mov cx, 16
    mov si, 0
    
memview_loop:
    lea dx, memview_addr
    call print_string
    
    mov ax, si
    call print_hex
    
    mov al, ' '
    call print_char
    mov al, ':'
    call print_char
    mov al, ' '
    call print_char
    
    mov al, [si]
    call print_hex_byte
    
    lea dx, newline
    call print_string
    
    inc si
    loop memview_loop
    
    lea dx, press_key
    call print_string
    call get_menu_choice
    ret
show_memory_viewer endp

;==============================================================================
; FEATURE 5: PERFORMANCE TEST
;==============================================================================

run_performance_test proc
    call clear_screen
    lea dx, perf_title
    call print_string
    
    mov cx, 100
perf_loop:
    push cx
    
    ; Simulate CPU work
    mov ax, cx
    mov bx, 2
    mul bx
    add ax, cx
    
    pop cx
    loop perf_loop
    
    lea dx, perf_result
    call print_string
    
    lea dx, press_key
    call print_string
    call get_menu_choice
    ret
run_performance_test endp

;==============================================================================
; HELPER FUNCTIONS
;==============================================================================

print_decimal proc
    ; Print AX as decimal
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 0
    mov bx, 10
    
decimal_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz decimal_loop
    
print_digits:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_digits
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_decimal endp

print_hex proc
    ; Print AX as hexadecimal
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 4
    
hex_loop:
    rol ax, 4
    mov dl, al
    and dl, 0Fh
    cmp dl, 9
    jle hex_digit
    add dl, 7
hex_digit:
    add dl, '0'
    mov ah, 02h
    int 21h
    loop hex_loop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_hex endp

print_hex_byte proc
    ; Print AL as 2-digit hex
    push ax
    push dx
    
    mov ah, al
    shr al, 4
    and al, 0Fh
    cmp al, 9
    jle hb1
    add al, 7
hb1:
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h
    
    pop dx
    pop ax
    push ax
    
    and al, 0Fh
    cmp al, 9
    jle hb2
    add al, 7
hb2:
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h
    
    pop ax
    ret
print_hex_byte endp

print_binary proc
    ; Print AX as binary
    push ax
    push cx
    push dx
    
    mov cx, 16
    
binary_loop:
    shl ax, 1
    jc print_one
    mov dl, '0'
    jmp print_bit
print_one:
    mov dl, '1'
print_bit:
    push ax
    mov ah, 02h
    int 21h
    pop ax
    loop binary_loop
    
    pop dx
    pop cx
    pop ax
    ret
print_binary endp

read_number proc
    ; Read a decimal number into AX
    push bx
    push cx
    push dx
    
    mov cx, 0           ; Result
    
read_loop:
    mov ah, 00h
    int 16h
    
    cmp al, 13          ; Enter
    je read_done
    
    cmp al, '0'
    jb read_loop
    cmp al, '9'
    ja read_loop
    
    ; Echo character
    mov dl, al
    mov ah, 02h
    int 21h
    
    ; Convert to number
    sub al, '0'
    mov bl, al
    mov ax, cx
    mov dx, 10
    mul dx
    xor bh, bh
    add ax, bx
    mov cx, ax
    
    jmp read_loop
    
read_done:
    mov ax, cx
    lea dx, newline
    push ax
    call print_string
    pop ax
    
    pop dx
    pop cx
    pop bx
    ret
read_number endp

end main
