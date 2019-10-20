* arithmetic6800.asm
*  - add/sub/mul/div routines in 6800 assembly (as0)
*
*
* Mikbug Entries
outch       equ $e075
pdata1      equ $e07e
out2h       equ $e0bf
*
* workarea
*
            org $0500
r1:         fdb $0000
r2:         fdb $0000
r101:       fdb $0000
r102:       fdb $0000
r103:       fdb $0000
r104:       fdb $0000
rmdr:       fdb $0000
* Start
            org $0400
*
* test add
            ldx #$00ff
            stx r1
            ldx #$0140
            stx r2
            jsr add16
            ldx r1
            stx r101
* test sub
            ldx #$1000
            stx r1
            ldx #$0040
            stx r2
            jsr sub16
            ldx r1
            stx r102
* test mul ; $5f * $35 = $13ab
            ldx #$005f
            stx r1
            ldx #$0035
            stx r2
            jsr mul16
            ldx r1
            stx r103
* test div ; $5555 / $33 = $01ac, rmdr = $11
            ldx #$5555
            stx r1
            ldx #$0033
            stx r2
            jsr div16
            ldx r1
            stx r104
* end
            swi
* add16: r1 + r2 -> r1, carry -> r2(msb)
add16:
            ldab r1+1
            ldaa r1
            addb r2+1
            adca r2
            stab r1+1
            staa r1
            tpa
            staa r2
            rts
*
* sub16: r1 - r2 -> r1, carry -> r2(msb)
sub16:
            ldab r1+1
            ldaa r1
            subb r2+1
            sbca r2
            stab r1+1
            staa r1
            tpa
            staa r2
            rts
*
* mul16: r1 * r2 -> r1
mul16:
            clra
            clrb
            ldx #16     ; preparing the 16 bit loop
mul16a:
            lsr r2
            ror r2+1
            bcc mul16b
            addb r1+1 
            adca r1
            bcs mul16err
mul16b:
            pshb
            lsrb ; put lsb -> Carry
            pulb ; restore accB
            rora
            rorb
            dex
            bne mul16a
            stab r1+1
            staa r1
            tpa
            staa r2
            rts ; succesfull
mul16err:
            ldx #$ffff
            stx r1
            stx r2
            rts ; error; r1=r2=$ffff
* div16: r1 / r2 -> r1, remainder-> rmdr
div16:
            clra
            clrb
            ldx #16     ; preparing the 16 bit loop
div16a:
            asl r1+1
            rol r1
            rolb
            rola
            stab rmdr+1
            staa rmdr
            subb r2+1
            sbca r2
            bcc div16b  ; success
            ldab rmdr+1 ; fail, recover remainder
            ldaa rmdr
            bra div16c
div16b:
            inc r1+1 ; success, inc dividend
div16c:
            dex
            bne div16a
            stab rmdr+1
            staa rmdr
            rts
*
* end