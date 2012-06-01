COMMENT ~

ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ Emulation of ST Hardware                                                 ³
³                                                                          ³
³       25/ 6/96  Converted all code to TASM IDEAL mode                    ³
³       05/ 8/96  New ROM access routines                                  ³
³       12/ 8/96  New chips read/write                                     ³
³       29/ 9/96  Started little MFP Timer A support                       ³
³       30/ 9/96  Fake video adress count                                  ³
³       20/12/96  mirrored AY registers                                    ³
³       27/12/96  output to // Port OK, as well as printer detection       ³
³       30/12/96  started direct FDC emulation                             ³
³       03/01/97  avoid returning cartridge memory if not from ROM         ³
³       18/01/97  Bus Error when reading/writting wrong RAM addresses      ³
³        5/02/97  Added Timer B delay mode                                 ³
³        6/03/97  Started a 100% ASM Blitter emulation                     ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
~
        IDEAL
        FromHard EQU 1                          ; supress EXTRN warnings

        include "simu68.inc"
        include "chips.inc"

        CODESEG

        PUBLIC Init_Chips

        PUBLIC Read_B_Hard
        PUBLIC Read_W_Hard
        PUBLIC Read_L_Hard
        PUBLIC Write_B_Hard
        PUBLIC Write_W_Hard
        PUBLIC Write_L_Hard

        DATASEG


        EXTRN IsMonochrome      : DWORD
        EXTRN IsParallel        : DWORD
        EXTRN VideoMode         : DWORD
        EXTRN PC_Base           : DWORD


        ;PUBLIC Return_After_HARD


;Return_After_HARD       dd      0
negTOSBASE              dd      0
Memory_Chunks_Read_B    dd      256 dup (Read_B_Undefined)
Memory_Chunks_Read_W    dd      256 dup (Read_W_Undefined)
Memory_Chunks_Read_L    dd      256 dup (Read_L_Undefined)
Memory_Chunks_Write_B   dd      256 dup (Write_B_Undefined)
Memory_Chunks_Write_W   dd      256 dup (Write_W_Undefined)
Memory_Chunks_Write_L   dd      256 dup (Write_L_Undefined)



Size_Access     dd      0       ;1, 2 or 4 on write (for FDC)

        CODESEG

PROC Init_Chips NEAR

        lea     esi,[Memory_Chunks_Read_B]
        mov     eax,[ebp+base.RamSize]
        shr     eax,16
        xor     ecx,ecx
@@copy:
        mov     [Memory_Chunks_Read_B+ecx*4],OFFSET Read_B_Ram
        mov     [Memory_Chunks_Read_W+ecx*4],OFFSET Read_W_Ram
        mov     [Memory_Chunks_Read_L+ecx*4],OFFSET Read_L_Ram
        mov     [Memory_Chunks_Write_B+ecx*4],OFFSET Write_B_Ram
        mov     [Memory_Chunks_Write_W+ecx*4],OFFSET Write_W_Ram
        mov     [Memory_Chunks_Write_L+ecx*4],OFFSET Write_L_Ram
        inc     ecx
        cmp     ecx,eax
        jne      @@copy

        mov     edx,[TOSBASE]
        neg     edx
        mov     [negTOSBASE],edx
        neg     edx

        mov     [Memory_Chunks_Read_B+0fah*4],OFFSET Read_B_Expansion
        mov     [Memory_Chunks_Read_W+0fah*4],OFFSET Read_W_Expansion
        mov     [Memory_Chunks_Read_L+0fah*4],OFFSET Read_L_Expansion
        mov     [Memory_Chunks_Read_B+0fbh*4],OFFSET Read_B_Expansion
        mov     [Memory_Chunks_Read_W+0fbh*4],OFFSET Read_W_Expansion
        mov     [Memory_Chunks_Read_L+0fbh*4],OFFSET Read_L_Expansion
        mov     [Memory_Chunks_Write_B+0fah*4],OFFSET Write_B_Expansion
        mov     [Memory_Chunks_Write_W+0fah*4],OFFSET Write_W_Expansion
        mov     [Memory_Chunks_Write_L+0fah*4],OFFSET Write_L_Expansion
        mov     [Memory_Chunks_Write_B+0fbh*4],OFFSET Write_B_Expansion
        mov     [Memory_Chunks_Write_W+0fbh*4],OFFSET Write_W_Expansion
        mov     [Memory_Chunks_Write_L+0fbh*4],OFFSET Write_L_Expansion

        mov     edi,edx         ;baseadr of TOS
        shr     edi,16
        and     edi,0ffh

        lea     eax,[Read_B_Rom]
        lea     ebx,[Read_W_Rom]
        lea     ecx,[Read_L_Rom]

        mov     [Memory_Chunks_Read_B+edi*4+0],eax
        mov     [Memory_Chunks_Read_B+edi*4+4],eax
        mov     [Memory_Chunks_Read_B+edi*4+8],eax
        mov     [Memory_Chunks_Read_B+edi*4+12],eax

        mov     [Memory_Chunks_Read_W+edi*4+0],ebx
        mov     [Memory_Chunks_Read_W+edi*4+4],ebx
        mov     [Memory_Chunks_Read_W+edi*4+8],ebx
        mov     [Memory_Chunks_Read_W+edi*4+12],ebx

        mov     [Memory_Chunks_Read_L+edi*4+0],ecx
        mov     [Memory_Chunks_Read_L+edi*4+4],ecx
        mov     [Memory_Chunks_Read_L+edi*4+8],ecx
        mov     [Memory_Chunks_Read_L+edi*4+12],ecx

        mov     [Memory_Chunks_Write_B+0ffh*4],OFFSET Write_B_RomOrHard
        mov     [Memory_Chunks_Write_W+0ffh*4],OFFSET Write_W_RomOrHard
        mov     [Memory_Chunks_Write_L+0ffh*4],OFFSET Write_L_RomOrHard

        cmp     edx,0fc0000h
        jne     @@noTOS1

;        mov     [TosBaseMax],0feffffh
        mov     [Memory_Chunks_Read_B+0ffh*4],OFFSET Read_B_RomOrHard
        mov     [Memory_Chunks_Read_W+0ffh*4],OFFSET Read_W_RomOrHard
        mov     [Memory_Chunks_Read_L+0ffh*4],OFFSET Read_L_RomOrHard
        jmp     @@continit
@@noTOS1:
;        add     edx,3ffffh
;        mov     [TosBaseMax],edx
        mov     [Memory_Chunks_Read_B+0ffh*4],OFFSET Read_B_Chip
        mov     [Memory_Chunks_Read_W+0ffh*4],OFFSET Read_W_Chip
        mov     [Memory_Chunks_Read_L+0ffh*4],OFFSET Read_L_Chip

@@continit:
        ret

        ENDP

MACRO Return_From_Access
        jmp     [DWORD PTR ebp+base.Return_After_HARD]
ENDM

        align 4
Read_B_Hard:
        and     edi,0ffffffh
        mov     edx,edi
        shr     edx,16
        jmp     [DWORD PTR Memory_Chunks_Read_B+edx*4]
        align 4
Read_W_Hard:
        and     edi,0ffffffh
        mov     edx,edi
        shr     edx,16
        jmp     [DWORD PTR Memory_Chunks_Read_W+edx*4]
        align 4
Read_L_Hard:
        and     edi,0ffffffh
        mov     edx,edi
        shr     edx,16
        jmp     [DWORD PTR Memory_Chunks_Read_L+edx*4]

        align 4
Write_B_Hard:
        and     edi,0ffffffh
        push    eax
        mov     eax,edi
        shr     eax,16
        jmp     [DWORD PTR Memory_Chunks_Write_B+eax*4]

        align 4
Write_W_Hard:
        and     edi,0ffffffh
        push    eax
        mov     eax,edi
        shr     eax,16
        jmp     [DWORD PTR Memory_Chunks_Write_W+eax*4]

        align 4
Write_L_Hard:
        and     edi,0ffffffh
        push    eax
        mov     eax,edi
        shr     eax,16
        jmp     [DWORD PTR Memory_Chunks_Write_L+eax*4]


        align   4
Read_B_Ram:
        mov     dl,[fs:edi]
        Return_From_Access
        align   4
Read_W_Ram:
        mov     dx,[fs:edi]
        rol     dx,8
        Return_From_Access
        align   4
Read_L_Ram:
        mov     edx,[fs:edi]
        bswap   edx
        Return_From_Access
        align   4
Write_B_Ram:
        pop     eax
        mov     [fs:edi],dl
        Return_From_Access
        align   4
Write_W_Ram:
        rol     dx,8
        pop     eax
        mov     [fs:edi],dx
        Return_From_Access
        align   4
Write_L_Ram:
        bswap   edx
        pop     eax
        mov     [fs:edi],edx
        Return_From_Access


        align 4
Read_B_Rom:
        mov     edx,[negTOSBASE]
        mov     dl,[BYTE PTR memtos+edi+edx]
        Return_From_Access

        align 4
Read_W_Rom:
        mov     edx,[negTOSBASE]
        mov     dx,[WORD PTR memtos+edi+edx]
        rol     dx,8
        Return_From_Access

        align 4
Read_L_Rom:
        mov     edx,[negTOSBASE]
        mov     edx,[DWORD PTR memtos+edi+edx]
        bswap   edx
        Return_From_Access

        align 4
Read_B_Chip:
        cmp     edi,0ff8000h
        jb      Read_B_Undefined
        push    edi
        call    Read_Hard
        pop     edi
        Return_From_Access

        align 4
Read_W_chip:
        cmp     edi,0ff8000h
        jb      Read_W_Undefined
        push    edi
        call    Read_Hard
        mov     dh,dl
        inc     edi
        call    Read_Hard
        pop     edi
        Return_From_Access

        align 4
Read_L_Chip:
        cmp     edi,0ff8000h
        jb      Read_L_Undefined
        push    edi
        call    Read_Hard
        rol     edx,8
        inc     edi
        call    Read_Hard
        rol     edx,8
        inc     edi
        call    Read_Hard
        rol     edx,8
        inc     edi
        call    Read_Hard
        pop     edi
        Return_From_Access


        align 4
Read_B_RomOrHard:
        cmp     edi,0ff8000h
        jb      Read_B_Rom
        push    edi
        call    Read_Hard
        pop     edi
        Return_From_Access

        align 4
Read_W_RomOrHard:
        cmp     edi,0ff8000h
        jb      Read_W_Rom
        push    edi
        call    Read_Hard
        mov     dh,dl
        inc     edi
        call    Read_Hard
        pop     edi
        Return_From_Access

        align 4
Read_L_RomOrHard:
        cmp     edi,0ff8000h
        jb      Read_L_Rom
        push    edi
        call    Read_Hard
        rol     edx,8
        inc     edi
        call    Read_Hard
        rol     edx,8
        inc     edi
        call    Read_Hard
        rol     edx,8
        inc     edi
        call    Read_Hard
        pop     edi
        Return_From_Access


        align 4
Write_B_RomOrHard:
        cmp     edi,0ff8000h
        jb      Write_B_Undefined
        push    edi
        call    Write_Hard
        pop     edi
        pop     eax
        Return_From_Access


        align 4
Write_W_RomOrHard:
        cmp     edi,0ff8000h
        jb      Write_W_Undefined
        mov     [Size_Access],2
        push    edi
        xchg    dl,dh
        call    Write_Hard
        xchg    dl,dh
        inc     edi
        call    Write_Hard
        pop     edi
        pop     eax
        Return_From_Access

        align 4
Write_L_RomOrHard:
        cmp     edi,0ff8000h
        jb      Write_L_Undefined
        mov     [Size_Access],4
        push    edi
        rol     edx,8
        call    Write_Hard
        inc     edi
        rol     edx,8
        call    Write_Hard
        inc     edi
        rol     edx,8
        call    Write_Hard
        inc     edi
        rol     edx,8
        call    Write_Hard
        pop     edi
        pop     eax
        Return_From_Access

        align 4

Write_B_Undefined:
Write_W_Undefined:
Write_L_Undefined:
        pop     eax
        cmp     edi,400000h
        jb      @@noiw
;        mov     [ebp+base.Illegal_Access],1      ; needed by ALLIANCE DEMO
        or      [ebp+base.events_Mask],MASK_ILLEGALACCESS
@@noiw:
        Return_From_Access

Read_B_Undefined:
Read_W_Undefined:
Read_L_Undefined:
        cmp     edi,400000h
        jb      @@noir
;        mov     [ebp+basE.Illegal_Access],1
        or      [ebp+base.events_Mask],MASK_ILLEGALACCESS
@@noir:
        Return_From_Access

        align 4

Read_B_Expansion:
;        cmp     esi,RAMSIZE
;        ja      @@nothidden

        cmp     [PC_Base],0     ;
        jnz     @@nothidden     ;

        cmp     edi,0fa0008h
        ja      @@nothidden
        mov     dl,0ffh
        jmp     @@fakenothing
@@nothidden:
        mov     dl,[BYTE PTR memcartridge+edi-0fa0000h]
@@fakenothing:
        Return_From_Access

        align 4
Read_W_Expansion:
;        cmp     esi,RAMSIZE
;        ja      @@nothidden

        cmp     [PC_Base],0     ;
        jnz     @@nothidden     ;

        cmp     edi,0fa0008h
        ja      @@nothidden
        mov     dx,0ffffh
        jmp     @@fakenothing
@@nothidden:
        mov     dx,[WORD PTR memcartridge+edi-0fa0000h]
        rol     dx,8
@@fakenothing:
        Return_From_Access

        align 4
Read_L_Expansion:
;        cmp     esi,RAMSIZE
;        ja      @@nothidden

        cmp     [PC_Base],0     ;
        jnz     @@nothidden     ;

        cmp     edi,0fa0008h
        ja      @@nothidden
        mov     edx,0ffffffffh
        jmp     @@fakenothing
@@nothidden:
        mov     edx,[DWORD PTR memcartridge+edi-0fa0000h]
        bswap   edx
@@fakenothing:
        Return_From_Access


Write_B_Expansion:
        cmp     [PC_Base],0fa0000h
        jnz     Write_notfromexpansion
        mov     [BYTE PTR memcartridge+edi-0fa0000h],dl
write_notfromexpansion:
        pop     eax
        Return_From_Access
Write_W_Expansion:
        cmp     [PC_Base],0fa0000h
        jnz     Write_notfromexpansion
        rol     dx,8
        mov     [WORD PTR memcartridge+edi-0fa0000h],dx
        rol     dx,8
        pop     eax
        Return_From_Access
Write_L_Expansion:
        cmp     [PC_Base],0fa0000h
        jnz     Write_notfromexpansion
        bswap   edx
        mov     [DWORD PTR memcartridge+edi-0fa0000h],edx
        bswap   edx
        pop     eax
        Return_From_Access


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Hardware read/write                                                      ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

        DATASEG

hunk:           ; Unknow memory location -> bus error generated if accessed
        dd      256 dup (Access_Hard_Undefined)
        dd      256 dup (Access_Hard_Undefined)

hmfp:
        dd      48 dup (Access_Hard_Undefined,read_mfp)
        dd      256-2*48 dup (Access_Hard_BusError)
        dd      48 dup (Access_Hard_Undefined,write_mfp)
        dd      256-2*48 dup (Access_Hard_BusError)
;        dd      Access_Hard_Undefined,read_MFP_GPIP     ;FA01
;        dd      Access_Hard_Undefined,read_fffa03
;        dd      Access_Hard_Undefined,read_fffa05
;        dd      Access_Hard_Undefined,read_MFP_IERA
;        dd      Access_Hard_Undefined,read_fffa09
;        dd      Access_Hard_Undefined,read_fffa0b
;        dd      Access_Hard_Undefined,read_fffa0d
;        dd      Access_Hard_Undefined,read_fffa0f
;        dd      Access_Hard_Undefined,read_fffa11
;        dd      Access_Hard_Undefined,read_fffa13
;        dd      Access_Hard_Undefined,read_fffa15
;        dd      Access_Hard_Undefined,read_fffa17
;        dd      Access_Hard_Undefined,read_fffa19
;        dd      Access_Hard_Undefined,read_fffa1b
;        dd      Access_Hard_Undefined,read_MFP_TCDCR    ;fffa1d
;        dd      Access_Hard_Undefined,read_MFP_TADR
;        dd      Access_Hard_Undefined,read_MFP_TBDR
;        dd      Access_Hard_Undefined,read_MFP_TCDR
;        dd      Access_Hard_Undefined,read_MFP_TDDR     ;fffa25
;        dd      Access_Hard_Undefined,read_fffa27
;        dd      Access_Hard_Undefined,read_fffa29
;        dd      Access_Hard_Undefined,read_fffa2b
;        dd      Access_Hard_Undefined,read_fffa2d
;        dd      Access_Hard_Undefined,read_fffa2f
;        dd      256-2*24 dup (Access_Hard_BusError)
;        dd      Access_Hard_Undefined,write_fffa01
;        dd      Access_Hard_Undefined,write_fffa03
;        dd      Access_Hard_Undefined,write_fffa05
;        dd      Access_Hard_Undefined,write_MFP_IERA
;        dd      Access_Hard_Undefined,write_MFP_IERB
;        dd      Access_Hard_Undefined,write_MFP_IPRA
;        dd      Access_Hard_Undefined,write_fffa0d
;        dd      Access_Hard_Undefined,write_MFP_ISRA
;        dd      Access_Hard_Undefined,write_fffa11
;        dd      Access_Hard_Undefined,write_MFP_IMRA
;        dd      Access_Hard_Undefined,write_MFP_IMRB ;fffa15
;        dd      Access_Hard_Undefined,write_fffa17
;        dd      Access_Hard_Undefined,write_MFP_TACR
;        dd      Access_Hard_Undefined,write_MFP_TBCR
;        dd      Access_Hard_Undefined,write_MFP_TCDCR ;fffa1d
;        dd      Access_Hard_Undefined,write_MFP_TADR
;        dd      Access_Hard_Undefined,write_MFP_TBDR
;        dd      Access_Hard_Undefined,write_MFP_TCDR
;        dd      Access_Hard_Undefined,write_MFP_TDDR    ;fffa25
;        dd      Access_Hard_Undefined,write_fffa27
;        dd      Access_Hard_Undefined,write_fffa29
;        dd      Access_Hard_Undefined,write_fffa2b
;        dd      Access_Hard_Undefined,write_fffa2d
;        dd      Access_Hard_Undefined,write_fffa2f
;        dd      256-2*24 dup (Access_Hard_BusError)

hshi:
        dd      5 dup (Read_Hard_Normal)
        dd      Read_ff8205
        dd      Read_Hard_Normal
        dd      Read_ff8207
        dd      Read_Hard_Normal
        dd      Read_ff8209
        dd      54 dup (Read_Hard_Normal)
        dd      32 dup (Read_Palette)
        dd      read_ff8260
        dd      159 dup (Read_Hard_Normal)

        dd      Write_Hard_Normal,Write_ff8201
        dd      Write_Hard_Normal,Write_ff8203

        dd      write_hard_normal,Write_ff8205
        dd      write_hard_normal,Write_ff8207
        dd      write_hard_normal,Write_ff8209
        dd      Write_ff820a,write_hard_normal
        dd      Write_Hard_Normal,write_ff820d

        dd      Write_Hard_Normal               ;ff820e
        dd      Write_ff820f                    ;ff820f - STE modulo

        dd      48 dup (Write_Hard_Normal)
        dd      32 dup (Write_Palette)
        dd      write_ff8260
        dd      159 dup (Write_Hard_Normal)

hmmu:
        dd      Access_Hard_Undefined
        dd      Read_Hard_Normal
        dd      254 dup (Access_Hard_Undefined)
        dd      Access_Hard_Undefined
        dd      Write_Hard_Normal
        dd      254 dup (Access_Hard_Undefined)

hdss:   ;*********************************** DMA Sound System + STe Microwire

;        dd      Read_Hard_Null,Read_ff8901
;        dd      Read_ff8902,Read_Hard_Null
;        dd      Read_ff8904,Read_Hard_Null
;        dd      Read_ff8906,Read_Hard_Null
;        dd      Read_ff8908,Read_Hard_Null
;        dd      Read_ff890a,Read_Hard_Null
;        dd      Read_ff890c,Read_Hard_Null
;        dd      Read_ff890e,Read_Hard_Null
;        dd      Read_ff8910,Read_Hard_Null
;        dd      Read_ff8912,Read_Hard_Null
;        dd      12 dup (Read_Hard_Null)
;        dd      Read_Hard_Null
;        dd      Read_ff8921
;        dd      Read_ff8922,Read_ff8923
;        dd      Read_ff8924,Read_ff8925
;        dd      256-38 dup (Read_Hard_Null)

        dd      Read_Hard_Null                  ;ff8900
        dd      Read_Hard_Null                  ;ff8901
        dd      32 dup (Access_Hard_Undefined)
        dd      Read_ff8922,Read_ff8923
        dd      Read_ff8924,Read_ff8925
        dd      256-38 dup (Access_Hard_Undefined)

        ;dd      256*2 dup (Access_Hard_BusError)



;        dd      Write_Hard_Normal, Write_ff8901;Write_Hard_Normal ;
;        dd      Write_ff8902,Access_Hard_Undefined
;        dd      Write_ff8904,Access_Hard_Undefined
;        dd      Write_ff8906,Access_Hard_Undefined
;        dd      Access_Hard_Undefined,Access_Hard_Undefined
;        dd      Access_Hard_Undefined,Access_Hard_Undefined
;        dd      Access_Hard_Undefined,Access_Hard_Undefined
;        dd      Write_ff890e,Access_Hard_Undefined
;        dd      Write_ff8910,Access_Hard_Undefined
;        dd      Write_ff8912,Access_Hard_Undefined
;        dd      12 dup (Access_Hard_Undefined)
;        dd      Write_Hard_Normal,Write_Hard_Normal;   dd      Write_ff8921
;        dd      Write_ff8922,Write_ff8923
;        dd      Write_ff8924,Write_ff8925
;        dd      256-38 dup (Access_Hard_Undefined)

        dd      Write_Hard_Normal
        dd      Write_Hard_Normal
        dd      32 dup (Access_Hard_Undefined)
        dd      Write_ff8922,Write_ff8923
        dd      Write_ff8924,Write_ff8925
        dd      256-38 dup (Access_Hard_Undefined)

hyam:
        dd      64 dup (read_ff8800,read_ff8801,read_ff8802,read_ff8803)
        dd      64 dup (write_ff8800,write_nothing,write_ff8802,write_nothing)

hcia:
        dd      read_fffc00,Access_Hard_Undefined
        dd      read_fffc02,Access_Hard_Undefined
        dd      read_fffc04,Access_Hard_Undefined
        dd      read_fffc06,Access_Hard_Undefined
        dd      24 dup (Access_Hard_Undefined)
        dd      Access_Hard_Undefined,read_fffc21       ;Real-time clock
        dd      Access_Hard_Undefined,read_fffc23
        dd      Access_Hard_Undefined,read_fffc25       ;fffc21 - fffc3f
        dd      Access_Hard_Undefined,read_fffc27
        dd      Access_Hard_Undefined,read_fffc29
        dd      Access_Hard_Undefined,read_fffc2b
        dd      Access_Hard_Undefined,read_fffc2d
        dd      Access_Hard_Undefined,read_fffc2f
        dd      Access_Hard_Undefined,read_fffc31
        dd      Access_Hard_Undefined,read_fffc33
        dd      Access_Hard_Undefined,read_fffc35
        dd      Access_Hard_Undefined,read_fffc37
        dd      Access_Hard_Undefined,read_fffc39
        dd      Access_Hard_Undefined,read_fffc3b
        dd      Access_Hard_Undefined,read_fffc3d
        dd      Access_Hard_Undefined,read_fffc3f
        dd      192 dup (Access_Hard_Undefined)
        dd      write_fffc00,Access_Hard_Undefined
        dd      write_fffc02,Access_Hard_Undefined
        dd      write_fffc04,Access_Hard_Undefined
        dd      write_fffc06,Access_Hard_Undefined
        dd      24 dup (Access_Hard_Undefined)
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      Access_Hard_Undefined,Write_Hard_Null
        dd      192 dup (Access_Hard_Undefined)

hpaci:
        dd      Read_paci_000
        dd      Read_paci_001
        dd      254 dup (Access_Hard_Undefined)
;        dd      256     dup (write_tfmx)
       dd      256 dup (Access_Hard_Undefined)

hblt:
;        dd      256 dup (Access_Hard_BusError)
;        dd      256 dup (Access_Hard_BusError)

        dd      60 dup (Read_Hard_Normal)       ;ff8a00-ff8a3b
        dd      Read_Blitter_ff8a3c
        dd      195 dup (Read_Hard_Normal)     ;ff8a3d-ff8aff

        dd      60 dup (Write_Hard_Normal)       ;ff8a00-ff8a3b
        dd      Write_Blitter_ff8a3c
        dd      Write_Blitter_ff8a3d
        dd      194 dup (Write_Hard_Normal)      ;ff8a3d-ff8aff


hff92:;******************************************************* ff9200 ?
        dd      16  dup (Read_Hard_Normal)
        dd      Read_ff9210,read_ff9211,read_ff9212,read_ff9213
        dd      256-20 dup (Access_Hard_Undefined)

        dd      16 dup (Write_Hard_Normal)
        dd      256-16 dup (Access_Hard_Undefined)

buse:   dd      256 dup (Access_Hard_BusError)
        dd      256 dup (Access_Hard_BusError)

Hardware_Global_Access:

        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xff00xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xff10xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xff20xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xff30xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xff40xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xff50xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xff60xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xff70xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hblt
        dd      hmmu,hpaci,hshi,hunk,hunk,hunk,hfdc,hunk ;0xff80xx
        dd      hyam,hdss,hblt,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hff92,hunk,hunk,hunk,hunk,hunk ;0xff90xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xffa0xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xffb0xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xffc0xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xffd0xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xffe0xx
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk
        dd      hunk,hunk,hunk,hunk,hunk,hunk,hunk,hunk ;0xfff0xx
        dd      hunk,hunk,hmfp,hunk,hcia,hunk,hunk,buse


        CODESEG


Access_Hard_BusError:
;        mov     [ebp+basE.Illegal_Access],1
        or      [ebp+base.events_Mask],MASK_ILLEGALACCESS
        ret

Access_Hard_Undefined:
        ret

write_nothing:
        ret

PROC Read_Hard NEAR
        push    eax
        push    ecx
        mov     ecx,edi
        mov     eax,edi
        shr     ecx,8
        and     eax,0ffh
        and     ecx,0ffh
        mov     ecx,[DWORD PTR Hardware_Global_Access+ecx*4]
        mov     eax,[ecx+eax*4]
        mov     [dummyjump],eax
        pop     ecx
        pop     eax
        jmp     [dword ptr dummyjump]
        ENDP

        DATASEG

dummyjump       dd      0

        CODESEG

PROC Write_Hard NEAR
        push    ecx
        mov     ecx,edi
        mov     eax,edi
        shr     ecx,8
        and     eax,0ffh
        and     ecx,0ffh
        mov     ecx,[DWORD PTR Hardware_Global_Access+ecx*4]
        mov     eax,[ecx+eax*4+400h]
        pop     ecx
        jmp     eax
        ENDP

Read_Hard_Normal:
        push    eax
        mov     eax,edi
        and     eax,7fffh
        mov     dl,[memio+eax]
        pop     eax
        ret

Write_Hard_Normal:
        push    eax
        mov     eax,edi
        and     eax,7fffh
        mov     [memio+eax],dl
        pop     eax
Write_Hard_Null:
        ret

Read_Hard_Null:
        mov     dl,0
        ret

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ PaCifiST registers                                                       ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

        EXTRN pacifist_major : BYTE
        EXTRN pacifist_minor : BYTE

read_paci_000:
        mov     dl,[pacifist_major]
        ret

read_paci_001:
        mov     dl,[pacifist_minor]
        ret

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ STE ANALOG PORT                                                          ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

        EXTRN STE_Analog1_X   : WORD
        EXTRN STE_Analog1_Y   : WORD

Read_ff9210:
Read_ff9212:
        mov     dl,0
        ret

read_ff9211:
        mov     dl,[BYTE PTR STE_Analog1_X]
        ret
read_ff9213:
        mov     dl,[BYTE PTR STE_Analog1_Y]
        ret


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ DMA SOUND SYSTEM & STe MICROWIRE                                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

        DATASEG

;        EXTRN DMASound_Mode : DWORD
;        EXTRN DMASound_Freq : DWORD
;        EXTRN DMASound_Start : DWORD
;        EXTRN DMASound_Current : DWORD
;        EXTRN DMASound_End : DWORD
DMASound_Mode dd      0
DMASound_Freq dd        0
DMASound_Start  Dd 0
DMASound_Current Dd 0
DMASound_End : Dd 0

        CODESEG

Read_ff8901:
        mov     dl,[BYTE PTR DMAsound_Mode]
        ret

Write_ff8901:
        mov     [memio+0901h],dl
        mov     [BYTE PTR DMAsound_Mode],dl
        ret

Read_ff8902:
        mov     dl,[BYTE PTR DMASound_Start]
        ret
Read_ff8904:
        mov     dl,[BYTE PTR DMASound_Start+1]
        ret
Read_ff8906:
        mov     dl,[BYTE PTR DMASound_Start+2]
        ret
Write_ff8902:
        mov     [BYTE PTR DMASound_Start],dl
        mov     [memio+0902h],dl
        ret
Write_ff8904:
        mov     [BYTE PTR DMASound_Start+1],dl
        mov     [memio+0904h],dl
        ret
Write_ff8906:
        mov     [BYTE PTR DMASound_Start+2],dl
        mov     [memio+0906h],dl
        ret

Read_ff8908:
        mov     dl,[BYTE PTR DMASound_Current]
        ret
Read_ff890a:
        mov     dl,[BYTE PTR DMASound_Current+1]
        ret
Read_ff890c:
        mov     dl,[BYTE PTR DMASound_Current+2]
        ret

Read_ff890e:
        mov     dl,[BYTE PTR DMASound_End]
        ret
Read_ff8910:
        mov     dl,[BYTE PTR DMASound_End+1]
        ret
Read_ff8912:
        mov     dl,[BYTE PTR DMASound_End+2]
        ret
Write_ff890e:
        mov     [BYTE PTR DMASound_End],dl
        mov     [memio+090eh],dl
        ret
Write_ff8910:
        mov     [BYTE PTR DMASound_End+1],dl
        mov     [memio+0910h],dl
        ret
Write_ff8912:
        mov     [BYTE PTR DMASound_End+2],dl
        mov     [memio+0912h],dl
        ret

Read_ff8921:
        mov     dl,[BYTE PTR DMASound_Freq]
        ret
Write_ff8921:
        mov     [BYTE PTR DMASound_Freq],dl
        mov     [BYTE PTR memio+0922h],dl
        ret


Read_ff8922:
        ;mov     dl,[memio+0922h]
        xor     dl,dl
        ret
Read_ff8923:
        ;mov     dl,[memio+0923h]
        xor     dl,dl
        ret
Read_ff8924:
        mov     dl,[memio+0924h]
        ret
Read_ff8925:
        mov     dl,[memio+0925h]
        ret

Write_ff8922:
        mov     [memio+0922h],dl
        ret
Write_ff8923:
        mov     [memio+0923h],dl
        ret
Write_ff8924:
        mov     [memio+0924h],dl
        ret
Write_ff8925:
        mov     [memio+0925h],dl
        ret

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ SHIFTER ff82xx                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


        DATASEG


        extrn   ST_Screen_PTR           :dword
        extrn   ST_Screen_PTR_current   :dword
        extrn   VideoModeReg            :dword
        extrn   nbVideoModeChanges      :dword
        extrn   shifter_modulo          :dword

        EXTRN   PaletteUpdate : dword
        EXTRN   ST_Palette

Raster_interpolation   dd      48      dup (0) ;cycles 0-95

rast=0
        REPT    80
        dd      rast
        dd      rast
rast=rast+2
        ENDM

        dd      48      dup (0) ;cycles 416-511


fakenext       dd      0

        CODESEG

Calc_Exact_Screen_Ptr:
        push    eax ebx ecx edx
        mov     ebx,[ST_Screen_PTR_current]
        mov     eax,[cycles_per_rasterline]
        ;cmp     eax,512
        ;jne     @@impossible
        sub     eax,[thisraster_cycles]
        add     eax,[fakenext]
        cmp     eax,512
        jb      @@okb
        xor     eax,eax
@@okb:
        shr     eax,1
        add     ebx,[Raster_interpolation+eax*4]
@@impossible:
        mov     [memio+0209h],bl
        shr     ebx,8
        mov     [memio+0207h],bl
        shr     ebx,8
        mov     [memio+0205h],bl
        pop     edx ecx ebx eax

        mov     [fakenext],0
        ret

read_ff8205:
        call    Calc_Exact_Screen_Ptr
        mov     dl,[memio+0205h]
        ret
read_ff8207:
        call    Calc_Exact_Screen_Ptr
        mov     dl,[memio+0207h]
        ret
read_ff8209:
        call    Calc_Exact_Screen_Ptr
        mov     dl,[memio+0209h]
        ret

write_ff8201:
        mov     [BYTE PTR ST_Screen_PTR+2],dl
        ;mov     [BYTE PTR ST_Screen_PTR_Current+2],dl
        ;mov     [BYTE PTR ST_Screen_PTR_Current],0
        mov     [memio+201h],dl
        mov     [memio+209h],0
        ret

write_ff8203:
        mov     [BYTE PTR ST_Screen_PTR+1],dl
        ;mov     [BYTE PTR ST_Screen_PTR_Current+1],dl
        ;mov     [BYTE PTR ST_Screen_PTR_Current],0
        mov     [memio+203h],dl
        mov     [memio+209h],0
        ret


        EXTRN isSTE : DWORD

write_ff8205:
        test     [isSTE],1
        jz      @@noste5
        mov     [memio+205h],dl ;STE
        ;mov     [BYTE PTR ST_Screen_PTR+2],dl
        mov     [BYTE PTR ST_Screen_PTR_current+2],dl
        mov     [fakenext],512
@@noste5:
        ret

write_ff8207:
        test     [isSTE],1
        jz      @@noste7
        mov     [memio+207h],dl ;STE
        ;mov     [BYTE PTR ST_Screen_PTR+1],dl
        mov     [BYTE PTR ST_Screen_PTR_current+1],dl
        mov     [fakenext],512
@@noste7:
        ret

write_ff8209:
        push    edx
        test    [isSTE],1
        jz      @@noste_
        and     dl,0feh
        mov     [memio+209h],dl ;STE
        ;mov     [BYTE PTR ST_Screen_PTR],dl
        mov     [BYTE PTR ST_Screen_PTR_current],dl
        mov     [fakenext],512
@@noste_:
        pop     edx
        ret

write_ff820d:
        push    edx
        mov     [memio+20dh],dl ;STE
        test    [isSTE],1
        jz      @@noste_
        and     dl,0feh
        mov     [BYTE PTR ST_Screen_PTR],dl
        mov     [BYTE PTR ST_Screen_PTR_current],dl
        mov     [fakenext],512
@@noste_:
        pop     edx
        ret


write_ff820f:
        test    [isSTE],1
;        jz      @@noste
        mov     [BYTE PTR memio+020fh],dl
        mov     [BYTE PTR shifter_modulo],dl
@@noste:
        ret

read_palette:
        push    edi
        and     edi,31
        mov     dl,[BYTE PTR memio+240h+edi]
        pop     edi
        ret

        DATASEG

masks:
           REPT 16
        db      00fh,0ffh
        ENDM

        CODESEG

write_palette:
        push    edi
        and     edi,31
        mov     eax,edx
        and     al,[BYTE PTR masks+edi]
        mov     [BYTE PTR memio+240h+edi],al

        cmp     [BYTE PTR ST_Palette+edi],dl
        je      @@same
        mov     [BYTE PTR ST_Palette+edi],dl

        shr     edi,1   ;color index
        bts     [PaletteUpdate],edi
@@same:
        pop     edi
        ret


write_ff8260:
        push    eax
        mov     eax,edx
        mov     [memio+260h],dl
        and     eax,3
        cmp     [VideoModeReg],eax
        jz      @@same
        inc     [nbVideoModeChanges]
@@same:
        mov     [VideoModeReg],eax
        mov     [VideoMode],eax
        pop     eax
        ret

read_ff8260:
        mov     dl,[memio+260h]
        ret


        extrn   low_overscan : dword
        extrn rasterline : dword

write_ff820a:
        push    edx
        mov     [memio+20ah],dl
        cmp     [rasterline],230
        jb      @@norange
        cmp     [rasterline],290
        ja      @@norange

        shr     edx,1
        and     edx,1   ;0/1
        inc     edx     ;1/2
        or      [low_overscan],edx
@@norange:
        pop     edx
        ret


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ MFP fffaxx                                                               ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

        extrn peek_mfp : near
        extrn poke_mfp : near
;
read_mfp:
        push    eax

        push    ebp
        push    es
        push    ds
        pop     es
        push    ecx
        push    edi
        call    peek_mfp
        add     esp,4
        pop     ecx             ;need pour sprintf
        mov     dl,al
        pop     es
        pop     ebp

        pop     eax
        ret

write_mfp:
        push    es
        push    ds
        pop     es
        push    edx
        push    edi
        call    poke_mfp
        add     esp,8
        pop     es
        ret

        DATASEG

rand            dd      0

        CODESEG


read_MFP_GPIP:                                                  ; FFFA01
        mov     dl,[memio+07a01h]
        or      dl,80h                  ;BIT 7 = Monochrome

        ;--------------- is printer busy?

        and     dl,0feh                 ;Printer not BUSY (default)

        test    [isparallel],1
        jz      @@online

        push    edx eax
        mov     edx,379h                ;Port 379h = Printer Status reg
        in      al,dx
        shr     al,5                    ;bit 4 = ON LINE
        pop     eax edx
        jc      @@online
        inc     dl                      ;printer BUSY
@@online:
        cmp     [IsMonochrome],0
        jz      @@IsMono
        and     dl,7fh
@@IsMono:
        or      dl,1    ;;;;;;;;;;;;;;;;;;;; NEW TRY //
        ret

read_MFP_IERA:                                                  ; FFFA07
        ;mov     dl,[BYTE PTR mfp_IERA]
        mov     dl,[BYTE PTR memio+07a07h]
        ret


read_fffa13:
        ;mov     dl,[BYTE PTR mfp_IMRA]
        mov     dl,[memio+7a13h]
        ret

read_fffa19:
        mov     dl,[memio+7a19h]
;        mov     dl,[BYTE PTR mfp_TACR]
        ret

read_fffa2d:
        mov     dl,081h
        ret

;read_fffa1f:
;        mov     dl,[memio+7a1fh]
;;        mov     dl,[BYTE PTR mfp_TADR]
;        ret

read_fffa23:
        add     [BYTE PTR rand],7
        mov     dl,[BYTE PTR rand]
        ret

;read_fffa25:
;        mov     dl,[memio+7a25h]
;        ret

read_fffa2b:
        mov     dl,[memio+7a2bh]
        ret

read_fffa0b:
        mov     dl,20h
        ret

read_fffa03:
read_fffa05:
read_fffa0d:
read_fffa0f:
read_fffa17:
read_fffa1b:
;read_fffa1d:
read_fffa27:
read_fffa29:
        mov     dl,1
        ret

;read_fffa21:
;        mov     dl,0ffh
;
;        ret


read_fffa09:
        mov     dl,[memio+7a09h]
        ret
read_fffa15:
        mov     dl,[memio+7a09h]
        ret

read_fffa11:
        mov     dl,[memio+7a11h]
        ret

read_fffa2f:                                    ; SERIAL STATUS
        xor     dl,dl
        ret

        DATASEG


STRUCT_MFP_START:

Timer_A_Enabled dd      0       ;is TIMER A enabled?
Timer_A_Masked  dd      0       ;is TIMER A masked?
Timer_A_Data    dd      0       ;value of TIMER A data

Timer_A_Mode            dd      TIMERMODE_STOP
Timer_A_Freq            dd      0
Timer_A_PredivisedFreq  dd      0
Timer_A_Cumul           dd      0

Timer_B_Enabled dd      0       ;is TIMER B enabled?
Timer_B_Masked  dd      0       ;is TIMER B masked?
;Timer_B_HBL     dd      0       ;is TIMER B under HBL?
Timer_B_Prediv  dd      0       ;Timer B Predivisor
Timer_B_PredivI dd      0       ;Timer B Predivisor initial value
Timer_B_Data    dd      0       ;value of TIMER B data
Timer_B_DataCurrent             dd      0

Timer_B_Mode    dd      0       ;Timer B current Mode
Timer_B_PredivisedFreq dd 0
Timer_B_Freq            dd 0

Timer_D_PredivisedFreq          dd      0
Timer_D_Data                    dd      0
Timer_D_Freq                    dd      0
Timer_D_Enabled                 dd      0
Timer_D_Masked                  dd      0

Timer_C_PredivisedFreq          dd      0
Timer_C_Data                    dd      0
Timer_C_Freq                    dd      0
Timer_C_Enabled                 dd      0
Timer_C_Masked                  dd      0
isSystemTimerC                  dd      0 ;  is Timer C 200Hz?

STRUCT_MFP_END:
Struct_MFP_Size dd offset STRUCT_MFP_END - STRUCT_MFP_START


Timer_Modes     dd      TIMERMODE_STOP,         0
                dd      TIMERMODE_DELAY,        Timer_FREQBASE/4
                dd      TIMERMODE_DELAY,        Timer_FREQBASE/10
                dd      TIMERMODE_DELAY,        Timer_FREQBASE/16
                dd      TIMERMODE_DELAY,        Timer_FREQBASE/50
                dd      TIMERMODE_DELAY,        Timer_FREQBASE/64
                dd      TIMERMODE_DELAY,        Timer_FREQBASE/100
                dd      TIMERMODE_DELAY,        Timer_FREQBASE/200
                dd      TIMERMODE_EVENTCOUNT,   0
                dd      TIMERMODE_SIGNAL,       Timer_FREQBASE/4
                dd      TIMERMODE_SIGNAL,       Timer_FREQBASE/10
                dd      TIMERMODE_SIGNAL,       Timer_FREQBASE/16
                dd      TIMERMODE_SIGNAL,       Timer_FREQBASE/50
                dd      TIMERMODE_SIGNAL,       Timer_FREQBASE/64
                dd      TIMERMODE_SIGNAL,       Timer_FREQBASE/100
                dd      TIMERMODE_SIGNAL,       Timer_FREQBASE/200

Timer_Predivisor dd     1,4,10,16,50,64,100,200
                 dd     1,4,10,16,50,64,100,200

        PUBLIC Struct_MFP_Start
        PUBLIC Struct_MFP_Size

        PUBLIC  Timer_A_Enabled
        PUBLIC  Timer_A_Data
        PUBLIC  Timer_A_Masked

        PUBLIC  Timer_A_Mode
        PUBLIC  Timer_A_Freq
        PUBLIC  Timer_A_Cumul

        PUBLIC  Timer_B_Enabled
        PUBLIC  Timer_B_Data
        PUBLIC  Timer_B_DataCurrent
        PUBLIC  Timer_B_Masked
        PUBLIC  Timer_B_Prediv
        PUBLIC  Timer_B_PredivI
        PUBLIC  TImer_B_Mode
        PUBLIC  Timer_B_PredivisedFreq
        PUBLIC  Timer_B_Freq

        PUBLIC  Timer_D_PredivisedFreq
        PUBLIC  Timer_D_Data
        PUBLIC  Timer_D_Freq

        PUBLIC  Timer_C_PredivisedFreq
        PUBLIC  Timer_C_Data
        PUBLIC  Timer_C_Freq


        PUBLIC  Timer_D_Enabled
        PUBLIC  Timer_D_Masked
        PUBLIC  Timer_C_Enabled
        PUBLIC  Timer_C_Masked


        PUBLIC isSystemTimerC


        CODESEG

        IFDEF DEBUG
                EXTRN  sendlog : near
        ENDIF

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Read FFFA1D - TCDCR = Timer C & D Control Register
read_MFP_TCDCR:
        mov     dl,[memio+_MFP_TCDCR]
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Read FFFA1F - TADR = Timer A Data Register
read_MFP_TADR:
        mov     dl,[BYTE PTR memio+_MFP_TADR]  ;current Timer A data value
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Read FFFA21 - TBDR = Timer B Data Register
read_MFP_TBDR:
        mov     dl,[BYTE PTR memio+_MFP_TBDR]  ;current Timer B data value
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Read FFFA23 - TCDR = Timer C Data Register
read_MFP_TCDR:
        mov     dl,[memio+_MFP_TCDR]
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Read FFFA25 - TDDR = Timer D Data Register
read_MFP_TDDR:
        mov     dl,[memio+_MFP_TDDR]
        ret



;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Write FFFA07 - IERA = Interrupt Enable Register
write_MFP_IERA:
        push    edx
        mov     [BYTE PTR memio+_MFP_IERA],dl   ;enable, Timer A, B...

        shr     dl,1                            ;bit 0 = TIMER B
        setc    [BYTE PTR Timer_B_Enabled]
        shr     dl,5                            ;bit 5 = TIMER A
        setc    [BYTE PTR Timer_A_Enabled]
        pop     edx
        ret



;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Write FFFA09 - IERB = Interrupt Enable Register
write_MFP_IERB:
        push    edx
;        or      dl,40h
        mov     [BYTE PTR memio+_MFP_IERB],dl      ; keyb irq

        shr     dl,5
        setc    [BYTE PTR Timer_D_Enabled]
        shr     dl,1
        setc    [BYTE PTR Timer_C_Enabled]
        pop     edx
        ret



;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Write FFFA0B - IPRA = Interrupt Pending Register A
write_MFP_IPRA:
        mov     [BYTE PTR memio+_MFP_IPRA],dl   ;irq triggered
        ret



;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Write FFFA0F - ISRA = Interrupt In Service Register A
write_MFP_ISRA:
        mov     [BYTE PTR memio+_MFP_ISRA],dl
        ret


;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Write FFFA13 - IMRA = Interrupt Mask Register A
write_MFP_IMRA:
        push    edx
        mov     [BYTE PTR memio+_MFP_IMRA],dl           ;;;; avant ISRA!!!
        shr     dl,1
        setc    [BYTE PTR Timer_B_Masked]
        shr     dl,5
        setc    [BYTE PTR Timer_A_Masked]
        pop     edx
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Write FFFA15 - IMRB = Interrupt Mask Register B
write_MFP_IMRB:
        push    edx
        mov     [BYTE PTR memio+_MFP_IMRB],dl
        shr     dl,5
        setc    [BYTE PTR Timer_D_Masked]
        shr     dl,1
        setc    [BYTE PTR Timer_C_Masked]
        pop     edx
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Write FFFA19 - TACR = Timer A Control Register
write_MFP_TACR:
        push    eax ebx ecx edx
        mov     ebx,edx
        mov     [BYTE PTR memio+_MFP_TACR],dl
        and     edx,0fh
        mov     eax,[Timer_Modes+edx*8]         ; mode
        mov     [Timer_A_Mode],eax
        mov     eax,[Timer_Modes+edx*8+4]       ; predivised frequency
        mov     [Timer_A_PredivisedFreq],eax
        cdq
        mov     ecx,[Timer_A_Data]              ; timer A DATA (divisor)

        test    ecx,ecx
        jnz     @@noda
        mov     ecx,100h
@@noda: div     ecx

        mov     [Timer_A_Freq],eax
        pop     edx ecx ebx eax
        ret
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Write FFFA1B - TBCR = Timer B Control Register
write_MFP_TBCR:
        push    eax ebx ecx edx
        mov     ebx,edx
        mov     [BYTE PTR memio+_MFP_TBCR],dl
        and     edx,0fh
        mov     eax,[Timer_Modes+edx*8]
        mov     [Timer_B_Mode],eax
        mov     eax,[Timer_Modes+edx*8+4]
        mov     [Timer_B_PredivisedFreq],eax
        cdq
        mov     ecx,[Timer_B_Data]

        test    ecx,ecx
        jnz     @@nodb
        mov     ecx,100h
@@nodb: div     ecx

        mov     [Timer_B_Freq],eax

        mov     eax,ebx
        and     ebx,8
        jz      @@noHBL
        and     eax,15

        mov     eax,[Timer_Predivisor+eax*4]
        mov     [Timer_B_Prediv],eax
        mov     [Timer_B_Predivi],eax
@@noHBL:
        pop     edx ecx ebx eax
        ret


;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Write FFFA1D - TCDCR = Timer C & D Control Register
write_MFP_TCDCR:
        push    eax ecx edx
        mov     [BYTE PTR memio+_MFP_TCDCR],dl

        push    edx

        and     edx,7
        mov     eax,[Timer_Modes+edx*8+4]    ;predivised Frequency
        mov     [Timer_D_PredivisedFreq],eax
        cdq
        mov     ecx,[Timer_D_Data]

        test    ecx,ecx
        jnz     @@nodd
        mov     ecx,100h
@@nodd: div     ecx

        mov     [Timer_D_Freq],eax
        pop     edx

        shr     edx,4
        and     edx,7
        mov     eax,[Timer_Modes+edx*8+4]    ;predivised Frequency
        mov     [Timer_C_PredivisedFreq],eax
        cdq
        mov     ecx,[Timer_C_Data]

        test    ecx,ecx
        jnz     @@nodc
        mov     ecx,100h
@@nodc: div     ecx

        mov     [Timer_C_Freq],eax
        cmp     eax,200
        sete    [BYTE PTR isSystemTimerC]

        pop     edx ecx eax
        ret



;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Write FFFA1F - TADR = Timer A Data Register
write_MFP_TADR:
        push    eax ebx ecx edx
        mov     ebx,edx
        mov     [BYTE PTR memio+_MFP_TADR],dl
        mov     [BYTE PTR Timer_A_Data],dl      ;current value
        xor     ecx,ecx
        mov     cl,dl
        mov     eax,[Timer_A_PredivisedFreq]
        cdq

        test    ecx,ecx
        jnz     @@noda
        mov     ecx,100h
@@noda: div     ecx

        mov     [Timer_A_Freq],eax
        pop     edx ecx ebx eax
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Write FFFA21 - TBDR = Timer B Data Register
write_MFP_TBDR:
        mov     [BYTE PTR memio+_MFP_TBDR],dl
        mov     [BYTE PTR Timer_B_Data],dl      ;current value
        mov     [BYTE PTR Timer_B_DataCurrent],dl      ;current value
        ret


;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Write FFFA23 - TCDR = Timer C Data Register
write_MFP_TCDR:
        push    eax ebx ecx edx
        mov     ebx,edx
        mov     [BYTE PTR memio+_MFP_TCDR],dl
        mov     [BYTE PTR Timer_C_Data],dl      ;current value
        xor     ecx,ecx
        mov     cl,dl
        mov     eax,[Timer_C_PredivisedFreq]
        cdq

        test    ecx,ecx
        jnz     @@nodc
        mov     ecx,100h
@@nodc: div     ecx

        mov     [Timer_C_Freq],eax
        cmp     eax,200
        sete    [BYTE PTR isSystemTimerC]
        pop     edx ecx ebx eax
        ret


;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Write FFFA25 - TDDR = Timer D Data Register
write_MFP_TDDR:
        push    eax ebx ecx edx
        mov     ebx,edx
        mov     [BYTE PTR memio+_MFP_TDDR],dl
        mov     [BYTE PTR Timer_D_Data],dl      ;current value
        xor     ecx,ecx
        mov     cl,dl
        mov     eax,[Timer_D_PredivisedFreq]
        cdq

        test    ecx,ecx
        jnz     @@nodd
        mov     ecx,100h
@@nodd: div     ecx

        mov     [Timer_D_Freq],eax
        pop     edx ecx ebx eax
        ret


;write_fffa07:   ;IERA: interrupts validation. bit 5=timer A on.
;
;        mov     [BYTE PTR memio+07a07h],dl
;        ret
;
;        push    edx eax
;        mov     dh,[BYTE PTR mfp_IERA]
;        xor     dl,dh
;
;        mov     al,dl
;        and     al,dh
;        and     al,20h
;        jz      @@notimera      ;prev. or last value have bit 5 setted
;
;        mov     eax,[mfp_TACR]
;        and     eax,15
;        cmp     [mode_A_tab+eax*8],2
;        jnz     @@end_fffa07
;
;        or      [events_mask],MASK_TIMERA       ;mode delay
;        mov     [timer_a_base],10000            ;UNKNOWN
;        jmp     @@end_fffa07
;@@notimera:
;        test    dl,20h
;        jz      @@end_fffa07
;        test    dh,20h
;        jnz     @@end_fffa07
;
;        mov     eax,MASK_TIMERA
;        not     eax
;        and     [events_mask],eax
;@@end_fffa07:
;        pop     eax edx
;        mov     [BYTE PTR mfp_IERA],dl        ;new value
;        ret

write_fffa11:
;;        and     [BYTE PTR memio+7a11h],dl
;        not     dl
        and     [BYTE PTR memio+7a11h],dl
;        not     dl
        ret

;write_fffa13:
;        mov     [BYTE PTR mfp_IMRA],dl
;        mov     [BYTE PTR memio+7a13h],dl
;        ret

;write_fffa1b:
;        mov     [BYTE PTR memio+7a1bh],dl
;
;        push    edx
;        or      dl,dl
;        jz      @@zero
;        mov     dl,255
;@@zero:
;        mov     [BYTE PTR mfp_TADR_reload],dl
;
;        test    [events_mask],MASK_TIMERA
;        jz      @@notima
;        mov     [BYTE PTR mfp_TADR],dl
;@@notima:
;        pop     edx
        ;ret

write_fffa01:
write_fffa03:
write_fffa05:
write_fffa0d:
;write_fffa15:
write_fffa17:
;write_fffa1d:
write_fffa1f:
write_fffa23:
;write_fffa25:
write_fffa27:
write_fffa29:
write_fffa2b:
write_fffa2d:
write_fffa2f:
        and     edi,7fffh
        mov     [memio+edi],dl
        ret

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ YAMAHA ff88xx                                                            ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

        DATASEG

IFDEF sound
        EXTRN YM_reg : dword

       EXTRN read_yamaha : near
       EXTRN write_yamaha : near
ELSE
YM_reg  dd      0
ENDIF

read_ff8801:
read_ff8803:
        mov     dl,0ffh
        ret

read_ff8800:                            ;read data
read_ff8802:                            ;read data
        cmp     [YM_reg],14
        jz      read_port_a
        cmp     [YM_reg],15
        jz      read_port_b

IFDEF SOUND
        push    eax edx esi edi ebp ebx ecx
        call    read_yamaha
        pop     ecx ebx ebp edi esi edx
        mov     dl,al
        pop     eax
ENDIF
        ret


write_ff8800:
        push    edx
        and     dl,15
        mov     [memio+800h],dl
        mov     [BYTE PTR YM_reg],dl
        pop     edx
        ret

write_ff8802:
        mov     [memio+802h],dl
        cmp     [YM_reg],14          ; parallel port?
        jz      write_port_a
        cmp     [YM_reg],15
        jz      write_port_b

IFDEF SOUND
        push    eax ebx ecx edx ebp esi edi
        push    edx
        call    write_yamaha
        add     esp,4
        pop     edi esi ebp edx ecx ebx eax
ENDIF
        ret

        DATASEG

porta   dd      0
portb   dd      0

        CODESEG

        EXTRN   Sys_FDC_driveside : NEAR

read_port_a:
        mov     dl,[byte ptr porta]
        ;or      dl,27h                  ;RTS=DTR=Centronics=1
        or      dl,20h
        ret

read_port_b:
        mov     dl,[byte ptr portb]
        mov     dl,0ffh
        ret

write_port_a:                           ;bits 0-2 are for FDC
        mov     [porta],edx
        pushad
        and     edx,7
        push    edx
        call    Sys_FDC_driveside
        add     esp,4
        popad
        ret

write_port_b:
        test    [isparallel],1
        jz      @@noprn

        mov     [portb],edx

        push    eax edx

        mov     eax,edx
        mov     edx,378h        ;Printer Data Output
        out     dx,al
        jmp     @@w1
@@w1:
        add     edx,2           ;Printer Control Register
        mov     eax,12          ;00001100
        out     dx,al
        jmp     @@w2
@@w2:
        mov     eax,13
        out     dx,al

        pop     edx eax
@@noprn:
        ret


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ 6301 Keyboard fffcxx                                                     ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

read_fffc00:
        mov    dl,[memio+07c00h]
        or     dl,2h
        ret

read_fffc02:
        pushad
        call    Keyboard_Read
        mov     [BYTE PTR Key],al
        popad
        mov     dl,[BYTE PTR Key]
        ret

write_fffc00:
;        mov [memio+07c00h],dl
        ret

write_fffc02:
        pushad
        mov     al,[memio+7c02h]
        push    eax
        push    edx
        mov     [ebp+base.PC],esi
        call    Keyboard_Send           ;send dl
        add     esp,4
        pop     eax
        or      al,2
        mov     [memio+7c02h],al
        popad
        ret

        DATASEG

Key     dd      0


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ MIDI                                                                     ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

read_fffc04:
                        ;mov     dl,0;81h
        mov     dl,03h    ;2 = pres … recevoir
        ret

read_fffc06:
        mov     dl,0
        ret

write_fffc04:
        ret

        EXTRN midi_out : NEAR

write_fffc06:
        pushad
        push    edx
        call    midi_out
        add     esp,4
        popad
        ret


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Realtime Clock                                                           ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

read_fffc21:
read_fffc23:
read_fffc25:
read_fffc27:
read_fffc29:
read_fffc2b:
read_fffc2d:
read_fffc2f:
read_fffc31:
read_fffc33:
read_fffc35:
read_fffc37:
read_fffc39:
read_fffc3b:
read_fffc3d:
read_fffc3f:
        xor     dl,dl
        ret


;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Blitter FF8A00-FF8A3D                                                    ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

            EXTRN Do_Blitter : NEAR

        PUBLIC must_do_blitter ;

must_do_blitter  dd     0

Write_Blitter_ff8a3d:
        mov     [memio+0a3dh],dl
        cmp     [size_access],2
        jnz     @@no2
        test    [memio+0a3ch],80h
        jz      @@no2

        ;mov     [must_do_blitter],1

        pushad
        call    Do_Blitter
        popad
@@no2:
        ret

Write_Blitter_ff8a3c:
        mov     [memio+0a3ch],dl
        cmp     [size_access],2
        jz      @@nobusy

        test    dl,80h
        jz      @@nobusy

;        mov     [must_do_blitter],1

        pushad
        call    Do_Blitter
        popad
@@nobusy:
        ret

Read_Blitter_ff8a3c:
        mov     dl,[memio+0a3ch]
        and     dl,7fh                  ;clear busy bit
        ret

;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ FDC                                                                      ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


        DATASEG

hfdc:
        dd      Access_Hard_Undefined
        dd      Access_Hard_Undefined
        dd      Access_Hard_Undefined
        dd      Access_Hard_Undefined
        dd      Read_ff8604                       ;ff8604
        dd      Read_ff8605                       ;ff8605
        dd      Read_ff8606                       ;ff8606
        dd      read_ff8607                       ;ff8607
        dd      Read_Hard_Normal                  ;ff8608
        dd      Read_ff8609                       ;ff8609
        dd      Read_Hard_Normal                  ;ff860a
        dd      read_ff860b                       ;ff860b
        dd      Read_Hard_Normal                  ;ff860c
        dd      read_ff860d                       ;ff860d
        dd      Read_Hard_Normal                  ;ff860e
        dd      Read_Hard_Normal                  ;ff860f
        dd      240 dup (Access_Hard_Undefined)

        dd      Access_Hard_Undefined
        dd      Access_Hard_Undefined
        dd      Access_Hard_Undefined
        dd      Access_Hard_Undefined
        dd      write_ff8604                       ;ff8604
        dd      write_ff8605                       ;ff8605
        dd      write_ff8606                       ;ff8606
        dd      write_ff8607                       ;ff8607
        dd      Write_Hard_Normal                  ;ff8608
        dd      Write_ff8609                       ;ff8609
        dd      Write_Hard_Normal                  ;ff860a
        dd      Write_ff860b                       ;ff860b
        dd      Write_Hard_Normal                  ;ff860c
        dd      write_ff860d                       ;ff860d
        dd      Write_Hard_Normal                  ;ff860e
        dd      Write_Hard_Normal                  ;ff860f
        dd      240 dup (Access_Hard_Undefined)


FDC_DMA_Ptr     dd      0       ;PTR of DMA
FDC_Cmd         dw      0       ;current FDC command/regidx (ff8606)
FDC_Data        dw      0       ;current FDC data (ff8604)

        PUBLIC  FDC_DMA_Ptr
        PUBLIC  FDC_Cmd
        PUBLIC  FDC_Data

        CODESEG

        EXTRN Sys_FDC : NEAR
        EXTRN SYS_FDC_getregister : NEAR
        EXTRN SYS_DMA_getstatus : NEAR


read_ff8604:
        mov     [ebp+base.PC],esi
        push    eax ebx ecx edx esi edi ebp
        call    SYS_FDC_getregister
        pop     ebp edi esi edx ecx ebx
        mov     dl,ah
        pop     eax
        ret

read_ff8605:
        mov     [ebp+base.PC],esi
        push    eax ebx ecx edx esi edi ebp
        call    SYS_FDC_getregister
        pop     ebp edi esi edx ecx ebx
        mov     dl,al
        pop     eax
        ret

read_ff8606:
        mov     dl,0
        ret

read_ff8607:
        mov     [ebp+base.PC],esi
        push    eax ebx ecx edx esi edi ebp
        call    SYS_DMA_getstatus
        pop     ebp edi esi edx ecx ebx
        mov     dl,al
        pop     eax
        ret

read_ff8609:
        mov     dl,[BYTE PTR FDC_Dma_Ptr+2]
        ret
read_ff860b:
        mov     dl,[BYTE PTR FDC_Dma_Ptr+1]
        ret
read_ff860d:
        mov     dl,[BYTE PTR FDC_Dma_Ptr]
        ret

write_ff8609:
        mov     [BYTE PTR FDC_Dma_Ptr+2],dl
        ret

write_ff860b:
        mov     [BYTE PTR FDC_Dma_Ptr+1],dl
        ret

write_ff860d:
        mov     [BYTE PTR FDC_Dma_Ptr],dl
        ret

write_ff8604:
        mov     [BYTE PTR FDC_Data+1],dl
        ret

write_ff8605:
        mov     [BYTE PTR FDC_Data],dl
        cmp     [Size_Access],4
        jz      @@later
        pushad
        call    SYS_FDC
        popad
@@later:
        ret

write_ff8606:
        mov     [BYTE PTR FDC_Cmd+1],dl
        ret

write_ff8607:
        mov     [BYTE PTR FDC_Cmd],dl
        cmp     [Size_Access],4
        jnz     @@noFDC
        pushad
        call    SYS_FDC
        popad
@@noFDC:
        ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
;
;        extrn   paula : byte
;        extrn   modpaula : byte
;
;write_tfmx:
;        push    eax edx edi
;        and     edi,255
;;        mov     [paula+edi],dl
;;        mov     [modpaula+edi],1
;        pop    edi edx eax
;        ret
;
;
        END


