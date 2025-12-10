.section .bss
input_buffer:   .skip 64
output_buffer:  .skip 64
matrix: .skip 64
matrix_size: .skip 2

.section .text
.global _start

_start:
ask_size:
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
    cmp x0, #1
    beq good_input_size

    mov x0, #1
    ldr x1, =msg_wrong_input
    mov x2, #msg_wrong_input_len
    mov x8, #64
    svc #0
    b _start

good_input_size:
    ldr x3, =input_buffer
    ldr x4, =matrix_size
    ldrb w1, [x3]

    mov x0, #3
    strh w0, [x4]
    mov x20, #3
    cmp w1, #'3'
    beq good_input

    mov x0, #5
    strh w0, [x4]
    mov x20, #5
    cmp w1, #'5'
    beq good_input

    mov x0, #7
    strh w0, [x4]
    mov x20, #7
    cmp w1, #'7'
    beq good_input

    mov x0, #1
    ldr x1, =msg_wrong_input
    mov x2, #msg_wrong_input_len
    mov x8, #64
    svc #0
    b _start



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
    bl itoa

    mov x0, #1
    ldr x1, =output_buffer
    mov x2, 2
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




itoa:
    mov x2, #10
    udiv x3, x0, x2 

    add x3, x3, #'0'
    strb w3, [x1]
    sub x3, x3, #'0'

    mov x4, #10
    mul x3, x3, x4
    sub x4, x0, x3

    add x4, x4, #'0'
    strb w4, [x1, #1] 

    ret

msg_input:    .asciz "Введите размер матрицы (3, 5 или 7): "
msg_input_len = . - msg_input - 1
msg_result:  .asciz "Матрица: \n"
msg_result_len = . - msg_result - 1
msg_wrong_input: .asciz "Неверный ввод!\n"
msg_wrong_input_len = . - msg_wrong_input - 1
new_line: .asciz "\n"
spa_char: .asciz " "
