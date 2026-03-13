# load stall test
.section .text
.global _start
_start:
    li    s2, 0x0002FFF8   # output port
    li    s3, 0x0002FFFC   # halt port

    la    t0, test_val
    lw    t1, 0(t0)        # t1 = 68 ('D')
    mv    t2, t1           # MUST STALL HERE
    sw    t2, 0(s2)        # Should print 'D'

    halt:
    li    t0, 1
    sw    t0, 0(s3)        # Finish

.section .data
.align 4
test_val: .word 68