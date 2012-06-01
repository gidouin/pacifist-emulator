COMMENT ~
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ Emulation of MOVE type instructions                                      ³
³                                                                          ³
³       25/6/96  Converted all code to TASM IDEAL mode                     ³
³                                                                          ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
~
        IDEAL

        INCLUDE "simu68.inc"
        INCLUDE "profile.inc"

        PUBLIC Do_MOVEM_W_to_mem_Aipd
        PUBLIC Do_MOVEM_L_to_mem_Aipd
        PUBLIC Do_MOVEM_W_to_mem
        PUBLIC Do_MOVEM_L_to_mem
        PUBLIC Do_MOVEM_W_from_mem_Aipi
        PUBLIC Do_MOVEM_L_from_mem_Aipi
        PUBLIC Do_MOVEM_W_from_mem
        PUBLIC Do_MOVEM_L_from_mem


        CODESEG

Do_MOVEM_W_from_mem_Aipi:
        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        and     eax,7

        push    esi eax
        mov     edi,[ebp+eax*4+base.A]

        and     edi,0ffffffh
        xor     eax,eax
        mov     esi,16
        lea     ebx,[ebp+base.D]
        cmp     edi,[ebp+base.RAMSIZE]
        jnb     @@nodirectmemory
@@all16d:
        shr     ecx,1
        jnc     @@nodd
        mov     dx,[fs:edi]
        rol     dx,8
        add     edi,2
        movsx   edx,dx
        inc     eax
        mov     [ebx],edx
@@nodd: add     ebx,4
        dec     esi
        jnz     @@all16d
        jmp     @@cont
@@nodirectmemory:
@@all16:
        shr     ecx,1
        jnc     @@nod
        Read_W
        add     edi,2
        movsx   edx,dx
        inc     eax
        mov     [ebx],edx
@@nod:  add     ebx,4
        dec     esi
        jnz     @@all16
@@cont:
        pop     ecx esi
        and     [ebp+ecx*4+base.A],0ff000000h
        add     [ebp+ecx*4+base.A],edi
        shl     eax,2
        add     eax,12
        Next    eax


Do_MOVEM_L_from_mem_Aipi:
        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        and     eax,7

        push    esi eax
        mov     edi,[ebp+eax*4+base.A]

        and     edi,0ffffffh
        xor     eax,eax
        mov     esi,16
        lea     ebx,[ebp+base.D]
        cmp     edi,[ebp+base.RAMSIZE]
        jnb     @@nodirectmemory
@@all16d:
        shr     ecx,1
        jnc     @@nodd
        mov     edx,[fs:edi]
        bswap   edx
        add     edi,4
        inc     eax
        mov     [ebx],edx
@@nodd: add     ebx,4
        dec     esi
        jnz     @@all16d
        jmp     @@cont

@@nodirectmemory:
@@all16:
        shr     ecx,1
        jnc     @@nod
        Read_L
        add     edi,4
        inc     eax
        mov     [ebx],edx
@@nod:  add     ebx,4
        dec     esi
        jnz     @@all16
@@cont:
        pop     ecx esi
        and     [ebp+ecx*4+base.A],0ff000000h
        add     [ebp+ecx*4+base.A],edi
        shl     eax,3
        add     eax,12
        Next    eax



Do_MOVEM_W_from_mem:
        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        Instr_To_EA_W

        push    esi
        and     edi,0ffffffh
        lea     ebx,[ebp+base.D]
        xor     eax,eax
        mov     esi,16
        cmp     edi,[ebp+base.RAMSIZE]
        jnb     @@nodirectmemory
@@all16d:
        shr     ecx,1
        jnc     @@nodd
        mov     dx,[fs:edi]
        rol     dx,8
        inc     eax
        movsx   edx,dx
        add     edi,2
        mov     [ebx],edx
@@nodd: add     ebx,4
        dec     esi
        jnz     @@all16d
        jmp     @@cont
@@nodirectmemory:
@@all16:
        shr     ecx,1
        jnc     @@nod
        Read_W
        inc     eax
        movsx   edx,dx
        add     edi,2
        mov     [ebx],edx
@@nod:  add     ebx,4
        dec     esi
        jnz     @@all16
@@cont:
        pop     esi
        shl     eax,2
        add     eax,8
        Next    eax


Do_MOVEM_L_from_mem:
        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        Instr_To_EA_W

        push    esi
        and     edi,0ffffffh
        lea     ebx,[ebp+base.D]
        xor     eax,eax
        mov     esi,16
        cmp     edi,[ebp+base.RAMSIZE]
        jnb     @@nodirectmemory
@@all16d:
        shr     ecx,1
        jnc     @@nodd
        mov     edx,[fs:edi]
        bswap   edx
        inc     eax
        add     edi,4
        mov     [ebx],edx
@@nodd: add     ebx,4
        dec     esi
        jnz     @@all16d
        jmp     @@cont
@@nodirectmemory:
@@all16:
        shr     ecx,1
        jnc     @@nod
        Read_L
        inc     eax
        add     edi,4
        mov     [ebx],edx
@@nod:  add     ebx,4
        dec     esi
        jnz     @@all16
@@cont:
        pop     esi
        shl     eax,3
        add     eax,4
        Next    eax


PROC Do_Movem_L_To_Mem NEAR
        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        Instr_To_EA_W

        push    esi

        and     edi,0ffffffh

        lea     ebx,[ebp+base.D]
        xor     eax,eax
        mov     esi,16

        cmp     edi,[ebp+base.RAMSIZE]
        jnb     @@nodirectmemory
@@all16d:
        shr     ecx,1
        jnc     @@nod1
        mov     edx,[ebx]
        bswap   edx
        inc     eax
        mov     [fs:edi],edx
        add     edi,4
@@nod1: add     ebx,4
        dec     esi
        jnz     @@all16d
        jmp     @@continue
@@nodirectmemory:
@@all16:
        shr     ecx,1
        jnc     @@nod2
        mov     edx,[ebx]
        inc     eax
        Write_L
        add     edi,4
@@nod2: add     ebx,4
        dec     esi
        jnz     @@all16
@@continue:
        lea     edx,[eax*8]
        pop     esi
        Next    edx
        ENDP

PROC Do_Movem_W_To_Mem NEAR
        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        Instr_To_EA_W

        push    esi

        and     edi,0ffffffh

        lea     ebx,[ebp+base.D]
        xor     eax,eax
        mov     esi,16

        cmp     edi,[ebp+base.RAMSIZE]
        jnb     @@nodirectmemory
@@all16d:
        shr     ecx,1
        jnc     @@nod1
        mov     dx,[ebx]
        rol     dx,8
        inc     eax
        mov     [fs:edi],dx
        add     edi,2
@@nod1: add     ebx,4
        dec     esi
        jnz     @@all16d
        jmp     @@continue
@@nodirectmemory:
@@all16:
        shr     ecx,1
        jnc     @@nod2
        mov     dx,[ebx]
        inc     eax
        Write_W
        add     edi,2
@@nod2: add     ebx,4
        dec     esi
        jnz     @@all16
@@continue:
        lea     edx,[eax*4+4]
        pop     esi
        Next    edx
        ENDP



PROC Do_Movem_W_To_Mem_Aipd NEAR
        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        and     eax,7

        push    eax esi

        mov     edi,[ebp+eax*4+base.A]          ;EDI=Address Register Value
        and     edi,0ffffffh

        lea     ebx,[ebp+8*4+base.A]
        xor     eax,eax
        mov     esi,16

        cmp     edi,[ebp+base.RAMSIZE]
        jnb     @@nodirectmemory
@@all16d:
        sub     ebx,4
        shr     ecx,1
        jnc     @@nodd
        mov     dx,[ebx]
        sub     edi,2
        rol     dx,8
        inc     eax
        mov     [fs:edi],dx
@@nodd: dec     esi
        jnz     @@all16
        jmp     @@continue
@@nodirectmemory:
@@all16:
        sub     ebx,4
        shr     ecx,1
        jnc     @@nod
        mov     dx,[ebx]
        sub     edi,2
        inc     eax
        Write_W
@@nod:  dec     esi
        jnz     @@all16
@@continue:
        lea     edx,[eax*4+8]
        pop     esi eax
        and     [ebp+eax*4+base.A],0ff000000h
        add     [ebp+eax*4+base.A],edi
        Next    edx
        ENDP

PROC Do_Movem_L_To_Mem_Aipd NEAR
        mov     cx,[es:esi]
        add     esi,2
        rol     cx,8
        and     eax,7

        push    eax esi

        mov     edi,[ebp+eax*4+base.A]          ;EDI=Address Register Value
        and     edi,0ffffffh

        lea     ebx,[ebp+8*4+base.A]
        xor     eax,eax
        mov     esi,16

        cmp     edi,[ebp+base.RAMSIZE]
        jnb     @@nodirectmemory
@@all16d:
        sub     ebx,4
        shr     ecx,1
        jnc     @@nodd
        mov     edx,[ebx]
        sub     edi,4
        bswap   edx
        inc     eax
        mov     [fs:edi],edx
@@nodd: dec     esi
        jnz     @@all16
        jmp     @@continue
@@nodirectmemory:
@@all16:
        sub     ebx,4
        shr     ecx,1
        jnc     @@nod
        mov     edx,[ebx]
        sub     edi,4
        inc     eax
        Write_L
@@nod:  dec     esi
        jnz     @@all16
@@continue:
        lea     edx,[eax*8+8]
        pop     esi eax
        and     [ebp+eax*4+base.A],0ff000000h
        add     [ebp+eax*4+base.A],edi
        Next    edx
        ENDP


        END

