* swi.asm
*
* 6800 swi Test
* 2019 ryu10
*
* Mikbug Entries
outch   equ $e075
*
        org $0400
start:
        swi ; immediately return to Mikbug
*       end
