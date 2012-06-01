COMMENT ~
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ Emulation of MOVE type instructions                                      ³
³                                                                          ³
³       25/6/96  Converted all code to TASM IDEAL mode                     ³
³        1/7/96  Start optimizing MOVEs functions                          ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
~
        IDEAL

        INCLUDE "simu68.inc"
        INCLUDE "profile.inc"

        CODESEG

        PUBLIC Init_Special_MOVES


;
;      destinations
;         ÚÄÄÄÄÂÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄ¿
; sources ³ Dn ³ An ³  (An) ³ (An)+ ³ -(An) ³ d(An) ³d(An,Xi)³ Abs.W ³Abs.L  ³
;ÚÄÄÄÄÄÄÄÄÅÄÄÄÄÅÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄ´
;³Dn      ³  x ³ x  ³   x   ³   x   ³   x   ³   x   ³        ³   x   ³   x   ³
;³An      ³  x ³ x  ³   x   ³   x   ³   x   ³   x   ³        ³   x   ³   x   ³
;³(An)    ³  x ³ x  ³   x   ³   x   ³   x   ³   x   ³        ³       ³   x   ³
;³(An)+   ³  x ³ x  ³   x   ³   x   ³   x   ³   x   ³        ³       ³   x   ³
;³-(An)   ³  x ³ x  ³   x   ³   x   ³   x   ³   x   ³        ³       ³   x   ³
;³d(An)   ³  x ³ x  ³   x   ³   x   ³   x   ³   x   ³        ³       ³   x   ³
;³d(An,Xi)³    ³    ³       ³       ³       ³       ³        ³       ³       ³
;³Abs.W   ³    ³    ³       ³       ³       ³       ³        ³       ³       ³
;³Abs.L   ³  x ³ x  ³   x   ³   x   ³   x   ³   x   ³        ³       ³   x   ³
;³d(PC)   ³    ³    ³       ³       ³       ³       ³        ³       ³       ³
;³d(PC,Xi)³    ³    ³       ³       ³       ³       ³        ³       ³       ³
;³Imm     ³  x ³ x  ³   x   ³   x   ³   x   ³   x   ³        ³       ³   x   ³
;ÀÄÄÄÄÄÄÄÄÁÄÄÄÄÁÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÙ


                ; AX = opcode  15   12-14  11   8-10    0-7
                ;             ÚÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄ¿
                ;             ³D/A³IDX reg³W/L³0 0 0 ³ offset ³
                ;             ÀÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÙ
                ;              0=D         0=W
                ;              1=A         1=L
                ;EDI = adr.
                ;EAX,EDX modified

Calc_Ai8d_Src:
        mov     dx,[esi+ebp]    ;DL = DA-Idx-WL DH=offset
        and     eax,7
        movsx   edi,dh          ;EDI = 32 bit signed offset
        and     edx,0ffh
        add     edi,[_A+eax*4]  ;EDI = Ax + 8 bit offset
        shr     edx,3
        add     esi,2
        jmp     [DWORD PTR Ai8d_Fast+edx*4]

Ai8d_A0W:
        mov     ax,[WORD PTR _A+0*4]
        cwde
        add     edi,eax
        ret
Ai8d_A1W:
        mov     ax,[WORD PTR _A+1*4]
        cwde
        add     edi,eax
        ret
Ai8d_A2W:
        mov     ax,[WORD PTR _A+2*4]
        cwde
        add     edi,eax
        ret
Ai8d_A3W:
        mov     ax,[WORD PTR _A+3*4]
        cwde
        add     edi,eax
        ret
Ai8d_A4W:
        mov     ax,[WORD PTR _A+4*4]
        cwde
        add     edi,eax
        ret
Ai8d_A5W:
        mov     ax,[WORD PTR _A+5*4]
        cwde
        add     edi,eax
        ret
Ai8d_A6W:
        mov     ax,[WORD PTR _A+6*4]
        cwde
        add     edi,eax
        ret
Ai8d_A7W:
        mov     ax,[WORD PTR _A+7*4]
        cwde
        add     edi,eax
        ret
Ai8d_D0W:
        mov     ax,[WORD PTR _D+0*4]
        cwde
        add     edi,eax
        ret
Ai8d_D1W:
        mov     ax,[WORD PTR _D+1*4]
        cwde
        add     edi,eax
        ret
Ai8d_D2W:
        mov     ax,[WORD PTR _D+2*4]
        cwde
        add     edi,eax
        ret
Ai8d_D3W:
        mov     ax,[WORD PTR _D+3*4]
        cwde
        add     edi,eax
        ret
Ai8d_D4W:
        mov     ax,[WORD PTR _D+4*4]
        cwde
        add     edi,eax
        ret
Ai8d_D5W:
        mov     ax,[WORD PTR _D+5*4]
        cwde
        add     edi,eax
        ret
Ai8d_D6W:
        mov     ax,[WORD PTR _D+6*4]
        cwde
        add     edi,eax
        ret
Ai8d_D7W:
        mov     ax,[WORD PTR _D+7*4]
        cwde
        add     edi,eax
        ret
Ai8d_A0L:
        add     edi,[_A+0*4]
        ret
Ai8d_A1L:
        add     edi,[_A+1*4]
        ret
Ai8d_A2L:
        add     edi,[_A+2*4]
        ret
Ai8d_A3L:
        add     edi,[_A+3*4]
        ret
Ai8d_A4L:
        add     edi,[_A+4*4]
        ret
Ai8d_A5L:
        add     edi,[_A+5*4]
        ret
Ai8d_A6L:
        add     edi,[_A+6*4]
        ret
Ai8d_A7L:
        add     edi,[_A+7*4]
        ret
Ai8d_D0L:
        add     edi,[_D+0*4]
        ret
Ai8d_D1L:
        add     edi,[_D+1*4]
        ret
Ai8d_D2L:
        add     edi,[_D+2*4]
        ret
Ai8d_D3L:
        add     edi,[_D+3*4]
        ret
Ai8d_D4L:
        add     edi,[_D+4*4]
        ret
Ai8d_D5L:
        add     edi,[_D+5*4]
        ret
Ai8d_D6L:
        add     edi,[_D+6*4]
        ret
Ai8d_D7L:
        add     edi,[_D+7*4]
        ret


        DATASEG

Ai8d_Fast:
        dd      Ai8d_D0W,Ai8d_D0L,Ai8d_D1W,Ai8d_D1L
        dd      Ai8d_D2W,Ai8d_D2L,Ai8d_D3W,Ai8d_D3L
        dd      Ai8d_D4W,Ai8d_D4L,Ai8d_D5W,Ai8d_D5L
        dd      Ai8d_D6W,Ai8d_D6L,Ai8d_D7W,Ai8d_D7L
        dd      Ai8d_A0W,Ai8d_A0L,Ai8d_A1W,Ai8d_A1L
        dd      Ai8d_A2W,Ai8d_A2L,Ai8d_A3W,Ai8d_A3L
        dd      Ai8d_A4W,Ai8d_A4L,Ai8d_A5W,Ai8d_A5L
        dd      Ai8d_A6W,Ai8d_A6L,Ai8d_A7W,Ai8d_A7L

        CODESEG

Do_MOVE_B_Ai8d_To_Dx:
        prof    _Optimized_MOVE

        mov     ebx,eax
        call    Calc_Ai8d_Src
        shr     ebx,9
        Read_B
        or      dl,dl
        Set_Flags_NZC
        and     ebx,7
        mov     [_V],0
        mov     [BYTE PTR _D+ebx*4],dl
        Next    14

Do_MOVE_W_Ai8d_To_Dx:
        prof    _Optimized_MOVE

        mov     ebx,eax
        call    Calc_Ai8d_Src
        shr     ebx,9
        Read_W
        or      dx,dx
        Set_Flags_NZC
        and     ebx,7
        mov     [_V],0
        mov     [WORD PTR _D+ebx*4],dx
        Next    14

Do_MOVE_L_Ai8d_To_Dx:
        prof    _Optimized_MOVE

        mov     ebx,eax
        call    Calc_Ai8d_Src
        shr     ebx,9
        Read_L
        or      edx,edx
        Set_Flags_NZC
        and     ebx,7
        mov     [_V],0
        mov     [_D+ebx*4],edx
        Next    18

;*************************************************************** MOVE Dx,...

; [fold]  [
; MOVE Dx,Dx
MACRO MOVE_Dx_Dx siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        and     eax,7
        shr     ebx,9
        mov     reg,[siz PTR _D+eax*4]
        and     ebx,7
        or      reg,reg
        Set_Flags_NZC
        mov     [_V],0
        mov     [siz PTR _D+ebx*4],reg
        ENDM

Do_MOVE_B_Dx_To_Dx:
        MOVE_Dx_Dx BYTE dl
        Next    4

Do_MOVE_W_Dx_To_Dx:
        MOVE_Dx_Dx WORD dx
        Next    4

Do_MOVE_L_Dx_To_Dx:
        MOVE_Dx_Dx DWORD edx
        Next    4


; [fold]  ]

; [fold]  [
; MOVEA Dx,Ax

Do_MOVEA_W_Dx:
        prof    _Optimized_MOVE
        mov     ebx,eax
        and     eax,7
        shr     ebx,9
        movsx   edx,[WORD PTR _D+eax*4]
        and     ebx,7
        mov     [DWORD PTR _A+ebx*4],edx
        Next    4

Do_MOVEA_L_Dx:
        prof    _Optimized_MOVE
        mov     ebx,eax
        and     eax,7
        shr     ebx,9
        mov     edx,[_D+eax*4]
        and     ebx,7
        mov     [_A+ebx*4],edx
        Next    4


; [fold]  ]

; [fold]  [
; MOVE Dx,(Ax)

MACRO MOVE_Dx_Aind siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        mov     reg,[siz PTR _D + ebx*4]
        mov     edi,[_A + eax*4]
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Dx_To_Aind:
        MOVE_Dx_Aind BYTE dl
        Write_B
        Next    8

Do_MOVE_W_Dx_To_Aind:
        MOVE_Dx_Aind WORD dx
        Write_W
        Next    8

Do_MOVE_L_Dx_To_Aind:
        MOVE_Dx_Aind DWORD edx
        Write_L
        Next    12


; [fold]  ]

; [fold]  [
; MOVE Dx,(Ax)+

MACRO MOVE_Dx_Aipi siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        mov     reg,[siz PTR _D + ebx*4]
        mov     edi,[_A + eax*4]
        add     [_A+ eax * 4],siz
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Dx_To_Aipi:
        MOVE_Dx_Aipi BYTE dl
        Write_B
        Next    8

Do_MOVE_W_Dx_To_Aipi:
        MOVE_Dx_Aipi WORD dx
        Write_W
        Next    8

Do_MOVE_L_Dx_To_Aipi:
        MOVE_Dx_Aipi DWORD edx
        Write_L
        Next    12


; [fold]  ]

; [fold]  [
; MOVE Dx,-(Ax)

MACRO MOVE_Dx_Aipd siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        sub     [_A+ eax * 4],siz
        mov     reg,[siz PTR _D + ebx*4]
        mov     edi,[_A + eax*4]
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Dx_A7pd:
        MOVE_Dx_Aipd WORD dx
        Write_B
        Next    8

Do_MOVE_B_Dx_To_Aipd:
        MOVE_Dx_Aipd BYTE dl
        Write_B
        Next    8

Do_MOVE_W_Dx_To_Aipd:
        MOVE_Dx_Aipd WORD dx
        Write_W
        Next    8

Do_MOVE_L_Dx_To_Aipd:
        MOVE_Dx_Aipd DWORD edx
        Write_L
        Next    12



; [fold]  ]

; [fold]  [
; MOVE Dx,d(Ax)

MACRO MOVE_Dx_Ai16 siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        mov     dx,[esi+ebp]    ;offset
        and     eax,7           ;(Ax)
        rol     dx,8            ;low-high swap
        and     ebx,7           ;source register
        movsx   edi,dx          ;EDI = 16 bits offset
        add     edi,[_A+eax*4]  ;EDI = Ax + offset
        add     esi,2           ;PC+=2
        mov     reg,[siz PTR _D+ebx*4]
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Dx_To_Ai16:
        MOVE_Dx_Ai16 BYTE dl
        Write_B
        Next    12

Do_MOVE_W_Dx_To_Ai16:
        MOVE_Dx_Ai16 WORD dx
        Write_W
        Next    12

Do_MOVE_L_Dx_To_Ai16:
        MOVE_Dx_Ai16 DWORD edx
        Write_L
        Next    16


; [fold]  ]

; [fold]  [
; MOVE Dx,Abs.W

MACRO MOVE_Dx_AbsW siz, reg
        prof    _Optimized_MOVE

        mov     bx,[esi+ebp]
        and     eax,7
        rol     bx,8
        mov     reg,[siz PTR _D+eax*4]
        add     esi,2
        movsx   edi,bx
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Dx_To_AbsW:
        MOVE_Dx_AbsW BYTE dl
        Write_B
        Next    12

Do_MOVE_W_Dx_To_AbsW:
        MOVE_Dx_AbsW WORD dx
        Write_W
        Next    12

Do_MOVE_L_Dx_To_AbsW:
        MOVE_Dx_AbsW DWORD edx
        Write_L
        Next    16


; [fold]  ]

; [fold]  [
; MOVE Dx,Abs.L

MACRO MOVE_Dx_AbsL siz, reg
        prof    _Optimized_MOVE

        and     eax,7
        mov     edi,[esi+ebp]
        mov     reg,[siz PTR _D+eax*4]
        add     esi,4
        bswap   edi
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Dx_To_AbsL:
        MOVE_Dx_AbsL BYTE dl
        Write_B
        Next    16

Do_MOVE_W_Dx_To_AbsL:
        MOVE_Dx_AbsL WORD dx
        Write_W
        Next    16

Do_MOVE_L_Dx_To_AbsL:
        MOVE_Dx_AbsL DWORD edx
        Write_L
        Next    20


; [fold]  ]


;************************************************************ MOVE Ax,...

; [fold]  [
; MOVE Ax,Dx
MACRO MOVE_Ax_Dx siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        and     eax,7
        shr     ebx,9
        mov     reg,[siz PTR _A+eax*4]
        and     ebx,7
        or      reg,reg
        Set_Flags_NZC
        mov     [_V],0
        mov     [siz PTR _D+ebx*4],reg
        ENDM

Do_MOVE_W_Ax_To_Dx:
        MOVE_Ax_Dx WORD dx
        Next    4

Do_MOVE_L_Ax_To_Dx:
        MOVE_Ax_Dx DWORD edx
        Next    4


; [fold]  ]

; [fold]  [
; MOVEA Dx,Ax

Do_MOVEA_W_Ax:
        prof    _Optimized_MOVE
        mov     ebx,eax
        and     eax,7
        shr     ebx,9
        movsx   edx,[WORD PTR _A+eax*4]
        and     ebx,7
        mov     [DWORD PTR _A+ebx*4],edx
        Next    4

Do_MOVEA_L_Ax:
        prof    _Optimized_MOVE
        mov     ebx,eax
        and     eax,7
        shr     ebx,9
        mov     edx,[_A+eax*4]
        and     ebx,7
        mov     [_A+ebx*4],edx
        Next    4


; [fold]  ]

; [fold]  [
; MOVE Ax,(Ax)

MACRO MOVE_Ax_Aind siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        mov     reg,[siz PTR _A + ebx*4]
        mov     edi,[_A + eax*4]
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_W_Ax_To_Aind:
        MOVE_Ax_Aind WORD dx
        Write_W
        Next    8

Do_MOVE_L_Ax_To_Aind:
        MOVE_Ax_Aind DWORD edx
        Write_L
        Next    12


; [fold]  ]

; [fold]  [
; MOVE Ax,(Ax)+

MACRO MOVE_Ax_Aipi siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        mov     reg,[siz PTR _A + ebx*4]
        mov     edi,[_A + eax*4]
        add     [_A+ eax * 4],siz
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_W_Ax_To_Aipi:
        MOVE_Ax_Aipi WORD dx
        Write_W
        Next    8

Do_MOVE_L_Ax_To_Aipi:
        MOVE_Ax_Aipi DWORD edx
        Write_L
        Next    12


; [fold]  ]

; [fold]  [
; MOVE Ax,-(Ax)

MACRO MOVE_Ax_Aipd siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7
        sub     [_A+ eax * 4],siz
        mov     [_V],0
        mov     reg,[siz PTR _A + ebx*4]
        mov     edi,[_A + eax*4]
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_W_Ax_To_Aipd:
        MOVE_Ax_Aipd WORD dx
        Write_W
        Next    8

Do_MOVE_L_Ax_To_Aipd:
        MOVE_Ax_Aipd DWORD edx
        Write_L
        Next    12


; [fold]  ]

; [fold]  [
; MOVE Ax,d(Ax)

MACRO MOVE_Ax_Ai16 siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        mov     dx,[esi+ebp]    ;offset
        and     eax,7           ;(Ax)
        rol     dx,8            ;low-high swap
        and     ebx,7           ;source register
        movsx   edi,dx          ;EDI = 16 bits offset
        add     esi,2           ;PC+=2
        add     edi,[_A+eax*4]  ;EDI = Ax + offset
        mov     reg,[siz PTR _A+ebx*4]
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_W_Ax_To_Ai16:
        MOVE_Ax_Ai16 WORD dx
        Write_W
        Next    12

Do_MOVE_L_Ax_To_Ai16:
        MOVE_Ax_Ai16 DWORD edx
        Write_L
        Next    16


; [fold]  ]

; [fold]  [
; MOVE Ax,Abs.W

MACRO MOVE_Ax_AbsW siz, reg
        prof    _Optimized_MOVE

        and     eax,7
        mov     bx,[esi+ebp]
        mov     reg,[siz PTR _A+eax*4]
        rol     bx,8
        add     esi,2
        movsx   edi,bx
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_W_Ax_To_AbsW:
        MOVE_Ax_AbsW WORD dx
        Write_W
        Next    12

Do_MOVE_L_Ax_To_AbsW:
        MOVE_Ax_AbsW DWORD edx
        Write_L
        Next    16


; [fold]  ]

; [fold]  [
; MOVE Ax,Abs.L

MACRO MOVE_Ax_AbsL siz, reg
        prof    _Optimized_MOVE

        and     eax,7
        mov     edi,[esi+ebp]
        mov     reg,[siz PTR _A+eax*4]
        add     esi,4
        bswap   edi
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_W_Ax_To_AbsL:
        MOVE_Ax_AbsL WORD dx
        Write_W
        Next    16

Do_MOVE_L_Ax_To_AbsL:
        MOVE_Ax_AbsL DWORD edx
        Write_L
        Next    20


; [fold]  ]


;************************************************************ MOVE (Ax),...

; [fold]  [
; MOVE (Ax),Dx

MACRO MOVE_Aind_Dx siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7           ;source register
        and     eax,7           ;(Ax)
        mov     edi,[_A+ebx*4]  ;EDI = Ax + offset

        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        mov     [_V],0
        mov     [siz PTR _D+eax*4],reg
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aind_To_Dx:
        MOVE_Aind_Dx BYTE dl
        Next    8

Do_MOVE_W_Aind_To_Dx:
        MOVE_Aind_Dx WORD dx
        Next    8

Do_MOVE_L_Aind_To_Dx:
        MOVE_Aind_Dx DWORD edx
        Next    12


; [fold]  ]

; [fold]  [
; MOVEA (Ax),Ax


Do_MOVEA_W_Aind:
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7           ;source register
        and     eax,7           ;(Ax)
        mov     edi,[_A+ebx*4]  ;EDI = Ax + offset
        Read_W
        movsx   edx,dx
        mov     [_A+eax*4],edx
        Next    8

Do_MOVEA_L_Aind:
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7           ;source register
        and     eax,7           ;(Ax)
        mov     edi,[_A+ebx*4]  ;EDI = Ax + offset
        Read_L
        mov     [_A+eax*4],edx
        Next    12


; [fold]  ]

; [fold]  [
; MOVE (Ax),(Ax)

MACRO MOVE_Aind_Aind siz, reg
        prof    _Optimized_MOVE

        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7

        mov     edi,[_A + ebx*4]                ; source adr.

        IFIDN <siz>,<BYTE>
                Read_B
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_W
        ELSE
                Read_L
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_L
        ENDIF
        ENDIF
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aind_To_Aind:
        MOVE_Aind_Aind BYTE dl
        Next    12

Do_MOVE_W_Aind_To_Aind:
        MOVE_Aind_Aind WORD dx
        Next    12

Do_MOVE_L_Aind_To_Aind:
        MOVE_Aind_Aind DWORD edx
        Next    20


; [fold]  ]

; [fold]  [
; MOVE (Ax),(Ax)+

MACRO MOVE_Aind_Aipi siz, reg
        prof    _Optimized_MOVE

        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7

        mov     edi,[_A + ebx*4]                ; source adr.

        IFIDN <siz>,<BYTE>
                Read_B
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_W
        ELSE
                Read_L
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_L
        ENDIF
        ENDIF
        add     [_A+eax*4],siz
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aind_To_Aipi:
        MOVE_Aind_Aipi BYTE dl
        Next    12

Do_MOVE_W_Aind_To_Aipi:
        MOVE_Aind_Aipi WORD dx
        Next    12

Do_MOVE_L_Aind_To_Aipi:
        MOVE_Aind_Aipi DWORD edx
        Next    20


; [fold]  ]

; [fold]  [
; MOVE (Ax),-(Ax)

MACRO MOVE_Aind_Aipd siz, reg, isa7
        prof    _Optimized_MOVE

        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7

        mov     edi,[_A + ebx*4]                ; source adr.
        sub     [_A+eax*4],siz

        IFIDN <siz>,<BYTE>
                IFIDN <isa7>,<YES>
                        dec     [_A+eax*4]
                ENDIF
                Read_B
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_W
        ELSE
                Read_L
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_L
        ENDIF
        ENDIF
        or      reg,reg
        Set_Flags_NZC
        ENDM


Do_MOVE_B_Aind_A7pd:
        MOVE_Aind_Aipd BYTE dl YES
        Next    12

Do_MOVE_B_Aind_To_Aipd:
        MOVE_Aind_Aipd BYTE dl NO
        Next    12

Do_MOVE_W_Aind_To_Aipd:
        MOVE_Aind_Aipd WORD dx NO
        Next    12

Do_MOVE_L_Aind_To_Aipd:
        MOVE_Aind_Aipd DWORD edx NO
        Next    20


; [fold]  ]

; [fold]  [
; MOVE (Ax),d(Ax)

MACRO MOVE_Aind_Ai16 siz, reg
        prof    _Optimized_MOVE

        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7

        mov     edi,[_A + ebx*4]                ; source adr.

        mov     bx,[esi+ebp]
        add     esi,2
        rol     bx,8

        IFIDN <siz>,<BYTE>
                Read_B
                movsx   edi,bx
                mov     [_V],0
                add     edi,[_A+eax*4]
                Write_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
                movsx   edi,bx
                mov     [_V],0
                add     edi,[_A+eax*4]
                Write_W
        ELSE
                Read_L
                movsx   edi,bx
                mov     [_V],0
                add     edi,[_A+eax*4]
                Write_L
        ENDIF
        ENDIF
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aind_To_Ai16:
        MOVE_Aind_Ai16 BYTE dl
        Next    16

Do_MOVE_W_Aind_To_Ai16:
        MOVE_Aind_Ai16 WORD dx
        Next    16

Do_MOVE_L_Aind_To_Ai16:
        MOVE_Aind_Ai16 DWORD edx
        Next    24


; [fold]  ]


; [fold]  [
; MOVE (Ax),AbsL

MACRO MOVE_Aind_AbsL siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7           ;source register
        and     eax,7           ;(Ax)
        mov     edi,[_A+ebx*4]  ;EDI = Ax + offset

        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        mov     edi,[esi+ebp]
        add     esi,4
        bswap   edi
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aind_To_AbsL:
        MOVE_Aind_AbsL BYTE dl
        Write_B
        Next    20

Do_MOVE_W_Aind_To_AbsL:
        MOVE_Aind_AbsL WORD dx
        Write_W
        Next    20

Do_MOVE_L_Aind_To_AbsL:
        MOVE_Aind_AbsL DWORD edx
        Write_L
        Next    28


; [fold]  ]



;************************************************************ MOVE (Ax)+,...

; [fold]  [
; MOVE (Ax)+,Dx

MACRO MOVE_Aipi_Dx siz, reg
        prof    _Optimized_MOVE

        mov     ebx,eax
        and     eax,7
        shr     ebx,9

        mov     edi,[_A + eax*4]        ;adr
        and     ebx,7

        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        IFIDN <siz>,<BYTE>
        cmp     eax,7
        jnz     short @@noA7
        add     [_A+eax*4],2
        mov     [_V],0
        mov     [siz PTR _D + ebx*4],reg
        or      reg,reg
        Set_Flags_NZC
        jmp short @@isA7
@@noA7:
        ENDIF

        add     [_A+eax*4],siz
        mov     [_V],0
        mov     [siz PTR _D + ebx*4],reg
        or      reg,reg
        Set_Flags_NZC
@@isA7:
        ENDM

Do_MOVE_B_Aipi_To_Dx:
        MOVE_Aipi_Dx BYTE dl
        Next    8

Do_MOVE_W_Aipi_To_Dx:
        MOVE_Aipi_Dx WORD dx
        Next    8

Do_MOVE_L_Aipi_To_Dx:
        MOVE_Aipi_Dx DWORD edx
        Next    12


; [fold]  ]

; [fold]  [
; MOVEA (Ax)+,Ax


Do_MOVEA_W_Aipi:
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7           ;source register
        and     eax,7           ;(Ax)
        mov     edi,[_A+ebx*4]  ;EDI = Ax + offset
        Read_W
        movsx   edx,dx
        add     [_A+ebx*4],2
        mov     [_A+eax*4],edx
        Next    8

Do_MOVEA_L_Aipi:
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7           ;source register
        and     eax,7           ;(Ax)
        mov     edi,[_A+ebx*4]  ;EDI = Ax + offset
        Read_L
        add     [_A+ebx*4],4
        mov     [_A+eax*4],edx
        Next    12


; [fold]  ]

; [fold]  [
; MOVE (Ax)+,(Ax)

MACRO MOVE_Aipi_Aind siz, reg
        prof    _Optimized_MOVE

        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7

        mov     edi,[_A + ebx*4]                ; source adr.
        add     [_A + ebx*4],siz                ; inc

        IFIDN <siz>,<BYTE>
                cmp     ebx,7
                jnz     @@noA7
                inc     [_A+4*7]
@@noA7:
                Read_B
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_W
        ELSE
                Read_L
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_L
        ENDIF
        ENDIF
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aipi_To_Aind:
        MOVE_Aipi_Aind BYTE dl
        Next    12

Do_MOVE_W_Aipi_To_Aind:
        MOVE_Aipi_Aind WORD dx
        Next    12

Do_MOVE_L_Aipi_To_Aind:
        MOVE_Aipi_Aind DWORD edx
        Next    20


; [fold]  ]

; [fold]  [
; MOVE (Ax)+,(Ax)+

MACRO MOVE_Aipi_Aipi siz, reg
        prof    _Optimized_MOVE

        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7

        mov     edi,[_A + ebx*4]                ; source adr.
        add     [_A + ebx*4],siz                ; inc

        IFIDN <siz>,<BYTE>
                cmp     ebx,7
                jnz     @@noA7
                inc     [_A+4*7]
@@noA7:
                Read_B
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_W
        ELSE
                Read_L
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_L
        ENDIF
        ENDIF
        add     [_A + eax*4],siz
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aipi_To_Aipi:
        MOVE_Aipi_Aipi BYTE dl
        Next    12

Do_MOVE_W_Aipi_To_Aipi:
        MOVE_Aipi_Aipi WORD dx
        Next    12

Do_MOVE_L_Aipi_To_Aipi:
        MOVE_Aipi_Aipi DWORD edx
        Next    20


; [fold]  ]

; [fold]  [
; MOVE (Ax)+,-(Ax)

MACRO MOVE_Aipi_Aipd siz, reg, isa7
        prof    _Optimized_MOVE

        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7

        mov     edi,[_A + ebx*4]                ; source adr.
        add     [_A + ebx*4],siz                ; inc
        sub     [_A + eax*4],siz

        IFIDN <siz>,<BYTE>
                IFIDN <isa7>,<YES>              ; spec: A7 dest
                        dec     [_A+eax*4]
                ENDIF
                cmp     ebx,7
                jnz     @@noA7
                inc     [_A+4*7]
@@noA7:
                Read_B
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_W
        ELSE
                Read_L
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_L
        ENDIF
        ENDIF
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aipi_A7pd:
        MOVE_Aipi_Aipd BYTE dl YES
        Next    12

Do_MOVE_B_Aipi_To_Aipd:
        MOVE_Aipi_Aipd BYTE dl NO
        Next    12

Do_MOVE_W_Aipi_To_Aipd:
        MOVE_Aipi_Aipd WORD dx NO
        Next    12

Do_MOVE_L_Aipi_To_Aipd:
        MOVE_Aipi_Aipd DWORD edx NO
        Next    20


; [fold]  ]

; [fold]  [
; MOVE (Ax)+,d(Ax)

MACRO MOVE_Aipi_Ai16 siz, reg
        prof    _Optimized_MOVE

        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7

        mov     edi,[_A + ebx*4]                ; source adr.
        add     [_A + ebx*4],siz                ; inc

        push    ebx             ; to test if is was A7

        mov     bx,[esi+ebp]
        add     esi,2
        rol     bx,8

        IFIDN <siz>,<BYTE>
                cmp     [DWORD PTR ss:esp],7
                jnz     @@noA7
                inc     [_A+4*7]
@@noA7:
                Read_B
                movsx   edi,bx
                mov     [_V],0
                add     edi,[_A+eax*4]
                Write_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
                movsx   edi,bx
                mov     [_V],0
                add     edi,[_A+eax*4]
                Write_W
        ELSE
                Read_L
                movsx   edi,bx
                mov     [_V],0
                add     edi,[_A+eax*4]
                Write_L
        ENDIF
        ENDIF

        add     esp,4   ;skip previous ebx

        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aipi_To_Ai16:
        MOVE_Aipi_Ai16 BYTE dl
        Next    16

Do_MOVE_W_Aipi_To_Ai16:
        MOVE_Aipi_Ai16 WORD dx
        Next    16

Do_MOVE_L_Aipi_To_Ai16:
        MOVE_Aipi_Ai16 DWORD edx
        Next    24


; [fold]  ]

; [fold]  [
; MOVE (Ax)+,AbsL

MACRO MOVE_Aipi_AbsL siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7           ;source register
        and     eax,7           ;(Ax)
        mov     edi,[_A+ebx*4]  ;EDI = Ax + offset
        add     [_A+ebx*4],siz

        IFIDN <siz>,<BYTE>
                cmp     ebx,7
                jnz     @@noA7
                inc     [_A+4*7]
@@noA7:
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        mov     edi,[esi+ebp]
        add     esi,4
        bswap   edi
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aipi_To_AbsL:
        MOVE_Aipi_AbsL BYTE dl
        Write_B
        Next    20

Do_MOVE_W_Aipi_To_AbsL:
        MOVE_Aipi_AbsL WORD dx
        Write_W
        Next    20

Do_MOVE_L_Aipi_To_AbsL:
        MOVE_Aipi_AbsL DWORD edx
        Write_L
        Next    28


; [fold]  ]


;************************************************************ MOVE -(Ax),...

; [fold]  [
; MOVE -(Ax),Dx

MACRO MOVE_Aipd_Dx siz, reg
        prof    _Optimized_MOVE

        mov     ebx,eax
        and     eax,7
        shr     ebx,9

        sub     [_A+eax*4],siz
        mov     edi,[_A + eax*4]        ;adr
        and     ebx,7

        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        mov     [_V],0
        mov     [siz PTR _D + ebx*4],reg
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aipd_To_Dx:
        MOVE_Aipd_Dx BYTE dl
        Next    10

Do_MOVE_W_Aipd_To_Dx:
        MOVE_Aipd_Dx WORD dx
        Next    10

Do_MOVE_L_Aipd_To_Dx:
        MOVE_Aipd_Dx DWORD edx
        Next    14


; [fold]  ]

; [fold]  [
; MOVEA -(Ax),Ax

Do_MOVEA_W_Aipd:
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7           ;source register
        sub     [_A+ebx*4],2
        mov     edi,[_A+ebx*4]  ;EDI = Ax + offset
        Read_W
        and     eax,7           ;(Ax)
        movsx   edx,dx
        mov     [_A+eax*4],edx
        Next    10

Do_MOVEA_L_Aipd:
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7           ;source register
        sub     [_A+ebx*4],4
        mov     edi,[_A+ebx*4]  ;EDI = Ax + offset
        Read_L
        and     eax,7           ;(Ax)
        mov     [_A+eax*4],edx
        Next    14


; [fold]  ]

; [fold]  [
; MOVE -(Ax),(Ax)

MACRO MOVE_Aipd_Aind siz, reg
        prof    _Optimized_MOVE

        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7

        sub     [_A + ebx*4],siz                ; inc
        mov     edi,[_A + ebx*4]                ; source adr.

        IFIDN <siz>,<BYTE>
                Read_B
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_W
        ELSE
                Read_L
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_L
        ENDIF
        ENDIF
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aipd_To_Aind:
        MOVE_Aipd_Aind BYTE dl
        Next    14

Do_MOVE_W_Aipd_To_Aind:
        MOVE_Aipd_Aind WORD dx
        Next    14

Do_MOVE_L_Aipd_To_Aind:
        MOVE_Aipd_Aind DWORD edx
        Next    22


; [fold]  ]

; [fold]  [
; MOVE -(Ax),(Ax)+

MACRO MOVE_Aipd_Aipi siz, reg
        prof    _Optimized_MOVE

        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7

        sub     [_A + ebx*4],siz                ; inc
        mov     edi,[_A + ebx*4]                ; source adr.

        IFIDN <siz>,<BYTE>
                Read_B
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_W
        ELSE
                Read_L
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_L
        ENDIF
        ENDIF
        add     [_A + eax*4],siz
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aipd_To_Aipi:
        MOVE_Aipd_Aipi BYTE dl
        Next    14

Do_MOVE_W_Aipd_To_Aipi:
        MOVE_Aipd_Aipi WORD dx
        Next    14

Do_MOVE_L_Aipd_To_Aipi:
        MOVE_Aipd_Aipi DWORD edx
        Next    22


; [fold]  ]

; [fold]  [
; MOVE -(Ax),-(Ax)

MACRO MOVE_Aipd_Aipd siz, reg, isa7
        prof    _Optimized_MOVE

        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7

        sub     [_A + ebx*4],siz                ; inc
        mov     edi,[_A + ebx*4]                ; source adr.
        sub     [_A + eax*4],siz

        IFIDN <siz>,<BYTE>
                IFIDN <isa7>,<YES>              ; spec: A7 dest
                        dec     [_A+eax*4]
                ENDIF
                Read_B
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_W
        ELSE
                Read_L
                mov     edi,[_A+eax*4]
                mov     [_V],0
                Write_L
        ENDIF
        ENDIF
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aipd_A7pd:
        MOVE_Aipd_Aipd BYTE dl YES      ;move ...,-(a7)
        Next    12

Do_MOVE_B_Aipd_To_Aipd:
        MOVE_Aipd_Aipd BYTE dl NO
        Next    14

Do_MOVE_W_Aipd_To_Aipd:
        MOVE_Aipd_Aipd WORD dx NO
        Next    14

Do_MOVE_L_Aipd_To_Aipd:
        MOVE_Aipd_Aipd DWORD edx NO
        Next    22


; [fold]  ]

; [fold]  [
; MOVE -(Ax),d(Ax)

MACRO MOVE_Aipd_Ai16 siz, reg
        prof    _Optimized_MOVE

        mov     ebx,eax
        shr     eax,9
        and     ebx,7
        and     eax,7

        sub     [_A + ebx*4],siz                ; inc
        mov     edi,[_A + ebx*4]                ; source adr.

        mov     bx,[esi+ebp]
        add     esi,2
        rol     bx,8

        IFIDN <siz>,<BYTE>
                Read_B
                movsx   edi,bx
                mov     [_V],0
                add     edi,[_A+eax*4]
                Write_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
                movsx   edi,bx
                mov     [_V],0
                add     edi,[_A+eax*4]
                Write_W
        ELSE
                Read_L
                movsx   edi,bx
                mov     [_V],0
                add     edi,[_A+eax*4]
                Write_L
        ENDIF
        ENDIF
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aipd_To_Ai16:
        MOVE_Aipd_Ai16 BYTE dl
        Next    18

Do_MOVE_W_Aipd_To_Ai16:
        MOVE_Aipd_Ai16 WORD dx
        Next    18

Do_MOVE_L_Aipd_To_Ai16:
        MOVE_Aipd_Ai16 DWORD edx
        Next    26


; [fold]  ]

; [fold]  [
; MOVE -(Ax),AbsL

MACRO MOVE_Aipd_AbsL siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        and     ebx,7           ;source register
        and     eax,7           ;(Ax)
        sub     [_A+ebx*4],siz
        mov     edi,[_A+ebx*4]  ;EDI = Ax + offset

        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        mov     edi,[esi+ebp]
        add     esi,4
        bswap   edi
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Aipd_To_AbsL:
        MOVE_Aipd_AbsL BYTE dl
        Write_B
        Next    20

Do_MOVE_W_Aipd_To_AbsL:
        MOVE_Aipd_AbsL WORD dx
        Write_W
        Next    20

Do_MOVE_L_Aipd_To_AbsL:
        MOVE_Aipd_AbsL DWORD edx
        Write_L
        Next    28


; [fold]  ]


;************************************************************ MOVE d(Ax),...

; [fold]  [
; MOVE d(Ax),Dx

MACRO MOVE_Ai16_Dx siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        mov     dx,[esi+ebp]    ;offset
        and     eax,7           ;(Ax)
        rol     dx,8            ;low-high swap
        and     ebx,7           ;source register
        movsx   edi,dx          ;EDI = 16 bits offset
        add     esi,2           ;PC+=2
        add     edi,[_A+ebx*4]  ;EDI = Ax + offset

        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        mov     [_V],0
        mov     [siz PTR _D+eax*4],reg
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Ai16_To_Dx:
        MOVE_Ai16_Dx BYTE dl
        Next    12

Do_MOVE_W_Ai16_To_Dx:
        MOVE_Ai16_Dx WORD dx
        Next    12

Do_MOVE_L_Ai16_To_Dx:
        MOVE_Ai16_Dx DWORD edx
        Next    16


; [fold]  ]

; [fold]  [
; MOVEA d(Ax),Ax

Do_MOVEA_W_Ai16:
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        mov     dx,[esi+ebp]    ;offset
        rol     dx,8            ;low-high swap
        and     ebx,7           ;source register
        movsx   edi,dx          ;EDI = 16 bits offset
        add     esi,2           ;PC+=2
        add     edi,[_A+ebx*4]  ;EDI = Ax + offset
        Read_W
        movsx   edx,dx
        and     eax,7           ;(Ax)
        mov     [_A+eax*4],edx
        Next    12

Do_MOVEA_L_Ai16:
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        mov     dx,[esi+ebp]    ;offset
        rol     dx,8            ;low-high swap
        and     ebx,7           ;source register
        movsx   edi,dx          ;EDI = 16 bits offset
        add     esi,2           ;PC+=2
        add     edi,[_A+ebx*4]  ;EDI = Ax + offset
        Read_L
        and     eax,7           ;(Ax)
        mov     [_A+eax*4],edx
        Next    16


; [fold]  ]

; [fold]  [
; MOVE d(Ax),(Ax)

MACRO MOVE_Ai16_Aind siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        mov     dx,[esi+ebp]    ;offset
        and     eax,7           ;(Ax)
        rol     dx,8            ;low-high swap
        and     ebx,7           ;source register
        movsx   edi,dx          ;EDI = 16 bits offset
        add     esi,2           ;PC+=2
        add     edi,[_A+ebx*4]  ;EDI = Ax + offset

        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        mov     edi,[_A + eax*4]
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Ai16_To_Aind:
        MOVE_Ai16_Aind BYTE dl
        Write_B
        Next    16

Do_MOVE_W_Ai16_To_Aind:
        MOVE_Ai16_Aind WORD dx
        Write_W
        Next    16

Do_MOVE_L_Ai16_To_Aind:
        MOVE_Ai16_Aind DWORD edx
        Write_L
        Next    24


; [fold]  ]

; [fold]  [
; MOVE d(Ax),(Ax)+

MACRO MOVE_Ai16_Aipi siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        mov     dx,[esi+ebp]    ;offset
        and     eax,7           ;(Ax)
        rol     dx,8            ;low-high swap
        and     ebx,7           ;source register
        movsx   edi,dx          ;EDI = 16 bits offset
        add     esi,2           ;PC+=2
        add     edi,[_A+ebx*4]  ;EDI = Ax + offset

        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        mov     edi,[_A + eax*4]
        add     [_A + eax*4],siz
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Ai16_To_Aipi:
        MOVE_Ai16_Aipi BYTE dl
        Write_B
        Next    16

Do_MOVE_W_Ai16_To_Aipi:
        MOVE_Ai16_Aipi WORD dx
        Write_W
        Next    16

Do_MOVE_L_Ai16_To_Aipi:
        MOVE_Ai16_Aipi DWORD edx
        Write_L
        Next    24


; [fold]  ]

; [fold]  [
; MOVE d(Ax),-(Ax)

MACRO MOVE_Ai16_Aipd siz, reg, isa7
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        mov     dx,[esi+ebp]    ;offset
        and     eax,7           ;(Ax)
        rol     dx,8            ;low-high swap
        and     ebx,7           ;source register
        movsx   edi,dx          ;EDI = 16 bits offset
        add     esi,2           ;PC+=2
        add     edi,[_A+ebx*4]  ;EDI = Ax + offset

        IFIDN <siz>,<BYTE>
                IFIDN <isa7>,<YES>              ; spec: A7 dest
                        dec     [_A+eax*4]
                ENDIF
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        sub     [_A + eax*4],siz
        mov     edi,[_A + eax*4]
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Ai16_A7pd:
        MOVE_Ai16_Aipd BYTE dl YES
        Write_B
        Next    16

Do_MOVE_B_Ai16_To_Aipd:
        MOVE_Ai16_Aipd BYTE dl NO
        Write_B
        Next    16

Do_MOVE_W_Ai16_To_Aipd:
        MOVE_Ai16_Aipd WORD dx NO
        Write_W
        Next    16

Do_MOVE_L_Ai16_To_Aipd:
        MOVE_Ai16_Aipd DWORD edx NO
        Write_L
        Next    24


; [fold]  ]

; [fold]  [
; MOVE d(Ax),d(Ax)

MACRO MOVE_Ai16_Ai16 siz, reg
        prof    _Optimized_MOVE
        mov     ebx,eax
        shr     eax,9
        mov     dx,[esi+ebp]    ;offset
        mov     cx,[esi+ebp+2]
        and     eax,7           ;(Ax)
        rol     dx,8            ;low-high swap
        rol     cx,8
        and     ebx,7           ;source register
        movsx   edi,dx          ;EDI = 16 bits offset
        add     esi,4           ;PC+=2
        add     edi,[_A+ebx*4]  ;EDI = Ax + offset

        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        movsx   edi,cx
        mov     [_V],0
        add     edi,[_A + eax*4]
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Ai16_To_Ai16:
        MOVE_Ai16_Ai16 BYTE dl
        Write_B
        Next    20

Do_MOVE_W_Ai16_To_Ai16:
        MOVE_Ai16_Ai16 WORD dx
        Write_W
        Next    20

Do_MOVE_L_Ai16_To_Ai16:
        MOVE_Ai16_Ai16 DWORD edx
        Write_L
        Next    28


; [fold]  ]

; [fold]  [
; MOVE d(Ax),Abs.L

MACRO MOVE_Ai16_AbsL siz, reg
        prof    _Optimized_MOVE

        mov     dx,[esi+ebp]    ;offset
        and     eax,7           ;(Ax)
        rol     dx,8            ;low-high swap
        add     esi,2           ;PC+=2
        movsx   edi,dx          ;EDI = 16 bits offset
        mov     [_V],0
        add     edi,[_A+eax*4]  ;EDI = Ax + offset

        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        mov     edi,[esi+ebp]
        or      reg,reg
        Set_Flags_NZC
        add     esi,4
        bswap   edi
        ENDM

Do_MOVE_B_Ai16_To_AbsL:
        MOVE_Ai16_AbsL BYTE dl
        Write_B
        Next    24

Do_MOVE_W_Ai16_To_AbsL:
        MOVE_Ai16_AbsL WORD dx
        Write_W
        Next    24

Do_MOVE_L_Ai16_To_AbsL:
        MOVE_Ai16_AbsL DWORD edx
        Write_L
        Next    32


; [fold]  ]



;*********************************************************** MOVE Abs.L,...

; [fold]  [
; MOVE Abs.L,Dx

MACRO MOVE_AbsL_Dx siz, reg
        prof    _Optimized_MOVE

        mov     edi,[esi+ebp]
        shr     eax,9
        bswap   edi
        add     esi,4
        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        and     eax,7
        mov     [_V],0
        mov     [siz PTR _D+eax*4],reg
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_AbsL_To_Dx:
        MOVE_AbsL_Dx BYTE dl
        Next    16

Do_MOVE_W_AbsL_To_Dx:
        MOVE_AbsL_Dx WORD dx
        Next    16

Do_MOVE_L_AbsL_To_Dx:

        MOVE_AbsL_Dx DWORD edx
        Next    20


; [fold]  ]

; [fold]  [
; MOVEA Abs.L,Ax

Do_MOVEA_W_AbsL:
        prof    _Optimized_MOVE

        mov     edi,[esi+ebp]
        shr     eax,9
        bswap   edi
        add     esi,4
        Read_W
        movsx   edx,dx
        and     eax,7
        mov     [_A+eax*4],edx
        Next    16

Do_MOVEA_L_AbsL:
        prof    _Optimized_MOVE

        mov     edi,[esi+ebp]
        shr     eax,9
        bswap   edi
        add     esi,4
        Read_L
        and     eax,7
        mov     [_A+eax*4],edx
        Next    20


; [fold]  ]

; [fold]  [
; MOVE Abs.L,(Ax)

MACRO MOVE_AbsL_Aind siz, reg
        prof    _Optimized_MOVE

        mov     edi,[esi+ebp]
        shr     eax,9
        bswap   edi
        add     esi,4
        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        and     eax,7
        mov     [_V],0
        mov     edi,[_A+eax*4]
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_AbsL_To_Aind:
        MOVE_AbsL_Aind BYTE dl
        Write_B
        Next    20

Do_MOVE_W_AbsL_To_Aind:
        MOVE_AbsL_Aind WORD dx
        Write_W
        Next    20

Do_MOVE_L_AbsL_To_Aind:
        MOVE_AbsL_Aind DWORD edx
        Write_L
        Next    28


; [fold]  ]

; [fold]  [
; MOVE Abs.L,(Ax)+

MACRO MOVE_AbsL_Aipi siz, reg
        prof    _Optimized_MOVE

        mov     edi,[esi+ebp]
        shr     eax,9
        bswap   edi
        add     esi,4
        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        and     eax,7
        mov     [_V],0
        mov     edi,[_A+eax*4]
        add     [_A+eax*4],siz
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_AbsL_To_Aipi:
        MOVE_AbsL_Aipi BYTE dl
        Write_B
        Next    20

Do_MOVE_W_AbsL_To_Aipi:
        MOVE_AbsL_Aipi WORD dx
        Write_W
        Next    20

Do_MOVE_L_AbsL_To_Aipi:
        MOVE_AbsL_Aipi DWORD edx
        Write_L
        Next    28


; [fold]  ]

; [fold]  [
; MOVE Abs.L,-(Ax)

MACRO MOVE_AbsL_Aipd siz, reg
        prof    _Optimized_MOVE

        mov     edi,[esi+ebp]
        shr     eax,9
        bswap   edi
        add     esi,4
        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        and     eax,7
        mov     [_V],0
        sub     [_A+eax*4],siz
        or      reg,reg
        mov     edi,[_A+eax*4]
        Set_Flags_NZC
        ENDM

Do_MOVE_B_AbsL_To_Aipd:
        MOVE_AbsL_Aipd BYTE dl
        Write_B
        Next    20

Do_MOVE_W_AbsL_To_Aipd:
        MOVE_AbsL_Aipd WORD dx
        Write_W
        Next    20

Do_MOVE_L_AbsL_To_Aipd:
        MOVE_AbsL_Aipd DWORD edx
        Write_L
        Next    28


; [fold]  ]

; [fold]  [
; MOVE Abs.L,d(Ax)

MACRO MOVE_AbsL_Ai16 siz, reg
        prof    _Optimized_MOVE

        mov     edi,[esi+ebp]
        mov     bx,[esi+ebp+4]
        shr     eax,9
        bswap   edi
        add     esi,6
        rol     bx,8
        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        movsx   edi,bx
        and     eax,7
        mov     [_V],0
        add     edi,[_A+eax*4]
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_AbsL_To_Ai16:
        MOVE_AbsL_Ai16 BYTE dl
        Write_B
        Next    24

Do_MOVE_W_AbsL_To_Ai16:
        MOVE_AbsL_Ai16 WORD dx
        Write_W
        Next    24

Do_MOVE_L_AbsL_To_Ai16:
        MOVE_AbsL_Ai16 DWORD edx
        Write_L
        Next    32


; [fold]  ]

; [fold]  [
; MOVE Abs.L,AbsL

MACRO MOVE_AbsL_AbsL siz, reg
        prof    _Optimized_MOVE

        mov     edi,[esi+ebp]
        shr     eax,9
        bswap   edi
        mov     [_V],0
        IFIDN <siz>,<BYTE>
                Read_B
        ELSE
        IFIDN <siz>,<WORD>
                Read_W
        ELSE
                Read_L
        ENDIF
        ENDIF

        mov     edi,[esi+ebp+4]
        or      reg,reg
        Set_Flags_NZC
        bswap   edi
        add     esi,8
        ENDM

Do_MOVE_B_AbsL_To_AbsL:
        MOVE_AbsL_AbsL BYTE dl
        Write_B
        Next    20

Do_MOVE_W_AbsL_To_AbsL:
        MOVE_AbsL_AbsL WORD dx
        Write_W
        Next    20

Do_MOVE_L_AbsL_To_AbsL:
        MOVE_AbsL_AbsL DWORD edx
        Write_L
        Next    28


; [fold]  ]


;*********************************************************** MOVE #Imm,...

; [fold]  [
; MOVE #Imm,Dx

MACRO MOVE_Imm_Dx siz, reg
        prof    _Optimized_MOVE

        shr     eax,9

        IFIDN <siz>,<BYTE>
                mov     dl,[esi+ebp+1]
                add     esi,2
        ELSE
        IFIDN <siz>,<WORD>
                mov     dx,[esi+ebp]
                add     esi,2
                rol     dx,8
        ELSE
                mov     edx,[esi+ebp]
                add     esi,4
                bswap   edx
        ENDIF
        ENDIF

        and     eax,7
        or      reg,reg
        mov     [siz PTR _D + eax*4],reg
        Set_Flags_NZC
        mov     [_V],0
        ENDM

Do_MOVE_B_Imm_To_Dx:
        MOVE_Imm_Dx BYTE dl
        Next    8

Do_MOVE_W_Imm_To_Dx:
        MOVE_Imm_Dx WORD dx
        Next    8

Do_MOVE_L_Imm_To_Dx:
        MOVE_Imm_Dx DWORD edx
        Next    12



; [fold]  ]

; [fold]  [
; MOVEA #Imm,Ax

MACRO MOVE_Imm_Dx siz, reg
        ENDM

Do_MOVEA_W_Imm:
        prof    _Optimized_MOVE

        shr     eax,9
        mov     dx,[esi+ebp]
        add     esi,2
        rol     dx,8
        and     eax,7
        movsx   edx,dx
        mov     [_A + eax*4],edx
        Next    8

Do_MOVEA_L_Imm:
        prof    _Optimized_MOVE

        shr     eax,9

        mov     edx,[esi+ebp]
        add     esi,4
        bswap   edx
        and     eax,7
        mov     [_A + eax*4],edx
        Next    12



; [fold]  ]

; [fold]  [
; MOVE #Imm,(Ax)

MACRO MOVE_Imm_Aind siz, reg
        prof    _Optimized_MOVE

        shr     eax,9

        IFIDN <siz>,<BYTE>
                mov     dl,[esi+ebp+1]
                add     esi,2
        ELSE
        IFIDN <siz>,<WORD>
                mov     dx,[esi+ebp]
                add     esi,2
                rol     dx,8
        ELSE
                mov     edx,[esi+ebp]
                add     esi,4
                bswap   edx
        ENDIF
        ENDIF

        and     eax,7
        or      reg,reg
        mov     edi,[_A+eax*4]
        Set_Flags_NZC
        mov     [_V],0
        ENDM

Do_MOVE_B_Imm_To_Aind:
        MOVE_Imm_Aind BYTE dl
        Write_B
        Next    12

Do_MOVE_W_Imm_To_Aind:
        MOVE_Imm_Aind WORD dx
        Write_W
        Next    12

Do_MOVE_L_Imm_To_Aind:
        MOVE_Imm_Aind DWORD edx
        Write_L
        Next    20



; [fold]  ]

; [fold]  [
; MOVE #Imm,(Ax)+

MACRO MOVE_Imm_Aipi siz, reg
        prof    _Optimized_MOVE

        shr     eax,9

        IFIDN <siz>,<BYTE>
                mov     dl,[esi+ebp+1]
                add     esi,2
        ELSE
        IFIDN <siz>,<WORD>
                mov     dx,[esi+ebp]
                add     esi,2
                rol     dx,8
        ELSE
                mov     edx,[esi+ebp]
                add     esi,4
                bswap   edx
        ENDIF
        ENDIF

        and     eax,7
        mov     [_V],0
        mov     edi,[_A+eax*4]
        add     [_A+eax*4],siz
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Imm_To_Aipi:
        MOVE_Imm_Aipi BYTE dl
        Write_B
        Next    12

Do_MOVE_W_Imm_To_Aipi:
        MOVE_Imm_Aipi WORD dx
        Write_W
        Next    12

Do_MOVE_L_Imm_To_Aipi:
        MOVE_Imm_Aipi DWORD edx
        Write_L
        Next    20



; [fold]  ]

; [fold]  [
; MOVE #Imm,-(Ax)

MACRO MOVE_Imm_Aipd siz, reg, isA7
        prof    _Optimized_MOVE

        shr     eax,9
        mov     [_V],0
        and     eax,7

        IFIDN <siz>,<BYTE>
                mov     dl,[esi+ebp+1]
                add     esi,2
                dec     [_A+eax*4]
                IFIDN <isA7>,<YES>
                        dec     [_A+eax*4]
                ENDIF
        ELSE
        IFIDN <siz>,<WORD>
                mov     dx,[esi+ebp]
                add     esi,2
                rol     dx,8
                sub     [_A+eax*4],2
        ELSE
                mov     edx,[esi+ebp]
                add     esi,4
                bswap   edx
                sub     [_A+eax*4],4
        ENDIF
        ENDIF

        or      reg,reg
        mov     edi,[_A+eax*4]
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Imm_A7pd:
        MOVE_Imm_Aipd BYTE dl YES
        Write_B
        Next    12

Do_MOVE_B_Imm_To_Aipd:
        MOVE_Imm_Aipd BYTE dl NO
        Write_B
        Next    12

Do_MOVE_W_Imm_To_Aipd:
        MOVE_Imm_Aipd WORD dx NO
        Write_W
        Next    12

Do_MOVE_L_Imm_To_Aipd:
        MOVE_Imm_Aipd DWORD edx NO
        Write_L
        Next    20



; [fold]  ]

; [fold]  [
; MOVE #Imm,d(Ax)

MACRO MOVE_Imm_Ai16 siz, reg
        prof    _Optimized_MOVE

        shr     eax,9

        IFIDN <siz>,<BYTE>
                mov     dl,[esi+ebp+1]
                mov     bx,[esi+ebp+2]
                add     esi,2+2
        ELSE
        IFIDN <siz>,<WORD>
                mov     dx,[esi+ebp]
                mov     bx,[esi+ebp+2]
                add     esi,2+2
                rol     dx,8
        ELSE
                mov     edx,[esi+ebp]
                mov     bx,[esi+ebp+4]
                add     esi,4+2
                bswap   edx
        ENDIF
        ENDIF

        rol     bx,8
        and     eax,7
        movsx   edi,bx
        or      reg,reg
        add     edi,[_A+eax*4]
        Set_Flags_NZC
        mov     [_V],0


        ENDM

Do_MOVE_B_Imm_To_Ai16:
        MOVE_Imm_Ai16 BYTE dl
        Write_B
        Next    16

Do_MOVE_W_Imm_To_Ai16:
        MOVE_Imm_Ai16 WORD dx
        Write_W
        Next    16

Do_MOVE_L_Imm_To_Ai16:
        MOVE_Imm_Ai16 DWORD edx
        Write_L
        Next    24



; [fold]  ]

; [fold]  [
; MOVE #Imm,Abs.L

MACRO MOVE_Imm_AbsL siz, reg
        prof    _Optimized_MOVE

        IFIDN <siz>,<BYTE>
                mov     dl,[esi+ebp+1]
                mov     edi,[esi+ebp+2]
                add     esi,6
        ELSE
        IFIDN <siz>,<WORD>
                mov     dx,[esi+ebp]
                mov     edi,[esi+ebp+2]
                add     esi,6
                rol     dx,8
        ELSE
                mov     edx,[esi+ebp]
                mov     edi,[esi+ebp+4]
                add     esi,8
                bswap   edx
        ENDIF
        ENDIF

        bswap   edi
        mov     [_V],0
        or      reg,reg
        Set_Flags_NZC
        ENDM

Do_MOVE_B_Imm_To_AbsL:
        MOVE_Imm_AbsL BYTE dl
        Write_B
        Next    16

Do_MOVE_W_Imm_To_AbsL:
        MOVE_Imm_AbsL WORD dx
        Write_W
        Next    16

Do_MOVE_L_Imm_To_AbsL:
        MOVE_Imm_AbsL DWORD edx
        Write_L
        Next    24



; [fold]  ]


;***************************************************************************
;*
;*                            INITIALISATIONS
;*
;***************************************************************************

PROC Init_Special_Moves NEAR

        lea     esi,[List_Special_MOVE]
@@allspec:
        mov     edi,[esi+8]             ;Do_MOVE_B_...
        or      edi,edi
        jz      @@noB
        mov     edx,01000h
        call    Add_Special_Moves
@@noB:
        mov     edi,[esi+12]            ;Do_MOVE_W_...
        mov     edx,03000h
        call    Add_Special_Moves

        mov     edi,[esi+16]            ;Do_MOVE_L_...
        mov     edx,02000h
        call    Add_Special_Moves

        add     esi,20
        cmp     esi,OFFSET End_List_Special_MOVE
        jnz     @@allspec

;------------------------------------------ special cases: move.b ....,-(a7)

        lea     edi,[Do_MOVE_B_Dx_A7pd]
        mov     eax,01f00h              ;init mask (for all 8 registers)
        call    Add_Special_Moves_A7

        lea     edi,[Do_MOVE_B_Aind_A7pd]
        mov     eax,1f10h
        call    Add_Special_Moves_A7

        lea     edi,[Do_MOVE_B_Aipi_A7pd]
        mov     eax,1f18h
        call    Add_Special_Moves_A7

        lea     edi,[Do_MOVE_B_Aipd_A7pd]
        mov     eax,1f20h
        call    Add_Special_Moves_A7

        lea     edi,[Do_MOVE_B_Ai16_A7pd]
        mov     eax,1f28h
        call    Add_Special_Moves_A7

        mov     [Opcodes_Jump+01f3ch*4],OFFSET Do_MOVE_B_Imm_A7pd
        ret
        ENDP

PROC Add_Special_Moves_A7 NEAR
        mov     ecx,8
@@a7spec:
        mov     [Opcodes_Jump+eax*4],edi
        inc     eax
        dec     ecx
        jnz     @@a7spec
        ret
        ENDP

PROC Add_Special_Moves NEAR
                                ;EDI : function
                                ;EDX : global mask
                                ;[esi+0].w init mask destination
                                ;[esi+2].w nb mask destination
                                ;[esi+4].w init mask source
                                ;[esi+6].w nb mask source
        mov     bx,[esi]
        shl     bx,6
        mov     cx,[esi+2]
@@desti:
        push    edx
        or      dx,bx           ;edx = mask with destination
        push    ecx
        push    ebx

        mov     bx,[esi+4]
        mov     cx,[esi+6]
@@src:
        mov     eax,edx
        or      ax,bx
        mov     [Opcodes_Jump+eax*4],edi

        inc     bx
        dec     cx
        jnz     @@src

        pop     ebx
        pop     ecx
        pop     edx
        add     bx,200h
        dec     cx
        jnz     @@desti
        ret
        ENDP

        DATASEG

all = 8
one = 1

LABEL List_Special_MOVE
                                ; global mask
                                ; adressing mode & nb regs for destination mode
                                ; adressing mode & nb regs for source mode

        dw      0,all,0,all                   ; Dx,Dx
        dd      Do_MOVE_B_Dx_To_Dx
        dd      Do_MOVE_W_Dx_To_Dx
        dd      Do_MOVE_L_Dx_To_Dx
        dw      1,all,0,all                   ; Dx,Ax
        dd      0
        dd      Do_MOVEA_W_Dx
        dd      Do_MOVEA_L_Dx
        dw      02h,all,0,all                 ; Dx,(Ax)
        dd      Do_MOVE_B_Dx_To_Aind
        dd      Do_MOVE_W_Dx_To_Aind
        dd      Do_MOVE_L_Dx_To_Aind
        dw      03h,all,0,all                 ; Dx,(Ax)+
        dd      Do_MOVE_B_Dx_To_Aipi
        dd      Do_MOVE_W_Dx_To_Aipi
        dd      Do_MOVE_L_Dx_To_Aipi
        dw      04h,all,0,all                 ; Dx,-(Ax)
        dd      Do_MOVE_B_Dx_To_Aipd
        dd      Do_MOVE_W_Dx_To_Aipd
        dd      Do_MOVE_L_Dx_To_Aipd
        dw      05h,all,0,all                ; Dx,d(Ax)
        dd      Do_MOVE_B_Dx_To_Ai16
        dd      Do_MOVE_W_Dx_To_Ai16
        dd      Do_MOVE_L_Dx_To_Ai16
        dw      07h,one,0,all                ; Dx,Abs.w
        dd      Do_MOVE_B_Dx_To_AbsW
        dd      Do_MOVE_W_Dx_To_AbsW
        dd      Do_MOVE_L_Dx_To_AbsW
        dw      0fh,one,0,all                ; Dx,Abs.l
        dd      Do_MOVE_B_Dx_To_AbsL
        dd      Do_MOVE_W_Dx_To_AbsL
        dd      Do_MOVE_L_Dx_To_AbsL

        dw      0,all,08h,all                ; Ax,Dx
        dd      0
        dd      Do_MOVE_W_Ax_To_Dx
        dd      Do_MOVE_L_Ax_To_Dx
        dw      1,all,8,all                  ; Ax,Ax
        dd      0
        dd      Do_MOVEA_W_Ax
        dd      Do_MOVEA_L_Ax
        dw      02h,all,08h,all              ; Ax,(Ax)
        dd      0
        dd      Do_MOVE_W_Ax_To_Aind
        dd      Do_MOVE_L_Ax_To_Aind
        dw      03h,all,08h,all              ; Ax,(Ax)+
        dd      0
        dd      Do_MOVE_W_Ax_To_Aipi
        dd      Do_MOVE_L_Ax_To_Aipi
        dw      04h,all,08h,all              ; Ax,-(Ax)
        dd      0
        dd      Do_MOVE_W_Ax_To_Aipd
        dd      Do_MOVE_L_Ax_To_Aipd
        dw      05h,all,8,all                ; Ax,d(Ax)
        dd      0
        dd      Do_MOVE_W_Ax_To_Ai16
        dd      Do_MOVE_L_Ax_To_Ai16
        dw      07h,one,8,all                ; Ax,Abs.w
        dd      0
        dd      Do_MOVE_W_Ax_To_AbsW
        dd      Do_MOVE_L_Ax_To_AbsW
        dw      0fh,one,8,all                ; Ax,Abs.l
        dd      0
        dd      Do_MOVE_W_Ax_To_AbsL
        dd      Do_MOVE_L_Ax_To_AbsL




        dw      0,all,10h,all                 ; (Ax),Dx
        dd      Do_MOVE_B_Aind_To_Dx
        dd      Do_MOVE_W_Aind_To_Dx
        dd      Do_MOVE_L_Aind_To_Dx
        dw      1,all,10h,all                 ; (Ax),Ax
        dd      0
        dd      Do_MOVEA_W_Aind
        dd      Do_MOVEA_L_Aind
        dw      02h,all,10h,all               ; (Ax),(Ax)
        dd      Do_MOVE_B_Aind_To_Aind
        dd      Do_MOVE_W_Aind_To_Aind
        dd      Do_MOVE_L_Aind_To_Aind
        dw      03h,all,10h,all               ; (Ax),(Ax)+
        dd      Do_MOVE_B_Aind_To_Aipi
        dd      Do_MOVE_W_Aind_To_Aipi
        dd      Do_MOVE_L_Aind_To_Aipi
        dw      04h,all,10h,all               ; (Ax),-(Ax)
        dd      Do_MOVE_B_Aind_To_Aipd
        dd      Do_MOVE_W_Aind_To_Aipd
        dd      Do_MOVE_L_Aind_To_Aipd
        dw      05h,all,010h,all              ; (Ax),d(Ax)
        dd      Do_MOVE_B_Aind_To_Ai16
        dd      Do_MOVE_W_Aind_To_Ai16
        dd      Do_MOVE_L_Aind_To_Ai16
        dw      0fh,one,010h,all              ; (Ax),Abs.L
        dd      Do_MOVE_B_Aind_To_AbsL
        dd      Do_MOVE_W_Aind_To_AbsL
        dd      Do_MOVE_L_Aind_To_AbsL


        dw      0,all,18h,all                 ; (Ax)+,Dx
        dd      Do_MOVE_B_Aipi_To_Dx
        dd      Do_MOVE_W_Aipi_To_Dx
        dd      Do_MOVE_L_Aipi_To_Dx
        dw      1,all,18h,all                 ; (Ax)+,Ax
        dd      0
        dd      Do_MOVEA_W_Aipi
        dd      Do_MOVEA_L_Aipi
        dw      02h,all,018h,all              ; (Ax)+,(Ax)
        dd      Do_MOVE_B_Aipi_To_Aind
        dd      Do_MOVE_W_Aipi_To_Aind
        dd      Do_MOVE_L_Aipi_To_Aind
        dw      03h,all,018h,all              ; (Ax)+,(Ax)+
        dd      Do_MOVE_B_Aipi_To_Aipi
        dd      Do_MOVE_W_Aipi_To_Aipi
        dd      Do_MOVE_L_Aipi_To_Aipi
        dw      04h,all,018h,all              ; (Ax)+,-(Ax)
        dd      Do_MOVE_B_Aipi_To_Aipd
        dd      Do_MOVE_W_Aipi_To_Aipd
        dd      Do_MOVE_L_Aipi_To_Aipd
        dw      05h,all,018h,all              ; (Ax)+,d(Ax)
        dd      Do_MOVE_B_Aipi_To_Ai16
        dd      Do_MOVE_W_Aipi_To_Ai16
        dd      Do_MOVE_L_Aipi_To_Ai16
        dw      0fh,one,018h,all              ; (Ax)+,Abs.L
        dd      Do_MOVE_B_Aipi_To_AbsL
        dd      Do_MOVE_W_Aipi_To_AbsL
        dd      Do_MOVE_L_Aipi_To_AbsL

        dw      0,all,20h,all                 ; -(Ax),Dx
        dd      Do_MOVE_B_Aipd_To_Dx
        dd      Do_MOVE_W_Aipd_To_Dx
        dd      Do_MOVE_L_Aipd_To_Dx
        dw      1,all,20h,all                 ; -(Ax),Ax
        dd      0
        dd      Do_MOVEA_W_Aipd
        dd      Do_MOVEA_L_Aipd
        dw      02h,all,020h,all              ; -(Ax),(Ax)
        dd      Do_MOVE_B_Aipd_To_Aind
        dd      Do_MOVE_W_Aipd_To_Aind
        dd      Do_MOVE_L_Aipd_To_Aind
        dw      03h,all,020h,all              ; -(Ax),(Ax)+
        dd      Do_MOVE_B_Aipd_To_Aipi
        dd      Do_MOVE_W_Aipd_To_Aipi
        dd      Do_MOVE_L_Aipd_To_Aipi
        dw      04h,all,020h,all              ; -(Ax),-(Ax)
        dd      Do_MOVE_B_Aipd_To_Aipd
        dd      Do_MOVE_W_Aipd_To_Aipd
        dd      Do_MOVE_L_Aipd_To_Aipd
        dw      05h,all,020h,all              ; -(Ax),d(Ax)
        dd      Do_MOVE_B_Aipd_To_Ai16
        dd      Do_MOVE_W_Aipd_To_Ai16
        dd      Do_MOVE_L_Aipd_To_Ai16
        dw      0fh,one,020h,all              ; -(Ax),Abs.L
        dd      Do_MOVE_B_Aipd_To_AbsL
        dd      Do_MOVE_W_Aipd_To_AbsL
        dd      Do_MOVE_L_Aipd_To_AbsL



        dw      0,all,28h,all                 ; d(Ax),Dx
        dd      Do_MOVE_B_Ai16_To_Dx
        dd      Do_MOVE_W_Ai16_To_Dx
        dd      Do_MOVE_L_Ai16_To_Dx
        dw      1,all,28h,all                 ; d(Ax),Ax
        dd      0
        dd      Do_MOVEA_W_Ai16
        dd      Do_MOVEA_L_Ai16
        dw      02h,all,28h,all               ; d(Ax),(Ax)
        dd      Do_MOVE_B_Ai16_To_Aind
        dd      Do_MOVE_W_Ai16_To_Aind
        dd      Do_MOVE_L_Ai16_To_Aind
        dw      03h,all,28h,all               ; d(Ax),(Ax)+
        dd      Do_MOVE_B_Ai16_To_Aipi
        dd      Do_MOVE_W_Ai16_To_Aipi
        dd      Do_MOVE_L_Ai16_To_Aipi
        dw      04h,all,28h,all               ; d(Ax),-(Ax)
        dd      Do_MOVE_B_Ai16_To_Aipd
        dd      Do_MOVE_W_Ai16_To_Aipd
        dd      Do_MOVE_L_Ai16_To_Aipd
        dw      05h,all,28h,all               ; d(Ax),d(Ax)
        dd      Do_MOVE_B_Ai16_To_Ai16
        dd      Do_MOVE_W_Ai16_To_Ai16
        dd      Do_MOVE_L_Ai16_To_Ai16
        dw      0fh,one,28h,all               ; d(Ax),Abs.L
        dd      Do_MOVE_B_Ai16_To_AbsL
        dd      Do_MOVE_W_Ai16_To_AbsL
        dd      Do_MOVE_L_Ai16_To_AbsL



        dw      0,all,39h,one                 ; Abs.l,Dx
        dd      Do_MOVE_B_AbsL_To_Dx
        dd      Do_MOVE_W_AbsL_To_Dx
        dd      Do_MOVE_L_AbsL_To_Dx
        dw      1,all,39h,one                 ; Abs.l,Ax
        dd      0
        dd      Do_MOVEA_W_AbsL
        dd      Do_MOVEA_L_AbsL
        dw      02h,all,39h,one               ; Abs.l,(Ax)
        dd      Do_MOVE_B_AbsL_To_Aind
        dd      Do_MOVE_W_AbsL_To_Aind
        dd      Do_MOVE_L_AbsL_To_Aind
        dw      03h,all,39h,one               ; Abs.l,(Ax)+
        dd      Do_MOVE_B_AbsL_To_Aipi
        dd      Do_MOVE_W_AbsL_To_Aipi
        dd      Do_MOVE_L_AbsL_To_Aipi
        dw      04h,all,39h,one               ; Abs.l,-(Ax)
        dd      Do_MOVE_B_AbsL_To_Aipd
        dd      Do_MOVE_W_AbsL_To_Aipd
        dd      Do_MOVE_L_AbsL_To_Aipd
        dw      05h,all,39h,one               ; Abs.l,d(Ax)
        dd      Do_MOVE_B_AbsL_To_Ai16
        dd      Do_MOVE_W_AbsL_To_Ai16
        dd      Do_MOVE_L_AbsL_To_Ai16
        dw      0fh,one,39h,one               ; Abs.l,Abs.L
        dd      Do_MOVE_B_AbsL_To_AbsL
        dd      Do_MOVE_W_AbsL_To_AbsL
        dd      Do_MOVE_L_AbsL_To_AbsL



        dw      0,all,3ch,one                 ; #imm,Dx
        dd      Do_MOVE_B_Imm_To_Dx
        dd      Do_MOVE_W_Imm_To_Dx
        dd      Do_MOVE_L_Imm_To_Dx
        dw      1,all,3ch,one                 ; #imm,Ax
        dd      0
        dd      Do_MOVEA_W_Imm
        dd      Do_MOVEA_L_Imm
        dw      02h,all,3ch,one               ; #imm,(Ax)
        dd      Do_MOVE_B_Imm_To_Aind
        dd      Do_MOVE_W_Imm_To_Aind
        dd      Do_MOVE_L_Imm_To_Aind
        dw      03h,all,3ch,one               ; #imm,(Ax)+
        dd      Do_MOVE_B_Imm_To_Aipi
        dd      Do_MOVE_W_Imm_To_Aipi
        dd      Do_MOVE_L_Imm_To_Aipi
        dw      04h,all,3ch,one               ; #imm,-(Ax)
        dd      Do_MOVE_B_Imm_To_Aipd
        dd      Do_MOVE_W_Imm_To_Aipd
        dd      Do_MOVE_L_Imm_To_Aipd

        dw      05h,all,3ch,one               ; #imm,d(Ax)
        dd      Do_MOVE_B_Imm_To_Ai16
        dd      Do_MOVE_W_Imm_To_Ai16
        dd      Do_MOVE_L_Imm_To_Ai16

        dw      0fh,one,3ch,one               ; #imm,Abs.L
        dd      Do_MOVE_B_Imm_To_AbsL
        dd      Do_MOVE_W_Imm_To_AbsL
        dd      Do_MOVE_L_Imm_To_AbsL

        dw      0,all,30h,all
        dd      Do_MOVE_B_Ai8d_To_Dx
        dd      Do_MOVE_W_Ai8d_To_Dx
        dd      Do_MOVE_L_Ai8d_To_Dx


LABEL End_List_Special_MOVE

        END

; [fold]  58
