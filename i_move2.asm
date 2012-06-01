COMMENT ~
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
ณ Emulation of MOVE type instructions                                      ณ
ณ                                                                          ณ
ณ       25/6/96  Converted all code to TASM IDEAL mode                     ณ
ณ        1/7/96  Start optimizing MOVEs functions                          ณ
ณ        9/3/97  Restarted some MOVEs from scratch                         ณ
ณ        9/3/97  Starting to optimize while not using EBX                  ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู


~
        IDEAL

        INCLUDE "simu68.inc"
        INCLUDE "profile.inc"

        CODESEG


       PUBLIC Do_MOVE_To_CCR, Do_MOVE_From_SR, Do_MOVE_To_SR
       PUBLIC Do_MOVEP_W_To_Mem, Do_MOVEP_L_To_Mem
       PUBLIC Do_MOVEP_W_From_Mem, Do_MOVEP_L_From_Mem
       PUBLIC Do_UNLK, Do_LINK
       PUBLIC Do_MOVE_From_USP, Do_MOVE_To_USP
       PUBLIC Do_EXG_Dx_Dx, Do_EXG_Ax_Ax, Do_EXG_Dx_Ax
       PUBLIC Do_CLR_B_Mem, Do_CLR_W_Mem, Do_CLR_L_Mem
       PUBLIC Do_CLR_B_Dx, Do_CLR_W_Dx, Do_CLR_L_Dx
       PUBLIC Do_Swap, Do_LEA, Do_PEA, Do_MOVEQ
       PUBLIC Do_General_MOVE_B, Do_General_MOVE_W,  Do_General_MOVE_L
       PUBLIC Do_Move_B_Dx_Dx, Do_Move_W_Rx_Dx, Do_Move_L_Rx_Dx
       PUBLIC Do_Move_B_Dx_Mem
       PUBLIC Do_Move_W_Rx_Mem, Do_Move_L_Rx_Mem, Do_Move_B_Mem_Dx
       PUBLIC Do_Move_W_Mem_Dx, Do_Move_L_Mem_Dx, Do_Move_B_Mem_Mem
       PUBLIC Do_Move_W_Mem_Mem, Do_Move_L_Mem_Mem
       PUBLIC Do_ST, Do_SF, Do_SHI, Do_SLS, Do_SCC, Do_SCS
       PUBLIC Do_SNE, Do_SEQ, Do_SVC, Do_SVS, Do_SPL, Do_SMI
       PUBLIC Do_SGE, Do_SLT, Do_SGT, Do_SLE
       PUBLIC Do_MOVEA_W_Rx
       PUBLIC Do_MOVEA_L_Rx, Do_MOVEA_W_mem, Do_MOVEA_L_mem

;        PUBLIC Init_Instructions_MOVES

;PROC Init_Instructions_MOVES NEAR
;        call    Init_Instruction_MOVE
;        call    Init_Instruction_MOVEA
;
;        call    Init_MOVE_Specific
;
;        call    Init_Instruction_MOVEQ
;        call    Init_Instruction_LEA_PEA
;        call    Init_Instruction_SWAP
;        call    Init_Instruction_CLR
;        call    Init_Instruction_EXG
;        call    Init_Instructions_Scc
;        call    Init_Instruction_MOVE_USP
;        call    Init_Instructions_LINK_UNLK
;        call    Init_Instruction_MOVEP
;        call    Init_Instructions_MOVE_ccr_sr
;        ret
;        ENDP



;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                   MOVE.B
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

PROC Do_Move_B_Dx_Dx NEAR
        mov     ebx,eax
        and     eax,7           ;source
        shr     ebx,9
        mov     [ebp+base.V],0
        and     ebx,7           ;destination
        mov     edx,[ebp+eax*4+base.D]
        or      dl,dl
        Set_Flags_NZC
        mov     [BYTE PTR ebp+ebx*4+base.D],dl
        Next    4
        ENDP

PROC Do_Move_W_Rx_Dx NEAR
        mov     ebx,eax
        and     eax,15           ;source
        shr     ebx,9
        mov     [ebp+base.V],0
        and     ebx,7           ;destination
        mov     edx,[ebp+eax*4+base.D]
        or      dx,dx
        Set_Flags_NZC
        mov     [WORD PTR ebp+ebx*4+base.D],dx
        Next    4
        ENDP

PROC Do_Move_L_Rx_Dx NEAR
        mov     ebx,eax
        and     eax,15           ;source
        shr     ebx,9
        mov     [ebp+base.V],0
        and     ebx,7           ;destination
        mov     edx,[ebp+eax*4+base.D]
        or      edx,edx
        Set_Flags_NZC
        mov     [ebp+ebx*4+base.D],edx
        Next    4
        ENDP

PROC Do_Move_B_Dx_Mem NEAR
        mov     ebx,eax
        mov     ecx,eax         ;Dx
        shr     ebx,9           ;registre
        shr     eax,3           ;mode
        and     ebx,7
        and     ecx,7           ;Dx (source)
        or      eax,ebx         ;mod:reg
        mov     [ebp+base.V],0
        Instr_To_EA_B
        mov     edx,[ebp+ecx*4+base.D]
        or      dl,dl
        Set_Flags_NZC
        Write_B
        Next 4
        ENDP

PROC Do_Move_W_Rx_Mem NEAR
        mov     ebx,eax
        mov     ecx,eax         ;Dx
        shr     ebx,9           ;registre
        shr     eax,3           ;mode
        and     ebx,7
        and     eax,038h
        and     ecx,15          ;Rx (source)
        or      eax,ebx         ;mod:reg
        mov     [ebp+base.V],0
        Instr_To_EA_W
        mov     edx,[ebp+ecx*4+base.D]
        or      dx,dx
        Set_Flags_NZC
        Write_W
        Next 4
        ENDP

PROC Do_Move_L_Rx_Mem NEAR
        mov     ebx,eax
        mov     ecx,eax         ;Dx
        shr     ebx,9           ;registre
        shr     eax,3           ;mode
        and     ebx,7
        and     eax,038h
        and     ecx,15          ;Rx (source)
        add     eax,ebx         ;mod:reg
        mov     [ebp+base.V],0
        Instr_To_EA_L
        mov     edx,[ebp+ecx*4+base.D]
        or      edx,edx
        Set_Flags_NZC
        Write_L
        Next    4
        ENDP

PROC Do_Move_B_Mem_Dx NEAR
        mov     ecx,eax         ;Dx
        Instr_To_EA_B
        shr     ecx,9
        mov     [ebp+base.V],0
        and     ecx,7
        Read_B
        mov     [BYTE PTR ebp+ecx*4+base.D],dl
        or      dl,dl
        Set_Flags_NZC
        Next    4
        ENDP

PROC Do_Move_W_Mem_Dx NEAR
        mov     ecx,eax         ;Dx
        Instr_To_EA_W
        shr     ecx,9
        mov     [ebp+base.V],0
        and     ecx,7
        Read_W
        mov     [WORD PTR ebp+ecx*4+base.D],dx
        or      dx,dx
        Set_Flags_NZC
        Next    4
        ENDP

PROC Do_Move_L_Mem_Dx NEAR
        mov     ecx,eax         ;Dx
        Instr_To_EA_L
        shr     ecx,9
        mov     [ebp+base.V],0
        and     ecx,7
        Read_L
        mov     [ebp+ecx*4+base.D],edx
        or      edx,edx
        Set_Flags_NZC
        Next    4
        ENDP

PROC Do_Move_B_Mem_Mem NEAR
        mov     ecx,eax         ;destination EA
        Instr_To_EA_B
        mov     eax,ecx
        shr     ecx,9
        shr     eax,3   ;mode
        and     ecx,7   ;reg
        and     eax,38h
        mov     [ebp+base.V],0
        or      eax,ecx ;destination EA
        Read_B
        Instr_To_EA_B
        or      dl,dl
        Set_Flags_NZC
        Write_B
        Next 4
        ENDP

PROC Do_Move_W_Mem_Mem NEAR
        mov     ecx,eax         ;destination EA
        Instr_To_EA_W
        mov     eax,ecx
        shr     ecx,9
        shr     eax,3   ;mode
        and     ecx,7   ;reg
        and     eax,38h
        mov     [ebp+base.V],0
        or      eax,ecx ;destination EA
        Read_W
        Instr_To_EA_W
        or      dx,dx
        Set_Flags_NZC
        Write_W
        Next 4
        ENDP

PROC Do_Move_L_Mem_Mem NEAR
        mov     ecx,eax         ;destination EA
        Instr_To_EA_L
        mov     eax,ecx
        shr     ecx,9
        shr     eax,3   ;mode
        and     ecx,7   ;reg
        and     eax,38h
        mov     [ebp+base.V],0
        or      eax,ecx ;destination EA
        Read_L
        Instr_To_EA_L
        or      edx,edx
        Set_Flags_NZC
        Write_L
        Next    4
        ENDP




; [fold]  (
PROC Do_General_MOVE_B NEAR
        prof    _MOVE_B

        push    eax
        Instr_To_EA_B
        pop     eax

        or      ebx,ebx
        jnz short    @@mem1

;        mov     dl,[edi+ebx]
        mov     dl,[edi]
        jmp short  @@cont1
@@mem1:
        Read_B                  ;*************
@@cont1:

        shr     eax,6
        mov     ecx,eax
        shl     eax,3
        and     eax,038h
        shr     ecx,3
        and     ecx,7
        or      eax,ecx
        Instr_To_EA_B                    ;destination EA

        or      ebx,ebx
        jnz short    @@mem2

;        mov     [edi+ebx],dl
        mov     [edi],dl
        jmp short    @@cont2

@@mem2:
        Write_B         ; ***********
@@cont2:
        or      dl,dl
        Set_Flags_NZC
        mov     [ebp+base.V],0
        Next 4
        ENDP

; [fold]  )

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                   MOVE.W
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  (
PROC Do_General_MOVE_W NEAR
        prof    _MOVE_W
        push    eax
        Instr_To_EA_W
        pop     eax

        or      ebx,ebx
        jnz short    @@mem1

;        mov     dx,[edi+ebx]
        mov     dx,[edi]
        jmp short    @@cont1
@@mem1:
        Read_W                  ;***********
@@cont1:
        shr     eax,6
        mov     ecx,eax
        shl     eax,3
        and     eax,038h
        shr     ecx,3
        and     ecx,7
        or      eax,ecx
        mov     ecx,ebx  ;neces?****            ;ecx = memory mode (REG/mem)
        Instr_To_EA_W                   ;destination EA

        or      ebx,ebx
        jnz short    @@mem2

        ;mov     [WORD PTR edi+ebx],dx
        mov     [WORD PTR edi],dx
        jmp short    @@cont2
@@mem2:
        Write_W
        rol     dx,8
@@cont2:

@@NoRegDest:
        or      dx,dx
        Set_Flags_NZC
        mov     [ebp+base.V],0
        Next 4
        ENDP

; [fold]  )

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                   MOVE.L
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  (
PROC Do_General_MOVE_L NEAR
        prof    _MOVE_L

        push    eax
        Instr_To_EA_L
        pop     eax

        or      ebx,ebx
        jnz short    @@mem1

;        mov     edx,[edi+ebx]
        mov     edx,[edi]
        jmp short    @@cont1
@@mem1:
        Read_L
        MoreCycles 4                   ;+4 cycles if mem
@@cont1:

        shr     eax,6
        mov     ecx,eax
        shl     eax,3
        and     eax,038h
        shr     ecx,3
        and     ecx,7
        or      eax,ecx
        mov     ecx,ebx
        Instr_To_EA_L

@@SameMemMode:
        or      ebx,ebx
        jnz short    @@mem2

        ;mov     [DWORD PTR edi+ebx],edx
        mov     [edi],edx
        jmp short    @@cont2
@@mem2:
       Write_L
       bswap    edx
       MoreCycles 4
@@cont2:
        or      edx,edx
        Set_Flags_NZC
        mov     [ebp+base.V],0
        Next 4
        ENDP

; [fold]  )


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                    MOVEP
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_MOVEP_W_To_Mem:
        prof    _MOVEP_W_to_mem

        mov     edi,esi         ;modified
        or      edi,[PC_Base]   ;
        Read_W
        movsx   edi,dx                          ;extend offset sign in EDI
        add     esi,2

        mov     ecx,eax                         ;keep ECX for data register
        and     eax,7
        add     edi,[ebp+eax*4+base.A]                  ;EDI is value of adress reg

        shr     ecx,9
        and     ecx,7
        mov     ax,[WORD PTR ebp+ecx*4+base.D]          ;EAX is the word to transfer

        mov     dl,ah
        Write_B                                 ;write first byte
dm4:    add     edi,2
        mov     dl,al
        Write_B                                 ;write second byte
        Next    16

; [fold]  ]

; [fold]  [
Do_MOVEP_L_To_Mem:
        prof    _MOVEP_L_to_mem

        mov     edi,esi         ;modified
        or      edi,[PC_Base]   ;

        Read_W
        movsx   edi,dx
        add     esi,2

        mov     ecx,eax
        and     eax,7
        add     edi,[ebp+eax*4+base.A]

        shr     ecx,9
        and     ecx,7
        mov     eax,[ebp+ecx*4+base.D]

        rol     eax,8
        mov     dl,al
        Write_B
dm1:    rol     eax,8
        add     edi,2
        mov     dl,al
        Write_B
dm2:    rol     eax,8
        add     edi,2
        mov     dl,al
        Write_B
dm3:    rol     eax,8
        add     edi,2
        mov     dl,al
        Write_B
        Next    24

; [fold]  ]

; [fold]  [
Do_MOVEP_W_From_Mem:
        prof    _MOVEP_W_from_mem

        mov     edi,esi         ;modified
        or      edi,[PC_Base]   ;
        Read_W
        movsx   edi,dx                          ;extend offset sign in EDI
        add     esi,2

        mov     ecx,eax
        and     eax,7
        add     edi,[ebp+eax*4+base.A]                  ;EDI is value of adress reg

        shr     ecx,9
        and     ecx,7                           ;ECX is the data register

        Read_B
        mov     ah,dl                           ;keep MSbyte
        add     edi,2
dm5:    Read_B
        mov     al,dl
        mov     [WORD PTR ebp+ecx*4+base.D],ax
        Next    16

; [fold]  ]

; [fold]  [
Do_MOVEP_L_From_Mem:
        prof    _MOVEP_L_From_mem

        mov     edi,esi         ;modified
        or      edi,[PC_Base]   ;

        Read_W
        movsx   edi,dx
        add     esi,2

        mov     ecx,eax
        and     eax,7
        add     edi,[ebp+eax*4+base.A]

        shr     ecx,9
        and     ecx,7

        Read_B
        mov     al,dl
        shl     eax,8
        add     edi,2
dm6:    Read_B
        mov     al,dl
        shl     eax,8
        add     edi,2
dm7:    Read_B
        mov     al,dl
        shl     eax,8
        add     edi,2
dm8:    Read_B
        mov     al,dl
        mov     [ebp+ecx*4+base.D],eax
        Next    24

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                    MOVEQ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  (
Do_MOVEQ:
        movsx   edx,al          ;extend 8 bits offset to 32 bits signed
        shr     eax,9
        mov     [ebp+base.V],0
        and     eax,7           ;reg.
        or      edx,edx
        mov     [ebp+eax*4+base.D],edx
        Set_Flags_NZC
        Next    4

; [fold]  )

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                    MOVEA
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_MOVEA_W_Rx:
        prof    _MOVEA_W_Dx
        mov     ebx,eax
        shr     eax,9
        and     ebx,15                          ;ebx = Dx src
        and     eax,7                           ;eax = Ax dest

        movsx   edx,[WORD PTR ebp+ebx*4+base.D]
        mov     [ebp+eax*4+base.A],edx
        Next    4

; [fold]  ]

; [fold]  [
Do_MOVEA_L_Rx:
        prof    _MOVEA_L_Dx
        mov     ebx,eax
        shr     eax,9
        and     ebx,15                           ;ebx = Dx
        and     eax,7                           ;eax = Ax dest

        mov     edx,[ebp+ebx*4+base.D]
        mov     [ebp+eax*4+base.A],edx
        Next    4

; [fold]  ]

; [fold]  [
Do_MOVEA_W_mem:
        prof    _MOVEA_W_mem

        mov     ecx,eax
        Instr_To_EA_W
        shr     ecx,9
        Read_W
        and     ecx,7
        movsx   edx,dx

        mov     [ebp+ecx*4+base.A],edx
        Next    4

; [fold]  ]

; [fold]  [
Do_MOVEA_L_mem:
        mov     ecx,eax
        Instr_To_EA_L
        shr     ecx,9
        and     ecx,7
        Read_L
        mov     [ebp+ecx*4+base.A],edx
        next 4

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      LEA
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_LEA:
        prof    _LEA
        mov     ecx,eax
        Instr_To_EA_W                   ;param EBX not needed
        shr     ecx,9
        and     ecx,7
        mov     [ebp+ecx*4+base.A],edi
        Next    0

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      PEA
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_PEA:
        prof    _PEA
        Instr_To_EA_L
        mov     edx,edi
        Push_Intel_Long
        Next    8

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                     SWAP
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  (
Do_SWAP:
        prof    _SWAP
        and     eax,7
        mov     edx,[ebp+eax*4+base.D]
        rol     edx,16
        mov     [ebp+base.V],0
        mov     [ebp+eax*4+base.D],edx
        or      edx,edx
        Set_Flags_NZC
        Next    4

; [fold]  )


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      CLR
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  (
_Do_CLR_B:
        prof    _CLR_B
        Instr_To_EA_B
        or      ebx,ebx
        jnz     @@mem
;        mov     [BYTE PTR edi+ebx],0                    ;clear reg/mem
        mov     [BYTE PTR edi],0
        jmp     @@cont
@@mem:
        xor     dl,dl
        Write_B
        MoreCycles 4
@@cont:
        mov     [ebp+base.NZC],040h                             ;N=C=0 Z=1
        mov     [ebp+base.V],0
        Next    4

; [fold]  )

; [fold]  [
_Do_CLR_W:
        prof    _CLR_W
        Instr_To_EA_W

        or      ebx,ebx
        jnz     @@mem

;        mov     [WORD PTR edi+ebx],0
        mov     [WORD PTR edi],0
        jmp     @@cont
@@mem:
        mov     eax,edi
        shr     eax,1
        jnc     @@even          ;CLR.W $1(A0) -> bus error for elektra demo

        ;mov     eax,_EXCEPTION_ADRESSERROR
        jmp     Trigger_AdressError

@@even:
        xor     dx,dx
        Write_W
        MoreCycles 4
@@cont:
        mov     [ebp+base.NZC],040h
        mov     [ebp+base.V],0
        Next    4

; [fold]  ]

; [fold]  [
_Do_CLR_L:
        prof    _CLR_L
        Instr_To_EA_L
        or      ebx,ebx
        jnz     @@mem

;        mov     [DWORD PTR edi+ebx],0
        mov     [DWORD PTR edi],0
        jmp     @@cont
@@mem:
        xor     edx,edx
        Write_L
        MoreCycles 6
@@cont:

        mov     [ebp+base.NZC],040h
        mov     [ebp+base.V],0
        Next    4

; [fold]  ]

; [fold]  [
Do_CLR_B_Dx:
        and     eax,7
        mov     [ebp+base.NZC],040h                             ;N=C=0 Z=1
        mov     [BYTE PTR ebp+eax*4+base.D],0
        mov     [ebp+base.V],0
        Next    4

; [fold]  ]

; [fold]  [
Do_CLR_W_Dx:
        and     eax,7
        mov     [ebp+base.NZC],040h                             ;N=C=0 Z=1
        mov     [WORD PTR ebp+eax*4+base.D],0
        mov     [ebp+base.V],0
        Next    4

; [fold]  ]

; [fold]  [
Do_CLR_L_Dx:
        and     eax,7
        mov     [ebp+base.NZC],040h                             ;N=C=0 Z=1
        mov     [DWORD PTR ebp+eax*4+base.D],0
        mov     [ebp+base.V],0
        Next    6

; [fold]  ]

; [fold]  [
Do_CLR_B_Mem:
        Instr_To_EA_B
        xor     edx,edx
        mov     [ebp+base.NZC],040h                             ;N=C=0 Z=1
        Write_B
        mov     [ebp+base.V],0
        Next    8

; [fold]  ]

; [fold]  [
Do_CLR_W_Mem:
        Instr_To_EA_W
        xor     edx,edx
        mov     [ebp+base.NZC],040h                             ;N=C=0 Z=1
        Write_W
        mov     [ebp+base.V],0
        Next    8

; [fold]  ]

; [fold]  [
Do_CLR_L_Mem:
        Instr_To_EA_L
        xor     edx,edx
        mov     [ebp+base.NZC],040h                             ;N=C=0 Z=1
        Write_L
        mov     [ebp+base.V],0
        Next    12

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      EXG
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_EXG_Dx_Dx:
        prof    _EXG_Dx_Dx
        mov     ebx,eax
        shr     ebx,9
        and     eax,7
        and     ebx,7

        mov     ecx,[ebp+eax*4+base.D]
        mov     edx,[ebp+ebx*4+base.D]
        mov     [ebp+ebx*4+base.D],ecx
        mov     [ebp+eax*4+base.D],edx
        Next    6

; [fold]  ]

; [fold]  [
Do_EXG_Ax_Ax:
        prof    _EXG_Ax_Ax
        mov     ebx,eax
        shr     ebx,9
        and     eax,7
        and     ebx,7

        mov     ecx,[ebp+eax*4+base.A]
        mov     edx,[ebp+ebx*4+base.A]
        mov     [ebp+ebx*4+base.A],ecx
        mov     [ebp+eax*4+base.A],edx
        Next    6

; [fold]  ]

; [fold]  [
Do_EXG_Dx_Ax:
        prof    _EXG_Dx_Ax
        mov     ebx,eax
        shr     ebx,9
        and     eax,7
        and     ebx,7

        mov     ecx,[ebp+eax*4+base.A]
        mov     edx,[ebp+ebx*4+base.D]
        mov     [ebp+ebx*4+base.D],ecx
        mov     [ebp+eax*4+base.A],edx
        Next    6

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      Scc
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ


; [fold]  [
Do_SEQ:
        mov     ecx,eax
        Instr_To_EA_B
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        setz    al
        shr     eax,1
        sbb     eax,eax
Do_Set:
        test    ecx,38h ;ea mode
        jnz     @@ea
        and     ecx,7
        or      al,al
        mov     [BYTE PTR ebp+ecx*4+base.D],al
        jnz     @@tru
        Next    4
@@tru:
        Next    6
@@ea:
        mov     dl,al
        Write_B
        Next    8

; [fold]  ]

; [fold]  [
Do_SF:
       mov     ecx,eax
       Instr_To_EA_B
       xor     al,al
       jmp     Do_Set


; [fold]  ]

; [fold]  [
Do_ST:
        mov     ecx,eax
        Instr_To_EA_B
        mov     al,0ffh
        jmp     Do_Set


; [fold]  ]

; [fold]  [
Do_SNE:
        mov     ecx,eax
        Instr_To_EA_B
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        setnz   al
        shr     eax,1
        sbb     eax,eax
        jmp     Do_Set

; [fold]  ]

; [fold]  [
Do_SCC:
        mov     ecx,eax
        Instr_To_EA_B
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        setnc   al
        shr     eax,1
        sbb     eax,eax
        jmp     Do_Set

; [fold]  ]

; [fold]  [
Do_SCS:
        mov     ecx,eax
        Instr_To_EA_B
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        setc    al
        shr     eax,1
        sbb     eax,eax
        jmp Do_Set

; [fold]  ]

; [fold]  [
Do_SVC:
        mov     ecx,eax
        Instr_To_EA_B
        mov     edx,[ebp+base.V]
        shr     edx,1
        sbb     eax,eax
        jmp     Do_Set

; [fold]  ]

; [fold]  [
Do_SVS:
        mov     ecx,eax
        Instr_To_EA_B
        mov     edx,[ebp+base.V]
        not     edx
        shr     edx,1
        sbb     eax,eax
        jmp     Do_Set

; [fold]  ]

; [fold]  [
Do_SMI:
        mov     ecx,eax
        Instr_To_EA_B
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        sets    al
        shr     eax,1
        sbb     eax,eax
        jmp     Do_Set

; [fold]  ]

; [fold]  [
Do_SPL:
        mov     ecx,eax
        Instr_To_EA_B
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        setns   al
        shr     eax,1
        sbb     eax,eax
        jmp     Do_Set

; [fold]  ]

; [fold]  [
Do_SHI:
        mov     ecx,eax
        Instr_To_EA_B
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        setnbe  al
        shr     eax,1
        sbb     eax,eax
        jmp     Do_Set


; [fold]  ]

; [fold]  [
Do_SLS:
        mov     ecx,eax
        Instr_To_EA_B
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        setbe   al
        shr     eax,1
        sbb     eax,eax
        jmp     Do_Set


; [fold]  ]

; [fold]  [
Do_SGE:
        mov     ecx,eax
        Instr_To_EA_B
        mov     ah,[BYTE PTR ebp+base.NZC]
        shr     ah,7                    ;bit 0=N
        xor     ah,[BYTE PTR ebp+base.V]        ;bit 0=N xor V
        shr     ah,1
        setnc   al
        shr     eax,1
        sbb     eax,eax
        jmp     Do_Set

; [fold]  ]

; [fold]  [
Do_SLT:
        mov     ecx,eax
        Instr_To_EA_B
        mov     ah,[BYTE PTR ebp+base.NZC]
        shr     ah,7                    ;bit 0=N
        xor     ah,[BYTE PTR ebp+base.V]        ;bit 0=N xor V
        shr     ah,1
        setc    al
        shr     eax,1
        sbb     eax,eax
        jmp     Do_Set


; [fold]  ]

; [fold]  [
Do_SLE:
        mov     ecx,eax
        Instr_To_EA_B
        mov     ah,[BYTE PTR ebp+base.NZC]
        mov     dl,ah
        shr     ah,7                    ;bit 0=N
        xor     ah,[BYTE PTR ebp+base.V]        ;bit 0=N xor V
        shr     dl,6                    ;bit 0=Z
        or      ah,dl                   ;bit 0=Z or (N xor V)
        shr     ah,1
        setc    al
        shr     eax,1
        sbb     eax,eax
        jmp     Do_Set

; [fold]  ]

; [fold]  [
Do_SGT:
        mov     ecx,eax
        Instr_To_EA_B
        mov     ah,[BYTE PTR ebp+base.NZC]
        mov     dl,ah
        shr     ah,7                    ;bit 0=N
        xor     ah,[BYTE PTR ebp+base.V]        ;bit 0=N xor V
        shr     dl,6                    ;bit 0=Z
        or      ah,dl                   ;bit 0=Z or (N xor V)
        shr     ah,1
        setnc   al
        shr     eax,1
        sbb     eax,eax
        jmp     Do_Set

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                 MOVE USP
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_MOVE_To_USP:
        prof    _MOVE_To_USP
        and     eax,7
        Check_Privilege
        mov     eax,[ebp+eax*4+base.A]
        mov     [ebp+base.A7],eax
        Next    4

; [fold]  ]

; [fold]  [
Do_MOVE_From_USP:
        prof    _MOVE_from_USP
        and     eax,7
        Check_Privilege
        mov     edx,[ebp+base.A7]
        mov     [ebp+eax*4+base.A],edx
        Next    4

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                LINK UNLK
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_LINK:
        prof    _LINK
        and     eax,7
;        mov     bx,[esi+ebp]

                mov     bx,[es:esi]

        mov     edx,[ebp+eax*4+base.A]                  ;push Ax
        rol     bx,8
        Push_INTEL_Long
        mov     edx,[ebp+7*4+base.A]
        movsx   ecx,bx
        add     esi,2
        mov     [ebp+eax*4+base.A],edx                  ;Ax = A7
        add     [ebp+7*4+base.A],ecx                    ;A7 = A7 + d16
        Next    16


; [fold]  ]

; [fold]  [
Do_UNLK:
        prof    _UNLK
        and     eax,7
        mov     ebx,[ebp+eax*4+base.A]
        mov     [ebp+7*4+base.A],ebx                    ;A7 = Ax
        Pop_INTEL_Long
        mov     [ebp+eax*4+base.A],edx
        Next    12

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                              MOVE ccr/sr
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_MOVE_To_CCR:
        test    eax,38h
        jnz     @@ea
        and     eax,7
        mov     edx,[ebp+eax*4+base.D]
        jmp     @@reg
@@ea:
        Instr_To_EA_W
        Read_W
@@reg:
        mov     [BYTE PTR ebp+base.SR],dl
        call     Convert_From_SR
        Next    12

; [fold]  ]

; [fold]  [
Do_MOVE_To_SR:
        Check_Privilege
        test    eax,38h
        jnz     @@ea
        and     eax,7
        mov     edx,[ebp+eax*4+base.D]
        jmp     @@reg
@@ea:
        Instr_To_EA_W
        Read_W
@@reg:
        mov     [WORD PTR ebp+base.SR],dx
        call     Convert_From_SR
        Next    12

; [fold]  ]

; [fold]  [
Do_MOVE_From_SR:
        push    eax
        call    Convert_To_SR
        pop     eax
        mov     edx,[ebp+base.SR]

        test    eax,38h
        jnz     @@ea
        and     eax,7
        mov     [WORD PTR ebp+eax*4+base.D],dx
        Next    6
@@ea:
        Instr_To_EA_W
        Write_W
        Next    8

; [fold]  ]

        END


; [fold]  50
