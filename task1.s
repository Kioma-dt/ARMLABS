.section .data
prompt: .asciz "Введите строку: "
prompt_len = . - prompt - 1
result_msg: .asciz "Отсортированная строка: "
result_len = . - result_msg - 1
newline: .asciz "\n"

.section .bss
input_buffer: .skip 256
output_buffer: .skip 256
word_starts: .skip 256
word_lengths: .skip 256

.section .text
.global _start

_start:
    mov x0, #1
    ldr x1, =prompt
    mov x2, #prompt_len
    mov x8, #64
    svc #0

    mov x0, #0
    ldr x1, =input_buffer
    mov x2, #256
    mov x8, #63
    svc #0
    mov x19, x0

    ldr x20, =input_buffer
    ldr x21, =word_starts
    ldr x22, =word_lengths
    mov x23, #0
    mov x24, #0

parse_loop:
    cmp x24, x19
    bge parse_done

    ldrb w25, [x20, x24]

    cmp w25, #32
    beq skip_char
    cmp w25, #10
    beq skip_char
    cmp w25, #0
    beq skip_char

    add x26, x20, x24
    str x26, [x21, x23, lsl #3]
    mov x27, #0

count_word:
    cmp x24, x19
    bge save_word_len
    ldrb w25, [x20, x24]
    cmp w25, #32
    beq save_word_len
    cmp w25, #10
    beq save_word_len
    cmp w25, #0
    beq save_word_len

    add x27, x27, #1
    add x24, x24, #1
    b count_word

save_word_len:
    str x27, [x22, x23, lsl #3]
    add x23, x23, #1
    b parse_loop

skip_char:
    add x24, x24, #1
    b parse_loop

parse_done:
    mov x28, x23

    cmp x28, #0
    ble print_result

    mov x24, #0
outer_loop:
    sub x25, x28, #1
    cmp x24, x25
    bge print_result

    mov x26, #0
inner_loop:
    sub x27, x28, x24
    sub x27, x27, #1
    cmp x26, x27
    bge next_outer

    ldr x9, [x22, x26, lsl #3]
    add x10, x26, #1
    ldr x11, [x22, x10, lsl #3]

    cmp x9, x11
    ble next_inner

    str x11, [x22, x26, lsl #3]
    str x9, [x22, x10, lsl #3]

    ldr x9, [x21, x26, lsl #3]
    ldr x11, [x21, x10, lsl #3]
    str x11, [x21, x26, lsl #3]
    str x9, [x21, x10, lsl #3]

next_inner:
    add x26, x26, #1
    b inner_loop

next_outer:
    add x24, x24, #1
    b outer_loop

print_result:
    mov x0, #1
    ldr x1, =result_msg
    mov x2, #result_len
    mov x8, #64
    svc #0

    ldr x20, =output_buffer
    mov x24, #0
    mov x25, #0

build_output:
    cmp x25, x28
    bge write_output

    ldr x26, [x21, x25, lsl #3]
    ldr x27, [x22, x25, lsl #3]
    mov x9, #0

copy_word:
    cmp x9, x27
    bge add_space
    ldrb w10, [x26, x9]
    strb w10, [x20, x24]
    add x24, x24, #1
    add x9, x9, #1
    b copy_word

add_space:
    add x25, x25, #1
    cmp x25, x28
    bge write_output
    mov w10, #32
    strb w10, [x20, x24]
    add x24, x24, #1
    b build_output

write_output:
    mov w10, #10
    strb w10, [x20, x24]
    add x24, x24, #1

    mov x0, #1
    ldr x1, =output_buffer
    mov x2, x24
    mov x8, #64
    svc #0

exit:
    mov x8, #93
    mov x0, #0
    svc #0