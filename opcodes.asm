COMMENT ~
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
ณ Initialisation of Emulation                                              ณ
ณ                                                                          ณ
ณ      29/03/96  opcodes building functions Grouped                        ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
~
        IDEAL


        INCLUDE "simu68.inc"


        PUBLIC  Init_Instructions



        CODESEG

PROC Init_Instructions NEAR

        call    Init_Instructions_BRANCH
        call   Init_Instructions_MOVES
        call    Init_Instructions_MATHS
        call    Init_Instructions_LOGIC
        call    Init_Instructions_MOVEM

;        call    Init_Table_Conditions
        ret
        ENDP




;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                                    MATHS
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

PROC Init_Instructions_MATHS NEAR
        call    Init_Instructions_ADDX_SUBX
        call    Init_Instruction_ADDA
        call    Init_Instruction_SUBA
        call    Init_Instruction_CMPA
        call    Init_Instruction_ADDQ
        call    Init_Instruction_SUBQ
        call    Init_Instruction_CMPM
        call    Init_Instruction_TST
        call    Init_Instruction_EXT
        call    Init_Instructions_NEG_NEGX_NBCD
        call    Init_Instructions_MUL_DIV
        call    Init_Instruction_CHK
        call    Init_Instruction_TAS
        call    Init_Instructions_BCD
        call    Init_Instructions_ADD_SUB_CMP           ;ok <ea>
        call    Init_Instructions_ADDI_SUBI_CMPI        ;ok <ea>
        ret
        ENDP

       EXTRN Do_ABCD_Dx, Do_ABCD_Ax, Do_SBCD_Dx, Do_SBCD_Ax : NEAR
        EXTRN Do_NBCD_Dx, Do_NBCD_Mem : NEAR
        EXTRN Do_ADD_B_Dx_Dx, Do_ADD_W_Rx_Dx, Do_ADD_L_Rx_Dx : NEAR
        EXTRN Do_ADD_B_Mem_Dx, Do_ADD_W_Mem_Dx, Do_ADD_L_Mem_Dx : NEAR
        EXTRN Do_ADD_B_Dx_Mem, Do_ADD_W_Dx_Mem, Do_ADD_L_Dx_Mem : NEAR
        EXTRN Do_SUB_B_Dx_Dx, Do_SUB_W_Rx_Dx, Do_SUB_L_Rx_Dx : NEAR
        EXTRN Do_SUB_B_Mem_Dx, Do_SUB_W_Mem_Dx, Do_SUB_L_Mem_Dx : NEAR
        EXTRN Do_SUB_B_Dx_Mem, Do_SUB_W_Dx_Mem, Do_SUB_L_Dx_Mem : NEAR
        EXTRN Do_CMP_B_Dx_Dx, Do_CMP_W_Rx_Dx, Do_CMP_L_Rx_Dx : NEAR
        EXTRN Do_CMP_B_Mem_Dx,Do_CMP_W_Mem_Dx, Do_CMP_L_Mem_Dx : NEAR
        EXTRN Do_ADDI_B_To_Dx, Do_ADDI_W_To_Dx, Do_ADDI_L_To_Dx : NEAR
        EXTRN Do_ADDI_B_To_Mem, Do_ADDI_W_To_Mem, Do_ADDI_L_To_Mem : NEAR
        EXTRN Do_SUBI_B_To_Dx, Do_SUBI_W_To_Dx, Do_SUBI_L_To_Dx : NEAR
        EXTRN Do_SUBI_B_To_Mem, Do_SUBI_W_To_Mem, Do_SUBI_L_To_Mem : NEAR
        EXTRN Do_CMPI_B_To_Dx, Do_CMPI_W_To_Dx, Do_CMPI_L_To_Dx : NEAR
        EXTRN Do_CMPI_B_To_Mem, Do_CMPI_W_To_Mem, Do_CMPI_L_To_Mem : NEAR
        EXTRN Do_ADDA_W_To_Ax, Do_SUBA_W_To_Ax, Do_CMPA_W : NEAR
        EXTRN Do_ADDA_L_To_Ax, Do_SUBA_L_To_Ax, Do_CMPA_L : NEAR
        EXTRN Do_ADDQ_B_Dx, Do_ADDQ_W_Dx, Do_ADDQ_L_Dx : NEAR
        EXTRN Do_ADDQ_W_Ax, Do_ADDQ_L_Ax : NEAR
        EXTRN Do_ADDQ_B_Mem, Do_ADDQ_W_Mem, Do_ADDQ_L_Mem : NEAR
        EXTRN Do_SUBQ_B_Dx, Do_SUBQ_W_Dx, Do_SUBQ_L_Dx : NEAR
        EXTRN Do_SUBQ_W_Ax, Do_SUBQ_L_Ax, Do_SUBQ_B_Mem : NEAR
        EXTRN Do_SUBQ_W_Mem, Do_SUBQ_L_Mem : NEAR
        EXTRN Do_ADDX_B_Dx, Do_ADDX_W_Dx, Do_ADDX_L_Dx : NEAR
        EXTRN Do_ADDX_B_Aipd, Do_ADDX_W_Aipd, Do_ADDX_L_Aipd : NEAR
        EXTRN Do_SUBX_B_Dx, Do_SUBX_W_Dx, Do_SUBX_L_Dx : NEAR
        EXTRN Do_SUBX_B_Aipd, Do_SUBX_W_Aipd, Do_SUBX_L_Aipd : NEAR
        EXTRN Do_CMPM_B, Do_CMPM_W, Do_CMPM_L : NEAR
        EXTRN Do_TST_B_Dx, Do_TST_W_Dx, Do_TST_L_Dx : NEAR
        EXTRN Do_TST_B_Mem, Do_TST_W_Mem, Do_TST_L_Mem : NEAR
        EXTRN Do_TST_L_Mem_addressError : NEAR
        EXTRN Do_EXT_W, Do_EXT_L : NEAR
        EXTRN Do_NEG_B_Dx, Do_NEG_W_Dx, Do_NEG_L_Dx : NEAR
        EXTRN Do_NEG_B_Mem, Do_NEG_W_Mem, Do_NEG_L_Mem : NEAR
        EXTRN Do_NEGX_B_Dx, Do_NEGX_W_Dx, Do_NEGX_L_Dx : NEAR
        EXTRN Do_NEGX_B_Mem, Do_NEGX_W_Mem, Do_NEGX_L_Mem : NEAR
        EXTRN Do_MULU, Do_MULS, Do_DIVU, Do_DIVS :NEAR
        EXTRN Do_CHK_Dx, Do_CHK_mem : NEAR
        EXTRN Do_TAS_Dx, Do_TAS_Mem : NEAR

; [fold]  [
PROC Init_Instruction_CHK NEAR

        lea     edi, [Do_CHK_Dx]
        lea     ebx, [Valid_Modes_CHK_Dx]
        mov     edx, 04180h
        call    Add_CHK
        lea     edi, [Do_CHK_mem]
        lea     ebx, [Valid_Modes_CHK_mem]
        mov     edx, 04180h
        call    Add_CHK
        ret
        ENDP

Add_CHK:
        mov     ecx,[ebx]
        add     ebx,4
@@allmodes:
        mov     eax,edx
        or      ax,[ebx]
        add     ebx,2
        mov     esi,8
@@allregs:
        mov     [Opcodes_Jump+eax*4],edi
        add     eax,0200h
        dec     esi
        jnz     @@allregs
        dec     ecx
        jnz     @@allmodes
        ret

; [fold]  ]

; [fold]  [
PROC Init_Instructions_MUL_DIV NEAR

        lea     edi,[Do_DIVS]
        mov     edx,081c0h
        call    Add_MUL
        lea     edi,[Do_DIVU]
        mov     edx,080c0h
        call    Add_MUL
        lea     edi,[Do_MULS]
        mov     edx,0c1c0h
        call    Add_MUL
        lea     edi,[Do_MULU]
        mov     edx,0c0c0h
        call    Add_MUL
        ret
        ENDP

PROC Add_MUL NEAR
        lea     ebx,[Valid_Modes_MUL]
@@Nxt:
        mov     eax,edx                         ;initial mask
        or      ax,[ebx]                        ;add all valid adressing modes
        mov     ecx,8                           ;for all data registers
@@dreg:
        mov     [Opcodes_Jump+eax*4],edi
        add     eax,0200h
        dec     ecx
        jnz     @@dreg

        add     ebx,2                           ;next adressing mode
        cmp     ebx,OFFSET End_Valid_Modes_MUL
        jne     @@Nxt
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instructions_NEG_NEGX_NBCD NEAR

        lea     edx,[Valid_Modes_ADD_To_EA]
        mov     esi,04400h                      ;Mask NEG.B
        lea     edi,[Do_NEG_B_Mem]
        call    Add_ADDI
        mov     esi,04440h                      ;Mask NEG.W
        lea     edi,[Do_NEG_W_Mem]
        call    Add_ADDI
        mov     esi,04480h                      ;Mask NEG.L
        lea     edi,[Do_NEG_L_Mem]
        call    Add_ADDI

        lea     edx,[Valid_Modes_ADDI_To_Dx]
        mov     esi,04400h                      ;Mask NEG.B ,Dx
        lea     edi,[Do_NEG_B_Dx]
        call    Add_ADDI
        mov     esi,04440h                      ;Mask NEG.W ,Dx
        lea     edi,[Do_NEG_W_Dx]
        call    Add_ADDI
        mov     esi,04480h                      ;Mask NEG.L ,Dx
        lea     edi,[Do_NEG_L_Dx]
        call    Add_ADDI

;----------------------------------------------------------------------- negx

        lea     edx,[Valid_Modes_ADD_To_EA]
        mov     esi,04000h                      ;Mask NEGX.B
        lea     edi,[Do_NEGX_B_Mem]
        call    Add_ADDI
        mov     esi,04040h                      ;Mask NEGX.W
        lea     edi,[Do_NEGX_W_Mem]
        call    Add_ADDI
        mov     esi,04080h                      ;Mask NEGX.L
        lea     edi,[Do_NEGX_L_Mem]
        call    Add_ADDI

        lea     edx,[Valid_Modes_ADDI_To_Dx]
        mov     esi,04000h                      ;Mask NEGX.B ,Dx
        lea     edi,[Do_NEGX_B_Dx]
        call    Add_ADDI
        mov     esi,04040h                      ;Mask NEGX.W ,Dx
        lea     edi,[Do_NEGX_W_Dx]
        call    Add_ADDI
        mov     esi,04080h                      ;Mask NEGX.L ,Dx
        lea     edi,[Do_NEGX_L_Dx]
        call    Add_ADDI

;----------------------------------------------------------------------- nbcd

        lea     edx,[Valid_Modes_NBCD_Dx]
        mov     esi,04800h
        lea     edi,[Do_NBCD_Dx]
        call    Add_ADDI

        lea     edx,[Valid_Modes_NBCD_Mem]
        mov     esi,4800h
        lea     edi,[Do_NBCD_Mem]
        call    Add_ADDI
        ret

        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_EXT NEAR

        lea     edi,[Do_EXT_W]
        lea     esi,[Do_EXT_L]
        mov     eax,4880h                               ;EXT.W D0
        mov     ebx,48C0h                               ;EXT.L D0
@@allregs:
        mov     [Opcodes_Jump+eax*4],edi
        mov     [Opcodes_Jump+ebx*4],esi
        inc     eax
        inc     ebx
        cmp     eax,4888h
        jnz     @@allregs
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_TST NEAR
        lea     edx,[Valid_Modes_ADD_To_EA]
        mov     esi,04a00h                      ;Mask TST.B
        lea     edi,[Do_TST_B_Mem]
        call    Add_ADDI
        mov     esi,04a40h                      ;Mask TST.W
        lea     edi,[Do_TST_W_Mem]
        call    Add_ADDI
        mov     esi,04a80h                      ;Mask TST.L
        lea     edi,[Do_TST_L_Mem]
        call    Add_ADDI

        lea     edx,[Valid_Modes_ADDI_To_Dx]
        mov     esi,04a00h                      ;Mask TST.B ,Dx
        lea     edi,[Do_TST_B_Dx]
        call    Add_ADDI
        mov     esi,04a40h                      ;Mask TST.W ,Dx
        lea     edi,[Do_TST_W_Dx]
        call    Add_ADDI
        mov     esi,04a80h                      ;Mask TST.L ,Dx
        lea     edi,[Do_TST_L_Dx]
        call    Add_ADDI

        mov     [Opcodes_Jump+04a99h*4],OFFSET DO_TST_L_Mem_AddressError

        ret

        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_CMPM NEAR
        lea     edi, [Do_CMPM_B]
        mov     edx, 0b108h
        call    Add_CMPM
        lea     edi, [Do_CMPM_W]
        mov     edx, 0b148h
        call    Add_CMPM
        lea     edi, [Do_CMPM_L]
        mov     edx, 0b188h
        call    Add_CMPM
        ret
        ENDP

PROC Add_CMPM NEAR
        mov     ecx,8
@@allRx:
        mov     eax,edx
        mov     esi,8
@@allRy:
        mov     [Opcodes_Jump+eax*4],edi
        inc     eax
        dec     esi
        jnz     @@allRy

        add     edx,0200h
        dec     ecx
        jnz     @@allRx
        ret
        ENDP


; [fold]  ]

; [fold]  [
PROC Init_Instructions_ADDX_SUBX NEAR

        lea     edi,[Do_ADDX_B_Dx]
        mov     esi,0d100h              ; ADDX.B Dy,Dx
        call    Add_ADDX
        lea     edi,[Do_ADDX_W_Dx]
        mov     esi,0d140h              ; ADDX.W Dy,Dx
        call    Add_ADDX
        lea     edi,[Do_ADDX_L_Dx]
        mov     esi,0d180h              ; ADDX.L Dy,Dx
        call    Add_ADDX
        lea     edi,[Do_ADDX_B_Aipd]
        mov     esi,0d108h              ; ADDX.B -(Ay),-(Ax)
        call    Add_ADDX
        lea     edi,[Do_ADDX_W_Aipd]
        mov     esi,0d148h              ; ADDX.W -(Ay),-(Ax)
        call    Add_ADDX
        lea     edi,[Do_ADDX_L_Aipd]
        mov     esi,0d188h              ; ADDX.L -(Ay),-(Ax)
        call    Add_ADDX

;------------------------------------------------------------------------ subx

        lea     edi,[Do_SUBX_B_Dx]
        mov     esi,09100h              ; SUBX.B Dy,Dx
        call    Add_ADDX
        lea     edi,[Do_SUBX_W_Dx]
        mov     esi,09140h              ; SUBX.W Dy,Dx
        call    Add_ADDX
        lea     edi,[Do_SUBX_L_Dx]
        mov     esi,09180h              ; SUBX.L Dy,Dx
        call    Add_ADDX
        lea     edi,[Do_SUBX_B_Aipd]
        mov     esi,09108h              ; SUBX.B -(Ay),-(Ax)
        call    Add_ADDX
        lea     edi,[Do_SUBX_W_Aipd]
        mov     esi,09148h              ; SUBX.W -(Ay),-(Ax)
        call    Add_ADDX
        lea     edi,[Do_SUBX_L_Aipd]
        mov     esi,09188h              ; SUBX.L -(Ay),-(Ax)
        call    Add_ADDX

        ret
        ENDP

PROC Add_ADDX NEAR
                                        ; add function EDI with all variations
                                        ; of boths registers Rx & Ry

        mov     ebx,0h                  ;initial Rx
@@AllRx:
        mov     ecx,0h                  ;initial Ry
@@AllRy:
        mov     eax,ebx
        or      eax,ecx
        or      eax,esi
        mov     [Opcodes_Jump+eax*4],edi
        inc     ecx
        cmp     cx,8
        jnz     @@AllRy
        add     ebx,0200h
        cmp     ebx,1000h
        jnz     @@AllRx
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_SUBQ NEAR
        lea     ebx,[List_Modes_SUBQ]
@@allType:
        mov     edi,[ebx]                               ;SUBQ function
        mov     ecx,[ebx+4]                             ;nb modes to init
        mov     edx,[ebx+8]                             ;first mode
@@allmodes:
        mov     eax,05100h                              ;init mask: subq.? #0
        or      eax,edx                                 ;+ adressing mode
        inc     edx
        mov     esi,8                                   ;8 immd values
@@allvalues:
        mov     [Opcodes_Jump+eax*4],edi
        add     eax,200h                                ;next value
        dec     esi
        jnz     @@allvalues

        dec     ecx
        jnz     @@allmodes

        add     ebx,12
        cmp     ebx,OFFSET List_Modes_SUBQ_End
        jnz     @@allType
        ret
        ENDP


; [fold]  ]

; [fold]  [
PROC Init_Instruction_ADDQ NEAR
        lea     ebx,[List_Modes_ADDQ]
@@allType:
        mov     edi,[ebx]                               ;ADDQ function
        mov     ecx,[ebx+4]                             ;nb modes to init
        mov     edx,[ebx+8]                             ;first mode
@@allmodes:
        mov     eax,05000h                              ;init mask: addq.? #0
        or      eax,edx                                 ;+ adressing mode
        inc     edx
        mov     esi,8                                   ;8 immd values
@@allvalues:
        mov     [Opcodes_Jump+eax*4],edi
        add     eax,200h                                ;next value
        dec     esi
        jnz     @@allvalues

        dec     ecx
        jnz     @@allmodes

        add     ebx,12
        cmp     ebx,OFFSET List_Modes_ADDQ_End
        jnz     @@allType
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_CMPA NEAR

        lea     esi,[Do_CMPA_W]         ;1011 | reg 0|11 <ea> mask in EAX
        lea     edi,[Do_CMPA_L]         ;1011 | reg 1|11 <ea> mask in EDX

        mov     ebx,0000h               ;mask for A0 register
@@AllRegs:
        mov     eax,ebx
        mov     edx,ebx
        or      eax,0b0c0h              ;mask for CMPA.W <ea>,Ax
        or      edx,0b1c0h              ;mask for CMPA.L <ea>,Ax

        xor     ecx,ecx                 ;first valid of the 61 ea mode
@@AllEA:
        mov     [Opcodes_Jump+eax*4],esi
        mov     [Opcodes_Jump+edx*4],edi
        inc     eax
        inc     edx
        inc     ecx
        cmp     ecx,61
        jnz     @@AllEA

        add     ebx,0200h
        cmp     ebx,1000h
        jnz     @@AllRegs
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_SUBA NEAR

        lea     esi,[Do_SUBA_W_To_Ax]   ;1001 | reg 0|11 <ea> mask in EAX
        lea     edi,[Do_SUBA_L_To_Ax]   ;1001 | reg 1|11 <ea> mask in EDX

        mov     ebx,0000h               ;mask for A0 register
@@AllRegs:
        mov     eax,ebx
        mov     edx,ebx
        or      eax,090c0h              ;mask for SUBA.W <ea>,Ax
        or      edx,091c0h              ;mask for SUBA.L <ea>,Ax

        xor     ecx,ecx                 ;first valid of the 61 ea mode
@@AllEA:
        mov     [Opcodes_Jump+eax*4],esi
        mov     [Opcodes_Jump+edx*4],edi
        inc     eax
        inc     edx
        inc     ecx
        cmp     ecx,61
        jnz     @@AllEA

        add     ebx,0200h
        cmp     ebx,1000h
        jnz     @@AllRegs
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_ADDA NEAR

        lea     esi,[Do_ADDA_W_To_Ax]   ;1101 | reg 0|11 <ea> mask in EAX
        lea     edi,[Do_ADDA_L_To_Ax]   ;1101 | reg 1|11 <ea> mask in EDX

        mov     ebx,0000h               ;mask for A0 register
@@AllRegs:
        mov     eax,ebx
        mov     edx,ebx
        or      eax,0d0c0h              ;mask for MOVEA.W <ea>,Ax
        or      edx,0d1c0h              ;mask for MOVEA.L <ea>,Ax

        xor     ecx,ecx                 ;first valid of the 61 ea mode
@@AllEA:
        mov     [Opcodes_Jump+eax*4],esi
        mov     [Opcodes_Jump+edx*4],edi
        inc     eax
        inc     edx
        inc     ecx
        cmp     ecx,61
        jnz     @@AllEA

        add     ebx,0200h
        cmp     ebx,1000h
        jnz     @@AllRegs
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instructions_ADDI_SUBI_CMPI NEAR
        lea     ebx,[Valid_Modes_ADDI_To_Dx]
        mov     esi,00600h                      ;Mask ADDI.B Dx
        lea     edi,[Do_ADDI_B_To_Dx]
        call    Add_ADDI_Dx
        mov     esi,00640h                      ;Mask ADDI.W Dx
        lea     edi,[Do_ADDI_W_To_Dx]
        call    Add_ADDI_Dx
        mov     esi,00680h                      ;Mask ADDI.L Dx
        lea     edi,[Do_ADDI_L_To_Dx]
        call    Add_ADDI_Dx
        mov     esi,00400h                      ;Mask SUBI.B Dx
        lea     edi,[Do_SUBI_B_To_Dx]
        call    Add_ADDI_Dx
        mov     esi,00440h                      ;Mask SUBI.W Dx
        lea     edi,[Do_SUBI_W_To_Dx]
        call    Add_ADDI_Dx
        mov     esi,00480h                      ;Mask SUBI.L Dx
        lea     edi,[Do_SUBI_L_To_Dx]
        call    Add_ADDI_Dx
        mov     esi,00c00h                      ;Mask CMPI.B Dx
        lea     edi,[Do_CMPI_B_To_Dx]
        call    Add_ADDI_Dx
        mov     esi,00c40h                      ;Mask CMPI.W Dx
        lea     edi,[Do_CMPI_W_To_Dx]
        call    Add_ADDI_Dx
        mov     esi,00c80h                      ;Mask CMPI.L Dx
        lea     edi,[Do_CMPI_L_To_Dx]
        call    Add_ADDI_Dx

        lea     ebx,[Valid_Modes_ADDI_To_Mem]
        mov     esi,00600h                      ;Mask ADDI.B Mem
        lea     edi,[Do_ADDI_B_To_Mem]
        call    Add_ADDI_Mem
        mov     esi,00640h                      ;Mask ADDI.W Mem
        lea     edi,[Do_ADDI_W_To_Mem]
        call    Add_ADDI_Mem
        mov     esi,00680h                      ;Mask ADDI.L Mem
        lea     edi,[Do_ADDI_L_To_Mem]
        call    Add_ADDI_Mem
        mov     esi,00400h                      ;Mask SUBI.B Mem
        lea     edi,[Do_SUBI_B_To_Mem]
        call    Add_ADDI_Mem
        mov     esi,00440h                      ;Mask SUBI.W Mem
        lea     edi,[Do_SUBI_W_To_Mem]
        call    Add_ADDI_Mem
        mov     esi,00480h                      ;Mask SUBI.L Mem
        lea     edi,[Do_SUBI_L_To_Mem]
        call    Add_ADDI_Mem
        mov     esi,00c00h                      ;Mask CMPI.B Mem
        lea     edi,[Do_CMPI_B_To_Mem]
        call    Add_ADDI_Mem
        mov     esi,00c40h                      ;Mask CMPI.W Mem
        lea     edi,[Do_CMPI_W_To_Mem]
        call    Add_ADDI_Mem
        mov     esi,00c80h                      ;Mask CMPI.L Mem
        lea     edi,[Do_CMPI_L_To_Mem]
        call    Add_ADDI_Mem
        ret


Add_ADDI_Dx:
        push    ebx
        mov     ecx,[ebx]
        add     ebx,4
@@allof:
        push    esi
        or      si,[ebx]        ; this <ea> mode
        add     ebx,2
        mov     eax,esi
        mov     edx,8           ; 8 registers
@@all8:
        mov     [Opcodes_Jump+eax*4],edi
        inc     eax
        dec     edx
        jnz     @@all8
        pop     esi
        dec     ecx
        jnz     @@allof
        pop     ebx
        ret


Add_ADDI_Mem:
        push    ebx
        mov     ecx,[ebx]
        add     ebx,4
@@allofm:
        push    esi
        or      si,[ebx]        ; this <ea> mode
        add     ebx,2
        mov     [Opcodes_Jump+esi*4],edi
        pop     esi
        dec     ecx
        jnz     @@allofm
        pop     ebx
        ret
        ENDP

; [fold]  ]

; [fold]  [
Add_ADDI:
        push    edx
        mov     ecx,[edx]
        add     edx,4
@@allofm:
        push    esi
        or      si,[edx]        ; this <ea> mode
        add     edx,2
        mov     [Opcodes_Jump+esi*4],edi
        pop     esi
        dec     ecx
        jnz     @@allofm
        pop     edx
        ret

; [fold]  ]

; [fold]  [
PROC Init_Instructions_ADD_SUB_CMP NEAR
        lea     ebx,[Valid_Modes_ADD_Dx_Dx]
        mov     esi,0d000h                      ;ADD.B Dx,Dx
        lea     edi,[Do_ADD_B_Dx_Dx]
        call    Add_ADD_S

        lea     ebx,[Valid_Modes_ADD_Rx_Dx]
        mov     esi,0d040h                      ;ADD.W Dx,Dx
        lea     edi,[Do_ADD_W_Rx_Dx]
        call    Add_ADD_S
        mov     esi,0d080h                      ;ADD.L Dx,Dx
        lea     edi,[Do_ADD_L_Rx_Dx]
        call    Add_ADD_S
        mov     esi,0d048h                      ;ADD.W Ax,Dx
        lea     edi,[Do_ADD_W_Rx_Dx]
        call    Add_ADD_S
        mov     esi,0d088h                      ;ADD.L Ax,Dx
        lea     edi,[Do_ADD_L_Rx_Dx]
        call    Add_ADD_S
        lea     ebx,[Valid_Modes_Add_Mem_Dx]
        mov     esi,0d000h                      ;ADD.B Mem,Dx
        lea     edi,[Do_ADD_B_Mem_Dx]
        call    Add_ADD_S
        mov     esi,0d040h                      ;ADD.W Mem,Dx
        lea     edi,[Do_ADD_W_Mem_Dx]
        call    Add_ADD_S
        mov     esi,0d080h                      ;ADD.L Mem,Dx
        lea     edi,[Do_ADD_L_Mem_Dx]
        call    Add_ADD_S
        lea     ebx,[Valid_Modes_Add_Dx_Mem]
        mov     esi,0d100h                      ;ADD.B Dx,Mem
        lea     edi,[Do_ADD_B_Dx_Mem]
        call    Add_ADD_S
        mov     esi,0d140h                      ;ADD.W Dx,Mem
        lea     edi,[Do_ADD_W_Dx_Mem]
        call    Add_ADD_S
        mov     esi,0d180h                      ;ADD.L Dx,Mem
        lea     edi,[Do_ADD_L_Dx_Mem]
        call    Add_ADD_S


        lea     ebx,[Valid_Modes_ADD_Dx_Dx]
        mov     esi,09000h                      ;SUB.B Dx,Dx
        lea     edi,[Do_SUB_B_Dx_Dx]
        call    Add_ADD_S

        lea     ebx,[Valid_Modes_ADD_Rx_Dx]
        mov     esi,09040h                      ;SUB.W Dx,Dx
        lea     edi,[Do_SUB_W_Rx_Dx]
        call    Add_ADD_S
        mov     esi,09080h                      ;SUB.L Dx,Dx
        lea     edi,[Do_SUB_L_Rx_Dx]
        call    Add_ADD_S
        mov     esi,09048h                      ;SUB.W Ax,Dx
        lea     edi,[Do_SUB_W_Rx_Dx]
        call    Add_ADD_S
        mov     esi,09088h                      ;SUB.L Ax,Dx
        lea     edi,[Do_SUB_L_Rx_Dx]
        call    Add_ADD_S
        lea     ebx,[Valid_Modes_Add_Mem_Dx]
        mov     esi,09000h                      ;SUB.B Mem,Dx
        lea     edi,[Do_SUB_B_Mem_Dx]
        call    Add_ADD_S
        mov     esi,09040h                      ;SUB.W Mem,Dx
        lea     edi,[Do_SUB_W_Mem_Dx]
        call    Add_ADD_S
        mov     esi,09080h                      ;SUB.L Mem,Dx
        lea     edi,[Do_SUB_L_Mem_Dx]
        call    Add_ADD_S
        lea     ebx,[Valid_Modes_Add_Dx_Mem]
        mov     esi,09100h                      ;SUB.B Dx,Mem
        lea     edi,[Do_SUB_B_Dx_Mem]
        call    Add_ADD_S
        mov     esi,09140h                      ;SUB.W Dx,Mem
        lea     edi,[Do_SUB_W_Dx_Mem]
        call    Add_ADD_S
        mov     esi,09180h                      ;SUB.L Dx,Mem
        lea     edi,[Do_SUB_L_Dx_Mem]
        call    Add_ADD_S

        lea     ebx,[Valid_Modes_ADD_Dx_Dx]
        mov     esi,0b000h                      ;CMP.B Dx,Dx
        lea     edi,[Do_CMP_B_Dx_Dx]
        call    Add_ADD_S

        lea     ebx,[Valid_Modes_ADD_Rx_Dx]
        mov     esi,0b040h                      ;CMP.W Dx,Dx
        lea     edi,[Do_CMP_W_Rx_Dx]
        call    Add_ADD_S
        mov     esi,0b080h                      ;CMP.L Dx,Dx
        lea     edi,[Do_CMP_L_Rx_Dx]
        call    Add_ADD_S
        mov     esi,0b048h                      ;CMP.W Ax,Dx
        lea     edi,[Do_CMP_W_Rx_Dx]
        call    Add_ADD_S
        mov     esi,0b088h                      ;CMP.L Ax,Dx
        lea     edi,[Do_CMP_L_Rx_Dx]
        call    Add_ADD_S
        lea     ebx,[Valid_Modes_Add_Mem_Dx]
        mov     esi,0b000h                      ;CMP.B Mem,Dx
        lea     edi,[Do_CMP_B_Mem_Dx]
        call    Add_ADD_S
        mov     esi,0b040h                      ;CMP.W Mem,Dx
        lea     edi,[Do_CMP_W_Mem_Dx]
        call    Add_ADD_S
        mov     esi,0b080h                      ;CMP.L Mem,Dx
        lea     edi,[Do_CMP_L_Mem_Dx]
        call    Add_ADD_S
        ret

Add_ADD_S:
        push    ebx
        mov     ecx,[ebx]
        add     ebx,4
@@allof:
        push    esi
        or      si,[ebx]        ; this <ea> mode
        add     ebx,2
        mov     eax,esi
        mov     edx,8           ; 8 registers
@@all8:
        mov     [Opcodes_Jump+eax*4],edi
        add     eax,200h
        dec     edx
        jnz     @@all8
        pop     esi
        dec     ecx
        jnz     @@allof
        pop     ebx
        ret

        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_TAS NEAR
        lea     edx,[Valid_Modes_TAS_MEM]
        mov     esi,04ac0h                      ;Mask TAS mem
        lea     edi,[Do_TAS_Mem]
        call    Add_ADDI

        lea     edx,[Valid_Modes_ADDI_To_Dx]
        mov     esi,04ac0h                      ;Mask TAS Dx
        lea     edi,[Do_TAS_Dx]
        call    Add_ADDI
        ret

        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instructions_BCD NEAR
        mov     esi,0c100h
        lea     edi,[Do_ABCD_Dx]
        call    Add_ABCD
        mov     esi,0c108h
        lea     edi,[Do_ABCD_Ax]
        call    Add_ABCD

        mov     esi,08100h
        lea     edi,[Do_SBCD_Dx]
        call    Add_ABCD
        mov     esi,08108h
        lea     edi,[Do_SBCD_Ax]
        call    Add_ABCD
        ret

Add_ABCD:
        mov     ecx,8
@@allRx:
        mov     eax,esi
        mov     edx,8
@@allRy:
        mov     [Opcodes_Jump+eax*4],edi
        add     eax,200h
        dec     edx
        jnz     @@allRy
        inc     esi
        dec     ecx
        jnz     @@allRx
        ret
        ENDP


; [fold]  ]

        DATASEG

LABEL Valid_Modes_ADDI_To_Dx
        dd      8
        dw      0,1,2,3,4,5,6,7,8

LABEL Valid_Modes_ADDI_To_Mem
        dd      42
        dw      10h,11h,12h,13h,14h,15h,16h,17h
        dw      18h,19h,1ah,1bh,1ch,1dh,1eh,1fh
        dw      20h,21h,22h,23h,24h,25h,26h,27h
        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh
        dw      30h,31h,32h,33h,34h,35h,36h,37h
        dw      38h,39h


LABEL Valid_Modes_ADD_Dx_Dx
        dd      8
        dw      0,1,2,3,4,5,6,7,8
LABEL Valid_Modes_ADD_Rx_Dx
        dd      16
        dw      0,1,2,3,4,5,6,7,8
        dw      9,10,11,12,13,14,15
LABEL Valid_Modes_ADD_Mem_Dx
        dd      45
        dw      10h,11h,12h,13h,14h,15h,16h,17h
        dw      18h,19h,1ah,1bh,1ch,1dh,1eh,1fh
        dw      20h,21h,22h,23h,24h,25h,26h,27h
        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh
        dw      30h,31h,32h,33h,34h,35h,36h,37h
        dw      38h,39h,3ah,3bh,3ch
LABEL Valid_Modes_ADD_Dx_Mem
        dd      42
        dw      10h,11h,12h,13h,14h,15h,16h,17h
        dw      18h,19h,1ah,1bh,1ch,1dh,1eh,1fh
        dw      20h,21h,22h,23h,24h,25h,26h,27h
        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh
        dw      30h,31h,32h,33h,34h,35h,36h,37h
        dw      38h,39h
LABEL Valid_Modes_CHK_Dx
        dd      8
        dw      00h,01h,02h,03h,04h,05h,06h,07h
LABEL Valid_Modes_CHK_mem
        dd      45
        dw      10h,11h,12h,13h,14h,15h,16h,17h
        dw      18h,19h,1ah,1bh,1ch,1dh,1eh,1fh
        dw      20h,21h,22h,23h,24h,25h,26h,27h
        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh
        dw      30h,31h,32h,33h,34h,35h,36h,37h
        dw      38h,39h,3ah,3bh,3ch
LABEL Valid_Modes_MUL
        dw      00h,01h,02h,03h,04h,05h,06h,07h
        dw      10h,11h,12h,13h,14h,15h,16h,17h
        dw      18h,19h,1ah,1bh,1ch,1dh,1eh,1fh
        dw      20h,21h,22h,23h,24h,25h,26h,27h
        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh
        dw      30h,31h,32h,33h,34h,35h,36h,37h
        dw      38h,39h,3ah,3bh,3ch
LABEL END_Valid_Modes_MUL

LABEL List_Modes_ADDQ
        dd      Do_ADDQ_B_Dx                            ;Adress Function
        dd      8                                       ;Nb of adressing modes
        dd      00h                                     ;First adressing modes
        dd      Do_ADDQ_W_Dx
        dd      8
        dd      40h
        dd      Do_ADDQ_L_Dx
        dd      8
        dd      80h
        dd      Do_ADDQ_W_Ax
        dd      8
        dd      48h
        dd      Do_ADDQ_L_Ax
        dd      8
        dd      88h
        dd      Do_ADDQ_B_mem
        dd      42
        dd      10h
        dd      Do_ADDQ_W_mem
        dd      42
        dd      50h
        dd      Do_ADDQ_L_mem
        dd      42
        dd      90h
LABEL List_Modes_ADDQ_End

LABEL List_Modes_SUBQ
        dd      Do_SUBQ_B_Dx                            ;Adress Function
        dd      8                                       ;Nb of adressing modes
        dd      00h                                     ;First adressing modes
        dd      Do_SUBQ_W_Dx
        dd      8
        dd      40h
        dd      Do_SUBQ_L_Dx
        dd      8
        dd      80h
        dd      Do_SUBQ_W_Ax
        dd      8
        dd      48h
        dd      Do_SUBQ_L_Ax
        dd      8
        dd      88h
        dd      Do_SUBQ_B_mem
        dd      42
        dd      10h
        dd      Do_SUBQ_W_mem
        dd      42
        dd      50h
        dd      Do_SUBQ_L_mem
        dd      42
        dd      90h
LABEL List_Modes_SUBQ_End

LABEL Valid_Modes_ADD_To_Dx
        dd      61                                      ;61 modes autoriss
        dw      000h,001h,002h,003h,004h,005h,006h,007h
        dw      008h,009h,00ah,00bh,00ch,00dh,00eh,00fh
        dw      010h,011h,012h,013h,014h,015h,016h,017h
        dw      018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
        dw      020h,021h,022h,023h,024h,025h,026h,027h
        dw      028h,029h,02ah,02bh,02ch,02dh,02eh,02fh
        dw      030h,031h,032h,033h,034h,035h,036h,037h
        dw      038h,039h,03ah,03bh,03ch

LABEL Valid_Modes_ADD_To_EA
        dd      61-16
        dw      010h,011h,012h,013h,014h,015h,016h,017h
        dw      018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
        dw      020h,021h,022h,023h,024h,025h,026h,027h
        dw      028h,029h,02ah,02bh,02ch,02dh,02eh,02fh
        dw      030h,031h,032h,033h,034h,035h,036h,037h
        dw      038h,039h,03ah,03bh,03ch

LABEL Valid_Modes_TAS_Mem
        dd      61-19
        dw      010h,011h,012h,013h,014h,015h,016h,017h
        dw      018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
        dw      020h,021h,022h,023h,024h,025h,026h,027h
        dw      028h,029h,02ah,02bh,02ch,02dh,02eh,02fh
        dw      030h,031h,032h,033h,034h,035h,036h,037h
        dw      038h,039h;,03ah,03bh,03ch


LABEL Valid_Modes_NBCD_Dx
        dd      8
        dw      000h,001h,002h,003h,004h,005h,006h,007h

LABEL Valid_Modes_NBCD_Mem
        dd      61-19
        dw      010h,011h,012h,013h,014h,015h,016h,017h
        dw      018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
        dw      020h,021h,022h,023h,024h,025h,026h,027h
        dw      028h,029h,02ah,02bh,02ch,02dh,02eh,02fh
        dw      030h,031h,032h,033h,034h,035h,036h,037h
        dw      038h,039h

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                                    LOGIC
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

        CODESEG

PROC Init_Instructions_LOGIC NEAR
        call    Init_Instruction_Bits           ;BTST, BCLR, BCHG, BSET
        call    Init_Instructions_Shifts        ;LSd ASd ROd ROXd
        call    Init_Instructions_CCR_SR        ;ANDI ORI EORI CCR/SR
        call    Init_Instructions_AND_EOR_OR    ;AND EOR OR
        call    Init_Instructions_ANDI_EORI_ORI ;ANDI EORI ORI
        call    Init_Instruction_NOT            ;NOT
        ret
        ENDP

        EXTRN Do_BTST_L_Dx_Dx, Do_BTST_L_Nb_Dx : NEAR
        EXTRN Do_BTST_B_Dx_mem, Do_BTST_B_Nb_mem : NEAR
        EXTRN Do_BSET_L_Dx_Dx, Do_BSET_L_Nb_Dx : NEAR
        EXTRN Do_BSET_B_Dx_mem, Do_BSET_B_Nb_mem : NEAR
        EXTRN Do_BCLR_L_Dx_Dx, Do_BCLR_L_Nb_Dx : NEAR
        EXTRN Do_BCLR_B_Dx_mem, Do_BCLR_B_Nb_mem : NEAR
        EXTRN Do_BCHG_L_Dx_Dx, Do_BCHG_L_Nb_Dx : NEAR
        EXTRN Do_BCHG_B_Dx_mem, Do_BCHG_B_Nb_mem : NEAR
        EXTRN Do_AND_B_Mem_To_Dx, Do_AND_W_Mem_To_Dx : NEAR
        EXTRN Do_AND_L_Mem_To_Dx, Do_AND_B_Dx_To_Dx : NEAR
        EXTRN Do_AND_W_Dx_To_Dx, Do_AND_L_Dx_To_Dx : NEAR
        EXTRN Do_AND_B_Dx_To_Mem,Do_AND_W_Dx_To_Mem : NEAR
        EXTRN Do_AND_L_Dx_To_Mem, Do_OR_B_Mem_To_Dx : NEAR
        EXTRN Do_OR_W_Mem_To_Dx, Do_OR_L_Mem_To_Dx : NEAR
        EXTRN Do_OR_B_Dx_To_Dx, Do_OR_W_Dx_To_Dx : NEAR
        EXTRN Do_OR_L_Dx_To_Dx, Do_OR_B_Dx_To_Mem : NEAR
        EXTRN Do_OR_W_Dx_To_Mem, Do_OR_L_Dx_To_Mem : NEAR
        EXTRN Do_EOR_B_Dx_To_Dx, Do_EOR_W_Dx_To_Dx : NEAR
        EXTRN Do_EOR_L_Dx_To_Dx, Do_EOR_B_Dx_To_Mem : NEAR
        EXTRN Do_EOR_W_Dx_To_Mem, Do_EOR_L_Dx_To_Mem : NEAR
        EXTRN Do_ANDI_B_To_Mem, Do_ANDI_W_To_Mem, Do_ANDI_L_To_Mem : NEAR
        EXTRN Do_ANDI_B_To_Dx, Do_ANDI_W_To_Dx, Do_ANDI_L_To_Dx : NEAR
        EXTRN Do_ORI_B_To_Mem, Do_ORI_W_To_Mem ,Do_ORI_L_To_Mem : NEAR
        EXTRN Do_ORI_B_To_Dx, Do_ORI_W_To_Dx, Do_ORI_L_To_Dx : NEAR
        EXTRN Do_EORI_B_To_Mem, Do_EORI_W_To_Mem, Do_EORI_L_To_Mem : NEAR
        EXTRN Do_EORI_B_To_Dx, Do_EORI_W_To_Dx, Do_EORI_L_To_Dx : NEAR
        EXTRN Do_NOT_B_Dx, Do_NOT_W_Dx, Do_NOT_L_Dx : NEAR
        EXTRN Do_NOT_B_Mem, Do_NOT_W_Mem, Do_NOT_L_Mem : NEAR
        EXTRN Do_ANDI_CCR, Do_ANDI_SR, Do_EORI_CCR, Do_EORI_SR : NEAR
        EXTRN Do_ORI_CCR, Do_ORI_SR : NEAR
        EXTRN Do_LSL_B_Dx_Dx, Do_LSL_W_Dx_Dx, Do_LSL_L_Dx_Dx : NEAR
        EXTRN Do_LSL_B_Nb_Dx, Do_LSL_W_Nb_Dx, Do_LSL_L_Nb_Dx : NEAR
        EXTRN Do_LSL_W_mem : NEAR
        EXTRN Do_LSR_B_Dx_Dx, Do_LSR_W_Dx_Dx, Do_LSR_L_Dx_Dx : NEAR
        EXTRN Do_LSR_B_Nb_Dx, Do_LSR_W_Nb_Dx, Do_LSR_L_Nb_Dx : NEAR
        EXTRN Do_LSR_W_mem : NEAR
        EXTRN Do_ASL_B_Dx_Dx, Do_ASL_W_Dx_Dx, Do_ASL_L_Dx_Dx : NEAR
        EXTRN Do_ASL_B_Nb_Dx, Do_ASL_W_Nb_Dx, Do_ASL_L_Nb_Dx : NEAR
        EXTRN Do_ASL_W_mem : NEAR
        EXTRN Do_ASR_B_Dx_Dx, Do_ASR_W_Dx_Dx, Do_ASR_L_Dx_Dx : NEAR
        EXTRN Do_ASR_B_Nb_Dx, Do_ASR_W_Nb_Dx, Do_ASR_L_Nb_Dx : NEAR
        EXTRN Do_ASR_W_mem : NEAR
        EXTRN Do_ROL_B_Dx_Dx, Do_ROL_W_Dx_Dx, Do_ROL_L_Dx_Dx : NEAR
        EXTRN Do_ROL_B_Nb_Dx, Do_ROL_W_Nb_Dx, Do_ROL_L_Nb_Dx : NEAR
        EXTRN Do_ROL_W_mem : NEAR
        EXTRN Do_ROR_B_Dx_Dx, Do_ROR_W_Dx_Dx, Do_ROR_L_Dx_Dx : NEAR
        EXTRN Do_ROR_B_Nb_Dx, Do_ROR_W_Nb_Dx, Do_ROR_L_Nb_Dx : NEAR
        EXTRN Do_ROR_W_mem : NEAR
        EXTRN Do_ROXL_B_Dx_Dx, Do_ROXL_W_Dx_Dx, Do_ROXL_L_Dx_Dx : NEAR
        EXTRN Do_ROXL_B_Nb_Dx, Do_ROXL_W_Nb_Dx, Do_ROXL_L_Nb_Dx : NEAR
        EXTRN Do_ROXL_W_mem : NEAR
        EXTRN Do_ROXR_B_Dx_Dx, Do_ROXR_W_Dx_Dx, Do_ROXR_L_Dx_Dx : NEAR
        EXTRN Do_ROXR_B_Nb_Dx, Do_ROXR_W_Nb_Dx, Do_ROXR_L_Nb_Dx : NEAR
        EXTRN Do_ROXR_W_mem : NEAR


; [fold]  [
PROC Init_Instruction_Bits NEAR

;---------------------------------------------------------------------- btst
        lea     ebx,[Valid_Modes_BTST_To_Dx]
        lea     edi,[Do_BTST_L_Dx_Dx]
        mov     edx,0100h
        call    Add_Bits_Dx
        lea     ebx,[Valid_Modes_BTST_To_Dx]
        lea     edi,[Do_BTST_L_Nb_Dx]
        mov     edx,0800h
        call    Add_Bits_Nb
        lea     ebx,[Valid_Modes_BTST_To_mem]
        lea     edi,[Do_BTST_B_Dx_mem]
        mov     edx,0100h
        call    Add_Bits_Dx
        lea     ebx,[Valid_Modes_BTST_To_mem]
        lea     edi,[Do_BTST_B_Nb_mem]
        mov     edx,0800h
        call    Add_Bits_Nb
;---------------------------------------------------------------------- bset
        lea     ebx,[Valid_Modes_BTST_To_Dx]
        lea     edi,[Do_BSET_L_Dx_Dx]
        mov     edx,01c0h
        call    Add_Bits_Dx
        lea     ebx,[Valid_Modes_BTST_To_Dx]
        lea     edi,[Do_BSET_L_Nb_Dx]
        mov     edx,08c0h
        call    Add_Bits_Nb
        lea     ebx,[Valid_Modes_BTST_To_mem]
        lea     edi,[Do_BSET_B_Dx_mem]
        mov     edx,01c0h
        call    Add_Bits_Dx
        lea     ebx,[Valid_Modes_BTST_To_mem]
        lea     edi,[Do_BSET_B_Nb_mem]
        mov     edx,08c0h
        call    Add_Bits_Nb
;---------------------------------------------------------------------- bclr
        lea     ebx,[Valid_Modes_BTST_To_Dx]
        lea     edi,[Do_BCLR_L_Dx_Dx]
        mov     edx,0180h
        call    Add_Bits_Dx
        lea     ebx,[Valid_Modes_BTST_To_Dx]
        lea     edi,[Do_BCLR_L_Nb_Dx]
        mov     edx,0880h
        call    Add_Bits_Nb
        lea     ebx,[Valid_Modes_BTST_To_mem]
        lea     edi,[Do_BCLR_B_Dx_mem]
        mov     edx,0180h
        call    Add_Bits_Dx
        lea     ebx,[Valid_Modes_BTST_To_mem]
        lea     edi,[Do_BCLR_B_Nb_mem]
        mov     edx,0880h
        call    Add_Bits_Nb
;---------------------------------------------------------------------- bchg
        lea     ebx,[Valid_Modes_BTST_To_Dx]
        lea     edi,[Do_BCHG_L_Dx_Dx]
        mov     edx,0140h
        call    Add_Bits_Dx
        lea     ebx,[Valid_Modes_BTST_To_Dx]
        lea     edi,[Do_BCHG_L_Nb_Dx]
        mov     edx,0840h
        call    Add_Bits_Nb
        lea     ebx,[Valid_Modes_BTST_To_mem]
        lea     edi,[Do_BCHG_B_Dx_mem]
        mov     edx,0140h
        call    Add_Bits_Dx
        lea     ebx,[Valid_Modes_BTST_To_mem]
        lea     edi,[Do_BCHG_B_Nb_mem]
        mov     edx,0840h
        call    Add_Bits_Nb
        ret
        ENDP

Add_Bits_Dx:
        mov     ecx,[ebx]
        add     ebx,4
@@allmodes:
        mov     eax,edx
        or      ax,[ebx]
        add     ebx,2
        mov     esi,8
@@all8:
        mov     [Opcodes_Jump+eax*4],edi
        add     eax,0200h
        dec     esi
        jnz     @@all8

        dec     ecx
        jnz     @@allmodes
        ret

Add_Bits_Nb:
        mov     ecx,[ebx]
        add     ebx,4
@@allmodes:
        mov     eax,edx
        or      ax,[ebx]
        add     ebx,2
        mov     [Opcodes_Jump+eax*4],edi
        dec     ecx
        jnz     @@allmodes
        ret

; [fold]  ]

; [fold]  [
PROC Init_Instructions_AND_EOR_OR NEAR
        lea     edx,[Valid_Modes_AND_mem_To_Dx]
        mov     esi,0C000h                      ; Mask for .B AND to Dx
        lea     edi,[Do_AND_B_Mem_To_Dx]
        call    Add_AND
        mov     esi,0C040h                      ; Mask for .W AND to Dx
        lea     edi,[Do_AND_W_Mem_To_Dx]
        call    Add_AND
        mov     esi,0C080h                      ; Mask for .L AND to Dx
        lea     edi,[Do_AND_L_Mem_To_Dx]
        call    Add_AND
        lea     edx,[Valid_Modes_AND_Dx_To_Dx]
        mov     esi,0C000h                      ; Mask for .B AND Dy,Dx
        lea     edi,[Do_AND_B_Dx_To_Dx]
        call    Add_AND
        mov     esi,0C040h                      ; Mask for .W AND Dy,Dx
        lea     edi,[Do_AND_W_Dx_To_Dx]
        call    Add_AND
        mov     esi,0C080h                      ; Mask for .L AND Dy,Dx
        lea     edi,[Do_AND_L_Dx_To_Dx]
        call    Add_AND
        lea     edx,[Valid_Modes_AND_Dx_To_mem]
        mov     esi,0C100h                      ; Mask for .B AND to EA
        lea     edi,[Do_AND_B_Dx_To_Mem]
        call    Add_AND
        mov     esi,0C140h                      ; Mask for .W AND to EA
        lea     edi,[Do_AND_W_Dx_To_Mem]
        call    Add_AND
        mov     esi,0C180h                      ; Mask for .L AND to EA
        lea     edi,[Do_AND_L_Dx_To_Mem]
        call    Add_AND
;------------------------------------------------------------------------- OR
        lea     edx,[Valid_Modes_AND_mem_To_Dx]
        mov     esi,08000h
        lea     edi,[Do_OR_B_Mem_To_Dx]
        call    Add_AND
        mov     esi,08040h
        lea     edi,[Do_OR_W_Mem_To_Dx]
        call    Add_AND
        mov     esi,08080h
        lea     edi,[Do_OR_L_Mem_To_Dx]
        call    Add_AND
        lea     edx,[Valid_Modes_AND_Dx_To_Dx]
        mov     esi,08000h
        lea     edi,[Do_OR_B_Dx_To_Dx]
        call    Add_AND
        mov     esi,08040h
        lea     edi,[Do_OR_W_Dx_To_Dx]
        call    Add_AND
        mov     esi,08080h
        lea     edi,[Do_OR_L_Dx_To_Dx]
        call    Add_AND
        lea     edx,[Valid_Modes_AND_Dx_To_mem]
        mov     esi,08100h
        lea     edi,[Do_OR_B_Dx_To_Mem]
        call    Add_AND
        mov     esi,08140h
        lea     edi,[Do_OR_W_Dx_To_Mem]
        call    Add_AND
        mov     esi,08180h
        lea     edi,[Do_OR_L_Dx_To_Mem]
        call    Add_AND
;------------------------------------------------------------------------- EOR
        ;lea     edx,[Valid_Modes_AND_mem_To_Dx
        ;mov     esi,0B000h
        ;lea     edi,[Do_EOR_B_Mem_To_Dx
        ;call    Add_AND
        ;mov     esi,0B040h
        ;lea     edi,[Do_EOR_W_Mem_To_Dx
        ;call    Add_AND
        ;mov     esi,0B080h
        ;lea     edi,[Do_EOR_L_Mem_To_Dx
        ;call    Add_AND

        lea     edx,[Valid_Modes_AND_Dx_To_Dx]
        mov     esi,0B100h
        lea     edi,[Do_EOR_B_Dx_To_Dx]
        call    Add_AND
        mov     esi,0B140h
        lea     edi,[Do_EOR_W_Dx_To_Dx]
        call    Add_AND
        mov     esi,0B180h
        lea     edi,[Do_EOR_L_Dx_To_Dx]
        call    Add_AND
        lea     edx,[Valid_Modes_AND_Dx_To_mem]
        mov     esi,0B100h
        lea     edi,[Do_EOR_B_Dx_To_Mem]
        call    Add_AND
        mov     esi,0B140h
        lea     edi,[Do_EOR_W_Dx_To_Mem]
        call    Add_AND
        mov     esi,0B180h
        lea     edi,[Do_EOR_L_Dx_To_Mem]
        call    Add_AND
        ret
        ENDP

PROC Add_AND NEAR
                                        ;ESI original mask 0F1C0h
                                        ;EDI function

        mov     ebx,00000h              ;Registre 00000h -> 00e00h
@@AllReg:
        push    edx
        mov     ecx,[edx]               ;valid modes
        add     edx,4
@@AllModes:
        mov     eax,esi
        or      eax,ebx
        or      ax,[edx]
        mov     [Opcodes_Jump+eax*4],edi
        add     edx,2
        dec     ecx
        jnz     @@AllModes
        pop     edx

        add     ebx,00200h
        cmp     ebx,00e00h
        jbe     @@AllReg
        ret
        ENDP


; [fold]  ]

; [fold]  [
PROC Init_Instructions_ANDI_EORI_ORI NEAR

        lea     edx,[Valid_Modes_ANDI_To_EA]
        mov     esi,00200h                      ;Mask ADDI.B
        lea     edi,[Do_ANDI_B_To_Mem]
        call    Add_ANDI
        mov     esi,00240h                      ;Mask ADDI.W
        lea     edi,[Do_ANDI_W_To_Mem]
        call    Add_ANDI
        mov     esi,00280h                      ;Mask ADDI.L
        lea     edi,[Do_ANDI_L_To_Mem]
        call    Add_ANDI

        lea     edx,[Valid_Modes_ANDI_To_Dx]
        mov     esi,00200h                      ;Mask ADDI.B ,Dx
        lea     edi,[Do_ANDI_B_To_Dx]
        call    Add_ANDI
        mov     esi,00240h                      ;Mask ADDI.W ,Dx
        lea     edi,[Do_ANDI_W_To_Dx]
        call    Add_ANDI
        mov     esi,00280h                      ;Mask ADDI.L ,Dx
        lea     edi,[Do_ANDI_L_To_Dx]
        call    Add_ANDI
;-------------------------------------------------------------------- ori
        lea     edx,[Valid_Modes_ANDI_To_EA]
        mov     esi,00000h
        lea     edi,[Do_ORI_B_To_Mem]
        call    Add_ANDI
        mov     esi,00040h
        lea     edi,[Do_ORI_W_To_Mem]
        call    Add_ANDI
        mov     esi,00080h
        lea     edi,[Do_ORI_L_To_Mem]
        call    Add_ANDI

        lea     edx,[Valid_Modes_ANDI_To_Dx]
        mov     esi,00000h
        lea     edi,[Do_ORI_B_To_Dx]
        call    Add_ANDI
        mov     esi,00040h
        lea     edi,[Do_ORI_W_To_Dx]
        call    Add_ANDI
        mov     esi,00080h
        lea     edi,[Do_ORI_L_To_Dx]
        call    Add_ANDI
;--------------------------------------------------------------------- eori
        lea     edx,[Valid_Modes_ANDI_To_EA]
        mov     esi,00a00h
        lea     edi,[Do_EORI_B_To_Mem]
        call    Add_ANDI
        mov     esi,00a40h
        lea     edi,[Do_EORI_W_To_Mem]
        call    Add_ANDI
        mov     esi,00a80h
        lea     edi,[Do_EORI_L_To_Mem]
        call    Add_ANDI

        lea     edx,[Valid_Modes_ANDI_To_Dx]
        mov     esi,00a00h
        lea     edi,[Do_EORI_B_To_Dx]
        call    Add_ANDI
        mov     esi,00a40h
        lea     edi,[Do_EORI_W_To_Dx]
        call    Add_ANDI
        mov     esi,00a80h
        lea     edi,[Do_EORI_L_To_Dx]
        call    Add_ANDI
        ret
        ENDP

PROC Add_ANDI NEAR
                                        ;ESI original
                                        ;EDI function
        push    edx
        mov     ecx,[edx]               ;number of valid modes
        add     edx,4
@@AllModes:
        mov     eax,esi
        or      ax,[edx]
        mov     [Opcodes_Jump+eax*4],edi
        add     edx,2
        dec     ecx
        jnz     @@AllModes
        pop     edx

        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_NOT NEAR
        lea     edx,[Valid_Modes_AND_Dx_To_Dx]
        mov     esi,04600h
        lea     edi,[Do_NOT_B_Dx]
        call    Add_NOT
        mov     esi,04640h
        lea     edi,[Do_NOT_W_Dx]
        call    Add_NOT
        mov     esi,04680h
        lea     edi,[Do_NOT_L_Dx]
        call    Add_NOT

        lea     edx,[Valid_Modes_AND_Dx_To_mem]
        mov     esi,04600h
        lea     edi,[Do_NOT_B_Mem]
        call    Add_NOT
        mov     esi,04640h
        lea     edi,[Do_NOT_W_Mem]
        call    Add_NOT
        mov     esi,04680h
        lea     edi,[Do_NOT_L_Mem]
        call    Add_NOT
        ret
        ENDP

PROC Add_NOT NEAR
        push    edx
        mov     ecx,[edx]               ;valid modes
        add     edx,4
@@AllModes:
        mov     eax,esi
        or      ax,[edx]
        mov     [Opcodes_Jump+eax*4],edi
        add     edx,2
        dec     ecx
        jnz     @@AllModes
        pop     edx
        ret
        ENDP



; [fold]  ]

; [fold]  [
PROC Init_Instructions_CCR_SR NEAR
        mov     [Opcodes_Jump+4*023ch],OFFSET Do_ANDI_CCR
        mov     [Opcodes_Jump+4*027ch],OFFSET Do_ANDI_SR
        mov     [Opcodes_Jump+4*0a3ch],OFFSET Do_EORI_CCR
        mov     [Opcodes_Jump+4*0a7ch],OFFSET Do_EORI_SR
        mov     [Opcodes_Jump+4*003ch],OFFSET Do_ORI_CCR
        mov     [Opcodes_Jump+4*007ch],OFFSET Do_ORI_SR
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instructions_Shifts NEAR
        lea     ebx,[Table_Functions_LSL]
        call    Add_Shift
        lea     ebx,[Table_Functions_LSR]
        call    Add_Shift

        lea     ebx,[Table_Functions_ASL]
        call    Add_Shift
        lea     ebx,[Table_Functions_ASR]
        call    Add_Shift

        lea     ebx,[Table_Functions_ROL]
        call    Add_Shift
        lea     ebx,[Table_Functions_ROR]
        call    Add_Shift

        lea     ebx,[Table_Functions_ROXL]
        call    Add_Shift
        lea     ebx,[Table_Functions_ROXR]
        call    Add_Shift
        ret
        ENDP

PROC Add_Shift NEAR
                                ; add functions in table EBX

        mov     ecx,6           ; 6 functions SHIFT Dx
@@All6Func:
        push    ecx
        mov     edx,[ebx]       ; mask
        mov     edi,[ebx+4]     ; function

        mov     esi,8
@@AllReg1:
        mov     eax,edx
        mov     ecx,8
@@AllReg2:
        mov     [Opcodes_Jump+eax*4],edi
        inc     eax
        dec     ecx
        jnz     @@AllReg2

        add     edx,0200h
        dec     esi
        jnz     @@AllReg1

        add     ebx,8           ; next function type
        pop     ecx
        dec     ecx
        jnz     @@All6Func

        mov     eax,[ebx]       ; mask for mem shift
        mov     edi,[ebx+4]     ; fucntion for mem shift
        mov     ecx,42          ; 42 valid modes
        or      eax,10h         ; first valid mode = 010h (An)
@@AllModes:
        mov     [Opcodes_Jump+eax*4],edi
        inc     eax
        dec     ecx
        jnz     @@AllModes
        ret
        ENDP

; [fold]  ]


        DATASEG

LABEL Valid_Modes_BTST_To_Dx
        dd      8
        dw      000h,001h,002h,003h,004h,005h,006h,007h
LABEL Valid_Modes_BTST_To_mem
        dd      42+3
        dw      010h,011h,012h,013h,014h,015h,016h,017h
        dw      018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
        dw      020h,021h,022h,023h,024h,025h,026h,027h
        dw      028h,029h,02ah,02bh,02ch,02dh,02eh,02fh
        dw      030h,031h,032h,033h,034h,035h,036h,037h
        dw      038h,039h,03ah,03bh,03ch                ;BTST to mem exists

LABEL Valid_Modes_ANDI_To_EA
        dd      42
        dw      010h,011h,012h,013h,014h,015h,016h,017h
        dw      018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
        dw      020h,021h,022h,023h,024h,025h,026h,027h
        dw      028h,029h,02ah,02bh,02ch,02dh,02eh,02fh
        dw      030h,031h,032h,033h,034h,035h,036h,037h
        dw      038h,039h

LABEL Valid_Modes_ANDI_To_Dx
        dd      8
        dw      000h,001h,002h,003h,004h,005h,006h,007h

LABEL Valid_Modes_AND_Dx_To_Dx
        dd      8
        dw      000h,001h,002h,003h,004h,005h,006h,007h

LABEL Valid_Modes_AND_mem_To_Dx
        dd      45
        dw      010h,011h,012h,013h,014h,015h,016h,017h
        dw      018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
        dw      020h,021h,022h,023h,024h,025h,026h,027h
        dw      028h,029h,02ah,02bh,02ch,02dh,02eh,02fh
        dw      030h,031h,032h,033h,034h,035h,036h,037h
        dw      038h,039h,03ah,03bh,03ch

LABEL Valid_Modes_AND_Dx_To_mem
        dd      42
        dw      010h,011h,012h,013h,014h,015h,016h,017h
        dw      018h,019h,01ah,01bh,01ch,01dh,01eh,01fh
        dw      020h,021h,022h,023h,024h,025h,026h,027h
        dw      028h,029h,02ah,02bh,02ch,02dh,02eh,02fh
        dw      030h,031h,032h,033h,034h,035h,036h,037h
        dw      038h,039h

LABEL Table_Functions_LSL
        dd      0e128h, Do_LSL_B_Dx_Dx
        dd      0e168h, Do_LSL_W_Dx_Dx
        dd      0e1a8h, Do_LSL_L_Dx_Dx
        dd      0e108h, Do_LSL_B_Nb_Dx
        dd      0e148h, Do_LSL_W_Nb_Dx
        dd      0e188h, Do_LSL_L_Nb_Dx
        dd      0e3c0h, Do_LSL_W_mem

LABEL Table_Functions_LSR
        dd      0e028h, Do_LSR_B_Dx_Dx
        dd      0e068h, Do_LSR_W_Dx_Dx
        dd      0e0a8h, Do_LSR_L_Dx_Dx
        dd      0e008h, Do_LSR_B_Nb_Dx
        dd      0e048h, Do_LSR_W_Nb_Dx
        dd      0e088h, Do_LSR_L_Nb_Dx
        dd      0e2c0h, Do_LSR_W_mem

LABEL Table_Functions_ASL
        dd      0e120h, Do_ASL_B_Dx_Dx
        dd      0e160h, Do_ASL_W_Dx_Dx
        dd      0e1a0h, Do_ASL_L_Dx_Dx
        dd      0e100h, Do_ASL_B_Nb_Dx
        dd      0e140h, Do_ASL_W_Nb_Dx
        dd      0e180h, Do_ASL_L_Nb_Dx
        dd      0e1c0h, Do_ASL_W_mem

LABEL Table_Functions_ASR
        dd      0e020h, Do_ASR_B_Dx_Dx
        dd      0e060h, Do_ASR_W_Dx_Dx
        dd      0e0a0h, Do_ASR_L_Dx_Dx
        dd      0e000h, Do_ASR_B_Nb_Dx
        dd      0e040h, Do_ASR_W_Nb_Dx
        dd      0e080h, Do_ASR_L_Nb_Dx
        dd      0e0c0h, Do_ASR_W_mem

LABEL Table_Functions_ROL
        dd      0e138h, Do_ROL_B_Dx_Dx
        dd      0e178h, Do_ROL_W_Dx_Dx
        dd      0e1b8h, Do_ROL_L_Dx_Dx
        dd      0e118h, Do_ROL_B_Nb_Dx
        dd      0e158h, Do_ROL_W_Nb_Dx
        dd      0e198h, Do_ROL_L_Nb_Dx
        dd      0e7c0h, Do_ROL_W_mem

LABEL Table_Functions_ROR
        dd      0e038h, Do_ROR_B_Dx_Dx
        dd      0e078h, Do_ROR_W_Dx_Dx
        dd      0e0b8h, Do_ROR_L_Dx_Dx
        dd      0e018h, Do_ROR_B_Nb_Dx
        dd      0e058h, Do_ROR_W_Nb_Dx
        dd      0e098h, Do_ROR_L_Nb_Dx
        dd      0e6c0h, Do_ROR_W_mem

LABEL Table_Functions_ROXL
        dd      0e130h, Do_ROXL_B_Dx_Dx
        dd      0e170h, Do_ROXL_W_Dx_Dx
        dd      0e1b0h, Do_ROXL_L_Dx_Dx
        dd      0e110h, Do_ROXL_B_Nb_Dx
        dd      0e150h, Do_ROXL_W_Nb_Dx
        dd      0e190h, Do_ROXL_L_Nb_Dx
        dd      0e5c0h, Do_ROXL_W_mem

LABEL Table_Functions_ROXR
        dd      0e030h, Do_ROXR_B_Dx_Dx
        dd      0e070h, Do_ROXR_W_Dx_Dx
        dd      0e0b0h, Do_ROXR_L_Dx_Dx
        dd      0e010h, Do_ROXR_B_Nb_Dx
        dd      0e050h, Do_ROXR_W_Nb_Dx
        dd      0e090h, Do_ROXR_L_Nb_Dx
        dd      0e4c0h, Do_ROXR_W_mem

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                                    MOVES
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

        CODESEG

        EXTRN Do_MOVE_To_CCR, Do_MOVE_From_SR, Do_MOVE_To_SR : NEAR
        EXTRN Do_MOVEP_W_To_Mem, Do_MOVEP_L_To_Mem : NEAR
        EXTRN Do_MOVEP_W_From_Mem, Do_MOVEP_L_From_Mem : NEAR
        EXTRN Do_UNLK, Do_LINK : NEAR
        EXTRN Do_MOVE_From_USP, Do_MOVE_To_USP : NEAR
        EXTRN Do_EXG_Dx_Dx, Do_EXG_Ax_Ax, Do_EXG_Dx_Ax : NEAR
        EXTRN Do_CLR_B_Mem, Do_CLR_W_Mem, Do_CLR_L_Mem : NEAR
        EXTRN Do_CLR_B_Dx, Do_CLR_W_Dx, Do_CLR_L_Dx : NEAR
        EXTRN Do_Swap, Do_LEA, Do_PEA, Do_MOVEQ : NEAR
        EXTRN Do_General_MOVE_B, Do_General_MOVE_W, Do_General_MOVE_L : NEAR
        EXTRN Do_Move_B_Dx_Dx, Do_Move_W_Rx_Dx, Do_Move_L_Rx_Dx : NEAR
        EXTRN Do_Move_B_Dx_Mem : NEAR
        EXTRN Do_Move_W_Rx_Mem, Do_Move_L_Rx_Mem, Do_Move_B_Mem_Dx : NEAR
        EXTRN Do_Move_W_Mem_Dx, Do_Move_L_Mem_Dx, Do_Move_B_Mem_Mem : NEAR
        EXTRN Do_Move_W_Mem_Mem, Do_Move_L_Mem_Mem : NEAR
        EXTRN Do_ST, Do_SF, Do_SHI, Do_SLS, Do_SCC, Do_SCS : NEAR
        EXTRN Do_SNE, Do_SEQ, Do_SVC, Do_SVS, Do_SPL, Do_SMI : NEAR
        EXTRN Do_SGE, Do_SLT, Do_SGT, Do_SLE : NEAR
        EXTRN Do_MOVEA_W_Rx : NEAR
        EXTRN Do_MOVEA_L_Rx, Do_MOVEA_W_mem, Do_MOVEA_L_mem : NEAR

PROC Init_Instructions_MOVES NEAR
        call    Init_Instruction_MOVE
        call    Init_Instruction_MOVEA
        call    Init_MOVE_Specific
        call    Init_Instruction_MOVEQ
        call    Init_Instruction_LEA_PEA
        call    Init_Instruction_SWAP
        call    Init_Instruction_CLR
        call    Init_Instruction_EXG
        call    Init_Instructions_Scc
        call    Init_Instruction_MOVE_USP
        call    Init_Instructions_LINK_UNLK
        call    Init_Instruction_MOVEP
        call    Init_Instructions_MOVE_ccr_sr
        ret
        ENDP

; [fold]  [
PROC Init_Instructions_MOVE_ccr_sr NEAR
        lea     ebx,[Valid_Modes_Move_to_CCR]
        lea     edi,[Do_MOVE_To_CCR]
        mov     edx,044c0h
        call    Add_MOVE_ccr
        lea     ebx,[Valid_Modes_Move_from_SR]
        lea     edi,[Do_MOVE_From_SR]
        mov     edx,040c0h
        call    Add_MOVE_ccr
        lea     ebx,[Valid_Modes_Move_to_CCR]
        lea     edi,[Do_MOVE_To_SR]
        mov     edx,046c0h
        call    Add_MOVE_ccr
        ret
        ENDP

Add_MOVE_ccr:
        mov     ecx,[ebx]
        add     ebx,4
@@allmodes:
        mov     eax,edx
        or      ax,[ebx]
        mov     [Opcodes_Jump+eax*4],edi
        add     ebx,2
        dec     ecx
        jnz     @@allmodes
        ret

; [fold]  ]

; [fold]  [
PROC Init_Instruction_MOVEP NEAR
        lea     edi,[Do_MOVEP_W_To_Mem]
        mov     edx,00188h
        call    Add_Movep
        lea     edi,[Do_MOVEP_L_To_Mem]
        mov     edx,001c8h
        call    Add_Movep
        lea     edi,[Do_MOVEP_W_From_Mem]
        mov     edx,00108h
        call    Add_Movep
        lea     edi,[Do_MOVEP_L_From_Mem]
        mov     edx,00148h
        call    Add_Movep
        ret
        ENDP

Add_Movep:
        mov     ecx,8
@@DoReg1:
        mov     eax,edx
        mov     esi,8
@@DoReg2:
        mov     [Opcodes_Jump+eax*4],edi
        inc     eax
        dec     esi
        jnz     @@DoReg2
        add     edx,0200h
        dec     ecx
        jnz     @@DoReg1
        ret

; [fold]  ]

; [fold]  [
PROC Init_Instructions_LINK_UNLK NEAR

        lea     edi,[Do_UNLK]
        mov     eax,04e58h
        call    Add_Link
        lea     edi,[Do_LINK]
        mov     eax,04e50h
        call    Add_Link
        ret
        ENDP

PROC Add_Link NEAR
        mov     ecx,8
@@nxt:  mov     [Opcodes_Jump+eax*4],edi
        inc     eax
        dec     ecx
        jnz     @@nxt
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_MOVE_USP  NEAR
        lea     edi,[Do_MOVE_From_USP]
        mov     eax,04e68h
        call    Add_USP
        lea     edi,[Do_MOVE_To_USP]
        mov     eax,04e60h
        call    Add_USP
        ret
        ENDP

PROC Add_Usp NEAR
        mov     ecx,8
@@nxt:  mov     [Opcodes_Jump+eax*4],edi
        inc     eax
        dec     ecx
        jnz     @@nxt
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instructions_Scc NEAR

        lea     ebx,[Table_Functions_Scc]
@@Next:
        mov     edx,[ebx]                       ; Mask instruction
        mov     edi,[ebx+4]                     ; Scc Function
        mov     ecx,8
@@AllRegs:
        lea     esi,[Table_Modes_Scc]
@@allmodes:
        mov     eax,edx
        or      ax,[esi]
        mov     [Opcodes_Jump+eax*4],edi
        add     esi,2
        cmp     esi,OFFSET END_Table_Modes_Scc
        jnz     @@allmodes


        add     ebx,8
        cmp     ebx,OFFSET END_Table_Functions_Scc
        jnz     @@Next
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_EXG NEAR
        lea     edi,[Do_EXG_Dx_Dx]
        mov     edx,0c140h
        call    Add_EXG
        lea     edi,[Do_EXG_Ax_Ax]
        mov     edx,0c148h
        call    Add_EXG
        lea     edi,[Do_EXG_Dx_Ax]
        mov     edx,0c188h
        call    Add_EXG
        ret
        ENDP

PROC Add_EXG NEAR
        mov     ecx,8
@@allRx:
        mov     eax,edx
        mov     esi,8
@@allRy:
        mov     [Opcodes_Jump+eax*4],edi
        inc     eax
        dec     esi
        jnz     @@allRy

        add     edx,0200h
        dec     ecx
        jnz     @@allRx
        ret
        ENDP

; [fold]  ]


; [fold]  [
PROC Init_Instruction_CLR NEAR
        lea     ebx,[Valid_Modes_CLR_Mem]
        lea     edi,[Do_CLR_B_Mem]
        mov     edx,4200h
        call    Add_CLR
        lea     edi,[Do_CLR_W_Mem]
        mov     edx,4240h
        call    Add_CLR
        lea     edi,[Do_CLR_L_Mem]
        mov     edx,4280h
        call    Add_CLR

        lea     ebx,[Valid_Modes_CLR_Dx]
        lea     edi,[Do_CLR_B_Dx]
        mov     edx,4200h
        call    Add_CLR
        lea     edi,[Do_CLR_W_Dx]
        mov     edx,4240h
        call    Add_CLR
        lea     edi,[Do_CLR_L_Dx]
        mov     edx,4280h
        call    Add_CLR
        ret
        ENDP

PROC Add_CLR NEAR
        push    ebx
        mov     ecx,[ebx]
        add     ebx,4
@@allmodes:
        mov     eax,edx
        or      ax,[ebx]
        mov     [Opcodes_Jump+eax*4],edi
        add     ebx,2
        dec     ecx
        jnz     @@allmodes
        pop     ebx
        ret
        ENDP

; [fold]  ]


; [fold]  [
PROC Init_Instruction_SWAP NEAR

        lea     edi,[Do_Swap]
        mov     eax,4840h
@@allregs:
        mov     [Opcodes_Jump+eax*4],edi
        inc     eax
        cmp     eax,4848h
        jnz     @@allregs
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_LEA_PEA NEAR

        lea     edi,[Do_LEA]
        lea     esi,[Do_PEA]
        lea     ebx,[Valid_Modes_LEA]
@@allvalid:
        mov     eax,041c0h                      ;general mask LEA
        mov     edx,04840h
        or      ax,[ebx]
        or      dx,[ebx]

        mov     [Opcodes_Jump+edx*4],esi        ;set PEA

        mov     ecx,8                           ;8 adress registers
@@allregs:
        mov     [Opcodes_Jump+eax*4],edi        ;set LEAs
        add     eax,0200h                       ;next registers
        dec     ecx
        jnz     @@allregs

        add     ebx,2
        cmp     ebx,OFFSET End_Valid_Modes_LEA
        jnz     @@allvalid
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_MOVEA NEAR

        lea     ebx,[List_Modes_MOVEA]
@@alltypes:
        mov     edi,[ebx]               ;function
        mov     ecx,[ebx+4]             ;number of mode
        mov     edx,[ebx+8]             ;first mask (with mode)
@@allmodes:
        mov     eax,edx                 ;all 8 registers with this mode
        mov     esi,8                   ;A0..A7
@@allregs:
        mov     [Opcodes_Jump+eax*4],edi
        add     eax,200h
        dec     esi
        jnz     @@allregs

        inc     edx                     ;next mode
        dec     ecx                     ;...for all of them
        jnz     @@allmodes

        add     ebx,12
        cmp     ebx,OFFSET List_Modes_MOVEA_END
        jnz     @@alltypes
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instruction_MOVEQ NEAR

        lea     edi,[Do_MOVEQ]          ;0111 |reg 0|data

        mov     ebx,07000h              ;initial mask (register D0)
@@AllRegs:
        mov     eax,ebx                 ;256 offsets for each regs.
@@AllOff:
        mov     [Opcodes_Jump+Eax*4],edi
        inc     al
        jnz     @@AllOff

        add     ebx,00200h              ;next register
        cmp     ebx,08000h              ;8 registers to process
        jnz     @@AllRegs
        ret
        ENDP

; [fold]  ]


; [fold]  [
PROC Init_Instruction_MOVE NEAR
        mov     esi,01000h      ; Mask for .B MOVE
        lea     edi,[Do_General_MOVE_B] ;
        call    Add_Move
        mov     esi,03000h      ; Mask for .W MOVE
        lea     edi,[Do_General_MOVE_W] ;
        call    Add_Move
        mov     esi,02000h      ; Mask for .L MOVE
        lea     edi,[Do_General_MOVE_L] ;
        call    Add_Move
        ret
        ENDP

PROC Add_Move NEAR
                        ;ESI: initial Mask
                        ;EDI: function
        lea     ebx,[Valid_Destination_MOVE]
@@AllDest:
        xor     eax,eax
        mov     ax, [ebx]      ;EAX = Valid Destination Mask

        mov     edx,eax
        shr     edx,3
        and     eax,7
        shl     eax,3
        or      eax,edx         ;swap Register / Mode

        shl     eax,6
        or      eax,esi         ;EAX = Valid Size & Destination
        mov     ecx,61          ;61 valid Source modes
@@AllSrc:
        mov     [Opcodes_Jump+eax*4],edi

        inc     eax             ;next valid sourcemode
        dec     ecx
        jnz     @@AllSrc

        add     ebx,2
        cmp     ebx,OFFSET End_Valid_Destination_MOVE
        jnz     @@AllDest
        ret
        ENDP

; [fold]  ]

PROC Init_MOVE_Specific NEAR
        mov     esi,01000h
        lea     edi,[Do_Move_B_Dx_Dx]
        call    Add_Move_Dx_Dx
        mov     esi,03000h
        lea     edi,[Do_Move_W_Rx_Dx]
        call    Add_Move_Dx_Dx
        mov     esi,02000h
        lea     edi,[Do_Move_L_Rx_Dx]
        call    Add_Move_Dx_Dx
        mov     esi,03008h
        lea     edi,[Do_Move_W_Rx_Dx]
        call    Add_Move_Dx_Dx
        mov     esi,02008h
        lea     edi,[Do_Move_L_Rx_Dx]
        call    Add_Move_Dx_Dx

        mov     esi,1000h
        lea     edi,[Do_Move_B_Dx_Mem]
        call    Add_Move_Dx_Mem
        mov     esi,3000h
        lea     edi,[Do_Move_W_Rx_Mem]
        call    Add_Move_Dx_Mem
        mov     esi,2000h
        lea     edi,[Do_Move_L_Rx_Mem]
        call    Add_Move_Dx_Mem

;------------------------------------------ PAS Ax,mem
;        mov     esi,3008h
;        lea     edi,[Do_Move_W_Rx_Mem]
;        call    Add_Move_Dx_Mem
;        mov     esi,2008h
;        lea     edi,[Do_Move_L_Rx_Mem]
;        call    Add_Move_Dx_Mem

        mov     esi,1000h
        lea     edi,[Do_Move_B_Mem_Dx]
        call    Add_Move_Mem_Dx
        mov     esi,3000h
        lea     edi,[Do_Move_W_Mem_Dx]
        call    Add_Move_Mem_Dx
        mov     esi,2000h
        lea     edi,[Do_Move_L_Mem_Dx]
        call    Add_Move_Mem_Dx

        mov     esi,1000h
        lea     edi,[Do_Move_B_Mem_Mem]
        call    Add_Move_Mem_Mem
        mov     esi,3000h
        lea     edi,[Do_Move_W_Mem_Mem]
        call    Add_Move_Mem_Mem
        mov     esi,2000h
        lea     edi,[Do_Move_L_Mem_Mem]
        call    Add_Move_Mem_Mem
        ret

Add_Move_Dx_Dx:
        mov     ecx,8           ;source reg
@@src2:
        mov     eax,esi
        add     esi,0200h
        mov     ebx,8           ;destination reg
@@dst2:
        mov     [Opcodes_Jump+eax*4],edi
        inc     eax
        dec     ebx
        jnz     @@dst2
        dec     ecx
        jnz     @@src2
        ret

Add_Move_Dx_Mem:
        mov     ecx,8           ;Dx reg (source)
@@src:
        lea     edx,[Valid_Move_Destination_Mem]
        mov     ebx,[edx]
        add     edx,4
@@dst:
        mov     eax,esi
        or      ax,[edx]
        add     edx,2
        mov     [Opcodes_Jump+eax*4],edi
        dec     ebx
        jnz     @@dst
        inc     esi
        dec     ecx
        jnz     @@src
        ret

Add_Move_Mem_Dx:
        mov     ecx,8           ;Dx reg (destination)
@@src3:
        lea     edx,[Valid_Move_Source_Mem]
        mov     ebx,[edx]
        add     edx,4
@@dst3:
        mov     eax,esi
        or      ax,[edx]
        add     edx,2
        mov     [Opcodes_Jump+eax*4],edi
        dec     ebx
        jnz     @@dst3
        add     esi,200h
        dec     ecx
        jnz     @@src3
        ret

Add_Move_Mem_Mem:
        push    ebp
        lea     ebp,[Valid_Move_Destination_Mem]
        mov     ecx,[ebp]
        add     ebp,4
@@src4:
        push    esi
        or      si,[ebp]
        add     ebp,2

        lea     edx,[Valid_Move_Source_Mem]
        mov     ebx,[edx]
        add     edx,4
@@dst4:
        mov     eax,esi
        or      ax,[edx]
        add     edx,2
        mov     [Opcodes_Jump+eax*4],edi
        dec     ebx
        jnz     @@dst4

        pop     esi
        dec     ecx
        jnz     @@src4
        pop     ebp
        ret
        ENDP



LABEL Valid_Modes_Move_to_CCR
        dd      (6*8)+5
        dw      00h,01h,02h,03h,04h,05h,06h,07h
        dw      10h,11h,12h,13h,14h,15h,16h,17h
        dw      18h,19h,1ah,1bh,1ch,1dh,1eh,1fh
        dw      20h,21h,22h,23h,24h,25h,26h,27h
        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh
        dw      30h,31h,32h,33h,34h,35h,36h,37h
        dw      38h,39h,3ah,3bh,3ch

LABEL Valid_Modes_Move_from_SR
        dd      (6*8)+2
        dw      00h,01h,02h,03h,04h,05h,06h,07h
        dw      10h,11h,12h,13h,14h,15h,16h,17h
        dw      18h,19h,1ah,1bh,1ch,1dh,1eh,1fh
        dw      20h,21h,22h,23h,24h,25h,26h,27h
        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh
        dw      30h,31h,32h,33h,34h,35h,36h,37h
        dw      38h,39h


LABEL Table_Functions_Scc
        dd      050c0h,Do_ST
        dd      051c0h,Do_SF
        dd      052c0h,Do_SHI
        dd      053c0h,Do_SLS
        dd      054c0h,Do_SCC
        dd      055c0h,Do_SCS
        dd      056c0h,Do_SNE
        dd      057c0h,Do_SEQ
        dd      058c0h,Do_SVC
        dd      059c0h,Do_SVS
        dd      05ac0h,Do_SPL
        dd      05bc0h,Do_SMI
        dd      05cc0h,Do_SGE
        dd      05dc0h,Do_SLT
        dd      05ec0h,Do_SGT
        dd      05fc0h,Do_SLE
LABEL END_Table_Functions_Scc

LABEL Table_Modes_Scc
        dw      00h,01h,02h,03h,04h,05h,06h,07h ;Dn
        dw      10h,11h,12h,13h,14h,15h,16h,17h ;(An)
        dw      18h,19h,1ah,1bh,1ch,1dh,1eh,1fh ;(An)+
        dw      20h,21h,22h,23h,24h,25h,26h,27h ;-(An)
        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh ;d(An)
        dw      30h,31h,32h,33h,34h,35h,36h,37h ;d(An,xi)
        dw      38h,39h                         ;Abs
LABEL END_Table_Modes_Scc

;LABEL Valid_Modes_CLR
;        dw      00h,01h,02h,03h,04h,05h,06h,07h
;        dw      10h,11h,12h,13h,14h,15h,16h,17h
;        dw      18h,19h,1ah,1bh,1ch,1dh,1eh,1fh
;        dw      20h,21h,22h,23h,24h,25h,26h,27h
;        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh
;        dw      30h,31h,32h,33h,34h,35h,36h,37h
;        dw      38h,39h
;LABEL End_Valid_Modes_CLR


LABEL Valid_Modes_CLR_Mem
;        dw      00h,01h,02h,03h,04h,05h,06h,07h
        dd      42
        dw      10h,11h,12h,13h,14h,15h,16h,17h
        dw      18h,19h,1ah,1bh,1ch,1dh,1eh,1fh
        dw      20h,21h,22h,23h,24h,25h,26h,27h
        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh
        dw      30h,31h,32h,33h,34h,35h,36h,37h
        dw      38h,39h

LABEL Valid_Modes_CLR_Dx
        dd      8
        dw      00h,01h,02h,03h,04h,05h,06h,07h
;        dw      10h,11h,12h,13h,14h,15h,16h,17h
;        dw      18h,19h,1ah,1bh,1ch,1dh,1eh,1fh
;        dw      20h,21h,22h,23h,24h,25h,26h,27h
;        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh
;        dw      30h,31h,32h,33h,34h,35h,36h,37h
;        dw      38h,39h


LABEL Valid_Modes_LEA
        dw      10h,11h,12h,13h,14h,15h,16h,17h
        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh
        dw      30h,31h,32h,33h,34h,35h,36h,37h
        dw      38h,39h,3ah,3bh
LABEL End_Valid_Modes_LEA


LABEL List_Modes_MOVEA
        dd      Do_MOVEA_W_Rx           ;function adress
        dd      8                       ;number of ea mode to init
        dd      03040h                  ;first mask
        dd      Do_MOVEA_L_Rx
        dd      8
        dd      02040h
        dd      Do_MOVEA_W_Rx
        dd      8
        dd      03048h
        dd      Do_MOVEA_L_Rx
        dd      8
        dd      02048h
        dd      Do_MOVEA_W_mem
        dd      45
        dd      03050h
        dd      Do_MOVEA_L_mem
        dd      45
        dd      02050h
LABEL List_Modes_MOVEA_END


LABEL Valid_Destination_MOVE
        dw      00h, 01h, 02h, 03h, 04h, 05h, 06h, 07h ; Destination Dn
        dw      10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h ; Destination (An)
        dw      18h, 19h, 1ah, 1bh, 1ch, 1dh, 1eh, 1fh ; Destination (An)+
        dw      20h, 21h, 22h, 23h, 24h, 25h, 26h, 27h ; Destination -(An)
        dw      28h, 29h, 2ah, 2bh, 2ch, 2dh, 2eh, 2fh ; Destination d(An)
        dw      30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h ; Destination d(An,Xi)
        dw      38h                                    ; Destination Abs.W
        dw      39h                                    ; Destination Abs.L
LABEL End_Valid_Destination_MOVE


LABEL Valid_Move_Destination_Mem
        dd      42
        dw      0080h,0280h,0480h,0680h,0880h,0a80h,0c80h,0e80h;dest (An)
        dw      00c0h,02c0h,04c0h,06c0h,08c0h,0ac0h,0cc0h,0ec0h;dest (An)+
        dw      0100h,0300h,0500h,0700h,0900h,0b00h,0d00h,0f00h;dest -(An)
        dw      0140h,0340h,0540h,0740h,0940h,0b40h,0d40h,0f40h;dest d(An)
        dw      0180h,0380h,0580h,0780h,0980h,0b80h,0d80h,0f80h;dest d(An,Xi)
        dw      01c0h;dest Abs.W
        dw      03c0h;dest Abs.L

LABEL Valid_Move_Source_Mem
        dd      45
        dw      10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h ; Destination (An)
        dw      18h, 19h, 1ah, 1bh, 1ch, 1dh, 1eh, 1fh ; Destination (An)+
        dw      20h, 21h, 22h, 23h, 24h, 25h, 26h, 27h ; Destination -(An)
        dw      28h, 29h, 2ah, 2bh, 2ch, 2dh, 2eh, 2fh ; Destination d(An)
        dw      30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h ; Destination d(An,Xi)
        dw      38h, 39h, 3ah, 3bh, 3ch                ; Destinations


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                                   BRANCH
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

        CODESEG

        EXTRN Do_RTS, DO_RTR, DO_TRAPV, DO_NOP, DO_RESET : NEAR
        EXTRN Do_TRAP, Do_JMP, Do_JSR : NEAR
        EXTRN Do_DBT, Do_DBF, Do_DBHI, Do_DBLS, Do_DBCC, Do_DBCS : NEAR
        EXTRN Do_DBNE, Do_DBEQ, Do_DBVC, Do_DBVS, Do_DBPL : NEAR
        EXTRN Do_DBMI : NEAR
        EXTRN Do_BRA_Long, Do_BRA_Short, Do_BSR_Long, Do_BSR_Short : NEAR
        EXTRN Do_BHI_Long, Do_BHI_Short, Do_BLS_Long, Do_BLS_Short : NEAR
        EXTRN Do_BCC_Long, Do_BCC_Short, Do_BCS_Long, Do_BCS_Short : NEAR
        EXTRN Do_BNE_Long, Do_BNE_Short, Do_BEQ_Long, Do_BEQ_Short : NEAR
        EXTRN Do_BVC_Long, Do_BVC_Short, Do_BVS_Long, Do_BVS_Short : NEAR
        EXTRN Do_BPL_Long, Do_BPL_Short, Do_BMI_Long, Do_BMI_Short : NEAR
;        EXTRN Do_DBxx, Do_Bxx_Long, Do_Bxx_Short : NEAR

        EXTRN Do_DBLT, Do_BLT_Long, Do_BLT_Short : NEAR
        EXTRN Do_DBGE, Do_BGE_Long, Do_BGE_Short : NEAR
        EXTRN Do_DBLE, Do_BLE_Long, Do_BLE_Short : NEAR
        EXTRN Do_DBGT, Do_BGT_Long, Do_BGT_Short : NEAR


PROC Init_Instructions_BRANCH NEAR

        call    Init_Instructions_Bxx                   ;Init BRA, BSR, Bcc
        call    Init_Instructions_DBcc                  ;Init DBcc
        call    Init_Instructions_Jxx                   ;Init JMP, JSR
        call    Init_Instruction_Trap                   ;Init TRAP
        mov     [Opcodes_Jump+4e75h*4],OFFSET Do_RTS    ;Init RTS
        mov     [Opcodes_Jump+4e77h*4],OFFSET Do_RTR    ;Init RTR
        mov     [Opcodes_Jump+4e76h*4],OFFSET Do_TRAPV  ;Init TRAPV
        mov     [Opcodes_Jump+4e71h*4],OFFSET Do_NOP    ;Init NOP
        mov     [Opcodes_Jump+4e70h*4],OFFSET Do_RESET  ;RESET!!!!
        ret
        ENDP



;PROC Init_Table_Conditions NEAR
;        lea     esi,[Table_Conditions]
;        xor     ecx,ecx
;@@make0:
;        xor     edx,edx
;@@tab256:
;        mov     [BYTE PTR esi+edx],0
;        mov     [BYTE PTR esi+edx+100h],0ffh
;        inc     dl
;        jnz     @@tab256
;        add     esi,200h
;        inc     ecx
;        cmp     ecx,8
;        jnz     @@make0
;
;        xor     edx,edx
;        lea     esi,[Table_Conditions]
;        lea     edi,[Table_MakeConditions]
;        mov     ecx,8
;@@all8:
;        mov     dx,[edi]        ;0000cccc 00000000
;        add     edi,2
;
;        mov     bx,[edi]
;        add     edi,2
;@@allv:
;        or      bx,bx
;        jz      @@nxt
;
;        mov     eax,edx
;        or      ax,[edi]
;        add     edi,2
;        mov     [BYTE PTR esi+eax],0ffh
;        mov     [BYTE PTR esi+eax+100h],0
;        dec     bx
;        jmp     @@allv
;@@nxt:
;        dec     ecx
;        jnz     @@all8
;        ret
;        ENDP

; [fold]  [
PROC Init_Instruction_TRAP NEAR
        mov     eax,04e40h
        mov     ecx,16
@@all:
        mov     [Opcodes_Jump+eax*4],OFFSET Do_TRAP
        inc     eax
        dec     ecx
        jnz     @@all
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instructions_Jxx NEAR

        lea     ebx,[Table_Valid_Jump]
        lea     esi,[Do_JMP]                    ;ESI: JMP ($4EC0)
        lea     edi,[Do_JSR]                    ;EDI: JSR ($4E80)
@@Next:
        mov     eax,04ec0h
        or      ax,[ebx]
        mov     [Opcodes_Jump+eax*4],esi
        mov     eax,04e80h
        or      ax,[ebx]
        mov     [Opcodes_Jump+eax*4],edi
        add     ebx,2
        cmp     ebx,OFFSET Table_Valid_Jump_END
        jnz     @@Next
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instructions_DBcc NEAR

        lea     ebx,[Table_DBranch_Functions]
@@Next:
        mov     eax,[ebx]                       ; Mask instruction
        mov     edi,[ebx+4]                     ; Dbcc Function
        mov     ecx,8
@@AllRegs:
        mov     [Opcodes_Jump+eax*4],edi
        inc     al
        dec     ecx
        jnz     @@AllRegs
        add     ebx,8
        cmp     ebx,OFFSET Table_DBranch_Functions_END
        jnz     @@Next
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Init_Instructions_Bxx NEAR

        lea     ebx,[Table_Branch_Functions]
@@Next:
        mov     eax,[ebx]                       ; Mask instruction
        mov     edi,[ebx+4]                     ; Function for Long branch
        mov     [Opcodes_Jump+eax*4],edi
        mov     edi,[ebx+8]                     ; Function for Short branch
        inc     eax
@@AllOffset:
        mov     [Opcodes_Jump+eax*4],edi
        inc     al
        jnz     @@AllOffset
        add     ebx,12
        cmp     ebx,OFFSET Table_Branch_Functions_End
        jnz     @@Next
        ret
        ENDP

; [fold]  ]

        DATASEG

;LABEL Table_MakeConditions      ;hybrid CCR => NZ-- --VC
;
;        dw      0000h,16         ;T                              1
;                        dw      000h    ;n=0  z=0  v=0  c=0
;                        dw      001h    ;n=0  z=0  v=0  c=1
;                        dw      002h    ;n=0  z=0  v=1  c=0
;                        dw      003h    ;n=0  z=0  v=1  c=1
;                        dw      040h    ;n=0  z=1  v=0  c=0
;                        dw      041h    ;n=0  z=1  v=0  c=1
;                        dw      042h    ;n=0  z=1  v=1  c=0
;                        dw      043h    ;n=0  z=1  v=1  c=1
;                        dw      080h    ;n=1  z=0  v=0  c=0
;                        dw      081h    ;n=1  z=0  v=0  c=1
;                        dw      082h    ;n=1  z=0  v=1  c=0
;                        dw      083h    ;n=1  z=0  v=1  c=1
;                        dw      0c0h    ;n=1  z=1  v=0  c=0
;                        dw      0c1h    ;n=1  z=1  v=0  c=1
;                        dw      0c2h    ;n=1  z=1  v=1  c=0
;                        dw      0c3h    ;n=1  z=1  v=1  c=1
;        dw      0200h,4         ;HI                             C+Z = 0
;                        dw      000h    ;n=0  z=0  v=0  c=0
;                        dw      002h    ;n=0  z=0  v=1  c=0
;                        dw      080h    ;n=1  z=0  v=0  c=0
;                        dw      082h    ;n=1  z=0  v=1  c=0
;        dw      0400h,8         ;CC                             C=0
;                        dw      000h    ;n=0  z=0  v=0  c=0
;                        dw      002h    ;n=0  z=0  v=1  c=0
;                        dw      040h    ;n=0  z=1  v=0  c=0
;                        dw      042h    ;n=0  z=1  v=1  c=0
;                        dw      080h    ;n=1  z=0  v=0  c=0
;                        dw      082h    ;n=1  z=0  v=1  c=0
;                        dw      0c0h    ;n=1  z=1  v=0  c=0
;                        dw      0c2h    ;n=1  z=1  v=1  c=0
;        dw      0600h,8         ;NE                             Z=0
;                        dw      000h    ;n=0  z=0  v=0  c=0
;                        dw      001h    ;n=0  z=0  v=0  c=1
;                        dw      002h    ;n=0  z=0  v=1  c=0
;                        dw      003h    ;n=0  z=0  v=1  c=1
;                        dw      080h    ;n=1  z=0  v=0  c=0
;                        dw      081h    ;n=1  z=0  v=0  c=1
;                        dw      082h    ;n=1  z=0  v=1  c=0
                        dw      083h    ;n=1  z=0  v=1  c=1
;        dw      0800h,8         ;VC                             V=0
;                        dw      000h    ;n=0  z=0  v=0  c=0
;                        dw      001h    ;n=0  z=0  v=0  c=1
;                        dw      040h    ;n=0  z=1  v=0  c=0
;                        dw      041h    ;n=0  z=1  v=0  c=1
;                        dw      080h    ;n=1  z=0  v=0  c=0
;                        dw      081h    ;n=1  z=0  v=0  c=1
;                        dw      0c0h    ;n=1  z=1  v=0  c=0
;                        dw      0c1h    ;n=1  z=1  v=0  c=1
;        dw      0a00h,8         ;PL                             N=0
;                        dw      000h    ;n=0  z=0  v=0  c=0
;                        dw      001h    ;n=0  z=0  v=0  c=1
;                        dw      002h    ;n=0  z=0  v=1  c=0
;                        dw      003h    ;n=0  z=0  v=1  c=1
;                        dw      040h    ;n=0  z=1  v=0  c=0
;                        dw      041h    ;n=0  z=1  v=0  c=1
;                        dw      042h    ;n=0  z=1  v=1  c=0
;                        dw      043h    ;n=0  z=1  v=1  c=1
;        dw      0c00h,8         ;GE                             N^V = 0
;                        dw      000h    ;n=0  z=0  v=0  c=0
;                        dw      001h    ;n=0  z=0  v=0  c=1
;                        dw      040h    ;n=0  z=1  v=0  c=0
;                        dw      041h    ;n=0  z=1  v=0  c=1
;                        dw      082h    ;n=1  z=0  v=1  c=0
;                        dw      083h    ;n=1  z=0  v=1  c=1
;                        dw      0c2h    ;n=1  z=1  v=1  c=0
;                        dw      0c3h    ;n=1  z=1  v=1  c=1
;        dw      0e00h,4         ;GT                             Z+(N^V)=0
;                        dw      000h    ;n=0  z=0  v=0  c=0
;                        dw      001h    ;n=0  z=0  v=0  c=1
;                        dw      082h    ;n=1  z=0  v=1  c=0
;                        dw      083h    ;n=1  z=0  v=1  c=1

LABEL Table_Valid_Jump                        ;valid EA with JSR & JMP

        dw      010h,011h,012h,013h,014h,015h,016h,017h         ;(An)
        dw      028h,029h,02ah,02bh,02ch,02dh,02eh,02fh         ;d(An)
        dw      030h,031h,032h,033h,034h,035h,036h,037h         ;d(An,Xi)
        dw      038h,039h,03ah,03bh                             ;Abs, Pc rel
LABEL Table_Valid_Jump_END

LABEL Table_DBranch_Functions
        dd      050c8h,Do_DBT
        dd      051c8h,Do_DBF
        dd      052c8h,Do_DBHI
        dd      053c8h,Do_DBLS
        dd      054c8h,Do_DBCC
        dd      055c8h,Do_DBCS
        dd      056c8h,Do_DBNE
        dd      057c8h,Do_DBEQ
        dd      058c8h,Do_DBVC
        dd      059c8h,Do_DBVS
        dd      05ac8h,Do_DBPL
        dd      05bc8h,Do_DBMI
        dd      05cc8h,Do_DBGE ;GE
        dd      05dc8h,Do_DBLT ;LT
        dd      05ec8h,Do_DBGT ;GT
        dd      05fc8h,Do_DBLE ;LE
LABEL Table_DBranch_Functions_END


LABEL Table_Branch_Functions
        dd      06000h,Do_BRA_Long,Do_BRA_Short
        dd      06100h,Do_BSR_Long,Do_BSR_Short
        dd      06200h,Do_BHI_Long,Do_BHI_Short
        dd      06300h,Do_BLS_Long,Do_BLS_Short
        dd      06400h,Do_BCC_Long,Do_BCC_Short
        dd      06500h,Do_BCS_Long,Do_BCS_Short
        dd      06600h,Do_BNE_Long,Do_BNE_Short
        dd      06700h,Do_BEQ_Long,Do_BEQ_Short
        dd      06800h,Do_BVC_Long,Do_BVC_Short
        dd      06900h,Do_BVS_Long,Do_BVS_Short
        dd      06a00h,Do_BPL_Long,Do_BPL_Short
        dd      06b00h,Do_BMI_Long,Do_BMI_Short
        dd      06c00h,Do_BGE_Long,Do_BGE_Short ;GE
        dd      06d00h,Do_BLT_Long,Do_BLT_Short ;LT
        dd      06e00h,Do_BGT_Long,Do_BGT_Short ;GT
        dd      06f00h,Do_BLE_Long,Do_BLE_Short ;LE
LABEL Table_Branch_Functions_END

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ                                                                    MOVEM
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

        EXTRN Do_MOVEM_W_to_mem_Aipd : NEAR
        EXTRN Do_MOVEM_L_to_mem_Aipd : NEAR
        EXTRN Do_MOVEM_W_to_mem : NEAR
        EXTRN Do_MOVEM_L_to_mem : NEAR
        EXTRN Do_MOVEM_W_from_mem_Aipi : NEAR
        EXTRN Do_MOVEM_L_from_mem_Aipi : NEAR
        EXTRN Do_MOVEM_W_from_mem : NEAR
        EXTRN Do_MOVEM_L_from_mem : NEAR


PROC Init_Instructions_MOVEM NEAR
;--------------------------------------------------------------- push
        lea     ebx,[Valid_Modes_MOVEM_Aipd]
        mov     edx,4880h
        lea     edi,[Do_MOVEM_W_to_mem_Aipd]
        call    Add_MOVEM
        lea     ebx,[Valid_Modes_MOVEM_Aipd]
        mov     edx,48c0h
        lea     edi,[Do_MOVEM_L_to_mem_Aipd]
        call    Add_MOVEM
        lea     ebx,[Valid_Modes_MOVEM_to_mem]
        mov     edx,4880h
        lea     edi,[Do_MOVEM_W_to_mem]
        call    Add_MOVEM
        lea     ebx,[Valid_Modes_MOVEM_to_mem]
        mov     edx,48c0h
        lea     edi,[Do_MOVEM_L_to_mem]
        call    Add_MOVEM
;--------------------------------------------------------------- pop
        lea     ebx,[Valid_Modes_MOVEM_Aipi]
        mov     edx,4c80h
        lea     edi,[Do_MOVEM_W_from_mem_Aipi]
        call    Add_MOVEM
        lea     ebx,[Valid_Modes_MOVEM_Aipi]
        mov     edx,4cc0h
        lea     edi,[Do_MOVEM_L_from_mem_Aipi]
        call    Add_MOVEM
        lea     ebx,[Valid_Modes_MOVEM_from_mem]
        mov     edx,4c80h
        lea     edi,[Do_MOVEM_W_from_mem]
        call    Add_MOVEM
        lea     ebx,[Valid_Modes_MOVEM_from_mem]
        mov     edx,4cc0h
        lea     edi,[Do_MOVEM_L_from_mem]
        call    Add_MOVEM
        ret
        ENDP

PROC Add_MOVEM NEAR
        mov     ecx,[ebx]
        add     ebx,4
@@allmodes:
        mov     eax,edx
        or      ax,[ebx]
        mov     [Opcodes_Jump+eax*4],edi
        add     ebx,2
        dec     ecx
        jnz     @@allmodes
        ret
        ENDP

        DATASEG


LABEL Valid_Modes_MOVEM_Aipd
        dd      8
        dw      20h,21h,22h,23h,24h,25h,26h,27h         ;-(An)
LABEL Valid_Modes_MOVEM_to_mem
        dd      26
        dw      10h,11h,12h,13h,14h,15h,16h,17h         ;(An)
        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh         ;d(An)
        dw      30h,31h,32h,33h,34h,35h,36h,37h         ;d(An,Xi)
        dw      38h,39h                                 ;Abs
LABEL Valid_Modes_MOVEM_Aipi
        dd      8
        dw      18h,19h,1ah,1bh,1ch,1dh,1eh,1fh         ;(An)+
LABEL Valid_Modes_MOVEM_from_mem
        dd      28
        dw      10h,11h,12h,13h,14h,15h,16h,17h         ;(An)
        dw      28h,29h,2ah,2bh,2ch,2dh,2eh,2fh         ;d(An)
        dw      30h,31h,32h,33h,34h,35h,36h,37h         ;d(An,Xi)
        dw      38h,39h,3ah,3bh                         ;Abs, pc rel

        END


; [fold]  39
