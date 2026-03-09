# =================================================================
# TEST DESCRIPTION: 
# Tests JAL and branch instructions (BNE loop) with no bypassing.
# Prints "Hello!\n" using direct stores, then uses a BNE loop
# to print "!!!\n" (3 exclamation marks via loop counter).
# Then halts.
#
# EXPECTED OUTPUT: Hello!!!!!\n
# (followed by a newline from the loop)
# =================================================================

# --- 1. SETUP I/O ADDRESS ---
lui  t0, 0x00030          # t0 = 0x0003_0000
nop
nop
nop
addi t0, t0, -8           # t0 = 0x0002_FFF8 (Output Port)
nop
nop
nop

# --- 2. JUMP OVER DEAD CODE (tests JAL) ---
jal  x0, start_print      # Jump forward, skipping the trap instruction
nop
nop
nop
addi a0, x0, 88           # 'X' -- should never execute
nop
nop
nop
sw   a0, 0(t0)            # should never execute

# --- 3. PRINT "Hello!" ---
start_print:
addi t2, x0, 72           # t2 = 'H'
nop
nop
nop
sw   t2, 0(t0)            # print 'H'
nop
nop
nop
addi t2, x0, 101          # t2 = 'e'
nop
nop
nop
sw   t2, 0(t0)            # print 'e'
nop
nop
nop
addi t2, x0, 108          # t2 = 'l'
nop
nop
nop
sw   t2, 0(t0)            # print 'l'
nop
nop
nop
sw   t2, 0(t0)            # print 'l' again
nop
nop
nop
addi t2, x0, 111          # t2 = 'o'
nop
nop
nop
sw   t2, 0(t0)            # print 'o'
nop
nop
nop
addi t2, x0, 33           # t2 = '!'
nop
nop
nop
sw   t2, 0(t0)            # print '!'
nop
nop
nop

# --- 4. BNE LOOP: print '!' 4 more times ---
addi t1, x0, 4            # t1 = loop counter
nop
nop
nop
addi t2, x0, 33           # t2 = '!'
nop
nop
nop
loop:
sw   t2, 0(t0)            # print '!'
nop
nop
nop
addi t1, t1, -1           # t1--
nop
nop
nop
bne  t1, x0, loop         # branch back if t1 != 0
nop
nop
nop

# --- 5. PRINT '\n' ---
addi t2, x0, 10           # t2 = '\n'
nop
nop
nop
sw   t2, 0(t0)            # print '\n'
nop
nop
nop

# --- 6. HALT ---
addi a1, x0, 1            # a1 = 1
nop
nop
nop
sw   a1, 4(t0)            # Write 1 to 0x0002_FFFC (Halt)