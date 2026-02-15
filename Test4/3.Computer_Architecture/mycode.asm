.model small
.stack 100h

.data
    hours db 0           
    minutes db 0         
    seconds db 0         
    time_msg db 'Time: 00:00:00$', 0  
    command_msg db 'Press S to start, E to stop, R to reset$', 0  
    esc_msg db 'Press ESC to exit$', 0  

    old_div_error_seg dw 0 
    old_div_error_off dw 0 

    div_10 db 10          

.code
start:
    cli                     
    push ds                
    push ax                
    mov ax, 0              
    mov ds, ax             
    mov ax, [0]            
    mov old_div_error_seg, ax 
    mov ax, [2]            
    mov old_div_error_off, ax 

    lea ax, divide_error_handler 
    mov [0], ax            
    mov [2], cs            

    sti                     

    mov ax, @data
    mov ds, ax

    call move_cursor_line_2
    mov dx, offset command_msg 
    call print_string          

    call move_cursor_line_3
    mov dx, offset esc_msg     
    call print_string          

main_loop:
    call move_cursor_home

    mov dx, offset time_msg   
    call print_string          

    mov ah, 01h               
    int 16h
    cmp al, 1Bh               
    je exit_program           
    cmp al, 'R'               
    je reset_timer            
    cmp al, 'S'               
    je start_timer            
    cmp al, 'E'               
    je stop_timer             

    call update_time
    jmp main_loop

exit_program:
    cli                     
    mov ax, old_div_error_seg 
    mov [0], ax            
    mov ax, old_div_error_off 
    mov [2], ax            
    sti                     

    mov ax, 4C00h          
    int 21h                

update_time:
    inc seconds             
    cmp seconds, 60
    jl update_done          
    mov seconds, 0         
    inc minutes             

    cmp minutes, 60
    jl update_done          
    mov minutes, 0         
    inc hours               

    cmp hours, 24
    jl update_done          
    mov hours, 0           

update_done:
    call update_time_msg    
    ret

update_time_msg:
    mov al, hours
    call convert_bcd
    mov [time_msg+6], al   
    mov [time_msg+7], ah   

    mov al, minutes
    call convert_bcd
    mov [time_msg+9], al   
    mov [time_msg+10], ah  

    mov al, seconds
    call convert_bcd
    mov [time_msg+12], al  
    mov [time_msg+13], ah  

    ret

convert_bcd:
    xor ah, ah             
    cmp al, 0
    je handle_zero         
    div byte ptr [div_10]   
    add al, '0'            
    add ah, '0'            
    ret

handle_zero:
    mov al, '0'            
    mov ah, '0'            
    ret

reset_timer:
    mov hours, 0           
    mov minutes, 0         
    mov seconds, 0         
    jmp main_loop          

start_timer:
    jmp main_loop          

stop_timer:
    jmp main_loop          

divide_error_handler:
    iret

print_string:
    mov ah, 09h            
    int 21h
    ret

move_cursor_home:
    mov ah, 02h            
    mov bh, 0              
    mov dh, 0              
    mov dl, 0              
    int 10h                
    ret

move_cursor_line_2:
    mov ah, 02h            
    mov bh, 0              
    mov dh, 1              
    mov dl, 0              
    int 10h                
    ret

move_cursor_line_3:
    mov ah, 02h            
    mov bh, 0              
    mov dh, 2              
    mov dl, 0              
    int 10h                
    ret

end start
