; ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»
; º                                    º Direct control of the PC hardware º
; º MOUSE                              ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹
; º SCREEN                                                                 º
; º JOYSTICKS                                                              º
; º                                                                        º
; º  25/6/96 rewritten for IDEAL MASM mode                                 º
; º   5/7/96 optimized planar to chunky conversion                         º
; º   6/7/96 video mode 2 support (monochrome)                             º
; º 17/11/96 started analog joystick support                               º
; º 18/12/96 low res rendering in 320x200x32768                            º
; º 22/12/96 started dynamic palette calculation for rasters effect        º
; º  8/01/97 256 colors line-oriented screen rendering OK.                 º
; º          32K & 64K modes slow but work well                            º
; º 13/01/97 switchable screen/line-oriented method.                       º
; º 22/01/97 new chunky->planar routine (thanx Patrice!)                   º
; º 20/03/97 direct mouse driver                                           º
; ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼

        IDEAL
        INCLUDE "simu68.inc"

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Mouse

        PUBLIC  internal_init_mouse              ; initialisation of mouse driver
        PUBLIC  internal_deinit_mouse            ; restauration of mouse driver

        DATASEG

        EXTRN  MouseX : dword          ; mouse X (relative)
        EXTRN  MouseY : dword          ; mouse Y (relative)
        EXTRN  Mouse_Buttons : dword   ; mouse buttons status

        EXTRN mousecom : dword

        CODESEG

        PUBLIC  Test_PC_Joysticks       ; joystick read each PC VBL
        PUBLIC  Init_Joysticks          ; autodetection of joysticks

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Video

        PUBLIC  ModeST                  ; are we in ST screen mode?
        ;PUBLIC  Draw_ST_Screen          ; transfer ST screen to PC
        ;PUBLIC  Enter_ST_Screen         ; enter in graphic mode
        ;PUBLIC  Quit_ST_Screen          ; quit graphic mode

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Timer

        PUBLIC Init_Video

        extrn low_overscan : dword
        extrn prev_low_overscan : dword
        extrn visible_rasters : dword


        EXTRN __GETDS : near

                DATASEG

        EXTRN   VideoModeReg            : DWORD ; current video mode register
        EXTRN   VideoMode               : DWORD ; current video mode on screen
        EXTRN   nbVideoModeChanges      : DWORD ; nb changes till last time

        EXTRN   IsFastVideo             : DWORD
        EXTRN   nb_joysticks_detected   : DWORD
        extrn toto : dword


MouseIRQ                db      8+4      ; mouse COM IRQ
MouseIRQmsk             db      0
MousePort               dd      03f8h
ModeST                  dd      0       ; ST mode?
MouseX_Raw              dd      0       ; intern Mouse X
MouseY_Raw              dd      0       ; intern Mouse Y
Prev_Serial_Irq_Ofs     dd      0
Prev_Serial_Irq_Seg     dw      0       ; previous Mouse IRQ
Nb_Received             dd      0       ; nb of bytes transmitted on serial
Bytes_Received          db      0,0,0   ; serial buffer

        EXTRN vbemode : dword

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                                                                        ³
;³                                                                  MOUSE ³
;³                                                                        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

; [fold]  [
PROC internal_init_mouse NEAR

        mov     al,4            ;COM1 : irq 4
        mov     edx,3f8h        ;COM1 : port 3f8
        mov     bl,10h          ;COM1 : PIC mask 10h
        cmp     [mousecom],1
        je      @@com1
        mov     al,3            ;COM2 : irq 3
        mov     edx,02f8h       ;COM2 : port 2f8
        mov     bl,08h          ;COM2 : PIC mask 08h
@@com1:
        add     al,8            ;calc vector
        mov     [MouseIrq],al
        mov     [MouseIrqMsk],bl
        mov     [MousePort],edx

        push    es
        cli
        mov     ah,35h
        mov     al,[MouseIRQ]
        int     21h                     ;get previous SERIAL IRQ (8259-4)
        mov     [Prev_Serial_Irq_Seg],es
        mov     [Prev_Serial_Irq_Ofs],ebx

        mov     ah,25h
        mov     al,[MouseIRQ]
        push    ds
        push    cs
        pop     ds
        lea     edx,[Mouse_Handler]
        int     21h                     ;install own serial handler
        pop     ds

        in      al,21h
        jmp short @@a
@@a:    or      al,8
        out     21h,al
        jmp short @@b                 ;Inhibe IRQ 4 (Port serie 1)
@@b:    ;mov     dx,3fbh               ;DLAB=1, divisor latch access
        mov     edx,[MousePort]
        add     edx,3
        mov     al,80h
        out     dx,al
        jmp short @@c
@@c:    ;mov     dx,3f9h              ;DLAB=1,divisor latch high
        mov     edx,[MousePort]
        inc     edx
        xor     al,al
        out     dx,al
        jmp short @@d
@@d:    ;mov     dx,3f8h              ;DLAB=1,divisor latch low
        mov     edx,[MousePort]
        mov     al,60h
        out     dx,al
        jmp short @@e
@@e:    ;mov     dx,03fbh             ;DLAB=0, mode de transfert
        mov     edx,[MousePort]
        add     edx,3
        mov     al,6h
        out     dx,al
        jmp short @@f
@@f:    ;mov     dx,3fch              ;mode de reception
        mov     edx,[MousePort]
        add     edx,4
        mov     al,0bh
        out     dx,al
        jmp short @@g
@@g:    ;mov     dx,3f9h              ;IRQ g‚n‚r‚e => data available
        mov     edx,[MousePort]
        inc     edx
        mov     al,1
        out     dx,al
        jmp short @@h
@@h:    ;mov     dx,3fdh              ;STROBE: lit status
        mov     edx,[MousePort]
        add     dx,5
        in      al,dx
        jmp short @@i
@@i:    ;mov     dx,3f8h              ;STROBE: buffer
        mov     edx,[MousePort]
        in      al,dx

        in      al,21h               ;Autorise IRQ 4
        jmp short @@k
@@k:    ;and    al,0efh
        mov     bl,[MouseIrqMsk]
        not     bl
        and     al,bl
        out    21h,al
        jmp short @@l
@@l:
        sti
        pop     es
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC internal_deinit_mouse NEAR
        in      al,21h
        or      al,[MouseIrqMsk]
        out     21h,al
        mov     ah,25h
        mov     al,[MouseIRQ]
        push    ds
        mov     edx,[Prev_Serial_Irq_Ofs]
        mov     ds,[Prev_Serial_Irq_Seg]
        int     21h
        pop     ds
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Mouse_Handler NEAR
       pushad
       push     ds es

       call     __GETDS

;       mov    dx,3f8h
        mov     edx,[MousePort]
       in     al,dx

       mov    ebx,[Nb_Received]
       test   al,40h                  ;on se synchronise sur la transmission
       je     @@PasPrem
       xor    ebx,ebx
@@PasPrem:
       mov    [ebx+OFFSET Bytes_Received],al
       inc    ebx
       mov    [Nb_Received],ebx
       cmp    ebx,3                    ;Nombre d'octets d‚j… re‡us
       jne    @@Wait_3_Bytes

       mov    dl,[Bytes_Received]
       mov    al,dl
       shr    al,4
       and    eax,3
       mov    [Mouse_Buttons],eax

       mov    al,[Bytes_Received+1]
       and    al,3fh                             ;increm X (bit 5-0)
       mov    dh,dl
       shl    dh,6                               ;increm X (bit 7-6)
       or     al,dh
       and    ax,255
       cmp    ax,128
       jl     @@n1
       sub    ax,256
@@n1:
        movsx   eax,ax
       add    [MouseX_Raw],eax

       mov    al,[Bytes_Received+2]
       and    al,3fh                             ;increm Y (bit 5-0)
       shl    dl,4                               ;increm Y (bit 7-6)
       and    dl,0c0h
       or     al,dl
       and    ax,255
       cmp    ax,128
       jl     @@n2
       sub    ax,256
@@n2:
        movsx   eax,ax
        add    [MouseY_Raw],eax

        mov     eax,[MouseX_Raw]
        mov     [MouseX],eax
        mov     eax,[MouseY_Raw]
        mov     [MouseY],eax

        mov     eax,0b8000h
        add     [dword ptr eax],0101h

        lea     eax,[base_processor]
        or      [eax+base.events_mask],MASK_MOUSE

@@Wait_3_Bytes:
;       cli
       mov    al,20h
       out    20h,al
;       sti

       pop      es ds
       popad
       iretd

       ENDP

; [fold]  ]

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                                                                        ³
;³                                                               JOYSTICK ³
;³                                                                        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

STRUC   TJoy
calib_xmin              dd      ?
calib_xmax              dd      ?
calib_ymin              dd      ?
calib_ymax              dd      ?
lim_xmin                dd      ?
lim_xmax                dd      ?
lim_ymin                dd      ?
lim_ymax                dd      ?
sensitivity_xjoy        dd      ?
sensitivity_yjoy        dd      ?
ENDS

        EXTRN joystick1_vars : Tjoy


; [fold]  [
PROC Init_Joysticks NEAR

        mov     dx,201h
        mov     al,0ffh
        out     dx,al       ;gonna test joysticks
        mov     cx,0ffffh

@@Waitalittle:
        in      al,dx
        test    al,0fh      ;mask %00001111: 2 JOYSTICKS supposed
        loopnz  @@Waitalittle

        xor     edx,edx
        test    al,03h
        jnz     @@j1
        inc     edx
@@j1:
        test    al,0ch
        jnz     @@j2
        inc     edx
@@j2:
        mov     [nb_joysticks_detected],edx
        ret
ENDP

; [fold]  ]

        DATASEG

Is_Joy1 dd      1       ; need to test joy 1 ?
Is_Joy2 dd      0       ; need to test joy 2 ?

Joy1_Button     db      0
Joy1_Left       db      0
Joy1_Right      db      0
Joy1_Up         db      0
Joy1_Down       db      0
Joy2_Button     db      0
Joy2_Left       db      0
Joy2_Right      db      0
Joy2_Up         db      0
Joy2_Down       db      0

Analog1_X       dw      0
Analog1_Y       dw      0

STE_Analog1_X   dw    0
STE_Analog1_Y   dw    0

maxloop         dd      0

        EXTRN PCJoy1_for_ST : DWORD     ; emulation ST joy by PC joy #1

        PUBLIC STE_Analog1_X
        PUBLIC STE_Analog1_Y

        CODESEG



        PUBLIC criticalerror_handler

criticalerror_handler:
        xor     al,al
        iretd


; [fold]  [
PROC Test_PC_Joysticks NEAR

        push    ebp

        xor   ebx,ebx
        cmp   [Is_Joy1],0
        je    @@PasJ1
        or    bl,3
@@PasJ1:
        cmp   [Is_Joy2],0
        je    @@PasJ2
        or    bl,0ch
@@PasJ2:
        or    bl,bl
        je    @@NoJoyz

        xor   bp,bp   ;Joy #1 X = BP
        mov   cx,bp   ;Joy #1 Y = CX
        mov   si,bp   ;Joy #2 X = SI
        mov   di,bp   ;Joy #2 Y = DI

        mov       [maxloop],0a000h

        mov   dx,0201h
        mov   al,0ffh
        out   dx,al
@@loloop:
        in    al,dx
        mov   ah,bl
        and   ah,al
        jz    @@EndTest

        shr   al,1
        adc   bp,0
        shr   al,1
        adc   cx,0
        shr   al,1
        adc   si,0
        shr   al,1
        adc   di,0

        dec     [maxloop]
        jnz     @@loloop
@@EndTest:

        mov     [Analog1_X],bp
        mov     [Analog1_Y],cx

        ;------------------------------------------------- test buttons

        shr     al,5
        setnc   ah
        shr     al,1
        setnc   al
        or      al,ah
        mov     [Joy1_Button],al

        ;------------------------------------------------- calibration

        lea     ebx,[joystick1_vars]
        cmp     bp,[WORD PTR ebx+TJOY.lim_xmin]
        setb    [Joy1_Left]
        cmp     bp,[WORD PTR ebx+TJOY.lim_xmax]
        seta    [Joy1_Right]
        cmp     cx,[WORD PTR ebx+TJOY.lim_ymin]
        setb    [Joy1_Up]
        cmp     cx,[WORD PTR ebx+TJOY.lim_ymax]
        seta    [Joy1_Down]


        mov     al,[Joy1_Button]
        shl     al,4
        or      al,[Joy1_Right]
        shl     al,1
        or      al,[Joy1_Left]
        shl     al,1
        or      al,[Joy1_Down]
        shl     al,1
        or      al,[Joy1_Up]

        and     eax,255
        mov     [PCJoy1_for_ST],eax
;        mov     [ST_Joy1],eax

        movzx   eax,[Analog1_X]
        sub     eax,[ebx+TJOY.calib_xmin]
        xor     edx,edx
        shl     eax,8
        mov     ecx,[ebx+TJOY.calib_xmax]
        sub     ecx,[ebx+TJOY.calib_xmin]
        inc     ecx
        div     ecx
        mov     [STE_Analog1_X],ax

        movzx   eax,[Analog1_Y]
        sub     eax,[ebx+TJOY.calib_ymin]
        xor     edx,edx
        shl     eax,8
        mov     ecx,[ebx+TJOY.calib_ymax]
        sub     ecx,[ebx+TJOY.calib_ymin]
        inc     ecx
        div     ecx
        mov     [STE_Analog1_Y],ax

@@NoJoyz:
        pop     ebp
        ret
;      pop     ebp
      ENDP

; [fold]  ]


        DATASEG


        EXTRN isTrueColor : DWORD
        EXTRN screen_linear : DWORD
        EXTRN   ST_Screen_Ptr   : DWORD ; adress of ST screen

Prev_VideoMode          dd      0

VideoModes_Draw         dd      Draw_Video_LowRes_256Colors
                        dd      Draw_Video_MedRes
                        dd      Draw_Video_HiRes
                        dd      Draw_Video_LowRes_256Colors


        EXTRN VideoEmu_Type : DWORD
        EXTRN vbemode_for_mixed : DWORD
        EXTRN vbemode_for_mixed_y : DWORD

        EXTRN vbemode_for_custom : DWORD
        EXTRN vbemode_for_custom_linewidth : DWORD

        EXTRN ST_Screen_PTR_Current : DWORD

        EXTRN vbemode_linewidth : DWORD
        EXTRN vbemode_x : DWORD
        EXTRN vbemode_y : DWORD
        EXTRN vbemode_bpp: DWORD

        CODESEG

        EXTRN VBE_setmode : NEAR
        EXTRN shifter_modulo : DWORD
;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                                                                        ³
;³                                                                  VIDEO ³
;³                                                                        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

        EXTRN OUTdebug : NEAR

MACRO LOG_VIDEOCHANGE msg_ptr
        IFDEF DEBUG
        push    OFFSET msg_ptr
        call    OUTdebug
        add     esp,4
        ENDIF
ENDM

msg_vbe db      'Switching to a VBE mode',0
msg_13h db      'Switching to 13h',0
msg_0eh db      'Switching to 0eh',0
msg_11h db      'Switching to 11h',0

; [fold]  [
PROC Init_Video NEAR
                        ;------------------- calc Chunkies for plane 1

        xor     ecx,ecx ;byte to calculate chunky with
@@chunk:
        mov     edx,ecx

        rept    4
        shl     eax,8
        shl     dl,1
        setc    al
        endm
        bswap   eax
        mov     [Chunkies+ecx*8],eax
        rept    4
        shl     eax,8
        shl     dl,1
        setc    al
        endm
        bswap   eax
        mov     [Chunkies+ecx*8+4],eax
        inc     cl
        jnz     @@chunk
                        ;------------------- ... for plane 2,3,4

        lea     esi,[Chunkies]
        xor     ecx,ecx
@@allofit:
        mov     eax,[esi+ecx*8]
        mov     edx,[esi+ecx*8+4]
        shl     eax,1
        shl     edx,1
        mov     [esi+ecx*8+8*256],eax
        mov     [esi+ecx*8+8*256+4],edx
        inc     ecx
        cmp     ecx,256*3
        jnz     @@allofit


        call    init_font

        ret
        ENDP

; [fold]  ]

; [fold]  (
PROC Set_PC_Palette NEAR
        push    esi
        lea     esi,[VGA_Palette]

        xor     ecx,ecx                         ; current color
        mov     edx,03c8h                       ; color PORT
@@allof16:
        mov     di,[WORD PTR memio+240h+ecx*2]  ; ST Color RGB
        cmp     [PreviousPalette+ecx*2],di
        jz      @@samecol
        mov     [PreviousPalette+ecx*2],di      ; if Not the same, set PC one
        rol     di,8

        mov     eax,ecx
        out     dx,al
        inc     edx
        mov     eax,edi
        shr     eax,8
        and     eax,7
        shl     eax,3
;        or      al,7
        mov     [esi],al
        out     dx,al
        mov     eax,edi
        shr     eax,4
        and     eax,7
        shl     eax,3
;        or      al,7
        mov     [esi+1],al
        out     dx,al
        mov     eax,edi
        and     eax,7
        shl     eax,3
        ;or      al,7
        mov     [esi+2],al
        out     dx,al
        dec     edx
@@samecol:
        add     esi,3
        inc     ecx
        cmp     ecx,16
        jne     @@allof16
        pop     esi
        ret
        ENDP

; [fold]  )

; [fold]  [
PROC Enter_ST_Screen NEAR       ; Set an ST resolution
        pushad

        mov     eax,[VideoEmu_Type]
        mov     [effective_VideoEmu_Type],eax

        xor     ecx,ecx
@@clr:  mov     [PreviousPalette+ecx*2],055aah
        inc     ecx
        cmp     ecx,16
        jnz     @@clr

        xor     eax,eax
        mov     ebx,eax
@@clr2:
        mov     [DWORD PTR PreviousScreen+eax*4],ebx
        inc     eax
        cmp     eax,8000
        jnz     @@clr2

        xor     eax,eax
        mov     ebx,12341234h
@@pale: mov     [DWORD PTR PreviousPalette+eax*4],ebx
        inc     eax
        cmp     eax,128
        jnz     @@pale

        cmp     [VideoEmu_Type],VIDEOEMU_CUSTOM
        jne     @@nocustom

;---------------------------------------------- CUSTOM VIDEO MODE
        ;mov     ax,12h
        ;int     10h
        ;jmp     End_Enter

        mov     eax,[vbemode_for_custom]
        or      eax,4000h
        push    eax
        call    VBE_setmode
        add     esp,4
        jmp     End_Enter

@@nocustom:
        cmp     [VideoModeReg],2
        je      @@hires

        cmp     [VideoEmu_Type],VIDEOEMU_MIXED
        jnz     @@Not_mixed_mode

;---------------------------------------------- MIXED VIDEO MODE

        LOG_VIDEOCHANGE msg_vbe

        mov     eax,[vbemode_for_mixed]
        or      eax,4000h
        push    eax
        call    VBE_setmode
        add     esp,4
        jmp     End_Enter

@@Not_Mixed_Mode:

        mov     eax,[VideoModeReg]
        mov     [VideoMode],eax
        and     eax,3
        cmp     eax,1
        je      @@medres

        ;---------------------------- low resolution

        cmp     [videoEmu_Type],VIDEOEMU_LINE
        jnz     @@colors256_low

        cmp     [screen_linear],0a0000h
        je      @@colors256_low


@@this_is_a_vbe_mode:
;        cmp     [screen_linear],0
;        jz      @@colors256_low

        LOG_VIDEOCHANGE msg_vbe

        mov     eax,[vbemode]
        or      eax,4000h
        push    eax
        call    VBE_setmode
        add     esp,4

        or      eax,eax
        jnz     @@cont_low
@@colors256_low:

        mov     [vbemode_y],200
        LOG_VIDEOCHANGE msg_13h

        mov     ax,13h
        int     10h
@@cont_low:
        jmp     End_Enter

        ;---------------------------- medium resolution

@@medres:
        mov     [effective_VideoEmu_Type],VIDEOEMU_SCREEN
        LOG_VIDEOCHANGE msg_0eh

        mov     ax,0eh  ;640x200x16
        int     10h
        jmp     End_Enter

        ;---------------------------- hi resolution

@@hires:
        mov     [effective_VideoEmu_Type],VIDEOEMU_SCREEN
        LOG_VIDEOCHANGE msg_11h

        mov     ax,11h
        int     10h
        call    SetMonoPalette

;        mov     dx,03c8h
;        xor     eax,eax
;        out     dx,al
;        inc     dx
;        mov     al,0
;        out     dx,al
;        out     dx,al
;        out     dx,al
;        mov     ecx,1
;@@completementconmaisbon:
;        mov     dx,03c8h
;        mov     eax,ecx
;        out     dx,al
;        inc     dx
;        mov     al,-1
;        out     dx,al
;        out     dx,al
;        out     dx,al
;        inc     cl
;        jnz     @@completementconmaisbon
        mov     edi,0a0000h
@@clrr: mov     [DWORD PTR edi],0
        add     edi,4
        cmp     edi,0a0000h+480*80
        jbe     @@clrr

End_Enter:
        popad
        mov     eax,[VideoModeReg]
        mov     [Prev_VideoMode],eax
        ret
        ENDP

; [fold]  ]

; [fold]  [
Draw_Video_MedRes:
        xor     ecx,ecx         ; current color
        mov     edx,03c8h       ; color PORT
        push    esi
        lea     esi,[VGA_Palette]
@@allof4:
        mov     di,[WORD PTR memio+240h+ecx*2]
        cmp     [PreviousPalette+ecx*2],di
        jz      @@samecol
        mov     [PreviousPalette+ecx*2],di
        rol     di,8


        mov     eax,ecx
        out     dx,al
        inc     edx
        mov     eax,edi
        shr     eax,8
        and     eax,7
        shl     eax,3
        mov     [esi],al
        out     dx,al
        mov     eax,edi
        shr     eax,4
        and     eax,7
        shl     eax,3
        mov     [esi+1],al
        out     dx,al
        mov     eax,edi
        ;shr     eax,8
        and     eax,7
        shl     eax,3
        mov     [esi+2],al
        out     dx,al
        dec     edx

@@samecol:
        add     esi,3
        inc     ecx
        cmp     ecx,4
        jne     @@allof4

        pop     esi

        mov     al,2            ;select map/mask function in GFX Sequencer
        xor     ecx,ecx         ;current plane...
        mov     ah,1            ;current mask for PC plane
@@pl2:
        mov     dx,03c4h
        out     dx,ax
        shl     ah,1

        push    eax
        push    ecx
        push    esi


        and     esi,0fffffeh
        cmp     esi,[ebp+base.RAMSIZE]
        jb      @@no
        xor     esi,esi
@@no:


        add     esi,[memory_ram]
        mov     edi,0a0000h
@@copy:

        mov     ax,[WORD PTR esi+4]
        shl     eax,16
        mov     bx,[WORD PTR esi+12]
        mov     ax,[WORD PTR esi]
        shl     ebx,16
        mov     bx,[WORD PTR esi+8]

        add     esi,16

        mov     [edi],eax
        mov     [edi+4],ebx

        add     edi,8
        cmp     edi,0a0000h+16000
        jb      @@copy

        pop     esi
        pop     ecx
        pop     eax
        add     esi,2           ;other plane in ST memory...
        inc     ecx
        cmp     ecx,2
        jnz     @@pl2
        ret

; [fold]  ]

; [fold]  [
Draw_Video_LowRes_256Colors:
        call    Set_PC_Palette

        and     esi,0fffffeh
        cmp     esi,[ebp+base.RAMSIZE]
        jb      @@no
        xor     esi,esi
@@no:

        push    ebp
        xor     edi,edi
        align   4

@@alllines:
        mov     ecx,20
@@AllWordsslow:
        mov     ebx,[DWORD PTR fs:esi]
        mov     edx,[DWORD PTR fs:esi+4]
        cmp     [edi+PreviousScreen],ebx
        jnz     @@diff
        cmp     [edi+PreviousScreen+4],edx
        jz      @@nextone
@@diff:
        mov     [edi+PreviousScreen],ebx
        mov     [edi+PreviousScreen+4],edx

        xor     eax,eax

        mov     al,[fs:esi]
        mov     ebp,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[fs:esi+2]
        add     ebp,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]
        mov     al,[fs:esi+4]
        add     ebp,[Chunkies+eax*8+2*8*256]
        add     edx,[Chunkies+eax*8+2*8*256+4]
        mov     al,[fs:esi+6]
        add     ebp,[Chunkies+eax*8+3*8*256]
        add     edx,[Chunkies+eax*8+3*8*256+4]
        mov     [edi*2+0a0000h],ebp
        mov     [edi*2+0a0000h+4],edx

        mov     al,[fs:esi+1]
        mov     ebp,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[fs:esi+3]
        add     ebp,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]
        mov     al,[fs:esi+5]
        add     ebp,[Chunkies+eax*8+2*8*256]
        add     edx,[Chunkies+eax*8+2*8*256+4]
        mov     al,[fs:esi+7]
        add     ebp,[Chunkies+eax*8+3*8*256]
        add     edx,[Chunkies+eax*8+3*8*256+4]

        mov     [edi*2+0a0000h+8],ebp
        mov     [edi*2+0a0000h+12],edx

@@nextone:
        add     edi,8
        add     esi,8
        dec     ecx
        jnz     @@allwordsslow

        add     esi,[modulo]
        mov     eax,[shifter_modulo]
        shl     eax,3
        add     esi,eax

        cmp     edi,32000
        jnz     @@Alllines
@@endDraw_Video_LowRes:
        pop     ebp

        ret

; [fold]  ]

; [fold]  [
SetMonoPalette:
        mov     bx,00ffh
        mov     dx,03c8h
        xor     eax,eax
        out     dx,al
        inc     dx
        mov     al,bl
        out     dx,al
        out     dx,al
        out     dx,al
        mov     ecx,1
@@completementconmaisbon:
        mov     dx,03c8h
        mov     eax,ecx
        out     dx,al
        inc     dx
        mov     al,bh
        out     dx,al
        out     dx,al
        out     dx,al
        inc     cl
        jnz     @@completementconmaisbon
        ret

; [fold]  ]

        dataseg

prevpal dw      0

; [fold]  [
Draw_Video_HiRes:

        and     esi,0fffffeh
        cmp     esi,[ebp+base.RAMSIZE]
        jb      @@no
        xor     esi,esi
@@no:

        ;------ test palette



        mov     ax,[word ptr ST_Palette]
        cmp     ax,[prevpal]
        jz      @@sampal
        mov     bx,0ff00h
        or      ax,ax
        jnz     @@okblack
        xchg    bl,bh
@@okblack:
        mov     [prevpal],ax
        call    SetMonoPalette
@@sampal:

        mov     edi,0a0000h+3200
@@copy:
        mov     eax,[DWORD PTR fs:esi]
        mov     ebx,[DWORD PTR fs:esi+4]
;        not     eax
;        not     ebx
        mov     [edi],eax
        mov     [edi+4],ebx
        mov     ecx,[DWORD PTR fs:esi+8]
        mov     edx,[DWORD PTR fs:esi+12]
;        not     ecx
;        not     edx
        add     esi,16
        mov     [edi+8],ecx
        mov     [edi+12],edx
        add     edi,16
        cmp     edi,0a0000h+32000+3200
        jb      @@copy
        ret

; [fold]  ]

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³                                                      Make_Screen_Line0 ³
;ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;³ Init everything at the beginning of each ST FRAME                      ³
;³                                                                        ³
;³  - SET PC Colors for ST Palette                                        ³
;³  - Init Corresponding table for ST->PC Color number                    ³
;³  - Clear PaletteUpdate flags te                                        ³
;³  - Init variables (NextFreeColor,NbFreeClolors,...)                    ³
;³                                                                        ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

        PUBLIC Make_Screen_Line0

Nothingtodo:
        ret

PROC Make_Screen_Line0 NEAR
        pushad

        mov     [PTR_Make_Screen_Line],OFFSET Nothingtodo
        mov     eax,[ST_Screen_Ptr]
        add     eax,[moduloy]
;        mov     [ST_Screen_PTR_Current],eax

;        cmp     eax,[ebp+base.RAMSIZE]
;        ja      @@NoS
        mov     esi,eax

        mov     eax,[VideoModeReg]
        and     eax,3
        test    [already_st_video],1
        jz      @@doit
        cmp     [Prev_VideoMode],eax            ;if new videomode selected,
        jz      @@NoChange
@@doit:
        test    [just_unfreezed],1
        jz      @@notfr
        mov     [just_unfreezed],0
        jmp     @@nod
@@notfr:
        call    Enter_ST_Screen                 ;init this one...
        mov     [already_st_video],1
        mov     eax,[VideoModeReg]
@@NoChange:
        cmp     [effective_VideoEmu_Type],VIDEOEMU_CUSTOM
        jnz     @@nocustom
        call    Build_Screen_Custom_256
        jmp     @@NoS
@@nocustom:
        cmp     [effective_VideoEmu_Type],VIDEOEMU_SCREEN
        jnz     @@lineo

        and     eax,3
        call    [DWORD PTR VideoModes_Draw+eax*4]       ;draw all at once

        ;call    display_infos


        jmp     @@NoS
@@lineo:
;------------------------------------------------------ ST Palette->PC Palette
        mov     [PTR_Make_Screen_Line],OFFSET Get_Line_Parameters
        mov     [Current_ST_Line],OFFSET STLines

        mov     eax,[screen_linear]
        mov     [PC_Screen_PTR_Current],eax

        cmp     [VideoEmu_Type],VIDEOEMU_MIXED
        jnz     @@no_mixed
        call    Build_Screen_256_Mixed
        jmp     @@nod
@@no_mixed:
        ;--------- line oriented

;        mov     eax,[low_overscan]
;        cmp     eax,[prev_low_overscan]
;        je      @@samovr
;        call    Enter_ST_Screen
;@@samovr:
        mov     edx,[visible_rasters]
        cmp     edx,[vbemode_y]
        jb      @@oky
        mov     edx,[vbemode_y]
        cmp     edx,240
        jb      @@oky
        mov     edx,240
@@oky:  or      edx,edx
        je      @@nod
        mov     [lines2go],edx

        cmp     [vbemode_bpp],8
        jnz     @@no256colors
        call    Build_Screen_256_LineOriented
        jmp     @@nod
@@no256colors:
        cmp     [vbemode_bpp],15
        jnz     @@no32768colors
        call    Build_Screen_32768_LineOriented
        jmp     @@nod
@@no32768colors:
        cmp     [vbemode_bpp],16
        jnz     @@no65536colors
        call    Build_Screen_65536_LineOriented
        jmp     @@nod
@@no65536colors:
@@nod:
        mov     [PaletteUpdate],0ffffh            ;all colors are to be new
        mov     [NextFreeColor],0
        mov     [NbFreeColors],256
@@NoS:
        popad
        ret
        ENDP

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;³                                             BUILD LINE-ORIENTED SCREENS
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

        DATASEG


PTR_Make_Screen_Line    dd      0       ; Pointer to make_line function

NextFreeColor           dd      0       ; next free color in 256 ones
NbFreeColors            dd      0       ; number of free colors

ST2PC_Colors            dd      0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9
                        dd      10,10,11,11,12,12,13,13,14,14,15,15

        PUBLIC PreviousPalette

PC_Palette              dw      256 dup (0)
PreviousPalette         dw      256 dup (0)

Effective_videoemu_type dd      0

STRUC STLine
StScreen        dd      0
PaletteUpdate   dd      0
VideoMode       dd      0
Palette         dw      16 dup (0)
ENDS STLine


STLines         STLine  256 dup (<>)
Current_ST_Line dd      0

rebuild_all     dd      0




        EXTRN  PaletteUpdate : DWORD
        EXTRN  ST_Palette : dword

        PUBLIC  PTR_Make_Screen_Line

        CODESEG


; [fold]  [
PROC Get_Line_Parameters NEAR
        push    ebp
        push    esi

        ;cmp     [visible_rasters],240
        ;ja      @@skiperr

        mov     esi,[Current_ST_Line]           ;current line structure pointer
        add     [Current_ST_Line],SIZE STLine   ;next line structure

        mov     eax,[ST_Screen_PTR_current]     ;ST screen pointer
        and     eax,0ffffffh
        cmp     eax,[ebp+base.RAMSIZE]          ;is it in RAM?
        jb      @@okram
        xor     eax,eax
@@okram:mov     [esi+STLine.StScreen],eax      ;save SCREEN PTR

        mov     eax,[VideoModeReg]
        mov     [esi+STLine.VideoMode],eax

        mov     eax,[PaletteUpdate]             ;save palette update
        mov     [esi+STLine.PaletteUpdate],eax
        or      eax,eax                         ;any color changed?
        jz      @@nopal

        mov     ecx,0                           ;16 colors to copy
@@copy16:
        mov     eax,[ST_Palette+ecx*4]
        mov     [DWORD PTR esi+ecx*4+STLine.Palette],eax
        inc     ecx
        cmp     ecx,8
        jnz     @@copy16
@@nopal:
        pop     esi
        pop     ebp
        mov     [PaletteUpdate],0       ;colors changed till next raster line
@@skiperr:
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Build_PC_Palette NEAR
        cmp     [NextFreeColor],0
        jnz     @@doit
        ret
@@doit:
        push    esi
        lea     esi,[VGA_Palette]
        xor     ecx,ecx                         ; current color
        mov     edx,03c8h                       ; color PORT
@@allof16:
        mov     di,[word ptr PC_Palette+ecx*2]  ; ST Color RGB
        cmp     [PreviousPalette+ecx*2],di
        jz      @@samecol
        mov     [PreviousPalette+ecx*2],di      ; if Not the same, set PC one
        rol     di,8

        mov     eax,ecx
        out     dx,al
        inc     edx

        mov     eax,edi
        shr     eax,8
        and     eax,7
        shl     eax,3
        mov     [esi],al
        out     dx,al
        mov     eax,edi
        shr     eax,4
        and     eax,7
        shl     eax,3
        mov     [esi+1],al
        out     dx,al
        mov     eax,edi
        and     eax,7
        shl     eax,3

        mov     [esi+2],al
        out     dx,al
        dec     edx
@@samecol:
        add     esi,3
        inc     ecx
        cmp     ecx,[NextFreeColor]
        jne     @@allof16
        pop     esi
        ret
        ENDP

; [fold]  ]

; [fold]  [
PROC Build_Screen_256_LineOriented NEAR
        push    ebp
        push    esi

        lea     ebp,[STLines]                   ; ST line structure
        mov     edi,[PC_Screen_PTR_Current]     ; PC screen adress
        lea     ebx,[PreviousScreen]            ; Previous screen buffer
        mov     esi,[Lines2Go]                  ; number of lines to build
@@li200:
        push    ebp                             ; keeps EBP (line structure)
        push    esi                             ; keeps ESI (number of lines)
        push    edi                             ; keeps EDI (PC screen buffer)


;-------------- palette update if needed for this RASTERLINE

        mov     [rebuild_all],0                 ; default is no rebuild all

        mov     eax,[ebp+STLine.PaletteUpdate]
        or      eax,eax                         ; any palette update?
        jz      short @@nonewcolors
        cmp     [NbFreeColors],16               ; if no more PC color, do
        jb      short @@nonewcolors             ; nothing to save time

        xor     ecx,ecx                         ; ecx handles ST current color
@@tst16:shr     eax,1                           ; this color modified?
        jnc     short @@notthis                 ; no -> next one

        dec     [NbFreeColors]                  ; use one more color
        mov     edx,[NextFreeColor]             ; edx is next free color
        inc     [NextFreeColor]

        push    eax
        mov     [ST2PC_Colors+ecx*4],edx        ; new PC color for a ST color
        mov     ax,[ebp+ecx*2+STLine.Palette]
        mov     [PC_Palette+edx*2],ax           ; keeps ST palette form
        pop      eax
@@notthis:
        inc     ecx
        cmp     ecx,16
        jnz     short @@tst16

        mov     [rebuild_all],1

@@nonewcolors:

;--------------- delta-planar-to-chunky conversion for this RASTERLINE


        mov     esi,[ebp+STLine.StScreen]
        and     esi,0ffffffh
        add     esi,[memory_ram]

        mov     ecx,20
@@allwords:
        mov     edx,[DWORD PTR esi]
        mov     ebp,[DWORD PTR esi+4]

        cmp     [rebuild_all],1
        je      short @@change

;        cmp     [ebx],ebp
;        jne     short @@change
;        cmp     [ebx+4],edx
;        je      @@sameword

@@change:
        push    ebx
        push    ecx

        xor     ebx,ebx
        xor     eax,eax

        mov     al,[esi]
        mov     ecx,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[esi+2]
        add     ecx,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]
        mov     al,[esi+4]
        add     ecx,[Chunkies+eax*8+2*8*256]
        add     edx,[Chunkies+eax*8+2*8*256+4]
        mov     al,[esi+6]
        add     ecx,[Chunkies+eax*8+3*8*256]
        add     edx,[Chunkies+eax*8+3*8*256+4]

        bswap   ecx
        bswap   edx

        mov     al,cl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,ch
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        shr     ecx,16
        shl     ebx,16
        mov     al,cl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,ch
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     [edi],ebx
        mov     al,dl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,dh
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        shr     edx,16
        shl     ebx,16
        mov     al,dl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,dh
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     [edi+4],ebx

        mov     al,[esi+1]
        mov     ecx,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[esi+3]
        add     ecx,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]
        mov     al,[esi+5]
        add     ecx,[Chunkies+eax*8+2*8*256]
        add     edx,[Chunkies+eax*8+2*8*256+4]
        mov     al,[esi+7]
        add     ecx,[Chunkies+eax*8+3*8*256]
        add     edx,[Chunkies+eax*8+3*8*256+4]

        bswap   ecx
        bswap   edx

        mov     al,cl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,ch
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        shr     ecx,16
        shl     ebx,16
        mov     al,cl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,ch
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     [edi+8],ebx
        mov     al,dl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,dh
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        shr     edx,16
        shl     ebx,16
        mov     al,dl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,dh
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     [edi+12],ebx



@@nextone:
        pop     ecx
        pop     ebx
@@sameword:
        add     esi,8
        add     edi,16
        add     ebx,8
        dec     ecx
        jnz     @@AllWords

        pop     edi
        add     edi,[vbemode_linewidth]
        pop     esi
        pop     ebp
        add     ebp,SIZE STLine
        dec     esi
        jnz     @@li200

        call    Build_PC_Palette

        pop     esi
        pop     ebp
        ret
        ENDP


; [fold]  ]

; [fold]  [
PROC Build_Screen_32768_LineOriented NEAR
        push    ebp
        push    esi

        lea     ebp,[STLines]                   ; ST line structure
        mov     edi,[PC_Screen_PTR_Current]     ; PC screen adress
        lea     ebx,[PreviousScreen]            ; Previous screen buffer
        mov     esi,[Lines2Go]                  ; number of lines to build
@@li200:
        push    ebp                             ; keeps EBP (line structure)
        push    esi                             ; keeps ESI (number of lines)
        push    edi                             ; keeps EDI (PC screen buffer)

;-------------- palette update if needed for this RASTERLINE

        mov     [rebuild_all],0                 ; default is no rebuild all

        mov     eax,[ebp+STLine.PaletteUpdate]
        or      eax,eax                         ; any palette update?
        jz      short @@nonewcolors

        xor     ecx,ecx                         ; ecx handles ST current color
@@tst16:shr     eax,1                           ; this color modified?
        jnc     short @@notthis                 ; no -> next one

        push    eax ebx

        mov     ax,[WORD PTR ebp+ecx*2+STLine.Palette]
        rol     ax,8

        mov     ebx,eax
        mov     edx,eax
        and     eax,0007h       ;R 3 bits 0-2
        and     ebx,0070h       ;G 3 bits 4-6
        and     edx,0700h       ;B 3 bits 8-10

        shl     eax,2          ;B 10-15 (12,13,14)
        shl     ebx,3           ;G 5-9   (7,8,9)
        shl     edx,4           ;R 0-4   (2,3,4)

        or      eax,ebx
        or      eax,edx

        mov     [WORD PTR ST2PC_Colors+ecx*4],ax



;        mov     ax,[ebp+ecx*2+STLine.Palette]
;        mov     [PC_Palette+edx*2],ax           ; keeps ST palette form

        pop     ebx eax
@@notthis:
        inc     ecx
        cmp     ecx,16
        jnz     short @@tst16

        mov     [rebuild_all],1

@@nonewcolors:

;--------------- delta-planar-to-chunky conversion for this RASTERLINE

        mov     esi,[ebp+STLine.StScreen]
        and     esi,0ffffffh
;        add     esi,OFFSET mem

        add     esi,[memory_ram]

        mov     ecx,20
@@allwords:
        mov     edx,[DWORD PTR esi]
        mov     ebp,[DWORD PTR esi+4]

        cmp     [rebuild_all],1
        je      short @@change

        ;cmp     [ebx],ebp
        ;jne     short @@change
        ;cmp     [ebx+4],edx
        ;je      @@sameword
@@change:
        ;---------------------- "optimized" planar to chunky routine (ESI free)
;@@nextone:

        push    ebx
        push    ecx

        xor     ebx,ebx
        xor     eax,eax

        mov     al,[esi]
        mov     ecx,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[esi+2]
        add     ecx,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]
        mov     al,[esi+4]
        add     ecx,[Chunkies+eax*8+2*8*256]
        add     edx,[Chunkies+eax*8+2*8*256+4]
        mov     al,[esi+6]
        add     ecx,[Chunkies+eax*8+3*8*256]
        add     edx,[Chunkies+eax*8+3*8*256+4]

        bswap   ecx
        bswap   edx

        mov     al,cl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,ch
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shr     ecx,16
        mov     [edi+4],ebx
        mov     al,cl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,ch
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        mov     [edi+0],ebx
        mov     al,dl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,dh
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        mov     [edi+12],ebx
        shr     edx,16
        mov     al,dl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,dh
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        mov     [edi+8],ebx

        mov     al,[esi+1]
        mov     ecx,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[esi+3]
        add     ecx,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]
        mov     al,[esi+5]
        add     ecx,[Chunkies+eax*8+2*8*256]
        add     edx,[Chunkies+eax*8+2*8*256+4]
        mov     al,[esi+7]
        add     ecx,[Chunkies+eax*8+3*8*256]
        add     edx,[Chunkies+eax*8+3*8*256+4]

        bswap   ecx
        bswap   edx


        mov     al,cl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,ch
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shr     ecx,16
        mov     [edi+20],ebx
        mov     al,cl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,ch
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        mov     [edi+16],ebx
        mov     al,dl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,dh
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        mov     [edi+28],ebx
        shr     edx,16
        mov     al,dl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,dh
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        mov     [edi+24],ebx

        pop     ecx
        pop     ebx

@@sameword:
        add     esi,8
        add     edi,32
@@nextword:
        add     ebx,8
        dec     ecx
        jnz     @@AllWords

        pop     edi
        add     edi,[vbemode_linewidth]
        pop     esi
        pop     ebp
        add     ebp,SIZE STLine
        dec     esi
        jnz     @@li200

        pop     esi
        pop     ebp
        ret
        ENDP


; [fold]  ]

; [fold]  [
PROC Build_Screen_65536_LineOriented NEAR
        push    ebp
        push    esi

        lea     ebp,[STLines]                   ; ST line structure
        mov     edi,[PC_Screen_PTR_Current]     ; PC screen adress
        lea     ebx,[PreviousScreen]            ; Previous screen buffer
        mov     esi,[Lines2Go]                  ; number of lines to build
@@li200:
        push    ebp                             ; keeps EBP (line structure)
        push    esi                             ; keeps ESI (number of lines)
        push    edi                             ; keeps EDI (PC screen buffer)

;-------------- palette update if needed for this RASTERLINE

        mov     [rebuild_all],0                 ; default is no rebuild all

        mov     eax,[ebp+STLine.PaletteUpdate]
        or      eax,eax                         ; any palette update?
        jz      short @@nonewcolors

        xor     ecx,ecx                         ; ecx handles ST current color
@@tst16:shr     eax,1                           ; this color modified?
        jnc     short @@notthis                 ; no -> next one

        push    eax ebx

        mov     ax,[WORD PTR ebp+ecx*2+STLine.Palette]
        rol     ax,8

        mov     ebx,eax
        mov     edx,eax
        and     eax,0007h       ;R 3 bits 0-2
        and     ebx,0070h       ;G 3 bits 4-6
        and     edx,0700h       ;B 3 bits 8-10

        shl     eax,2          ;B 10-15 (12,13,14)
        shl     ebx,3+1           ;G 5-9   (7,8,9)
        shl     edx,4+1           ;R 0-4   (2,3,4)

        or      eax,ebx
        or      eax,edx

        mov     [WORD PTR ST2PC_Colors+ecx*4],ax


;        mov     ax,[ebp+ecx*2+STLine.Palette]
;        mov     [PC_Palette+edx*2],ax           ; keeps ST palette form

        pop     ebx eax
@@notthis:
        inc     ecx
        cmp     ecx,16
        jnz     short @@tst16

        mov     [rebuild_all],1

@@nonewcolors:

;--------------- delta-planar-to-chunky conversion for this RASTERLINE

        mov     esi,[ebp+STLine.StScreen]
        and     esi,0ffffffh
;        add     esi,OFFSET mem

        add     esi,[memory_ram]

        mov     ecx,20
@@allwords:
        mov     edx,[DWORD PTR esi]
        mov     ebp,[DWORD PTR esi+4]

        cmp     [rebuild_all],1
        je      short @@change

        ;cmp     [ebx],ebp
        ;jne     short @@change
        ;cmp     [ebx+4],edx
        ;je      @@sameword
@@change:

        push    ebx
        push    ecx

        xor     ebx,ebx
        xor     eax,eax

        mov     al,[esi]
        mov     ecx,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[esi+2]
        add     ecx,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]
        mov     al,[esi+4]
        add     ecx,[Chunkies+eax*8+2*8*256]
        add     edx,[Chunkies+eax*8+2*8*256+4]
        mov     al,[esi+6]
        add     ecx,[Chunkies+eax*8+3*8*256]
        add     edx,[Chunkies+eax*8+3*8*256+4]

        bswap   ecx
        bswap   edx

        mov     al,cl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,ch
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shr     ecx,16
        mov     [edi+4],ebx
        mov     al,cl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,ch
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        mov     [edi+0],ebx
        mov     al,dl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,dh
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        mov     [edi+12],ebx
        shr     edx,16
        mov     al,dl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,dh
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        mov     [edi+8],ebx

        mov     al,[esi+1]
        mov     ecx,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[esi+3]
        add     ecx,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]
        mov     al,[esi+5]
        add     ecx,[Chunkies+eax*8+2*8*256]
        add     edx,[Chunkies+eax*8+2*8*256+4]
        mov     al,[esi+7]
        add     ecx,[Chunkies+eax*8+3*8*256]
        add     edx,[Chunkies+eax*8+3*8*256+4]

        bswap   ecx
        bswap   edx


        mov     al,cl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,ch
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shr     ecx,16
        mov     [edi+20],ebx
        mov     al,cl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,ch
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        mov     [edi+16],ebx
        mov     al,dl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,dh
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        mov     [edi+28],ebx
        shr     edx,16
        mov     al,dl
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        shl     ebx,16
        mov     al,dh
        mov     bx,[WORD PTR st2pc_Colors+eax*4]
        mov     [edi+24],ebx

        pop     ecx
        pop     ebx

@@sameword:
        add     esi,8
        add     edi,32
@@nextword:
        add     ebx,8
        dec     ecx
        jnz     @@AllWords

        pop     edi
        add     edi,[vbemode_linewidth]
        pop     esi
        pop     ebp
        add     ebp,SIZE STLine
        dec     esi
        jnz     @@li200

        pop     esi
        pop     ebp
        ret
        ENDP


; [fold]  ]


; [fold]  [
PROC Build_Screen_256_Mixed NEAR
        push    ebp
        push    esi

        lea     ebp,[STLines]                   ; ST line structure
        mov     edi,[PC_Screen_PTR_Current]     ; PC screen adress
        mov     esi,200                         ; number of lines to build
@@li200:
        push    ebp                             ; keeps EBP (line structure)
        push    esi                             ; keeps ESI (number of lines)
        push    edi                             ; keeps EDI (PC screen buffer)


;-------------- palette update if needed for this RASTERLINE

        mov     [rebuild_all],0                 ; default is no rebuild all

        mov     eax,[ebp+STLine.PaletteUpdate]
        or      eax,eax                         ; any palette update?
        jz      short @@nonewcolors
        cmp     [NbFreeColors],16               ; if no more PC color, do
        jb      short @@nonewcolors             ; nothing to save time

        xor     ecx,ecx                         ; ecx handles ST current color
@@tst16:shr     eax,1                           ; this color modified?
        jnc     short @@notthis                 ; no -> next one

        dec     [NbFreeColors]                  ; use one more color
        mov     edx,[NextFreeColor]             ; edx is next free color
        inc     [NextFreeColor]

        push    eax
        mov     [ST2PC_Colors+ecx*4],edx        ; new PC color for a ST color
        mov     ax,[ebp+ecx*2+STLine.Palette]
        mov     [PC_Palette+edx*2],ax           ; keeps ST palette form
        pop      eax
@@notthis:
        inc     ecx
        cmp     ecx,16
        jnz     short @@tst16

@@nonewcolors:

;--------------- delta-planar-to-chunky conversion for this RASTERLINE

        mov     esi,[ebp+STLine.StScreen]
        and     esi,0ffffffh
        add     esi,[memory_ram]

        mov     eax,[ebp+STLine.VideoMode]

        push    ebp
        mov     ebp,[vbemode_linewidth]

;-------------------------------------------------- low resolution

        or      eax,eax
        jnz     @@medrez

        mov     ecx,20
@@allwords_low:
        push    ecx
        xor     ebx,ebx
        xor     eax,eax
        mov     al,[esi]
        mov     ecx,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[esi+2]
        add     ecx,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]
        mov     al,[esi+4]
        add     ecx,[Chunkies+eax*8+2*8*256]
        add     edx,[Chunkies+eax*8+2*8*256+4]
        mov     al,[esi+6]
        add     ecx,[Chunkies+eax*8+3*8*256]
        add     edx,[Chunkies+eax*8+3*8*256+4]
        bswap   ecx
        bswap   edx
        mov     al,cl
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        shl     ebx,16
        mov     al,ch
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        mov     [edi+4],ebx
        mov     [edi+ebp+4],ebx
        shr     ecx,16
        mov     al,cl
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        shl     ebx,16
        mov     al,ch
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        mov     [edi],ebx
        mov     [edi+ebp],ebx
        mov     al,dl
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        shl     ebx,16
        mov     al,dh
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        mov     [edi+12],ebx
        mov     [edi+ebp+12],ebx
        shr     edx,16
        mov     al,dl
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        shl     ebx,16
        mov     al,dh
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        mov     [edi+8],ebx
        mov     [edi+ebp+8],ebx
        mov     al,[esi+1]
        mov     ecx,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[esi+3]
        add     ecx,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]
        mov     al,[esi+5]
        add     ecx,[Chunkies+eax*8+2*8*256]
        add     edx,[Chunkies+eax*8+2*8*256+4]
        mov     al,[esi+7]
        add     ecx,[Chunkies+eax*8+3*8*256]
        add     edx,[Chunkies+eax*8+3*8*256+4]
        bswap   ecx
        bswap   edx
        mov     al,cl
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        shl     ebx,16
        mov     al,ch
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        mov     [edi+20],ebx
        mov     [edi+ebp+20],ebx
        shr     ecx,16
        mov     al,cl
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        shl     ebx,16
        mov     al,ch
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        mov     [edi+16],ebx
        mov     [edi+ebp+16],ebx
        mov     al,dl
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        shl     ebx,16
        mov     al,dh
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        mov     [edi+28],ebx
        mov     [edi+ebp+28],ebx
        shr     edx,16
        mov     al,dl
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        shl     ebx,16
        mov     al,dh
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     bh,bl
        mov     [edi+24],ebx
        mov     [edi+ebp+24],ebx

        pop     ecx
        add     esi,8
        add     edi,32
        dec     ecx
        jnz     @@AllWords_low
        jmp     @@continue

;-------------------------------------------------- med resolution
@@medrez:
        mov     ecx,40
@@allwords_med:
        push    ecx
        xor     ebx,ebx
        xor     eax,eax

        mov     al,[esi]
        mov     ecx,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[esi+2]
        add     ecx,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]

        bswap   ecx
        bswap   edx

        mov     al,cl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,ch
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        shr     ecx,16
        shl     ebx,16
        mov     al,cl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,ch
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     [edi],ebx
        mov     [edi+ebp],ebx
        mov     al,dl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,dh
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        shr     edx,16
        shl     ebx,16
        mov     al,dl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,dh
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     [edi+4],ebx
        mov     [edi+ebp+4],ebx

        mov     al,[esi+1]
        mov     ecx,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[esi+3]
        add     ecx,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]

        bswap   ecx
        bswap   edx

        mov     al,cl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,ch
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        shr     ecx,16
        shl     ebx,16
        mov     al,cl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,ch
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     [edi+8],ebx
        mov     [edi+ebp+8],ebx
        mov     al,dl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,dh
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        shr     edx,16
        shl     ebx,16
        mov     al,dl
        mov     bh,[BYTE PTR st2pc_Colors+eax*4]
        mov     al,dh
        mov     bl,[BYTE PTR st2pc_Colors+eax*4]
        mov     [edi+12],ebx
        mov     [edi+ebp+12],ebx

        pop     ecx
        add     esi,4
        add     edi,16
        dec     ecx
        jnz     @@AllWords_med

@@continue:
        pop     ebp
        pop     edi
        add     edi,[vbemode_linewidth]
        add     edi,[vbemode_linewidth]
        pop     esi
        pop     ebp
        add     ebp,SIZE STLine
        dec     esi
        jnz     @@li200

        call    Build_PC_Palette

        pop     esi
        pop     ebp
        ret
        ENDP


; [fold]  ]




; [fold]  [
Build_Screen_Custom_16:
        call    Set_Pc_Palette



        mov     eax,esi
        add     eax,640*480/2
        cmp     eax,[ebp+base.ramsize]
        ja      @@nothin


        mov     al,2            ;select map/mask function in GFX Sequencer
        xor     ecx,ecx         ;current plane...
        mov     ah,1            ;current mask for PC plane
@@pl2:
        mov     dx,03c4h
        out     dx,ax
        shl     ah,1

        push    eax
        push    ecx
        push    esi

        ;add     esi,OFFSET mem

        add     esi,[memory_ram]
        mov     edi,0a0000h
@@copy:

        mov     ax,[WORD PTR esi+8]
        shl     eax,16
        mov     bx,[WORD PTR esi+24]
        mov     ax,[WORD PTR esi]
        shl     ebx,16
        mov     bx,[WORD PTR esi+16]

        add     esi,32

        mov     [edi],eax
        mov     [edi+4],ebx

        add     edi,8
        cmp     edi,0a0000h+38400
        jb      @@copy

        pop     esi
        pop     ecx
        pop     eax
        add     esi,2          ;other plane in ST memory...
        inc     ecx
        cmp     ecx,4
        jnz     @@pl2
@@nothin:
        ret

; [fold]  ]

PROC Build_Screen_Custom_256 NEAR
        call    Set_PC_Palette

        push    ebp

        mov     eax,[ebp+base.ramsize]
        sub     eax,320
        mov     [max_ram],eax
        align   4
        mov     edi,[screen_linear]
        lea     ebx,[PreviousScreen]
        mov     ecx,480
@@alllines:
        push    ecx
        push    edi
        mov     ecx,40
@@Width:
        xor     eax,eax

        mov     al,[fs:esi]
        mov     ebp,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[fs:esi+2]
        add     ebp,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]
        mov     al,[fs:esi+4]
        add     ebp,[Chunkies+eax*8+2*8*256]
        add     edx,[Chunkies+eax*8+2*8*256+4]
        mov     al,[fs:esi+6]
        add     ebp,[Chunkies+eax*8+3*8*256]
        add     edx,[Chunkies+eax*8+3*8*256+4]
        mov     [edi],ebp
        mov     [edi+4],edx

        mov     al,[fs:esi+1]
        mov     ebp,[Chunkies+eax*8+0*8*256]
        mov     edx,[Chunkies+eax*8+0*8*256+4]
        mov     al,[fs:esi+3]
        add     ebp,[Chunkies+eax*8+1*8*256]
        add     edx,[Chunkies+eax*8+1*8*256+4]
        mov     al,[fs:esi+5]
        add     ebp,[Chunkies+eax*8+2*8*256]
        add     edx,[Chunkies+eax*8+2*8*256+4]
        mov     al,[fs:esi+7]
        add     ebp,[Chunkies+eax*8+3*8*256]
        add     edx,[Chunkies+eax*8+3*8*256+4]

        mov     [edi+8],ebp
        mov     [edi+12],edx
@@nextone:
        add     edi,16
        add     esi,8
;        add     ebx,8
        dec     ecx
        jnz     @@width
        pop     edi
        pop     ecx
        cmp     esi,[max_ram]
        ja      @@enddraw_video_custom
        add     edi,[vbemode_for_custom_linewidth]
        dec     ecx
        jnz     @@Alllines
@@endDraw_Video_custom:
        pop     ebp

        ret
        ENDP

        DATASEG


        public pc_screen_ptr_current
        extrn just_unfreezed : DWORD
        public video_unfreeze

video_unfreeze:
        mov     [PTR_Make_Screen_Line],OFFSET Nothingtodo
        ret


        align 4

PC_Screen_PTR_Current           dd      0       ; Current PC Screen address
lines2go                        dd      0       ;nombre de lignes a afficher

max_ram dd      0
Chunkies        dd      4*8*256 dup (?)


truecolor:        dw      0000h,0111h
        dw      0222h,0333h
        dw      0444h,0555h
        dw      0555h,0666h
        dw      0777h,0888h
        dw      0999h,0aaah
        dw      0bbbh,0ccch
        dw      0dddh,0eeeh
        dw      0fffh,-1

                UDATASEG

        PUBLIC VGA_Palette

PreviousScreen          dd      40*256 dup (?)
VGa_Palette             db      256*3 dup (?)

                CODESEG

PROC Display_infos NEAR
        push    esi ebp
        mov     esi,[Screen_Linear]
        add     esi,320*16
        mov     ebx,[pacifist_release]
        call    display_string


        mov     esi,[Screen_Linear]
        add     esi,320*23
        lea     ebx,[copyright]
        call    display_string

        pop     ebp esi
        ret
        ENDP


display_string:
        mov     dx,0000fh
        xchg    dl,dh
@@allc:
        movzx   edi,[BYTE PTR ebx]
        or      edi,edi
        jz      @@finito

        sub     edi,32
        shl     edi,4

        push    esi
        mov     ebp,7
@@li6:

        mov     al,[edi+font]
        mov     ah,[edi+font+1]
        shl     al,3
        shl     ah,1

;        add     ah,ah
;        jnc     @@m6
;        mov     [BYTE PTR esi],dl
;@@m6:
;        add     ah,ah
;        jnc     @@m5
;        mov     [BYTE PTR esi+1],dl
;@@m5:
;        add     ah,ah
;        jnc     @@m4
;        mov     [BYTE PTR esi+2],dl
;@@m4:
;        add     ah,ah
;        jnc     @@m3
;        mov     [BYTE PTR esi+3],dl
;@@m3:
;        add     ah,ah
;        jnc     @@m2
;        mov     [BYTE PTR esi+4],dl
;@@m2:
;        add     ah,ah
;        jnc     @@m1
;        mov     [BYTE PTR esi+5],dl
;@@m1:
;        add     ah,ah
;        jnc     @@m0
;        mov     [BYTE PTR esi+6],dl
;@@m0:
        add     al,al
        jnc     @@n6
        mov     [BYTE PTR esi+1],dh
@@n6:
        add     al,al
        jnc     @@n5
        mov     [BYTE PTR esi+2],dh
@@n5:
        add     al,al
        jnc     @@n4
        mov     [BYTE PTR esi+3],dh
@@n4:
        add     al,al
        jnc     @@n3
        mov     [BYTE PTR esi+4],dh
@@n3:
        add     al,al
        jnc     @@n2
        mov     [BYTE PTR esi+5],dh
@@n2:
        add     edi,2
        add     esi,320
        dec     ebp
        jnz     @@li6
        pop     esi

        movzx   eax,[BYTE PTR edi + font]
        add     esi,eax
        add     esi,3

        inc     ebx
        jmp     @@allc
@@finito:
        ret

init_font:
        lea     esi,[font_base]
        lea     edi,[font]
        mov     ch,96
@@allchars:
        mov     bl,[esi]
        mov     bh,[esi+1]
        mov     dl,[esi+2]
        mov     dh,[esi+3]
        mov     cl,[esi+4]
        mov     al,[esi+5]


        mov     [byte ptr edi+00],0
        mov     [byte ptr edi+02],bl
        mov     [byte ptr edi+04],bh
        mov     [byte ptr edi+06],dl
        mov     [byte ptr edi+08],dh
        mov     [byte ptr edi+10],cl
        mov     [byte ptr edi+12],0
        mov     [byte ptr edi+14],al

        mov     [byte ptr edi+03],bl
        mov     [byte ptr edi+05],bh
        mov     [byte ptr edi+07],dl
        mov     [byte ptr edi+09],dh
        mov     [byte ptr edi+11],cl

        shl     bx,1
        shl     dx,1
        shl     cl,1

        mov     [byte ptr edi+01],bl
        or      [byte ptr edi+03],bl
        or      [byte ptr edi+05],bh
        or      [byte ptr edi+07],dl
        or      [byte ptr edi+09],dh
        or      [byte ptr edi+11],cl
        mov     [byte ptr edi+13],cl

        or      [byte ptr edi+05],bl
        or      [byte ptr edi+03],bh
        or      [byte ptr edi+07],bh
        or      [byte ptr edi+05],dl
        or      [byte ptr edi+09],dl
        or      [byte ptr edi+07],dh
        or      [byte ptr edi+11],dh
        or      [byte ptr edi+09],cl

        shl     bx,1
        shl     dx,1
        shl     cl,1

        or      [byte ptr edi+03],bl
        or      [byte ptr edi+05],bh
        or      [byte ptr edi+07],dl
        or      [byte ptr edi+09],dh
        or      [byte ptr edi+11],cl

        add     esi,6
        add     edi,16
        dec     ch
        jnz     @@allchars
        ret

        DATASEG


;copyright       db      '(c) 1996-98 F.Gidouin',0
copyright       db      '198%',0
        EXTRN pacifist_release : DWORD ; "PaCiFiST/DOS v0.49" ;

text_text:
;        db      '!"#$%&''()*+,-./'
;        db      '0123456789:;<=>?'
;       db      '@ABCDEFGHIJKLMNO'
        db      'PQRSTUVWXYZ[\]^_'
        db      '`abcdefghijklmno'
        db      'pqrstuvwxyz{|}',0


LABEL font BYTE ; 2*8 octets par char
        db      96*16 dup (0)

LABEL font_base BYTE    ;-------- 96 CHARS



; 0x20 espace
        db      00000b
        db      00000b
        db      00000b
        db      00000b
        db      00000b
        db      4

; 0x21 !
        db      10000b
        db      10000b
        db      10000b
        db      00000b
        db      10000b
        db      2


; 0x22 "
        db      10100b
        db      10100b
        db      00000b
        db      00000b
        db      00000b
        db      3

; 0x23 #
        db      01010b
        db      11111b
        db      01010b
        db      11111b
        db      01010b
        db      5

; 0x24 $
        db      01111b
        db      10100b
        db      01110b
        db      00101b
        db      01110b
        db      5

; 0x25 %
        db      01001b
        db      00010b
        db      00100b
        db      01000b
        db      10010b
        db      5

; 0x26 &
        db      11110b
        db      10100b
        db      01101b
        db      10010b
        db      01101b
        db      5
; 0x27 '
        db      01000b
        db      10000b
        db      00000b
        db      00000b
        db      00000b
        db      2
; 0x28 (
        db      00100b
        db      01000b
        db      01000b
        db      01000b
        db      00100b
        db      4
; 0x29 )
        db      01000b
        db      00100b
        db      00100b
        db      00100b
        db      01000b
        db      4
; 0x2a *
        db      00000b
        db      10100b
        db      01000b
        db      10100b
        db      00000b
        db      3
; 0x2b +
        db      00000b
        db      01000b
        db      11100b
        db      01000b
        db      00000b
        db      3
; 0x2c ,
        db      00000b
        db      00000b
        db      00000b
        db      01000b
        db      10000b
        db      2
; 0x2d -
        db      00000b
        db      00000b
        db      11100b
        db      00000b
        db      00000b
        db      3
; 0x2e .
        db      00000b
        db      00000b
        db      00000b
        db      00000b
        db      10000b
        db      2
; 0x2f
        db      00001b
        db      00010b
        db      00100b
        db      01000b
        db      10000b
        db      5
; 0x30
        db      01100b
        db      10110b
        db      10010b
        db      11010b
        db      01100b
        db      4
; 0x31
        db      01000b
        db      11000b
        db      01000b
        db      01000b
        db      01000b
        db      2
; 0x32
        db      01100b
        db      10010b
        db      00010b
        db      00100b
        db      01110b
        db      4

; 0x33
        db      11100b
        db      00010b
        db      01100b
        db      00010b
        db      11100b
        db      4
; 0x34
        db      10000b
        db      10100b
        db      11110b
        db      00100b
        db      00100b
        db      4
; 0x35
        db      11110b
        db      10000b
        db      11100b
        db      00010b
        db      11100b
        db      4
; 0x36
        db      00110b
        db      01000b
        db      10110b
        db      10010b
        db      01100b
        db      4
; 0x37
        db      11110b
        db      10010b
        db      00100b
        db      00100b
        db      00100b
        db      4
; 0x38
        db      01100b
        db      10010b
        db      01100b
        db      10010b
        db      01100b
        db      4
; 0x39
        db      01100b
        db      10010b
        db      01110b
        db      00010b
        db      01100b
        db      4
; 0x3a :
        db      00000b
        db      10000b
        db      00000b
        db      10000b
        db      00000b
        db      2
; 0x3b ;
        db      00000b
        db      01000b
        db      00000b
        db      01000b
        db      10000b
        db      2
; 0x3c <
        db      00100b
        db      01000b
        db      10000b
        db      01000b
        db      00100b
        db      3
; 0x3d =
        db      00000b
        db      11110b
        db      00000b
        db      11110b
        db      00000b
        db      4
; 0x3e >
        db      10000b
        db      01000b
        db      00100b
        db      01000b
        db      10000b
        db      3
; 0x3f ?
        db      01100b
        db      10010b
        db      00100b
        db      00000b
        db      00100b
        db      4

; 0x40 @
        db      01111b
        db      10011b
        db      10111b
        db      10000b
        db      01110b
        db      5
; 0x41 A
        db      01110b
        db      10001b
        db      10001b
        db      11111b
        db      10001b
        db      5
; 0x42 B
        db      11110b
        db      10001b
        db      11110b
        db      10001b
        db      11110b
        db      5
; 0x43 C
        db      01110b
        db      10000b
        db      10000b
        db      10000b
        db      01110b
        db      4
; 0x44 D
        db      11110b
        db      01001b
        db      01001b
        db      01001b
        db      11110b
        db      5
; 0x45 E
        db      11111b
        db      10000b
        db      11100b
        db      10000b
        db      11111b
        db      5
; 0x46 F
        db      11110b
        db      10000b
        db      11100b
        db      10000b
        db      10000b
        db      4
; 0x47 G
        db      01110b
        db      10000b
        db      10111b
        db      10011b
        db      01101b
        db      5
; 0x48 H
        db      10010b
        db      10010b
        db      11110b
        db      10010b
        db      10010b
        db      4
; 0x49 I
        db      11100b
        db      01000b
        db      01000b
        db      01000b
        db      11100b
        db      3
; 0x4A J
        db      11110b
        db      00100b
        db      00100b
        db      00100b
        db      11000b
        db      4
; 0x4B K
        db      10010b
        db      10100b
        db      11100b
        db      10010b
        db      10010b
        db      4
; 0x4C L
        db      10000b
        db      10000b
        db      10000b
        db      10000b
        db      11110b
        db      4

; 0x4D M
        db      11011b
        db      10101b
        db      10001b
        db      10001b
        db      10001b
        db      5
; 0x4E N
        db      10001b
        db      11001b
        db      10101b
        db      10011b
        db      10001b
        db      5
; 0x4F O
        db      01100b
        db      10010b
        db      10010b
        db      10010b
        db      01100b
        db      4
; 0x50 P
        db      11110b
        db      10001b
        db      10001b
        db      11110b
        db      10000b
        db      5
; 0x51 Q
        db      01110b
        db      10001b
        db      10101b
        db      10011b
        db      01111b
        db      5
; 0x52 R
        db      11110b
        db      10001b
        db      11110b
        db      10010b
        db      10001b
        db      5
; 0x53 S
        db      01111b
        db      10000b
        db      01110b
        db      00001b
        db      11110b
        db      5
; 0x54 T
        db      11111b
        db      00100b
        db      00100b
        db      00100b
        db      00100b
        db      5
; 0x55 U
        db      10001b
        db      10001b
        db      10001b
        db      10001b
        db      01110b
        db      5
; 0x56 V
        db      10001b
        db      10001b
        db      10001b
        db      01010b
        db      00100b
        db      5
; 0x57 W
        db      10001b
        db      10001b
        db      10001b
        db      10101b
        db      01010b
        db      5
; 0x58 X
        db      10001b
        db      01010b
        db      00100b
        db      01010b
        db      10001b
        db      5
; 0x59 Y
        db      10001b
        db      10001b
        db      01110b
        db      00100b
        db      00100b
        db      5

; 0x5a Z
        db      11111b
        db      00010b
        db      00100b
        db      01000b
        db      11111b
        db      5
; 0x5b [
        db      11100b
        db      10000b
        db      10000b
        db      10000b
        db      11100b
        db      3
; 0x5c \
        db      10000b
        db      01000b
        db      00100b
        db      00010b
        db      00001b
        db      5
; 0x5d
        db      11100b
        db      00100b
        db      00100b
        db      00100b
        db      11100b
        db      3
; 0x5e ^
        db      01000b
        db      10100b
        db      00000b
        db      00000b
        db      00000b
        db      3
; 0x5f _
        db      00000b
        db      00000b
        db      00000b
        db      00000b
        db      11111b
        db      4


; 0x50 `
        db      10000b
        db      01000b
        db      00000b
        db      00000b
        db      00000b
        db      2
; 0x51 a
        db      00000b
        db      01100b
        db      10010b
        db      11110b
        db      10010b
        db      4
; 0x52 b
        db      00000b
        db      10000b
        db      11000b
        db      10100b
        db      11100b
        db      3
; 0x53 c
        db      00000b
        db      01000b
        db      10000b
        db      10000b
        db      01100b
        db      3
; 0x54 d
        db      00000b
        db      00100b
        db      11100b
        db      10100b
        db      01100b
        db      3
; 0x55 e
        db      01000b
        db      10100b
        db      11000b
        db      10000b
        db      01100b
        db      3
; 0x56 f
        db      00000b
        db      01100b
        db      10000b
        db      11000b
        db      10000b
        db      3
; 0x57 g
        db      01000b
        db      10100b
        db      01000b
        db      00100b
        db      01100b
        db      3
; 0x58 h
        db      10000b
        db      10000b
        db      11000b
        db      10100b
        db      10100b
        db      3
; 0x59 i
        db      00000b
        db      10000b
        db      00000b
        db      10000b
        db      10000b
        db      1

; 0x5a j
        db      00100b
        db      00000b
        db      00100b
        db      10100b
        db      01100b
        db      3
; 0x5b k
        db      00000b
        db      10100b
        db      11000b
        db      11000b
        db      10100b
        db      3
; 0x5c l
        db      00000b
        db      10000b
        db      10000b
        db      10000b
        db      11000b
        db      2
; 0x5d m
        db      00000b
        db      00000b
        db      11011b
        db      10101b
        db      10001b
        db      5
; 0x5e n
        db      00000b
        db      01100b
        db      10010b
        db      10010b
        db      10010b
        db      4
; 0x5f o
        db      00000b
        db      01100b
        db      10010b
        db      10010b
        db      01100b
        db      4

; 0x60 p
        db      00000b
        db      11100b
        db      10100b
        db      11000b
        db      10000b
        db      3
; 0x61 q
        db      00000b
        db      11100b
        db      10100b
        db      01100b
        db      00100b
        db      3
; 0x62 r
        db      00000b
        db      01000b
        db      10100b
        db      10000b
        db      10000b
        db      3
; 0x63 s
        db      00000b
        db      01110b
        db      11000b
        db      00100b
        db      11110b
        db      4
; 0x64 t
        db      01000b
        db      11100b
        db      01000b
        db      01000b
        db      00100b
        db      5
; 0x65 u
        db      00000b
        db      10100b
        db      10100b
        db      10100b
        db      01010b
        db      4
; 0x66 v
        db      00000b
        db      10001b
        db      10001b
        db      01010b
        db      00100b
        db      5
; 0x67 w
        db      00000b
        db      00000b
        db      10001b
        db      10101b
        db      01010b
        db      5
; 0x68 x
        db      00000b
        db      00000b
        db      10100b
        db      01000b
        db      10100b
        db      3
; 0x69 y
        db      00000b
        db      10100b
        db      11100b
        db      00100b
        db      11000b
        db      3

; 0x6a z
        db      00000b
        db      11100b
        db      00100b
        db      01000b
        db      11100b
        db      3
; 0x6b {
        db      01100b
        db      01000b
        db      10000b
        db      01000b
        db      01100b
        db      3
; 0x6c |
        db      01000b
        db      01000b
        db      01000b
        db      01000b
        db      01000b
        db      3
; 0x6d }
        db      11000b
        db      01000b
        db      00100b
        db      01000b
        db      11000b
        db      3
; 0x6e ~ libre
        db      00000b
        db      00000b
        db      00000b
        db      00000b
        db      00000b
        db      0
; 0x5f libre
        db      00000b
        db      00000b
        db      00000b
        db      00000b
        db      00000b
        db      0


        END

; [fold]  19
