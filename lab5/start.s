# Target Addresses:
# Output: 0x0002_FFF8
# Halt:   0x0002_FFFC

# 1. Initialize Base Pointer
# We want t0 to hold 0x0002_FFF8. 
# We'll use LUI (Load Upper Immediate) to get close.
lui t0, 0x00030           # t0 = 0x0003_0000
nop
nop
nop

# 2. Adjust Pointer to exact Output address
# 0x0003_0000 - 8 = 0x0002_FFF8
addi t0, t0, -8           
nop
nop
nop

# 3. Write "G" (ASCII 0x47 / 71)
addi a0, x0, 71           
nop
nop
nop
sw a0, 0(t0)              # Store to 0x0002_FFF8 (Output)
nop
nop
nop

# 4. Write "E" (ASCII 0x45 / 69)
addi a0, x0, 69           
nop
nop
nop
sw a0, 0(t0)              # Store to 0x0002_FFF8 (Output)
nop
nop
nop

# 5. Write "M" (ASCII 0x4D / 77)
addi a0, x0, 77           
nop
nop
nop
sw a0, 0(t0)              # Store to 0x0002_FFF8 (Output)
nop
nop
nop

# 6. Halt Simulation
# Write a 1 to 0x0002_FFFC (which is t0 + 4)
addi a1, x0, 1            
nop
nop
nop
sw a1, 4(t0)              # Store to 0x0002_FFFC (Halt)
nop
nop
nop