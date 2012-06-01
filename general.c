#include "cpu68.h"
#include <stdio.h>

struct info_mfp mfp ;
int current_drive = 0 ;

MPTR prevpc ;
unsigned int total_cycles = 0;
int timer_cycle2go = 0;
int timer_cycle2go_start = 0 ;
int nbtimer_cycle2go ;

#define PatchedOpcode 0x11BF

int     RefreshRate = 1 ;
int     VideoMode ;

unsigned int PC_Base ;  // base for PC (0=ram,e00000=rom,fa0000=cart,ff8000=io)

char Table_Conditions[16*256] ;

# ifdef DEBUGPROFILE

        int     isprofile = FALSE ;
        int     wasprofile = FALSE ;
        int     profile[65536] ;
# endif


unsigned int Nb_PC_VBLs = 0 ;           // number of PC VBLs during ST mode
volatile unsigned int Global_PC_VBLs =0  ;       // number of PC VBLs (global)

int NativeSpeed = FALSE ;

char tempdir[256] ;
int isSound = TRUE ;
int globalvolume = 255 ;
int isSerial = TRUE ;
int isParallel = TRUE ;
int isLeds = TRUE ;
int isPCDrive = FALSE ;
int isLaptop = FALSE ;
int isSTE = FALSE ;
int isMIDI = FALSE ;

struct tprocessor *processor ;

int nb_tos = 0 ;
struct TOSentry TOStable[8] ;
int current_tos ;

char startdir[256] ;

int modulo = 0 ;
int moduloy=  0 ;
int MouseSensibility = 5;
int already_st_video  = FALSE ;
int special_patch = SPECIALPATCH_NONE ;
int YMrecording = FALSE ;
int isYMrecord = FALSE;

//int quit_st_mode ;
int Just_Enter_68000  = FALSE ;

//UBYTE mem[RAMSIZE] ;                    // RAM

char *memory_ram ;
//int ramsize = 1024*1024 ;

UBYTE memtos[256*1024] ;                // ROM
UBYTE memio[32768/*65536*/] ;                    // IO
UBYTE memcartridge[/*2**/65536] ;           // EXPANSION ROM

int IsFastVideo = TRUE ;
int is68030 = FALSE ;

/************************************* Joystick ****************************/

int JoyEmu = FALSE ;
int nb_joysticks_detected = 0;
//int ST_Joy0 ;                           // bits 0-3: directions, bit 7: fire
//int ST_Joy1 ;

unsigned int STPort_Emu_Allowed = 0;
unsigned int STPort[2] ;

/*
#define STPORT_EMU_NONE                 0x00
#define STPORT_EMU_PCJOY1               0x01
#define STPORT_EMU_PCJOY2               0x02
#define STPORT_EMU_NUMERICPAD           0x04
*/

char *STPort_Emu_Names[4] = {
        "        None        ",
        "   PC Joystick #1   ",
        "   PC Joystick #2   ",
        "     Numeric Pad    "
} ;


//int LineOriented = FALSE ;
int videoemu_type = VIDEOEMU_SCREEN ;

MPTR adr_breakaccess ;
MPTR breakpoints[8] ;
MPTR breakaccess[8] ;
char breakaccess_rw[8] ;
int Nb_Breakpoints = 0;
int Nb_Breakaccess = 0;
int break_cycles = 0 ;
int IsBreakOnCycles ;
int bootexec = TRUE ;
//int events_mask = 0 ;
int allocated_ram ;

int Opcodes_Jump[65536] ;
//int Offset_Next ;
//int Nb_Cycles ;

MPTR lineabase ;

int logIRQs[256] ;
int trapIRQs[256] ;

volatile unsigned int Nb_VBLs = 0;

char errormsg[] = "**** stmem_to_pc ERROR ****\n" ;

void *stmem_to_pc(MPTR adress)
{
        if (adress < processor->ramsize)
//                return &mem[adress] ;
                return memory_ram+adress ;
        if (adress > 0xff8000)
                return &memio[adress-0xff8000] ;

         if ((adress>=0xfa0000)&&(adress<0xfc0000))
              return &memcartridge[adress-0xfa0000] ;

         if ((adress>=TOSbase)&&(adress<(TOSbaseMax)))
              return &memtos[adress-TOSbase] ;

        return (void *)-1 ;
        //return &errormsg ;

}

UBYTE read_st_byte(MPTR adress)
{
         adress &=0xffffff ;            // 24 bits

         if (adress < processor->ramsize)
//             return mem[adress] ;
                return *(memory_ram+adress) ;

         if ((adress>=0xff8000))
              return memio[adress-0xff8000] ;

         if ((adress>=0xfa0000)&&(adress<0xfc0000))
              return memcartridge[adress-0xfa0000] ;

         if ((adress>=TOSbase)&&(adress<(TOSbaseMax)))
              return memtos[adress-TOSbase] ;

//        printf("\n***** error readingg adress %0x ******\n",adress) ;
        if (adress&1) return 0x55 ; else return 0xaa ;
}

UWORD read_st_word(ptr)
MPTR ptr ;
{
//        return (UWORD)(mem[ptr+1]+(mem[ptr]<<8)) ;

        return (UWORD)(read_st_byte(ptr+1)+(read_st_byte(ptr)<<8)) ;
} ;

ULONG read_st_long(ptr)
MPTR ptr ;
{
        return (ULONG)(read_st_word(ptr+2)+(read_st_word(ptr)<<16)) ;
} ;

void write_st_byte(MPTR adress, int value)
{
         adress &=0xffffff ;            // 24 bits

         if (adress < processor->ramsize)
//             {mem[adress]=value ; goto endw ;} ;
             {*(memory_ram+adress)=value ; goto endw ;} ;

         if ((adress>=0xff8000))
              {memio[adress-0xff8000]=value ; goto endw ;}

         if ((adress>=0xfa0000)&&(adress<0xfc0000))
              {memcartridge[adress-0xfa0000]=value;goto endw;}

         if ((adress>=TOSbase)&&(adress<(TOSbaseMax)))
              {memtos[adress-TOSbase]=value;goto endw ;}

//        printf("\n***** error writting adress %0x ******\n",adress) ;
endw:                                 ;
}

void write_st_word(MPTR adress, int value)
{
        write_st_byte(adress,value>>8) ;
        write_st_byte(adress+1,value&255) ;
}

void write_st_long(MPTR adress, int value)
{
        write_st_word(adress,value>>16) ;
        write_st_word(adress+2,value&65535) ;
}

#define _CCR    0
#define _SR     1
#define _USP    2
#define _MUL    3
#define _DB     4
#define _Scc    5
#define _BCD    6
#define _EXG    7
#define _Bcc    8
#define _BRA    9
#define _MOVEP  10
#define _TRAP   11
#define _BSR    12
#define _BTST   13
#define _ADDQ   14
#define _ADDA   15
#define _ADDI   16
#define _ADD    17
#define _ASR    18
#define _LSR    19
#define _ROR    20
#define _ROXR   21
#define _RTS    22
#define _AND    23
#define _EOR    24
#define _OR     25
#define _NOT    26
#define _MOVEM  27
#define _MOVEQ  28
#define _CLR    29
#define _CMP    30
#define _DIV    31
#define _EXT    32
#define _SWAP   33
#define _JMP    34
#define _MOVE   35
#define _NEG    36
#define _LINK   37
#define _TST    38
#define _NOP    39
#define _ADDX   40
#define _DCW    41

#define MC68030 0x80

#ifdef DEBUGPROFILE

profileNAME profiles_group[nb_profiles] =
              { "<op> CCR\0",
                "<op> SR \0",
                "MOVE USP\0",
                "MULu/s  \0",
                "DBcc    \0",
                "Scc     \0",
                "xBCD    \0",
                "EXG     \0",
                "Bcc     \0",
                "BRA     \0",
                "MOVEP   \0",
                "TRAPs   \0",
                "BSR     \0",
                "Bit inst\0",
                "add/subQ\0",
                "add/subA\0",
                "add/subI\0",
                "ADD/SUB \0",
                "ASr/l   \0",
                "LSr/l   \0",
                "ROr/l   \0",
                "ROXr/l  \0",
                "RTs/e/r \0",
                "AND     \0",
                "EOR     \0",
                "OR      \0",
                "NOT     \0",
                "MOVEM   \0",
                "MOVEQ   \0",
                "CLR     \0",
                "CMPs    \0",
                "DIVu/s  \0",
                "EXT     \0",
                "SWAP    \0",
                "JMP/JSR \0",
                "MOVE/LEA\0",
                "NEG/NEGX\0",
                "LiNKs   \0",
                "TST     \0",
                "NOP     \0",
                "add/subX\0",
                "rest... \0"
                      } ;
#endif

struct Entry_Instr_68000 Table_Instr_68000[] =
        {
        0xfffe , 0x4e7a , coding_MOVEC          , "MOVEC " ,_DCW|MC68030,
        0xf1c0 , 0xf000 , coding_FPU            , "FPU?  " ,_DCW|MC68030,

        0xffff , PatchedOpcode, coding_PATCH    , "PatCh " ,_DCW,
        0xffff , 0x023c , coding_i2CCR          , "ANDI  " ,_CCR,
        0xffff , 0x027c , coding_i2SR           , "ANDI  " ,_SR,
        0xffff , 0x0a3c , coding_i2CCR          , "EORI  " ,_CCR,
        0xffff , 0x0a7c , coding_i2SR           , "EORI  " ,_SR,
        0xffc0 , 0x44c0 , coding_2CCR           , "MOVE  " ,_CCR,
        0xfff8 , 0x4e60 , coding_2USP           , "MOVE  " ,_USP,
        0xfff8 , 0x4e68 , coding_USP2           , "MOVE  " ,_USP,
        0xffc0 , 0x40c0 , coding_SR2            , "MOVE  " ,_SR,
        0xffc0 , 0x46c0 , coding_2SR            , "MOVE  " ,_SR,
        0xffff , 0x007c , coding_i2SR           , "ORI   " ,_SR,
        0xffff , 0x003c , coding_i2CCR          , "ORI   " ,_CCR,
        0xf1c0 , 0xc1c0 , coding_CHK            , "MULS  " ,_MUL,
        0xf1c0 , 0xc0c0 , coding_CHK            , "MULU  " ,_MUL,
        0xfff8 , 0x54c8 , coding_DBF            , "DBCC  " ,_DB,
        0xfff8 , 0x55c8 , coding_DBF            , "DBCS  " ,_DB,
        0xfff8 , 0x57c8 , coding_DBF            , "DBEQ  " ,_DB,
        0xfff8 , 0x56c8 , coding_DBF            , "DBNE  " ,_DB,
        0xfff8 , 0x5cc8 , coding_DBF            , "DBGE  " ,_DB,
        0xfff8 , 0x5ec8 , coding_DBF            , "DBGT  " ,_DB,
        0xfff8 , 0x52c8 , coding_DBF            , "DBHI  " ,_DB,
        0xfff8 , 0x5fc8 , coding_DBF            , "DBLE  " ,_DB,
        0xfff8 , 0x53c8 , coding_DBF            , "DBLS  " ,_DB,
        0xfff8 , 0x5dc8 , coding_DBF            , "DBLT  " ,_DB,
        0xfff8 , 0x5bc8 , coding_DBF            , "DBMI  " ,_DB,
        0xfff8 , 0x5ac8 , coding_DBF            , "DBPL  " ,_DB,
        0xfff8 , 0x58c8 , coding_DBF            , "DBVC  " ,_DB,
        0xfff8 , 0x59c8 , coding_DBF            , "DBVS  " ,_DB,
        0xfff8 , 0x50c8 , coding_DBF            , "DBT   " ,_DB,
        0xfff8 , 0x51c8 , coding_DBF            , "DBF   " ,_DB,
        0xffc0 , 0x54c0 , coding_NBCD           , "SCC   " ,_Scc,
        0xffc0 , 0x55c0 , coding_NBCD           , "SCS   " ,_Scc,
        0xffc0 , 0x57c0 , coding_NBCD           , "SEQ   " ,_Scc,
        0xffc0 , 0x56c0 , coding_NBCD           , "SNE   " ,_Scc,
        0xffc0 , 0x5cc0 , coding_NBCD           , "SGE   " ,_Scc,
        0xffc0 , 0x5ec0 , coding_NBCD           , "SGT   " ,_Scc,
        0xffc0 , 0x52c0 , coding_NBCD           , "SHI   " ,_Scc,
        0xffc0 , 0x5fc0 , coding_NBCD           , "SLE   " ,_Scc,
        0xffc0 , 0x53c0 , coding_NBCD           , "SLS   " ,_Scc,
        0xffc0 , 0x5dc0 , coding_NBCD           , "SLT   " ,_Scc,
        0xffc0 , 0x5bc0 , coding_NBCD           , "SMI   " ,_Scc,
        0xffc0 , 0x5ac0 , coding_NBCD           , "SPL   " ,_Scc,
        0xffc0 , 0x58c0 , coding_NBCD           , "SVC   " ,_Scc,
        0xffc0 , 0x59c0 , coding_NBCD           , "SVS   " ,_Scc,
        0xffc0 , 0x50c0 , coding_NBCD           , "ST    " ,_Scc,
        0xffc0 , 0x51c0 , coding_NBCD           , "SF    " ,_Scc,
        0xf1f0 , 0xc100 , coding_ABCD           , "ABCD  " ,_BCD,
        0xf0c0 , 0xd0c0 , coding_ADDA           , "ADDA  " ,_ADDA,
        0xf130 , 0xd100 , coding_ADDX           , "ADDX  " ,_ADDX,
        0xff00 , 0x0600 , coding_ADDI           , "ADDI  " ,_ADDI,
        0xf000 , 0xd000 , coding_ADD            , "ADD   " ,_ADD,
        0xf100 , 0x5000 , coding_ADDQ           , "ADDQ  " ,_ADDQ,
        0xf130 , 0xc100 , coding_EXG            , "EXG   " ,_EXG,
        0xf000 , 0xc000 , coding_AND            , "AND   " ,_AND,
        0xff00 , 0x0200 , coding_ADDI           , "ANDI  " ,_AND,
        0xffc0 , 0xe0c0 , coding_ASL_EA         , "ASR   " ,_ASR,
        0xffc0 , 0xe1c0 , coding_ASL_EA         , "ASL   " ,_ASR,
        0xf118 , 0xe000 , coding_ASL_Dx         , "ASR   " ,_ASR,
        0xf118 , 0xe100 , coding_ASL_Dx         , "ASL   " ,_ASR,
        0xff00 , 0x6400 , coding_BRA            , "BCC   " ,_Bcc,
        0xff00 , 0x6500 , coding_BRA            , "BCS   " ,_Bcc,
        0xff00 , 0x6700 , coding_BRA            , "BEQ   " ,_Bcc,
        0xff00 , 0x6600 , coding_BRA            , "BNE   " ,_Bcc,
        0xff00 , 0x6c00 , coding_BRA            , "BGE   " ,_Bcc,
        0xff00 , 0x6e00 , coding_BRA            , "BGT   " ,_Bcc,
        0xff00 , 0x6200 , coding_BRA            , "BHI   " ,_Bcc,
        0xff00 , 0x6f00 , coding_BRA            , "BLE   " ,_Bcc,
        0xff00 , 0x6300 , coding_BRA            , "BLS   " ,_Bcc,
        0xff00 , 0x6d00 , coding_BRA            , "BLT   " ,_Bcc,
        0xff00 , 0x6b00 , coding_BRA            , "BMI   " ,_Bcc,
        0xff00 , 0x6a00 , coding_BRA            , "BPL   " ,_Bcc,
        0xff00 , 0x6800 , coding_BRA            , "BVC   " ,_Bcc,
        0xff00 , 0x6900 , coding_BRA            , "BVS   " ,_Bcc,
        0xff00 , 0x6000 , coding_BRA            , "BRA   " ,_BRA,
        0xf1b8 , 0x0108 , coding_MOVEP_2Dx      , "MOVEP " ,_MOVEP,
        0xf1b8 , 0x0188 , coding_MOVEP_Dx2      , "MOVEP " ,_MOVEP,
        0xf1c0 , 0x0140 , coding_BCHG_Dx        , "BCHG  " ,_BTST,
        0xffc0 , 0x0840 , coding_BCHG_n         , "BCHG  " ,_BTST,
        0xf1c0 , 0x0180 , coding_BCHG_Dx        , "BCLR  " ,_BTST,
        0xffc0 , 0x0880 , coding_BCHG_n         , "BCLR  " ,_BTST,
        0xf1c0 , 0x01c0 , coding_BCHG_Dx        , "BSET  " ,_BTST,
        0xffc0 , 0x08c0 , coding_BCHG_n         , "BSET  " ,_BTST,
        0xff00 , 0x6100 , coding_BRA            , "BSR   " ,_BSR,
        0xf1c0 , 0x0100 , coding_BCHG_Dx        , "BTST  " ,_BTST,
        0xffc0 , 0x0800 , coding_BCHG_n         , "BTST  " ,_BTST,
        0xf1c0 , 0x4180 , coding_CHK            , "CHK   " ,_TRAP,
        0xf0c0 , 0xb0c0 , coding_ADDA           , "CMPA  " ,_CMP,
        0xf138 , 0xb108 , coding_CMPM           , "CMPM  " ,_CMP,
        0xff00 , 0x0a00 , coding_ADDI           , "EORI  " ,_EOR,
        0xf100 , 0xb100 , coding_EOR            , "EOR   " ,_EOR,
        0xff00 , 0x0c00 , coding_ADDI           , "CMPI  " ,_CMP,
        0xf000 , 0xb000 , coding_CMP            , "CMP   " ,_CMP,
        0xf1c0 , 0x81c0 , coding_CHK            , "DIVS  " ,_DIV,
        0xf1c0 , 0x80c0 , coding_CHK            , "DIVU  " ,_DIV,
        0xffb8 , 0x4880 , coding_EXT            , "EXT   " ,_EXT,
        0xffff , 0x4afC , coding_None           , "ILLEGL" ,_TRAP,
        0xfff8 , 0x4840 , coding_SWAP           , "SWAP  " ,_SWAP,
        0xffc0 , 0x4ec0 , coding_JMP            , "JMP   " ,_JMP,
        0xffc0 , 0x4e80 , coding_JMP            , "JSR   " ,_JMP,
        0xf1c0 , 0x41c0 , coding_LEA            , "LEA   " ,_MOVE,
        0xfff8 , 0x4e50 , coding_LINK           , "LINK  " ,_LINK,
        0xe1c0 , 0x2040 , coding_MOVEA          , "MOVEA " ,_MOVE,
        0xff80 , 0x0000 , coding_ADDI           , "ORI   " ,_OR,
        0xffc0 , 0x0080 , coding_ADDI           , "ORI   " ,_OR,
        0xf000 , 0x1000 , coding_MOVE           , "MOVE  " ,_MOVE,
        0xe000 , 0x2000 , coding_MOVE           , "MOVE  " ,_MOVE,
        0xff80 , 0x4880 , coding_MOVEM2mem      , "MOVEM " ,_MOVEM,
        0xff80 , 0x4c80 , coding_MOVEMmem2      , "MOVEM " ,_MOVEM,
        0xf100 , 0x7000 , coding_MOVEQ          , "MOVEQ " ,_MOVEQ,
        0xffc0 , 0x4800 , coding_NBCD           , "NBCD  " ,_BCD,
        0xff00 , 0x4400 , coding_CLR            , "NEG   " ,_NEG,
        0xff00 , 0x4000 , coding_CLR            , "NEGX  " ,_NEG,
        0xffff , 0x4e71 , coding_None           , "NOP   " ,_NOP,
        0xff00 , 0x4600 , coding_CLR            , "NOT   " ,_NOT,
        0xffc0 , 0x4840 , coding_JMP            , "PEA   " ,_MOVE,
        0xf1f0 , 0x8100 , coding_ABCD           , "SBCD  " ,_BCD,
        0xf000 , 0x8000 , coding_AND            , "OR    " ,_OR,
        0xffff , 0x4e70 , coding_None           , "RESET " ,_TRAP,
        0xffc0 , 0xe6c0 , coding_ASL_EA         , "ROR   " ,_ROR,
        0xffc0 , 0xe7c0 , coding_ASL_EA         , "ROL   " ,_ROR,
        0xffc0 , 0xe4c0 , coding_ASL_EA         , "ROXR  " ,_ROXR,
        0xffc0 , 0xe5c0 , coding_ASL_EA         , "ROXL  " ,_ROXR,
        0xf118 , 0xe018 , coding_ASL_Dx         , "ROR   " ,_ROR,
        0xf118 , 0xe118 , coding_ASL_Dx         , "ROL   " ,_ROR,
        0xf118 , 0xe010 , coding_ASL_Dx         , "ROXR  " ,_ROXR,
        0xf118 , 0xe110 , coding_ASL_Dx         , "ROXL  " ,_ROXR,
        0xffc0 , 0xe2c0 , coding_ASL_EA         , "LSR   " ,_LSR,
        0xffc0 , 0xe3c0 , coding_ASL_EA         , "LSL   " ,_LSR,
        0xf118 , 0xe008 , coding_ASL_Dx         , "LSR   " ,_LSR,
        0xf118 , 0xe108 , coding_ASL_Dx         , "LSL   " ,_LSR,
        0xffff , 0x4e73 , coding_None           , "RTE   " ,_RTS,
        0xffff , 0x4e77 , coding_None           , "RTR   " ,_RTS,
        0xffff , 0x4e75 , coding_None           , "RTS   " ,_RTS,
        0xf0c0 , 0x90c0 , coding_ADDA           , "SUBA  " ,_ADDA,
        0xf130 , 0x9100 , coding_ADDX           , "SUBX  " ,_ADDX,
        0xff00 , 0x0400 , coding_ADDI           , "SUBI  " ,_ADDI,
        0xf000 , 0x9000 , coding_ADD            , "SUB   " ,_ADD,
        0xf100 , 0x5100 , coding_ADDQ           , "SUBQ  " ,_ADDQ,
        0xffff , 0x4e72 , coding_STOP           , "STOP  " ,_TRAP,
        0xfff0 , 0x4e40 , coding_TRAP           , "TRAP  " ,_TRAP,
        0xffff , 0x4e76 , coding_None           , "TRAPV " ,_TRAP,
        0xffc0 , 0x4ac0 , coding_NBCD           , "TAS   " ,_MOVE,
        0xff00 , 0x4a00 , coding_CLR            , "TST   " ,_TST,
        0xfff8 , 0x4e58 , coding_UNLK           , "UNLK  " ,_LINK,
        0xff00 , 0x4200 , coding_CLR            , "CLR   " ,_CLR,
        0x0000 , 0x0000 , coding_DATA           , "DC.W  " ,_DCW
        } ;
