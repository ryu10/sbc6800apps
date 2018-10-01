*
* Conway's Game of Life
* for SBC6800 (Bit-sum)
* 2018 ryu10
*
*
* Mikbug Entries
outch   equ $e075
pdata1  equ $e07e
out2h   equ $e0bf
*
* Constants
esc     equ $1b
linebyte equ 4  ; widht of the buffer in bytes
bwidth  equ 32   ; px width of the buffer
bheight equ 16   ; height of the buffer
buf_len equ bheight*linebyte   ; buffer length in bytes
blen_mask equ linebyte-1 ; max# of bytes in a line
*
        org $0100
        ldx #screen_buf1
        stx curr_bufp
        ldx #screen_buf2
        stx next_bufp
        clra
        staa gen_ctr
        staa gen_ctr+1
        staa gen_ctr+2
        staa gen_ctr+3
        ldx #screen_clr_d
        jsr pdata1
        ldx #screen_home_d
        jsr pdata1
        ldx #title_str_d
        jsr pdata1
        jsr init_screen
loop:   jsr mirror_edges ; make it toroidal
        jsr print_screen
        jsr gen_update ; update the next_buf based on the game rules
        jsr swap_buffer
        bra loop
        swi                 ; end main
*
init_screen:
        ldx #screen_buf_init
        stx curr_adrs ; as a temporary workspace
        ldx curr_bufp
        stx temp_word
        ldaa #buf_len
init_scr1:
        ldx curr_adrs
        ldab 0,x
        inx
        stx curr_adrs
        ldx temp_word
        stab 0,x
        inx
        stx temp_word
        deca
        bne init_scr1
        rts
*
mirror_edges:
* mirror the buffer edges to make it a torus
* draw top & bottom edges
        ldx curr_bufp
        ldab #linebyte ; repeat four times
mirr_topbtm:
        ldaa linebyte,x
        staa buf_len-linebyte,x ; mirror top to bottom edge
        ldaa buf_len-linebyte-linebyte,x
        staa 0,x ; mirror bottom to top edge
        inx
        decb
        bne mirr_topbtm
* draw left & right edges
        ldx curr_bufp
        ldaa #linebyte
mirr4:  inx
        deca
        bne mirr4 ; start x from curr_bufp+linebyte (line#1)
        ldab #bheight-2 ; repeat 14 times
mirr_leftrt:
        pshb ; iter counter
        ldaa 0,x
        ldab linebyte-1,x
        rola ; bit6->bit7
        rorb
        rola ; bit7->carry
        rolb ; carry->bit0
        stab linebyte-1,x ; copy left to right edge
        ldaa 0,x ; restore left
        rorb ; bit1->bit0
        rola
        rorb ; bit0->carry
        rora ; carry->bit7
        staa 0,x ; copy right to left edge
        ldaa #linebyte
mirr5:  inx
        deca
        bne mirr5
        pulb ; iter counter
        decb
        bne mirr_leftrt
* draw four corners
        ldx curr_bufp
        ldaa linebyte,x ; topleft to bottomright
        ldab buf_len-1,x
        rola ; bit6->7
        rorb
        rola ; bit7->carry
        rolb ; carry->bit0
        stab buf_len-1,x
        ldaa buf_len-linebyte-1,x ; bottomright to topleft
        ldab 0,x
        rora ; bit1->bit0
        rolb
        rora ; bit0->carry
        rorb ; carry->MSB
        stab 0,x
        ldaa 2*linebyte-1,x; topright to bottomleft
        ldab buf_len-linebyte,x
        rora ; bit1->bit0
        rolb
        rora ; bit0->carry
        rorb ; carry->MSB
        stab buf_len-linebyte,x
        ldaa buf_len-linebyte-linebyte,x; bottomleft to topright
        ldab linebyte-1,x
        rola ; bit6->7
        rorb
        rola ; bit7->carry
        rolb ; carry->bit0
        stab linebyte-1,x
        rts
*
gen_update:
        ldx curr_bufp
        ldaa #linebyte
        staa curr_off
update0:
        inx
        deca
        bne update0
        stx curr_adrs ; start from line 1
        ldx next_bufp
        ldaa #linebyte
update1:
        inx
        deca
        bne update1
        stx next_adrs ; start from line 1
* get the shifted frames ka-kh
update_loop1:
        ldx curr_adrs
        ldaa #linebyte
update2:
        dex
        deca
        bne update2
        jsr get3frames ; x = prev line (upper)
        ldaa temp_word
        staa ka
        ldaa temp_word+1
        staa kb
        stab kc
        ldx curr_adrs
        jsr get3frames ; x = curr line (middle)
        ldaa temp_word
        staa kd
        stab ke
        ldx curr_adrs
        ldaa #linebyte
update3:
        inx
        deca
        bne update3
        jsr get3frames ; x = next line (lower)
        ldaa temp_word
        staa kf
        ldaa temp_word+1
        staa kg
        stab kh
* calculate neighbor counts and update next byte
        ldx curr_adrs
        ldaa 0,x
        staa temp_word ; save curr byte
        ldaa #8
upd_byte:
        psha
        clrb
        ldx #ka
        ldaa #8
upd_bit:
        psha
        ldaa 0,x ; load ka ... kh
        rola
        bcc upd_b1
        incb
upd_b1: staa 0,x
        inx
        pula
        deca
        bne upd_bit
* at this point AccB contains the neighbor count
        cmpb #2
        bne upd_b21
        ldx curr_adrs
        ldaa 0,x ; load curr
        rola   ; count=2, need to check curr
        bcc upd_b22
        ldx next_adrs
        ldaa 0,x ; load next
        sec    ; count=2, current=1 -> set next bit
        bra upd_b3
upd_b21:
        cmpb #3
        bne upd_b22
        ldx next_adrs
        ldaa 0,x ; load next
        sec      ; count = 3 -> set next bit
        bra upd_b3
upd_b22:
        ldx next_adrs
        ldaa 0,x ; load next
        clc      ; otherwise -> clear next bit
upd_b3:
        rola
        staa 0,x ; store next
        ldx curr_adrs
        ldaa 0,x
        rola     ; rotate curr
        staa 0,x
        pula
        deca
        bne upd_byte
* rotate ops done, restore curr
        ldx curr_adrs
        ldaa temp_word
        staa 0,x
* increment the buf pointers and test if reached to the end
*        ldx curr_adrs   ; inc current adrs
        inx
        stx curr_adrs
        ldx next_adrs
        inx
        stx next_adrs
        ldaa curr_off
        inca
        staa curr_off
        adda #linebyte ; add one line (exit loop at maxline -1)
        cmpa #buf_len
        beq update4
        jmp update_loop1
update4:
        rts
* get3frames, x=input, temp_word=left&mid frames, b=right frame
get3frames:
        dex
        ldaa 0,x ; get left byte
        ldab 1,x ; get mid byte
        stab temp_word+1 ; mid frame
        rora
        rorb
        stab temp_word ; left frame
        rolb ; restore mid byte
        ldaa 2,x ; get right byte
        rola
        rolb ; b = righ frame
        inx ; restore x
        rts
*
print_gen_ctr:
        jsr inc_gen_ctr
        ldx #gen_ctr
        jsr out2h
        jsr out2h
        jsr out2h
        jsr out2h
        rts
*
inc_gen_ctr:
        ldaa gen_ctr+3
        clc
        adca #1
        daa
        staa gen_ctr+3
        ldaa gen_ctr+2
        adca #0
        daa
        staa gen_ctr+2
        ldaa gen_ctr+1
        adca #0
        daa
        staa gen_ctr+1
        ldaa gen_ctr
        adca #0
        daa
        staa gen_ctr
        rts
*
print_screen:
        ldx #screen_home_d ; move cursor to home
        jsr pdata1
        ldx #skiptitle_str_d ; skip title text
        jsr pdata1
        jsr print_gen_ctr ; print ctr next to title
        ldx #screen_home1_d ; move cursor to home
        jsr pdata1
        ldx #screen_clr1_d ; clear the rest of the screen
        jsr pdata1
        ldx curr_bufp ; init pointers
        stx curr_adrs
        clr curr_off
read_position:
        ldx curr_adrs ; print contents with loop
        ldaa 0,x
        bne rp0  ; contains dots
        ldx #skip8_d ; empty, skip 8px
        jsr pdata1
        bra rp3
rp0:    ldab #8      ; draw 8 pix
rp1:    rola
        psha
        pshb
        bcc rp20 ; carry flg stores rola result
        ldaa #'*
        bra rp2
rp20:   ldaa #$20 ; space char
rp2:    jsr outch
        pulb ; bit pos count
        pula ; bit pattern
        decb
        bne rp1
rp3:    ldaa curr_off; test and print eol
        ldab #linebyte
        anda #blen_mask
        cmpa #blen_mask
        bne rp4
        ldx #crlf_d
        jsr pdata1
rp4:    ldx curr_adrs
        inx
        stx curr_adrs
        ldaa curr_off
        inca
        staa curr_off
        cmpa #buf_len
        bne read_position
        rts
* Swap screen buffers
swap_buffer:
        ldx curr_bufp
        stx temp_word
        ldx next_bufp
        stx curr_bufp
        ldx temp_word
        stx next_bufp
        rts
* Data area
screen_clr_d:
        fcb esc,'[,'2,'J,4
screen_clr1_d:
        fcb esc,'[,'J,4
screen_home_d:
        fcb esc,'[,'1,';,'1,'H,4
screen_home1_d:
        fcb esc,'[,'2,';,'0,'H,4
skip8_d:
        fcb esc,'[,'8,'C,4
title_str_d:
        fcc " [CONWAY'S GAME OF LIFE] GEN: "
        fcb 4
skiptitle_str_d:
        fcb esc,'[,'3,'0,'C,4
gen_str_d:
        fcc "GEN: "
        fcb 4
crlf_d: fcb 13,10,4
gen_ctr:
        fcb 0,0,0,0 ; 4byte bcd
temp_word:
        fcb 0,0
curr_bufp:
        fcb 0,0
next_bufp:
        fcb 0,0
curr_adrs:
        fcb 0,0
next_adrs:
        fcb 0,0
curr_off:
        fcb 0
next_off:
        fcb 0
* update algorithm variables
ka:     fcb 0
kb:     fcb 0
kc:     fcb 0
kd:     fcb 0
ke:     fcb 0
kf:     fcb 0
kg:     fcb 0
kh:     fcb 0
s2:     fcb 0
s3:     fcb 0
xab:    fcb 0
xcd:    fcb 0
xef:    fcb 0
xgh:    fcb 0
*
screen_buf_init:
        fcb $00,$00,$00,$00
        fcb $20,$00,$20,$00
        fcb $10,$00,$10,$00
        fcb $70,$00,$70,$00
        fcb $00,$20,$00,$20
        fcb $00,$10,$00,$10
        fcb $00,$70,$00,$70
        fcb $20,$00,$20,$00
        fcb $10,$00,$10,$00
        fcb $70,$00,$70,$00
        fcb $00,$20,$00,$20
        fcb $00,$10,$00,$10
        fcb $00,$70,$00,$70
        fcb $00,$00,$00,$00
        fcb $00,$00,$00,$00
        fcb $00,$00,$00,$00
*
var:    org $0500
screen_buf1:
        rmb buf_len ; 32x16 bits = 64 bytes
screen_buf2:
        rmb buf_len
        end
