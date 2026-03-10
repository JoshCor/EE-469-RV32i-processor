.globl _start
.text
_start:
    lui  t0, 0x00030
    addi t0, t0, -8
    addi t1, t0, 4

    la   a0, src_buf
    nop
    nop
    nop
    lb   t2, 0(a0)
    nop
    nop
    nop
    sw   t2, 0(t0)      # should print 'H'

    li   t2, 1
    sw   t2, 0(t1)
hang:
    j    hang

.data
src_buf:
    .asciz "Hi\n"
dest_buf:
    .space 64