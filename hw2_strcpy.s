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