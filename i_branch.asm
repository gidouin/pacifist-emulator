COMMENT ~
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
ณ Emulation of MATHs instructions                                          ณ
ณ                                                                          ณ
ณ       25/6/96  Converted all code to TASM IDEAL mode                     ณ
ณ        7/7/96  Optimization in Bcc & Dbcc                                ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
~
        IDEAL

        INCLUDE "simu68.inc"
        INCLUDE "profile.inc"

        CODESEG

        PUBLIC Do_RTS, DO_RTR, DO_TRAPV, DO_NOP, DO_RESET
        PUBLIC Do_TRAP, Do_JMP, Do_JSR
        PUBLIC Do_DBT, Do_DBF, Do_DBHI, Do_DBLS, Do_DBCC, Do_DBCS
        PUBLIC Do_DBNE, Do_DBEQ, Do_DBVC, Do_DBVS, Do_DBPL
        PUBLIC Do_DBMI
        PUBLIC Do_BRA_Long, Do_BRA_Short, Do_BSR_Long, Do_BSR_Short
        PUBLIC Do_BHI_Long, Do_BHI_Short, Do_BLS_Long, Do_BLS_Short
        PUBLIC Do_BCC_Long, Do_BCC_Short, Do_BCS_Long, Do_BCS_Short
        PUBLIC Do_BNE_Long, Do_BNE_Short, Do_BEQ_Long, Do_BEQ_Short
        PUBLIC Do_BVC_Long, Do_BVC_Short, Do_BVS_Long, Do_BVS_Short
        PUBLIC Do_BPL_Long, Do_BPL_Short, Do_BMI_Long, Do_BMI_Short

        PUBLIC Do_DBLT, Do_BLT_Long, Do_BLT_Short
        PUBLIC Do_DBGE, Do_BGE_Long, Do_BGE_Short
        PUBLIC Do_DBLE, Do_BLE_Long, Do_BLE_Short
        PUBLIC Do_DBGT, Do_BGT_Long, Do_BGT_Short



;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      NOP
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
Do_NOP:
        prof _NOP
        Next    4
Do_RESET:
        prof _RESET
        Next    132


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BSR
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_BSR_Short:
        prof    _BSR_Short
        mov     edx,esi         ;modified
        and     edx,0ffffffh
        or      edx,[HiByte_PC]
        or      edx,[PC_Base]
        movsx   ebx,al
        Push_Intel_LONG
        add     esi,ebx
        Next    18

Do_BSR_Long:
        prof    _BSR_Long

        mov     ax,[es:esi]
        mov     edx,esi         ;modified
        rol     ax,8
        add     edx,2
        and     edx,0ffffffh
        or      edx,[HiByte_PC]
        or      edx,[PC_Base]
        cwde
        Push_Intel_LONG
        add     esi,eax
        Next    18

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      RTS
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_RTS:
        prof    _RTS
        Pop_Intel_LONG
        mov     esi,edx
        CheckPC

        test    [Illegal_PC],1
        jnz      Trigger_BusError
        Next    16


; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BRA
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

MACRO Bra_S
        movsx   eax,al
        add     esi,eax
        Next    10
        align 4
        ENDM

MACRO Bra_L
        mov     ax,[es:esi]
        rol     ax,8
        cwde
        add     esi,eax
        Next    10
        align 4
        ENDM

        align 4

Do_Bra_Short:
        Bra_S

        align 4
Do_Bra_Long:
;        Bra_L
        cmp     [isPrefetch],0
        jne     @@PrefetchCase
@@normal:
        mov     ax,[es:esi]
        rol     ax,8
        cwde
        add     esi,eax
        Next    10

@@PrefetchCase:
        mov     eax,[PrefetchPC2]
        add     eax,2
        cmp     esi,eax
        jnz     @@normal

        mov     ax,[WORD PTR PrefetchQueue2+2]
        rol     ax,8
        cwde
        add     esi,eax
        Next    10


        align 4
Do_DBT:
        add     esi,2                   ;if not, continue
        Next    14

        align 4
Do_DBF:
        and     eax,7                           ;get data register
        dec     [WORD PTR ebp+eax*4+base.D]     ;decrement it (word)
        cmp     [WORD PTR ebp+eax*4+base.D],-1  ;if Dx.w != -1 -> branch
        je      short Do_DBT
        ;Bra_L
        jmp Do_Bra_Long

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BEQ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
Do_BEQ_Short:
        prof    _BEQ_Short
        test    [BYTE PTR ebp+base.NZC],40h
        jz      short @@NoBeq_S
        Bra_S
@@NoBeq_S:
        Next    8

Do_BEQ_Long:
        prof    _BEQ_Long
        test    [BYTE PTR ebp+base.NZC],40h
        jz      short @@NoBeq_L
        Bra_L
@@NoBeq_L:
        add     esi,2
        Next    12

Do_DBEQ:
        prof    _DBEQ
        test    [BYTE PTR ebp+base.NZC],40h
        jz      Do_DBF
        add     esi,2
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BNE
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_BNE_Short:
        prof    _BNE_Short
        test    [ebp+base.NZC],40h
        jnz     @@NoBne_S
        BRA_S
@@NoBne_S:
        Next    8

Do_BNE_Long:
        prof    _BNE_Long
        test    [ebp+base.NZC],40h
        jnz     @@NoBne_L
        BRA_L
@@NoBne_L:
        add     esi,2
        Next    12

Do_DBNE:
        prof    _DBNE
        test    [ebp+base.NZC],40h
        jnz     Do_DBF
        add     esi,2
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BCC
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_BCC_Short:
        prof    _BCC_Short
        test    [ebp+base.NZC],1
        jnz     short @@NoBcc_S
        BRA_S
@@NoBCC_S:
        Next    8

Do_BCC_Long:
        prof    _BCC_Long
        test    [ebp+base.NZC],1
        jnz     short @@NoBcc_L
        BRA_L
@@NoBcc_L:
        add     esi,2
        Next    12

Do_DBCC:
        prof    _DBCC
        test    [ebp+base.NZC],1
        jnz     Do_DBF
        add     esi,2
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BCS
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_BCS_Short:
        prof    _BCS_Short

        test    [ebp+base.NZC],1
        jz      short @@NoBcs_S
        BRA_S
@@NoBcs_S:
        Next    8

Do_BCS_Long:
        prof    _BCS_Long

        test    [ebp+base.NZC],1
        jz      short @@NoBcs_L
        BRA_L
@@NoBcs_L:
        add     esi,2
        Next    12

Do_DBCS:
        prof    _DBCS
        test    [ebp+base.NZC],1
        jz      Do_DBF
        add     esi,2
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BVC
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_BVC_Short:
        prof    _BVC_Short
        test    [ebp+base.V],1
        jnz     @@NoBvc_S
        BRA_S
@@NoBvc_S:
        Next    8

Do_BVC_Long:
        prof    _BVC_Long
        test    [ebp+base.V],1
        jnz     short @@NoBvc_L
        BRA_L
@@NoBvc_L:
        add     esi,2
        Next    12

Do_DBVC:
        prof    _DBVC
        test    [ebp+base.V],1
        jnz     Do_DBF
        add     esi,2
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BVS
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_BVS_Short:
        prof    _BVS_Short
        test    [ebp+base.V],1
        jz      @@NoBvs_S
        BRA_S
@@NoBVS_S:
        Next    8

Do_BVS_Long:
        prof    _BVS_Long
        test    [ebp+base.V],1
        jz      @@NoBvs_L
        BRA_L
@@NoBvs_L:
        add     esi,2
        Next    12

Do_DBVS:
        prof    _DBVS
        test    [ebp+base.V],1
        jz      Do_DBF
        add     esi,2
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BMI
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_BMI_Short:
        prof    _BMI_Short
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        jns     short @@NoBmi_S
        BRA_S
@@NoBMI_S:
        Next    8

Do_BMI_Long:
        prof    _BMI_Long
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        jns     short @@NoBmi_L
        BRA_L
@@NoBmi_L:
        add     esi,2
        Next    12

Do_DBMI:
        prof    _DBMI
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        jns     Do_DBF
        add     esi,2
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BPL
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_BPL_Short:
        prof    _BPL_Short
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        js      short @@NoBpl_S
        BRA_S
@@NoBpl_S:
        Next    8

Do_BPL_Long:
        prof    _BPL_Long
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        js      short @@NoBpl_L
        BRA_L
@@NoBpl_L:
        add     esi,2
        Next    12

Do_DBPL:
        prof    _DBPL
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        js      Do_DBF
        add     esi,2
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BHI
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_BHI_Short:                               ;HIGH: (C or Z)=0
        prof    _BHI_Short
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        jbe     short @@NoBhi_S
        BRA_S
@@NoBhi_S:
        Next    8

Do_BHI_Long:                                ;HIGH: (C or Z)=0
        prof    _BHI_Long
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        jbe     short @@NoBhi_L
        BRA_L
@@NoBhi_L:
        add     esi,2
        Next    12

Do_DBHI:
        prof    _DBHI
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        jbe     Do_DBF
        add     esi,2
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BLS
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_BLS_Short:                               ;LESS OR SAME: (C or Z)=1
        prof    _BLS_Short
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        jnbe    short @@NoBls_S
        BRA_S
@@NoBls_S:
        Next    8

Do_BLS_Long:                                ;LESS OR SAME: (C or Z)=1
        prof    _BLS_Long
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        jnbe    short @@NoBls_L
        BRA_L
@@NoBls_L:
        add     esi,2
        Next    12

Do_DBLS:
        prof    _DBLS
        mov     ah,[BYTE PTR ebp+base.NZC]
        sahf
        jnbe    Do_DBF
        add     esi,2
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BGE
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_BGE_Short:                               ;GREATER OR EQUAL (N xor V)=0
        prof    _BGE_Short

        mov     edx,[ebp+base.NZC]
        shr     edx,7
        xor     edx,[ebp+base.V]
        shr     edx,1
        jc      short @@NoBGE_S
        BRA_S
@@NoBGE_S:
        Next    8

Do_BGE_Long:                                ;GREATER OR EQUAL (N xor V)=0
        prof    _BGE_Long

        mov     ah,[BYTE PTR ebp+base.NZC]
        shr     ah,7                    ;bit 0=N
        xor     ah,[BYTE PTR ebp+base.V]        ;bit 9=N xor V
        shr     ah,1
        jc      short @@NoBGE_L
        BRA_L
@@NoBGE_L:
        add     esi,2
        Next    12

Do_DBGE:
        prof    _DBGE

        mov     ah,[BYTE PTR ebp+base.NZC]
        shr     ah,7
        xor     ah,[BYTE PTR ebp+base.V]
        shr     ah,1
        jc      Do_DBF
        add     esi,2
        Next    12

;
;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BLT
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_BLT_Short:
        prof    _BLT_Short

                       ;LESS THAN (N xor V)=1
        mov     ah,[BYTE PTR ebp+base.NZC]
        shr     ah,7                    ;bit 0=N
        xor     ah,[BYTE PTR ebp+base.V]        ;bit 0=N xor V
        shr     ah,1
        jnc     short @@NoBlt_S
        BRA_S
@@NoBlt_S:
        Next    8

Do_BLT_Long:                               ;LESS THAN (N xor V)=1
        prof    _BLT_Long

        mov     ah,[BYTE PTR ebp+base.NZC]
        shr     ah,7                    ;bit 0=N
        xor     ah,[BYTE PTR ebp+base.V]        ;bit 9=N xor V
        shr     ah,1
        jnc     short @@NoBlt_S
        BRA_L
@@NoBlt_S:
        add     esi,2
        Next    12

Do_DBLT:
        prof    _DBLT

        mov     ah,[BYTE PTR ebp+base.NZC]
        shr     ah,7
        xor     ah,[BYTE PTR ebp+base.V]
        shr     ah,1
        jnc     Do_DBF
        add     esi,2
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BLE
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

Do_BLE_Short:                               ;LESS OR EQUAL: (Z or (N xor V))=1
        prof    _BLE_Short

        mov     ah,[BYTE PTR ebp+base.NZC]
        mov     dl,ah
        shr     ah,7                    ;bit 0=N
        xor     ah,[BYTE PTR ebp+base.V]        ;bit 0=N xor V
        shr     dl,6                    ;bit 0=Z
        or      ah,dl                   ;bit 0=Z or (N xor V)
        shr     ah,1
        jnc     short @@NoBle_S
        BRA_S
@@NoBle_S:
        Next    8

Do_BLE_Long:                                ;LESS OR EQUAL: (Z or (N xor V))=1
        prof    _BLE_Long

        mov     ah,[BYTE PTR ebp+base.NZC]
        mov     dl,ah
        shr     ah,7                    ;bit 0=N
        xor     ah,[BYTE PTR ebp+base.V]        ;bit 0=N xor V
        shr     dl,6                    ;bit 0=Z
        or      ah,dl                   ;bit 0=Z or (N xor V)
        shr     ah,1
        jnc     short @@NoBle_L
        BRA_L
@@NoBle_L:
        add     esi,2
        Next    12

Do_DBLE:
        prof    _DBLE

        mov     ah,[BYTE PTR ebp+base.NZC]
        mov     dl,ah
        shr     ah,7
        xor     ah,[BYTE PTR ebp+base.V]
        shr     dl,6
        or      ah,dl
        shr     ah,1
        jnc     Do_DBF
        add     esi,2
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      BGT
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

;
Do_BGT_Short:                               ;GREATER THAN: (Z or (N xor V))=0
        prof    _BGT_Short

        mov     ah,[BYTE PTR ebp+base.NZC]
        mov     dl,ah
        shr     ah,7                    ;bit 0=N
        xor     ah,[BYTE PTR ebp+base.V]        ;bit 0=N xor V
        shr     dl,6                    ;bit 0=Z
        or      ah,dl                   ;bit 0=Z or (N xor V)
        shr     ah,1
        jc      short @@NoBgt_S
        BRA_S
@@NoBgt_S:
        Next    8

Do_BGT_Long:                                ;GREATER THAN: (Z or (N xor V))=0
        prof    _BGT_Long

        mov     ah,[BYTE PTR ebp+base.NZC]
        mov     dl,ah
        shr     ah,7                    ;bit 0=N
        xor     ah,[BYTE PTR ebp+base.V]        ;bit 0=N xor V
        shr     dl,6                    ;bit 0=Z
        or      ah,dl                   ;bit 0=Z or (N xor V)
        shr     ah,1
        jc      @@NoBgt_L
        BRA_L
@@NoBgt_L:
        add     esi,2
        Next    12

Do_DBGT:
        prof    _DBGT

        mov     ah,[BYTE PTR ebp+base.NZC]
        mov     dl,ah
        shr     ah,7
        xor     ah,[BYTE PTR ebp+base.V]
        shr     dl,6
        or      ah,dl
        shr     ah,1
        jc      Do_DBF
        add     esi,2
        Next    12

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      Bxx
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;        PUBLIC Do_DBxx, Do_Bxx_Long, Do_Bxx_Short
;
;        align 4
;Do_Bxx_Short:
;        mov     dh,ah                           ;xxxxCCCC xxxxxxxx
;        mov     ecx,[ebp+base.V]                ;00000000 0000000V
;        mov     dl,[BYTE PTR ebp+base.NZC]      ;xxxxCCCC NZxxxxxC
;        shl     ecx,1                           ;00000000 000000V0
;        and     edx,00fc1h                      ;0000CCCC NZ00000C
;        or      edx,ecx                         ;0000CCCC NZ0000VC
;
;        test    [Table_Conditions+edx],1
;        jnz     @@true
;        Next    4
;@@true:
;        movsx   edi,al
;        add     esi,edi
;        Next    10
;
;        align 4
;Do_Bxx_Long:
;        mov     ecx,[ebp+base.V]                ;00000000 0000000V
;        mov     al,[BYTE PTR ebp+base.NZC]      ;xxxxCCCC NZxxxxxC
;        shl     ecx,1                           ;00000000 000000V0
;        and     eax,00fc1h                      ;0000CCCC NZ00000C
;        or      eax,ecx                         ;0000CCCC NZ0000VC
;
;        test    [Table_Conditions+eax],1
;        jnz     @@true
;        add     esi,2
;        Next    12
;@@true:
;        mov     ax,[es:esi]
;        rol     ax,8
;        cwde
;        add     esi,eax
;        Next    10
;
;        align 4
;Do_DBxx:
;        mov     dh,ah
;        mov     ecx,[ebp+base.V]
;        mov     dl,[BYTE PTR ebp+base.NZC]
;        shl     ecx,1
;        and     edx,00fc1h
;        or      edx,ecx
;        and     eax,7
;        test    [Table_Conditions+edx],1
;        jnz     @@true
;
;        dec     [WORD PTR ebp+eax*4+base.D]
;        cmp     [WORD PTR ebp+eax*4+base.D],-1
;        je      @@true
;
;        mov     ax,[es:esi]
;        rol     ax,8
;        cwde
;        add     esi,eax
;        Next    10
;
;@@true:
;        add     esi,2
;        Next    14
;

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      JMP
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
Do_Jmp:
        prof    _JMP
        Instr_To_EA_L
        mov     esi,edi
        CheckPC
        test    [Illegal_PC],1
        jnz      Trigger_BusError
        Next    0


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      JSR
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
Do_Jsr:
        prof    _JSR
        Instr_To_EA_L
        mov     edx,esi
        mov     esi,0ffffffh
        and     esi,edi
        and     edx,0ffffffh
        or      edx,[HiByte_PC]
        or      edx,[PC_Base]
        Push_Intel_LONG
        CheckPC
        test    [Illegal_PC],1
        jnz     Trigger_BusError
        Next    8

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                      RTR
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_RTR:
        prof    _RTR
        Pop_Intel_WORD                          ;pop CCR & convert to PC
        mov     ax,[WORD PTR ebp+base.SR]
        and     ax,0ff00h
        and     dx,000ffh
        or      dx,ax
        mov     [WORD PTR ebp+base.SR],dx
        call    Convert_From_SR

        Pop_Intel_LONG                          ;pop new PC
        mov     esi,edx
        CheckPC

        test    [Illegal_PC],1
        jnz     Trigger_BusError
        Next    20

; [fold]  ]

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                    TRAPV
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  (
Do_TRAPV:
        prof    _TRAPV
        cmp     [ebp+base.V],0
        jnz     @@trapv
        Next    4
@@trapv:
        mov     eax,[ebp+base.IOPL]
        mov     [ebp+base.New_IOPL],eax
        mov     eax,_EXCEPTION_TRAPV
        jmp     Trigger_Exception

; [fold]  )

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                     TRAP
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; [fold]  [
Do_TRAP:
        prof    _TRAP
        mov     edx,[ebp+base.IOPL]
        mov     [ebp+basE.New_IOPL],edx
        and     eax,15
        add     eax,32                          ;add TRAP #0 vector
        jmp     Trigger_Exception

; [fold]  ]

        END

; [fold]  4
