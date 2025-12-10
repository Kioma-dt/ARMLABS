.section .bss
input_buf:   .skip 512
matrix:      .skip 128
temp_matrix: .skip 72
matrix_size: .skip 8
total_elems: .skip 8

.section .text
.global _start

_start:
ask_size:
    mov x0, #1
    ldr x1, =msg_size
    mov x2, #msg_size_len
    mov x8, #64
    svc #0

    mov x0, #0
    ldr x1, =input_buf
    mov x2, #10
    mov x8, #63
    svc #0

    ldr x1, =input_buf
    ldrb w0, [x1]

    cmp w0, #49
    blt print_size_err
    cmp w0, #52
    bgt print_size_err

    sub w0, w0, #48
    ldr x1, =matrix_size
    str x0, [x1]

    mul x2, x0, x0
    ldr x1, =total_elems
    str x2, [x1]

ask_elements:
    mov x0, #1
    ldr x1, =msg_elems
    mov x2, #msg_elems_len
    mov x8, #64
    svc #0

    ldr x19, =total_elems
    ldr x19, [x19]
    mov x0, x19
    bl print_number_simple

    mov x0, #1
    ldr x1, =msg_elems_end
    mov x2, #msg_elems_end_len
    mov x8, #64
    svc #0

    mov x0, #0
    ldr x1, =input_buf
    mov x2, #512
    mov x8, #63
    svc #0
    mov x10, x0

    ldr x19, =input_buf
    ldr x20, =matrix
    mov x21, #0
    mov x22, #0

parse_loop:
    cmp x22, x10
    bge check_total_count

    ldrb w23, [x19, x22]

    cmp w23, #32
    beq skip_char
    cmp w23, #10
    beq skip_char
    cmp w23, #0
    beq check_total_count

    mov x24, #0
    mov x25, #0

    cmp w23, #45
    beq is_minus

    cmp w23, #48
    blt print_input_err
    cmp w23, #57
    bgt print_input_err

    b parse_digits

is_minus:
    mov x25, #1
    add x22, x22, #1

    cmp x22, x10
    bge print_input_err
    ldrb w23, [x19, x22]
    cmp w23, #48
    blt print_input_err
    cmp w23, #57
    bgt print_input_err

parse_digits:
    cmp x22, x10
    bge store_number

    ldrb w23, [x19, x22]

    cmp w23, #32
    beq store_number
    cmp w23, #10
    beq store_number
    cmp w23, #0
    beq store_number

    cmp w23, #48
    blt print_input_err
    cmp w23, #57
    bgt print_input_err

    sub w23, w23, #48
    mov x26, #10
    mul x24, x24, x26
    add x24, x24, x23

    add x22, x22, #1
    b parse_digits

store_number:
    cmp x25, #1
    bne save_to_mem
    neg x24, x24

save_to_mem:
    strh w24, [x20, x21, lsl #1]
    add x21, x21, #1
    b parse_loop

skip_char:
    add x22, x22, #1
    b parse_loop

check_total_count:
    ldr x2, =total_elems
    ldr x2, [x2]
    cmp x21, x2
    bne print_count_err

    ldr x0, =matrix_size
    ldr x0, [x0]

    cmp x0, #1
    beq case_1
    cmp x0, #2
    beq case_2
    cmp x0, #3
    beq case_3
    cmp x0, #4
    beq case_4

case_1:
    ldr x20, =matrix
    ldrsh x19, [x20]
    b print_result

case_2:
    ldr x20, =matrix
    ldrsh x1, [x20, #0]
    ldrsh x2, [x20, #6]
    mul x1, x1, x2
    ldrsh x3, [x20, #2]
    ldrsh x4, [x20, #4]
    mul x3, x3, x4
    sub x19, x1, x3
    b print_result

case_3:
    ldr x0, =matrix
    ldr x1, =temp_matrix
    mov x2, #0
copy_3x3:
    cmp x2, #9
    bge call_det3
    ldrsh x3, [x0, x2, lsl #1]
    strh w3, [x1, x2, lsl #1]
    add x2, x2, #1
    b copy_3x3
call_det3:
    bl det_3x3_fixed
    mov x19, x24
    b print_result

case_4:
    bl det_4x4_calc
    b print_result

print_size_err:
    mov x0, #1
    ldr x1, =err_size
    mov x2, #err_size_len
    mov x8, #64
    svc #0
    b ask_size

print_count_err:
    mov x0, #1
    ldr x1, =err_count
    mov x2, #err_count_len
    mov x8, #64
    svc #0
    b ask_elements

print_input_err:
    mov x0, #1
    ldr x1, =err_input
    mov x2, #err_input_len
    mov x8, #64
    svc #0
    b ask_elements

det_4x4_calc:
    str x30, [sp, #-16]!
    ldr x20, =matrix
    mov x19, #0
    mov x21, #0

loop_4x4:
    cmp x21, #4
    bge end_4x4

    ldrsh x22, [x20, x21, lsl #1]

    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    bl create_minor_4to3
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16

    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!
    bl det_3x3_fixed
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16

    mul x23, x22, x24

    tst x21, #1
    bne sub_val
    add x19, x19, x23
    b next_iter_4
sub_val:
    sub x19, x19, x23

next_iter_4:
    add x21, x21, #1
    b loop_4x4
end_4x4:
    ldr x30, [sp], #16
    ret

create_minor_4to3:
    ldr x26, =matrix
    ldr x27, =temp_matrix
    mov x28, #0
    mov x9, #1
c_min_row:
    cmp x9, #4
    bge c_min_ret
    mov x10, #0
c_min_col:
    cmp x10, #4
    bge c_min_next_row
    cmp x10, x21
    beq c_min_skip
    mov x11, #4
    mul x12, x9, x11
    add x12, x12, x10
    ldrsh x13, [x26, x12, lsl #1]
    strh w13, [x27, x28, lsl #1]
    add x28, x28, #1
c_min_skip:
    add x10, x10, #1
    b c_min_col
c_min_next_row:
    add x9, x9, #1
    b c_min_row
c_min_ret:
    ret

det_3x3_fixed:
    ldr x26, =temp_matrix
    ldrsh x1, [x26, #0]
    ldrsh x2, [x26, #8]
    ldrsh x3, [x26, #16]
    mul x10, x1, x2
    mul x10, x10, x3
    ldrsh x1, [x26, #2]
    ldrsh x2, [x26, #10]
    ldrsh x3, [x26, #12]
    mul x11, x1, x2
    mul x11, x11, x3
    add x10, x10, x11
    ldrsh x1, [x26, #4]
    ldrsh x2, [x26, #6]
    ldrsh x3, [x26, #14]
    mul x11, x1, x2
    mul x11, x11, x3
    add x10, x10, x11
    ldrsh x1, [x26, #4]
    ldrsh x2, [x26, #8]
    ldrsh x3, [x26, #12]
    mul x11, x1, x2
    mul x11, x11, x3
    sub x10, x10, x11
    ldrsh x1, [x26, #2]
    ldrsh x2, [x26, #6]
    ldrsh x3, [x26, #16]
    mul x11, x1, x2
    mul x11, x11, x3
    sub x10, x10, x11
    ldrsh x1, [x26, #0]
    ldrsh x2, [x26, #10]
    ldrsh x3, [x26, #14]
    mul x11, x1, x2
    mul x11, x11, x3
    sub x10, x10, x11
    mov x24, x10
    ret

print_result:
    mov x0, #1
    ldr x1, =msg_res
    mov x2, #msg_res_len
    mov x8, #64
    svc #0
    mov x0, x19
    bl print_number_simple
    mov x0, #1
    ldr x1, =newline
    mov x2, #1
    mov x8, #64
    svc #0
    b exit

print_number_simple:
    stp x29, x30, [sp, #-16]!
    str x19, [sp, #-8]!
    mov x19, x0
    cmp x19, #0
    bge pns_convert
    mov x0, #1
    ldr x1, =minus
    mov x2, #1
    mov x8, #64
    svc #0
    neg x19, x19
pns_convert:
    sub sp, sp, #32
    mov x20, sp
    add x20, x20, #31
    mov w21, #10
    mov x22, x20
    mov x23, #10
pns_loop:
    udiv x24, x19, x23
    msub x25, x24, x23, x19
    add w25, w25, #48
    strb w25, [x22]
    sub x22, x22, #1
    mov x19, x24
    cmp x19, #0
    bne pns_loop
    add x22, x22, #1
    mov x0, #1
    mov x1, x22
    mov x2, sp
    add x2, x2, #31
    sub x2, x2, x22
    add x2, x2, #1
    mov x8, #64
    svc #0
    add sp, sp, #32
    ldr x19, [sp], #8
    ldp x29, x30, [sp], #16
    ret

exit:
    mov x8, #93
    mov x0, #0
    svc #0

msg_size:    .asciz "Введите размер матрицы (одна цифра: 1, 2, 3 или 4): "
msg_size_len = . - msg_size - 1

msg_elems:   .asciz "Введите элементы (количество чисел должно быть ровно "
msg_elems_len = . - msg_elems - 1
msg_elems_end: .asciz "): "
msg_elems_end_len = . - msg_elems_end - 1

msg_res:     .asciz "Определитель: "
msg_res_len = . - msg_res - 1

err_size:    .asciz "Ошибка: Размер должен быть числом от 1 до 4! Попробуйте еще раз.\n\n"
err_size_len = . - err_size - 1

err_count:   .asciz "\nОшибка: Неверное количество чисел! Попробуйте еще раз.\n"
err_count_len = . - err_count - 1

err_input:   .asciz "\nОшибка: Введен недопустимый символ! Только цифры и пробелы. Попробуйте еще раз.\n"
err_input_len = . - err_input - 1

newline:     .asciz "\n"
minus:       .asciz "-"