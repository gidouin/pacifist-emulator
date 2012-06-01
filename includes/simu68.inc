        IDEAL
        P486
        MODEL FLAT
        LOCALS

VIDEOEMU_SCREEN         EQU     0
VIDEOEMU_LINE           EQU     1
VIDEOEMU_MIXED          EQU     2
VIDEOEMU_CUSTOM         EQU     3

STRUC base

Offset_Next             dd      0
CyclesLeft              dd      0
D                       dd      8 dup (0)
A                       dd      8 dup (0)
A7                      dd      0
Return_After_Hard       dd      0
Ramsize                 dd      0
NZC                     dd      0
V                       dd      0
X                       dd      0
SR                      dd      0
SUPERVISOR              dd      0
IOPL                    dd      0
New_IOPL                dd      0
ExceptionNumber         dd      0
events_mask             dd      0
PC                      dd      0
Offset_Next_Direct      dd      0
Cycles_2_Go             dd      0
Cycles_Instruction      dd      0
Cycles_This_Raster      dd      0
dummy                   db      48 dup (0)
ENDS


ACTIVE_EVENT_RASTER   EQU       00000001h ;mask in Active_Events
ACTIVE_EVENT_TIMERA   EQU       00000002h ;mask in Active_Events

MAX_EVENTS      EQU 2

STRUC Tevent
time            dd      0
event_function  dd      0
ENDS

   ; definition of masks for events processing


   MASK_VBL     =       00000001h
   MASK_ACIA    =       00000002h
   MASK_TIMERC  =       00000004h
   MASK_TIMERA  =       00000008h
   MASK_TIMERB  =       00000010h
   MASK_FDC     =       00000020h
   MASK_TIMERD  =       00000040h

   MASK_IRQS    =       0000007fh
   MASK_FDC2    =       00000080h


   MASK_ILLEGALACCESS   = 00001000h
   MASK_ISEXCEPTION     = 00002000h
   MASK_SoftReset       = 00004000h
   MASK_HardReset       = 00008000h
   MASK_UserBreak       = 00010000h
   MASK_DiskSelector    = 00020000h
   MASK_DoubleBus       = 00040000h
   MASK_PTRSCR          = 00080000h
   MASK_DUMPSCREEN      = 00100000h

   MASK_MOUSE           = 010000000h

        EXTRN Table_Conditions  : BYTE

;        EXTRN ramsize : DWORD


SystemPatchOpcode = 11bfh       ; used for system conversion in expansion rom
SYSCMD_BOOT       = 1           ; boot (jump in $47A)
SYSCMD_INIT       = 2           ; init
SYSCMD_DISKBPB    = 3           ; get disk bpb
SYSCMD_DISKRW     = 4           ; read/write sector
SYSCMD_LINEABASE  = 5           ; read LineA base
SYSCMD_TESTTOS1   = 6           ; return D0 != 0 if TOS1
SYSCMD_MEDIACH    = 7           ; Media Change
SYSCMD_PRTOUT     = 8
SYSCMD_PRTSTATUS  = 9
SYSCMD_NEWDTA     = 10

SYSCMD_RCYCLES  =  0ff00h
SYSCMD_CCYCLES   =  0ff01h

STATE_STOP      = 00001h        ; currently in a STOP instruction
STATE_QUITSTOP   = 00002h       ; IRQ occured, quit STOP process

        DATASEG


        EXTRN Opcodes_Jump      :       DWORD   ;Table of opcodes function



 IFDEF DEBUG

        EXTRN Nb_Breakpoints    :       DWORD   ;number of defined breakpoints
        EXTRN breakpoints       :       DWORD   ;array of breakpoints
        EXTRN Nb_Breakaccess    :       DWORD
        EXTRN breakaccess       :       DWORD
        EXTRN breakaccess_rw    :       BYTE
        EXTRN adr_breakaccess   :       DWORD
        EXTRN break_cycles      :       DWORD
        EXTRN breakopcode_msk   :       DWORD
        EXTRN breakopcode_cmp   :       DWORD
 ENDIF

 IFDEF DEBUGPROFILE
        EXTRN isprofile         :       DWORD
        EXTRN wasprofile        :       DWORD
        EXTRN profile           :       DWORD
 ENDIF


;        EXTRN timers_this_raster     : DWORD
;        EXTRN next_timer_this_raster : DWORD

 IFDEF DEBUG
        EXTRN LOGirq       :       NEAR
        EXTRN logIRQs           :       DWORD
 ENDIF

        EXTRN Nb_VBLs           :       DWORD

        EXTRN prevpc : DWORD
        EXTRN timer_cycle2go : DWORD

;        EXTRN mem               :       BYTE    ;RAM (Any size <16 Mo)

        EXTRN memory_ram        :       DWORD


        EXTRN memtos            :       BYTE    ;ROM (512 Ko)
        EXTRN memio             :       BYTE    ;I/O Ports (32 Ko)
        EXTRN memcartridge      :       BYTE    ;EXPANSION ROM (128 Ko)
        EXTRN SystemBoot        :       NEAR    ;C function to read bootsector
        EXTRN SystemInit        :       NEAR
        EXTRN SystemDiskBPB     :       NEAR
        EXTRN SystemDiskRW      :       NEAR
        EXTRN   Keyboard_Read    :       NEAR
        EXTRN   Keyboard_Write   :       NEAR
        EXTRN   Keyboard_Send   :       NEAR
        EXTRN  Global_PC_VBLs   :       DWORD
        EXTRN lineabase         :       DWORD
        EXTRN TOSBASE           :       DWORD
        EXTRN TOSBASEMAX        :       DWORD
        EXTRN NativeSpeed       :       DWORD

        EXTRN ramseg            :       WORD    ; descriptor for RAM
        EXTRN romseg            :       WORD    ; descriptor for ROM
        EXTRN cartseg           :       WORD    ; descriptor for CARTRIDGE
        EXTRN ioseg             :       WORD    ; descriptor for I/O
        EXTRN PC_Base           :       DWORD   ; base for PC (ram,rom...)


        extrn modulo : dword
        extrn moduloy : dword

        EXTRN Cycles_Per_RasterLine : DWORD

        IFNDEF FromHard
                EXTRN Read_B_Hard       :       NEAR
                EXTRN Read_W_Hard       :       NEAR
                EXTRN Read_L_Hard       :       NEAR
                EXTRN Write_B_Hard      :       NEAR
                EXTRN Write_W_Hard      :       NEAR
                EXTRN Write_L_Hard      :       NEAR
;                EXTRN Return_After_HARD :       DWORD
        ENDIF


        IFNDEF FromSimu68
                EXTRN Convert_To_SR     :       NEAR
                EXTRN Convert_From_SR   :       NEAR
                EXTRN Do_Privilege_Violation :  NEAR
                DATASEG
;                EXTRN New_IOPL :                DWORD
                EXTRN HiByte_PC :               DWORD
                EXTRN Instr_To_EA_Functions_B : DWORD
                EXTRN Instr_To_EA_Functions_W : DWORD
                EXTRN Instr_To_EA_Functions_L : DWORD

        EXTRN Opcode_Cycles : DWORD
        EXTRN thisraster_Cycles : DWORD


        ;EXTRN Active_Events : DWORD
        ;EXTRN Next_Event : DWORD
        ;EXTRN next_event_cycles : DWORD

        EXTRN IsPrefetch : dword
        EXTRN PrefetchPC : dword
        EXTRN PrefetchQueue : dword
        EXTRN PrefetchPC2 : dword
        EXTRN PrefetchQueue2 : dword

        EXTRN already_st_video : dword

        EXTRN YMrecording : DWORD

        EXTRN base_processor : DWORD

;        EXTRN _SUPERVISOR       :       DWORD   ;68000 SR supervisor bit
;        EXTRN _IOPL             :       DWORD   ;68000 SR Interrupt Level
;        EXTRN _IsException      :       DWORD   ;Exception generated?
;        EXTRN _ExceptionNumber  :       DWORD   ;Exception number

        EXTRN Illegal_PC : DWORD
;        EXTRN Illegal_Access : DWORD

                CODESEG
          IFDEF DEBUG
                 EXTRN Test_Breakaccess_read  :       NEAR
                 EXTRN Test_Breakaccess_write  :       NEAR
          ENDIF
                EXTRN Trigger_Exception :       NEAR
                EXTRN Trigger_BusError :       NEAR
                EXTRN Trigger_AdressError :       NEAR


        EXTRN State_68000       :       DWORD
        EXTRN Wait_STOP         :       DWORD


        ENDIF

        IFNDEF FromEvents
                EXTRN Nb_Cycles         :       DWORD   ;Nb of cycles elapsed
;                EXTRN CyclesLeft        :       DWORD   ;left cycles before VBL
                EXTRN Periodic_RasterLine:      NEAR
;                EXTRN It_s_Event_Time : NEAR
        ENDIF

        CODESEG

_EXCEPTION_0                    =       0
_EXCEPTION_1                    =       1
_EXCEPTION_BUSERROR             =       2
_EXCEPTION_ADRESSERROR          =       3
_EXCEPTION_ILLEGALINSTRUCTION   =       4
_EXCEPTION_ZERODIVIDE           =       5
_EXCEPTION_CHK                  =       6
_EXCEPTION_TRAPV                =       7
_EXCEPTION_PRIVILEGEVIOLATION   =       8
_EXCEPTION_TRACE                =       9
_EXCEPTION_LINEA                =       10
_EXCEPTION_LINEF                =       11
_EXCEPTION_12                   =       12
_EXCEPTION_13                   =       13
_EXCEPTION_14                   =       14
_EXCEPTION_15                   =       15
_EXCEPTION_28                   =       16


_EXCEPTION_HBL                  =       26
_EXCEPTION_VBL                  =       28
_EXCEPTION_TIMERC               =       69
_EXCEPTION_ACIA                 =       70
_EXCEPTION_FDC                  =       71
_EXCEPTION_TIMERB               =       72
_EXCEPTION_TIMERA               =       77
_EXCEPTION_TRAP                 =       32
_EXCEPTION_TIMERD               =       68

_EXCEPTION_BREAKPOINT           =      256
_EXCEPTION_BREAKACCESS          =      257
_EXCEPTION_CYCLES               =      258
_EXCEPTION_BREAKOPCODE          =      259
_EXCEPTION_USER                 =      260
_EXCEPTION_SOFTRESET            =      261
_EXCEPTION_HARDRESET            =      262
_EXCEPTION_DISKSELECTOR         =      263
_EXCEPTION_DOUBLEBUS            =      511

MACRO Instr_To_EA_B
        LOCAL @@r1
        mov     edi,eax
        and     edi,03fh
        call     [DWORD PTR edi*4+Instr_To_EA_Functions_B]
@@r1:
        ENDM

MACRO Instr_To_EA_W
        LOCAL @@r2
        mov     edi,eax
        and     edi,03fh
        call    [DWORD PTR edi*4+Instr_To_EA_Functions_W]
@@r2:
        ENDM

MACRO Instr_To_EA_L
        LOCAL @@r3
        mov     edi,eax
        and     edi,03fh
        call     [DWORD PTR edi*4+Instr_To_EA_Functions_L]
@@r3:
        ENDM

MACRO prof   labl                     ;Macro for profiling each functions
        IFDEF DEBUGPROFILE
        inc [labl]
        ENDIF
        ENDM

MACRO CheckPC
        LOCAL @@rom,@@ram,@@cont,@@contil,@@maybecouille, @@realcouille
        and     esi,0ffffffh
        cmp     esi,[ebp+base.RAMSIZE]
        jb short @@ram

        cmp     esi,0fa0000h
        jb      @@nocart
        cmp     esi,0fc0000h
        jae     @@nocart

        sub     esi,0fa0000h
        mov     es,[cartseg]
        mov     [PC_Base],0fa0000h
        jmp     @@cont
@@nocart:
        cmp     esi,[TOSbase]
        jb      @@maybecouille
        cmp     esi,[TOSbaseMax]
        jbe     @@okrom
@@maybecouille:
        cmp     esi,0ff8000h
        jb      @@realcouille

        mov     es,[ioseg]
        sub     esi,0ff8000h
        mov     [PC_Base],0ff8000h
        jmp short @@cont
@@realcouille:
        mov     [Illegal_PC],1
        jmp     short @@contil
@@okrom:
        push    eax
        mov     eax,[TOSbase]
        mov     es,[romseg]
        sub     esi,eax
        mov     [PC_Base],eax
        pop     eax
        jmp     short @@cont
@@ram:
        mov     es,[ramseg]
        mov     [PC_Base],0
@@cont:
        mov     [Illegal_PC],0
@@contil:
        ENDM

;;;MACRO NEXT nbcycles
;;;;       add      [thisraster_cycles],nbcycles
;;;;       sub      [timer_cycle2go],nbcycles
;;;;       jmp      [DWORD PTR ebp]
;;;;       align 4
;;;
;;;
;;;        mov     eax,nbcycles
;;;        add     eax,[ebp+BASE.Cycles_Instruction]
;;;        jmp     [DWORD PTR ebp]
;;;
;;;        align   4
;;;       ENDM
;;;
;;;MACRO NEXTDIRECT
;;;        xor     eax,eax
;;;        jmp     [DWORD PTR ebp]
;;;        align   4
;;;        ENDM
;;;
;;;MACRO MoreCycles nbcycles
;;;;        add     [thisraster_cycles],nbcycles
;;;;        sub     [timer_cycle2go],nbcycles
;;;        add     [ebp+BASE.Cycles_Instruction],nbcycles
;;;        ENDM
;;;


MACRO NEXT nbcycles
;        add     [thisraster_cycles],nbcycles
        mov     eax,nbcycles
       jmp     [DWORD PTR ebp]
       align 4
       ENDM


MACRO MoreCycles nbcycles
        ;add     [thisraster_cycles],nbcycles
        sub     [ebp+BASE.cycles_2_go],nbcycles
        ENDM


IFDEF DEBUG
MACRO TestIfBreakaccess1
        LOCAL @@nobreak1
        cmp     [Nb_Breakaccess],0
        jz short     @@nobreak1
        call    Test_Breakaccess_read
@@nobreak1:
        ENDM

MACRO TestIfBreakaccess2
        LOCAL @@nobreak2
        cmp     [Nb_Breakaccess],0
        jz short     @@nobreak2
        call    Test_Breakaccess_read
@@nobreak2:
        ENDM

MACRO TestIfBreakaccess3
        LOCAL @@nobreak3
        cmp     [Nb_Breakaccess],0
        jz short     @@nobreak3
        call    Test_Breakaccess_read
@@nobreak3:
        ENDM

MACRO TestIfBreakaccess4
        LOCAL @@nobreak4
        cmp     [Nb_Breakaccess],0
        jz short     @@nobreak4
        call    Test_Breakaccess_write
@@nobreak4:
        ENDM

MACRO TestIfBreakaccess5
        LOCAL @@nobreak5
        cmp     [Nb_Breakaccess],0
        jz short     @@nobreak5
        call    Test_Breakaccess_write
@@nobreak5:
        ENDM

MACRO TestIfBreakaccess6
        LOCAL @@nobreak6
        cmp     [Nb_Breakaccess],0
        jz short     @@nobreak6
        call    Test_Breakaccess_write
@@nobreak6:
        ENDM
ENDIF

;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ  Exceptions simulations -  Privileges Checking
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ


MACRO Check_Privilege
        test    [ebp+base.SUPERVISOR],1         ;if non supervisor #=-> exception
        jz      Do_Privilege_Violation
        ENDM



;/////////////////////////////////////////////////////////// Read BYTE in mem
MACRO Read_B
        LOCAL @@conti
        mov     [ebp+base.Return_After_Hard],OFFSET @@conti
        cmp     edi,[ebp+base.RAMSIZE]
        jnb     Read_B_Hard
        mov     dl,[fs:edi]
@@Conti:
        IFDEF DEBUG
                Testifbreakaccess1
        ENDIF

        ENDM



MACRO ReRead_B nodirect
        mov     [ebp+base.Return_After_Hard],OFFSET nodirect
        cmp     edi,[ebp+base.RAMSIZE]
        jnb Read_B_Hard
        add     edi,[memory_ram]
                IFDEF DEBUG
                 Testifbreakaccess1
                ENDIF
        ENDM

;/////////////////////////////////////////////////////////// Read WORD in mem
MACRO Read_W
        LOCAL @@conti2
        mov     [ebp+base.Return_After_Hard],OFFSET @@conti2
        cmp     edi,[ebp+base.RAMSIZE]
        jnb     Read_W_Hard
        mov     dx,[fs:edi]
        rol     dx,8

@@Conti2:
        IFDEF DEBUG
                Testifbreakaccess2
        ENDIF
       ENDM

MACRO ReRead_W nodirect
        mov     [ebp+base.Return_After_Hard],OFFSET nodirect
        cmp     edi,[ebp+base.RAMSIZE]
        jnb     Read_W_Hard
        add     edi,[memory_ram]

        IFDEF DEBUG
                Testifbreakaccess2
        ENDIF
       ENDM



;/////////////////////////////////////////////////////////// Read LONG in mem
MACRO Read_L
        LOCAL @@Conti3
        mov     [ebp+base.Return_After_Hard],OFFSET @@conti3
        cmp     edi,[ebp+base.RAMSIZE]
        jnb     Read_L_Hard
        mov     edx,[fs:edi]
        bswap   edx
@@Conti3:
        IFDEF DEBUG
                Testifbreakaccess3
        ENDIF
        ENDM

MACRO ReRead_L nodirect
        mov     [ebp+base.Return_After_Hard],OFFSET nodirect
        cmp     edi,[ebp+basE.RAMSIZE]
        jnb     Read_L_Hard
        add     edi,[memory_ram]
        IFDEF DEBUG
                Testifbreakaccess3
        ENDIF
        ENDM

;/////////////////////////////////////////////////////////// Write BYTE in mem
MACRO Write_B
        LOCAL @@conti4
        mov     [ebp+base.Return_After_Hard],OFFSET @@conti4
        cmp     edi,[ebp+base.RAMSIZE]
        jnb     Write_B_Hard
        mov     [fs:edi],dl
@@Conti4:
        IFDEF DEBUG
                Testifbreakaccess4
        ENDIF
        ENDM

;/////////////////////////////////////////////////////////// Write WORD in mem
MACRO Write_W
        LOCAL @@Conti5
        mov     [ebp+base.Return_After_Hard],OFFSET @@conti5
        cmp     edi,[ebp+base.RAMSIZE]
        jnb     Write_W_Hard
        rol     dx,8
        mov     [fs:edi],dx
@@Conti5:
        IFDEF DEBUG
                Testifbreakaccess5
        ENDIF
        ENDM

;/////////////////////////////////////////////////////////// Write WORD in mem
MACRO Write_L
        LOCAL @@conti6
        mov     [ebp+base.Return_After_Hard],OFFSET @@conti6
        cmp     edi,[ebp+base.RAMSIZE]
        jnb     Write_L_Hard
        bswap   edx
        mov     [fs:edi],edx
@@Conti6:
        IFDEF DEBUG
                Testifbreakaccess6
        ENDIF
        ENDM


;ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
;บ
;บ  Push / Pop MACROS
;บ
;ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ


;********************************** push DX on 68000 Stack
MACRO Push_Intel_WORD
        sub     [ebp+7*4+base.A],2
        mov     edi,[ebp+7*4+base.A]
        Write_W
        ENDM

;********************************** push EDX on 68000 Stack
MACRO Push_Intel_LONG
        sub     [ebp+7*4+base.A],4
        mov     edi,[ebp+7*4+base.A]
        Write_L
        ENDM

;********************************** pop DX from 68000 Stack
MACRO Pop_Intel_WORD
        mov     edi,[ebp+7*4+base.A]
        add     [ebp+7*4+base.A],2
        Read_W
        ENDM

;********************************** pop EDX from 68000 Stack
MACRO Pop_Intel_LONG
        mov     edi,[ebp+7*4+base.A]
        add     [ebp+7*4+base.A],4
        Read_L
        ENDM




MACRO Set_Flags_NZ
;      mov      al,[BYTE PTR ebp+base.NZC]
;      lahf
;      and      eax,0fe01h
;      or       al,ah
;      mov     [ebp+base.NZC],eax

        bt      [BYTE PTR ebp+base.NZC],0
        lahf
        mov     [ebp+base.NZC],eax


      ENDM

MACRO Set_Flags_NZC
      lahf
      mov      [BYTE PTR ebp+base.NZC],ah
      ENDM


