.section .bss
input_buffer:   .skip 64
output_buffer:  .skip 64
matrix: .skip 64
matrix_size: .skip 2

.section .text
.global _start

_start:
input:
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
    bgt input_is_num

    mov x0, #1
    ldr x1, =error_not_number
    mov x2, #error_not_number_len
    mov x8, #64
    svc #0

    b input
input_is_num:
    cmp x0, #0
    bgt input_is_positive

    mov x0, #1
    ldr x1, =error_border
    mov x2, #error_border_len
    mov x8, #64
    svc #0

    b input    


input_is_positive:
    cmp x0, #32
    blt input_is_in_border

    mov x0, #1
    ldr x1, =error_border
    mov x2, #error_border_len
    mov x8, #64
    svc #0

    b input    

input_is_in_border:
    mov x2, #1
    and x1, x0, x2
    cmp x1, #0
    bne good_input

    mov x0, #1
    ldr x1, =error_not_odd
    mov x2, #error_not_odd_len
    mov x8, #64
    svc #0

    b input    


good_input:

// x21 - end
// x20 - matrix size
// x19 - matrix_ptr
// x6 - temp
// x5 - number
// x4 - next_j
// x3 - next_i
// x2 - j
// x1 - i
// x0 - abs address

    mov x20, x0
    ldr x19, =matrix
    mul x21, x20, x20

    mov x0, 0

    mov x1, 0

    mov x6, #2
    udiv x2, x20, x6

    mov x3, #0
    mov x4, #0

    mov x5, #1

mag_square_loop:
    cmp x5, x21
    bgt output

    mov x0, #0
    mul x0, x1, x20
    add x0, x0, x2

    strb w5, [x19, x0]

    add x5, x5, #1

    sub x3, x1, #1
    add x4, x2, #1

    cmp x3, 0
    bge next_i_ok

    sub x3, x20, #1
next_i_ok:

    cmp x4, x20
    blt next_j_ok

    mov x4, #0

next_j_ok:

    mul x0, x3, x20
    add x0, x0, x4

    mov x6, #0
    ldrb w6, [x19, x0]
    cmp w6, #0

    bne move_down

    mov x1, x3
    mov x2, x4

    b mag_square_loop
move_down:
    add x1, x1, #1
    cmp x1, x20
    blt i_ok

    mov x1, 0

i_ok:
    b mag_square_loop




// x22 - count
// x21 - num elements
// x20 - matrix size
// x19 - matrix_ptr
output:
    mov x0, #1
    ldr x1, =msg_result
    mov x2, #msg_result_len
    mov x8, #64
    svc #0

    ldr x19, =matrix
    mul x21, x20, x20
    mov x22, #0
output_matrix_loop:
    mov x0, 0
    ldrb w0, [x19], 1
    ldr x1, =output_buffer
    mov x2, #3
    bl itoa

    mov x0, #1
    ldr x1, =output_buffer
    mov x2, 3
    mov x8, #64
    svc #0

    sub x21, x21, #1

    add x22, x22, #1
    cmp x22, x20
    beq next_row

    mov x0, #1
    ldr x1, =spa_char
    mov x2, #1
    mov x8, #64
    svc #0

    cmp x21, #0
    beq exit
    b output_matrix_loop

next_row:
    mov x0, #1
    ldr x1, =new_line
    mov x2, #1
    mov x8, #64
    svc #0

    mov x22, #0
    cmp x21, #0
    beq exit
    b output_matrix_loop




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



// x0 - number, x1 - buffer ptr, x2 - len of num
// x0 - buff len
itoa:            
    mov x3, #0

    cmp x0, #0
    bne itoa_extract

    mov w4, #'0'
    strb w4, [x1]
    mov x3, #1
    b itoa_fill_zero

itoa_extract:
    mov x5, #10

itoa_extract_loop:
    udiv x6, x0, x5
    msub x7, x6, x5, x0 
    add x7, x7, #'0'
    strb w7, [x1, x3]
    add x3, x3, #1

    mov x0, x6
    cmp x0, #0
    bne itoa_extract_loop

itoa_fill_zero:
    cmp x3, x2
    bge itoa_reverse

itoa_fill_zero_loop:
    mov w4, #'0'
    strb w4, [x1, x3]
    add x3, x3, #1

    cmp x3, x2
    blt itoa_fill_zero_loop


itoa_reverse:
    mov x9, x3            
    sub x3, x3, #1        
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

msg_input:    .asciz "Введите размер матрицы (нечетное число от 1 до 31): "
msg_input_len = . - msg_input - 1
msg_result:  .asciz "Матрица: \n"
msg_result_len = . - msg_result - 1
error_not_number: .asciz "Введенная строка не является целым числом\n\n"
error_not_number_len = . - error_not_number - 1
error_border: .asciz "Введенное число не входит в промежуток от 1 до 31\n\n"
error_border_len = . - error_border - 1
error_not_odd: .asciz "Введенное число четное\n\n"
error_not_odd_len = . - error_not_odd - 1
new_line: .asciz "\n"
spa_char: .asciz " "
