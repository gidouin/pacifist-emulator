COMMENT ~
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
ณ Events Processing                                                        ณ
ณ                                                                          ณ
ณ      18/11/96  Started a new events processing scheme                    ณ
ณ      01/01/96  Added FDC interrupt                                       ณ
ณ      17/01/96  Added HBL interrupt                                       ณ
ณ       5/02/96  MFP Timers A & B modified, Added Timer D                  ณ
ณ      26/02/96  IOPL ok after interrupts                                  ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
~
        IDEAL



FromEvents EQU 1                                ; supress EXTRN warnings

MFP_TIMERA      EQU 13
MFP_TIMERB      EQU 8
MFP_FDC         EQU 7
MFP_ACIA        EQU 6
MFP_TIMERC      EQU 5
MFP_TIMERD      EQU 4
MFP_BLITTER     EQU 3

        INCLUDE "simu68.inc"
        INCLUDE "chips.inc"
        INCLUDE "profile.inc"

        EXTRN Keyboard_Wait : DWORD
        EXTRN Keyboard_ShiftBuffer : NEAR

        EXTRN Periodic_Mouse :    NEAR
        EXTRN Periodic_Joystick : NEAR

;        EXTRN mfp_acknoledge : NEAR
        EXTRN mfp_request : NEAR

        EXTRN isSTE : DWORD
        PUBLIC shifter_modulo
        PUBLIC IsMonochrome

        DATASEG

        EXTRN Cycles_Calculation : DWORD
        EXTRN IsPrefetch : DWORD

        PUBLIC Nb_Cycles           ;Nb of cycles elapsed
        PUBLIC Total_Raster

        CODESEG

;       PUBLIC It_s_Event_Time
       PUBLIC Periodic_RasterLine


        EXTRN total_cycles : DWORD

       EXTRN timer_read : NEAR

MACRO alignmax
        align 4
       ENDM

        DATASEG

        PUBLIC low_overscan
        PUBLIC prev_low_overscan
        PUBLIC visible_rasters
        PUBLIC lowraster_max
        PUBLIC Total_RasterLines
        PUBLIC Nb_RasterLines_Last_VBL

        EXTRN   PTR_Make_Screen_Line : dword
        EXTRN   toto : dword
        PUBLIC waitfdc
        PUBLIC  Relative_Speed
        EXTRN   Just_Enter_68000 : DWORD


;**************************** shifter structure ********************

        public struct_work_start, struct_work_end, struct_work_size

STRUCT_WORK_START:

lowraster_max                   dd      0fbh
prev_low_overscan               dd      0       ;lower overscan previous
low_overscan                    dd      0       ;lower overscan befire
visible_rasters                 dd      0
RasterLine                      dd      0
Nb_Cycles_Full                  dd      0
Nb_Cycles                       dd      0
Total_Raster                    dd      0
Nb_RasterLines_Last_VBL         dd      0
Total_RasterLines               dd      0
waitfdc                         dd      0
SkipVBL                         dd      0
waitacia                        dd      0
wait_50hz                       dd      0
must_call_make_line             dd      0
Timer_At_VBL_End                dd      0
Timer_At_VBL_Start              dd      0
Timer_During_128VBLs            dd      0
List_Timers_During_VBL          dd      128 dup (0)
nb_Timers_During_VBL            dd      0
Relative_Speed                  dd      0
Timer_C_Cumul                   dd      0
Timer_B_Cumul                   dd      0
Timer_D_Cumul                   dd      0
PaletteUpdate                   dd      0       ; 16 bits for each colors
ST_Palette                      dd      8 dup (0)
ST_Screen_PTR                   dd      0
ST_Screen_PTR_current           dd      0
VideoModeReg                    dd      0
nbVideoModeChanges              dd      0
shifter_modulo                  dd      0
nbrasterstilltimerc             dd      74
IsMonochrome                    dd      0

STRUCT_WORK_END:

struct_work_size        dd offset STRUCT_WORK_END - offset STRUCT_WORK_START

        public st_palette
        public paletteupdate
        public st_screen_ptr
        public st_screen_ptr_current
        public videomodereg
        public nbvideomodechanges

        extrn mfp : byte


        IFNDEF DEBUG

        EXTRN   Return_Step : NEAR
        EXTRN   Return_Step_n : NEAR
        EXTRN   Return_Step_TURBO : NEAR
        ENDIF

        ;extrn Timer_Works : near

        public wait_50hz

        extrn dont_trigger_fdc : dword

        EXTRN RefreshRate : dword

        EXTRN _TRACE0 : dword

        EXTRN nb_redrawn_screen : dword
        EXTRN redrawing_screen : dword


        PUBLIC   ST_Screen_PTR
        PUBLIC   ST_Screen_PTR_Current

        PUBLIC RasterLine

        EXTRN   rasters_till_periodic_FDC : DWORD
        EXTRN volume_Buffer : dword
        EXTRN nbVolumeEntries : dword
        EXTRN PSGRegs : BYTE

        CODESEG

        EXTRN YMrecord : near

        EXTRN   Make_Screen_Line0 : near

        EXTRN   Periodic_FDC : NEAR


        EXTRN OUTdebug : NEAR

MACRO LOGMSG msg_ptr
        IFDEF DEBUG
        pushad
        push    OFFSET msg_ptr
        call    OUTdebug
        add     esp,4
        popad
        ENDIF
ENDM




MACRO   Process_STOP level
        LOCAL @@continue_stop,@@nostop

        test    [State_68000],STATE_STOP
        jz      @@nostop
        cmp     [Wait_Stop],level
        ja      @@continue_stop

        or      [State_68000],STATE_QUITSTOP
        cmp     [Wait_Stop],level
        jne     @@nostop
@@continue_stop:
        Next    4
        ;NextDirect
@@nostop:
        ENDM

        extrn do_dumpscreen : near

totobo  dd      0


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                             PERIODIC 128
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

;ACTIVE_EVENT_RASTER   EQU       00000001h ;mask in Active_Events
;ACTIVE_EVENT_TIMERA   EQU       00000002h ;mask in Active_Events

        ;Active_Events :        DWORD with active events mask
        ;next_event   : Address of next event routine
        ;events          dd     MAX_EVENTS dup (Tevent)

;PROC It_s_Event_Time NEAR
;
;        Next    0
;        ENDP
;
;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                             TIMERS / VBL
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;
        PUBLIC event_mfp_triggered
        EXTRN mfp_acknoledge : NEAR
;
PROC event_mfp_triggered NEAR
        mov     eax,[ebp+base.events_mask]

        cmp     [ebp+base.IOPL],7
        je      @@nothing

;;        ;------------------------------------- TIMER A
;
;        test    eax,MASK_TIMERA
;        jz short @@NoTimerA
;
;        Process_STOP 6
;        cmp     [ebp+base.IOPL],6
;        ja      @@notimera
;
;        mov     eax,MFP_TIMERA
;        push    eax
;        call    mfp_acknoledge
;        add     esp,4
;
;        xor     [ebp+base.events_mask],MASK_TIMERA
;
;        mov     [ebp+base.New_IOPL],6
;        mov     eax,_EXCEPTION_TIMERA
;        jmp     Trigger_Exception
;@@NoTimerA:
;        ;------------------------------------- TIMER B
;
;        test    eax,MASK_TIMERB
;        jz  short @@NoTimerB
;
;        Process_STOP 6
;        cmp     [ebp+base.IOPL],6
;        ja      @@notimerb
;
;        mov     eax,MFP_TIMERB
;        push    eax
;        call    mfp_acknoledge
;        add     esp,4
;
;        xor     [ebp+base.events_mask],MASK_TIMERB
;        mov     [ebp+base.New_IOPL],6
;        mov     eax,_EXCEPTION_TIMERB
;        jmp     Trigger_Exception
;
;        ;------------------------------------- TIMER C
;
;@@NoTimerB:
;

;************************************************ ACIA

        test    eax,MASK_ACIA
        jz short @@NoACIA

        Process_STOP 6
        cmp     [ebp+base.IOPL],6
        ja      @@notimerc

        dec     [waitacia]
        jns     @@NoACIA
        mov     [waitacia],3

       mov     eax,MFP_ACIA
        push    eax
        call    mfp_acknoledge
        add     esp,4

        xor     [ebp+base.events_mask],MASK_ACIA
        mov     [ebp+base.New_IOPL],7
        mov     eax,_EXCEPTION_ACIA
        jmp     Trigger_Exception
@@NoACIA:

;************************************************ TIMER C

        test    eax,MASK_TIMERC
        jz short @@NoTimerC

        Process_STOP 6
        cmp     [ebp+base.IOPL],6
        ja      @@notimerc

        mov     eax,MFP_TIMERC
        push    eax
        call    mfp_acknoledge
        add     esp,4

        xor     [ebp+base.events_mask],MASK_TIMERC
        mov     [ebp+base.New_IOPL],7
        mov     eax,_EXCEPTION_TIMERC
        jmp     Trigger_Exception
@@NoTimerC:
;************************************************ FDC



;
;        ;------------------------------------- TIMER D
;
;        test    eax,MASK_TIMERD
;        jz short @@NoTimerD
;
;        Process_STOP 6
;        cmp     [ebp+base.IOPL],6
;        ja      @@notimerd
;
;        mov     eax,MFP_TIMERD
;        push    eax
;        call    mfp_acknoledge
;        add     esp,4
;
;        xor     [ebp+base.events_mask],MASK_TIMERD
;        mov     [ebp+base.New_IOPL],6
;        mov     eax,_EXCEPTION_TIMERD
;        jmp     Trigger_Exception
;@@NoTimerD:
;
;        ;------------------------------------- VBL
;
;        test    eax,MASK_VBL
;        jz short @@NoVBL
;
;        Process_STOP 3
;        cmp     [ebp+base.IOPL],3
;        ja      @@NoVBL                         ;VBL is IOPL 4
;
;        xor     [ebp+base.events_mask],MASK_VBL
;        mov     [ebp+base.New_IOPL],4
;        mov     eax,_EXCEPTION_VBL
;
;        jmp     Trigger_Exception
;@@NoVBL:
@@nothing:
        Next    0
;        NextDirect
ENDP

        PUBLIC event_timera
        PUBLIC event_timerb
        PUBLIC event_timerc
        PUBLIC event_timerd
       PUBLIC Next_Event

       EXTRN event_cycles_2_go : DWORD
;       EXTRN event_mask : DWORD


PROC Next_Event NEAR
;        push    eax     ;keep cycles of current instruction
;
;        add     [event_cycles_2_go],100000
;
;
;        pop     eax
;        sub     [ebp+BASE.cycles_2_go],eax
;        js      Periodic_RasterLine
        Next    0
        ENDP
        ;.....          ;and now to periodic_rasterline

        extrn timera_cycles_2_go : dword
        extrn timerb_cycles_2_go : dword
        extrn timerc_cycles_2_go : dword
        extrn timerd_cycles_2_go : dword


        extrn event_timer_a_c : near
        extrn event_timer_b_c : near
        extrn event_timer_c_c : near
        extrn event_timer_d_c : near

PROC  event_timera NEAR
        pushad
        push    es
        push    ds
        pop     es
        call    event_timer_a_c
        pop     es
        popad

        sub     [timerb_cycles_2_go],eax
        js      event_timerb
        sub     [timerc_cycles_2_go],eax
        js      event_timerc
        sub     [timerd_cycles_2_go],eax
        js      event_timerd
        sub     [ebp+BASE.cycles_2_go],eax
        js      Periodic_RasterLine
        Next    0
        ENDP

PROC  event_timerb NEAR
        pushad
        push    es
        push    ds
        pop     es
        call    event_timer_b_c
        pop     es
        popad

        sub     [timerc_cycles_2_go],eax
        js      event_timerc
        sub     [timerd_cycles_2_go],eax
        js      event_timerd
        sub     [ebp+BASE.cycles_2_go],eax
        js      Periodic_RasterLine
        Next    0
        ENDP

PROC  event_timerc NEAR
        pushad
        push    es
        push    ds
        pop     es
        call    event_timer_c_c
        pop     es
        popad

        sub     [timerd_cycles_2_go],eax
        js      event_timerd
        sub     [ebp+BASE.cycles_2_go],eax
        js      Periodic_RasterLine
        Next    0
        ENDP

PROC  event_timerd NEAR
        pushad
        push    es
        push    ds
        pop     es
        call    event_timer_d_c
        pop     es
        popad

        sub     [ebp+BASE.cycles_2_go],eax
        js      Periodic_RasterLine
        Next    0
        ENDP

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                      PERIODIC RASTERLINE
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ


PROC Periodic_RasterLine NEAR

        mov     eax,[Cycles_Per_RasterLine]
        add     [total_cycles],eax
        add     [ebp+BASE.Cycles_this_Raster],eax
        add     [ebp+BASE.Cycles_2_Go],eax

        cmp     [Keyboard_Wait],0
        je      @@no_kbd_shift
        dec     [Keyboard_Wait]
        jne     @@no_kbd_shift
        push    esi ebp
        call    Keyboard_ShiftBuffer
        pop     ebp esi
@@no_kbd_shift:

        extrn do_blitter : near
        extrn must_do_blitter : dword

        cmp     [must_do_blitter],1
        jnz     @@nob
        pushad
        call    Do_blitter
        popad
        mov     [must_do_blitter],0
        and     [memio+0a3ch],7fh
@@nob:
        cmp     [rasters_till_periodic_FDC],0
        je      @@noperiodicFDC
        dec     [rasters_till_periodic_FDC]
        jne     @@noperiodicFDC
        call    Periodic_FDC
@@noperiodicFDC:

        IFNDEF DEBUG
        cmp     [_TRACE0],0
        jnz     @@trace
        cmp     [ebp+base.Offset_Next],OFFSET Return_Step
        jz      @@trace
        test    [isPrefetch],1
        jnz     @@trace
        mov     [ebp+base.offset_Next],OFFSET Return_Step_Turbo
@@trace:
        ENDIF

        mov     ebx,[nbVolumeEntries]
        cmp     ebx,511
        ja      @@plu
        mov     eax,[DWORD PTR PSGRegs+8]       ;Vol A,B,C
        and     eax,000f0f0fh
        inc     [nbVolumeEntries]
        mov     [volume_buffer+ebx*4],eax
@@plu:
        mov     eax,[Cycles_Per_RasterLine]
        sub     [thisraster_cycles],eax
        add     [Nb_Cycles_Full],eax
        add     [Cycles_Calculation],eax        ; resetted every second

        cmp     [RasterLine],0h
        jnz     @@nonewvbl

;-------------------------------------------------------------- Raster Line 0

        mov     eax,[st_screen_ptr]
        mov     [st_screen_ptr_current],eax

        test    [YMrecording],1
        jz      @@noym

        push    esi ebp
        call    YMrecord
        pop     ebp esi
@@noym:
        test    [ebp+BASE.events_mask],MASK_PTRSCR
        jz      @@nodump
        xor     [ebp+BASE.events_mask],MASK_PTRSCR; or MASK_DUMPSCREEN
        pushad
        push ds es fs gs

        call do_dumpscreen

        pop gs fs es ds
        popad
@@nodump:

        ;--------------- SCREEN ----------

        dec     [SkipVBL]
        sets    [BYTE PTR must_call_make_line]
        jns     @@firstline                     ;test refreshrate

                ;---- low overscan

        mov     eax,0fbh
        cmp     [low_overscan],3
        jnz     @@noover
        add     eax,50
        cmp     [prev_low_overscan],3
        je      @@over
;        mov     [already_st_video],0
        jmp     @@over
@@noover:
        cmp     [prev_low_overscan],3
        jne     @@over
;        mov     [already_st_video],0
@@over:
        mov     [lowraster_max],eax

                ;-----

        mov     eax,[RefreshRate]
        dec     eax
        mov     [SkipVBL],eax

        mov     [redrawing_screen],1            ;we're redrawing screen
        push    esi ebp
        call    Make_Screen_Line0
        pop     ebp esi
        mov     [redrawing_screen],0            ;we're no more

        mov     eax,[low_overscan]
        mov     [prev_low_overscan],eax
        mov     [low_overscan],0
        mov     [visible_rasters],0
        inc     [nb_redrawn_screen]
        jmp     @@firstline

;----------------------------------------------------------------------------

@@nonewvbl:

        cmp     [RasterLine],34h
        jb      @@firstline
        mov     eax,[lowraster_max]
        cmp     [RasterLine],eax
        ja      @@firstLine

        inc     [visible_rasters]

        cmp     [must_call_make_line],0         ; depends on refresh screen
        jz      @@no_line_mode


        call    [PTR_Make_Screen_Line]
@@no_line_mode:
        add     [ST_Screen_PTR_Current],160
        mov     ebx,[shifter_modulo]
        mov     eax,[modulo]
        shl     ebx,3
        add     eax,ebx
        add     [ST_Screen_PTR_Current],eax
@@firstline:


        EXTRN timers_on_rasterline : NEAR

;;;;---------------------- new mfp tempo
        pushad
        push    es
        push    ds
        pop     es

        call    timers_on_rasterline

        pop     es
        popad
;;;;----------------------



        inc     [RasterLine]
        inc     [Total_Raster]
        inc     [Nb_RasterLines_Last_VBL]

        cmp     [NativeSpeed],0
        je      @@atarispeed
        ;---------------------------------------------------- NATIVE SPEED

        jmp     @@nativespeed

@@atarispeed:   ;------------------------------------------- ATARI SPEED

        cmp     [RasterLine],313                ; is it last rasterline?
        jb      @@SameFrame

        cmp     [Just_Enter_68000],0
        jnz     @@www

        ;-------- wait at least than a VBL is processed...

        call    Timer_Read
        mov     [Timer_At_VBL_End],eax
        sub     eax,[Timer_At_VBL_Start]

        mov     ebx,[nb_Timers_During_VBL]
        inc     [nb_Timers_During_VBL]
        and     ebx,07fh

        add     [Timer_During_128VBLs],eax
        mov     edx,[List_Timers_During_VBL+ebx*4]
        mov     [List_Timers_During_VBL+ebx*4],eax
        sub     [Timer_During_128VBLs],edx

        mov     eax,0
        mov     edx,128*4
        mov     ecx,[Timer_During_128VBLs]
        div     ecx
        mov     [Relative_Speed],eax
@@www:
        cmp     [wait_50hz],0
        je      @@www
        mov     [wait_50hz],0
        mov     [Just_Enter_68000],0

        mov     [RasterLine],0
        or      [ebp+base.events_mask],MASK_VBL

        call    Timer_Read
        mov     [Timer_At_VBL_Start],eax


@@SameFrame:

@@nativespeed:
;        call    Periodic_MFP_Timer_C
        test    [RasterLine],80h
        jz      @@nomooz

        push    ebp esi
        call    Periodic_Joystick
        pop     esi ebp
@@dotestmouse:
        push    ebp esi
        call    Periodic_Mouse
        pop     esi ebp
        and     [ebp+base.events_mask],not MASK_MOUSE
@@nomooz:
        test    [ebp+base.events_mask],MASK_MOUSE
        jnz     @@dotestmouse

;------------------------------------------------------- TIMER B

;        call    Periodic_MFP_Timer_B

;------------------------------------------------------- TIMER A

;        call    Periodic_MFP_Timer_A
;
;------------------------------------------------------- TIMER D

;        call    Periodic_MFP_TIMER_D

;------------------------------------------------------- EVENTS DISPATCHER

events_processing:

        mov     eax,[ebp+base.events_mask]               ; mask of events
        or      eax,eax
        jz      @@NoIRQ_exceptHBL

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                                      FDC
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

        test    eax,MASK_FDC2
        jnz     @@nofdc2

        dec     [waitfdc]
        jns     @@noFDC2

        mov     [waitfdc],200                   ;2000
        and     [byte ptr mfp+0],0dfh           ;GPIP
        xor     [ebp+base.events_mask],MASK_FDC2

        ;test    [dont_trigger_fdc],1
        ;jnz     @@noFDC2

        pushad
        push    es
        push    ds
        pop     es
        mov     eax,MFP_FDC
        push    eax
        call    mfp_request
        add     esp,4
        pop     es
        popad
        jmp     @@nofdc
@@nofdc2:

        test    eax,MASK_FDC
        jz      @@NoFDC

;        test    [dont_trigger_fdc],1
;        jnz     @@noFDC
;        and     [memio+7a01h],0dfh ;        GPIP bit 5 = 0 : DMA Irq.

        cmp     [ebp+base.IOPL],7
        je      @@noFDC

        xor     [ebp+base.events_mask],MASK_FDC

        mov     eax,MFP_FDC
        push    eax
        call    mfp_acknoledge
        add     esp,4

;        test    [memio+_MFP_IERB],080h
;        jz      @@noFDC
;        test    [memio+_MFP_IMRB],080h
;        jz      @@noFDC

        Process_STOP 6

        mov     [ebp+base.New_IOPL],7
        mov     eax,_EXCEPTION_FDC
        jmp     Trigger_Exception

@@noFDC:

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                                     ACIA
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;
;        test    eax,MASK_ACIA                   ; ************** ACIA-Keyboard
;        jz short NoACIA
;
;        dec     [waitacia]
;        jns     NoACIA
;        mov     [waitacia],3
;
;        Process_STOP 6
;
;        cmp     [ebp+base.IOPL],6
;        ja      @@IOPL_is_7                     ; no need to test the rest!
;
;        xor     [ebp+base.events_mask],MASK_ACIA
;
;        mov     [ebp+base.New_IOPL],7                    ; ACIA is IOPL 6
;        mov     eax,_EXCEPTION_ACIA
;        jmp     Trigger_Exception

;NoACIA:
;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                                      VBL
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

        test    eax,MASK_VBL                    ; ************** VBL
        jz short @@NoVBL


        xor     [ebp+base.events_mask],MASK_VBL

        Process_STOP 3

        cmp     [ebp+base.IOPL],3
        ja      @@NoVBL                         ;VBL is IOPL 4

        mov     [ebp+base.New_IOPL],4
        mov     eax,_EXCEPTION_VBL

        jmp     Trigger_Exception
@@NoVBL:
;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                                  TIMER C
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;
;        test    eax,MASK_TIMERC
;        jz short NoTimerC
;
;
;        xor     [ebp+base.events_mask],MASK_TIMERC
;
;        Process_STOP 6
;
;        cmp     [ebp+base.IOPL],6
;        ja      @@IOPL_is_7
;
;      ;  mov     dl,[memio+7a11h]              ; fffa11 & 0x20
;      ;  and     dl,20h
;      ;  jnz     NoTimerC
;      ;  or      [memio+7a11h],20h
;
;        mov     [ebp+base.New_IOPL],7
;        mov     eax,_EXCEPTION_TIMERC
;        jmp     Trigger_Exception
;NoTimerC:

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                                  TIMER B
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;
;        test    eax,MASK_TIMERB
;        jz  short @@NoTimerB
;
;        xor     [ebp+base.events_mask],MASK_TIMERB
;
;        Process_STOP 6
;
;        cmp     [ebp+base.IOPL],6
;        ja      @@IOPL_is_7
;
;        mov     [ebp+base.New_IOPL],7
;        mov     eax,_EXCEPTION_TIMERB
;        jmp     Trigger_Exception
;
;@@NoTimerB:
;
;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                                  TIMER A
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;
;        test    eax,MASK_TIMERA
;        jz short @@NoTimerA
;
;
;        xor     [ebp+base.events_mask],MASK_TIMERA
;        Process_STOP 6
;
;        cmp     [ebp+base.IOPL],6
;        ja      @@IOPL_is_7
;
;        mov     [ebp+base.New_IOPL],7
;        mov     eax,_EXCEPTION_TIMERA
;        jmp     Trigger_Exception
;@@NoTimerA:
;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                                  TIMER D
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;
;        test    eax,MASK_TIMERD
;        jz short @@NoTimerD
;        xor     [ebp+base.events_mask],MASK_TIMERD
;
;        Process_STOP 6
;
;        cmp     [ebp+base.IOPL],6
;        ja      @@IOPL_is_7
;
;        mov     [ebp+base.New_IOPL],7
;        mov     eax,_EXCEPTION_TIMERD
;        jmp     Trigger_Exception
;@@NoTimerD:
;
;
;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ                                                                      HBL
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

@@NoIRQ_exceptHBL:

        Process_STOP 2

        cmp     [ebp+base.IOPL],2
        ja      @@NoHBL                         ;HBL is IOPL 2

        mov     [ebp+base.New_IOPL],3
        mov     eax,_EXCEPTION_HBL
        jmp     Trigger_Exception
@@NoHBL:
@@IOPL_is_7:
        Next 0
        ENDP



;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ MFP WORKS
;บ
;บ    TIMER A in Delay Mode
;บ    TIMER B in Events count Mode (HBL)
;บ
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

;------------------------------------------------------------------ TIMER A
;
;Periodic_MFP_Timer_A:
;        cmp     [Timer_A_MODE],TIMERMODE_DELAY
;        jne     @@Timer_A_notDelayMode
;
;        dec     [BYTE PTR memio+_MFP_TADR]
;
;        cmp     [Timer_A_Enabled],0
;        je      @@endA
;        cmp     [Timer_A_Masked],0
;        je      @@endA
;
;;        cmp     [Timer_A_Mode],TIMERMODE_DELAY  ;only delay mode
;;        jnz     @@endA
;
;        mov     eax,[Timer_A_Freq]
;        add     [Timer_A_Cumul],eax
;        cmp     [Timer_A_Cumul],313*50
;        jb      @@endA
;        sub     [Timer_A_Cumul],313*50
;
;        or      [ebp+base.events_mask],MASK_TIMERA       ;timer A ok
;@@endA:
;@@Timer_A_notDelayMode:
;        ret
;
;;------------------------------------------------------------------ TIMER B
;
;Periodic_MFP_Timer_B:
;        cmp     [Timer_B_Mode],TIMERMODE_EVENTCOUNT
;        jb      @@BnoHBL                                ;Event Count & Signal
;
;        mov     eax,[RasterLine]
;        cmp     eax,033h
;        jb      @@endB
;        cmp     eax,0fah
;        ja      @@endB                  ;200 lines only
;
;        cmp     [Timer_B_Prediv],1
;        jnz     @@Timer_B_Predivised
;        mov     eax,[Timer_B_PredivI]
;        mov     [Timer_B_Prediv],eax
;
;        cmp     [memio+_MFP_TBDR],1
;        jnz     @@notB
;
;        mov     eax,[Timer_B_Data]
;        mov     [BYTE PTR memio+_MFP_TBDR],al
;
;        cmp     [Timer_B_Enabled],0
;        je      @@quitB
;        cmp     [Timer_B_Masked],0
;        je      @@quitB
;
;        or      [ebp+base.events_mask],MASK_TIMERB
;        jmp     @@quitB
;@@notB:
;        dec     [memio+_MFP_TBDR]
;        jmp     @@quitB
;
;@@Timer_B_Predivised:
;        dec     [Timer_B_Prediv]
;        jmp     @@quitB
;@@BnoHBL:
;        dec     [BYTE PTR memio+_MFP_TBDR]
;
;
;-------------- essai
;
;        cmp     [Timer_B_Enabled],0
;        je      @@endbb
;        cmp     [Timer_B_Masked],0
;        je      @@endbb
;
;        mov     eax,[Timer_B_Freq]
;        add     [Timer_B_Cumul],eax
;        cmp     [Timer_B_Cumul],313*50
;        jb      @@endbb
;        sub     [Timer_B_Cumul],313*50
;
;        or      [ebp+base.events_mask],MASK_TIMERB       ;timer B
;@@endbb:
;
;
;-------------- fin essai
;
;@@endB:
;
;@@quitb:
;        ret
;
;;------------------------------------------------------------------ TIMER C
;
;Periodic_MFP_Timer_C:
;        dec     [BYTE PTR memio+_MFP_TCDR]
;        cmp     [NativeSpeed],0
;        jne     @@endC
;
;        cmp     [Timer_C_Enabled],0
;        je      @@endC
;        cmp     [Timer_C_Masked],0
;        je      @@endC
;
;        mov     eax,[Timer_C_Freq]
;        add     [Timer_C_Cumul],eax
;        cmp     [Timer_C_Cumul],313*50
;        jb      @@endC
;        sub     [Timer_C_Cumul],313*50
;
;        or      [ebp+base.events_mask],MASK_TIMERC
;@@endC:
;        ret
;;------------------------------------------------------------------ TIMER D
;
;Periodic_MFP_Timer_D:
;        dec     [memio+_MFP_TDDR]
;
;        cmp     [Timer_D_Enabled],0
;        je      @@endD
;        cmp     [Timer_D_Masked],0
;        je      @@endD
;
;        mov     eax,[Timer_D_Freq]
;        add     [Timer_D_Cumul],eax
;        cmp     [Timer_D_Cumul],313*50
;        jb      @@endD
;        sub     [Timer_D_Cumul],313*50
;
;        or      [ebp+base.events_mask],MASK_TIMERD       ;timer D
;@@endD:
;        ret
;
;
;now_over        db      'now overscan',0
;now_noover      db      'now non overscan',0
;

;        CODESEG
;
;        public there_is_an_mfp_event
;        public there_is_an_mfp_interrupt
;        extrn mfp_timer_reached : near
;
;there_is_an_mfp_event:
;
;        pushad
;        call    mfp_timer_reached
;        popad
;        ret
;
;
;there_is_an_mfp_interrupt:
;        mov     eax,[ebp+base.events_mask]
;
;        cmp     [ebp+base.IOPL],7
;        je      @@nothing
;
;;;        ;------------------------------------- TIMER A
;;
;;        test    eax,MASK_TIMERA
;;        jz short @@NoTimerA
;;
;;        Process_STOP 6
;;        cmp     [ebp+base.IOPL],6
;;        ja      @@notimera
;;
;;        mov     eax,MFP_TIMERA
;;        push    eax
;;        call    mfp_acknoledge
;;        add     esp,4
;;
;;        xor     [ebp+base.events_mask],MASK_TIMERA
;;
;;        mov     [ebp+base.New_IOPL],6
;;        mov     eax,_EXCEPTION_TIMERA
;;        jmp     Trigger_Exception
;;@@NoTimerA:
;;        ;------------------------------------- TIMER B
;;
;;        test    eax,MASK_TIMERB
;;        jz  short @@NoTimerB
;;
;;        Process_STOP 6
;;        cmp     [ebp+base.IOPL],6
;;        ja      @@notimerb
;;
;;        mov     eax,MFP_TIMERB
;;        push    eax
;;        call    mfp_acknoledge
;;        add     esp,4
;;
;;        xor     [ebp+base.events_mask],MASK_TIMERB
;;        mov     [ebp+base.New_IOPL],6
;;        mov     eax,_EXCEPTION_TIMERB
;;        jmp     Trigger_Exception
;;
;;        ;------------------------------------- TIMER C
;;
;;@@NoTimerB:
;;
;        test    eax,MASK_TIMERC
;        jz short @@NoTimerC
;
;        Process_STOP 6
;        cmp     [ebp+base.IOPL],6
;        ja      @@notimerc
;
;        mov     eax,MFP_TIMERC
;        push    eax
;        call    mfp_acknoledge
;        add     esp,4
;
;        xor     [ebp+base.events_mask],MASK_TIMERC
;        mov     [ebp+base.New_IOPL],6
;        mov     eax,_EXCEPTION_TIMERC
;        jmp     Trigger_Exception
;@@NoTimerC:
;;
;;        ;------------------------------------- TIMER D
;;
;;        test    eax,MASK_TIMERD
;;        jz short @@NoTimerD
;;
;;        Process_STOP 6
;;        cmp     [ebp+base.IOPL],6
;;        ja      @@notimerd
;;
;;        mov     eax,MFP_TIMERD
;;        push    eax
;;        call    mfp_acknoledge
;;        add     esp,4
;;
;;        xor     [ebp+base.events_mask],MASK_TIMERD
;;        mov     [ebp+base.New_IOPL],6
;;        mov     eax,_EXCEPTION_TIMERD
;;        jmp     Trigger_Exception
;;@@NoTimerD:
;;
;;        ;------------------------------------- VBL
;;
;;        test    eax,MASK_VBL
;;        jz short @@NoVBL
;;
;;        Process_STOP 3
;;        cmp     [ebp+base.IOPL],3
;;        ja      @@NoVBL                         ;VBL is IOPL 4
;;
;;        xor     [ebp+base.events_mask],MASK_VBL
;;        mov     [ebp+base.New_IOPL],4
;;        mov     eax,_EXCEPTION_VBL
;;
;;        jmp     Trigger_Exception
;;@@NoVBL:
;@@nothing:
;;        NextDirect
;;ENDP
;        jmp     [ebp+base.offset_next_direct]


        END

