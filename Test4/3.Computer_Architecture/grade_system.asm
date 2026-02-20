;==============================================================================
; STUDENT GRADE MANAGEMENT SYSTEM - Advanced 8086 Assembly Project
;==============================================================================
; Features:
; 1. Add/Edit student records (ID, Name, Grades)
; 2. Calculate GPA and statistics (Average, Min, Max)
; 3. Bubble Sort students by GPA
; 4. Search student by ID or Name
; 5. Generate formatted report cards
; 6. Grade distribution analysis
;==============================================================================

.model small
.stack 100h

.data
    ; === Student Record Structure ===
    ; Each student: ID(4), Name(20), Grade1(2), Grade2(2), Grade3(2), GPA(4)
    MAX_STUDENTS    equ 10
    student_count   dw 0
    
    ; Student database arrays
    student_ids     dw MAX_STUDENTS dup(0)
    student_names   db MAX_STUDENTS * 21 dup('$')  ; 20 chars + null
    student_grade1  dw MAX_STUDENTS dup(0)
    student_grade2  dw MAX_STUDENTS dup(0)
    student_grade3  dw MAX_STUDENTS dup(0)
    student_gpa     dw MAX_STUDENTS dup(0)          ; GPA * 100
    
    ; === Menu & UI Strings ===
    title_msg       db 10,13,'+==============================================================+',10,13
                    db '|    STUDENT GRADE MANAGEMENT SYSTEM v1.0                      |',10,13
                    db '|    Advanced Computer Architecture Project                    |',10,13
                    db '+==============================================================+',10,13,'$'
    
    menu_msg        db 10,13,'+--- MAIN MENU --------------------------------------------+',10,13
                    db '|  [1] Add New Student Record                              |',10,13
                    db '|  [2] Display All Students                                |',10,13
                    db '|  [3] Search Student (by ID)                              |',10,13
                    db '|  [4] Calculate Class Statistics                          |',10,13
                    db '|  [5] Sort Students by GPA                                |',10,13
                    db '|  [6] Generate Report Card                                |',10,13
                    db '|  [7] Grade Distribution Chart                            |',10,13
                    db '|  [ESC] Exit System                                       |',10,13
                    db '+----------------------------------------------------------+',10,13
                    db 'Select Option: $'
    
    ; === Input Prompts ===
    prompt_id       db 10,13,'Enter Student ID (1-9999): $'
    prompt_name     db 10,13,'Enter Student Name (max 20 chars): $'
    prompt_grade1   db 10,13,'Enter Math Grade (0-100): $'
    prompt_grade2   db 10,13,'Enter Physics Grade (0-100): $'
    prompt_grade3   db 10,13,'Enter Chemistry Grade (0-100): $'
    
    ; === Display Headers ===
    header_line     db 10,13,'================================================================',10,13,'$'
    student_header  db 'ID    Name                  Math  Phys  Chem  GPA   Grade',10,13
                    db '----  --------------------  ----  ----  ----  ----  -----',10,13,'$'
    
    ; === Report Messages ===
    report_title    db 10,13,'+==================== REPORT CARD =======================+',10,13,'$'
    report_line     db '=============================================================',10,13,'$'
    stats_title     db 10,13,'============ CLASS STATISTICS ============',10,13,'$'
    avg_msg         db 'Class Average: $'
    highest_msg     db 10,13,'Highest GPA: $'
    lowest_msg      db 10,13,'Lowest GPA: $'
    total_students  db 10,13,'Total Students: $'
    
    ; === Distribution Chart ===
    dist_title      db 10,13,'============ GRADE DISTRIBUTION ============',10,13,'$'
    grade_a         db 'A (90-100): $'
    grade_b         db 10,13,'B (80-89):  $'
    grade_c         db 10,13,'C (70-79):  $'
    grade_d         db 10,13,'D (60-69):  $'
    grade_f         db 10,13,'F (0-59):   $'
    
    ; === Status Messages ===
    success_msg     db 10,13,'[OK] Operation completed successfully!',10,13,'$'
    error_full      db 10,13,'[ERROR] Database full! (Max 10 students)',10,13,'$'
    error_notfound  db 10,13,'[ERROR] Student not found!',10,13,'$'
    error_empty     db 10,13,'[ERROR] No students in database!',10,13,'$'
    error_invalid   db 10,13,'[ERROR] Invalid input! Please try again.',10,13,'$'
    
    ; === General Messages ===
    press_key       db 10,13,'Press any key to continue...$'
    space_str       db '    $'
    newline         db 10,13,'$'
    goodbye_msg     db 10,13,10,13,'Thank you for using Grade Management System!',10,13
                    db 'All data saved. Goodbye!',10,13,'$'
    
    ; === Letter Grade Table ===
    letter_A        db 'A $'
    letter_B        db 'B $'
    letter_C        db 'C $'
    letter_D        db 'D $'
    letter_F        db 'F $'
    
    ; === Working Variables ===
    temp_id         dw 0
    temp_name       db 21 dup('$')
    temp_grade      dw 0
    search_id       dw 0
    input_buffer    db 30 dup('$')
    sort_swapped    db 0

.code
main proc
    mov ax, @data
    mov ds, ax
    
    call clear_screen
    
main_loop:
    call display_title
    call display_menu
    call get_choice
    
    cmp al, 27              ; ESC
    je exit_program
    cmp al, '1'
    je opt_add_student
    cmp al, '2'
    je opt_display_all
    cmp al, '3'
    je opt_search
    cmp al, '4'
    je opt_statistics
    cmp al, '5'
    je opt_sort
    cmp al, '6'
    je opt_report
    cmp al, '7'
    je opt_distribution
    
    lea dx, error_invalid
    call print_string
    jmp main_loop
    
opt_add_student:
    call add_student
    jmp main_loop
    
opt_display_all:
    call display_all_students
    jmp main_loop
    
opt_search:
    call search_student
    jmp main_loop
    
opt_statistics:
    call show_statistics
    jmp main_loop
    
opt_sort:
    call sort_by_gpa
    jmp main_loop
    
opt_report:
    call generate_report
    jmp main_loop
    
opt_distribution:
    call show_distribution
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
    mov ah, 06h
    mov al, 0
    mov bh, 07h
    mov cx, 0
    mov dx, 184fh
    int 10h
    
    mov ah, 02h
    mov bh, 0
    mov dx, 0
    int 10h
    ret
clear_screen endp

print_string proc
    mov ah, 09h
    int 21h
    ret
print_string endp

print_char proc
    mov ah, 02h
    mov dl, al
    int 21h
    ret
print_char endp

get_choice proc
    mov ah, 00h
    int 16h
    ret
get_choice endp

display_title proc
    call clear_screen
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
; FEATURE 1: ADD STUDENT
;==============================================================================

add_student proc
    ; Check if database is full
    mov ax, student_count
    cmp ax, MAX_STUDENTS
    jge db_full
    
    call clear_screen
    lea dx, header_line
    call print_string
    
    ; Get student ID
    lea dx, prompt_id
    call print_string
    call read_number
    mov temp_id, ax
    
    ; Get student name
    lea dx, prompt_name
    call print_string
    
    ; Clear temp_name buffer
    push di
    push cx
    lea di, temp_name
    mov cx, 21
    mov al, '$'
clear_name_loop:
    mov [di], al
    inc di
    loop clear_name_loop
    pop cx
    pop di
    
    lea si, temp_name
    call read_string
    
    ; Get grades
    lea dx, prompt_grade1
    call print_string
    call read_number
    mov temp_grade, ax
    
    ; Store in database
    mov bx, student_count
    shl bx, 1               ; BX = index * 2 (word array)
    
    ; Store ID
    mov ax, temp_id
    mov student_ids[bx], ax
    
    ; Store Grade 1
    mov ax, temp_grade
    mov student_grade1[bx], ax
    
    ; Get Grade 2
    lea dx, prompt_grade2
    call print_string
    call read_number
    mov student_grade2[bx], ax
    
    ; Get Grade 3
    lea dx, prompt_grade3
    call print_string
    call read_number
    mov student_grade3[bx], ax
    
    ; Calculate and store GPA
    call calculate_gpa
    mov student_gpa[bx], ax
    
    ; Store name
    mov bx, student_count
    mov ax, 21
    mul bx
    mov bx, ax
    lea si, temp_name
    lea di, student_names
    add di, bx
    mov cx, 20
copy_name:
    lodsb
    cmp al, '$'         ; Check if end of string
    je pad_name         ; If yes, pad rest with '$'
    stosb
    loop copy_name
    jmp name_copied
    
pad_name:
    mov al, '$'         ; Pad remaining with '$'
pad_loop:
    stosb
    loop pad_loop
    
name_copied:
    inc student_count
    
    lea dx, success_msg
    call print_string
    jmp add_done
    
db_full:
    lea dx, error_full
    call print_string
    
add_done:
    lea dx, press_key
    call print_string
    call get_choice
    ret
add_student endp

calculate_gpa proc
    ; Calculate GPA from three grades stored in grade arrays
    ; GPA = (grade1 + grade2 + grade3) / 3
    ; Result stored as integer (multiply by 100 for 2 decimal places)
    push bx
    
    mov ax, student_grade1[bx]
    add ax, student_grade2[bx]
    add ax, student_grade3[bx]
    
    ; Multiply by 100 for precision
    mov dx, 100
    mul dx
    
    ; Divide by 3
    mov bx, 3
    div bx
    
    pop bx
    ret
calculate_gpa endp

;==============================================================================
; FEATURE 2: DISPLAY ALL STUDENTS
;==============================================================================

display_all_students proc
    call clear_screen
    
    cmp student_count, 0
    je no_students
    
    lea dx, header_line
    call print_string
    lea dx, student_header
    call print_string
    
    mov cx, student_count
    mov si, 0
    
display_loop:
    push cx
    push si
    
    ; Print ID
    mov bx, si
    shl bx, 1
    mov ax, student_ids[bx]
    call print_decimal_4
    
    lea dx, space_str
    call print_string
    
    ; Print Name
    pop si
    push si
    mov ax, 21
    mul si
    mov bx, ax
    lea dx, student_names[bx]
    call print_name_20
    
    lea dx, space_str
    call print_string
    
    ; Print grades
    pop si
    push si
    mov bx, si
    shl bx, 1
    
    mov ax, student_grade1[bx]
    call print_decimal_4
    call print_space
    
    mov ax, student_grade2[bx]
    call print_decimal_4
    call print_space
    
    mov ax, student_grade3[bx]
    call print_decimal_4
    call print_space
    
    ; Print GPA
    mov ax, student_gpa[bx]
    call print_gpa
    call print_space
    
    ; Print letter grade
    call get_letter_grade
    call print_string
    
    lea dx, newline
    call print_string
    
    pop si
    inc si
    pop cx
    loop display_loop
    
    jmp display_done
    
no_students:
    lea dx, error_empty
    call print_string
    
display_done:
    lea dx, press_key
    call print_string
    call get_choice
    ret
display_all_students endp

;==============================================================================
; FEATURE 3: SEARCH STUDENT
;==============================================================================

search_student proc
    call clear_screen
    
    cmp student_count, 0
    je search_no_students
    
    lea dx, prompt_id
    call print_string
    call read_number
    mov search_id, ax
    
    ; Search for student
    mov cx, student_count
    mov si, 0
    
search_loop:
    mov bx, si
    shl bx, 1
    mov ax, student_ids[bx]
    cmp ax, search_id
    je found_student
    
    inc si
    loop search_loop
    
    ; Not found
    lea dx, error_notfound
    call print_string
    jmp search_done
    
found_student:
    lea dx, header_line
    call print_string
    lea dx, student_header
    call print_string
    
    ; Display found student (reuse display logic)
    mov bx, si
    shl bx, 1
    mov ax, student_ids[bx]
    call print_decimal_4
    
    lea dx, space_str
    call print_string
    
    mov ax, 21
    mul si
    mov bx, ax
    lea dx, student_names[bx]
    call print_name_20
    
    mov bx, si
    shl bx, 1
    
    mov ax, student_grade1[bx]
    call print_decimal_4
    call print_space
    
    mov ax, student_grade2[bx]
    call print_decimal_4
    call print_space
    
    mov ax, student_grade3[bx]
    call print_decimal_4
    call print_space
    
    mov ax, student_gpa[bx]
    call print_gpa
    call print_space
    
    call get_letter_grade
    call print_string
    
    jmp search_done
    
search_no_students:
    lea dx, error_empty
    call print_string
    
search_done:
    lea dx, press_key
    call print_string
    call get_choice
    ret
search_student endp

;==============================================================================
; FEATURE 4: CLASS STATISTICS
;==============================================================================

show_statistics proc
    call clear_screen
    
    cmp student_count, 0
    je stats_empty
    
    lea dx, stats_title
    call print_string
    
    ; Calculate average GPA
    mov cx, student_count
    mov si, 0
    xor ax, ax
    xor dx, dx
    
calc_avg_loop:
    mov bx, si
    shl bx, 1
    add ax, student_gpa[bx]
    adc dx, 0
    inc si
    loop calc_avg_loop
    
    div student_count
    push ax                 ; Save average
    
    lea dx, avg_msg
    call print_string
    pop ax
    push ax
    call print_gpa
    
    ; Find highest GPA
    mov cx, student_count
    mov si, 0
    mov bx, 0
    mov ax, student_gpa[bx]
    mov dx, ax              ; DX = highest
    
find_max_loop:
    mov bx, si
    shl bx, 1
    mov ax, student_gpa[bx]
    cmp ax, dx
    jle not_higher
    mov dx, ax
not_higher:
    inc si
    loop find_max_loop
    
    lea dx, highest_msg
    call print_string
    mov ax, dx
    call print_gpa
    
    ; Find lowest GPA
    mov cx, student_count
    mov si, 0
    mov bx, 0
    mov ax, student_gpa[bx]
    mov dx, ax              ; DX = lowest
    
find_min_loop:
    mov bx, si
    shl bx, 1
    mov ax, student_gpa[bx]
    cmp ax, dx
    jge not_lower
    mov dx, ax
not_lower:
    inc si
    loop find_min_loop
    
    lea dx, lowest_msg
    call print_string
    mov ax, dx
    call print_gpa
    
    lea dx, total_students
    call print_string
    mov ax, student_count
    call print_decimal
    
    jmp stats_done
    
stats_empty:
    lea dx, error_empty
    call print_string
    
stats_done:
    pop ax                  ; Clean stack
    lea dx, press_key
    call print_string
    call get_choice
    ret
show_statistics endp

;==============================================================================
; FEATURE 5: BUBBLE SORT BY GPA
;==============================================================================

sort_by_gpa proc
    call clear_screen
    
    cmp student_count, 0
    je sort_empty
    cmp student_count, 1
    je sort_done
    
    ; Bubble sort implementation
    mov cx, student_count
    dec cx                  ; Outer loop count
    
outer_loop:
    push cx
    mov sort_swapped, 0
    mov si, 0
    mov cx, student_count
    dec cx
    
inner_loop:
    push cx
    
    ; Compare GPA[si] with GPA[si+1]
    mov bx, si
    shl bx, 1
    mov ax, student_gpa[bx]
    
    mov di, si
    inc di
    mov bx, di
    shl bx, 1
    mov dx, student_gpa[bx]
    
    cmp ax, dx
    jge no_swap
    
    ; Swap needed
    mov sort_swapped, 1
    
    ; Swap IDs
    mov bx, si
    shl bx, 1
    mov ax, student_ids[bx]
    mov di, si
    inc di
    push di
    shl di, 1
    xchg ax, student_ids[di]
    pop di
    mov bx, si
    shl bx, 1
    mov student_ids[bx], ax
    
    ; Swap all grades and GPA similarly
    mov bx, si
    shl bx, 1
    mov ax, student_grade1[bx]
    push si
    mov si, di
    shl si, 1
    xchg ax, student_grade1[si]
    pop si
    mov bx, si
    shl bx, 1
    mov student_grade1[bx], ax
    
    mov bx, si
    shl bx, 1
    mov ax, student_grade2[bx]
    push si
    mov si, di
    shl si, 1
    xchg ax, student_grade2[si]
    pop si
    mov bx, si
    shl bx, 1
    mov student_grade2[bx], ax
    
    mov bx, si
    shl bx, 1
    mov ax, student_grade3[bx]
    push si
    mov si, di
    shl si, 1
    xchg ax, student_grade3[si]
    pop si
    mov bx, si
    shl bx, 1
    mov student_grade3[bx], ax
    
    mov bx, si
    shl bx, 1
    mov ax, student_gpa[bx]
    push si
    mov si, di
    shl si, 1
    xchg ax, student_gpa[si]
    pop si
    mov bx, si
    shl bx, 1
    mov student_gpa[bx], ax
    
no_swap:
    inc si
    pop cx
    loop inner_loop
    
    pop cx
    cmp sort_swapped, 0
    je sort_done
    loop outer_loop
    
sort_done:
    lea dx, success_msg
    call print_string
    jmp sort_exit
    
sort_empty:
    lea dx, error_empty
    call print_string
    
sort_exit:
    lea dx, press_key
    call print_string
    call get_choice
    ret
sort_by_gpa endp

;==============================================================================
; FEATURE 6: GENERATE REPORT CARD
;==============================================================================

generate_report proc
    call clear_screen
    
    cmp student_count, 0
    je report_empty
    
    lea dx, report_title
    call print_string
    
    ; Display all students with enhanced formatting
    call display_all_students
    jmp report_exit
    
report_empty:
    lea dx, error_empty
    call print_string
    lea dx, press_key
    call print_string
    call get_choice
    
report_exit:
    ret
generate_report endp

;==============================================================================
; FEATURE 7: GRADE DISTRIBUTION
;==============================================================================

show_distribution proc
    call clear_screen
    
    cmp student_count, 0
    je dist_empty
    
    lea dx, dist_title
    call print_string
    
    ; Count grades in each category
    xor ax, ax
    mov bx, ax
    mov cx, ax
    mov dx, ax
    mov di, ax              ; A, B, C, D, F counters
    
    push ax
    push bx
    push cx
    push dx
    push di
    
    mov cx, student_count
    mov si, 0
    
count_loop:
    mov bx, si
    shl bx, 1
    mov ax, student_gpa[bx]
    
    ; Divide by 100 to get actual grade
    push cx
    mov cx, 100
    xor dx, dx
    div cx
    pop cx
    
    cmp ax, 90
    jge is_A
    cmp ax, 80
    jge is_B
    cmp ax, 70
    jge is_C
    cmp ax, 60
    jge is_D
    jmp is_F
    
is_A:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    inc ax
    push ax
    push bx
    push cx
    push dx
    push di
    jmp count_next
    
is_B:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    inc bx
    push ax
    push bx
    push cx
    push dx
    push di
    jmp count_next
    
is_C:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    inc cx
    push ax
    push bx
    push cx
    push dx
    push di
    jmp count_next
    
is_D:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    inc dx
    push ax
    push bx
    push cx
    push dx
    push di
    jmp count_next
    
is_F:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    inc di
    push ax
    push bx
    push cx
    push dx
    push di
    
count_next:
    inc si
    loop count_loop
    
    ; Display distribution
    lea dx, grade_a
    call print_string
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    push ax
    push bx
    push cx
    push dx
    push di
    call print_decimal
    
    lea dx, grade_b
    call print_string
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    push ax
    push bx
    push cx
    push dx
    push di
    mov ax, bx
    call print_decimal
    
    lea dx, grade_c
    call print_string
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    push ax
    push bx
    push cx
    push dx
    push di
    mov ax, cx
    call print_decimal
    
    lea dx, grade_d
    call print_string
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    push ax
    push bx
    push cx
    push dx
    push di
    mov ax, dx
    call print_decimal
    
    lea dx, grade_f
    call print_string
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    mov ax, di
    call print_decimal
    
    jmp dist_done
    
dist_empty:
    lea dx, error_empty
    call print_string
    
dist_done:
    lea dx, press_key
    call print_string
    call get_choice
    ret
show_distribution endp

;==============================================================================
; HELPER FUNCTIONS
;==============================================================================

read_number proc
    push bx
    push cx
    push dx
    
    xor cx, cx
read_num_loop:
    mov ah, 00h
    int 16h
    
    cmp al, 13
    je read_num_done
    
    cmp al, '0'
    jb read_num_loop
    cmp al, '9'
    ja read_num_loop
    
    mov dl, al
    mov ah, 02h
    int 21h
    
    sub al, '0'
    mov bl, al
    mov ax, cx
    mov dx, 10
    mul dx
    xor bh, bh
    add ax, bx
    mov cx, ax
    jmp read_num_loop
    
read_num_done:
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

read_string proc
    push bx
    push cx
    push di
    
    mov di, si
    mov cx, 0
    
read_str_loop:
    mov ah, 00h
    int 16h
    
    cmp al, 13
    je read_str_done
    
    cmp al, 8               ; Backspace
    je read_str_back
    
    cmp cx, 20
    jge read_str_loop
    
    mov dl, al
    mov ah, 02h
    int 21h
    
    stosb
    inc cx
    jmp read_str_loop
    
read_str_back:
    cmp cx, 0
    je read_str_loop
    
    mov dl, 8
    mov ah, 02h
    int 21h
    mov dl, ' '
    int 21h
    mov dl, 8
    int 21h
    
    dec di
    dec cx
    jmp read_str_loop
    
read_str_done:
    mov byte ptr [di], '$'
    lea dx, newline
    call print_string
    
    pop di
    pop cx
    pop bx
    ret
read_string endp

print_decimal proc
    push ax
    push bx
    push cx
    push dx
    
    mov cx, 0
    mov bx, 10
    
    cmp ax, 0
    jne pd_loop
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp pd_done
    
pd_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz pd_loop
    
pd_print:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop pd_print
    
pd_done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_decimal endp

print_decimal_4 proc
    ; Print number in AX with minimum 4-character width (right-aligned)
    push ax
    push bx
    push cx
    push dx
    
    ; Count digits
    mov bx, 10
    mov cx, 0
    push ax
    
count_digits:
    xor dx, dx
    div bx
    inc cx
    test ax, ax
    jnz count_digits
    
    pop ax
    
    ; Print leading spaces if needed
    push ax
    mov dx, 4
    sub dx, cx
    jle no_padding
    
print_padding:
    push dx
    mov dl, ' '
    mov ah, 02h
    int 21h
    pop dx
    dec dx
    jnz print_padding
    
no_padding:
    pop ax
    call print_decimal
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_decimal_4 endp

print_gpa proc
    ; Print GPA with 2 decimal places (value is * 100)
    push ax
    push bx
    push dx
    
    mov bx, 100
    xor dx, dx
    div bx
    
    call print_decimal
    
    mov dl, '.'
    mov ah, 02h
    int 21h
    
    mov ax, dx
    call print_decimal
    
    pop dx
    pop bx
    pop ax
    ret
print_gpa endp

print_name_20 proc
    push ax
    push cx
    push si
    push dx
    
    mov si, dx          ; SI points to name string
    mov cx, 20          ; Print exactly 20 characters
    
pn_loop:
    lodsb               ; Load character from [SI] into AL
    cmp al, '$'         ; Check if end of string
    je pn_pad           ; If yes, pad with spaces
    
    mov dl, al
    mov ah, 02h
    int 21h
    loop pn_loop
    jmp pn_done
    
pn_pad:
    mov dl, ' '         ; Pad remaining with spaces
    mov ah, 02h
pn_pad_loop:
    int 21h
    loop pn_pad_loop
    
pn_done:
    pop dx
    pop si
    pop cx
    pop ax
    ret
print_name_20 endp

print_space proc
    push ax
    push dx
    mov dl, ' '
    mov ah, 02h
    int 21h
    pop dx
    pop ax
    ret
print_space endp

get_letter_grade proc
    ; Get letter grade based on GPA in AX
    ; AX contains GPA * 100
    push ax
    push bx
    
    mov bx, 100
    xor dx, dx
    div bx
    
    cmp ax, 90
    jge assign_A
    cmp ax, 80
    jge assign_B
    cmp ax, 70
    jge assign_C
    cmp ax, 60
    jge assign_D
    lea dx, letter_F
    jmp letter_done
    
assign_A:
    lea dx, letter_A
    jmp letter_done
    
assign_B:
    lea dx, letter_B
    jmp letter_done
    
assign_C:
    lea dx, letter_C
    jmp letter_done
    
assign_D:
    lea dx, letter_D
    
letter_done:
    pop bx
    pop ax
    ret
get_letter_grade endp

end main
