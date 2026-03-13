.section .text
.global _start

_start:
    li  x5,  0x0002FFF8  # Output port
    li  x30, 0x0002FFFC  # Halt address
    li  x28, 80          # 'P' (pass)
    li  x29, 70          # 'F' (fail)
    li  x27, 71          # 'G' (stall)
    li  x26, 72          # 'H' (load nop)

    # -----------------------------------------------
    # TEST 1: EX->EX bypass (back-to-back RAW)
    # x2 written, x3 reads x2 the very next instruction
    # -----------------------------------------------
    li   x2, 78
    addi x3, x2, 2       # x3 = 80 -- EX/MEM->EX forward required
    bne  x3, x28, fail
    sw   x28, 0(x5)      # 'P'

    # -----------------------------------------------
    # TEST 2: EX->EX bypass chain
    # x3->x4->x6 consecutive dependencies
    # -----------------------------------------------
    li   x2, 76
    addi x3, x2, 1       # x3 = 77, EX->EX
    addi x4, x3, 1       # x4 = 78, EX->EX
    addi x6, x4, 2       # x6 = 80, EX->EX
    bne  x6, x28, fail
    sw   x28, 0(x5)      # 'P'

    # -----------------------------------------------
    # TEST 3: MEM->EX bypass (1 instruction gap)
    # -----------------------------------------------
    li   x2, 79
    addi x3, x2, 0       # x3 = 79
    nop                   # x3 now in MEM/WB when next instr hits EX
    addi x4, x3, 1       # x4 = 80 -- MEM/WB->EX forward required
    bne  x4, x28, fail
    sw   x28, 0(x5)      # 'P'

    # -----------------------------------------------
    # TEST 4: WB->DEC bypass (2 instruction gap)
    # -----------------------------------------------
    li   x2, 80
    nop
    nop
    add  x3, x2, x0      # x3 = 80 -- WB->DEC forward required
    bne  x3, x28, fail
    sw   x28, 0(x5)      # 'P'

    # -----------------------------------------------
    # TEST 5: Load-use stall
    # LW followed immediately by dependent instruction
    # Pipeline must stall 1 cycle then MEM->EX forward
    # -----------------------------------------------
    la   x7, data_val
    lw   x8, 0(x7)       # load 80
    add  x9, x8, x0      # RAW: stall inserted, then forward
    bne  x9, x28, fail
    sw   x27, 0(x5)      # 'G'

    # -----------------------------------------------
    # TEST 6: Load result forwarded after 1 NOP
    # No stall needed, but MEM->EX bypass still required
    # -----------------------------------------------
    la   x7, data_val
    lw   x8, 0(x7)       # load 80
    nop
    add  x9, x8, x0      # MEM/WB->EX forward of load result
    bne  x9, x28, fail
    sw   x26, 0(x5)      # 'H'

    # -----------------------------------------------
    # TEST 7: Branch using forwarded value
    # Tests that bypass feeds branch comparator correctly
    # -----------------------------------------------
    li   x10, 79
    addi x11, x10, 1     # x11 = 80 -- EX->EX bypass
    bne  x11, x28, fail  # branch depends on just-computed x11
    sw   x28, 0(x5)      # 'P'

    # -----------------------------------------------
    # TEST 8: Branch not taken (no flush)
    # -----------------------------------------------
    li   x10, 1
    li   x11, 2
    beq  x10, x11, fail  # condition false, must not flush
    sw   x28, 0(x5)      # 'P' -- only prints if flush was correctly suppressed

    # -----------------------------------------------
    # TEST 9: Branch taken + flush
    # 2 instructions after branch must be squashed
    # -----------------------------------------------
    li   x20, 0
    beq  x20, x20, t9_pass
    sw   x29, 0(x5)      # 'F' -- flush failed if this prints
    j    fail
t9_pass:
    sw   x28, 0(x5)      # 'P'

    # -----------------------------------------------
    # TEST 10: Store with forwarded rs2
    # Verifies bypass reaches rd2 path, not just rd1
    # -----------------------------------------------
    li   x2, 80
    addi x3, x2, 0       # x3 = 80 -- will be rs2 of store
    sw   x3, 0(x5)       # 'P' -- EX->EX bypass into store's data path

    # All passed - halt
    li   x10, 1
    sw   x10, 0(x30)

fail:
    sw   x29, 0(x5)      # 'F'
spin:
    j    spin

.section .data
.align 4
data_val: .word 80       # 'P'