#ifndef CPU68
#define CPU68

#define TRUE 1
#define FALSE 0

#define MASK_VBL                0x00000001
#define MASK_ACIA               0x00000002
#define MASK_TIMERC             0x00000004
#define MASK_TIMERA             0x00000008
#define MASK_TIMERB             0x00000010
#define MASK_FDC                0x00000020
#define MASK_TIMERD             0x00000040
#define MASK_FDC2               0x00000080

#define MASK_ILLEGALACCESS      0x00001000
#define MASK_IsException        0x00002000
#define MASK_SoftReset          0x00004000
#define MASK_HardReset          0x00008000
#define MASK_UserBreak          0x00010000
#define MASK_DiskSelector       0x00020000
#define MASK_DoubleBus          0x00040000
#define MASK_PRTSCR             0x00080000
#define MASK_DUMPSCREEN         0x00100000
#define MASK_MOUSE              0x10000000

#define KBDMAXBUF 0x1ff

#define SPECIALPATCH_NONE               0
#define SPECIALPATCH_JOY                1


typedef unsigned char   UBYTE ;
typedef unsigned short  UWORD ;
typedef unsigned long   ULONG ;

typedef unsigned long DWORD ;

typedef char    BYTE ;
typedef short   WORD ;
typedef int     LONG ;

typedef LONG MPTR;

union iregister {
#pragma pack (1) ;
        UWORD ab ;
        struct {
        #pragma pack (1) ;
                UBYTE b ;
                UBYTE a ;
        } ;
} ;

#define MFP_FREQ        2457600

#define MFP_TIMERA      13
#define MFP_TIMERB      8
#define MFP_FDC         7
#define MFP_ACIA        6
#define MFP_TIMERC      5
#define MFP_TIMERD      4
#define MFP_BLITTER     3


extern void mfp_request(int channel) ;
extern void mfp_acknoledge(int channel) ;

struct ttimer {
#pragma pack (1) ;
        UBYTE mode;
        UBYTE data ;
        UWORD channel ;
        int cycle2go;
        unsigned int freq;
        unsigned int predivisedfreq ;
        unsigned int cyclecumul ;
        unsigned int cycleperiod ;
        unsigned int cyclestart ;
        unsigned int cycleend ;
} ;

struct info_mfp {
#pragma pack (1) ;

        UBYTE   gpip ;  // ne pas d‚passer
        UBYTE   aer ;
        UBYTE   ddr ;
        UBYTE   void1 ;//align

        union iregister ier ;
        union iregister ipr ;
        union iregister isr ;
        union iregister imr ;

        union iregister rasterline_events ;

        UBYTE   vr ;
        UBYTE   tacr ;
        UBYTE   tbcr ;
        UBYTE   tcdcr ;

        UBYTE  tbdr ;
        UBYTE  soft_eoi ;

        UBYTE void2,void3 ;     //align

        struct ttimer timers[4] ;

        int     next_timer ;     // timer number for next event
        int     next_cycles ;
        char dummy[64] ;
} ;


extern int timer_cycle2go ;
extern int timer_cycle2go_start  ;
extern int nbtimer_cycle2go ;


#define TIMERMODE_STOPPED       0
#define TIMERMODE_DELAY         1
#define TIMERMODE_EVENTCOUNT    2
#define TIMERMODE_PULSEWIDTH    3

extern UBYTE peek_tacr() ;
extern UBYTE peek_tbcr() ;
extern UBYTE peek_tcdcr() ;
extern UBYTE peek_tadr() ;
extern UBYTE peek_tbdr() ;
extern UBYTE peek_tcdr() ;
extern UBYTE peek_tddr() ;

extern struct info_mfp mfp ;

typedef struct {
        int calib_xmin,calib_xmax,calib_ymin,calib_ymax ;
        int lim_xmin, lim_xmax, lim_ymin, lim_ymax ;
        int sensitivity_xjoy ;
        int sensitivity_yjoy ;
} type_joy ;

extern char pacifist_minor ;
extern char pacifist_major ;

extern type_joy joystick1_vars ;
extern type_joy joystick2_vars ;

extern MPTR prevpc ;    // previous Program Counter

extern int keyboard_inbuf ;
extern int keyboard_outbuf ;
extern int keyboard_next_outbuf ;
extern int keyboard_wait ;
extern int keyboard_delay ;
extern char keyboard_buffer[KBDMAXBUF] ;

extern void disk_activity(int activ) ;
extern int modulo ;
extern int moduloy ;
extern int already_st_video ;
extern int special_patch ;

extern int withinselector ;
extern void init_fileselector(void) ;
extern void deinit_fileselector(void) ;
extern int YMrecording ;
extern int isYMrecord ;

extern char startdir[256] ;

extern int RefreshRate ;
extern int IsMonochrome ;
extern int IsFastVideo  ;
extern int isSamples ;
extern int isLeds  ;
extern int isPCDrive ;
extern int isLaptop ;
extern int isSTE ;
extern int isMIDI ;
extern int VideoMode ;
//extern int events_mask ;

extern unsigned int total_cycles ;

extern int IsBreakOnCycles ;

//extern int autojoy = ;    // all joy moves to be send to keyboard
extern int nb_joysticks_detected ;
//extern int ST_Joy0 ;
//extern int ST_Joy1 ;

//#define RAMSIZE 512*1024
//#define TOSBASE 0xfc0000

extern char *memory_ram ;
//extern int ramsize ;
extern int globalvolume ;
extern int isSerial ;
extern int isParallel  ;
extern int JoyEmu ;

extern int is68030 ;

extern volatile unsigned int  Global_PC_VBLs   ;

extern unsigned int breakopcode_msk ;
extern unsigned int breakopcode_cmp ;

extern int ModeST ;
//extern int quit_st_mode ;

#define SystemPatchOpcode       = 0x11bf ;    // followed by a command like:
#define SYSCMD_BOOT             = 1      ;    //    * boot (jump in $47A)
#define SYSCMD_INIT             = 2      ;    //    * initialisation
#define SYSCMD_DISKBPB          = 3      ;    //    * disk BPB
#define SYSCMD_DISKRW           = 4      ;    //    * read/write sector on disk
#define SYSCMD_LINEABASE        = 5      ;    //    * get base of LineA

extern unsigned short GoodByeScreen[] ;


extern int isSystemTimerC  ; // Timer C is 200Hz?

extern unsigned int thisraster_cycles ;
extern unsigned int RasterLine ;

extern int logIRQs[256] ;
extern int trapIRQs[256] ;
extern void LOGirq(int irq) ;

extern int  SystemBoot(void) ;
extern void SystemInit(void) ;
extern void SystemDiskBPB(void) ;
extern void SystemClose(void) ;
extern void SystemDiskRW(void) ;
extern void Reset_System(void) ;

extern unsigned int timer_read(void) ;

#ifdef DEBUGPROFILE
extern int     isprofile  ;
extern int     wasprofile  ;
extern int     profile[65536] ;
#define nb_profiles 42
typedef char profileNAME[9] ;
extern profileNAME profiles_group[nb_profiles] ;
#endif

extern unsigned int Relative_Speed ;
extern int Just_Enter_68000  ;

extern int Keyboard_Read() ;                    // return first key in buffer
extern int Keyboard_Write() ;                   // write a key in buffer
extern int Keyboard_Send() ;                    // send a command to 6301

extern MPTR TOSbase ;
extern MPTR TOSbaseMax ;

extern char tempdir[256] ;

extern int isSound ;

struct Entry_Instr_68000
{
        UWORD   AndMask ;
        UWORD   CmpMask ;
        char    Coding ;
        char    InstrName[6+1] ;
        UWORD   InstrInfo ;
} ;

struct DOSMEM {
        unsigned short  realmode_segment ;
        unsigned short  pmode_selector ;
        unsigned int    linear_base ;
} ;


extern unsigned int Total_Raster ;

// for DPMI

typedef struct RMREGS
{
        ULONG           edi;
        ULONG           esi;
        ULONG           ebp;
        ULONG           reserved;
        ULONG           ebx;
        ULONG           edx;
        ULONG           ecx;
        ULONG           eax;
        UWORD           flags;
        UWORD           es,ds,fs,gs,ip,cs,sp,ss;
} RMREGS;


//extern UBYTE mem[RAMSIZE] ;
extern UBYTE memtos[256*1024] ;
extern UBYTE memio[/*65536*/32768] ;
extern UBYTE memcartridge[/*2**/65536] ;

extern MPTR breakaccess[8] ;
extern char  breakaccess_rw[8] ;
extern int Nb_Breakaccess ;
extern MPTR breakpoints[8] ;
extern int Nb_Breakpoints ;
extern MPTR adr_breakaccess ;
extern int break_cycles;        // exception when nb_cycles = this

extern struct Entry_Instr_68000 Table_Instr_68000[] ;
extern int Opcodes_Jump[65536];
extern int Offset_Next ;
extern int Nb_Cycles ;
//extern int CyclesLeft ;

extern volatile unsigned int Nb_VBLs ;

extern unsigned int Local_PC_VBLs ;
extern unsigned int Nb_PC_VBLs ;

#define VIDEOEMU_SCREEN 0
#define VIDEOEMU_LINE   1
#define VIDEOEMU_MIXED  2
#define VIDEOEMU_CUSTOM 3
#define VIDEOEMU_NUMBERSOF 2

extern MPTR st_screen_ptr ;

extern int videoemu_type ;
//extern int LineOriented ;
extern int NativeSpeed ;

extern char Table_Conditions[16*256] ;

extern int MouseSensibility ;

/* simulation */

typedef struct  tprocessor{
#pragma pack (1) ;
        int     Offset_Next ;
        int     CyclesLeft ;
        int     D[8] ;
        int     A[8] ;
        int     A7 ;
        int     Return_After_Hard ;
        int     ramsize ;
        int     NZC ;
        int     V ;
        int     X ;
        int     SR ;
        int     SUPERVISOR ;
        int     IOPL ;
        int     New_IOPL ;
        int     ExceptionNumber ;
        int     events_mask ;
        int     PC ;
        int     Offset_Next_Direct ;
        int     Cycles_2_Go ;
        int     Cycles_Instructtion ;
        int     Cycles_This_Raster ;
        char    dummy[48] ;
};

extern int allocated_ram ;

#define ACTIVE_EVENT_RASTER   0x0000001
#define ACTIVE_EVENT_TIMERA   0x0000002
#define MAX_EVENTS 2

typedef struct Tevent {
#pragma pack (1) ;
        unsigned int event_time ;
        void *event_function ;
} ;

typedef struct TOSentry {
        char filename[124] ;
        char comments[124] ;
        unsigned int base ;
        unsigned short v1,v2 ;
} ;

extern int nb_tos ;
extern int current_tos ;
extern struct TOSentry TOStable[8] ;

extern struct tprocessor base_processor ;
extern struct tprocessor *processor ;

//extern int _PC ;//_D[8],_A[8],_A7 ;
//extern int _SR ;
//extern int _X ;
//extern int _V ;
//extern int _NZC ;
//extern int _SUPERVISOR ;
//extern int _IsException ;
//extern int _ExceptionNumber ;
//extern int _IOPL ;

extern void Reset_68000() ;
extern void Init_68000() ;
extern void Step_68000() ;
extern void Quit_68000() ;
extern void Do_DivideZero() ;
extern void Run_68000() ;

/* C */

extern int isdebugsys ;
//extern FILE *fdebug ;
extern void OUTDEBUG(char *string) ;


extern void enter_monitor() ;
extern void disa_instr(MPTR adr, char *disa_string, int *siz) ;

extern int allocdosmem(int paragraphs, struct DOSMEM *dosmem) ;
extern void freedosmem(struct DOSMEM *dosmem) ;

extern int isPrefetch ;
extern MPTR PrefetchPC ;

extern UBYTE read_st_byte(MPTR adress) ;    // general.c
extern UWORD read_st_word(MPTR ptr) ;
extern ULONG read_st_long(MPTR ptr) ;
extern void write_st_byte(MPTR adress,int value) ;
extern void write_st_word(MPTR adress,int value) ;
extern void write_st_long(MPTR adress,int value) ;
extern void *stmem_to_pc(MPTR adress) ;

extern void Test_PC_Joysticks(void) ;
extern void periodic_sound(void) ;

extern unsigned int STPort_Emu_Allowed ;
extern unsigned int STPort[2] ;

extern int bootexec ;

#define STPORT_EMU_NONE                 0x01
#define STPORT_EMU_PCJOY1               0x02
#define STPORT_EMU_PCJOY2               0x04
#define STPORT_EMU_NUMERICPAD           0x08

//                                                      exceptions

#define _EXCEPTION_0                           0
#define _EXCEPTION_1                           1
#define _EXCEPTION_BUSERROR                    2
#define _EXCEPTION_ADRESSERROR                 3
#define _EXCEPTION_ILLEGALINSTRUCTION          4
#define _EXCEPTION_ZERODIVIDE                  5
#define _EXCEPTION_CHK                         6
#define _EXCEPTION_TRAPV                       7
#define _EXCEPTION_PRIVILEGEVIOLATION          8
#define _EXCEPTION_TRACE                       9
#define _EXCEPTION_LINEA                       10
#define _EXCEPTION_LINEF                       11
#define _EXCEPTION_12                          12
#define _EXCEPTION_13                          13
#define _EXCEPTION_14                          14
#define _EXCEPTION_15                          15
#define _EXCEPTION_TRAP                        32
#define _EXCEPTION_VBL                         28
#define _EXCEPTION_ACIA                        70
#define _EXCEPTION_TIMERC                      69
#define _EXCEPTION_FDC                         71
#define _EXCEPTION_TIMERA                      77

#define _EXCEPTION_HBL                         26
#define _EXCEPTION_TIMERB                      72
#define _EXCEPTION_TIMERD                      68

#define _EXCEPTION_BREAKPOINT                  256
#define _EXCEPTION_BREAKACCESS                 257
#define _EXCEPTION_CYCLES                      258
#define _EXCEPTION_BREAKOPCODE                 259
#define _EXCEPTION_USER                        260
#define _EXCEPTION_SOFTRESET                   261
#define _EXCEPTION_HARDRESET                   262
#define _EXCEPTION_DISKSELECTOR                263
#define _EXCEPTION_DOUBLEBUS                   511

/*
 *       (de)coding modes of instruction set.
 *
 *  provide a way of checking invalid adressing mode
 */

#define coding_None             0
#define coding_ABCD             1
#define coding_ADD              2
#define coding_ADDA             3
#define coding_ADDI             4
#define coding_ADDQ             5
#define coding_ADDX             6
#define coding_AND              7
#define coding_i2CCR            8
#define coding_i2SR             9
#define coding_ASL_Dx           10
#define coding_ASL_EA           11
#define coding_BRA              12
#define coding_BCHG_Dx          13
#define coding_BCHG_n           14
#define coding_CHK              15
#define coding_CLR              16
#define coding_CMP              17
#define coding_CMPM             18
#define coding_DBF              19
#define coding_EOR              20
#define coding_EXG              21
#define coding_EXT              22
#define coding_JMP              23
#define coding_LEA              24
#define coding_LINK             25
#define coding_MOVE             26
#define coding_2CCR             27
#define coding_MOVEA            28
#define coding_2USP             29
#define coding_USP2             30
#define coding_SR2              31
#define coding_2SR              32
#define coding_MOVEM2mem        33
#define coding_MOVEMmem2        34
#define coding_MOVEP_2Dx        35
#define coding_MOVEP_Dx2        36
#define coding_MOVEQ            37
#define coding_NBCD             38
#define coding_STOP             39
#define coding_SWAP             40
#define coding_TRAP             41
#define coding_UNLK             42
#define coding_DATA             43
#define coding_PATCH            44
#define coding_MOVEC            45
#define coding_FPU              46

#endif
