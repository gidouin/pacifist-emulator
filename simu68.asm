COMMENT ~
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ Initialisation of Emulation                                              ³
³                                                                          ³
³      25/06/96  Converted all code to TASM IDEAL mode                     ³
³      29/06/96  "Next" sequence rewritten                                 ³
³      31/06/96  Patch for Xbios calls to disk                             ³
³      05/08/96  New ROM/Chips access routines                             ³
³      17/11/96  break on cycles more acute                                ³
³      26/12/96  added BIOS level SERIAL communications                    ³
³      30/12/96  added STOP mnemonic support                               ³
³      01/01/97  added TRACE mode                                          ³
³      04/03/97  fixed ILLEGAL stackframe                                  ³
³      26/03/97  68000 Prefetch added                                      ³
³      29/03/97  Code remodelling with structure                           ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
~
        IDEAL

FromSimu68 EQU 1                                ; supress EXTRN warnings

        INCLUDE "simu68.inc"
        INCLUDE "chips.inc"
        INCLUDE "profile.inc"


        DATASEG

        EXTRN is68030 : dword
        EXTRN Nb_Cycles     : dword
        EXTRN Total_Raster  : dword


        EXTRN init_68030 : NEAR

        PUBLIC thisraster_cycles
        PUBLIC  opcode_cycles
;        PUBLIC next_event_cycles
;        PUBLIC Next_Event
        PUBLIC Active_Events


        ;EXTRN mfp_triggered : NEAR
        EXTRN IsBreakOnCycles : DWORD

        EXTRN   IsTrappedGemdos : DWORD
        EXTRN   IsTrappedPexec  : DWORD

        PUBLIC  Instr_To_EA_Functions_B
        PUBLIC  Instr_To_EA_Functions_W
        PUBLIC  Instr_To_EA_Functions_L

;        PUBLIC _SUPERVISOR         ;68000 SR supervisor bit
;        PUBLIC _IOPL               ;68000 SR Interrupt Level
;        PUBLIC _IsException        ;Exception generated?
;        PUBLIC _ExceptionNumber    ;Exception number

        PUBLIC  HiByte_PC

        PUBLIC Illegal_PC

        PUBLIC IsPrefetch
        PUBLIC PrefetchPC
        PUBLIC PrefetchQueue
        PUBLIC PrefetchPC2
        PUBLIC PrefetchQueue2

        CODESEG

        EXTRN SystemXbios : NEAR
        EXTRN SystemGemdos: NEAR
        EXTRN SystemBios  : NEAR
        EXTRN SystemMediaChange : NEAR
        EXTRN SystemVDI : NEAR
        EXTRN SystemPrtOut : NEAR
        EXTRN SystemPrtStatus : NEAR

        EXTRN   Init_Instructions        : NEAR

        EXTRN   Init_Chips                      : NEAR
        EXTRN   ModeST : DWORD

        EXTRN Break_Raster : DWORD
        EXTRN IsBreakOnRaster : DWORD

        PUBLIC  LastEA

        PUBLIC Reset_68000
        PUBLIC Init_68000
        PUBLIC Step_68000
        PUBLIC Quit_68000
        PUBLIC Run_68000
        PUBLIC Direct_Rewrite_OK
        PUBLIC Convert_To_SR
        PUBLIC Convert_From_SR
        PUBLIC Trigger_Exception
        PUBLIC Trigger_BusError
        PUBLIC Trigger_AdressError
        PUBLIC Do_Privilege_Violation

        PUBLIC PrevPC_tbl
        PUBLIC PrevPC_cur

        PUBLIC  State_68000
        PUBLIC  Wait_STOP

        IFDEF DEBUG
         PUBLIC Test_Breakaccess_read
         PUBLIC Test_Breakaccess_write
        ENDIF

MACRO alignmax
        align 4
       ENDM

        PUBLIC   Return_Step
        PUBLIC   Return_Step_n

        IFNDEF DEBUG

        PUBLIC  Return_Step_TURBO

        ENDIF


;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;º
;º                                                         TEST BREAKACCESS
;º
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

IFDEF DEBUG

PROC Test_Breakaccess_read NEAR
        push    eax
        mov     eax,[Nb_Breakaccess]
@@allofit:
        cmp     [breakaccess_rw-1+eax],'w'
        je      @@nxtone
        cmp     edi,[breakaccess-4+eax*4]
        jnz     @@nxtone
        or      [ebp+base.events_mask], MASK_IsException
        mov     [ebp+base.ExceptionNumber],_EXCEPTION_BREAKACCESS
        jmp     @@contin
@@nxtone:
        dec     eax
        jnz     @@allofit
@@contin:
        pop     eax
        ret
        ENDP

PROC Test_Breakaccess_write NEAR
        push    eax
        mov     eax,[Nb_Breakaccess]
@@allofit:
        test    [breakaccess_rw-1+eax],'r'
        je      @@nxtone
        cmp     edi,[breakaccess-4+eax*4]
        jnz     @@nxtone
        or      [ebp+base.events_mask], MASK_IsException
        mov     [ebp+base.ExceptionNumber],_EXCEPTION_BREAKACCESS
        jmp     @@contin
@@nxtone:
        dec     eax
        jnz     @@allofit
@@contin:
        pop     eax
        ret
        ENDP


ENDIF


;***************************************************************************
;*
;*  Call all the Init_... functions for simulation of all opcodes
;*
;***************************************************************************


PROC Init_68000 NEAR
        push    ebp
        lea     ebp,[base_processor]

        lea     ebx,[Opcodes_Jump]
        mov     eax,OFFSET Illegal_Instruction
        xor     ecx,ecx
@@blk:  mov     [ebx+ecx*4],eax
        inc     cx
        jnz short @@blk

        mov     [ebp+basE.Offset_Next],OFFSET Return_Step
        mov     [ebp+base.Offset_Next_Direct],OFFSET Return_Step_Direct

        push    ebp
        call    Init_Instructions
        call    Init_Chips
        pop     ebp

        mov     [Opcodes_Jump+SystemPatchOpcode*4],OFFSET Do_SystemPatch
        mov     [Opcodes_Jump+4e73h*4],OFFSET Do_RTE
        mov     [Opcodes_Jump+4e72h*4],OFFSET Do_STOP
        mov     eax,0
@@linex:
        mov     [Opcodes_Jump+(0a000h*4)+eax*4],OFFSET Do_LineA
        mov     [Opcodes_Jump+(0f000h*4)+eax*4],OFFSET Do_LineF
        inc     eax
        cmp     eax,1000h
        jne short    @@linex

        test    [is68030],1
        jz      @@plain68000

        call    init_68030

@@plain68000:
        mov     eax,[Cycles_Per_RasterLine]
        ;mov     [ebp+base.CyclesLeft],eax
        mov     [thisraster_cycles],0
        mov     [Nb_Cycles_Full],0
        pop     ebp
        ret
        ENDP

Do_STOP:
        test    [State_68000],STATE_STOP
        jnz     @@dejaStop

        Check_Privilege                         ;must be in supervisor mode

        or      [State_68000],STATE_STOP
        and     [State_68000],not STATE_QUITSTOP

        call    Convert_TO_SR
        mov     ax,[es:esi]
        rol     ax,8
        and     eax,0700h
        and     [ebp+base.SR],0f8ffh
        or      [ebp+base.SR],eax
        shr     eax,8
        mov     [ebp+base.IOPL],eax
        mov     [ebp+base.New_IOPL],eax
        mov     [Wait_Stop],eax ;IOPL to wait for
        call    Convert_From_SR
@@noquit:
        sub     esi,2
        Next    4

@@dejaStop:
        test    [State_68000],STATE_QUITSTOP
        jz      @@noquit

        and     [State_68000],not (STATE_STOP or STATE_QUITSTOP)
        add     esi,2
        next 4

PROC Quit_68000 NEAR
        ret
        ENDP

PROC Reset_68000 NEAR
        push    eax ebx edx ebp
        lea     ebp,[base_processor]

        mov     eax,0f000h
        mov     [ds:ebp+7*4+base.A],eax
        mov     [ds:ebp+base.A7],eax
        mov     [ds:ebp+base.SR],2700h
        mov     eax,[TOSbase]


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov	eax,0fa2000h
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        mov     [ds:ebp+base.PC],eax

        mov     ebx,[memory_ram]

        mov     eax,[DWORD PTR memtos]
        mov     edx,[DWORD PTR memtos+4]
        mov     [DWORD PTR ebx],eax
        mov     [DWORD PTR ebx+4],edx

        mov     [State_68000],0

        mov     [ebp+BASE.Cycles_2_Go],1000
        mov     [ebp+BASE.Cycles_This_Raster],511

        ;pushad
        ;EXTRN init_mfp : near
        ;call    Init_MFP
        ;popad

        pop     ebp edx ebx eax
        ret
        ENDP

;*********************************************************************** STEP

        align 4

        DATASEG

Step_68000_trace        dd      0
Step_68000_trace0       dd      0


        CODESEG

;MACRO PERIODIC_ON_RETURN
;        LOCAL @@l, @@paslapeine, @@ouioui
;        cmp     [timer_cycle2go],0
;        jns      @@paslapeine
;        EXTRN   mfp_something_happens : NEAR
;        push    esi ebp
;        call    mfp_something_happens
;        pop     ebp esi
;@@paslapeine:
;        test    [ebp+base.events_mask],MASK_TIMERA or MASK_TIMERB or MASK_TIMERC or MASK_TIMERD or MASK_VBL
;        jnz     mfp_triggered
;@@ouioui:
;        ;cmp     ebx,[next_event_cycles]
;        ;jns     it_s_event_time
;@@l:
;ENDM
;
;MACRO PERIODIC_ON_RETURN2
;        mov     ebx,[thisraster_cycles]
;        mov     eax,[Cycles_Per_RasterLine]
;        cmp     eax,ebx
;        js      Periodic_RasterLine
;        ENDM
;
;        extrn there_is_an_mfp_event : near
;        extrn there_is_an_mfp_interrupt : near

;;MACRO PERIODIC_ON_RETURN
;;        LOCAL @@ll
;;        sub     [ebp+BASE.Cycles_2_Go],eax
;;        jns     @@ll
;;        call    there_is_an_mfp_event
;;@@ll:
;;        sub     [ebp+BASE.Cycles_This_Raster],eax
;;        js      Periodic_RasterLine
;;
;;        test    [ebp+BASE.events_mask],MASK_TIMERA or MASK_TIMERB or MASK_TIMERC or MASK_TIMERD
;;        jnz     there_is_an_mfp_interrupt
;;ENDM
;;

       EXTRN Next_Event : NEAR
       EXTRN event_cycles_2_go : DWORD
       ;EXTRN event_mask : DWORD

        extrn timera_cycles_2_go : dword
        extrn timerb_cycles_2_go : dword
        extrn timerc_cycles_2_go : dword
        extrn timerd_cycles_2_go : dword

        extrn event_timera : NEAR
        extrn event_timerb : NEAR
        extrn event_timerc : NEAR
        extrn event_timerd : NEAR
        extrn event_mfp_triggered : NEAR


MACRO PERIODIC_ON_RETURN
        LOCAL @@l

;        sub     [event_cycles_2_go],eax
;        js      Next_Event


	add	[optim],eax

        test    eax,eax
        jz      @@l

        sub     [timera_cycles_2_go],eax
        js      event_timera
        sub     [timerb_cycles_2_go],eax
        js      event_timerb
        sub     [timerc_cycles_2_go],eax
        js      event_timerc
        sub     [timerd_cycles_2_go],eax
        js      event_timerd

        sub     [ebp+BASE.cycles_2_go],eax
        js      Periodic_RasterLine

        test    [ebp+base.events_mask],MASK_TIMERA or MASK_TIMERB or MASK_TIMERC or MASK_TIMERD
        jnz     event_mfp_triggered

@@l:
       ENDM

PROC Step_68000 NEAR
        push    ebp es fs gs
        lea     ebp,[base_processor]
        mov     fs,[ramseg]

        mov     [ebp+base.Offset_Next],OFFSET Return_Step
        mov     [ebp+base.Offset_Next_Direct],OFFSET Return_Step_Direct
        and     [ebp+base.events_mask], not MASK_IsException
        mov     [Direct_Rewrite_OK],1

        call    Convert_From_SR

        mov     esi,[ebp+base.PC]
        mov     [prevpc],esi
        CheckPC

      IFDEF DEBUG
        mov     eax,[PC_Base]
        or      eax,esi                         ;modified
        mov     [adr_breakaccess],eax           ;for monitor to display adress

        mov     ebx,[PrevPC_cur]
        mov     [PrevPC_tbl+ebx*4],esi
        inc     ebx
        and     ebx,63
        mov     [PrevPC_cur],ebx

      ENDIF

        xor     eax,eax

        test    [isPrefetch],1
        jz      @@noprefetch2
        cmp     [PrefetchPC],esi
        jnz     @@noprefetch1
        mov     ax,[WORD PTR PrefetchQueue]
        jmp     @@prefetch
@@noprefetch1:
        mov     edx,[PrefetchPC]
        add     edx,2
        cmp     edx,esi
        jnz     @@noprefetch2
        mov     ax,[WORD PTR PrefetchQueue+2]
        jmp     @@prefetch
@@noprefetch2:
        mov     ax,[es:esi]
@@prefetch:
        mov     edx,[es:esi+2]          ;PREFETCH
        rol     ax,8
        add     esi,2
        xchg    [PrefetchQueue],edx     ;PREFETCH QUEUE
        mov     [PrefetchQueue2],edx
        mov     ecx,[PrefetchPC]
        mov     [PrefetchPC],esi
        mov     [PrefetchPC2],ecx


      IFDEF DEBUGPROFILE
        mov     edx,[isprofile]
        add     [profile+eax*4],edx
      ENDIF

        mov     [Opcode_cycles],0
        mov     [ebp+base.Cycles_Instruction],0
        jmp     [DWORD PTR Opcodes_Jump+eax*4]

Return_Step:
        PERIODIC_ON_RETURN
Return_Step_Direct:
        mov     eax,[_TRACE0]
        cmp     [_TRACE],0
        mov     [_TRACE],eax
        jz      Return_Trace
        mov     [ebp+basE.Offset_Next],OFFSET Return_Trace
        mov     [ebp+base.Offset_Next_Direct],OFFSET Return_Trace_Direct

        mov     eax,[ebp+base.IOPL]
        mov     [ebp+base.New_IOPL],eax

        mov     eax,_EXCEPTION_TRACE
        jmp     Trigger_Exception

Return_Trace:
Return_Trace_Direct:


;        mov     [CyclesLeft],ebp
        mov     eax,esi         ;modified
        or      eax,[PC_Base]
        mov     [ebp+base.PC],eax
        call    Convert_To_SR


;        mov     eax,[_TRACE]
;        mov     [Step_68000_trace],eax
;        mov     eax,[_TRACE0]
;        mov     [Step_68000_trace0],eax

        mov     eax,[Cycles_Per_RasterLine]
        ;mov     [thisraster_cycles],0
        add     eax,[Nb_Cycles_Full]
        mov     [Nb_Cycles],eax

      IFDEF DEBUG
        mov     [lastEA],edi
        mov     eax,[Nb_Breakpoints]
        or      eax,eax
        jz short     @@NoBreak
        mov     ecx,[PC_Base]
        lea     ebx,[breakpoints]
        or      ecx,esi                 ; modified
@@NxtBrk:
        cmp     ecx,[ebx]
        jnz short    @@NotThis

        or      [ebp+base.events_mask], MASK_IsException
        mov     [ebp+base.ExceptionNumber],_EXCEPTION_BREAKPOINT
        jmp short    @@NoBreak
@@NotThis:
        add     ebx,4
        dec     eax
        jnz short    @@NxtBrk
@@NoBreak:
      ENDIF

        pop    gs fs es ebp
        ret
        ENDP


;*********************************************************************** RUN

        CODESEG

        align 4

PROC Run_68000 NEAR
        push    ebp es fs gs

        lea     ebp,[base_processor]

        mov     [PrefetchPC],-1
        mov     fs,[ramseg]

        mov     [FakeException],0
        mov     [ModeST],1
        mov     [ebp+base.Offset_Next],OFFSET Return_Step_n
        mov     [ebp+base.Offset_Next_direct],OFFSET Return_Step_n_Direct
;        mov     [ebp+base.IsException],0
        and      [ebp+base.events_mask], not MASK_IsException
        mov     [Direct_Rewrite_OK],1

IFNDEF DEBUG
        test    [isPrefetch],1
        jnz     @@notr
        mov     [ebp+base.Offset_Next],OFFSET Return_Step_turbo  ;TURBO IF NO TRACE
        mov     [ebp+base.Offset_Next_direct],OFFSET Return_Step_turbo_Direct
        mov     eax,[_TRACE0]
        or      eax,[_TRACE]
        jz      @@notr
        mov     [ebp+base.Offset_Next],OFFSET Return_Step_n      ;IF Trace: Slow Mode
        mov     [ebp+base.OFfset_Next_Direct],OFFSET Return_Step_n_Direct
@@notr:
ENDIF

        call    Convert_From_SR
        mov     esi,[ebp+base.PC]
        CheckPC
        jmp     @@NextStep2     ;TRACE test at first

Return_Step_n:
        PERIODIC_ON_RETURN
Return_Step_n_Direct:
;        PERIODIC_ON_RETURN2


        mov     eax,[_TRACE0]
        cmp     [_TRACE],0
        mov     [_TRACE],eax
        jz      @@notrace1st
        mov     eax,[ebp+base.IOPL]
        mov     [ebp+base.New_IOPL],eax
        mov     eax,_EXCEPTION_TRACE
        jmp     trigger_exception
@@notrace1st:


        IFDEF GURU
                mov     eax,esi         ;modified
                or      eax,[PC_Base]
                mov     [ebp+base.PC],eax
                mov     [lastEA],edi

                mov     ebx,[PrevPC_cur]
                mov     [PrevPC_tbl+ebx*4],esi
                inc     ebx
                and     ebx,63
                mov     [PrevPC_cur],ebx

        ENDIF

        test    [ebp+base.events_mask], MASK_IsException or MASK_SoftReset or MASK_HardReset or MASK_UserBreak or MASK_DiskSelector or MASK_DoubleBus or MASK_DUMPSCREEN
        jnz     @@Abort

      IFDEF DEBUG

      test      [isBreakOnRaster],1
      jz        @@nobreakoncycles

      mov       eax,[Total_Raster]
      cmp       [Break_Raster],eax
      ja        @@nobreakoncycles

;      mov       [ebp+base.IsException],1
      or      [ebp+base.events_mask], MASK_IsException
      mov       [ebp+base.ExceptionNumber],_EXCEPTION_CYCLES
      jmp       @@abort

@@nobreakoncycles:
        mov     eax,[Nb_Breakpoints]
        or      eax,eax
        jz short     @@NoBreak
        mov     ecx,[PC_Base]
        lea     ebx,[breakpoints]
        or      ecx,esi                 ; modified
@@NxtBrk:
        cmp     ecx,[ebx]
        jnz short    @@NotThis

;       mov     [ebp+base.IsException],1
        or      [ebp+base.events_mask], MASK_IsException
        mov     [ebp+base.ExceptionNumber],_EXCEPTION_BREAKPOINT
        jmp     @@Abort
@@NotThis:
        add     ebx,4
        dec     eax
        jnz short    @@NxtBrk
      ENDIF

@@NoBreak:
@@NextStep:
        test     [ebp+base.Events_Mask],MASK_ILLEGALACCESS
        jnz     Trigger_BusError

@@nextstep2:
;        mov     eax,[_TRACE0]
;        cmp     [_TRACE],0
;        mov     [_TRACE],eax
;        jz      @@notrace
;
;        mov     eax,[_IOPL]
;        mov     [new_IOPL],eax
;
;        mov     eax,_EXCEPTION_TRACE
;        jmp     trigger_exception
;@@notrace:
@@NextStep1:

        xor     eax,eax

      IFDEF DEBUG
        mov     edx,esi
        mov     [prevpc],esi
        or      edx,[PC_Base]
        mov     [adr_breakaccess],edx
      ENDIF


        test    [isPrefetch],1
        jz      @@noprefetch_atall
        cmp     [PrefetchPC],esi
        jnz     @@noprefetch1
        mov     ax,[WORD PTR PrefetchQueue]
        jmp     @@prefetch
@@noprefetch1:
        mov     edx,[PrefetchPC]
        add     edx,2
        cmp     edx,esi
        jnz     @@noprefetch2
        mov     ax,[WORD PTR PrefetchQueue+2]
        jmp     @@prefetch
@@noprefetch2:
        mov     ax,[es:esi]
@@prefetch:
        mov     edx,[es:esi+2]          ;PREFETCH
        rol     ax,8
        add     esi,2

        xchg    [PrefetchQueue],edx     ;PREFETCH QUEUE
        mov     [PrefetchQueue2],edx
        mov     ecx,[PrefetchPC]
        mov     [PrefetchPC],esi
        mov     [PrefetchPC2],ecx
        jmp     @@afterpref
@@noprefetch_atall:
        mov     ax,[es:esi]
        rol     ax,8
        add     esi,2
@@afterpref:

      IFDEF DEBUG
        mov     ebx,[breakopcode_msk]
        and     ebx,eax
        cmp     ebx,[breakopcode_cmp]
        jnz short @@nobreak_opcode

        or      [ebp+base.events_mask], MASK_IsException
        mov     [ebp+base.ExceptionNumber],_EXCEPTION_BREAKOPCODE
        sub     esi,2
        jmp     Return_Step_n
@@nobreak_opcode:
      ENDIF
        mov     [Opcode_cycles],0
        mov     [ebp+base.Cycles_Instruction],0
        jmp     [DWORD PTR Opcodes_Jump+eax*4]

        IFNDEF DEBUG

Return_Step_TURBO:
        PERIODIC_ON_RETURN
Return_Step_Turbo_direct:
        ;PERIODIC_ON_RETURN2


        IFDEF DEBUG
                mov     ebx,[PrevPC_cur]
                mov     [PrevPC_tbl+ebx*4],esi
                inc     ebx
                and     ebx,63
                mov     [PrevPC_cur],ebx
        ENDIF


        test    [ebp+base.events_mask], MASK_IsException or MASK_IllegalAccess or MASK_SoftReset or MASK_HardReset or MASK_UserBreak or MASK_DiskSelector or MASK_DoubleBus or MASK_DUMPSCREEN
        jnz     @@Special

        xor     eax,eax
        mov     ah,[es:esi]
        mov     al,[es:esi+1]
        add     esi,2
        mov     [Opcode_cycles],0
        mov     [ebp+base.Cycles_Instruction],0
        jmp     [DWORD PTR Opcodes_Jump+eax*4]
        ENDIF
@@Special:
        test    [ebp+base.events_mask],MASK_UserBreak or MASK_DOUBLEBUS
        jnz     @@Abort
        test    [ebp+base.events_mask],MASK_IllegalAccess
        jnz     Trigger_BusError

@@Abort:
        mov     [ModeST],0
        add     esi,[PC_Base]
        mov     [ebp+base.PC],esi
        call    Convert_To_SR
        pop    gs fs es ebp
        ret
        ENDP


;***************************************************************************
;*
;* Returns the effective adress, converted into PC memory (mem, regs, imm)
;*
;*  In  : EAX = Opcode  (modified)
;*        ESI = PC
;*
;*  Out : EDI = EA
;*        ESI = PC
;*        EBX = 00 si reg (Intel Mode), OFFSET mem sinon (68000 mode)
;*
;***************************************************************************

MACRO ret_mem
        mov     ebx,[memory_ram]
        ret
        ENDM

MACRO ret_reg
        xor     ebx,ebx
        ret
        ENDM

        alignmax
Instr_To_EA_BYTE:
        mov     edi,eax
        pop     ebx
        and     edi,03fh
        jmp     [DWORD PTR edi*4+Instr_To_EA_Functions_B]
        ENDP
        alignmax
Instr_To_EA_WORD:
        mov     edi,eax
        pop     ebx
        and     edi,03fh
        jmp     [DWORD PTR edi*4+Instr_To_EA_Functions_W]
        alignmax
Instr_To_EA_DWORD:
        mov     edi,eax
        pop     ebx
        and     edi,03fh
        jmp     [DWORD PTR edi*4+Instr_To_EA_Functions_L]
        alignmax

i2ea_Aind_BW:
        and     eax,7
        MoreCycles 4                           ; 4 cycles (An)
        mov     edi,[ebp+eax*4+base.A]
        Ret_Mem
        alignmax

i2ea_Aipi_B:
        and     eax,7
        MoreCycles 4                           ; 4 cycles (An)+
        mov     edi,[ebp+eax*4+base.A]
        inc     [ebp+eax*4+base.A]
        Ret_Mem
        alignmax

i2ea_A7pi_B:
        and     eax,7
        MoreCycles 4                           ; 4 cycles (An)+
        mov     edi,[ebp+eax*4+base.A]
        add     [ebp+eax*4+base.A],2
        Ret_Mem
        alignmax

i2ea_Aipd_B:
        and     eax,7
        MoreCycles 6                           ; 6 cycles -(An)
        dec     [ebp+eax*4+base.A]
        mov     edi,[ebp+eax*4+base.A]
        Ret_Mem
        alignmax


i2ea_A7pd_B:
        and     eax,7
        MoreCycles 6                           ; 6 cycles -(An)
        sub     [ebp+eax*4+base.A],2
        mov     edi,[ebp+eax*4+base.A]
        Ret_Mem
        alignmax

i2ea_Ai16_BW:
        mov     di,[es:esi]
        and     eax,7
        rol     di,8
        add     esi,2
        movsx   edi,di
        MoreCycles 8                           ; 8 cycles d(An)
        add     edi,[ebp+eax*4+base.A]
        Ret_Mem
        alignmax

i2ea_AbsW_BW:
        mov     di,[es:esi]
        MoreCycles 8                          ; 8 cycles Abs.w
        rol     di,8
        add     esi,2
        movsx   edi,di
        Ret_Mem
        alignmax

i2ea_AbsL_BW:
        mov     edi,[es:esi]
        add     esi,4
        bswap   edi
        MoreCycles 12                          ; 12 cycles Abs.l
        Ret_Mem
        alignmax

i2ea_PC16_BW:
        mov     di,[es:esi]
        MoreCycles 8                           ; 8 cycles d(PC)
        rol     di,8
        movsx   edi,di
        add     edi,esi
        add     esi,2
        or      edi,[PC_Base]
        Ret_Mem
        alignmax

i2ea_Immd_B:
        mov     edi,esi
        add     esi,2
        or      edi,[PC_Base]
        MoreCycles 4                           ; 4 cycles immediate
        inc     edi
        Ret_Mem
        alignmax

i2ea_ADreg_BWL:
        and     eax,15
        lea     edi,[ebp+eax*4+base.D]
        Ret_Reg
        alignmax

i2ea_Aipi_W:
        and     eax,7
        MoreCycles 4
        mov     edi,[ebp+eax*4+base.A]
        add     [ebp+eax*4+base.A],2
        Ret_Mem
        alignmax

i2ea_Aipd_W:
        and     eax,7
        MoreCycles 6
        sub     [ebp+eax*4+base.A],2
        mov     edi,[ebp+eax*4+base.A]
        Ret_Mem
        alignmax


i2ea_Immd_W:
        mov     edi,esi         ;modified
        add     esi,2
        or      edi,[PC_Base]   ;
        MoreCycles 4
        Ret_Mem
        alignmax

i2ea_Aind_L:
        and     eax,7
        MoreCycles 8
        mov     edi,[ebp+eax*4+base.A]
        Ret_Mem
        alignmax

i2ea_Aipi_L:
        and     eax,7
        MoreCycles 8
        mov     edi,[ebp+eax*4+base.A]
        add     [ebp+eax*4+base.A],4
        Ret_Mem
        alignmax

i2ea_Aipd_L:
        and     eax,7
        MoreCycles 10
        sub     [ebp+eax*4+base.A],4
        mov     edi,[ebp+eax*4+base.A]
        Ret_Mem
        alignmax

i2ea_Ai16_L:
        and     eax,7
        mov     di,[es:esi]
        MoreCycles 12
        rol     di,8
        add     esi,2
        movsx   edi,di
        add     edi,[ebp+eax*4+base.A]
        Ret_Mem
        alignmax

PROC i2ea_AbsW_L NEAR
        mov     di,[es:esi]
        MoreCycles 12
        rol     di,8
        add     esi,2
        movsx   edi,di
        Ret_Mem
        ENDP
        alignmax

PROC i2ea_AbsL_L NEAR
        mov     edi,[es:esi]
        MoreCycles 16
        add     esi,4
        bswap   edi
        Ret_Mem
        ENDP
        alignmax

PROC i2ea_PC16_L NEAR
        mov     di,[es:esi]
        MoreCycles 12
        rol     di,8
        movsx   edi,di
        add     edi,esi
        or      edi,[PC_Base]
        add     esi,2
        Ret_Mem
        ENDP
        alignmax

i2ea_Immd_L:
        mov     edi,esi
        add     esi,4
        or      edi,[PC_Base]
        MoreCycles 8
        Ret_Mem
        alignmax

i2ea_Unkn_BWL:
        xor     edi,edi
        Ret_Mem
        alignmax

i2ea_Ai8d_L:
        MoreCycles 4
i2ea_Ai8d_BW:
        and     eax,7
        movsx   edi,[BYTE PTR es:esi+1]
        add     edi,[ebp+eax*4+base.A]
        xor     eax,eax
        mov     al,[es:esi]
        add     esi,2
        shr     eax,3
        MoreCycles 10
        jmp     [DWORD PTR Instr_To_EA_Functions_BWL+eax*4]

        alignmax

i2ea_PC8d_L:
        MoreCycles 4
i2ea_PC8d_BW:
        movsx   edi,[BYTE PTR es:esi+1]
        add     edi,esi
        or      edi,[Pc_Base]
        xor     eax,eax
        mov     al,[es:esi]
        add     esi,2
        shr     eax,3
        MoreCycles 10
        jmp     [DWORD PTR Instr_To_EA_Functions_BWL+eax*4]

        alignmax

i2ea_iDxW_BW:
        and     eax,0eh
        movsx   eax,[WORD PTR ebp+eax*2+base.D]
        add     edi,eax
        Ret_Mem

        alignmax

i2ea_iDxL_BW:
        and     eax,0eh
        add     edi,[ebp+eax*2+base.D]
        Ret_Mem

        alignmax

i2ea_iAxW_BW:
        and     eax,0eh
        movsx   eax,[WORD PTR ebp+eax*2+base.A]
        add     edi,eax
        Ret_Mem

        alignmax

i2ea_iAxL_BW:
        and     eax,0eh
        add     edi,[ebp+eax*2+base.A]
        Ret_Mem

        DATASEG

        public _trace
        public _trace0

LABEL Instr_To_EA_Functions_B
        dd      8 dup (i2ea_ADreg_BWL)     ;Instr_To_EA -  Case Dn
        dd      8 dup (i2ea_ADreg_BWL)     ;               Case An
        dd      8 dup (i2ea_Aind_BW)      ;               Case (An)
        dd      7 dup (i2ea_Aipi_B)       ;               Case (An)+
        dd      i2ea_A7pi_B               ;               Case (A7)+
        dd      7 dup (i2ea_Aipd_B)       ;               Case -(An)
        dd      i2ea_A7pd_B               ;               Case -(A7)
        dd      8 dup (i2ea_Ai16_BW)      ;               Case d(An)
        dd      8 dup (i2ea_Ai8d_BW)      ;               Case d(An,Xi)
        dd      i2ea_AbsW_BW              ;Instr_To_EA -  Abs.W
        dd      i2ea_AbsL_BW              ;               Abs.L
        dd      i2ea_PC16_BW              ;               d(PC)
        dd      i2ea_PC8d_BW              ;               d(PC,Xi)
        dd      i2ea_Immd_B               ;               #Immd
        dd      i2ea_Unkn_BWL             ;Unknown modes
        dd      i2ea_Unkn_BWL
        dd      i2ea_Unkn_BWL

LABEL Instr_To_EA_Functions_W
        dd      8 dup (i2ea_ADreg_BWL)     ;Instr_To_EA -  Case Dn
        dd      8 dup (i2ea_ADreg_BWL)     ;               Case An
        dd      8 dup (i2ea_Aind_BW)      ;               Case (An)
        dd      8 dup (i2ea_Aipi_W)       ;               Case (An)+
        dd      8 dup (i2ea_Aipd_W)       ;               Case -(An)
        dd      8 dup (i2ea_Ai16_BW)      ;               Case d(An)
        dd      8 dup (i2ea_Ai8d_BW)      ;               Case d(An,Xi)
        dd      i2ea_AbsW_BW              ;Instr_To_EA -  Abs.W
        dd      i2ea_AbsL_BW              ;               Abs.L
        dd      i2ea_PC16_BW              ;               d(PC)
        dd      i2ea_PC8d_BW              ;               d(PC,Xi)
        dd      i2ea_Immd_W               ;               #Immd
        dd      i2ea_Unkn_BWL             ;Unknown modes
        dd      i2ea_Unkn_BWL
        dd      i2ea_Unkn_BWL

LABEL Instr_To_EA_Functions_L
        dd      8 dup (i2ea_ADreg_BWL)     ;Instr_To_EA -  Case Dn
        dd      8 dup (i2ea_ADreg_BWL)     ;               Case An
        dd      8 dup (i2ea_Aind_L)       ;               Case (An)
        dd      8 dup (i2ea_Aipi_L)       ;               Case (An)+
        dd      8 dup (i2ea_Aipd_L)       ;               Case -(An)
        dd      8 dup (i2ea_Ai16_L)       ;               Case d(An)
        dd      8 dup (i2ea_Ai8d_L)       ;               Case d(An,Xi)
        dd      i2ea_AbsW_L               ;Instr_To_EA -  Abs.W
        dd      i2ea_AbsL_L               ;               Abs.L
        dd      i2ea_PC16_L               ;               d(PC)
        dd      i2ea_PC8d_L               ;               d(PC,Xi)
        dd      i2ea_Immd_L               ;               #Immd
        dd      i2ea_Unkn_BWL             ;Unknown modes
        dd      i2ea_Unkn_BWL
        dd      i2ea_Unkn_BWL

LABEL Instr_To_EA_Functions_BWL
        dd      i2ea_iDxW_bw,i2ea_iDxL_bw   ;indexed modes
        dd      i2ea_iDxW_bw,i2ea_iDxL_bw
        dd      i2ea_iDxW_bw,i2ea_iDxL_bw
        dd      i2ea_iDxW_bw,i2ea_iDxL_bw
        dd      i2ea_iDxW_bw,i2ea_iDxL_bw
        dd      i2ea_iDxW_bw,i2ea_iDxL_bw
        dd      i2ea_iDxW_bw,i2ea_iDxL_bw
        dd      i2ea_iDxW_bw,i2ea_iDxL_bw
        dd      i2ea_iAxW_bw,i2ea_iAxL_bw
        dd      i2ea_iAxW_bw,i2ea_iAxL_bw
        dd      i2ea_iAxW_bw,i2ea_iAxL_bw
        dd      i2ea_iAxW_bw,i2ea_iAxL_bw
        dd      i2ea_iAxW_bw,i2ea_iAxL_bw
        dd      i2ea_iAxW_bw,i2ea_iAxL_bw
        dd      i2ea_iAxW_bw,i2ea_iAxL_bw
        dd      i2ea_iAxW_bw,i2ea_iAxL_bw


        CODESEG


        DATASEG

Nb_Cycles_Full  dd      0

        CODESEG



;************************************************************************
;*
;* Convert 68000 SR into simulation forms: LAHF form (NZC), X, V
;*
;************************************************************************

PROC Convert_From_SR NEAR       ;OPTIMIZED Function
        mov     eax,[ebp+base.SR]       ;---X NZVC  -> NZ-- ---C   / X / V
        or      ax,ax
        jns     @@notrace

        IFNDEF DEBUG
        cmp     [ebp+base.Offset_Next],OFFSET Return_Step        ;if was turbo mode
        je      @@quit_turbo                            ;go to slow mode
        mov     [ebp+base.Offset_Next],OFFSET Return_Step_n      ;while in trace
        mov     [ebp+base.Offset_Next_Direct],OFFSET Return_Step_n_Direct
@@quit_turbo:
        ENDIF

        cmp     [_TRACE0],1
        je      @@trace

        mov     [_TRACE],0
        mov     [_TRACE0],1
        jmp     @@trace
@@notrace:
        mov     [_TRACE0],0
@@trace:
        mov     ebx,7
        mov     ecx,1           ; ECX = 1 for later
        and     bl,ah
        bt      eax,13
        mov     [ebp+base.IOPL],ebx             ;EBX=bl=IOPL
        setc    bl                              ;ebx=bl=1 if supervisor mode
        cmp     [ebp+base.SUPERVISOR],ebx               ;changed mode?
        je      short @@SameMode                ;if not, swap stacks
        mov     [ebp+base.SUPERVISOR],ebx       ;swap stacks
        mov     ebx,[ebp+7*4+base.A]
        xchg    ebx,[ebp+base.A7]
        mov     [ebp+7*4+base.A],ebx
@@SameMode:
        bt      eax,ecx         ;bit V (ecx=1!)
        setc    [BYTE PTR ebp+base.V]
        bt      eax,4           ;bit X
        setc    [BYTE PTR ebp+base.X]
        and     ecx,eax         ;ECX keeps bit C in LAHF form
        shl     eax,4
        and     eax,0c0h        ;EAX keeps bits NZ in LAHF form
        or      eax,ecx
        mov     [ebp+base.NZC],eax
        ret
        ENDP



;************************************************************************
;*
;* Convert simulation SR form into 68000 SR -
;*
;************************************************************************


PROC Convert_To_SR NEAR
        mov     eax,[ebp+base.NZC]      ;NZ-- ---C / X / V -> ---X NZVC
        mov     ebx,eax
        shr     eax,4
        and     ebx,1
        and     eax,0ch
        or      eax,ebx
        cmp     [ebp+base.X],0
        jz      short @@NoX
        or      eax,10h
@@NoX:  cmp     [ebp+base.V],0
        jz      short @@NoV
        or      eax,2
@@NoV:  cmp     [ebp+base.SUPERVISOR],0
        jz      short @@NoS
        or      eax,02000h
@@NoS:  mov     ebx,[ebp+base.IOPL]
        shl     ebx,8
        or      eax,ebx
        cmp     [_TRACE0],0
        je      @@notrace
        or      eax,8000h
@@notrace:
        IFNDEF DEBUG
        cmp     [ebp+base.Offset_Next],OFFSET Return_Step
        je      @@step_trace
        test    [isPrefetch],1
        jnz     @@step_trace
        cmp     [_TRACE0],0
        jz      @@not_in_trace_mode
        mov     [ebp+base.Offset_Next],OFFSET Return_Step_n
        mov     [ebp+base.Offset_Next_Direct],OFFSET Return_Step_n_Direct
                jmp     @@step_trace
@@not_in_trace_mode:
        mov     [ebp+base.Offset_Next],OFFSET Return_Step_TURBO
        mov     [ebp+base.Offset_Next_Direct],OFFSET Return_Step_Turbo_Direct
@@step_trace:
        ENDIF

        mov     [ebp+base.SR],eax
        ret
        ENDP



;************************************************************************
;*
;* Exceptions
;*
;************************************************************************


;@@OkSuper:
Do_Privilege_Violation:
        mov     eax,[ebp+base.IOPL]
        mov     [ebp+base.New_IOPL],eax
        mov     eax,_EXCEPTION_PRIVILEGEVIOLATION
        jmp     Trigger_Exception
                        ; Generate Exception (EAX)

PROC Trigger_Exception NEAR
        cmp     eax,255
        ja      quitex

        mov     [Invalid_Address],edi

        mov     [ebp+base.ExceptionNumber],eax  ;alert monitor
        mov     [IsTrappedPexec],0
        mov     ecx,eax

        call    Convert_To_SR           ;ECX holds IRQ number

        IFDEF DEBUG
                cmp     [logIRQs+ecx*4],0
                jz      @@Noneed
                pushad
                push    ecx
                call    LOGirq
                add     esp,4
                popad
@@Noneed:
        ENDIF

        mov     [_TRACE],0
        mov     [_TRACE0],0

;-------------------------------------------------- trap some XBIOS call

        cmp     ecx,14+32
        jnz     @@NoXbios       ;*********** patch Xbios 8 => floprd
        mov     edi,[ebp+7*4+base.A]
        Read_W
        cmp     dx,25h
        jnz     @@novbl
        cmp     [dword ptr 6*4+ebp+base.D],'Emu?'
        jnz     @@novbl
        cmp     [dword ptr ebp+7*4+base.D],'Emu?'
        jnz     @@novbl

        mov     [ebp+6*4+base.D],'PaCi'
        mov     [ebp+7*4+base.D],'fiST'
        mov     [ebp+base.A],0ffff8100h
        Next 38
@@novbl:
        cmp     dx,15
        jz      @@Xbios
        cmp     dx,10
        jz      @@Xbios
        cmp     dx,9
        jz      @@Xbios
        cmp     dx,8
        jnz     @@NoXbios
@@Xbios:
        push    esi ebp
        call    SystemXbios
        pop     ebp esi
        Next 38
@@NoXbios:

;-------------------------------------------------- trap some BIOS call

        cmp     ecx,13+32
        jnz     @@NoBios                ;is TRAP #$D ?
        mov     edi,[ebp+7*4+base.A]    ;Stack
        Read_W                          ;function number. Is this...
        cmp     dx,1                            ;BCONSTAT
        je      short @@NeedBiosTrapIfSERIAL
        cmp     dx,2                            ;BCONIN
        je      short @@NeedBiosTrapIfSERIAL
        cmp     dx,3                            ;BCONOUT
        je      short @@NeedBiosTrapIfSERIAL
        cmp     dx,8                            ;BCOSTAT
        jmp     short @@NoBios
@@NeedBiosTrapIfSerial:
        add     edi,2
        Read_W                          ;device used on BIOS call
        cmp     dx,1                    ;is it AUX?
        jnz     @@NoBios

        pushad
        call    SystemBIOS
        popad
        Next    38
@@NoBios:
;-------------------------------------------------- trap some VDI calls
;        cmp     ecx,2+32
;        jnz     @@NoVDI
;        cmp     [ebp+base.D],073h
;        jnz     @@NoVDI
;        pushad
;        call    SystemVDI
;        popad
;@@novdi:
;-------------------------------------------------- trap some GEMDOS calls
        cmp     ecx,1+32
        jnz     @@NoGemdos
        mov     [IsTrappedGemdos],0     ;if TRAP #1, call SYS.SystemGemdos
        pushad
        call    SystemGemdos
        popad
        cmp     [IsTrappedGemdos],0     ;if trapped, continue...
        jz      @@NoGemdos              ;else, normal gemdos execution
        Next    38
@@NoGemdos:
        push    ecx             ; push IRQ number



        mov     [_TRACE],0
        mov     ebx,[ebp+base.New_IOPL]
        mov     eax,[ebp+base.SR]
        mov     [ebp+base.IOPL],ebx
        shl     ebx,8
        and     eax,78ffh               ;disable TRACE & IPL
        or      eax,ebx                 ;set IOPL
        or      eax,02000h              ;set Supervisor
        bts     [ebp+base.SUPERVISOR],0
        jc      Super

        mov     edx,[ebp+base.A7]       ;swap stacks if user -> super
        mov     ebx,[ebp+7*4+base.A]
        mov     [ebp+7*4+base.A],edx
        mov     [ebp+base.A7],ebx
Super:
        mov     edx,esi                 ;modif
        or      edx,[PC_Base]           ;
        and     edx,0ffffffh
        or      edx,[HiByte_PC]         ;necessary for bombs handling
;;;;;;;;;;;;
        cmp     ecx,32+2
        jne     @@noVDI
        mov     [vdipatch_return],edx
        mov     ebx,[ebp+4+base.D]
        mov     [vdi_parameters],ebx
@@noVDI:
;;;;;;;;;;;;
        Push_INTEL_Long                 ;push PC on stack

        mov     edx,[ebp+base.SR]
        push_INTEL_Word                 ;push prev SR on stack

        pop     edx
        mov     [ebp+base.SR],eax

        cmp     [IsTrappedPexec],0
        jz      nopexec
        mov     esi,0fa0800h            ;******************* PEXEC
        jmp     short @@goint
nopexec:

        ;mov     esi,[DWORD PTR mem+edx*4]         ;BRANCH to exception vector
        mov     esi,[fs:edx*4]
;        mov     [ebp+base.IsException],1
        or      [ebp+base.events_mask], MASK_IsException
        bswap   esi

        mov     eax,esi
        and     esi,000ffffffh
        and     eax,0ff000000h
        mov     [HiByte_PC],eax
@@goint:
        CheckPC

        cmp    [Illegal_PC],0
        je     @@noil
;-------------------------------------- Special Case: Invalid Interrupt Vector
        cmp    [DoubleBusError],0
        je     @@avoid2buserrors
;        mov     [ebp+base.ExceptionNumber],_EXCEPTION_DOUBLEBUS
;        or      [ebp+base.events_mask], MASK_IsException

        or      [ebp+base.events_mask], MASK_DoubleBus
        next    0
        ;----------------------------------- BUS ERROR

@@avoid2buserrors:
        mov     [DoubleBusError],1
        jmp     Trigger_BusError

@@noil:
        mov     eax,[ebp+base.ExceptionNumber]
        cmp     eax,_EXCEPTION_ADRESSERROR
        je      @@exception_makestackframe
        cmp     eax,_EXCEPTION_BUSERROR
        je      @@exception_makestackframe
        mov     [DoubleBusError],0
quitex:
        Next    46

@@exception_makestackframe:
        xor     edx,edx
        push_INTEL_WORD
        mov     edx,[Invalid_Address]
        push_INTEL_LONG
        xor     edx,edx
        push_INTEL_WORD
        Next    94

Trigger_BusError:
;        mov     [ebp+base.Illegal_Access],0

        and     [ebp+base.Events_Mask],not MASK_ILLEGALACCESS

        mov     eax,[ebp+base.IOPL]
        mov     [ebp+base.New_IOPL],eax
        mov     eax,_EXCEPTION_BUSERROR
        jmp     Trigger_Exception

Trigger_AdressError:
        mov     eax,[ebp+base.IOPL]
        mov     [ebp+base.New_IOPL],eax
        mov     eax,_EXCEPTION_ADRESSERROR
        jmp     Trigger_Exception

        ENDP


;ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
;º                                                                      RTE
;ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

; [fold]  [
Do_RTE:
        prof    _RTE
        Check_Privilege                         ;must be in supervisor mode

        Pop_Intel_WORD                          ;pop SR & convert to PC
        mov     [WORD PTR ebp+base.SR],dx

        Pop_Intel_LONG                          ;pop new PC
        cmp     edx,[vdipatch_return]
        jnz     @@nvdi
        pushad
        call    SystemVDI
        popad
@@nvdi:
        mov     esi,0ffffffh
        and     esi,edx
        call    Convert_From_SR
        CheckPC

        test    [Illegal_PC],1
        jz      @@noil
        jmp     Trigger_BusError
@@noil:
        Next    40


; [fold]  ]


Do_LineA:
        sub     esi,2
        mov     eax,[ebp+base.IOPL]
        mov     [ebp+base.New_IOPL],eax
        mov     eax,_EXCEPTION_LINEA
        jmp     Trigger_Exception
Do_LineF:
        sub     esi,2
        mov     eax,[ebp+base.IOPL]
        mov     [ebp+base.New_IOPL],eax
        mov     eax,_EXCEPTION_LINEF
        jmp     Trigger_Exception


Illegal_Instruction:
        mov     eax,[ebp+base.IOPL]
        sub     esi,2
        mov     [ebp+base.New_IOPL],eax
        mov     eax,_EXCEPTION_ILLEGALINSTRUCTION
        jmp     Trigger_Exception


Do_SystemPatch:
        mov     dx,[es:esi]
        rol     dx,8

        cmp     dx,SYSCMD_BOOT
        je      DoSystemBOOT

        cmp     dx,SYSCMD_INIT
        je      DoSystemINIT

        cmp     dx,SYSCMD_DISKBPB
        je      DoSystemDiskBPB

        cmp     dx,SYSCMD_DISKRW
        je      DoSystemDiskRW

        cmp     dx,SYSCMD_LINEABASE
        je      DoSystemLineabase

        cmp     dx,SYSCMD_TESTTOS1
        je      DoSystemTestTos1

        cmp     dx,SYSCMD_MEDIACH
        je      DoSystemMediaChange

        cmp     dx,SYSCMD_PRTOUT
        je      DoSystemPrtOut

        cmp     dx,SYSCMD_PRTSTATUS
        je      DoSystemPrtStatus

        cmp     dx,SYSCMD_NEWDTA
        je      DoSystemNewDTA

	cmp     dx,SYSCMD_RCYCLES
        je      DoSystemRCYCLES

	cmp     dx,SYSCMD_CCYCLES
        je      DoSystemCCYCLES


        jmp     Illegal_Instruction     ;if no command -> it's illegal opcode


        extrn DTA : dword
        extrn gemdos_forcedta : near
	public optim_cycles
	dataseg

optim	dd	0
optim_cycles dd	0

	codeseg



DoSystemRCYCLES:
	mov	[optim],0
	add	esi,2
	Next	0

DoSystemCCYCLES:
	mov	eax,[optim]
	mov	[optim_cycles],eax
	add	esi,2
	Next	0

DoSystemNewDTA:

        mov     edi,[ebp+base.D]
        add     edi,020h                ;ptr DTA
        READ_L
        mov     [dta],edx
        push    esi ebp
        call    gemdos_forcedta
        pop     ebp esi
        add     esi,2
        Next    0


DoSystemBOOT:
        push    esi ebp                 ;preserve PC from modif
        call    SystemBoot
        pop     ebp esi
        add     esi,2                   ;continue 68000 after command...
        Next 0

DoSystemTestTos1:
        mov     [ebp+base.D],0
        cmp     [TosBase],0fc0000h
        jnz     @@notos1
        mov     [ebp+base.D],-1
@@notos1:
        add     esi,2
        Next 0


DoSystemINIT:
        push    esi ebp
        call    SystemInit
        pop     ebp esi
        add     esi,2
        Next 0

DoSystemDiskBPB:
        push    esi ebp
        call    SystemDiskBPB
        pop     ebp esi
        add     esi,2
        Next 0

DoSystemDiskRW:
        push    esi ebp
        call    SystemDiskRW
        pop     ebp esi
        add     esi,2
        Next 0

DoSystemLineabase:
        mov     eax,[ebp+base.D]
        add     esi,2
        mov     [lineabase],eax
        Next 0


DoSystemMediaChange:
        push    esi ebp
        call    SystemMediaChange
        pop     ebp esi
        add     esi,2
        Next    0

DoSystemPrtOut:
        push    esi ebp
        call    SystemPrtOut
        pop     ebp esi
        add     esi,2
        Next    0

DoSystemPrtStatus:
        push    esi ebp
        call    SystemPrtStatus
        pop     ebp esi
        add     esi,2
        Next    0



        DATASEG

        public vdi_parameters
;        public  New_IOPL


vdipatch_return dd 0
vdi_parameters  dd 0
Direct_Rewrite_OK       dd      1
LastEA          dd      0
FakeException   dd      0
DoubleBusError  dd      0
State_68000     dd      0
Wait_STOP       dd      0
Invalid_Address dd      0

        PUBLIC  GoodByeScreen
        PUBLIC  PacifistLogo

LABEL GoodByeScreen WORD

        include "goodbye.asm"

LABEL PacifistLogo WORD

        include "logo.asm"


        alignmax

        PUBLIC base_processor


Base_processor  base




;
;_D             dd      8 dup (0)
;_A             dd      8 dup (0)
;_A7            dd      0
;CyclesLeft     dd      0
;_NZC            dd      0
;_V              dd      0
;_X              dd      0
;_SR            dd      0
;_PC            dd      0



HiByte_PC       dd      0
Illegal_PC      dd      0
;Illegal_Access  dd      0
;New_IOPL        dd      0
;_IOPL           dd      0
;_SUPERVISOR     dd      0
;_IsException    dd      0
;_ExceptionNumber        dd      0
isPrefetch      dd      0
PrefetchQueue   dd      0
PrefetchPC      dd      0
PrefetchQueue2  dd      0       ;Previous PC queue (for DBF)
PrefetchPC2     dd      0       ;Previous PC

_TRACE          dd      0
_TRACE0          dd      0
first_trace     dd      0       ;1: wait next, 0:ok

opcode_cycles           dd      0
thisraster_cycles       dd      0

Active_Events   dd      0
events          dd     MAX_EVENTS dup (Tevent)

;next_event      dd      Periodic_RasterLine       ;adr of next event routine
;next_event_cycles       dd      0


prevPC_tbl      dd      64 dup (0)
prevPC_cur      dd      0
        END
; [fold]  1
