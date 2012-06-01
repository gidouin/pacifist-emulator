COMMENT ~
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ 68030 Stuffs                                                             ³
³                                                                          ³
³       21/5/97  Started                                                   ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
~
        IDEAL

        INCLUDE "simu68.inc"

        CODESEG

        PUBLIC init_68030


PROC init_68030 NEAR
        lea     esi,[Opcodes_Jump]
        mov     [DWORD PTR esi+04e7ah*4],OFFSET Do_MOVEC
        mov     [DWORD PTR esi+04e7bh*4],OFFSET Do_MOVEC

        mov     eax,0
@@linex:
        mov     [Opcodes_Jump+(0f000h*4)+eax*4],OFFSET Do_FPU
        inc     eax
        cmp     eax,1000h
        jne short @@linex

        ret
        ENDP

Do_MOVEC:
        add     esi,2
        Next    2

Do_FPU:
        add     esi,2
        Instr_To_EA_W
        Next 2


END
