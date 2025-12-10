
.section .data
msg_before:     .asciz "Содержимое директории ДО chroot:\n"
msg_before_len = . - msg_before - 1
msg_after:      .asciz "\nСодержимое директории ПОСЛЕ chroot:\n"
msg_after_len = . - msg_after - 1
prompt_dir:     .asciz "Введите путь для новой корневой директории: "
prompt_dir_len = . - prompt_dir - 1
error_msg:      .asciz "Ошибка: chroot не удался (проверьте права sudo и путь к папке)\n"
error_len = . - error_msg - 1

current_dir:    .asciz "."       // Для просмотра текущей папки
slash:          .asciz "/"       // Для перехода в корень
newline:        .asciz "\n"

.section .bss
input_buffer:   .skip 256
dir_buffer:     .skip 4096       // буфер для getdents
fd:             .skip 8          // дескриптор директории

.section .text
.global _start

_start:
    mov x0, #1
    ldr x1, =msg_before
    mov x2, #msg_before_len
    mov x8, #64
    svc #0

    bl list_directory

    mov x0, #1
    ldr x1, =prompt_dir
    mov x2, #prompt_dir_len
    mov x8, #64
    svc #0

    mov x0, #0
    ldr x1, =input_buffer
    mov x2, #256
    mov x8, #63
    svc #0

    ldr x19, =input_buffer
    mov x20, #0
remove_newline:
    ldrb w21, [x19, x20]
    cmp w21, #10
    beq null_terminate
    cmp w21, #0
    beq do_chroot
    add x20, x20, #1
    b remove_newline

null_terminate:
    strb wzr, [x19, x20]

do_chroot:
    // ARM64 syscall: 51
    ldr x0, =input_buffer    // Путь, который ввел пользователь
    mov x8, #51              // SYS_chroot
    svc #0

    cmp x0, #0
    blt chroot_error

    // 7. ПЕРЕХОД В НОВЫЙ КОРЕНЬ (chdir "/")
    ldr x0, =slash           // Строка "/"
    mov x8, #49              // SYS_chdir
    svc #0

    // 8. Вывод заголовка "ПОСЛЕ"
    mov x0, #1
    ldr x1, =msg_after
    mov x2, #msg_after_len
    mov x8, #64
    svc #0

    // 9. Показ файлов
    bl list_directory

    b exit

chroot_error:
    mov x0, #2
    ldr x1, =error_msg
    mov x2, #error_len
    mov x8, #64
    svc #0

    mov x8, #93
    mov x0, #1
    svc #0

list_directory:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    // openat(AT_FDCWD, ".", O_RDONLY, 0)
    mov x0, #-100            // AT_FDCWD
    ldr x1, =current_dir     // строка "."
    mov x2, #0               // O_RDONLY (0).
    mov x3, #0
    mov x8, #56              // SYS_openat
    svc #0

    cmp x0, #0
    blt list_done

    ldr x19, =fd
    str x0, [x19]

read_entries:
    // getdents64(fd, buf, count)
    ldr x19, =fd
    ldr x0, [x19]
    ldr x1, =dir_buffer
    mov x2, #4096
    mov x8, #61              // SYS_getdents64
    svc #0

    cmp x0, #0
    ble close_dir            // 0 = EOF, <0 = Error

    mov x20, x0              // Всего байт прочитано
    ldr x21, =dir_buffer     // Текущий указатель
    mov x22, #0              // Счетчик байт

process_entries:
    cmp x22, x20
    bge read_entries

    // Структура dirent64: смещение 16 = d_reclen (u16)
    ldrh w23, [x21, #16]

    // Пропуск "." и ".."
    add x25, x21, #19        // d_name начинается с 19-го байта
    ldrb w26, [x25]

    cmp w26, #46             // '.'
    bne print_entry

    ldrb w27, [x25, #1]
    cmp w27, #0
    beq skip_entry           // Имя "." -> пропуск

    cmp w27, #46             // '..'
    bne print_entry
    ldrb w28, [x25, #2]
    cmp w28, #0
    beq skip_entry           // Имя ".." -> пропуск

print_entry:
    mov x0, x25
    bl strlen

    mov x2, x0               // Длина
    mov x0, #1               // stdout
    mov x1, x25              // Адрес строки
    mov x8, #64              // write
    svc #0

    // Печать переноса строки
    mov x0, #1
    ldr x1, =newline
    mov x2, #1
    mov x8, #64
    svc #0

skip_entry:
    add x22, x22, x23        // Следующая запись
    add x21, x21, x23
    b process_entries

close_dir:
    ldr x19, =fd
    ldr x0, [x19]
    mov x8, #57              // close
    svc #0

list_done:
    ldp x29, x30, [sp], #16
    ret

strlen:
    mov x4, #0
strlen_loop:
    ldrb w5, [x0, x4]
    cmp w5, #0
    beq strlen_ret
    add x4, x4, #1
    b strlen_loop
strlen_ret:
    mov x0, x4
    ret

exit:
    mov x8, #93
    mov x0, #0
    svc #0