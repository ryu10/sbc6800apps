*
* Conway's Game of Life (Bitboard)
* for SBC6800
* and K68-VDG
* 2020/2022 ryuStudio
*
* Constants
linebyte equ 4  ; widht of the buffer in bytes
bwidth  equ 32   ; px width of the buffer
bheight equ 16   ; height of the buffer
buf_len equ bheight*linebyte   ; buffer length in bytes
blen_mask equ linebyte-1 ; max# of bytes in a line
vram_top equ $a000
vram_end equ $a200
vdg_ctl_ad equ $8110
vdg_mode equ %00000000
spc equ $20
greenbase equ $80 ; (blank char for green dots)
*
        org $0200
        ldx #screen_buf1
        stx curr_bufp
        ldx #screen_buf2
        stx next_bufp
        clra
        staa gen_ctr
        staa gen_ctr+1
        staa gen_ctr+2
        staa gen_ctr+3
  jsr vdginit
  ldaa #greenbase
  jsr vdgfill
  jsr vdghome
  jsr vdgtitle
  jsr vdggenlbl
        jsr init_screen
loop:   jsr mirror_edges ; make it toroidal
*        jsr print_screen
        jsr printgscreen
        jsr vdggenctr
        jsr gen_update ; update the next_buf based on the game rules
        jsr inc_gen_ctr
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
* calculate neighbor counts s2 and s3
* Step 1. (xab ka) = ka + kb, (xcd kc) = kc + kd, ...
* xab = ka & kb
        ldaa ka
        anda kb
        staa xab
* ka ^= kb
        ldaa ka
        eora kb
        staa ka
* xcd = kc & kd
        ldaa kc
        anda kd
        staa xcd
* kc ^= kd
        ldaa kc
        eora kd
        staa kc
* xef = ke & kf
        ldaa ke
        anda kf
        staa xef
* ke ^= kf
        ldaa ke
        eora kf
        staa ke
* xgh = kg & kh
        ldaa kg
        anda kh
        staa xgh
* kg ^= kh
        ldaa kg
        eora kh
        staa kg
* Step 2. (kc kb ka) = (xab ka) + (xcd kc)
* kd = ka & kc
        ldaa ka
        anda kc
        staa kd
* ka ^= kc
        ldaa ka
        eora kc
        staa ka
* kc = xab & xcd
        ldaa xab
        anda xcd
        staa kc
* kb = xab ^ xcd ^ kd
        ldaa xab
        eora xcd
        eora kd
        staa kb
* Step 3. (kg kf ke) = (xef ke) + (xgh kg)
* kh = ke & kg
        ldaa ke
        anda kg
        staa kh
* ke ^= kg
        ldaa ke
        eora kg
        staa ke
* kg = xef & xgh
        ldaa xef
        anda xgh
        staa kg
* kf = xef ^ xgh ^ kh
        ldaa xef
        eora xgh
        eora kh
        staa kf
* Step 4. (kc kb ka) = (kc kb ka) + (kg kf ke)
* kd = ka & ke
        ldaa ka
        anda ke
        staa kd
* ka ^= ke
        ldaa ka
        eora ke
        staa ka
* kh = kb & kf
        ldaa kb
        anda kf
        staa kh
* kb ^= kf
        ldaa kb
        eora kf
        staa kb
* kh |= kb & kd ;; kh = (kb & kf) | ((kb ^ kf) & (ka & ke))
        ldaa kb
        anda kd
        staa temp_word
        ldaa kh
        oraa temp_word
        staa kh
* kb ^= kd
        ldaa kb
        eora kd
        staa kb
* kc ^= kg ^ kh
        ldaa kc
        eora kh
        eora kg
        staa kc
* Step 5. Calc. s2 and s3 from (kc kb ka)
* temp_word = ~kc & kb
        ldaa kc
        eora #$ff
        anda kb
        staa temp_word
* s2 = temp_word & ~ka
        ldaa ka
        eora #$ff
        anda temp_word
        staa s2
* s3 = temp_word & ka
        ldaa temp_word
        anda ka
        staa s3
* Final Step. [next_adrs] = ([curr_adrs] & s2) | s3
        ldx curr_adrs
        ldaa 0,x
        anda s2
        oraa s3
        ldx next_adrs
        staa 0,x
* increment the buf pointers and test
        ldx curr_adrs   ; inc current adrs
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
* Swap screen buffers
swap_buffer:
        ldx curr_bufp
        stx temp_word
        ldx next_bufp
        stx curr_bufp
        ldx temp_word
        stx next_bufp
        rts
*
* print VDG screen
printgscreen ldx curr_bufp ; init pointers
  stx curr_adrs
  clr curr_off
  ldx #vram_top
  stx scrloc
* draw 32x16 = 16 char x 8 char
pgs0  ldx curr_adrs
  ldaa ,X ; draw 8x2 dots (4 chars)
  ldab linebyte,X
  pshb
  psha
  ldaa #4
  staa bitpos
pgs1 tsx
  ldaa ,X
  ldab 1,X
  anda #$c0
  andb #$c0
  lsrb
  lsrb
  aba
  lsra
  lsra
  lsra
  lsra
  adda #greenbase
  ldx scrloc
  staa ,X
  inx
  stx scrloc
* shift within bytes
  tsx
  asl ,X ; accA
  asl ,X ; accA
  asl 1,X ; accB
  asl 1,X ; accB  
  dec bitpos
  bne pgs1 ; if zero the byte is done
  pula ; adjust stack
  pulb
* advance buffer adrs
  ldx curr_adrs
  inx
  stx curr_adrs
  ldaa curr_off
  inca
  staa curr_off
* check eol
  ldaa scrloc+1
  bita #$0f
  bne pgs2
  ldab scrloc
  adda #$10 ; advance scrloc by 16 chars 
  adcb #0
  staa scrloc+1
  stab scrloc
  ldx curr_adrs ; advance curr_adrs by 4 bytes = skip odd line
  inx
  inx
  inx
  inx
  stx curr_adrs
  ldaa curr_off ; advance curr_off by 4 bytes = skip odd line
  clc
  adca #linebyte
  staa curr_off
pgs2 ldaa curr_off
  cmpa #buf_len
  beq pgsq
  jmp pgs0
pgsq rts
*
fliptbl fcb 0,2,1,3
  fcb 8,$a,9,$b ; +8
  fcb 4,6,5,7 ; +4
  fcb $c,$e,$d,$f ; +c
* 
* initialize vdg hardware 
vdginit  ldaa #0
  staa vdg_ctl_ad
  rts
*
* clear screen
vdgclr ldaa #spc
* fill screen
vdgfill  ldx #vram_top
clr1  staa ,X
  inx
  cpx #vram_end
  bne clr1
  rts
*
* home cursor
vdghome ldx #vram_top
  stx scrloc
  rts
*
* print title on vdg screen
vdgtitle ldx #vram_top+256+32
  stx dstx
  ldx #titlestr
  stx savx
vdgtl1  ldaa ,X
  cmpa #4
  beq vdgtlq
  inx
  stx savx
  anda #$3f
  ldx dstx
  staa ,X
  inx
  stx dstx
  ldx savx
  bra vdgtl1
vdgtlq rts
*
titlestr fcc "CONWAY'S GAME OF LIFE"
  fcb 4
* print 'GEN" on vdg screen
vdggenlbl ldx #vram_top+256+64
  stx dstx
  ldx #genlbl
  stx savx
  bra vdgtl1
genlbl fcc "GEN: "
  fcb 4
*
* Print gen ctr on vdg screen
vdggenctr ldx #vram_top+256+64+5
  stx dstx
  ldx #gen_ctr
  ldaa ,X
  psha
  jsr vdggc1
  pula
  jsr vdggc2
  ldx #gen_ctr+1
  ldaa ,X
  psha
  jsr vdggc1
  pula
  jsr vdggc2
  ldx #gen_ctr+2
  ldaa ,X
  psha
  jsr vdggc1
  pula
  jsr vdggc2
  ldx #gen_ctr+3
  ldaa ,X
  psha
  jsr vdggc1
  pula
  jsr vdggc2
  rts
vdggc1 lsra
  lsra
  lsra
  lsra
vdggc2 anda #$0f
  adda #$30
  ldx dstx
  staa ,X
  inx
  stx dstx
  rts
*  
* work area
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
gvar equ *
scrloc equ gvar+$0
savx equ gvar+$2
curbuf equ gvar+$4
bitpos equ gvar+$5
dstx equ gvar+$6
*
  org gvar+$10
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
var:    org $0680
screen_buf1:
        rmb buf_len ; 32x16 bits = 64 bytes
screen_buf2:
        rmb buf_len
        end
