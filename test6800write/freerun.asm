* freerun.asm
*
* 6800 Free Run Test
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
        ldx #$0000 ; write to ($0200)-($02FF)
        stx STRX_BASE+$00
        stx STRX_BASE+$02
        stx STRX_BASE+$04
        stx STRX_BASE+$06
        stx STRX_BASE+$08
        stx STRX_BASE+$0A
        stx STRX_BASE+$0C
        stx STRX_BASE+$0E
        stx STRX_BASE+$10
        stx STRX_BASE+$12
        stx STRX_BASE+$14
        stx STRX_BASE+$16
        stx STRX_BASE+$18
        stx STRX_BASE+$1A
        stx STRX_BASE+$1C
        stx STRX_BASE+$1E
        stx STRX_BASE+$20
        stx STRX_BASE+$22
        stx STRX_BASE+$24
        stx STRX_BASE+$26
        stx STRX_BASE+$28
        stx STRX_BASE+$2A
        stx STRX_BASE+$2C
        stx STRX_BASE+$2E
        stx STRX_BASE+$30
        stx STRX_BASE+$32
        stx STRX_BASE+$34
        stx STRX_BASE+$36
        stx STRX_BASE+$38
        stx STRX_BASE+$3A
        stx STRX_BASE+$3C
        stx STRX_BASE+$3E
        stx STRX_BASE+$40
        stx STRX_BASE+$42
        stx STRX_BASE+$44
        stx STRX_BASE+$46
        stx STRX_BASE+$48
        stx STRX_BASE+$4A
        stx STRX_BASE+$4C
        stx STRX_BASE+$4E
        stx STRX_BASE+$50
        stx STRX_BASE+$52
        stx STRX_BASE+$54
        stx STRX_BASE+$56
        stx STRX_BASE+$58
        stx STRX_BASE+$5A
        stx STRX_BASE+$5C
        stx STRX_BASE+$5E
        stx STRX_BASE+$60
        stx STRX_BASE+$62
        stx STRX_BASE+$64
        stx STRX_BASE+$66
        stx STRX_BASE+$68
        stx STRX_BASE+$6A
        stx STRX_BASE+$6C
        stx STRX_BASE+$6E
        stx STRX_BASE+$70
        stx STRX_BASE+$72
        stx STRX_BASE+$74
        stx STRX_BASE+$76
        stx STRX_BASE+$78
        stx STRX_BASE+$7A
        stx STRX_BASE+$7C
        stx STRX_BASE+$7E
        stx STRX_BASE+$80
        stx STRX_BASE+$82
        stx STRX_BASE+$84
        stx STRX_BASE+$86
        stx STRX_BASE+$88
        stx STRX_BASE+$8A
        stx STRX_BASE+$8C
        stx STRX_BASE+$8E
        stx STRX_BASE+$90
        stx STRX_BASE+$92
        stx STRX_BASE+$94
        stx STRX_BASE+$96
        stx STRX_BASE+$98
        stx STRX_BASE+$9A
        stx STRX_BASE+$9C
        stx STRX_BASE+$9E
        stx STRX_BASE+$A0
        stx STRX_BASE+$A2
        stx STRX_BASE+$A4
        stx STRX_BASE+$A6
        stx STRX_BASE+$A8
        stx STRX_BASE+$AA
        stx STRX_BASE+$AC
        stx STRX_BASE+$AE
        stx STRX_BASE+$B0
        stx STRX_BASE+$B2
        stx STRX_BASE+$B4
        stx STRX_BASE+$B6
        stx STRX_BASE+$B8
        stx STRX_BASE+$BA
        stx STRX_BASE+$BC
        stx STRX_BASE+$BE
        stx STRX_BASE+$C0
        stx STRX_BASE+$C2
        stx STRX_BASE+$C4
        stx STRX_BASE+$C6
        stx STRX_BASE+$C8
        stx STRX_BASE+$CA
        stx STRX_BASE+$CC
        stx STRX_BASE+$CE
        stx STRX_BASE+$D0
        stx STRX_BASE+$D2
        stx STRX_BASE+$D4
        stx STRX_BASE+$D6
        stx STRX_BASE+$D8
        stx STRX_BASE+$DA
        stx STRX_BASE+$DC
        stx STRX_BASE+$DE
        stx STRX_BASE+$E0
        stx STRX_BASE+$E2
        stx STRX_BASE+$E4
        stx STRX_BASE+$E6
        stx STRX_BASE+$E8
        stx STRX_BASE+$EA
        stx STRX_BASE+$EC
        stx STRX_BASE+$EE
        stx STRX_BASE+$F0
        stx STRX_BASE+$F2
        stx STRX_BASE+$F4
        stx STRX_BASE+$F6
        stx STRX_BASE+$F8
        stx STRX_BASE+$FA
        stx STRX_BASE+$FC
        stx STRX_BASE+$FE
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
