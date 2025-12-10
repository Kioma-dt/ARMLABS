.section .data
msg_input: .asciz "Введите число, до которого будет угадываться (2-999): "
msg_input_len = . - msg_input - 1
msg_guess: .asciz "Введите число от 1 до "
msg_guess_len = . - msg_guess - 1
msg_not_guessed: .asciz "Вы не угадали попробуйте еще раз\n"
msg_not_guessed_len = . - msg_not_guessed - 1
msg_end_of_guess: .asciz "Вы угадали!!! Потрачено попыток: "
msg_end_of_guess_len = . - msg_end_of_guess - 1
error_not_number: .asciz "Введенная строка не является целым числом\n\n"
error_not_number_len = . - error_not_number - 1
error_border: .asciz "Введенное число не входит в промежуток\n\n"
error_border_len = . - error_border - 1
new_line: .asciz "\n"
input_buffer: .skip 256
output_buffer: .skip 256
radnom_buffer: .skip 4

.section .text
.global _start

_start:
first_input:
    mov x0, #1
    ldr x1, =msg_input
    mov x2, #msg_input_len
    mov x8, #64
    svc #0

    mov x0, #0
    ldr x1, =input_buffer
    mov x2, #64
    mov x8, #63
    svc #0

    sub x0, x0, #1
    ldr x1, =input_buffer
    bl atoi

    cmp x0, #-1
    bgt first_input_is_num

    mov x0, #1
    ldr x1, =error_not_number
    mov x2, #error_not_number_len
    mov x8, #64
    svc #0

    b first_input

first_input_is_num:
    cmp x0, #1
    bgt first_input_is_greater_1

    mov x0, #1
    ldr x1, =error_border
    mov x2, #error_border_len
    mov x8, #64
    svc #0

    b first_input

first_input_is_greater_1:   
    cmp x0, #1000
    blt first_input_is_ok

    mov x0, #1
    ldr x1, =error_border
    mov x2, #error_border_len
    mov x8, #64
    svc #0

    b first_input

// x19 - to what random
// x20 - random number
// x21 - number of guess
// x22 - output buffer len
first_input_is_ok:

    mov x19, x0

    mov x0, x19
    bl random
    mov x20, x0
    mov x21, #1

    mov x0, x19
    ldr x1, =output_buffer
    bl itoa
    mov x22, x0

guess:

    mov x0, #1
    ldr x1, =msg_guess
    mov x2, #msg_guess_len
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =output_buffer
    mov x2, x22
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =new_line
    mov x2, #1
    mov x8, #64
    svc #0

// input
    mov x0, #0
    ldr x1, =input_buffer
    mov x2, #64
    mov x8, #63
    svc #0

    sub x0, x0, #1
    ldr x1, =input_buffer
    bl atoi

    cmp x0, #-1
    bgt guess_is_num

    mov x0, #1
    ldr x1, =error_not_number
    mov x2, #error_not_number_len
    mov x8, #64
    svc #0

    b guess

guess_is_num:
    cmp x0, #0
    bgt guess_is_greater_1

    mov x0, #1
    ldr x1, =error_border
    mov x2, #error_border_len
    mov x8, #64
    svc #0

    b guess

guess_is_greater_1:   
    cmp x0, x19
    ble guess_is_ok

    mov x0, #1
    ldr x1, =error_border
    mov x2, #error_border_len
    mov x8, #64
    svc #0

    b guess

guess_is_ok:

    cmp x0, x20
    beq end_of_guess
    
    mov x0, #1
    ldr x1, =msg_not_guessed
    mov x2, #msg_not_guessed_len
    mov x8, #64
    svc #0

    add x21, x21, #1

    b guess




end_of_guess:

    mov x0, #1
    ldr x1, =msg_end_of_guess
    mov x2, #msg_end_of_guess_len
    mov x8, #64
    svc #0

    mov x0, x21
    ldr x1, =output_buffer
    bl itoa

    mov x2, x0
    mov x0, #1
    ldr x1, =output_buffer
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =new_line
    mov x2, #1
    mov x8, #64
    svc #0


exit:
    mov x8, #93
    mov x0, #0
    svc #0


// x0 - buff len, x1 - buff ptr
// x0 - number or -1
atoi:
    mov x2, #0          
    mov x3, #0          

atoi_loop:
    cmp x3, x0
    bge atoi_done

    ldrb w4, [x1, x3]
    add x3, x3, #1

    cmp w4, #'0'
    blt atoi_error
    cmp w4, #'9'
    bgt atoi_error

    sub w4, w4, #'0'

    mov x5, #10
    mul x2, x2, x5
    add x2, x2, x4

    b atoi_loop

atoi_done:
    mov x0, x2
    ret

atoi_error:
    mov x0, #-1
    ret



// x0 - number, x1 - buffer ptr
// x0 - buff len
itoa:
    mov x2, x0          
    mov x3, #0        

    cmp x2, #0
    bne itoa_extract

    mov w4, #'0'
    strb w4, [x1]
    mov x0, #1
    ret

itoa_extract:
    mov x5, #10
itoa_extract_loop:
    udiv x6, x2, x5
    msub x7, x6, x5, x2
    add x7, x7, #'0'
    strb w7, [x1, x3]
    add x3, x3, #1
    mov x2, x6
    cmp x2, #0
    bne itoa_extract_loop

    mov x9, x3

    sub x3, x9, #1       
    mov x4, #0            

itoa_reverse_loop:
    cmp x4, x3
    bge itoa_done

    ldrb w5, [x1, x4]
    ldrb w6, [x1, x3]
    strb w6, [x1, x4]
    strb w5, [x1, x3]

    add x4, x4, #1
    sub x3, x3, #1
    b itoa_reverse_loop

itoa_done:
    mov x0, x9
    ret


// x0 - to what number
// x0 - random number
random:
    mov x27, x0           

    ldr x0, =radnom_buffer             
    mov x1, #4           
    mov x2, #0             
    mov x8, #278         
    svc #0

    ldr x0, =radnom_buffer  
    ldr w4, [x0]

    udiv w3, w4, w27      
    msub w0, w3, w27, w4  
    add w0, w0, #1

    ret