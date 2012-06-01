COMMENT ~
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
ณ Emulation of MATHs instructions                                          ณ
ณ                                                                          ณ
ณ       25/ 6/96  Converted all code to TASM IDEAL mode                    ณ
ณ        8/ 8/96  TAS added                                                ณ
ณ       28/ 9/96  ABCD added (pheew! must be an easier way!!!)             ณ
ณ       30/ 9/96  SBCD added                                               ณ
ณ        1/10/96  Zero DIVides fixed                                       ณ
ณ       20/12/96  Overflows fixed for DIVU/S                               ณ
ณ        9/ 2/97  Fixed a bug in CMPM                                      ณ
ณ       13/ 2/97  Fixed a bug in TAS Dx                                    ณ
ณ        6/ 3/97  NBCD                                                     ณ
ณ        9/ 3/97  Started to optimized ADD/SUB/CMP with <ea>               ณ
ณ        4/ 2/97  ABCD ok (except for flag V)                              ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
~
        IDEAL

        INCLUDE "simu68.inc"
        INCLUDE "profile.inc"

        CODESEG

        PUBLIC  Do_ABCD_Dx, Do_ABCD_Ax, Do_SBCD_Dx, Do_SBCD_Ax
        PUBLIC  Do_NBCD_Dx, Do_NBCD_Mem
        PUBLIC  Do_ADD_B_Dx_Dx, Do_ADD_W_Rx_Dx, Do_ADD_L_Rx_Dx
        PUBLIC  Do_ADD_B_Mem_Dx, Do_ADD_W_Mem_Dx, Do_ADD_L_Mem_Dx
        PUBLIC  Do_ADD_B_Dx_Mem, Do_ADD_W_Dx_Mem, Do_ADD_L_Dx_Mem
        PUBLIC  Do_SUB_B_Dx_Dx, Do_SUB_W_Rx_Dx, Do_SUB_L_Rx_Dx
        PUBLIC  Do_SUB_B_Mem_Dx, Do_SUB_W_Mem_Dx, Do_SUB_L_Mem_Dx
        PUBLIC  Do_SUB_B_Dx_Mem, Do_SUB_W_Dx_Mem, Do_SUB_L_Dx_Mem
        PUBLIC  Do_CMP_B_Dx_Dx, Do_CMP_W_Rx_Dx, Do_CMP_L_Rx_Dx
        PUBLIC  Do_CMP_B_Mem_Dx,Do_CMP_W_Mem_Dx, Do_CMP_L_Mem_Dx
        PUBLIC  Do_ADDI_B_To_Dx, Do_ADDI_W_To_Dx, Do_ADDI_L_To_Dx
        PUBLIC  Do_ADDI_B_To_Mem, Do_ADDI_W_To_Mem, Do_ADDI_L_To_Mem
        PUBLIC  Do_SUBI_B_To_Dx, Do_SUBI_W_To_Dx, Do_SUBI_L_To_Dx
        PUBLIC  Do_SUBI_B_To_Mem, Do_SUBI_W_To_Mem, Do_SUBI_L_To_Mem
        PUBLIC  Do_CMPI_B_To_Dx, Do_CMPI_W_To_Dx, Do_CMPI_L_To_Dx
        PUBLIC  Do_CMPI_B_To_Mem, Do_CMPI_W_To_Mem, Do_CMPI_L_To_Mem
        PUBLIC  Do_ADDA_W_To_Ax, Do_SUBA_W_To_Ax, Do_CMPA_W
        PUBLIC  Do_ADDA_L_To_Ax, Do_SUBA_L_To_Ax, Do_CMPA_L
        PUBLIC  Do_ADDQ_B_Dx, Do_ADDQ_W_Dx, Do_ADDQ_L_Dx
        PUBLIC  Do_ADDQ_W_Ax, Do_ADDQ_L_Ax
        PUBLIC  Do_ADDQ_B_Mem, Do_ADDQ_W_Mem, Do_ADDQ_L_Mem
        PUBLIC  Do_SUBQ_B_Dx, Do_SUBQ_W_Dx, Do_SUBQ_L_Dx
        PUBLIC  Do_SUBQ_W_Ax, Do_SUBQ_L_Ax, Do_SUBQ_B_Mem
        PUBLIC  Do_SUBQ_W_Mem, Do_SUBQ_L_Mem
        PUBLIC  Do_ADDX_B_Dx, Do_ADDX_W_Dx, Do_ADDX_L_Dx
        PUBLIC  Do_ADDX_B_Aipd, Do_ADDX_W_Aipd, Do_ADDX_L_Aipd
        PUBLIC  Do_SUBX_B_Dx, Do_SUBX_W_Dx, Do_SUBX_L_Dx
        PUBLIC  Do_SUBX_B_Aipd, Do_SUBX_W_Aipd, Do_SUBX_L_Aipd
        PUBLIC  Do_CMPM_B, Do_CMPM_W, Do_CMPM_L
        PUBLIC  Do_TST_B_Dx, Do_TST_W_Dx, Do_TST_L_Dx
        PUBLIC  Do_TST_B_Mem, Do_TST_W_Mem, Do_TST_L_Mem
        PUBLIC  Do_TST_L_Mem_addressError
        PUBLIC  Do_EXT_W, Do_EXT_L
        PUBLIC  Do_NEG_B_Dx, Do_NEG_W_Dx, Do_NEG_L_Dx
        PUBLIC  Do_NEG_B_Mem, Do_NEG_W_Mem, Do_NEG_L_Mem
        PUBLIC  Do_NEGX_B_Dx, Do_NEGX_W_Dx, Do_NEGX_L_Dx
        PUBLIC  Do_NEGX_B_Mem, Do_NEGX_W_Mem, Do_NEGX_L_Mem
        PUBLIC  Do_MULU, Do_MULS, Do_DIVU, Do_DIVS
        PUBLIC  Do_CHK_Dx, Do_CHK_mem
        PUBLIC  Do_TAS_Dx, Do_TAS_Mem


;        PUBLIC Init_Instructions_MATHS


; [fold]  (
PROC Init_Instructions_MATHS NEAR


;        call    Init_Instructions_ADDX_SUBX
;        call    Init_Instruction_ADDA
;        call    Init_Instruction_SUBA
;        call    Init_Instruction_CMPA
;        call    Init_Instruction_ADDQ
;        call    Init_Instruction_SUBQ
;        call    Init_Instruction_CMPM
;        call    Init_Instruction_TST
;        call    Init_Instruction_EXT
;        call    Init_Instructions_NEG_NEGX_NBCD
;        call    Init_Instructions_MUL_DIV
;        call    Init_Instruction_CHK
;        call    Init_Instruction_TAS
;        call    Init_Instructions_BCD
;
;        call    Init_Instructions_ADD_SUB_CMP           ;ok <ea>
;        call    Init_Instructions_ADDI_SUBI_CMPI        ;ok <ea>

        ret
        ENDP

; [fold]  )


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                  *********** MACROS DEFINITIONS ***********
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ


MACRO Set_Flags_After_ADD
        seto    [BYTE PTR ebp+base.V]
        Set_Flags_NZC
;;;;        bt      [ebp+base.NZC],0    ;;;;;;;; 2SEE ;;;;;;;;;
        setc    [BYTE PTR ebp+base.X]
        ENDM


MACRO Set_Flags_After_CMP
        seto    [BYTE PTR ebp+base.V]
        Set_Flags_NZC
        ENDM

MACRO Set_Flags_After_TST
        lahf
        and     ah,0feh
        mov     [ebp+base.V],0
        mov     [BYTE PTR ebp+base.NZC],ah
        ENDM

MACRO Set_Flags_After_ADDX     ;Z unset if non zero, ELSE REMAIN UNCHANGED!
        seto    [BYTE PTR ebp+base.V]
        lahf
        jz short     @@WasResultNull
        and     [BYTE PTR ebp+base.NZC],0bfh            ;Z=0 if  result != 0
@@WasResultNull:
        and     [BYTE PTR ebp+base.NZC],040h            ;don't modify bit Z
        and     ah,0bfh
        or      [BYTE PTR ebp+base.NZC],ah
        bt      [ebp+base.NZC],0
        setc    [BYTE PTR ebp+base.X]  ;X = C
        ENDM


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                         BCD instructions
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ


; [fold]  [
PROC Do_ABCD NEAR
        push    edi
                ; al,bl : 2 values
                ; result returned in al

;---------------------------------------- convert from 68000 BCD (al,bl)
        mov     edi,eax
        mov     edx,ebx
        and     edi,15
        and     edx,15
        and     eax,0f0h
        and     ebx,0f0h
        shr     [ebp+base.X],1
        adc     edx,edi         ;EDX = lo byte
        add     eax,ebx

        mov     ebx,[ebp+base.NZC]
        and     ebx,0c0h         ;no carry by default

        cmp     edx,9
        jbe     @@inrange
        add     edx,6
@@inrange:
        add     eax,edx
        cmp     eax,9fh
        jbe     @@noc

        inc     ebx
        mov     [ebp+base.X],1
        add     eax,060h
@@noc:
        or      al,al
        jz      @@iszero
        and     ebx,81h         ;Z=0
@@iszero:
        mov     [ebp+base.NZC],ebx
        pop     edi
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Do_SBCD NEAR
        push    edi
                ; al : source
                ; bl : destination
                ; result returned in al

;---------------------------------------- convert from 68000 BCD (al,bl)
        mov     edx,eax         ;EDX=EAX=src
        mov     edi,ebx         ;EDI=EBX=dst
        and     edx,15          ;EDX=src lo
        and     edi,15          ;EDI=dst lo
        and     eax,0f0h        ;EAX=src hi
        and     ebx,0f0h        ;EBX=dst hi
        shr     [ebp+base.X],1
        sbb     edi,edx         ;EDI= new_lo (dst_lo - src_lo - X)
        sub     ebx,eax         ;EBX= new_hi (dst_hi - src_hi)

        mov     edx,[ebp+base.NZC]
        and     edx,0c0h        ;no carry by default

        cmp     edi,9
        jbe     @@inrange       ;if new_lo > 9
        sub     edi,6           ;newlo -= 0x6
        sub     ebx,10h         ;newhi-= 0x10
@@inrange:
        and     edi,0fh
        add     edi,ebx         ;edi=newv = newhi+newlo&f

        mov     ebx,edi
        and     ebx,1f0h
        cmp     ebx,90h         ;if newhi&1f0>0x90
        jbe     @@noc

        inc     edx
        mov     [ebp+base.X],1
        sub     edi,060h
@@noc:
        mov     eax,edi
        or      al,al
        jz      @@iszero
        and     edx,81h         ;Z=0
@@iszero:
        mov     [ebp+base.NZC],edx
        pop     edi
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Do_ABCD_Dx NEAR
        mov     ebx,eax
        shr     ebx,9
        and     eax,7           ; Src register
        and     ebx,7           ; DSt register
        push    ebx
        mov     eax,[ebp+eax*4+base.D]
        mov     ebx,[ebp+ebx*4+base.D]
        call    Do_ABCD
        pop     ebx
        mov     [BYTE PTR ebp+ebx*4+base.D],al
        Next    6
        ENDP

; [fold]  ]

; [fold]  [
PROC Do_ABCD_Ax NEAR
        mov     ebx,eax
        shr     ebx,9
        and     eax,7
        and     ebx,7
        dec     [ebp+eax*4+base.A]
        dec     [ebp+ebx*4+base.A]
        mov     edi,[ebp+eax*4+base.A]
        Read_B
        mov     edi,[ebp+ebx*4+base.A]
        mov     bl,dl
        Read_B
        mov     al,dl
        call    Do_ABCD
        mov     dl,al
        Write_B
        Next    18
        ENDP

; [fold]  ]

; [fold]  [
PROC Do_SBCD_Dx NEAR
        mov     ebx,eax
        shr     ebx,9
        and     eax,7           ; Src register
        and     ebx,7           ; DSt register
        push    ebx
        mov     eax,[ebp+eax*4+base.D]
        mov     ebx,[ebp+ebx*4+base.D]
        call    Do_SBCD
        pop     ebx
        mov     [BYTE PTR ebp+ebx*4+base.D],al
        Next    6
        ENDP

; [fold]  ]

; [fold]  [
PROC Do_SBCD_Ax NEAR
        mov     ebx,eax
        shr     ebx,9
        and     eax,7
        and     ebx,7
        dec     [ebp+eax*4+base.A]
        dec     [ebp+ebx*4+base.A]
        mov     edi,[ebp+eax*4+base.A]
        Read_B
        mov     edi,[ebp+ebx*4+base.A]
        mov     bl,dl
        Read_B
        mov     al,dl
        call    Do_SBCD
        mov     dl,al
        Write_B
        Next    18
        ENDP

; [fold]  ]

PROC Do_NBCD_Dx NEAR
        and     eax,7
        push    eax
        mov     eax,[ebp+eax*4+base.D]  ; Dst
        mov     ebx,0           ; Src
        xchg    eax,ebx
        call    Do_SBCD
        pop     ebx
        mov     [BYTE PTR ebp+ebx*4+base.D],al
        Next    6
        ENDP


PROC Do_NBCD_Mem NEAR
        Instr_To_EA_B
        push    edi
        Read_B
        mov     eax,edx         ; Dst
        mov     ebx,0           ; Src
        xchg    eax,ebx
        call    Do_SBCD
        pop     edi
        mov     edx,eax
        Write_B
        Next    8
        ENDP

;
;        DATASEG
;
;Table_Nbcd:
;        db      09bh, 09ch, 09dh, 09eh, 09fh, 0a0h, 0a1h, 0a2h
;        db      0a3h, 0a4h, 0a5h, 0a6h, 0a7h, 0a8h, 0a9h, 0b0h
;        db      0abh, 0ach, 0adh, 0aeh, 0afh, 0b0h, 0b1h, 0b2h
;        db      0b3h, 0b4h, 0b5h, 0b6h, 0b7h, 0b8h, 0b9h, 0c0h
;
;        db      0bbh, 0bch, 0bdh, 0beh, 0bfh, 0c0h, 0c1h, 0c2h
;        db      0c3h, 0c4h, 0c5h, 0c6h, 0c7h, 0c8h, 0c9h, 0d0h
;        db      0cbh, 0cch, 0cdh, 0ceh, 0cfh, 0d0h, 0d1h, 0d2h
;        db      0d3h, 0d4h, 0d5h, 0d6h, 0d7h, 0d8h, 0d9h, 0e0h
;
;        db      0dbh, 0dch, 0ddh, 0deh, 0dfh, 0e0h, 0e1h, 0e2h
;        db      0e3h, 0e4h, 0e5h, 0e6h, 0e7h, 0e8h, 0e9h, 0f0h
;        db      0ebh, 0ech, 0edh, 0eeh, 0efh, 0f0h, 0f1h, 0f2h
;        db      0f3h, 0f4h, 0f5h, 0f6h, 0f7h, 0f8h, 0f9h, 000h
;
;        db      0fbh, 0fch, 0fdh, 0feh, 0ffh, 000h, 001h, 002h
;        db      003h, 004h, 005h, 006h, 007h, 008h, 009h, 010h
;        db      00bh, 00ch, 00dh, 00eh, 00fh, 010h, 011h, 012h
;        db      013h, 014h, 015h, 016h, 017h, 018h, 019h, 020h
;
;        db      01bh, 01ch, 01dh, 01eh, 01fh, 020h, 021h, 022h
;        db      023h, 024h, 025h, 026h, 027h, 028h, 029h, 030h
;        db      02bh, 02ch, 02dh, 02eh, 02fh, 030h, 031h, 032h
;        db      033h, 034h, 035h, 036h, 037h, 038h, 039h, 040h
;
;        db      03bh, 03ch, 03dh, 03eh, 03fh, 040h, 041h, 042h
;        db      043h, 044h, 045h, 046h, 047h, 048h, 049h, 050h
;        db      04bh, 04ch, 04dh, 04eh, 04fh, 050h, 051h, 052h
;        db      053h, 054h, 055h, 056h, 057h, 058h, 059h, 060h
;
;        db      05bh, 05ch, 05dh, 05eh, 05fh, 060h, 061h, 062h
;        db      063h, 064h, 065h, 066h, 067h, 068h, 069h, 070h
;        db      06bh, 06ch, 06dh, 06eh, 06fh, 070h, 071h, 072h
;        db      073h, 074h, 075h, 076h, 077h, 078h, 079h, 080h
;
;        db      07bh, 07ch, 07dh, 07eh, 07fh, 080h, 081h, 082h
;        db      083h, 084h, 085h, 086h, 087h, 088h, 089h, 090h
;        db      08bh, 08ch, 08dh, 08eh, 08fh, 090h, 091h, 092h
;        db      093h, 094h, 095h, 096h, 097h, 098h, 099h, 000h




        CODESEG


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      ADD
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_ADD_B_Dx_Dx:
        mov     ecx,eax
        shr     eax,9
        and     ecx,7
        and     eax,7
        mov     edx,[ebp+ecx*4+base.D]  ;source: Dx or Ax
        add     [BYTE PTR ebp+eax*4+base.D],dl
        Set_Flags_After_ADD
        Next    4


Do_ADD_W_Rx_Dx:
        mov     ecx,eax
        shr     eax,9
        and     ecx,15
        and     eax,7
        mov     edx,[ebp+ecx*4+base.D]  ;source: Dx or Ax
        add     [WORD PTR ebp+eax*4+base.D],dx
        Set_Flags_After_ADD
        Next    4

Do_ADD_L_Rx_Dx:
        mov     ecx,eax
        shr     eax,9
        and     ecx,15
        and     eax,7
        mov     edx,[ebp+ecx*4+base.D]  ;source: Dx or Ax
        add     [ebp+eax*4+base.D],edx
        Set_Flags_After_Add
        Next    6

Do_ADD_B_Mem_Dx:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_B
        and     ecx,7
        Read_B
        add     [BYTE PTR ebp+ecx*4+base.D],dl
        Set_Flags_After_ADD
        Next    4

Do_ADD_W_Mem_Dx:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_W
        and     ecx,7
        Read_W
        add     [WORD PTR ebp+ecx*4+base.D],dx
        Set_Flags_After_ADD
        Next    4

Do_ADD_L_Mem_Dx:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_L
        and     ecx,7
        Read_L
        add     [ebp+ecx*4+base.D],edx
        Set_Flags_After_ADD
        Next    6

Do_ADD_B_Dx_Mem:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_B
        and     ecx,7
        Read_B
        add     dl,[BYTE PTR ebp+ecx*4+base.D]
        Set_Flags_After_ADD
        Write_B
        Next    8

Do_ADD_W_Dx_Mem:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_W
        and     ecx,7
        Read_W
        add     dx,[WORD PTR ebp+ecx*4+base.D]
        Set_Flags_After_ADD
        Write_W
        Next    8

Do_ADD_L_Dx_Mem:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_L
        and     ecx,7
        Read_L
        add     edx,[ebp+ecx*4+base.D]
        Set_Flags_After_ADD
        Write_L
        Next    12


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      SUB
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_SUB_B_Dx_Dx:
        mov     ecx,eax
        shr     eax,9
        and     ecx,7
        and     eax,7
        mov     edx,[ebp+ecx*4+base.D]  ;source: Dx or Ax
        sub     [BYTE PTR ebp+eax*4+base.D],dl
        Set_Flags_After_ADD
        Next    4

Do_SUB_W_Rx_Dx:
        mov     ecx,eax
        shr     eax,9
        and     ecx,15
        and     eax,7
        mov     edx,[ebp+ecx*4+base.D]  ;source: Dx or Ax
        sub     [WORD PTR ebp+eax*4+base.D],dx
        Set_Flags_After_ADD
        Next    4

Do_SUB_L_Rx_Dx:
        mov     ecx,eax
        shr     eax,9
        and     ecx,15
        and     eax,7
        mov     edx,[ebp+ecx*4+base.D]  ;source: Dx or Ax
        sub     [ebp+eax*4+base.D],edx
        Set_Flags_After_Add
        Next    6

Do_SUB_B_Mem_Dx:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_B
        and     ecx,7
        Read_B
        sub     [BYTE PTR ebp+ecx*4+base.D],dl
        Set_Flags_After_ADD
        Next    4

Do_SUB_W_Mem_Dx:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_W
        and     ecx,7
        Read_W
        sub     [WORD PTR ebp+ecx*4+base.D],dx
        Set_Flags_After_ADD
        Next    4

Do_SUB_L_Mem_Dx:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_L
        and     ecx,7
        Read_L
        sub     [ebp+ecx*4+base.D],edx
        Set_Flags_After_ADD
        Next    6

Do_SUB_B_Dx_Mem:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_B
        and     ecx,7
        Read_B
        sub     dl,[BYTE PTR ebp+ecx*4+base.D]
        Set_Flags_After_ADD
        Write_B
        Next    8

Do_SUB_W_Dx_Mem:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_W
        and     ecx,7
        Read_W
        sub     dx,[WORD PTR ebp+ecx*4+base.D]
        Set_Flags_After_ADD
        Write_W
        Next    8

Do_SUB_L_Dx_Mem:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_L
        and     ecx,7
        Read_L
        sub     edx,[ebp+ecx*4+base.D]
        Set_Flags_After_ADD
        Write_L
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      CMP
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_CMP_B_Dx_Dx:
        mov     ecx,eax
        shr     eax,9
        and     ecx,7
        and     eax,7
        mov     edx,[ebp+ecx*4+base.D]  ;source: Dx or Ax
        cmp     [BYTE PTR ebp+eax*4+base.D],dl
        Set_Flags_After_CMP
        Next    4

Do_CMP_W_Rx_Dx:
        mov     ecx,eax
        shr     eax,9
        and     ecx,15
        and     eax,7
        mov     edx,[ebp+ecx*4+base.D]  ;source: Dx or Ax
        cmp     [WORD PTR ebp+eax*4+base.D],dx
        Set_Flags_After_CMP
        Next    4

Do_CMP_L_Rx_Dx:
        mov     ecx,eax
        shr     eax,9
        and     ecx,15
        and     eax,7
        mov     edx,[ebp+ecx*4+base.D]  ;source: Dx or Ax
        cmp     [ebp+eax*4+base.D],edx
        Set_Flags_After_CMP
        Next    6

Do_CMP_B_Mem_Dx:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_B
        and     ecx,7
        Read_B
        cmp     [BYTE PTR ebp+ecx*4+base.D],dl
        Set_Flags_After_CMP
        Next    4

Do_CMP_W_Mem_Dx:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_W
        and     ecx,7
        Read_W
        cmp     [WORD PTR ebp+ecx*4+base.D],dx
        Set_Flags_After_CMP
        Next    4

Do_CMP_L_Mem_Dx:
        mov     ecx,eax
        shr     ecx,9
        Instr_To_EA_L
        and     ecx,7
        Read_L
        cmp     [ebp+ecx*4+base.D],edx
        Set_Flags_After_CMP
        Next    6


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                     ADDI
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_ADDI_B_To_Dx:
        mov     dl,[es:esi+1]
        and     eax,7
        add     esi,2
        add     [BYTE PTR ebp+eax*4+base.D],dl
        Set_Flags_After_ADD
        Next    8

Do_ADDI_W_To_Dx:
        mov     dx,[es:esi]
        and     eax,7
        rol     dx,8
        add     esi,2
        add     [WORD PTR ebp+eax*4+base.D],dx
        Set_Flags_After_ADD
        Next    8

Do_ADDI_L_To_Dx:
        mov     edx,[es:esi]
        and     eax,7
        bswap   edx
        add     esi,4
        add     [ebp+eax*4+base.D],edx
        Set_Flags_After_ADD
        Next    16


Do_ADDI_B_To_Mem:
        mov     cl,[es:esi+1]
        add     esi,2
        Instr_To_EA_B
        Read_B
        add     dl,cl
        Set_Flags_After_ADD
        Write_B
        Next 12

Do_ADDI_W_To_Mem:
        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        Instr_To_EA_W
        Read_W
        add     dx,cx
        Set_Flags_After_ADD
        Write_W
        Next 12

Do_ADDI_L_To_Mem:
        mov     ecx,[es:esi]
        add     esi,4
        bswap   ecx
        Instr_To_EA_L
        Read_L
        add     edx,ecx
        Set_Flags_After_ADD
        Write_L
        Next 20

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                     SUBI
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_SUBI_B_To_Dx:
        mov     dl,[es:esi+1]
        and     eax,7
        add     esi,2
        sub    [BYTE PTR ebp+eax*4+base.D],dl
        Set_Flags_After_ADD
        Next    8

Do_SUBI_W_To_Dx:
        mov     dx,[es:esi]
        and     eax,7
        rol     dx,8
        add     esi,2
        sub     [WORD PTR ebp+eax*4+base.D],dx
        Set_Flags_After_ADD
        Next    8

Do_SUBI_L_To_Dx:
        mov     edx,[es:esi]
        and     eax,7
        bswap   edx
        add     esi,4
        sub     [ebp+eax*4+base.D],edx
        Set_Flags_After_ADD
        Next    16


Do_SUBI_B_To_Mem:
        mov     cl,[es:esi+1]
        add     esi,2
        Instr_To_EA_B
        Read_B
        sub     dl,cl
        Set_Flags_After_ADD
        Write_B
        Next 12

Do_SUBI_W_To_Mem:
        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        Instr_To_EA_W
        Read_W
        sub     dx,cx
        Set_Flags_After_ADD
        Write_W
        Next 12

Do_SUBI_L_To_Mem:
        mov     ecx,[es:esi]
        add     esi,4
        bswap   ecx
        Instr_To_EA_L
        Read_L
        sub     edx,ecx
        Set_Flags_After_ADD
        Write_L
        Next 20


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                     CMPI
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ


Do_CMPI_B_To_Dx:
        mov     dl,[es:esi+1]
        and     eax,7
        add     esi,2
        cmp     [BYTE PTR ebp+eax*4+base.D],dl
        Set_Flags_After_CMP
        Next    8

Do_CMPI_W_To_Dx:
        mov     dx,[es:esi]
        and     eax,7
        rol     dx,8
        add     esi,2
        cmp     [WORD PTR ebp+eax*4+base.D],dx
        Set_Flags_After_CMP
        Next    8

Do_CMPI_L_To_Dx:
        mov     edx,[es:esi]
        and     eax,7
        bswap   edx
        add     esi,4
        cmp     [ebp+eax*4+base.D],edx
        Set_Flags_After_CMP
        Next    14


Do_CMPI_B_To_Mem:
        mov     cl,[es:esi+1]
        add     esi,2
        Instr_To_EA_B
        Read_B
        cmp     dl,cl
        Set_Flags_After_CMP
        Next 8

Do_CMPI_W_To_Mem:
        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        Instr_To_EA_W
        Read_W
        cmp     dx,cx
        Set_Flags_After_CMP
        Next 8

Do_CMPI_L_To_Mem:
        mov     ecx,[es:esi]
        add     esi,4
        bswap   ecx
        Instr_To_EA_L
        Read_L
        cmp     edx,ecx
        Set_Flags_After_CMP
        Next 12


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                     ADDA.W SUBA.W CMPA.W
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
PROC Do_ADDA_W_To_Ax NEAR
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        test    eax,30h
        jnz     @@mem
        and     eax,15
        mov     dx,[WORD PTR ebp+eax*4+base.D]
        jmp     @@reg
@@mem:
        Instr_To_EA_W
        Read_W
@@reg:
        movsx   edx,dx
        add     [ebp+ecx*4+base.A],edx
        Next    8
        ENDP

; [fold]  ]

; [fold]  [
PROC Do_SUBA_W_To_Ax NEAR
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        test    eax,30h
        jnz     @@mem
        and     eax,15
        mov     dx,[WORD PTR ebp+eax*4+base.D]
        jmp     @@reg
@@mem:
        Instr_To_EA_W
        Read_W
@@reg:
        movsx   edx,dx
        sub     [ebp+ecx*4+base.A],edx
        Next    8

        ENDP

; [fold]  ]

; [fold]  (
Do_CMPA_W:
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        test    eax,30h
        jnz     @@mem
        and     eax,15
        mov     dx,[WORD PTR ebp+eax*4+base.D]
        jmp     @@reg
@@mem:
        Instr_To_EA_W
        Read_W
@@reg:
        movsx   edx,dx
;        cmp     [ebp+ecx*4+base.A],edx
        mov     eax,[ebp+ecx*4+base.A]
        sub     eax,edx
        Set_Flags_After_CMP
        Next    8

;        mov     ecx,eax
;        Instr_To_EA_W
;        shr     ecx,9
;
;        or      ebx,ebx
;        jnz     short @@mem
;        movsx   edx,[WORD PTR edi]
;        jmp     short @@co
;@@mem:
;        Read_W
;        movsx   edx,dx
;@@co:
;        and     ecx,7
;        mov     eax,[ebp+ecx*4+base.A]
;        sub     eax,edx                 ;CMP SUBA; CCR remains unchanged
;        Set_Flags_After_CMP
        Next    8

; [fold]  )

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                     ADDA.L SUBA.L CMPA.L
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
PROC Do_ADDA_L_To_Ax NEAR

        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        test    eax,30h
        jnz     @@mem
        and     eax,15
        mov     edx,[ebp+eax*4+base.D]
        jmp     @@reg
@@mem:
        Instr_To_EA_L
        Read_L
@@reg:
        add     [ebp+ecx*4+base.A],edx
        Next    6
        ENDP

; [fold]  ]

; [fold]  [
PROC Do_SUBA_L_To_Ax NEAR
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        test    eax,30h
        jnz     @@mem
        and     eax,15
        mov     edx,[ebp+eax*4+base.D]
        jmp     @@reg
@@mem:
        Instr_To_EA_L
        Read_L
@@reg:
        sub     [ebp+ecx*4+base.A],edx
        Next    6
ENDP

; [fold]  ]

; [fold]  [
PROC Do_CMPA_L NEAR
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        test    eax,30h
        jnz     @@mem
        and     eax,15
        mov     edx,[ebp+eax*4+base.D]
        jmp     @@reg
@@mem:
        Instr_To_EA_L
        Read_L
@@reg:
        mov     eax,[ebp+ecx*4+base.A]
;        cmp     [ebp+ecx*4+base.A],edx
        sub     eax,edx
        Set_Flags_After_CMP
        Next    6
        ENDP

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                ADDQ SUBQ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_ADDQ_B_Dx:
        prof    _ADDQ_B_Dx
        mov     ebx,eax
        shr     eax,9
        and     ebx,7                                   ;Dx reg
        and     eax,7
        jnz     @@Pas0
        mov     eax,8
@@Pas0:
        add     [BYTE PTR ebp+ebx*4+base.D],al
        Set_Flags_After_ADD
        Next    4

; [fold]  ]

; [fold]  [
Do_ADDQ_W_Dx:
        prof    _ADDQ_W_Dx
        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        jnz     @@Pas0
        mov     eax,8
@@Pas0:
        add     [WORD PTR ebp+ebx*4+base.D],ax
        Set_Flags_After_ADD
        Next    4

; [fold]  ]

; [fold]  [
Do_ADDQ_L_Dx:
        prof    _ADDQ_L_Dx

        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        jnz     @@Pas0
        mov     eax,8
@@Pas0:
        add     [ebp+ebx*4+base.D],eax
        Set_Flags_After_ADD
        Next    8

; [fold]  ]

; [fold]  [
Do_ADDQ_W_Ax:                   ; idem ADDQ.L #x,Ax
        prof    _ADDQ_W_Ax
        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        jnz     @@Pas0
        mov     eax,8
@@Pas0: add     [ebp+ebx*4+base.A],eax
        Next    8

; [fold]  ]

; [fold]  [
Do_ADDQ_L_Ax:
        prof    _ADDQ_L_Ax
        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        jnz     @@Pas0
        mov     eax,8
@@Pas0: add     [ebp+ebx*4+base.A],eax
        Next    8

; [fold]  ]

; [fold]  [
Do_ADDQ_B_Mem:
        prof    _ADDQ_B_Mem
        mov     ecx,eax
        Instr_To_EA_B
        shr     ecx,9
        and     ecx,7
        jnz     @@Pas0
        mov     ecx,8
@@Pas0:
        ReRead_B nodirect1
        add     [edi],cl
        Set_Flags_After_ADD
        Next    8
nodirect1:
        add     dl,cl
        Set_Flags_After_ADD
        Write_B
        Next    8

; [fold]  ]

; [fold]  [
Do_ADDQ_W_Mem:
        prof    _ADDQ_W_mem
        mov     ecx,eax
        Instr_To_EA_W
        shr     ecx,9
        and     ecx,7
        jnz     @@Pas0
        mov     ecx,8
@@Pas0:
        ReRead_W nodirect2
        mov     dx,[edi]
        rol     dx,8
        add     dx,cx
        Set_Flags_After_ADD
        rol     dx,8
        mov     [edi],dx
        Next    8

nodirect2:
        add     dx,cx
        Set_Flags_After_ADD
        Write_W
        Next    8

; [fold]  ]

; [fold]  [
Do_ADDQ_L_Mem:
        prof    _ADDQ_L_mem
        mov     ecx,eax
        Instr_To_EA_L
        shr     ecx,9
        and     ecx,7
        jnz     @@Pas0
        mov     ecx,8
@@Pas0:
        ReRead_L nodirect3
        mov     edx,[edi]
        bswap   edx
        add     edx,ecx
        Set_Flags_After_ADD
        bswap   edx
        mov     [edi],edx
        Next    12
nodirect3:
        add     edx,ecx
        Set_Flags_After_ADD
        Write_L
        Next    12

; [fold]  ]

; [fold]  [
Do_SUBQ_B_Dx:
        prof    _SUBQ_B_Dx
        mov     ebx,eax
        shr     eax,9
        and     ebx,7                                   ;Dx reg
        and     eax,7
        jnz     @@Pas0
        mov     eax,8
@@Pas0:
        sub     [BYTE PTR ebp+ebx*4+base.D],al
        Set_Flags_After_ADD
        Next    4

; [fold]  ]

; [fold]  [
Do_SUBQ_W_Dx:
        prof    _SUBQ_W_Dx
        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        jnz     @@Pas0
        mov     eax,8
@@Pas0:
        sub     [WORD PTR ebp+ebx*4+base.D],ax
        Set_Flags_After_ADD
        Next    4

; [fold]  ]

; [fold]  [
Do_SUBQ_L_Dx:
        prof    _SUBQ_L_Dx
        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        jnz     @@Pas0
        mov     eax,8
@@Pas0:
        sub     [ebp+ebx*4+base.D],eax
        Set_Flags_After_ADD
        Next    8

; [fold]  ]

; [fold]  [
Do_SUBQ_W_Ax:
        prof    _SUBQ_W_Ax
        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        jnz     @@Pas0
        mov     eax,8
@@Pas0: sub     [ebp+ebx*4+base.A],eax
        Next    8

; [fold]  ]

; [fold]  [
Do_SUBQ_L_Ax:
        prof    _SUBQ_L_Ax
        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        jnz     @@Pas0
        mov     eax,8
@@Pas0: sub     [ebp+ebx*4+base.A],eax
        Next    8

; [fold]  ]

; [fold]  [
Do_SUBQ_B_Mem:
        prof    _SUBQ_B_Mem
        mov     ecx,eax
        Instr_To_EA_B
        shr     ecx,9
        and     ecx,7
        jnz     @@Pas0
        mov     ecx,8
@@Pas0:
        ReRead_B nodirect4
        sub     [edi],cl
        Set_Flags_After_ADD
        Next    8
nodirect4:
        sub     dl,cl
        Set_Flags_After_ADD
        Write_B
        Next    8

; [fold]  ]

; [fold]  [
Do_SUBQ_W_Mem:
        prof    _SUBQ_W_Mem

        mov     ecx,eax
        Instr_To_EA_W
        shr     ecx,9
        and     ecx,7
        jnz     @@Pas0
        mov     ecx,8
@@Pas0:
        ReRead_W nodirect5
        mov     dx,[edi]
        rol     dx,8
        sub     dx,cx
        Set_Flags_After_ADD
        rol     dx,8
        mov     [edi],dx
        Next    8
nodirect5:
        sub     dx,cx
        Set_Flags_After_ADD
        Write_W
        Next    8

; [fold]  ]

; [fold]  [
Do_SUBQ_L_Mem:
        prof    _SUBQ_L_Mem

        mov     ecx,eax
        Instr_To_EA_L
        shr     ecx,9
        and     ecx,7
        jnz     @@Pas0
        mov     ecx,8
@@Pas0:
        ReRead_L nodirect6
        mov     edx,[edi]
        bswap   edx
        sub     edx,ecx
        Set_Flags_After_ADD
        bswap   edx
        mov     [edi],edx
        Next    12
nodirect6:
        sub     edx,ecx
        Set_Flags_After_ADD
        Write_L
        Next    12


; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                ADDX SUBX
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_ADDX_B_Dx:
        prof    _ADDX_B_Dx
        mov     ebx,eax
        mov     ecx,eax
        shr     ecx,9
        and     ebx,7                   ;EBX = Ry (source)
        and     ecx,7                   ;ECX = Rx (destination)

        mov     dl,[BYTE PTR ebp+ebx*4+base.D]
        shr     [BYTE PTR ebp+base.X],1
        adc     [BYTE PTR ebp+ecx*4+base.D],dl
        Set_Flags_After_ADDX
        Next    4

; [fold]  ]

; [fold]  [
Do_ADDX_W_Dx:
        prof    _ADDX_W_Dx
        mov     ebx,eax
        mov     ecx,eax
        shr     ecx,9
        and     ebx,7
        and     ecx,7

        mov     dx,[WORD PTR ebp+ebx*4+base.D]
        shr     [BYTE PTR ebp+base.X],1
        adc     [WORD PTR ebp+ecx*4+base.D],dx
        Set_Flags_After_ADDX
        Next    4

; [fold]  ]

; [fold]  [
Do_ADDX_L_Dx:
        prof    _ADDX_L_Dx

        mov     ebx,eax
        mov     ecx,eax
        shr     ecx,9
        and     ebx,7
        and     ecx,7

        mov     edx,[ebp+ebx*4+base.D]
        shr     [BYTE PTR ebp+base.X],1
        adc     [ebp+ecx*4+base.D],edx

        Set_Flags_After_ADDX
        Next    8

; [fold]  ]

; [fold]  [
Do_ADDX_B_Aipd:
        prof    _ADDX_B_Aipd

        mov     ebx,eax
        mov     ecx,eax
        shr     ecx,9
        and     ebx,7
        and     ecx,7

        dec     [ebp+ebx*4+base.A]
        dec     [ebp+ecx*4+base.A]
        mov     edi,[ebp+ebx*4+base.A]          ;source
        Read_B
dummty0:
        mov     bl,dl
        mov     edi,[ebp+ecx*4+base.A]          ;destination
        Read_B
        shr     [BYTE PTR ebp+base.X],1

        adc     dl,bl
        Set_Flags_After_ADDX
        Write_B
        Next    18

; [fold]  ]

; [fold]  [
Do_ADDX_W_Aipd:
        prof    _ADDX_W_Aipd
        mov     ebx,eax
        mov     ecx,eax
        shr     ecx,9
        and     ebx,7
        and     ecx,7

        sub     [ebp+ebx*4+base.A],2
        sub     [ebp+ecx*4+base.A],2
        mov     edi,[ebp+ebx*4+base.A]          ;source
        Read_W
        mov     bx,dx
dummy9:
        mov     edi,[ebp+ecx*4+base.A]          ;destination
        Read_W
        shr     [BYTE PTR ebp+base.X],1

        adc     dx,bx
        Set_Flags_After_ADDX
        Write_W

        Next    18

; [fold]  ]

; [fold]  [
Do_ADDX_L_Aipd:
        prof    _ADDX_L_Aipd

        mov     ebx,eax
        mov     ecx,eax
        shr     ecx,9
        and     ebx,7
        and     ecx,7

        sub     [ebp+ebx*4+base.A],4
        sub     [ebp+ecx*4+base.A],4
        mov     edi,[ebp+ebx*4+base.A]          ;source
        Read_L
dummy8:
        mov     ebx,edx
        mov     edi,[ebp+ecx*4+base.A]          ;destination
        Read_L
        shr     [BYTE PTR ebp+base.X],1
        adc     edx,ebx
        Set_Flags_After_ADDX
        Write_L
        Next    30

; [fold]  ]

; [fold]  [
Do_SUBX_B_Dx:
        prof    _SUBX_B_Dx
        mov     ebx,eax
        mov     ecx,eax
        shr     ecx,9
        and     ebx,7                   ;EBX = Ry (source)
        and     ecx,7                   ;ECX = Rx (destination)

        mov     dl,[BYTE PTR ebp+ebx*4+base.D]
        shr     [BYTE PTR ebp+base.X],1
        sbb     [BYTE PTR ebp+ecx*4+base.D],dl

        Set_Flags_After_ADDX
        Next    4

; [fold]  ]

; [fold]  [
Do_SUBX_W_Dx:
        prof    _SUBX_W_Dx
        mov     ebx,eax
        mov     ecx,eax
        shr     ecx,9
        and     ebx,7
        and     ecx,7

        mov     dx,[WORD PTR ebp+ebx*4+base.D]
        shr     [BYTE PTR ebp+base.X],1
        sbb     [WORD PTR ebp+ecx*4+base.D],dx

        Set_Flags_After_ADDX
        Next    4

; [fold]  ]

; [fold]  [
Do_SUBX_L_Dx:
        prof    _SUBX_L_Dx
        mov     ebx,eax
        mov     ecx,eax
        shr     ecx,9
        and     ebx,7
        and     ecx,7

        mov     edx,[ebp+ebx*4+base.D]
        shr     [BYTE PTR ebp+base.X],1
        sbb     [ebp+ecx*4+base.D],edx

        Set_Flags_After_ADDX
        Next    8

; [fold]  ]

; [fold]  [
Do_SUBX_B_Aipd:
        prof    _SUBX_B_Aipd

        mov     ebx,eax
        mov     ecx,eax
        shr     ecx,9
        and     ebx,7
        and     ecx,7

        dec     [ebp+ebx*4+base.A]
        dec     [ebp+ecx*4+base.A]
        mov     edi,[ebp+ebx*4+base.A]          ;source
        Read_B
dummy1:
        mov     bl,dl
        mov     edi,[ebp+ecx*4+base.A]          ;destination
        Read_B
        shr     [BYTE PTR ebp+base.X],1
        sbb     dl,bl
        Set_Flags_After_ADDX
        Write_B

        Next    18

; [fold]  ]

; [fold]  [
Do_SUBX_W_Aipd:
        prof    _SUBX_W_Aipd

        mov     ebx,eax
        mov     ecx,eax
        shr     ecx,9
        and     ebx,7
        and     ecx,7

        sub     [ebp+ebx*4+base.A],2
        sub     [ebp+ecx*4+base.A],2
        mov     edi,[ebp+ebx*4+base.A]          ;source
        Read_W
dummy2:
        mov     bx,dx
        mov     edi,[ebp+ecx*4+base.A]          ;destination
        Read_W
        shr     [BYTE PTR ebp+base.X],1
        adc     dx,bx
        Set_Flags_After_ADDX
        Write_W
        Next    18

; [fold]  ]

; [fold]  (
Do_SUBX_L_Aipd:
        prof    _SUBX_L_Aipd

        mov     ebx,eax
        mov     ecx,eax
        shr     ecx,9
        and     ebx,7
        and     ecx,7

        sub     [ebp+ebx*4+base.A],4
        sub     [ebp+ecx*4+base.A],4
        mov     edi,[ebp+ebx*4+base.A]          ;source
        Read_L
        mov     ebx,edx
        mov     edi,[ebp+ecx*4+base.A]          ;destination
dummy4:
        Read_L
        shr     [BYTE PTR ebp+base.X],1
        adc     edx,ebx
        Set_Flags_After_ADDX
        Write_L
        Next    30

; [fold]  )


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                     CMPM
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_CMPM_B:
        prof    _CMPM_B
        mov     ebx,eax                         ;ebx = Ax (destination)
        mov     ecx,eax                         ;ecx = Ay (source)
        shr     ebx,9
        and     ebx,7
        and     ecx,7

        mov     edi,[ebp+ecx*4+base.A]
        inc     [ebp+ecx*4+base.A]
        Read_B
dummy6:
        mov     al,dl                           ;al=destination
        mov     edi,[ebp+ebx*4+base.A]
        inc     [ebp+ebx*4+base.A]
        Read_B
        sub     dl,al
        Set_Flags_After_CMP
        Next    12

; [fold]  ]

; [fold]  [
Do_CMPM_W:
        prof    _CMPM_W
        mov     ebx,eax                         ;ebx = Ax (destination)
        mov     ecx,eax                         ;ecx = Ay (source)
        shr     ebx,9
        and     ebx,7
        and     ecx,7

;        mov     edi,[ebp+ebx*4+base.A]
;        add     [ebp+ebx*4+base.A],2
        mov     edi,[ebp+ecx*4+base.A]
        add     [ebp+ecx*4+base.A],2
        Read_W
dummy5:
        mov     ax,dx                           ;ad=source
;        mov     edi,[ebp+ecx*4+base.A]
;        add     [ebp+ecx*4+base.A],2
        mov     edi,[ebp+ebx*4+base.A]
        add     [ebp+ebx*4+base.A],2
        Read_W
        sub     dx,ax
        Set_Flags_After_CMP

        Next    12

; [fold]  ]

; [fold]  [
Do_CMPM_L:
        prof    _CMPM_L

        mov     ebx,eax                         ;ebx = Ax (destination)
        mov     ecx,eax                         ;ecx = Ay (source)
        shr     ebx,9
        and     ebx,7
        and     ecx,7

        mov     edi,[ebp+ecx*4+base.A]
        add     [ebp+ecx*4+base.A],4
        Read_L
        mov     eax,edx
        mov     edi,[ebp+ebx*4+base.A]
        add     [ebp+ebx*4+base.A],4
dummy7:
        Read_L
        sub     edx,eax
        Set_Flags_After_CMP
        Next    20

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      TST
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_TST_B_Dx:
        and     eax,7
        mov     dl,[BYTE PTR ebp+eax*4+base.D]
        or      dl,dl
        Set_Flags_After_TST
        Next    4

; [fold]  ]

; [fold]  [
Do_TST_W_Dx:
        and     eax,7
        mov     dx, [WORD PTR ebp+eax*4+base.D]
        or      dx,dx
        Set_Flags_After_TST
        Next    4

; [fold]  ]

; [fold]  [
Do_TST_L_Dx:
        and     eax,7
        mov     edx,[ebp+eax*4+base.D]
        or      edx,edx
        Set_Flags_After_TST
        Next    4

; [fold]  ]

; [fold]  [
Do_TST_B_Mem:
        prof    _TST_B_Mem

        Instr_To_EA_B
        Read_B
        or      dl,dl

        Set_Flags_After_TST
        Next    4

; [fold]  ]

; [fold]  [
Do_TST_W_Mem:
        prof    _TST_W_Mem
        Instr_To_EA_W
        Read_W
        or      dx,dx
        Set_Flags_After_TST
        Next    4

; [fold]  ]

; [fold]  (
Do_TST_L_Mem:
        prof    _TST_L_Mem

        Instr_To_EA_L
        Read_L
        or      edx,edx

        Set_Flags_After_TST
        Next    4

; [fold]  )

Do_TST_L_Mem_addressError:      ;opcode 4a99: TST.L (A1)+
        ;OPCODE 4A99 BIG DEMO Triggers address error with TST.L (A1)+

        Instr_To_EA_L
        mov     eax,edi
        shr     eax,1
        jnc     @@noodd
        jmp     Trigger_AdressError
@@noodd:
        Read_L
        or      edx,edx
        Set_Flags_After_TST
        Next    4


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      EXT
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_EXT_W:
        prof    _EXT_W
        and     eax,7
        movsx   dx,[BYTE PTR ebp+eax*4+base.D]
        mov     [WORD PTR ebp+eax*4+base.D],dx
        or      dx,dx
        Set_Flags_After_TST
        Next    4

; [fold]  ]

; [fold]  [
Do_EXT_L:
        prof    _EXT_L
        and     eax,7
        movsx   edx,[WORD PTR ebp+eax*4+base.D]
        mov     [ebp+eax*4+base.D],edx
        or      edx,edx
        Set_Flags_After_TST
        Next    4

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      NEG
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_NEG_B_Dx:
        prof    _NEG_B_Dx
        and     eax,7
        mov     dl,[BYTE PTR ebp+eax*4+base.D]
        neg     dl
        mov     [BYTE PTR ebp+eax*4+base.D],dl
        Set_Flags_After_ADD
        Next    4

; [fold]  ]

; [fold]  [
Do_NEG_W_Dx:
        prof    _NEG_W_Dx
        and     eax,7
        mov     dx,[WORD PTR ebp+eax*4+base.D]
        neg     dx
        mov     [WORD PTR ebp+eax*4+base.D],dx
        Set_Flags_After_ADD
        Next    4

; [fold]  ]

; [fold]  [
Do_NEG_L_Dx:
        prof    _NEG_L_Dx

        and     eax,7
        mov     edx,[ebp+eax*4+base.D]
        neg     edx
        mov     [ebp+eax*4+base.D],edx
        Set_Flags_After_ADD
        Next    6

; [fold]  ]

; [fold]  [
Do_NEG_B_Mem:
        prof    _NEG_B_Mem

        Instr_To_EA_B
        Read_B
        neg     dl
        Set_Flags_After_ADD
        Write_B
        Next    8

; [fold]  ]

; [fold]  [
Do_NEG_W_Mem:
        prof    _NEG_W_Mem

        Instr_To_EA_W
        Read_W
        neg     dx
        Set_Flags_After_ADD
        Write_W
        Next    8

; [fold]  ]

; [fold]  [
Do_NEG_L_Mem:
        prof    _NEG_L_Mem

        Instr_To_EA_L
        Read_L
        neg     edx
        Set_Flags_After_ADD
        Write_L
        Next    12

; [fold]  ]

; [fold]  [
Do_NEGX_B_Dx:
        prof    _NEGX_B_Dx
        and     eax,7
        mov     ebx,eax

        xor     edx,edx
        shr     [BYTE PTR ebp+base.X],1

        mov     al,[BYTE PTR ebp+ebx*4+base.D]
        sbb     dl,al
        mov     [BYTE PTR ebp+ebx*4+base.D],dl
        Set_Flags_After_ADD
        Next    4

; [fold]  ]

; [fold]  [
Do_NEGX_W_Dx:
        prof    _NEGX_W_Dx
        and     eax,7
        mov     ebx,eax

        xor     edx,edx
        shr     [BYTE PTR ebp+base.X],1

        mov     ax,[WORD PTR ebp+ebx*4+base.D]
        sbb     dx,ax
        mov     [WORD PTR ebp+ebx*4+base.D],dx
        Set_Flags_After_ADD
        Next    4


; [fold]  ]

; [fold]  [
Do_NEGX_L_Dx:
        prof    _NEGX_L_Dx

        and     eax,7
        mov     ebx,eax

        xor     edx,edx
        shr     [BYTE PTR ebp+base.X],1

        mov     eax,[ebp+ebx*4+base.D]
        sbb     edx,eax
        mov     [ebp+ebx*4+base.D],edx
        Set_Flags_After_ADD
        Next    6

; [fold]  ]

; [fold]  [
Do_NEGX_B_Mem:
        prof    _NEGX_B_Mem

        Instr_To_EA_B
        Read_B
        xor     ecx,ecx
        shr     [BYTE PTR ebp+base.X],1
        sbb     cl,dl
        Set_Flags_After_ADD
        mov     dl,cl
        Write_B
        Next    8

; [fold]  ]

; [fold]  [
Do_NEGX_W_Mem:
        prof    _NEGX_W_Mem

        Instr_To_EA_W
        Read_W
        xor     ecx,ecx
        shr     [BYTE PTR ebp+base.X],1
        sbb     cx,dx
        Set_Flags_After_ADD
        mov     dx,cx
        Write_W
        Next    8
; [fold]  ]

; [fold]  [
Do_NEGX_L_Mem:
        prof    _NEGX_L_Mem

        Instr_To_EA_L
        Read_L
        xor     ecx,ecx
        shr     [BYTE PTR ebp+base.X],1
        sbb     ecx,edx
        Set_Flags_After_ADD
        mov     edx,ecx
        Write_L
        Next    12

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                MULS MULU
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

MACRO Set_Flags_After_MUL
        lahf
        and     ah,0feh                         ;C=0
        mov     [BYTE PTR ebp+base.NZC],ah
        mov     [ebp+base.V],0
        ENDM

; [fold]  [
Do_MULU:
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        test    eax,38h
        jnz     @@mem1
        and     eax,7
        mov     edx,[ebp+eax*4+base.D]
        jmp     @@reg1
@@mem1: Instr_To_EA_W
        Read_W
@@reg1: mov     eax,[ebp+ecx*4+base.D]



        mul     dx
        shl     edx,16
        mov     dx,ax                           ;DX:AX -> EDX

        mov     [DWORD PTR ebp+ecx*4+base.D],edx
        or      edx,edx
        Set_Flags_After_MUL

        Next    70

; [fold]  ]

; [fold]  [
Do_MULS:

        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        test    eax,38h
        jnz     @@mem1
        and     eax,7
        mov     edx,[ebp+eax*4+base.D]
        jmp     @@reg1
@@mem1:
        Instr_To_EA_W
        Read_W
@@reg1:
        mov     eax,[ebp+ecx*4+base.D]


        imul    dx
        shl     edx,16
        mov     dx,ax
        mov     [DWORD PTR ebp+ecx*4+base.D],edx
        or      edx,edx
        Set_Flags_After_MUL
        Next    70

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                DIVS DIVU
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

MACRO Set_Flags_After_DIVS
        or      dx,dx
        lahf
        and     ah,0feh                         ;C=0
        mov     [BYTE PTR ebp+base.NZC],ah              ;set N & Z
        movsx   eax,cx                          ;if edx != dx -> oVerflow
        cmp     eax,ecx
        setne   [BYTE PTR ebp+base.V]
        ENDM

MACRO Set_Flags_After_DIVU
        or      dx,dx
        lahf
        and     ah,0feh                         ;C=0
        mov     [BYTE PTR ebp+base.NZC],ah              ;set N & Z
        mov     [ebp+base.V],0
        ENDM


; [fold]  (
Do_DIVU:
        push    eax
        test    eax,38h
        jnz     @@mem1
        and     eax,7
        mov     edx,[ebp+eax*4+base.D]
        jmp     @@reg1
@@mem1: Instr_To_EA_W
        Read_W
@@reg1: pop     ebx
        shr     ebx,9
        or      dx,dx
        jz      DivideZero
        and     ebx,7
        movzx   ecx,dx
        mov     edx,[ebp+ebx*4+base.D]


;************** Detect OVERFLOW to avoid Intel Divide Error *********

        mov     eax,ecx
        shl     eax,16
        sub     eax,edx
        jnc     @@noover

        mov     [ebp+base.V],1
        jmp     @@contdivu
@@noover:
;********************************************************************



        mov     eax,edx
        xor     edx,edx

        div     ecx                     ;divide on 64 bits to avoid Overflow
        mov     ecx,eax                 ;ecx keeps result (test overflow)
        shl     edx,16                  ;mod on upper word
        mov     dx,ax                   ;result in lower word

        mov     [ebp+ebx*4+base.D],edx
        Set_Flags_After_DIVU

@@contdivu:
        Next    140

; [fold]  )

; [fold]  (
Do_DIVS:

        push    eax
        test    eax,38h
        jnz     @@mem1
        and     eax,7
        mov     edx,[ebp+eax*4+base.D]
        jmp     @@reg1
@@mem1:
        Instr_To_EA_W
        Read_W
@@reg1:
        pop     ebx
        shr     ebx,9
        or      dx,dx
        jz      DivideZero
        and     ebx,7
        movsx   ecx,dx
        mov     eax,[ebp+ebx*4+base.D]


;************* Detect OVERFLOW BEFORE DIV

;        mov     edx,ecx
;        shl     edx,16
;        sub     edx,eax
;        jnc     @@noover
;
;        mov     [_V],1
;        jmp     @@contdivs
;
;@@noover:
        cdq                     ; extend sign on EDX
        idiv     ecx                     ;divide on 64 bits to avoid Overflow
        mov     ecx,eax                 ;ecx keeps result (test overflow)
        shl     edx,16                  ;mod on upper word
        mov     dx,ax                   ;result in lower word


        Set_Flags_After_DIVS
        cmp     [ebp+base.V],0
        jnz     @@contdivs
        mov     [DWORD PTR ebp+ebx*4+base.D],edx
@@contdivs:
        Next    158


PROC DivideZero NEAR
        mov     eax,[ebp+base.IOPL]
        mov     [ebp+base.New_IOPL],eax
        mov     eax,_EXCEPTION_ZERODIVIDE
        MoreCycles 42
        jmp     Trigger_Exception
        ENDP

; [fold]  )

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      CHK
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  (
Do_CHK_Dx:
        prof    _CHK_Dx
        mov     edx,eax
        and     edx,7
        mov     dx,[WORD PTR ebp+edx*4+base.D]          ;range value
        jmp     Check

Do_CHK_mem:
        prof    _CHK_mem
        push    eax
        Instr_To_EA_W
        Read_W
        pop     eax
Check:
        shr     eax,9
        and     eax,7

        mov     ax,[WORD PTR ebp+eax*4+base.D]          ;value to check
        or      ax,ax
        js      Chk_Minus
        cmp     ax,dx
        ja      Chk_Plus
                                                ;flags????
        Next    10


Chk_Minus:                                      ;exception CHK
        or      [BYTE PTR ebp+base.NZC],080h            ;N=1
Excpt:
        mov     eax,[ebp+base.IOPL]
        mov     [ebp+base.New_IOPL],eax
        mov     eax,_EXCEPTION_CHK
        MoreCycles 44
        jmp     Trigger_Exception
Chk_Plus:
        and     [BYTE PTR ebp+base.NZC],07fh            ;N=0
        jmp     Excpt

; [fold]  )


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      TAS
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_TAS_Dx:
        prof    _TST_B_Dx
        and     eax,7
        mov     dl,[BYTE PTR ebp+eax*4+base.D]
        or      dl,dl
        push    eax
        Set_Flags_After_TST
        pop     eax
        or      [BYTE PTR ebp+eax*4+base.D],80h
        Next    4

; [fold]  ]

; [fold]  [
Do_TAS_Mem:
        prof    _TST_B_Mem

        Instr_To_EA_B
        Read_B
        or      dl,dl
        Set_Flags_After_TST
        or      dl,80h
        Write_B
        Next    4

; [fold]  ]

END

; [fold]  71
