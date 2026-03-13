.section .text
.global _start
_start:
    li   s2, 0x0002FFF8   # output port
    li   s3, 0x0002FFFC   # halt port
    li   s4, 80           # 'P'
    li   s5, 70           # 'F'

    li   t0, 0x41
    sw   t0, 0(s2)        # 'A' before call
    la   a0, dest_buf
    la   a1, src_single
    call hw2_strcpy
    li   t0, 0x42
    sw   t0, 0(s2)        # 'B' after call
    li   t0, 1
    sw   t0, 0(s3)
spin:
    j    spin

hw2_strcpy:
    addi sp, sp, -32
    sw   ra, 28(sp)
    sw   s0,  0(sp)
    sw   s1,  4(sp)
    sw   s2,  8(sp)
    sw   s3, 12(sp)
    sw   s4, 16(sp)
    sw   s5, 20(sp)
    sw   s6, 24(sp)
    li   t0, 0x43
    sw   t0, 0(s2)        # 'C' entered
    mv   s0, a0
loop:
    lb   s1, 0(a1)
    beq  s1, zero, end
    sb   s1, 0(a0)
    addi a0, a0, 1
    addi a1, a1, 1
    j    loop
end:
    sb   zero, 0(a0)
    mv   a0, s0
    li   t0, 0x44
    sw   t0, 0(s2)        # 'D' about to ret
    lw   ra, 28(sp)
    lw   s6, 24(sp)
    lw   s5, 20(sp)
    lw   s4, 16(sp)
    lw   s3, 12(sp)
    lw   s2,  8(sp)
    lw   s1,  4(sp)
    lw   s0,  0(sp)
    addi sp, sp, 32
    ret

.section .data
.align 4
src_single: .asciz "P"
dest_buf:   .space 64