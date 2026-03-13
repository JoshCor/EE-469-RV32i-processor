.section .text
.global _start
_start:
    li    s2, 0x0002FFF8   # output port
    li    s3, 0x0002FFFC   # halt port
    li    s4, 65           # 'A'
    li    s5, 70           # 'F' (Fail)

    # -----------------------------------------------
    # LEVEL 1: Basic Store (No hazards)
    # -----------------------------------------------
    sw    s4, 0(s2)        # Should print 'A'
    nop
    nop
    nop

    # -----------------------------------------------
    # LEVEL 2: RAW Hazard (EX -> EX Forwarding)
    # -----------------------------------------------
    li    t0, 66           # 'B'
    mv    t1, t0           # Hazard! t0 is in EX/MEM
    sw    t1, 0(s2)        # Should print 'B'
    nop
    nop

    # -----------------------------------------------
    # LEVEL 3: RAW Hazard (MEM -> EX Forwarding)
    # -----------------------------------------------
    li    t0, 67           # 'C'
    nop                    # Move t0 to MEM/WB
    mv    t1, t0           # Hazard!
    sw    t1, 0(s2)        # Should print 'C'
    nop
    nop

    # -----------------------------------------------
    # LEVEL 4: Load-Use Stall
    # -----------------------------------------------
    la    t0, 68
    lw    t1, 0(t0)        # t1 = 68 ('D')
    mv    t2, t1           # MUST STALL HERE
    sw    t2, 0(s2)        # Should print 'D'
    nop
    nop

    # -----------------------------------------------
    # LEVEL 5: Branch Flush
    # -----------------------------------------------
    li    t0, 1
    beq   t0, t0, t_jump   # Should flush the next 'F' store
    sw    s5, 0(s2)        # Fail if this prints
    j     halt
t_jump:
    li    t0, 69           # 'E'
    sw    t0, 0(s2)        # Should print 'E'

halt:
    li    t0, 1
    sw    t0, 0(s3)        # Finish

.section .data
.align 4
test_val: .word 68