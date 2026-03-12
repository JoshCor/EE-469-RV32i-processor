.globl _start
.text
_start:
    # setup stack
    lui  sp, 0x00001        # sp = 0x1000
    sw s0, 0(sp)
    sw s1, 4(sp)

    # setup I/O addresses
    lui  s0, 0x00030
    addi s0, s0, -8         # t0 = 0x0002FFF8 output
    lui  s1, 0x00030
    addi s1, s1, -4         # t1 = 0x0002FFFC halt
    

    # call strcpy
    la   a0, dest_buf
    la   a1, src_buf
    call hw2_strcpy

    # print result
    la   a0, dest_buf
    call print_string

    # halt
    li   t2, 1
    sw   t2, 0(s1)

print_string:
    lui  t2, 0x00030
    addi t2, t2, -8
print_loop:
    lb   t3, 0(a0)
    beq  t3, zero, print_done
    sw   t3, 0(t2)
    addi a0, a0, 1
    j    print_loop
print_done:
    lw s1, 4(sp)
    lw s0, 0(sp)
    ret

hw2_strcpy:
    # standard function set up, save return adress and stack frame pointer
    addi sp,sp,-16
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw ra, 12(sp)

    # a0 = *dest, a1 = *src
    mv s0,a0 # store front of destination string in temp memory
    loop:
        lb s1, 0(a1) # load the value pointed to by a1 into t1
        beq s1, zero, end # exit loop (jump to end) when *a1 = '\0'
        sb s1, 0(a0) # store the value in t1 to the location a1
        addi a0, a0, 1 # increment a0 which is the src pointer
        addi a1, a1, 1 # increment a1 which is the dest pointer
        j loop # loop
    end:
        sb zero, 0(a0) # store a null terminator into the end of the string
        mv a0, s0 # set a0 to s0 for return

    # standard function end, restore return adress and stack frame pointer
    lw ra, 12(sp)
    lw s1, 4(sp)
    lw s0, 0(sp)
    addi sp,sp,16
    ret # jump to the return address (end function)

src_buf:
    .asciz "Hello Lab!\n"
dest_buf:
    .space 64