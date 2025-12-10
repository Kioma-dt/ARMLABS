.section .data
prompt: .asciz "Введите строку: "
prompt_len = . - prompt - 1
error: .asciz "Неверно введенная строка (должны быть тольк цифры и буквы)!\n"
error_len = . - error - 1
result_msg: .asciz "Отсортированная строка: "
result_len = . - result_msg - 1
new_line: .asciz "\n"
buffer: .skip 256

.section .text
.global _start

_start:
    mov x0, #1
    ldr x1, =prompt
    mov x2, #prompt_len
    mov x8, #64
    svc #0

    mov x0, #0
    ldr x1, =buffer
    mov x2, #256
    mov x8, #63
    svc #0

    sub x19, x0, #1
    ldr x20, =buffer

check_input:

    mov x1, x20
    add x3, x19, #1

check_loop:
    sub     x3, x3, #1
    cmp     x3, #0
    ble     valid   

    ldrb    w2, [x1], #1        


    cmp     w2, #'0'
    blt     invalid
    cmp     w2, #'9'
    ble     check_loop

    cmp     w2, #'A'
    blt     invalid
    cmp     w2, #'Z'
    ble     check_loop

    cmp     w2, #'a'
    blt     invalid
    cmp     w2, #'z'
    ble     check_loop

    b       invalid

invalid:

    mov x0, #1
    ldr x1, =error
    mov x2, #error_len
    mov x8, #64
    svc #0

    b _start



valid:

insertion_sort:
    ldr x0, =buffer
    mov x1, x19
    cmp x1, #1
    ble sort_done

    mov x2, #1             
outer_loop:
    cmp x2, x1
    bge sort_done           

    add x3, x0, x2          
    ldrb w4, [x3]         

    sub x5, x2, #1          

inner_loop:
    cmp x5, #0
    blt insert_key       

    add x6, x0, x5        
    ldrb w7, [x6]  

    mov w8, w7
    mov w9, w4

    mov x0, x7
    bl get_char_order
    mov x7, x0
    mov x0, x4
    bl get_char_order
    mov x4, x0


    cmp w7, w4        
    ble insert_key   

    mov w7, w8
    mov w4, w9  
    ldr x0, =buffer

    strb w7, [x6, #1]

    sub x5, x5, #1         

    b inner_loop

insert_key:
    mov w7, w8
    mov w4, w9 
    ldr x0, =buffer
    add x6, x5, #1
    add x6, x0, x6         
    strb w4, [x6]           

    add x2, x2, #1          
    b outer_loop

sort_done:

output:
    mov x0, #1
    ldr x1, =result_msg
    mov x2, #result_len
    mov x8, #64
    svc #0


    mov x0, #1
    ldr x1, =buffer
    mov x2, x19
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


get_char_order:
    cmp     x0, #'0'
    blt     not_digit
    cmp     x0, #'9'
    bgt     not_digit

    sub     x0, x0, #'0'
    add     x0, x0, #1
    ret

not_digit:
    bic x21, x0, #0x20

    cmp     x21, #'A'
    blt     not_letter
    cmp     x21, #'Z'
    bgt     not_letter

    sub     x0, x21, #'A'
    add     x0, x0, #11
    ret

not_letter:
    mov     x0, #0
    ret
