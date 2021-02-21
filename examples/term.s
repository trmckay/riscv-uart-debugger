.equ TERM_STAT_ADDR, 0x11010000
.equ TERM_CHAR_ADDR, 0x11010004

INIT:
    li s0, TERM_STAT_ADDR
    li s1, TERM_CHAR_ADDR
    li t1, 1
    li t0, 0x41  # 0x41 = ASCII(a)

MAIN:
    sw t0, 0(s1) # write character
    sw t1, 0(s0) # set status to ready
    j MAIN
