; ========================================
; PROFESSIONAL 8086 CALCULATOR
; ========================================
; Features:
; - Addition, Subtraction, Multiplication, Division
; - Interactive menu system
; - Input validation
; - Error handling for division by zero
; - User-friendly interface
; ========================================

.MODEL SMALL
.STACK 100H

.DATA
    ; Menu Strings
    banner      DB 0DH,0AH,'+======================================+',0DH,0AH
                DB '|           8086 CALCULATOR                     |',0DH,0AH
                DB '+======================================+',0DH,0AH,'$'
    
    menu        DB 0DH,0AH,'+-------------------------------------+',0DH,0AH
                DB '|  Select Operation:                  |',0DH,0AH
                DB '|  1. Addition       (+)              |',0DH,0AH
                DB '|  2. Subtraction    (-)              |',0DH,0AH
                DB '|  3. Multiplication (x)              |',0DH,0AH
                DB '|  4. Division       (/)              |',0DH,0AH
                DB '|  5. Exit                            |',0DH,0AH
                DB '+-------------------------------------+',0DH,0AH
                DB 'Enter your choice (1-5): $'
    
    prompt1     DB 0DH,0AH,'Enter first number (0-9999): $'
    prompt2     DB 0DH,0AH,'Enter second number (0-9999): $'
    
    result_msg  DB 0DH,0AH,0DH,0AH,'=======================================',0DH,0AH
                DB ' RESULT: $'
    
    add_sign    DB ' + $'
    sub_sign    DB ' - $'
    mul_sign    DB ' x $'
    div_sign    DB ' / $'
    equal_sign  DB ' = $'
    
    quotient_msg DB 0DH,0AH,' Quotient: $'
    remainder_msg DB 0DH,0AH,' Remainder: $'
    
    div_error   DB 0DH,0AH,' ERROR: Division by zero!',0DH,0AH,'$'
    invalid_msg DB 0DH,0AH,' ERROR: Invalid choice! Please try again.',0DH,0AH,'$'
    
    continue_msg DB 0DH,0AH,'=======================================',0DH,0AH
                DB 0DH,0AH,'Press any key to continue...$'
    
    exit_msg    DB 0DH,0AH,0DH,0AH,'Thank you for using the calculator!',0DH,0AH
                DB 'Goodbye!',0DH,0AH,'$'
    
    ; Variables
    num1        DW 0
    num2        DW 0
    result      DW 0
    quotient    DW 0
    remainder   DW 0
    choice      DB 0
    temp        DW 0

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
MAIN_LOOP:
    ; Clear screen (optional - using multiple newlines)
    CALL CLEAR_SCREEN
    
    ; Display banner
    LEA DX, banner
    MOV AH, 09H
    INT 21H
    
    ; Display menu
    LEA DX, menu
    MOV AH, 09H
    INT 21H
    
    ; Get user choice
    MOV AH, 01H
    INT 21H
    SUB AL, '0'
    MOV choice, AL
    
    ; Validate choice
    CMP choice, 1
    JL INVALID_CHOICE
    CMP choice, 5
    JG INVALID_CHOICE
    
    ; Check if exit
    CMP choice, 5
    JE EXIT_PROGRAM
    
    ; Get first number
    LEA DX, prompt1
    MOV AH, 09H
    INT 21H
    CALL READ_NUMBER
    MOV num1, AX
    
    ; Get second number
    LEA DX, prompt2
    MOV AH, 09H
    INT 21H
    CALL READ_NUMBER
    MOV num2, AX
    
    ; Perform operation based on choice
    MOV AL, choice
    CMP AL, 1
    JE DO_ADDITION
    CMP AL, 2
    JE DO_SUBTRACTION
    CMP AL, 3
    JE DO_MULTIPLICATION
    CMP AL, 4
    JE DO_DIVISION
    
DO_ADDITION:
    MOV AX, num1
    ADD AX, num2
    MOV result, AX
    
    ; Display result
    LEA DX, result_msg
    MOV AH, 09H
    INT 21H
    
    MOV AX, num1
    CALL PRINT_NUMBER
    
    LEA DX, add_sign
    MOV AH, 09H
    INT 21H
    
    MOV AX, num2
    CALL PRINT_NUMBER
    
    LEA DX, equal_sign
    MOV AH, 09H
    INT 21H
    
    MOV AX, result
    CALL PRINT_NUMBER
    
    JMP CONTINUE_PROMPT
    
DO_SUBTRACTION:
    MOV AX, num1
    SUB AX, num2
    MOV result, AX
    
    ; Display result
    LEA DX, result_msg
    MOV AH, 09H
    INT 21H
    
    MOV AX, num1
    CALL PRINT_NUMBER
    
    LEA DX, sub_sign
    MOV AH, 09H
    INT 21H
    
    MOV AX, num2
    CALL PRINT_NUMBER
    
    LEA DX, equal_sign
    MOV AH, 09H
    INT 21H
    
    MOV AX, result
    CALL PRINT_NUMBER
    
    JMP CONTINUE_PROMPT
    
DO_MULTIPLICATION:
    MOV AX, num1
    MOV BX, num2
    MUL BX          ; Result in DX:AX
    MOV result, AX
    
    ; Display result
    LEA DX, result_msg
    MOV AH, 09H
    INT 21H
    
    MOV AX, num1
    CALL PRINT_NUMBER
    
    LEA DX, mul_sign
    MOV AH, 09H
    INT 21H
    
    MOV AX, num2
    CALL PRINT_NUMBER
    
    LEA DX, equal_sign
    MOV AH, 09H
    INT 21H
    
    MOV AX, result
    CALL PRINT_NUMBER
    
    JMP CONTINUE_PROMPT
    
DO_DIVISION:
    ; Check for division by zero
    CMP num2, 0
    JE DIVISION_ERROR
    
    MOV AX, num1
    MOV DX, 0       ; Clear DX for division
    MOV BX, num2
    DIV BX          ; Quotient in AX, Remainder in DX
    MOV quotient, AX
    MOV remainder, DX
    
    ; Display result
    LEA DX, result_msg
    MOV AH, 09H
    INT 21H
    
    MOV AX, num1
    CALL PRINT_NUMBER
    
    LEA DX, div_sign
    MOV AH, 09H
    INT 21H
    
    MOV AX, num2
    CALL PRINT_NUMBER
    
    LEA DX, quotient_msg
    MOV AH, 09H
    INT 21H
    
    MOV AX, quotient
    CALL PRINT_NUMBER
    
    LEA DX, remainder_msg
    MOV AH, 09H
    INT 21H
    
    MOV AX, remainder
    CALL PRINT_NUMBER
    
    JMP CONTINUE_PROMPT
    
DIVISION_ERROR:
    LEA DX, div_error
    MOV AH, 09H
    INT 21H
    JMP CONTINUE_PROMPT
    
INVALID_CHOICE:
    LEA DX, invalid_msg
    MOV AH, 09H
    INT 21H
    JMP CONTINUE_PROMPT
    
CONTINUE_PROMPT:
    LEA DX, continue_msg
    MOV AH, 09H
    INT 21H
    
    ; Wait for key press
    MOV AH, 01H
    INT 21H
    
    JMP MAIN_LOOP
    
EXIT_PROGRAM:
    LEA DX, exit_msg
    MOV AH, 09H
    INT 21H
    
    MOV AH, 4CH
    INT 21H
MAIN ENDP

; ========================================
; Procedure: READ_NUMBER
; Description: Reads a multi-digit number from keyboard
; Input: None
; Output: AX = number entered
; ========================================
READ_NUMBER PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX, 0       ; BX will store the result
    MOV CX, 0       ; CX will count digits
    
READ_LOOP:
    MOV AH, 01H     ; Read character
    INT 21H
    
    CMP AL, 0DH     ; Check for Enter key
    JE READ_DONE
    
    CMP AL, '0'     ; Validate digit
    JL READ_LOOP
    CMP AL, '9'
    JG READ_LOOP
    
    ; Convert ASCII to digit
    SUB AL, '0'
    MOV AH, 0
    
    ; Multiply current result by 10
    PUSH AX
    MOV AX, BX
    MOV DX, 10
    MUL DX
    MOV BX, AX
    POP AX
    
    ; Add new digit
    ADD BX, AX
    INC CX
    
    CMP CX, 4       ; Limit to 4 digits
    JL READ_LOOP
    
READ_DONE:
    MOV AX, BX
    
    POP DX
    POP CX
    POP BX
    RET
READ_NUMBER ENDP

; ========================================
; Procedure: PRINT_NUMBER
; Description: Prints a number in AX
; Input: AX = number to print
; Output: None
; ========================================
PRINT_NUMBER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV CX, 0       ; Digit counter
    MOV BX, 10      ; Divisor
    
    ; Handle special case of 0
    CMP AX, 0
    JNE CONVERT_LOOP
    PUSH AX
    MOV DL, '0'
    MOV AH, 02H
    INT 21H
    POP AX
    JMP PRINT_DONE
    
CONVERT_LOOP:
    CMP AX, 0
    JE PRINT_LOOP
    
    MOV DX, 0
    DIV BX          ; Divide by 10
    PUSH DX         ; Save remainder (digit)
    INC CX          ; Count digit
    JMP CONVERT_LOOP
    
PRINT_LOOP:
    CMP CX, 0
    JE PRINT_DONE
    
    POP DX          ; Get digit
    ADD DL, '0'     ; Convert to ASCII
    MOV AH, 02H     ; Print character
    INT 21H
    DEC CX
    JMP PRINT_LOOP
    
PRINT_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUMBER ENDP

; ========================================
; Procedure: CLEAR_SCREEN
; Description: Clears the screen using newlines
; Input: None
; Output: None
; ========================================
CLEAR_SCREEN PROC
    PUSH AX
    PUSH CX
    PUSH DX
    
    MOV CX, 25      ; Print 25 newlines
CLEAR_LOOP:
    MOV AH, 02H
    MOV DL, 0DH     ; Carriage return
    INT 21H
    MOV DL, 0AH     ; Line feed
    INT 21H
    LOOP CLEAR_LOOP
    
    POP DX
    POP CX
    POP AX
    RET
CLEAR_SCREEN ENDP

END MAIN
