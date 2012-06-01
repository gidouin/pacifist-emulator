
        IDEAL

        include "simu68.inc"
        include "chips.inc"

        PUBLIC Do_Blitter

        PUBLIC  Halftone_Memory
        PUBLIC  Inc_Source_X
        PUBLIC  Inc_Source_Y
        PUBLIC  Inc_Destination_X
        PUBLIC  Inc_Destination_Y
        PUBLIC  Size_X
        PUBLIC  Size_Y
        PUBLIC  Adr_Source
        PUBLIC  Adr_Destination
        PUBLIC  Mask1
        PUBLIC  Mask2
        PUBLIC  Mask3
        PUBLIC  HOp
        PUBLIC  LOp
        PUBLIC  Line_Number
        PUBLIC  Source_Shift
        PUBLIC  NFSR
        PUBLIC  FXSR
        PUBLIC  Blitter_Control

        CODESEG

;--------------------------------------------------- init transfer

MACRO BLIT_A_WORD msk1, msk2
        call    [do_hop]
        mov     dx,[edi]                        ;read destination
        rol     dx,8                            ;intel order
        mov     ax,dx                           ;ax = destination
        call    [Logical_Operation_Routine]     ;LOGICAL OPERATION
        and     ax,[msk1]                       ;mask result
        and     dx,[msk2]                       ;mask destination
        or      ax,dx                           ;new destination
        rol     ax,8                            ;motorola order
        mov     [edi],ax
ENDM

Do_Blitter:
        pushad
        lea     esi,[memio+0a00h]       ; ffff8a00.w

        lea     ecx,[Table_Read_Blitter_Source] ;plus routines default
        mov     ebx,0ffff0000h                  ;mask plus default
        mov     ax,[esi+020h]           ; ffff8a20.w = Increment Source X
        rol     ax,8
        and     ax,0fffeh
        movsx   eax,ax
        cmp     eax,0
        jns     @@poz
        add     ecx,4*4                 ; minus routines
        mov     ebx,0ffffh              ; minus mask
@@poz:
        mov     [keep_bits],ebx
        mov     [Inc_Source_X],eax

        mov     al,[esi+03ah]           ; ffff8a3a.b = Halftone Operation
        and     eax,3
        mov     [HOp],eax
        mov     edx,[ecx+eax*4]
        mov     [Read_Blitter_Source],edx
        mov     edx,[Table_Hop+eax*4]
        mov     [Do_Hop],edx

        mov     al,[esi+03bh]          ; ffff8a3b.b = Logical Operation
        and     eax,15
        mov     [LOp],eax
        mov     edx,[Table_Logical_Operations+eax*4]
        mov     [Logical_Operation_Routine],edx

        mov     ax,[esi+022h]           ; ffff8a22.w = Increment Source Y
        rol     ax,8
        and     ax,0fffeh
        movsx   eax,ax
        mov     [Inc_Source_Y],eax

        mov     eax,[esi+24h]           ; ffff8a24.l = Adresse Source
        bswap   eax
        and     eax,0fffffeh
        mov     [Adr_Source],eax

        mov     ax,[esi+28h]            ; ffff8a28.w = mask 1
        mov     bx,[esi+2ah]            ; ffff8a2a.w = mask 2
        mov     cx,[esi+2ch]            ; ffff8a2c.w = mask 3
        rol     ax,8
        rol     bx,8
        rol     cx,8
        mov     [Mask1],ax
        mov     [Mask2],bx
        mov     [Mask3],cx
        not     ax
        not     bx
        not     cx
        mov     [notMask1],ax
        mov     [notMask2],bx
        mov     [notMask3],cx

        mov     ax,[esi+02eh]           ; ffff8a2e.w = Increment Dest X
        rol     ax,8
        and     ax,0fffeh
        movsx   eax,ax
        mov     [Inc_Destination_X],eax

        mov     ax,[esi+030h]           ; ffff8a30.w = Increment Dest Y
        rol     ax,8
        and     ax,0fffeh
        movsx   eax,ax
        mov     [Inc_Destination_Y],eax

        mov     eax,[esi+032h]          ; ffff8a32.w = Adresse Destination
        bswap   eax
        and     eax,0fffffeh
        mov     [Adr_Destination],eax

        mov     ax,[esi+036h]           ; ffff8a36.w = Size X
        rol     ax,8
        movzx   eax,ax
        mov     [Size_X],eax

        mov     ax,[esi+038h]           ; ffff8a38.w = Size Y
        rol     ax,8
        movzx   eax,ax
        mov     [Size_Y],eax

        mov     al,[esi+03dh]          ; ffff8a3d.b = Blitter Modes
        mov     edx,eax
        and     eax,15
        mov     [Source_Shift],eax
        add     dl,dl
        setc    [BYTE PTR FXSR]
        add     dl,dl
        setc    [BYTE PTR NFSR]

        mov     al,[esi+03ch]          ; ffff8a3c.b = Blitter Control
        mov     [BYTE PTR Blitter_Control],al
        mov     edx,eax
        and     eax,15
        mov     [Line_Number],eax       ; Current Halftone = Line Number
;        test    edx,020h
;        jz      @@noskew
;        mov     eax,[Source_Shift]
;@@noskew:
        mov     [Halftone_Current],eax

        mov     eax,1
        cmp     [Inc_Destination_Y],0
        jns     @@pozit
        mov     eax,-1
@@pozit:
        mov     [Halftone_Direction],eax

        IFDEF DEBUG
;        extrn debug_blitter : near              ; call C function
        push    es fs
;        call    debug_blitter                   ; LOG blitter access
        pop     fs es
        ENDIF

        ;----------------------------------------- calc PC pointers

        call    Get_Blitter_Pointers    ;ESI:src EDI:dest (esi|edi)==0:error
        jc      Error_ptr               ;BX:src DX:dst

        ;------------------------------------------ blitting MACRO

        xor     ebx,ebx
        mov     ecx,[Source_Shift]
        push    ebp

        ;------------------------------------------- start blitting
y_loop:
        test    [Hop],1
        jz      @@noi
        call    Halftone_Inc
@@noi:
        push    [Size_X]                        ;preserve Size_X

        test    [FXSR],1                        ;Fetch Extra Source?
        jz      @@nofxsr
        rol     ebx,16                          ;shift source to hi order
        and     ebx,[keep_bits]
        call    [read_blitter_source]           ;read source
        add     esi,[Inc_Source_X]              ;next source adr
@@nofxsr:
        ;------------------------------------------- a line of blitter

        rol     ebx,16                          ;shift source to hi order
        and     ebx,[keep_bits]
        call    [read_blitter_source]           ;read source

        BLIT_A_WORD mask1 notmask1              ;BLIT first word
        dec     [Size_X]                        ;only one word???
        je      end_line_blitter
@@next:
        dec     [Size_X]                        ;last words?
        je      third_word

        add     esi,[Inc_Source_X]
        add     edi,[Inc_Destination_X]
        rol     ebx,16
        and     ebx,[keep_bits]
        call    [read_blitter_source]
        BLIT_A_WORD mask2 notmask2
        jmp     @@next
third_word:
        add     edi,[Inc_Destination_X]
        rol     ebx,16
        and     ebx,[keep_bits]

        test    [NFSR],1
        jnz     @@nofsr
@@ddd:
        add     esi,[Inc_Source_X]
        call    [read_blitter_source]
@@nofsr:
        BLIT_A_WORD mask3 notmask3
end_line_blitter:
;--------------------------------------------------------- next line
        pop     [Size_X]                        ;pop Size_X for next line
        add     esi,[Inc_Source_Y]              ;next Source line
        add     edi,[Inc_Destination_Y]         ;next Destination line

        dec     [WORD PTR Size_Y]
        jnz     y_loop                          ;...for all height

        pop     ebp

        sub     edi,[base_dest]
        bswap   edi
        mov     [DWORD PTR memio+0a32h],edi

        ;mov     eax,[Halftone_Current]
        ;and     eax,15
        ;and     [memio+0a3ch],0f0h
        ;or      [memio+0a3ch],al
Error_Ptr:
        popad
        ret

        ;----------------------------------------- returns ESI, EDI

Get_Blitter_Pointers:
        mov     ebx,[memory_ram]
        mov     eax,[Adr_Source]
        cmp     eax,[ebp+BASE.ramsize]
        jb      @@src_found
        lea     ebx,[memtos]
        cmp     eax,[tosbase]
        jb      @@error
        cmp     eax,[tosbasemax]
        ja      @@error
        sub     ebx,[tosbase]
@@src_found:
        mov     [base_src],ebx
        lea     esi,[eax+ebx]

        mov     ebx,[memory_ram]
        mov     eax,[Adr_Destination]
        cmp     eax,[ebp+BASE.ramsize]
        jb      @@dst_found
        lea     ebx,[memtos]
        cmp     eax,[tosbase]
        jb      @@error
        cmp     eax,[tosbasemax]
        ja      @@error
        sub     ebx,[tosbase]
@@dst_found:
        mov     [base_dest],ebx
        lea     edi,[eax+ebx]
        clc
        ret
@@error:
        stc
        ret

;------------------------------------------------- read HalfTone RAM

Halftone_Inc:
        mov     eax,[HalfTone_Current]
        and     eax,15
        mov     dx,[WORD PTR memio+0a00h+eax*2]
        add     eax,[HalfTone_Direction]
        rol     dx,8
        mov     [HalfTone_Value],dx
        mov     [HalfTone_Current],eax
        ret
;------------------------------------------------- HalfTone operations
        ;-------------------------------- 1

ht_0_plus:
        mov     bx,0ffffh
        mov     ebp,ebx
        ret
ht_0_minus:
        or      ebx,0ffff0000h
        mov     ebp,ebx
        ret

        ;-------------------------------- HALFTONE

ht_1_plus:
        mov     bx,[HalfTone_Value]
        mov     ebp,ebx
        ret
ht_1_minus:
        mov     ax,[HalfTone_Value]
        and     ebx,0ffffh
        shl     eax,16
        or      ebx,eax
        mov     ebp,ebx
        ret

        ;-------------------------------- SOURCE

ht_2_plus:
        mov     bx,[esi]
        rol     bx,8
        mov     ebp,ebx
        shr     ebp,cl
        ret
ht_2_minus:
        mov     ax,[esi]
        rol     ax,8
        and     ebx,0ffffh
        shl     eax,16
        or      ebx,eax
        mov     ebp,ebx
        shr     ebp,cl
        ret

        ;-------------------------------- SOURCE and HALFTONE

ht_3_plus:
        mov     bx,[esi]
        rol     bx,8
        mov     ebp,ebx
        shr     ebp,cl
        and     bp,[HalfTone_Value]
        ret
ht_3_minus:
        mov     ax,[esi]
        rol     ax,8
        and     ebx,0ffffh
        shl     eax,16
        or      ebx,eax
        mov     ebp,ebx
        shr     ebp,cl
        and     bp,[HalfTone_Value]
        ret
;------------------------------------------------- Logical operations
;                                        ax : destination, bp: source

lo_0:                           ;0
        xor     ax,ax
        ret
lo_1:                           ;s AND d
        and     ax,bp
        ret
lo_2:                           ;s AND NOT d
        not     ax
        and     ax,bp
        ret
lo_3:                           ;s
        mov     ax,bp
        ret
lo_4:                           ;NOT s AND d
        not     bp
        and     ax,bp
        ret
lo_5:                           ;d
        ret
lo_6:                           ;s XOR d
        xor     ax,bp
        ret
lo_7:                           ;s OR d
        or      ax,bp
        ret
lo_8:                           ;NOT s AND NOT d
        not     ax
        not     bp
        and     ax,bp
        ret
lo_9:                           ;NOT s XOR d
        not     bp
        xor     ax,bp
        ret
lo_a:                           ;NOT d
        not     ax
        ret
lo_b:                           ;s OR NOT d
        not     ax
        or      ax,bp
        ret
lo_c:                           ;NOT s
        mov     ax,bp
        not     ax
        ret
lo_d:                           ;NOT s OR d
        not     bp
        or      ax,bp
        ret
lo_e:                           ;NOT s OR NOT d
        not     ax
        not     bp
        or      ax,bp
        ret
lo_f:                           ;1
        mov     ax,-1
        ret


do_hop0:
        mov     bp,-1
        ret
do_hop1:
        mov     bp,[Halftone_Value]
        ret
do_hop2:
        mov     ebp,ebx
        shr     ebp,cl
        ret
do_hop3:
        mov     ebp,ebx
        shr     ebp,cl
        and     bp,[Halftone_Value]
        ret

read_hop0_p:
read_hop1_p:
read_hop0_n:
read_hop1_n:
        ret
read_hop2_p:
read_hop3_p:
        mov     bx,[esi]
        rol     bx,8
        ret

read_hop2_n:
read_hop3_n:
        mov     ax,[esi]
        rol     ax,8
        and     ebx,0ffffh
        shl     eax,16
        or      ebx,eax
        ret



        DATASEG

Halftone_Memory         dw      16      dup (0)
Inc_Source_X            dd      0       ;Increment X source
Inc_Source_Y            dd      0       ;Increment Y source
Inc_Destination_X       dd      0       ;Increment X destination
Inc_Destination_Y       dd      0       ;Increment Y destination
Size_X                  dd      0       ;Size X
Size_Y                  dd      0       ;Size Y
Adr_Source              dd      0       ;Adresse Source
Adr_Destination         dd      0       ;Adresse Destination
HOp                     dd      0       ;Halftone Operation
LOp                     dd      0       ;Logical Operation
Line_Number             dd      0       ;Line Number
Source_Shift            dd      0       ;Skew (source shift)
NFSR                    dd      0       ;No Final Source Read
FXSR                    dd      0       ;Force eXtra Source Read
Blitter_Control         dd      0

Mask1                   dw      0       ;mask gauche
Mask2                   dw      0       ;mask milieu
Mask3                   dw      0       ;mask droit
NotMask1                dw      0
NotMask2                dw      0
NotMask3                dw      0

Halftone_Current        dd      0
Halftone_Direction      dd      0
Halftone_Value          dw      0

Logical_Operation_Routine       dd      0
Read_Blitter_Source             dd      0

LABEL Table_Logical_Operations DWORD
        dd      lo_0,lo_1,lo_2,lo_3,lo_4,lo_5,lo_6,lo_7
        dd      lo_8,lo_9,lo_a,lo_b,lo_c,lo_d,lo_e,lo_f

LABEL Table_Read_Blitter_Source DWORD
        dd      read_hop0_p, read_hop1_p, read_hop2_p, read_hop3_p
        dd      read_hop0_n, read_hop1_n, read_hop2_n, read_hop3_n


LABEL Table_Hop DWORD
        dd      do_hop0, do_hop1, do_hop2, do_hop3

do_hop  dd      0

base_src        dd      0
base_dest       dd      0
keep_bits       dd      0

END


