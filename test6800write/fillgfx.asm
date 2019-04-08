* fillgfx.asm
*
* 6800 Fill the virtual vram
* Fill 0x4000-0x657f with 0xff
* 2019 ryu10
*
* Mikbug Entries
outch   equ $e075
* Consts
VRAM_START equ $4000
VRAM_END equ $6580
CH_X    equ 'X
*
        org $0400
start:
        ldx #VRAM_START
        ldaa #$ff
l_stx:
        staa 0,x
        inx
        cpx #VRAM_END
        bne l_stx
        ldaa #CH_X
        jsr outch
*
        swi
*       end
