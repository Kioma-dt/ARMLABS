.section .bss
input_buffer:   .skip 64
output_buffer:  .skip 64
matrix:      .skip 128
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


// x22 - count
// x21 - num elements
// x20 - matrix size
// x19 - matrix_ptr
good_input:



output:
    mov x0, #1
    ldr x1, =msg_result
    mov x2, #msg_result_len
    mov x8, #64
    svc #0

    ldr x19, =mat
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
mat: .fill 64, 1, 0