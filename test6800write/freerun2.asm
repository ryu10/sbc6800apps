* freerun.asm
*
* 6800 Free Run Test #2
* Write to 2 pages
* 2019 ryu10
*
* Mikbug Entries
outch   equ $e075
* Consts
STRX_BASE equ $0200 ; base address for stx block
STRA_BASE equ $0300 ; base address for STRA block
CH_X equ 'X
CH_A equ 'A
*
        org $0400
start:
        ldx #STRX_BASE ; write to ($0200)-($02FF)
l_stx:
        stx 0,x
        inx
        inx
        cpx #$0300
        bne l_stx
        ldaa #CH_X
        jsr outch
*
        clra
        ldx #STRA_BASE  ; write to ($0300)-($03FF)
l1:
        staa 0,x
        inx
        inca
        bne l1
        ldaa #CH_A
        jsr outch
*
        jmp start ; do forever
*       end
