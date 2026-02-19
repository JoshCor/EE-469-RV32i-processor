#.extern main
.globl _start

#######################################################
# code to test most basic instructions
# will print out string to console
#######################################################
.text
_start:

    # load addresses of buffers
    la  a0, dest_buf     # a0 = destination
    la  a1, src_buf      # a1 = source

    call hw2_strcpy

    # print copied string
    la  a0, dest_buf
    call print_string

    # halt simulation
    li  t0, 0x0002FFFC
    sw  zero, 0(t0)

########################################################
# print_string(a0 = pointer)
########################################################

print_string:
    li  t2, 0x0002FFF8   # output register

print_loop:
    lb  t1, 0(a0)
    beq t1, zero, print_done

    sw  t1, 0(t2)        # simulator prints char/value
    addi a0, a0, 1
    j   print_loop

print_done:
    ret



hw2_strcpy:
    # standard function set up, save return adress and stack frame pointer
    addi sp,sp,-16
    sw s0, 0(sp)
    sw ra, 12(sp)

    # a0 = *dest, a1 = *src
    mv t0,a0 # store front of destination string in temp memory
    loop:
        lb t1, 0(a1) # load the value pointed to by a1 into t1
        beq t1, zero, end # exit loop (jump to end) when *a1 = '\0'
        sb t1, 0(a0) # store the value in t1 to the location a1
        addi a0, a0, 1 # increment a0 which is the src pointer
        addi a1, a1, 1 # increment a1 which is the dest pointer
        j loop # loop
    end:
        sb zero, 0(a0) # store a null terminator into the end of the string
        mv a0, t0 # set a0 to t0 for return

    # standard function end, restore return adress and stack frame pointer
    lw ra, 12(sp)
    lw s0, 0(sp)
    addi sp,sp,16
    ret # jump to the return address (end function)

  

########################################################
# Data section
########################################################

.data

src_buf:
    .asciz "Hello Lab!\n"

dest_buf:
    .space 64