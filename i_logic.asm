COMMENT ~
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
ณ Emulation of LOGICAL instructions                                        ณ
ณ                                                                          ณ
ณ       25/6/96  Converted all code to TASM IDEAL mode                     ณ
ณ                                                                          ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
~
        IDEAL

        include "simu68.inc"
        include "profile.inc"

        CODESEG

        PUBLIC  Do_BTST_L_Dx_Dx, Do_BTST_L_Nb_Dx
        PUBLIC  Do_BTST_B_Dx_mem, Do_BTST_B_Nb_mem
        PUBLIC  Do_BSET_L_Dx_Dx, Do_BSET_L_Nb_Dx
        PUBLIC  Do_BSET_B_Dx_mem, Do_BSET_B_Nb_mem
        PUBLIC  Do_BCLR_L_Dx_Dx, Do_BCLR_L_Nb_Dx
        PUBLIC  Do_BCLR_B_Dx_mem, Do_BCLR_B_Nb_mem
        PUBLIC  Do_BCHG_L_Dx_Dx, Do_BCHG_L_Nb_Dx
        PUBLIC  Do_BCHG_B_Dx_mem, Do_BCHG_B_Nb_mem
        PUBLIC  Do_AND_B_Mem_To_Dx, Do_AND_W_Mem_To_Dx
        PUBLIC  Do_AND_L_Mem_To_Dx, Do_AND_B_Dx_To_Dx
        PUBLIC  Do_AND_W_Dx_To_Dx, Do_AND_L_Dx_To_Dx
        PUBLIC  Do_AND_B_Dx_To_Mem,Do_AND_W_Dx_To_Mem
        PUBLIC  Do_AND_L_Dx_To_Mem, Do_OR_B_Mem_To_Dx
        PUBLIC  Do_OR_W_Mem_To_Dx, Do_OR_L_Mem_To_Dx
        PUBLIC  Do_OR_B_Dx_To_Dx, Do_OR_W_Dx_To_Dx
        PUBLIC  Do_OR_L_Dx_To_Dx, Do_OR_B_Dx_To_Mem
        PUBLIC  Do_OR_W_Dx_To_Mem, Do_OR_L_Dx_To_Mem
        PUBLIC  Do_EOR_B_Dx_To_Dx, Do_EOR_W_Dx_To_Dx
        PUBLIC  Do_EOR_L_Dx_To_Dx, Do_EOR_B_Dx_To_Mem
        PUBLIC  Do_EOR_W_Dx_To_Mem, Do_EOR_L_Dx_To_Mem
        PUBLIC  Do_ANDI_B_To_Mem, Do_ANDI_W_To_Mem, Do_ANDI_L_To_Mem
        PUBLIC  Do_ANDI_B_To_Dx, Do_ANDI_W_To_Dx, Do_ANDI_L_To_Dx
        PUBLIC  Do_ORI_B_To_Mem, Do_ORI_W_To_Mem ,Do_ORI_L_To_Mem
        PUBLIC  Do_ORI_B_To_Dx, Do_ORI_W_To_Dx, Do_ORI_L_To_Dx
        PUBLIC  Do_EORI_B_To_Mem, Do_EORI_W_To_Mem, Do_EORI_L_To_Mem
        PUBLIC  Do_EORI_B_To_Dx, Do_EORI_W_To_Dx, Do_EORI_L_To_Dx
        PUBLIC  Do_NOT_B_Dx, Do_NOT_W_Dx, Do_NOT_L_Dx
        PUBLIC  Do_NOT_B_Mem, Do_NOT_W_Mem, Do_NOT_L_Mem
        PUBLIC  Do_ANDI_CCR, Do_ANDI_SR, Do_EORI_CCR, Do_EORI_SR
        PUBLIC  Do_ORI_CCR, Do_ORI_SR
        PUBLIC  Do_LSL_B_Dx_Dx, Do_LSL_W_Dx_Dx, Do_LSL_L_Dx_Dx
        PUBLIC  Do_LSL_B_Nb_Dx, Do_LSL_W_Nb_Dx, Do_LSL_L_Nb_Dx
        PUBLIC  Do_LSL_W_mem
        PUBLIC  Do_LSR_B_Dx_Dx, Do_LSR_W_Dx_Dx, Do_LSR_L_Dx_Dx
        PUBLIC  Do_LSR_B_Nb_Dx, Do_LSR_W_Nb_Dx, Do_LSR_L_Nb_Dx
        PUBLIC  Do_LSR_W_mem
        PUBLIC  Do_ASL_B_Dx_Dx, Do_ASL_W_Dx_Dx, Do_ASL_L_Dx_Dx
        PUBLIC  Do_ASL_B_Nb_Dx, Do_ASL_W_Nb_Dx, Do_ASL_L_Nb_Dx
        PUBLIC  Do_ASL_W_mem
        PUBLIC  Do_ASR_B_Dx_Dx, Do_ASR_W_Dx_Dx, Do_ASR_L_Dx_Dx
        PUBLIC  Do_ASR_B_Nb_Dx, Do_ASR_W_Nb_Dx, Do_ASR_L_Nb_Dx
        PUBLIC  Do_ASR_W_mem
        PUBLIC  Do_ROL_B_Dx_Dx, Do_ROL_W_Dx_Dx, Do_ROL_L_Dx_Dx
        PUBLIC  Do_ROL_B_Nb_Dx, Do_ROL_W_Nb_Dx, Do_ROL_L_Nb_Dx
        PUBLIC  Do_ROL_W_mem
        PUBLIC  Do_ROR_B_Dx_Dx, Do_ROR_W_Dx_Dx, Do_ROR_L_Dx_Dx
        PUBLIC  Do_ROR_B_Nb_Dx, Do_ROR_W_Nb_Dx, Do_ROR_L_Nb_Dx
        PUBLIC  Do_ROR_W_mem
        PUBLIC  Do_ROXL_B_Dx_Dx, Do_ROXL_W_Dx_Dx, Do_ROXL_L_Dx_Dx
        PUBLIC  Do_ROXL_B_Nb_Dx, Do_ROXL_W_Nb_Dx, Do_ROXL_L_Nb_Dx
        PUBLIC  Do_ROXL_W_mem
        PUBLIC  Do_ROXR_B_Dx_Dx, Do_ROXR_W_Dx_Dx, Do_ROXR_L_Dx_Dx
        PUBLIC  Do_ROXR_B_Nb_Dx, Do_ROXR_W_Nb_Dx, Do_ROXR_L_Nb_Dx
        PUBLIC  Do_ROXR_W_mem

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                     BTST
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ


MACRO Set_Flags_After_BTST dst,src
        LOCAL @@bit1
        or     [BYTE PTR ebp+base.NZC],40h
        test    dst,src
        jz      short @@bit1
        and      [BYTE PTR ebp+base.NZC],81h
@@bit1:
        ENDM


; [fold]  [
Do_BTST_L_Nb_Dx:
        mov     dl,[es:esi+1]
        add     esi,2
        and     edx,31
        and     eax,7
        mov     ebx,[BittestMasks_L+edx*4]
        Set_Flags_After_BTST [ebp+eax*4+base.D],ebx
        Next    10

; [fold]  ]

; [fold]  [
Do_BTST_L_Dx_Dx:
        mov     edx,eax
        shr     edx,9
        and     edx,7
        mov     edx,[ebp+edx*4+base.D]          ;number of the bit to test
        and     edx,31
        mov     ebx,[BittestMasks_L+edx*4]      ;mask of bit
        and     eax,7
        Set_Flags_After_BTST [ebp+eax*4+base.D],ebx
        Next    6

; [fold]  ]

; [fold]  [
Do_BTST_B_Nb_mem:
        mov     dl,[es:esi+1]
        and     edx,7
        add     esi,2
        mov     cl,[BYTE PTR BittestMasks_B+edx]       ;cx= mask of bits
        Instr_To_EA_B
        Read_B
        Set_Flags_After_BTST dl,cl
        Next    8

; [fold]  ]

; [fold]  [
Do_BTST_B_Dx_mem:
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     ecx,[ebp+ecx*4+base.D]
        and     ecx,7
        Instr_To_EA_B
        mov     cl, [BYTE PTR BittestMasks_B+ecx]
        Read_B
        Set_Flags_After_BTST dl,cl
        Next    4

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                     BCLR
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_BCLR_L_Nb_Dx:
        prof _BCLR_L_Nb_Dx

        mov     dl,[es:esi+1]
        add     esi,2
        and     eax,7
        and     edx,31
        lea     edi,[ebp+eax*4+base.D]
        mov     ebx,[BittestMasks_L+edx*4]
        Set_Flags_After_BTST [edi],ebx
        not     ebx
        and     [edi],ebx
        Next    14

; [fold]  ]

; [fold]  [
Do_BCLR_L_Dx_Dx:
        prof _BCLR_L_Dx_Dx
        mov     edx,eax
        shr     edx,9
        and     edx,7
        mov     edx,[ebp+edx*4+base.D]          ;number of the bit to test
        and     edx,31
        and     eax,7
        mov     ebx,[BittestMasks_L+edx*4]      ;mask of bit
        lea     edi,[ebp+eax*4+base.D]

        Set_Flags_After_BTST [edi],ebx
        not     ebx
        and     [edi],ebx
        Next    10

; [fold]  ]

; [fold]  [
Do_BCLR_B_Nb_mem:
        prof _BCLR_B_Nb_mem

        mov     dl,[es:esi+1]
        add     esi,2
        and     edx,7
        Instr_To_EA_B
        mov     cl,[BYTE PTR BittestMasks_B+edx]       ;cx= mask of bits
        Read_B
        Set_Flags_After_BTST dl,cl
        not     cl
        and     dl,cl
        Write_B
        Next    12

; [fold]  ]

; [fold]  [
Do_BCLR_B_Dx_mem:
        prof _BCLR_B_Dx_mem

        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     ecx,[ebp+ecx*4+base.D]
        and     ecx,7
        Instr_To_EA_B
        mov     cl, [BYTE PTR BittestMasks_B+ecx]
        Read_B
        Set_Flags_After_BTST dl,cl
        not     cl
        and     dl,cl
        Write_B
        Next    8

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                     BSET
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_BSET_L_Nb_Dx:
        prof _BSET_L_Nb_Dx

        mov     dl,[es:esi+1]
        add     esi,2
        and     eax,7
        and     edx,31
        lea     edi,[ebp+eax*4+base.D]
        mov     ebx,[BittestMasks_L+edx*4]
        Set_Flags_After_BTST [edi],ebx
        or     [edi],ebx
        Next    12

; [fold]  ]

; [fold]  [
Do_BSET_L_Dx_Dx:
        prof _BSET_L_Dx_Dx

        mov     edx,eax
        shr     edx,9
        and     edx,7
        mov     edx,[ebp+edx*4+base.D]          ;number of the bit to test
        and     edx,31
        and     eax,7
        mov     ebx,[BittestMasks_L+edx*4]      ;mask of bit
        lea     edi,[ebp+eax*4+base.D]

        Set_Flags_After_BTST [edi],ebx
        or      [edi],ebx
        Next    8

; [fold]  ]

; [fold]  [
Do_BSET_B_Nb_mem:
        prof _BSET_B_Nb_mem

        mov     dl,[es:esi+1]
        add     esi,2
        and     edx,7
        Instr_To_EA_B
        mov     cl,[BYTE PTR BittestMasks_B+edx]       ;cx= mask of bits
        Read_B
        Set_Flags_After_BTST dl,cl
        or      dl,cl
        Write_B
        Next    12

; [fold]  ]

; [fold]  [
Do_BSET_B_Dx_mem:
        prof _BSET_B_Dx_mem

        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     ecx,[ebp+ecx*4+base.D]
        and     ecx,7
        Instr_To_EA_B
        mov     cl, [BYTE PTR BittestMasks_B+ecx]
        Read_B
        Set_Flags_After_BTST dl,cl
        or      dl,cl
        Write_B
        Next    8

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                     BCHG
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_BCHG_L_Nb_Dx:
        prof _BCHG_L_Nb_Dx

        mov     dl,[es:esi+1]
        add     esi,2
        and     eax,7
        and     edx,31
        lea     edi,[ebp+eax*4+base.D]
        mov     ebx,[BittestMasks_L+edx*4]
        Set_Flags_After_BTST [edi],ebx
        xor     [edi],ebx
        Next    12

; [fold]  ]

; [fold]  [
Do_BCHG_L_Dx_Dx:
        prof _BCHG_L_Dx_Dx

        mov     edx,eax
        shr     edx,9
        and     edx,7
        mov     edx,[ebp+edx*4+base.D]          ;number of the bit to test
        and     edx,31
        and     eax,7
        mov     ebx,[BittestMasks_L+edx*4]      ;mask of bit
        lea     edi,[ebp+eax*4+base.D]
        Set_Flags_After_BTST [edi],ebx
        xor     [edi],ebx
        Next    8

; [fold]  ]

; [fold]  [
Do_BCHG_B_Nb_mem:
        mov     dl,[es:esi+1]
        add     esi,2
        and     edx,7
        Instr_To_EA_B
        mov     cl,[BYTE PTR BittestMasks_B+edx]       ;cx= mask of bits
        Read_B
        Set_Flags_After_BTST dl,cl
        xor     dl,cl
        Write_B
        Next    12

; [fold]  ]

; [fold]  [
Do_BCHG_B_Dx_mem:

        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     ecx,[ebp+ecx*4+base.D]
        and     ecx,7
        Instr_To_EA_B
        mov     cl, [BYTE PTR BittestMasks_B+ecx]
        Read_B
        Set_Flags_After_BTST dl,cl
        xor     dl,cl
        Write_B
        Next    8

; [fold]  ]

        DATASEG

LABEL BittestMasks_L
        dd      000000001h,000000002h,000000004h,000000008h
        dd      000000010h,000000020h,000000040h,000000080h
        dd      000000100h,000000200h,000000400h,000000800h
        dd      000001000h,000002000h,000004000h,000008000h
        dd      000010000h,000020000h,000040000h,000080000h
        dd      000100000h,000200000h,000400000h,000800000h
        dd      001000000h,002000000h,004000000h,008000000h
        dd      010000000h,020000000h,040000000h,080000000h

LABEL BittestMasks_B
        db      01h,02h,04h,08h
        db      10h,20h,40h,80h


        CODESEG

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                 AND ANDI
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

MACRO Set_Flags_After_AND
        lahf
        mov     [ebp+base.V],0
        mov     [BYTE PTR ebp+base.NZC],ah
        ENDM

; [fold]  [
Do_AND_B_Dx_To_Dx:
        prof    _AND_B_Dx_To_Dx

        mov     ebx,eax
        shr     ebx,9
        and     eax,7                           ;source data register
        and     ebx,7
        mov     dl,[BYTE PTR ebp+eax*4+base.D]
        and     [byte ptr ebp+ebx*4+base.D],dl
        Set_Flags_After_AND
        Next    4

; [fold]  ]

; [fold]  [
Do_AND_W_Dx_To_Dx:
        prof    _AND_W_Dx_To_Dx

        mov     ebx,eax
        shr     ebx,9
        and     eax,7
        and     ebx,7
        mov     dx,[WORD PTR ebp+eax*4+base.D]
        and     [WORD PTR ebp+ebx*4+base.D],dx
        Set_Flags_After_AND
        Next    4

; [fold]  ]

; [fold]  [
Do_AND_L_Dx_To_Dx:
        prof    _AND_L_Dx_To_Dx

        mov     ebx,eax
        shr     ebx,9
        and     eax,7
        and     ebx,7
        mov     edx,[ebp+eax*4+base.D]
        and     [ebp+ebx*4+base.D],edx
        Set_Flags_After_AND
        Next    6

; [fold]  ]

; [fold]  [
Do_AND_B_Mem_To_Dx:
        prof    _AND_B_mem_To_Dx
        mov     ecx,eax
        Instr_To_EA_B
        shr     ecx,9
        and     ecx,7
        Read_B
        and     [BYTE PTR ebp+ecx*4+base.D],dl
        Set_Flags_After_AND
        Next    4

; [fold]  ]

; [fold]  [
Do_AND_W_Mem_To_Dx:
        prof    _AND_W_mem_To_Dx

        mov     ecx,eax
        Instr_To_EA_W
        shr     ecx,9
        and     ecx,7
        Read_W
        and     [WORD PTR ebp+ecx*4+base.D],dx
        Set_Flags_After_AND
        Next    4

; [fold]  ]

; [fold]  [
Do_AND_L_Mem_To_Dx:
        prof    _AND_L_mem_To_Dx

        mov     ecx,eax
        Instr_To_EA_L
        shr     ecx,9
        and     ecx,7
        Read_L
        and     [ebp+ecx*4+base.D],edx
        Set_Flags_After_AND
        Next    6

; [fold]  ]

; [fold]  [
Do_AND_B_Dx_To_Mem:
        prof    _AND_B_Dx_To_mem

        mov     ecx,eax
        Instr_To_EA_B
        shr     ecx,9
        and     ecx,7
        Read_B
        and     dl,[BYTE PTR ebp+ecx*4+base.D]
        Set_Flags_After_AND
        Write_B
        Next    8

; [fold]  ]

; [fold]  [
Do_AND_W_Dx_To_Mem:
        prof    _AND_W_Dx_To_mem

        mov     ecx,eax
        Instr_To_EA_W
        shr     ecx,9
        and     ecx,7
        Read_W
        and     dx,[WORD PTR ebp+ecx*4+base.D]
        Set_Flags_After_AND
        Write_W
        Next    8

; [fold]  ]

; [fold]  [
Do_AND_L_Dx_To_Mem:
        prof    _AND_L_Dx_To_mem

        mov     ecx,eax
        Instr_To_EA_L
        shr     ecx,9
        and     ecx,7
        Read_L
        and     edx,[ebp+ecx*4+base.D]
        Set_Flags_After_AND
        Write_L
        Next    12

; [fold]  ]

; [fold]  [
Do_ANDI_B_To_Dx:

        mov     dl,[es:esi+1]
        and     eax,7
        add     esi,2
        and     [BYTE PTR ebp+eax*4+base.D],dl
        Set_Flags_After_AND
        Next    8

; [fold]  ]

; [fold]  [
Do_ANDI_W_To_Dx:

        mov     dx,[es:esi]
        rol     dx,8
        and     eax,7
        add     esi,2
        and     [WORD PTR ebp+eax*4+base.D],dx
        Set_Flags_After_AND
        Next    8

; [fold]  ]

; [fold]  [
Do_ANDI_L_To_Dx:
        mov     edx,[es:esi]
        add     esi,4
        and     eax,7
        bswap   edx
        and     [DWORD PTR ebp+eax*4+base.D],edx
        Set_Flags_After_AND
        Next    16

; [fold]  ]

; [fold]  [
Do_ANDI_B_to_Mem:

        mov     cl,[es:esi+1]
        add     esi,2
        Instr_To_EA_B
        Read_B
        and     dl,cl
        Set_Flags_After_AND
        Write_B
        Next    12

; [fold]  ]

; [fold]  [
Do_ANDI_W_to_Mem:

        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        Instr_To_EA_W
        Read_W
        and     dx,cx
        Set_Flags_After_AND
        Write_W
        Next    12

; [fold]  ]

; [fold]  [
Do_ANDI_L_to_Mem:
        mov     ecx,[es:esi]
        add     esi,4
        bswap   ecx
        Instr_To_EA_L
        Read_L
        and     edx,ecx
        Set_Flags_After_AND
        Write_L
        Next    20

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                 EOR EORI
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_EOR_B_Dx_To_Dx:
        prof    _EOR_B_Dx_To_Dx
        mov     ebx,eax
        shr     ebx,9
        and     ebx,7
        and     eax,7                           ;source data register
        mov     dl,[BYTE PTR ebp+ebx*4+base.D]
        xor     [BYTE PTR ebp+eax*4+base.D],dl
        Set_Flags_After_AND
        Next    4

; [fold]  ]

; [fold]  [
Do_EOR_W_Dx_To_Dx:
        mov     ebx,eax
        shr     ebx,9
        and     ebx,7
        and     eax,7
        mov     dx,[WORD PTR ebp+ebx*4+base.D]
        xor     [WORD PTR ebp+eax*4+base.D],dx
        Set_Flags_After_AND
        Next    4

; [fold]  ]

; [fold]  [
Do_EOR_L_Dx_To_Dx:
        prof    _EOR_L_Dx_To_Dx
        mov     ebx,eax
        shr     ebx,9
        and     ebx,7
        and     eax,7
        mov     edx,[ebp+ebx*4+base.D]
        xor     [ebp+eax*4+base.D],edx
        Set_Flags_After_AND
        Next    6

; [fold]  ]

; [fold]  [
Do_EOR_B_Dx_To_Mem:
        mov     ecx,eax
        Instr_To_EA_B
        shr     ecx,9
        and     ecx,7
        Read_B
        xor     dl,[BYTE PTR ebp+ecx*4+base.D]
        Set_Flags_After_AND
        Write_B
        Next    8

; [fold]  ]

; [fold]  [
Do_EOR_W_Dx_To_Mem:
        prof    _EOR_W_Dx_To_mem

        mov     ecx,eax
        Instr_To_EA_W
        shr     ecx,9
        and     ecx,7
        Read_W
        xor     dx,[WORD PTR ebp+ecx*4+base.D]
        Set_Flags_After_AND
        Write_W
        Next    8

; [fold]  ]

; [fold]  [
Do_EOR_L_Dx_To_Mem:
        prof    _EOR_L_Dx_To_mem

        mov     ecx,eax
        Instr_To_EA_L
        shr     ecx,9
        and     ecx,7
        Read_L
        xor     edx,[ebp+ecx*4+base.D]
        Set_Flags_After_AND
        Write_L
        Next    12

; [fold]  ]

; [fold]  [
Do_EORI_B_To_Dx:
        mov     dl,[es:esi+1]
        and     eax,7
        add     esi,2
        xor     [BYTE PTR ebp+eax*4+base.D],dl
        Set_Flags_After_AND
        Next    8

; [fold]  ]

; [fold]  [
Do_EORI_W_To_Dx:
        mov     dx,[es:esi]
        rol     dx,8
        and     eax,7
        add     esi,2
        xor     [WORD PTR ebp+eax*4+base.D],dx
        Set_Flags_After_AND
        Next    8

; [fold]  ]

; [fold]  [
Do_EORI_L_To_Dx:
        mov     edx,[es:esi]
        and     eax,7
        bswap   edx
        add     esi,4
        xor     [DWORD PTR ebp+eax*4+base.D],edx
        Set_Flags_After_AND
        Next    16

; [fold]  ]

; [fold]  [
Do_EORI_B_to_Mem:
        mov     cl,[es:esi+1]
        add     esi,2
        Instr_To_EA_B
        Read_B
        xor     dl,cl
        Set_Flags_After_AND
        Write_B
        Next    12

; [fold]  ]

; [fold]  [
Do_EORI_W_to_Mem:
        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        Instr_To_EA_W
        Read_W
        xor     dx,cx
        Set_Flags_After_AND
        Write_W
        Next    12

; [fold]  ]

; [fold]  [
Do_EORI_L_to_Mem:
        mov     ecx,[es:esi]
        add     esi,4
        bswap   ecx
        Instr_To_EA_L
        Read_L
        xor     edx,ecx
        Set_Flags_After_AND
        Write_L
        Next    20

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                   OR ORI
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_OR_B_Dx_To_Dx:
        prof    _OR_B_Dx_To_Dx
        mov     ebx,eax
        shr     ebx,9
        and     eax,7                           ;source data register
        and     ebx,7
        mov     dl,[BYTE PTR ebp+eax*4+base.D]
        or      [BYTE PTR ebp+ebx*4+base.D],dl
        Set_Flags_After_AND
        Next    4

; [fold]  ]

; [fold]  [
Do_OR_W_Dx_To_Dx:
        prof    _OR_W_Dx_To_Dx

        mov     ebx,eax
        shr     ebx,9
        and     eax,7
        and     ebx,7
        mov     dx,[WORD PTR ebp+eax*4+base.D]
        or      [WORD PTR ebp+ebx*4+base.D],dx
        Set_Flags_After_AND
        Next    4

; [fold]  ]

; [fold]  [
Do_OR_L_Dx_To_Dx:
        prof    _OR_L_Dx_To_Dx

        mov     ebx,eax
        shr     ebx,9
        and     eax,7
        and     ebx,7
        mov     edx,[ebp+eax*4+base.D]
        or      [ebp+ebx*4+base.D],edx
        Set_Flags_After_AND
        Next    6

; [fold]  ]

; [fold]  [
Do_OR_B_Mem_To_Dx:
        prof    _OR_B_Mem_To_Dx

        mov     ecx,eax
        Instr_To_EA_B
        shr     ecx,9
        and     ecx,7
        Read_B
        or      [BYTE PTR ebp+ecx*4+base.D],dl
        Set_Flags_After_AND
        Next    4

; [fold]  ]

; [fold]  [
Do_OR_W_Mem_To_Dx:
        prof    _OR_W_Mem_To_Dx

        mov     ecx,eax
        Instr_To_EA_W
        shr     ecx,9
        and     ecx,7
        Read_W
        or      [WORD PTR ebp+ecx*4+base.D],dx
        Set_Flags_After_AND
        Next    4

; [fold]  ]

; [fold]  [
Do_OR_L_Mem_To_Dx:
        mov     ecx,eax
        Instr_To_EA_L
        shr     ecx,9
        and     ecx,7
        Read_L
        or     [ebp+ecx*4+base.D],edx
        Set_Flags_After_AND
        Next    6

; [fold]  ]

; [fold]  [
Do_OR_B_Dx_To_Mem:
        mov     ecx,eax
        Instr_To_EA_B
        shr     ecx,9
        and     ecx,7
        Read_B
        or     dl,[BYTE PTR ebp+ecx*4+base.D]
        Set_Flags_After_AND
        Write_B
        Next    8

; [fold]  ]

; [fold]  [
Do_OR_W_Dx_To_Mem:

        mov     ecx,eax
        Instr_To_EA_W
        shr     ecx,9
        and     ecx,7
        Read_W
        or      dx, [WORD PTR ebp+ecx*4+base.D]
        Set_Flags_After_AND
        Write_W
        Next    8

; [fold]  ]

; [fold]  [
Do_OR_L_Dx_To_Mem:
        mov     ecx,eax
        Instr_To_EA_L
        shr     ecx,9
        and     ecx,7
        Read_L
        or      edx,[ebp+ecx*4+base.D]
        Set_Flags_After_AND
        Write_L
        Next    12

; [fold]  ]

; [fold]  [
Do_ORI_B_To_Dx:
        mov     dl,[es:esi+1]
        and     eax,7
        add     esi,2
        or      [BYTE PTR ebp+eax*4+base.D],dl
        Set_Flags_After_AND
        Next    8

; [fold]  ]

; [fold]  [
Do_ORI_W_To_Dx:
        mov     dx,[es:esi]
        and     eax,7
        rol     dx,8
        add     esi,2
        or      [WORD PTR ebp+eax*4+base.D],dx
        Set_Flags_After_AND
        Next    8

; [fold]  ]

; [fold]  [
Do_ORI_L_To_Dx:
        mov     edx,[es:esi]
        bswap   edx
        and     eax,7
        add     esi,4
        or      [DWORD PTR ebp+eax*4+base.D],edx
        Set_Flags_After_AND
        Next    16

; [fold]  ]

; [fold]  [
Do_ORI_B_to_Mem:
        mov     cl,[es:esi+1]
        add     esi,2
        Instr_To_EA_B
        Read_B
        or      dl,cl
        Set_Flags_After_AND
        Write_B
        Next    12

; [fold]  ]

; [fold]  [
Do_ORI_W_to_Mem:
        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        Instr_To_EA_W
        Read_W
        or      dx,cx
        Set_Flags_After_AND
        Write_W
        Next    12

; [fold]  ]

; [fold]  [
Do_ORI_L_to_Mem:
        mov     ecx,[es:esi]
        add     esi,4
        bswap   ecx
        Instr_To_EA_L
        Read_L
        or      edx,ecx
        Set_Flags_After_AND
        Write_L
        Next    20

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      NOT
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_NOT_B_Dx:
        prof    _NOT_B_Dx
        and     eax,7                           ;source data register
        not     [BYTE PTR ebp+eax*4+base.D]
        mov     al,[BYTE PTR ebp+eax*4+base.D]
        or      al,al
        Set_Flags_After_AND
        Next    4

; [fold]  ]

; [fold]  [
Do_NOT_W_Dx:
        prof    _NOT_W_Dx

        and     eax,7
        not     [WORD PTR ebp+eax*4+base.D]
        mov     ax,[WORD PTR ebp+eax*4+base.D]
        or      ax,ax
        Set_Flags_After_AND
        Next    4

; [fold]  ]

; [fold]  [
Do_NOT_L_Dx:
        prof    _NOT_L_Dx

        and     eax,7
        not     [DWORD PTR ebp+eax*4+base.D]
        mov     eax,[DWORD PTR ebp+eax*4+base.D]
        or      eax,eax
        Set_Flags_After_AND
        Next    6

; [fold]  ]

; [fold]  [
Do_NOT_B_Mem:
        prof    _NOT_B_Mem

        Instr_To_EA_B
        Read_B
        not     dl
        or      dl,dl
        Set_Flags_After_AND
        Write_B
        Next    8

; [fold]  ]

; [fold]  [
Do_NOT_W_Mem:
        prof    _NOT_W_Mem

        Instr_To_EA_W
        Read_W
        not     dx
        or      dx,dx
        Set_Flags_After_AND
        Write_W
        Next    8

; [fold]  ]

; [fold]  [
Do_NOT_L_Mem:
        prof    _NOT_L_Mem

        Instr_To_EA_L
        Read_L
        not     edx
        or      edx,edx
        Set_Flags_After_AND
        Write_L
        Next    12

; [fold]  ]


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                  (AND/EOR/OR) to CCR/SR
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_ANDI_CCR:
        mov     dl,[es:esi+1]
        add     esi,2
        call    Convert_To_SR
        and     [BYTE PTR ebp+base.SR],dl
        call    Convert_From_SR
        Next    20

; [fold]  ]

; [fold]  [
Do_EORI_CCR:
        mov     dl,[es:esi+1]
        add     esi,2
        call    Convert_To_SR
        xor     [BYTE PTR ebp+base.SR],dl
        call    Convert_From_SR
        Next    20

; [fold]  ]

; [fold]  [
Do_ORI_CCR:
        mov     dl,[es:esi+1]
        add     esi,2
        call    Convert_To_SR
        or      [BYTE PTR ebp+base.SR],dl
        call    Convert_From_SR
        Next    20

; [fold]  ]

; [fold]  [
Do_ANDI_SR:
        mov     dx,[es:esi]
        add     esi,2
        rol     dx,8
        Check_Privilege
        call    Convert_To_SR
        and     [WORD PTR ebp+base.SR],dx
        call    Convert_From_SR
        Next    20

; [fold]  ]

; [fold]  [
Do_EORI_SR:
        mov     dx,[es:esi]
        add     esi,2
        rol     dx,8
        Check_Privilege
        call    Convert_To_SR
        xor     [WORD PTR ebp+base.SR],dx
        call    Convert_From_SR
        Next    20

; [fold]  ]

; [fold]  [
Do_ORI_SR:
        mov     dx,[es:esi]
        add     esi,2
        rol     dx,8
        Check_Privilege
        call    Convert_To_SR
        or      [WORD PTR ebp+base.SR],dx
        call    Convert_From_SR
        Next    20

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                  LSL LSR
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

;************************************************ Flags setting after LSL/LSR
MACRO Set_Flags_After_LShift
        lahf
        mov     [BYTE PTR ebp+base.NZC],ah
        setc    [BYTE PTR ebp+base.X]
        mov     [ebp+base.V],0
ENDM

MACRO Set_Flags_After_LShift0
        lahf
        and     ah,0feh                         ;***** new
        mov     [BYTE PTR ebp+base.NZC],ah
        mov     [ebp+base.V],0
ENDM

; [fold]  [
Do_LSL_B_Dx_Dx:
        prof    _LSL_B_Dx_Dx

        mov     ecx,eax                                 ;get Dx
        shr     ecx,9
        and     ecx,7
        mov     cl,[BYTE PTR ebp+ecx*4+base.D]                  ;number of shifts
        and     eax,7
        and     cl,63
        jz      NoRot_                                 ;nothing to do if cl=0
        shl     [BYTE PTR ebp+eax*4+base.D],cl
        Set_Flags_After_LShift
        Next    10
NoRot_:
        cmp     [BYTE PTR ebp+eax*4+base.D],0
        Set_Flags_After_LShift0
        Next    10

; [fold]  ]

; [fold]  [
Do_LSL_W_Dx_Dx:
        prof    _LSL_W_Dx_Dx

        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     eax,7
        and     cl,63
        jz      NoRotz
        shl     [word ptr ebp+eax*4+base.D],cl
        Set_Flags_After_LShift
        Next    10
NoRotz:
        cmp     [word ptr ebp+eax*4+base.D],0
        Set_Flags_After_LShift0
        Next    10

; [fold]  ]

; [fold]  [
Do_LSL_L_Dx_Dx:
        prof    _LSL_L_Dx_Dx

        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     eax,7
        and     cl,63
        jz      NoRot1
        shl     [dword ptr ebp+eax*4+base.D],cl
        Set_Flags_After_LShift
        Next    16
NoRot1:
        cmp     [dword ptr ebp+eax*4+base.D],0
        Set_Flags_After_LShift0
        Next    16

; [fold]  ]

; [fold]  [
Do_LSL_B_Nb_Dx:
        prof    _LSL_B_Nb_Dx

        mov     ecx,eax                                 ;get number of shift
        shr     ecx,9
        and     eax,7
        and     ecx,7
        jnz     NoRot8_1
        mov     cl,8
NoRot8_1:
        shl     [byte ptr ebp+eax*4+base.D],cl
        Set_Flags_After_LShift
        Next    10

; [fold]  ]

; [fold]  [
Do_LSL_W_Nb_Dx:
        prof    _LSL_W_Nb_Dx

        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        jnz     NoRot8_2
        mov     cl,8
NoRot8_2:
        shl     [word ptr ebp+eax*4+base.D],cl
        Set_Flags_After_LShift
        Next    10

; [fold]  ]

; [fold]  [
Do_LSL_L_Nb_Dx:
        prof    _LSL_L_Nb_Dx

        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        jnz     NoRot8_3
        mov     cl,8
NoRot8_3:
        shl     [dword ptr ebp+eax*4+base.D],cl
        Set_Flags_After_LShift
        Next    16

; [fold]  ]

; [fold]  [
Do_LSL_W_mem:
        prof    _LSL_W_mem

        Instr_To_EA_W
        Read_W                                          ;word to shift
        shl     dx,1
        Set_Flags_After_LShift
        Write_W
        Next    8

; [fold]  ]


; [fold]  [
Do_LSR_B_Dx_Dx:
        prof    _LSR_B_Dx_Dx

        mov     ecx,eax                                 ;get Dx
        shr     ecx,9
        and     eax,7
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]                  ;number of shifts
        and     cl,63
        jz      NoRot_2                                 ;nothing to do if cl=0
        shr     [byte ptr ebp+eax*4+base.D],cl
        Set_Flags_After_LShift
        Next    10
NoRot_2:
        cmp     [byte ptr ebp+eax*4+base.D],0
        Set_Flags_After_LShift0
        Next    10

; [fold]  ]

; [fold]  [
Do_LSR_W_Dx_Dx:
        prof    _LSR_W_Dx_Dx

        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     cl,63
        jz      NoRot_3
        shr     [word ptr ebp+eax*4+base.D],cl
        Set_Flags_After_LShift
        Next    10
NoRot_3:
        cmp     [word ptr ebp+eax*4+base.D],0
        Set_Flags_After_LShift0
        Next    10

; [fold]  ]

; [fold]  [
Do_LSR_L_Dx_Dx:
        prof    _LSR_L_Dx_Dx

        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     cl,63
        jz      NoRot_4
        shr     [dword ptr ebp+eax*4+base.D],cl
        Set_Flags_After_LShift
        Next    16
NoRot_4:
        cmp     [dword ptr ebp+eax*4+base.D],0
        Set_Flags_After_LShift0
        Next    16

; [fold]  ]

; [fold]  [
Do_LSR_B_Nb_Dx:
        prof    _LSR_B_Nb_Dx

        mov     ecx,eax                                 ;get number of shift
        shr     ecx,9
        and     eax,7
        and     ecx,7
        jnz     NoRot8_4
        mov     cl,8
NoRot8_4:
        shr     [byte ptr ebp+eax*4+base.D],cl
        Set_Flags_After_LShift
        Next    10

; [fold]  ]

; [fold]  [
Do_LSR_W_Nb_Dx:
        prof    _LSR_W_Nb_Dx

        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        jnz     NoRot8_5
        mov     cl,8
NoRot8_5:
        shr     [word ptr ebp+eax*4+base.D],cl
        Set_Flags_After_LShift
        Next    10

; [fold]  ]

; [fold]  [
Do_LSR_L_Nb_Dx:
        prof    _LSR_L_Nb_Dx

        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        jnz     NoRot8_6
        mov     cl,8
NoRot8_6:
        shr     [dword ptr ebp+eax*4+base.D],cl
        Set_Flags_After_LShift
        Next    16

; [fold]  ]

; [fold]  [
Do_LSR_W_mem:
        prof    _LSR_W_mem
        Instr_To_EA_W
        Read_W                                          ;word to shift
        shr     dx,1
        Set_Flags_After_LShift
        Write_W
        Next    8

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                  ASL ASR
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

;************************************************* Flags setting after ASL/ASR

MACRO Set_Flags_After_AShift
        seto    [byte ptr ebp+base.V]
        setc    [byte ptr ebp+base.X]
        lahf
        mov     [byte ptr ebp+base.NZC],ah
ENDM

MACRO Set_Flags_After_AShift0
        lahf
        and     ah,0feh
        mov     [byte ptr ebp+base.NZC],ah
        mov     [ebp+base.V],0
ENDM

        DATASEG

ASL_Table:
        dd      000000000h,0c0000000h,0e0000000h,0f0000000h
        dd      0f8000000h,0fc000000h,0fe000000h,0ff000000h
        dd      0ff800000h,0ffc00000h,0ffe00000h,0fff00000h
        dd      0fff80000h,0fffc0000h,0fffe0000h,0ffff0000h
        dd      0ffff8000h,0ffffc000h,0ffffe000h,0fffff000h
        dd      0fffff800h,0fffffc00h,0fffffe00h,0ffffff00h
        dd      0ffffff80h,0ffffffc0h,0ffffffe0h,0fffffff0h
        dd      0fffffff8h,0fffffffch,0fffffffeh,0ffffffffh

        CODESEG


; [fold]  [
Do_ASL_B_Dx_Dx:
        prof    _ASL_B_Dx_Dx

        mov     ecx,eax                                 ;get Dx
        shr     ecx,9
        and     eax,7
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]         ;number of shifts
        and     ecx,63
        jz      NoRota                                 ;nothing to do if cl=0
        sal     [byte ptr ebp+eax*4+base.D],cl
        Set_Flags_After_AShift
        Next    10
NoRota:
        cmp     [byte ptr ebp+eax*4+base.D],0
        Set_Flags_After_AShift0
        Next    10

; [fold]  ]

; [fold]  [
Do_ASL_W_Dx_Dx:
        prof    _ASL_W_Dx_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     ecx,63
        jz      NoRotb
        sal     [word ptr ebp+eax*4+base.D],cl
        Set_Flags_After_AShift
        Next    10
NoRotb:
        cmp     [word ptr ebp+eax*4+base.D],0
        Set_Flags_After_AShift0
        Next    10

; [fold]  ]

MACRO Set_Flags_After_multi_ASL
        setc    [byte ptr ebp+base.X]
        lahf
        mov     [byte ptr ebp+base.NZC],ah
ENDM


; [fold]  (
Do_ASL_L_Dx_Dx:
        prof    _ASL_L_Dx_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
;        and     ecx,63
;        jz      NoRotc
;        sal     [dword ptr ebp+eax*4+base.D],cl
;        Set_Flags_After_AShift

        and     ecx,63
        jz      NoRotc
        mov     edx,[dword ptr ebp+eax*4+base.D]
        mov     ebx,edx
        sal     edx,cl
        mov     ecx,[dword ptr ASL_Table+ecx*4]
        mov     [dword ptr ebp+eax*4+base.D],edx
        Set_Flags_After_Multi_ASL

        and     ebx,ecx
        jz      @@no_over
        cmp     ebx,ecx
@@no_over:
        setnz   [byte ptr ebp+base.V]
        Next    16
NoRotc:
        cmp     [dword ptr ebp+eax*4+base.D],0
        Set_Flags_After_AShift0
        Next    16

; [fold]  )

; [fold]  [
Do_ASL_B_Nb_Dx:
        prof    _ASL_B_Nb_Dx
        mov     ecx,eax                                 ;get number of shift
        shr     ecx,9
        and     eax,7
        and     ecx,7
        jnz     NoRot8d
        mov     cl,8
NoRot8d:
        sal     [byte ptr ebp+eax*4+base.D],cl
        Set_Flags_After_AShift
        Next    10

; [fold]  ]

; [fold]  [
Do_ASL_W_Nb_Dx:
        prof    _ASL_W_Nb_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        jnz     NoRot8e
        mov     cl,8
NoRot8e:
        sal     [word ptr ebp+eax*4+base.D],cl
        Set_Flags_After_AShift
        Next    10

; [fold]  ]

; [fold]  [
Do_ASL_L_Nb_Dx:
        prof    _ASL_L_Nb_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        jnz     NoRot8f
        mov     cl,8
NoRot8f:

        sal     [dword ptr ebp+eax*4+base.D],cl
        Set_Flags_After_AShift
        Next    16

; [fold]  ]

; [fold]  [
Do_ASL_W_mem:
        prof    _ASL_W_mem
        Instr_To_EA_W
        Read_W                                          ;word to shift
        sal     dx,1
        Set_Flags_After_AShift
        Write_W
        Next    8

; [fold]  ]


; [fold]  [
Do_ASR_B_Dx_Dx:
        prof    _ASR_B_Dx_Dx
        mov     ecx,eax                                 ;get Dx
        shr     ecx,9
        and     eax,7
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]                  ;number of shifts
        and     cl,63
        jz      NoRotg                                  ;nothing to do if cl=0
        sar     [byte ptr ebp+eax*4+base.D],cl
        Set_Flags_After_AShift
        Next    10
NoRotg:
        cmp     [byte ptr ebp+eax*4+base.D],0
        Set_Flags_After_AShift0
        Next    10

; [fold]  ]

; [fold]  [
Do_ASR_W_Dx_Dx:
        prof    _ASR_W_Dx_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     cl,63
        jz      NoRoth
        sar     [word ptr ebp+eax*4+base.D],cl
        Set_Flags_After_AShift
        Next    10
NoRoth:
        cmp     [word ptr ebp+eax*4+base.D],0
        Set_Flags_After_AShift0
        Next    10

; [fold]  ]

; [fold]  [
Do_ASR_L_Dx_Dx:
        prof    _ASR_L_Dx_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     cl,63
        jz      NoRoti
        sar     [dword ptr ebp+eax*4+base.D],cl
        Set_Flags_After_AShift
        Next    16
NoRoti:
        cmp     [dword ptr ebp+eax*4+base.D],0
        Set_Flags_After_AShift0
        Next    16

; [fold]  ]

; [fold]  [
Do_ASR_B_Nb_Dx:
        prof    _ASR_B_Nb_Dx
        mov     ecx,eax                                 ;get number of shift
        shr     ecx,9
        and     eax,7
        and     ecx,7
        jnz     NoRot8j
        mov     cl,8
NoRot8j:
        sar     [byte ptr ebp+eax*4+base.D],cl
        Set_Flags_After_AShift
        Next    10

; [fold]  ]

; [fold]  [
Do_ASR_W_Nb_Dx:
        prof    _ASR_W_Nb_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        jnz     NoRot8k
        mov     cl,8
NoRot8k:

        sar     [word ptr ebp+eax*4+base.D],cl
        Set_Flags_After_AShift
        Next    10

; [fold]  ]

; [fold]  [
Do_ASR_L_Nb_Dx:
        prof    _ASR_L_Nb_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        and     ecx,7
        jnz     NoRot8l
        mov     cl,8
NoRot8l:
        sar     [dword ptr ebp+eax*4+base.D],cl
        Set_Flags_After_AShift
        Next    16

; [fold]  ]

; [fold]  [
Do_ASR_W_mem:
        prof    _ASR_W_mem
        Instr_To_EA_W
        Read_W                                          ;word to shift
        sar     dx,1
        Set_Flags_After_AShift
        Write_W
        Next    8

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                  ROL ROR
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

;************************************************* Flags setting after ROL/ROR
MACRO Set_Flags_After_Rotation reg
        setc    al
        or      Reg,Reg
        lahf
        mov     [ebp+base.V],0
        or      ah,al
        mov     [byte ptr ebp+base.NZC],ah
ENDM

MACRO Set_Flags_After_Rotation0 reg
        or      Reg,Reg
        lahf
        and     ah,0feh
        mov     [ebp+base.V],0
        mov     [byte ptr ebp+base.NZC],ah
ENDM


; [fold]  [
Do_ROL_B_Dx_Dx:
        prof    _ROL_B_Dx_Dx
        mov     ecx,eax                                 ;get Dx
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]                  ;number of shifts
        and     eax,7
        mov     dl,[byte ptr ebp+eax*4+base.D]
        and     cl,63
        jz      NoRotm                                  ;nothing to do if cl=0
        rol     dl,cl
        mov     [byte ptr ebp+eax*4+base.D],dl
        Set_Flags_After_Rotation dl
        Next    10
NoRotm:
        Set_Flags_After_Rotation0 dl
        Next    10

; [fold]  ]

; [fold]  [
Do_ROL_W_Dx_Dx:
        prof    _ROL_W_Dx_Dx
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     eax,7
        mov     dx,[word ptr ebp+eax*4+base.D]
        and     cl,63
        jz      NoRotn
        rol     dx,cl
        mov     [word ptr ebp+eax*4+base.D],dx
        Set_Flags_After_Rotation dx
        Next    10
NoRotn:
        Set_Flags_After_Rotation0 dx
        Next    10

; [fold]  ]

; [fold]  [
Do_ROL_L_Dx_Dx:
        prof    _ROL_L_Dx_Dx
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     eax,7
        mov     edx,[dword ptr ebp+eax*4+base.D]
        and     cl,63
        jz      NoRoto
        rol     edx,cl
        mov     [dword ptr ebp+eax*4+base.D],edx
        Set_Flags_After_Rotation edx
        Next    16
NoRoto:
        Set_Flags_After_Rotation0 edx
        Next    16

; [fold]  ]

; [fold]  [
Do_ROL_B_Nb_Dx:
        prof    _ROL_B_Nb_Dx
        mov     ecx,eax                                 ;get number of shift
        shr     ecx,9
        and     eax,7
        mov     dl,[byte ptr ebp+eax*4+base.D]
        and     ecx,7
        jnz     NoRot8p
        mov     cl,8
NoRot8p:

        rol     dl,cl
        mov     [byte ptr ebp+eax*4+base.D],dl
        Set_Flags_After_Rotation dl
        Next    10

; [fold]  ]

; [fold]  [
Do_ROL_W_Nb_Dx:
        prof    _ROL_W_Nb_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        mov     dx,[WORD PTR  ebp+eax*4+base.D]
        and     ecx,7
        jnz     NoRot8q
        mov     cl,8
NoRot8q:
        rol     dx,cl
        mov     [word ptr ebp+eax*4+base.D],dx
        Set_Flags_After_Rotation dx
        Next    10

; [fold]  ]

; [fold]  [
Do_ROL_L_Nb_Dx:
        prof    _ROL_L_Nb_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        mov     edx,[dword ptr ebp+eax*4+base.D]
        and     ecx,7
        jnz     NoRot8r
        mov     cl,8
NoRot8r:
        rol     edx,cl
        mov     [dword ptr ebp+eax*4+base.D],edx
        Set_Flags_After_Rotation edx
        Next    16

; [fold]  ]

; [fold]  [
Do_ROL_W_mem:
        prof    _ROL_W_mem
        Instr_To_EA_W
        Read_W                                          ;word to shift
        rol     dx,1
        Set_Flags_After_Rotation dx
        Write_W
        Next    8

; [fold]  ]


; [fold]  [
Do_ROR_B_Dx_Dx:
        prof    _ROR_B_Dx_Dx

        mov     ecx,eax                                 ;get Dx
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]                  ;number of shifts
        and     eax,7
        mov     dl,[byte ptr ebp+eax*4+base.D]
        and     cl,63
        jz      NoRots                                ;nothing to do if cl=0
        ror     dl,cl
        mov     [byte ptr ebp+eax*4+base.D],dl
        Set_Flags_After_Rotation dl
        Next    10
NoRots:
        Set_Flags_After_Rotation0 dl
        Next    10

; [fold]  ]

; [fold]  [
Do_ROR_W_Dx_Dx:
        prof    _ROR_W_Dx_Dx
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     eax,7
        mov     dx,[word ptr ebp+eax*4+base.D]
        and     cl,63
        jz      NoRott
        ror     dx,cl
        mov     [word ptr ebp+eax*4+base.D],dx
        Set_Flags_After_Rotation dx
        Next    10
NoRott:
        Set_Flags_After_Rotation0 dx
        Next    10

; [fold]  ]

; [fold]  [
Do_ROR_L_Dx_Dx:
        prof    _ROR_L_Dx_Dx
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     eax,7
        mov     edx,[dword ptr ebp+eax*4+base.D]
        and     cl,63
        jz      NoRotu
        ror     edx,cl
        mov     [dword ptr ebp+eax*4+base.D],edx
        Set_Flags_After_Rotation edx
        Next    16
NoRotu:
        Set_Flags_After_Rotation0 edx
        Next    16

; [fold]  ]

; [fold]  [
Do_ROR_B_Nb_Dx:
        prof    _ROR_B_Nb_Dx
        mov     ecx,eax                                 ;get number of shift
        shr     ecx,9
        and     eax,7
        mov     dl,[byte ptr ebp+eax*4+base.D]
        and     ecx,7
        jnz     NoRot8v
        mov     cl,8
NoRot8v:
        ror     dl,cl
        mov     [byte ptr ebp+eax*4+base.D],dl
        Set_Flags_After_Rotation dl
        Next    10

; [fold]  ]

; [fold]  [
Do_ROR_W_Nb_Dx:
        prof    _ROR_W_Nb_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        mov     dx,[WORD PTR  ebp+eax*4+base.D]
        and     ecx,7
        jnz     NoRot8w
        mov     cl,8
NoRot8w:
        ror     dx,cl
        mov     [word ptr ebp+eax*4+base.D],dx
        Set_Flags_After_Rotation dx
        Next    10

; [fold]  ]

; [fold]  [
Do_ROR_L_Nb_Dx:
        prof    _ROR_L_Nb_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        mov     edx,[dword ptr ebp+eax*4+base.D]
        and     ecx,7
        jnz     NoRot8x
        mov     cl,8
NoRot8x:
        ror     edx,cl
        mov     [dword ptr ebp+eax*4+base.D],edx
        Set_Flags_After_Rotation edx
        Next    16

; [fold]  ]

; [fold]  [
Do_ROR_W_mem:
        prof    _ROR_W_mem
        Instr_To_EA_W
        Read_W                                          ;word to shift
        ror     dx,1
        Set_Flags_After_Rotation dx
        Write_W
        Next    8

; [fold]  ]


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                ROXL ROXR
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

;********************************************* Flags setting after ROXL/ROXR
MACRO Set_Flags_After_XRotation Reg
        setc    al
        or      Reg,Reg
        lahf
        mov     [byte ptr ebp+base.X],al
        or      ah,al
        mov     [ebp+base.V],0
        mov     [byte ptr ebp+base.NZC],ah
ENDM

MACRO Set_Flags_After_XRotation0 Reg
        or      Reg,Reg
        lahf
        or      ah,[byte ptr ebp+base.X]                ;bit C=X; X unchanged
        mov     [ebp+base.V],0
        mov     [byte ptr ebp+base.NZC],ah
ENDM


; [fold]  [
Do_ROXL_B_Dx_Dx:
        prof    _ROXL_B_Dx_Dx

        mov     ecx,eax                                 ;get Dx
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]                  ;number of shifts
        and     eax,7
        mov     dl,[byte ptr ebp+eax*4+base.D]
        and     cl,63
        jz      NoRot_11                              ;nothing to do if cl=0
        shr     [byte ptr ebp+base.X],1               ;set later...can use it
        rcl     dl,cl
        mov     [byte ptr ebp+eax*4+base.D],dl
        Set_Flags_After_XRotation dl
        Next    10
NoRot_11:
        Set_Flags_After_XRotation0 dl
        Next    10

; [fold]  ]

; [fold]  [
Do_ROXL_W_Dx_Dx:
        prof    _ROXL_W_Dx_Dx
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     eax,7
        mov     dx,[word ptr ebp+eax*4+base.D]
        and     cl,63
        jz      NoRot_12
        shr     [byte ptr ebp+base.X],1
        rcl     dx,cl
        mov     [word ptr ebp+eax*4+base.D],dx
        Set_Flags_After_XRotation dx
        Next    10
NoRot_12:
        Set_Flags_After_XRotation0 dx
        Next    10

; [fold]  ]

; [fold]  [
Do_ROXL_L_Dx_Dx:
        prof    _ROXL_L_Dx_Dx

        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     eax,7
        mov     edx,[dword ptr ebp+eax*4+base.D]
        and     cl,63
        jz      NoRot_13
        shr     [byte ptr ebp+base.X],1
        rcl     edx,cl
        mov     [dword ptr ebp+eax*4+base.D],edx
        Set_Flags_After_XRotation edx
        Next    16
NoRot_13:
        Set_Flags_After_XRotation0 edx
        Next    16

; [fold]  ]

; [fold]  [
Do_ROXL_B_Nb_Dx:
        prof    _ROXL_B_Nb_Dx
        mov     ecx,eax                                 ;get number of shift
        shr     ecx,9
        and     eax,7
        mov     dl,[byte ptr ebp+eax*4+base.D]
        and     ecx,7
        jnz     @@NoRot8
        mov     cl,8
@@NoRot8:
        shr     [byte ptr ebp+base.X],1
        rcl     dl,cl
        mov     [byte ptr ebp+eax*4+base.D],dl
        Set_Flags_After_XRotation dl
        Next    10

; [fold]  ]

; [fold]  [
Do_ROXL_W_Nb_Dx:
        prof    _ROXL_W_Nb_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        mov     dx,[WORD PTR  ebp+eax*4+base.D]
        and     ecx,7
        jnz     @@NoRot8
        mov     cl,8
@@NoRot8:
        shr     [byte ptr ebp+base.X],1
        rcl     dx,cl
        mov     [word ptr ebp+eax*4+base.D],dx
        Set_Flags_After_XRotation dx
        Next    10

; [fold]  ]

; [fold]  [
Do_ROXL_L_Nb_Dx:
        prof    _ROXL_L_Nb_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        mov     edx,[dword ptr ebp+eax*4+base.D]
        and     ecx,7
        jnz     @@NoRot8
        mov     cl,8
@@NoRot8:
        shr     [byte ptr ebp+base.X],1
        rcl     edx,cl
        mov     [dword ptr ebp+eax*4+base.D],edx
        Set_Flags_After_XRotation edx
        Next    16

; [fold]  ]

; [fold]  [
Do_ROXL_W_mem:
        prof    _ROXL_W_mem
        Instr_To_EA_W
        Read_W                                          ;word to shift
        shr     [byte ptr ebp+base.X],1
        rcl     dx,1
        Set_Flags_After_XRotation dx
        Write_W
        Next    8

; [fold]  ]

; [fold]  [
Do_ROXR_B_Dx_Dx:
        prof    _ROXR_B_Dx_Dx
        mov     ecx,eax                                 ;get Dx
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]                  ;number of shifts
        and     eax,7
        mov     dl,[byte ptr ebp+eax*4+base.D]
        and     cl,63
        jz      NoRot_14                              ;nothing to do if cl=0
        shr     [byte ptr ebp+base.X],1                         ;set later...can use it
        rcr     dl,cl
        mov     [byte ptr ebp+eax*4+base.D],dl
        Set_Flags_After_XRotation dl
        Next    10
NoRot_14:
        Set_Flags_After_XRotation0 dl
        Next    10

; [fold]  ]

; [fold]  [
Do_ROXR_W_Dx_Dx:
        prof    _ROXR_W_Dx_Dx
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     eax,7
        mov     dx,[word ptr ebp+eax*4+base.D]
        and     cl,63
        jz      NoRot_15
        shr     [byte ptr ebp+base.X],1
        rcr     dx,cl
        mov     [word ptr ebp+eax*4+base.D],dx
        Set_Flags_After_XRotation dx
        Next    10
NoRot_15:
        Set_Flags_After_XRotation0 dx
        Next    10

; [fold]  ]

; [fold]  [
Do_ROXR_L_Dx_Dx:
        prof    _ROXR_L_Dx_Dx
        mov     ecx,eax
        shr     ecx,9
        and     ecx,7
        mov     cl,[byte ptr ebp+ecx*4+base.D]
        and     eax,7
        mov     edx,[dword ptr ebp+eax*4+base.D]
        and     cl,63
        jz      NoRot_16
        shr     [byte ptr ebp+base.X],1
        rcr     edx,cl
        mov     [dword ptr ebp+eax*4+base.D],edx
        Set_Flags_After_XRotation edx
        Next    16
NoRot_16:
        Set_Flags_After_XRotation0 edx
        Next    16

; [fold]  ]

; [fold]  [
Do_ROXR_B_Nb_Dx:
        prof    _ROXR_B_Nb_Dx
        mov     ecx,eax                                 ;get number of shift
        shr     ecx,9
        and     eax,7
        mov     dl,[byte ptr ebp+eax*4+base.D]
        and     ecx,7
        jnz     @@NoRot8
        mov     cl,8
@@NoRot8:
        shr     [byte ptr ebp+base.X],1
        rcr     dl,cl
        mov     [byte ptr ebp+eax*4+base.D],dl
        Set_Flags_After_XRotation dl
        Next    10

; [fold]  ]

; [fold]  [
Do_ROXR_W_Nb_Dx:
        prof    _ROXR_W_Nb_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        mov     dx, [WORD PTR ebp+eax*4+base.D]
        and     ecx,7
        jnz     @@NoRot8
        mov     cl,8
@@NoRot8:
        shr     [byte ptr ebp+base.X],1
        rcr     dx,cl
        mov     [word ptr ebp+eax*4+base.D],dx
        Set_Flags_After_XRotation dx
        Next    10

; [fold]  ]

; [fold]  [
Do_ROXR_L_Nb_Dx:
        prof    _ROXR_L_Nb_Dx
        mov     ecx,eax
        shr     ecx,9
        and     eax,7
        mov     edx,[dword ptr ebp+eax*4+base.D]
        and     ecx,7
        jnz     @@NoRot8
        mov     cl,8
@@NoRot8:
        shr     [byte ptr ebp+base.X],1
        rcr     edx,cl
        mov     [dword ptr ebp+eax*4+base.D],edx
        Set_Flags_After_XRotation edx
        Next    16

; [fold]  ]

; [fold]  [
Do_ROXR_W_mem:
        prof    _ROXR_W_mem
        Instr_To_EA_W
        Read_W                                          ;word to shift
        shr     [byte ptr ebp+base.X],1
        rcr     dx,1
        Set_Flags_After_XRotation dx
        Write_W
        Next    8

; [fold]  ]

        END
; [fold]  126
