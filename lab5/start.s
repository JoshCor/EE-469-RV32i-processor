# =================================================================
# TEST DESCRIPTION: 
# Prints "Hello!\n" to the output memory location 0x0002_FFF8.
#
# EXPECTED OUTPUT: Hello!
# (followed by a newline)
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

# --- 2. PRINT 'H' (72) ---
addi a0, x0, 72           
nop
nop
nop
sw   a0, 0(t0)            # Output 'H'

# --- 3. PRINT 'e' (101) ---
addi a0, x0, 101          
nop
nop
nop
sw   a0, 0(t0)            # Output 'e'

# --- 4. PRINT 'l' (108) ---
addi a0, x0, 108          
nop
nop
nop
sw   a0, 0(t0)            # Output 'l'

# --- 5. PRINT 'l' (108) ---
# (Even though it's the same value, we re-store it)
sw   a0, 0(t0)            # Output 'l'

# --- 6. PRINT 'o' (111) ---
addi a0, x0, 111          
nop
nop
nop
sw   a0, 0(t0)            # Output 'o'

# --- 7. PRINT '!' (33) ---
addi a0, x0, 33           
nop
nop
nop
sw   a0, 0(t0)            # Output '!'

# --- 8. PRINT '\n' (10) ---
addi a0, x0, 10           
nop
nop
nop
sw   a0, 0(t0)            # Output '\n'

# --- 9. HALT ---
addi a1, x0, 1            # a1 = 1
nop
nop
nop
sw   a1, 4(t0)            # Write 1 to 0x0002_FFFC (Halt)