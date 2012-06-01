#include <stdlib.h>
#include <i86.h>
#include <io.h>
#include <conio.h>
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <direct.h>
#include "cpu68.h"
#include "disk.h"
#include "config.h"
#include "kb.h"
#include "vbe.h"
#include "timer.h"
#include "eval.h"

#define _col_help 10
#define _col_regs 3
#define _col_pc   15
#define _col_excp 0x70
#define _col_input 14
#define _col_err 0x7f
#define _col_brk 5
#define _col_normal 7

extern int nb_variables  ;
extern struct {
        char name[16] ;
        int attrib ;
        int value ;
} variables[] ;

extern void disk_selector(void) ;

//extern void Enter_ST_Screen(void) ;
//extern void Quit_ST_Screen(void) ;

extern int needcycles ;
extern unsigned int lastEA ;    // in simu68.asm (EDI at any time)

extern int isAutoRun ;

static int      currenty ;
static int      silent = FALSE ;
static int      istrap = TRUE;
static char     cmd[80], *parameters ;
static char     nullchar = 0 ;
static short    sscreen[80*50] ;
static MPTR     lastdisa = 0;
static MPTR     lastdump = 0;

unsigned int    breakopcode_msk = 0;
unsigned int    breakopcode_cmp = 0xffff;

static MPTR     window_disa_base ;
static MPTR     window_disa_start = 7 ;
static MPTR     window_disa_length = 13 ;
static MPTR     window_free_start = 20 ;

static void     do_config(void) ;

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                INPUT / OUTPUT routines
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

static int is_ctrl(void)
{
        union REGS regs ;

        regs.h.ah = 2 ;
        int386(0x16,&regs,&regs) ;      // SHIFT Status
        return ((regs.h.al&0x4)!=0) ;   // 0:rshift,1:lshift,2:ctrl,3:alt
}

static void setcursor(int x, int y)
{
        union REGS regs ;

        regs.h.ah = 1 ;
        regs.h.ch = 6 ;
        regs.h.cl = 7 ;
        int386(0x10,&regs,&regs) ;

        regs.h.ah = 2 ;
        regs.h.bh = 0 ;
        regs.h.dh = y ;
        regs.h.dl = x ;
        int386(0x10,&regs,&regs) ;

}

// [fold]  [
static void skip_spaces(char **pt)
{
   while (**pt && ((**pt==' ')||(*pt=='\t')  /*||(*pt==13)||(*pt==10)*/   ))
            (*pt)++ ;
}

// [fold]  ]


static int Read_Number(int *v,int verbose)
{
        int stat,value;
        char *msg ;
        char *e,estring[128] ;
        int nbbra = 0 ;

        skip_spaces(&parameters) ;

        e = estring ;
        while ((nbbra>=0)/*(*parameters!=']')*/&&(*parameters!=' ')&&(*parameters)) {
                if (*parameters == '[') nbbra += 1 ;
                *e++ = *parameters++ ;
                if (*parameters == ']') nbbra -= 1 ;
        }

        *e = 0 ;

        stat = evaluator(estring,&value,&msg) ;
        if (stat&&verbose) print_string(0x70,msg) ;
        *v = value ;
        return stat ;
}

// [fold]  [
void deinit_gfx(void)
{
        int x ;
        short *video ;
        union REGS regs;

//        Quit_ST_Screen() ;

        already_st_video  = FALSE ;

        regs.w.ax = 0x1202 ;
        regs.h.bl = 0x30 ;
        int386(0x10,&regs,&regs) ;
        regs.w.ax = 3 ;
        int386(0x10,&regs,&regs) ;
        regs.w.ax = 0x1112 ;
        regs.h.bl = 0 ;
        int386(0x10,&regs,&regs) ;

        video = (short *)0xb8000 ;
        for (x=0;x<80*50;x++) *video++ = sscreen[x] ;
}

// [fold]  ]

// [fold]  [
void init_gfx()
{
//        union REGS regs;

        int x ;
        short *video ;
        video = (short *)0xb8000 ;
        for (x=0;x<80*50;x++) sscreen[x] = *video++ ;

        already_st_video  = FALSE ;

//        Enter_ST_Screen() ;

}

// [fold]  ]

// [fold]  [
static void scroll()
{
        int l,x ;
        short *pt  = (short *)(0xb8000+(window_free_start*160)) ;
        short *pt2 = pt+80 ;

        for (l=0;l<(50-window_free_start);l++) {
                for (x=0;x<64;x++)
                        *pt++ = *pt2++ ;

                pt += 16 ;
                pt2 += 16 ;
        }

}

// [fold]  ]

// [fold]  [
static void display_string(int x, int y, int a, char *str)
{
        int c ; int tab ;

        char *video = (char *)(0xb8000+(y*160)+x*2) ;
        while (*str) {
                c = *str++ ;
                if (c==9)               // tabulation
                        for (tab=x&0x3c;tab<x+1;tab++)
                                {*video++= ' ' ; *video++ = a ;}
                else                    // normal char
                        {
                         *video++ = c ;
                         *video++ = a ;
                        }
                x++ ;
        } ;
}

// [fold]  ]

// [fold]  [
static void print_string(int a, char *str)
{
        if (silent) return ;
        display_string(0,currenty,a,str) ;
        if (currenty == 49) scroll() ;else currenty++ ;
}

// [fold]  ]

// [fold]  (
static void display_bar()
{
        char b[140] ;

        char b_screen[32] ;
        char b_speed[20] ;
        char b_samples[10] ;
        char b_color[10] ;

        switch(videoemu_type) {
                case VIDEOEMU_SCREEN:
                        strcpy(b_screen,"F1:SCR/line/mix±F2:VBE") ;
                        break ;
                case VIDEOEMU_LINE:
                        strcpy(b_screen,"F1:scr/LINE/mix±F2:VBE") ;
                        break ;
                case VIDEOEMU_MIXED:
                        strcpy(b_screen,"F1:scr/line/MIX±F2:VBE") ;
                        break ;
                case VIDEOEMU_CUSTOM:
                        strcpy(b_screen,"  CUSTOM SCREEN mode  ") ;
                        break ;
        }

        if (NativeSpeed)
              strcpy(b_speed,"MAX Speed") ;
        else  strcpy(b_speed," ST Speed") ;

        if (isSamples)
                strcpy(b_samples," On") ;
        else    strcpy(b_samples,"Off") ;

        if (IsMonochrome)
                strcpy(b_color,"MONO/color") ;
        else    strcpy(b_color,"mono/COLOR") ;

        sprintf(b,"%s±F3:%s±F4:Joyports±F5:Samples %s±F10:%s",b_screen,b_speed,b_samples,b_color);
        display_string(0,0,0x1f,b) ;
        display_string(62,1,0x1f,"±F12:Disk") ;

}

// [fold]  )

// [fold]  (
static void print_exception_number(int exception)
{
        char b[80] ;
        switch(exception) {
         case _EXCEPTION_BUSERROR               : sprintf(b,"*** Exception  2: Bus Error ***") ; break ;
         case _EXCEPTION_ADRESSERROR            : sprintf(b,"*** Exception  3: Adress Error ***") ; break ;
         case _EXCEPTION_ILLEGALINSTRUCTION     : sprintf(b,"*** Exception  4: Illegal Instruction ***") ; break ;
         case _EXCEPTION_ZERODIVIDE             : sprintf(b,"*** Exception  5: Zero Divide ***") ; break ;
         case _EXCEPTION_CHK                    : sprintf(b,"*** Exception  6: CHK ***") ; break ;
         case _EXCEPTION_TRAPV                  : sprintf(b,"*** Exception  7: TRAPV ***") ; break ;
         case _EXCEPTION_PRIVILEGEVIOLATION     : sprintf(b,"*** Exception  8: Privilege Violation ***") ; break ;
         case _EXCEPTION_TRACE                  : sprintf(b,"*** Exception  9: TRACE mode ***") ; break ;
         case _EXCEPTION_LINEA                  : sprintf(b,"*** Exception 10: Line-A ***") ; break ;
         case _EXCEPTION_LINEF                  : sprintf(b,"*** Exception 11: Line-F ***") ; break ;
         case _EXCEPTION_BREAKPOINT             : sprintf(b,"*** breakpoint reached at %08x ***",processor->PC) ; break ;
         case _EXCEPTION_BREAKACCESS            : sprintf(b,"*** breakaccess reached at %08x ***",adr_breakaccess) ; break ;
         case _EXCEPTION_CYCLES                 : sprintf(b,"*** break on cycles count = %x ***",Nb_Cycles) ;break;
         case _EXCEPTION_BREAKOPCODE            : sprintf(b,"*** breakopcode reached at %08x ***",adr_breakaccess) ; break ;
         case _EXCEPTION_USER                   : sprintf(b,"*** USER BREAK ***") ; break ;
         case _EXCEPTION_DOUBLEBUS              : sprintf(b,"*** Double Bus Error - 68000 Hangs ***") ; break ;
         case _EXCEPTION_TIMERA                 : sprintf(b,"*** MFP TIMER A [vector 0x4D/77 at $134]") ; break ;
         case _EXCEPTION_TIMERB                 : sprintf(b,"*** MFP TIMER B [vector 0x48/72 at $120]") ; break ;
         case _EXCEPTION_TIMERC                 : sprintf(b,"*** MFP TIMER C [vector 0x45/69 at $114]") ; break ;
         case _EXCEPTION_TIMERD                 : sprintf(b,"*** MFP TIMER D [vector 0x44/68 at $110]") ; break ;
         case _EXCEPTION_ACIA                   : sprintf(b,"*** MFP ACIA [vector 0x46/70 at $118]") ; break ;
         case _EXCEPTION_VBL                    : sprintf(b,"*** Vertical Blank [vector 0x1C/28 at $70]") ; break ;
         case _EXCEPTION_HBL                    : sprintf(b,"*** Horizontal Blank [vector 0x1A/26 at $68]") ; break ;
         case _EXCEPTION_FDC                    : sprintf(b,"*** MFP FDC Interrupt [vector 0x47/71 at $11C]") ; break ;

         case 32:case 33:case 34:case 35:
         case 36:case 37:case 38:case 39:
         case 40:case 41:case 42:case 43:
         case 44:case 45:case 46:case 47        : sprintf(b,"*** TRAP %d ***",exception-32) ; break;
         default                                : sprintf(b,"*** Exception %d ***",exception) ;
        }
        print_string(_col_excp,b) ;

}



// [fold]  [
void print_dump(MPTR pc, int nb)
{

        int b,i,l ;
        char buf[80],buf2[80];
        char bufa[80] ;
        char *pta ;       //ascii

        bufa[0] = bufa[1] = ' ' ;
        for (l=0;l<nb;l++)                              // each dump line
        {
                pta = bufa+2 ;
                sprintf(buf,"%08x : ",pc) ;
                for (i=0;i<8;i++) {
                  b = read_st_byte(pc++) ;
                  sprintf(buf2,"%02x ",b) ;
                  strcat(buf,buf2) ;
                  if (b) *pta++ = b ; else *pta++=' ' ;

                }
        *pta++ = '\0' ;
        strcat(buf,bufa) ;
        print_string(7,buf) ;
        } ;
        lastdump = pc ;
}

// [fold]  ]

// [fold]  )

#ifdef DEBUG
// [fold]  [
void LOGirq(int exception)
{
        char b[150],buf[150] ;
        MPTR l ;
        int k ;
        int istotrace = TRUE ;

        if (TRUE/*logIRQs[exception]*/)
        switch(exception) {
         case _EXCEPTION_BUSERROR               : sprintf(b,"*** Exception  2: Bus Error ***") ; break ;
         case _EXCEPTION_ADRESSERROR            : sprintf(b,"*** Exception  3: Adress Error ***") ; break ;
         case _EXCEPTION_ILLEGALINSTRUCTION     : sprintf(b,"*** Exception  4: Illegal Instruction ***") ; break ;
         case _EXCEPTION_ZERODIVIDE             : sprintf(b,"*** Exception  5: Zero Divide ***") ; break ;
         case _EXCEPTION_CHK                    : sprintf(b,"*** Exception  6: CHK ***") ; break ;
         case _EXCEPTION_TRAPV                  : sprintf(b,"*** Exception  7: TRAPV ***") ; break ;
         case _EXCEPTION_PRIVILEGEVIOLATION     : sprintf(b,"*** Exception  8: Privilege Violation ***") ; break ;
         case _EXCEPTION_TRACE                  : sprintf(b,"*** Exception  9: TRACE mode ***") ; break ;
         case _EXCEPTION_LINEA                  : sprintf(b,"*** Exception 10: Line-A ***") ; break ;
         case _EXCEPTION_LINEF                  : sprintf(b,"*** Exception 11: Line-F ***") ; break ;
         case 32:case 33:case 35:
         case 36:case 37:case 38:case 39:
         case 40:case 41:case 42:case 43:
         case 44:case 45:case 46:case 47:         sprintf(b,"*** TRAP %d ***",exception-32) ; break;
         case 34                                : l = read_st_long(processor->D[1]) ;
                                                  sprintf(buf,"*** TRAP #2 - AES/VDI*** D0=%08x  D1=%08x\n",processor->D[0],l) ;
                                                  OUTDEBUG(buf) ;
                                                  buf[0] = 0 ;
                                                  strcat(buf,"contrl:\n") ;
                                                  for (k=0;k<6;k++)
                                                       { sprintf(b,"\t\t[%d]=%04x\t[%d]=%04x\n",k*2,read_st_word(l+k*4),k*2+1,read_st_word(l+k*4+2)) ;
                                                         strcat(buf,b) ;
                                                       }
                                                  OUTDEBUG(buf) ;
                                                  b[0] = 0 ;
                                                  break ;
         case _EXCEPTION_VBL                    : sprintf(b,"*** Vertical Blank Interrupt ***") ; break ;
         case _EXCEPTION_ACIA                   : sprintf(b,"*** Keyboard ACIA Interrupt ***") ; break ;
         case _EXCEPTION_TIMERA                 : sprintf(b,"*** Timer A Interrupt ***") ; break ;
         case _EXCEPTION_TIMERC                 : sprintf(b,"*** Timer C Interrupt ***") ; break ;
         case _EXCEPTION_TIMERB                 : sprintf(b,"*** MFP TIMER B [vector 0x48/72 at $120]") ; break ;
         case _EXCEPTION_TIMERD                 : sprintf(b,"*** MFP TIMER D [vector 0x44/68 at $110]") ; break ;
         case _EXCEPTION_HBL                    : sprintf(b,"*** Horizontal Blank [vector 0x1A/26 at $68]") ; break ;
         case _EXCEPTION_FDC                    : sprintf(b,"*** MFP FDC Interrupt [vector 0x47/71 at $11C]") ; break ;

         default : istotrace=FALSE ;
        }
        else istotrace=FALSE ;

        if (istotrace)
        {
                sprintf(buf," PC=%08X  SR=%04X A7=%08x\n     %04x         %04x %04x %04x %04x %04x %04x %04x\n\n",
                processor->PC,processor->SR,processor->A[7],read_st_word(processor->A[7]),read_st_word(processor->A[7]+2),read_st_word(processor->A[7]+4),read_st_word(processor->A[7]+6),
                read_st_word(processor->A[7]+8),read_st_word(processor->A[7]+10),read_st_word(processor->A[7]+12),read_st_word(processor->A[7]+14)) ;
                strcat(b,buf) ;
                OUTDEBUG(b) ;
        }
}

// [fold]  ]
#endif

static int readkey(void)
{
        while (!isspecialkey&&!kbhit()) ;
        if (!isspecialkey) return getch() ;
        if (kbhit()) getch() ;
        return specialkey ;
}


static char doskey[128][80] ;
static int curdoskey = 0;

// [fold]  (
static void input_string()
{
        int ch ;
        char *pt ;
        int curdoskey2 = curdoskey ;

        pt = cmd ;
        display_string(0,currenty,0x10,"                                                             ") ;
        setcursor(pt-cmd,currenty) ;

        while ((ch=readkey())!=0xd) {
                if (is_ctrl()) {
                        ctrl_keys(ch+0x60) ;
                        continue ;
                }

                if (isspecialkey) {

                        isspecialkey = FALSE ;

                  if (ch==KEY_F1) {
                        //if (!vbe_ok) continue ;
                        //LineOriented = ~LineOriented ;
                       if (videoemu_type==VIDEOEMU_CUSTOM) continue ;

                        videoemu_type++ ;
                        if ((videoemu_type==VIDEOEMU_MIXED)&&!vbemode_for_mixed)
                                videoemu_type++ ;
                        if (videoemu_type>VIDEOEMU_NUMBERSOF) videoemu_type = 0 ;
                        display_bar() ;
                        continue ;
                  }

                  if (ch==KEY_F2) {
                        if ((videoemu_type==VIDEOEMU_CUSTOM)||!vbe_ok) continue ;
                        do_config() ;
                        continue ;
                  }

                  if (ch==KEY_F3) {
                        NativeSpeed = TRUE-NativeSpeed ;
                        display_bar() ;
                        if (!NativeSpeed) Cycles_Per_RasterLine = 512 ;
                        continue ;
                  }

                  if (ch==KEY_F4) {
/*                        JoyEmu = TRUE-JoyEmu ; */
                        do_joysticks() ;
                        display_bar() ;

                        continue ;
                  }

                  if (ch==KEY_F5) {
                        isSamples = TRUE-isSamples ;
                        display_bar() ;
                        continue ;
                  }

                  if (ch==KEY_F12) {
                        do_changedisk() ;
                        continue ;
                  }

                  if (ch==KEY_F10) {
                        IsMonochrome = TRUE-IsMonochrome ;
                        reset_machine(TRUE) ;
                        display_bar() ;
                        continue ;
                  }


                }
/*
                if (ch==KEY_F4) {
                        do_changedisk(1) ;
                        continue ;
                }
*/


                 if (isextendedkey&&(ch==KEY_DOWN)) {
                        curdoskey2 = (curdoskey2+1)&127 ;
                        strncpy(cmd,doskey[curdoskey2],80) ;
                        pt = cmd+strlen(cmd) ;
                        goto conti ;
                 }

                 if (isextendedkey&&(ch==KEY_UP)) {
                        curdoskey2 = (curdoskey2-1)&127 ;
                        strncpy(cmd,doskey[curdoskey2],80) ;
                        pt = cmd+strlen(cmd) ;
                        goto conti ;
                 }

          if (!isextendedkey)
           if (ch>31) *pt++ = ch ;
                else if (ch==27)
                        pt=cmd ;
                else if (ch == 8) // DEL
                        if (cmd!=pt) *pt-- = '\0' ;
conti:
          *pt = '\0' ;
          display_string(0,currenty,0x10,"                                                             ") ;
          display_string(0,currenty,0x1f,cmd) ;
          setcursor(pt-cmd,currenty) ;
        }
        *pt++ = '\0' ;
        *pt++ = '\0' ;
        *pt++ = '\0' ;
        *pt = '\0' ;
        display_string(0,currenty,0x0,"                                                             ") ;
        print_string(_col_input,cmd) ;

        strncpy(doskey[curdoskey],cmd,80) ;
        curdoskey = (curdoskey+1)&127 ;
}

// [fold]  )

// [fold]  [
static int iscmd(char *test, char *string)
{
        parameters = string ;
        while (*test) {
                if (!*parameters) return FALSE ;
                if (*test++ != ((*parameters++)|0x20)) return FALSE ;
         }

         while (*parameters==' ') parameters++ ;
         return TRUE ;
}

// [fold]  ]

static int is_in_breakpoints_list(MPTR address)
{
        int i ;
        for (i=0;i<Nb_Breakpoints;i++)
                if (breakpoints[i] == address) return (i+1) ;
        return 0 ;
}

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                             DISASSEMBLING MODULE CALLS
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

#define SPECIAL_NONE    0x0000
#define SPECIAL_PC      0x0001
#define SPECIAL_BRKPT   0x0002

// [fold]  [
static void disa_line(MPTR ad,char *buf,int *siz,int *special)
{
        int i ;
        char    st[80],buf2[80] ;

        *special = SPECIAL_NONE ;
        if (ad == processor->PC)
                *special |= SPECIAL_PC ;        // current line is PC
        if (is_in_breakpoints_list(ad))
                *special |= SPECIAL_BRKPT ;     // current line is BREAKPOINT

        disa_instr(ad,st,siz) ;
        sprintf(buf,"%06X ",ad) ;
        for (i=0;i<*siz;i++) {
                sprintf(buf2,"%02x",(char)read_st_byte(ad++)) ;
                strcat(buf,buf2) ;
        }
        for (i=*siz;i<11;i++)
                strcat(buf,"  ") ;
        strcat(buf,st) ;

        if (*special&SPECIAL_BRKPT)
                buf[28] = '*' ;
}

// [fold]  ]

// [fold]  [
static void print_disa(MPTR pc, int nb) {

        int l,siz,special ;
        char st[80] ;

        for (l=0;l<nb;l++)
        {
                disa_line(pc,st,&siz,&special) ;
                if (special&SPECIAL_PC)
                        print_string(15,st) ;
                else
                        print_string(7,st) ;
                pc+=siz;
        } ;
        lastdisa = pc ;
}

// [fold]  ]

// [fold]  [
static MPTR address_for_disa(MPTR ad, int nb)  // starting adress for exact DISA
{
        MPTR    prec ;
        int     range,i,siz ;
        char    dummy[80] ;

        range = nb*10 ;
        while (range >= nb*2) {         // range from pc-2*n to pc-10*n

                prec = ad-range ;
                for (i=0;i<nb;i++) {
                        disa_instr(prec,dummy,&siz) ;
                        prec+=siz;
                }

                if (prec==ad) return (ad-range) ;
                range -= 2 ;
        }

        return ad ;
}

// [fold]  ]

// [fold]  [
static void display_disa_window(MPTR address,int start,int length)
{
        int     l,siz,special ;
        MPTR    ad ;
        char    st[80] ;

        ad = address_for_disa(address,(length>>1)-1) ;

        display_string(0,start,15,"-----------------------------------------------------------") ;
        display_string(0,start+length-1,15,"-----------------------------------------------------------") ;

        for (l=1;l<length-1;l++)
        {
                disa_line(ad,st,&siz,&special) ;
                display_string(0,start+l,0,"                                                              ") ;
                if (special&SPECIAL_PC)
                        display_string(0,start+l,15,st) ;
                else
                        display_string(0,start+l,7,st) ;
                ad+=siz;
        }


}

// [fold]  ]

// [fold]  [
static void out_disa(void)
{
        int l,siz ;
        int fx,fn,fz,fv,fc ;
        char st[80],buf[80] ;

        if ((lastEA > processor->ramsize)&&(lastEA<TOSbase))
                lastEA = 0 ;


        fx = ((processor->SR&0x10)==0x10) ;
        fn = ((processor->SR&0x08)==0x08) ;
        fz = ((processor->SR&0x04)==0x04) ;
        fv = ((processor->SR&0x02)==0x02) ;
        fc = ((processor->SR&0x01)==0x01) ;
        for (l=0;l<4;l++) {
                sprintf(buf,"\t\tD%d = %08x  D%d = %08x  A%d = %08x  A%d = %08x",l,processor->D[l],l+4,processor->D[l+4],l,processor->A[l],l+4,processor->A[l+4]) ;
                OUTDEBUG(buf) ;
        }
        sprintf(buf,"\t\tCycles = %08x SR = %04x  X=%d N=%d Z=%d V=%d C=%d  %08x\n",processor->Cycles_2_Go,processor->SR,fx,fn,fz,fv,fc,processor->A7) ;
        OUTDEBUG(buf) ;

        sprintf(buf,"\t\t\t\t\t%08x [%04x %04x]  RASTER=%d\n",lastEA,read_st_word(lastEA),read_st_word(lastEA+2),RasterLine) ;
        OUTDEBUG(buf) ;

        disa_instr(processor->PC, st, &siz) ;
        sprintf(buf,"%08x : %s\n",processor->PC,st) ;
        OUTDEBUG(buf) ;

}

// [fold]  ]

extern void Init_MFP() ;

// [fold]  [
void reset_machine(int hard)
{
        int i ;
#ifdef SOUND
        Reset_Sound() ;
#endif
        processor->ramsize = allocated_ram ;
        Init_MFP() ;

        if (hard) {
                write_st_long(0x426,0) ;        // no RESET user routine
                for (i=0;i<0x7fff;i++)
                        memio[i] = 0 ;
                for (i=0;i<processor->ramsize;i++)
                        memory_ram[i] = 0 ;
        }


        Reset_68000() ;
        Reset_System() ; // in sys.c -> close image files...
        processor->PC = TOSbase ;
        Nb_Cycles = 0 ;

        Reset_Keyboard() ;

        st_screen_ptr = 0 ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                      DISPLAY REGISTERS
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void display_registers()
{
        int i,l ;
        int siz;
        int fx,fn,fz,fv,fc ;
        char st[80], buf[80] ;

        display_bar() ;

        fx = ((processor->SR&0x10)==0x10) ;
        fn = ((processor->SR&0x08)==0x08) ;
        fz = ((processor->SR&0x04)==0x04) ;
        fv = ((processor->SR&0x02)==0x02) ;
        fc = ((processor->SR&0x01)==0x01) ;

        for (l=0;l<4;l++) {
                sprintf(buf,"D%d = %08x  D%d = %08x  A%d = %08x  A%d = %08x",l,processor->D[l],l+4,processor->D[l+4],l,processor->A[l],l+4,processor->A[l+4]) ;
                display_string(0,l+1,_col_regs,buf) ;
        }
        sprintf(buf,"Cycles = %08x SR = %04x  X=%d N=%d Z=%d V=%d C=%d  %08x",total_cycles+thisraster_cycles,processor->SR,fx,fn,fz,fv,fc,processor->A7) ;
        display_string(0,5,_col_regs,buf) ;
        disa_instr(processor->PC,st,&siz) ;
        sprintf(buf,"PC=%8x : %s",processor->PC,st) ;
        strcat(buf," ...                       ") ;
        display_string(0,6,/*_col_pc*/10,buf) ;

        sprintf(buf,"Potential Speed") ;
        display_string(60,2,0x6e,buf) ;
        if (NativeSpeed) {
/*
                sprintf(buf,"Cycles/Raster") ;
                display_string(60,1,0x6e,buf) ;
                sprintf(buf,"is %4d      ",Cycles_Per_RasterLine) ;
                display_string(60,2,0x6e,buf) ;
*/
                sprintf(buf,"is %#7.3f%% ",((float)(Cycles_Per_RasterLine*100))/512) ;
                display_string(60,3,0x6e,buf) ;

        }
        else {
                sprintf(buf,"is %#7.3f%% ",((float)Relative_Speed*100.0)/65536.0) ;
                display_string(60,3,0x6e,buf) ;
        }

        sprintf(buf,"%d - %d",RasterLine,Total_Raster) ;
        display_string(60,4,10,buf) ;

        sprintf(buf,"  [A7=%08X]  ",processor->A[7]) ;
        display_string(62,6,12,buf) ;
        l = processor->A[7] ;
        for (i=0;i<4;i++) {
                sprintf(buf,"%08x %08x",read_st_long(l), read_st_long(l+4)) ;
                display_string(62,7+i,12,buf) ;
                l += 8 ;
        }

        sprintf(buf,"BRKPT [%2d]",Nb_Breakpoints) ;
        display_string(69,12,0x2f,buf) ;
        for (i=0;i<16;i++) {
                if (i >= Nb_Breakpoints)
                        strcpy(buf,"        ") ;
                else
                        sprintf(buf,"%08x",breakpoints[i]) ;
                display_string(70,13+i,6,buf) ;
        }

        sprintf(buf,"BRKAC [%2d]",Nb_Breakaccess) ;
        display_string(69,30,0x2f,buf) ;
        for (i=0;i<16;i++) {
                if (i >= Nb_Breakaccess)
                        display_string(70,31+i,12,"          ") ;
                else {
                        sprintf(buf,"%08x",breakaccess[i]) ;
                        display_string(70,31+i,12,buf) ;
                        sprintf(buf,"%c",breakaccess_rw[i]) ;
                        display_string(79,31+i,10,buf) ;
                }
        }


        sprintf(buf,"%08X",timer_cycle2go) ;
        display_string(70,48,15,buf) ;

        display_string(70,46,0x2f,"BRKOPCODE") ;
        sprintf(buf,"%04X %04X",breakopcode_msk, breakopcode_cmp) ;
        display_string(70,47,6,buf) ;

        sprintf(buf,"%08X",prevpc) ;
        display_string(70,49,7,buf) ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                               DISPLAY SYSTEM STATUS (drives, MFP, ...)
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

static int read_b(MPTR a)
{
        return read_st_byte(a) ;
}

// [fold]  [
static void do_status()
{
        char b[256] ;
        int i ;

        sprintf(b,"ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ DRIVES STATUS ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ") ;
        print_string(15,b) ;
        for (i=0;i<nb_drives;i++)
         if (drives[i].kind) {
                sprintf(b,"%c: <=> %s",i+'A',drives[i].basepath) ;
                print_string(7,b) ;
        }
        sprintf(b,"ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ MFP ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ") ;
        print_string(15,b) ;

        sprintf(b,"enable IERA=%02x   pending IPRA=%02x   in-serv ISRA=%02x   masked IMRA=%02x",read_b(0xfffa07),read_b(0xfffa0b),read_b(0xfffa0f),read_b(0xfffa13)) ;
        print_string(7,b) ;
        sprintf(b,"enable IERB=%02x   pending IPRB=%02x   in-serv ISRB=%02x   masked IMRB=%02x",read_b(0xfffa09),read_b(0xfffa0d),read_b(0xfffa11),read_b(0xfffa15)) ;
        print_string(7,b) ;
        print_string(7,"") ;
        sprintf(b,"control  TACR=%02x TBCR=%02x  data TADR=%02x TBDR=%02x",read_b(0xfffa19),read_b(0xfffa1b),read_b(0xfffa1f),read_b(0xfffa21)) ;
        print_string(7,b) ;
        sprintf(b,"control TCDCR=%02x          data TCDR=%02x TDDR=%02x",read_b(0xfffa1d),read_b(0xfffa23),read_b(0xfffa25)) ;
        print_string(7,b) ;
        print_string(7,"") ;
        sprintf(b,"TIMER A (0x134) = %08X   TIMER B (0x120) = %08X",read_st_long(0x134),read_st_long(0x120)) ;
        print_string(7,b) ;
        sprintf(b,"TIMER C (0x114) = %08X   TIMER D (0x110) = %08X",read_st_long(0x114),read_st_long(0x110)) ;
        print_string(7,b) ;

}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                   DISPLAY MONITOR HELP
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
static void do_help()
{
        union REGS regs ;
        int prev_currenty = currenty ;
        currenty = 0 ;

        init_gfx() ;
        regs.w.ax = 0x1202 ;
        regs.h.bl = 0x30 ;
        int386(0x10,&regs,&regs) ;
        regs.w.ax = 3 ;
        int386(0x10,&regs,&regs) ;
        regs.w.ax = 0x1112 ;
        regs.h.bl = 0 ;
        int386(0x10,&regs,&regs) ;


        display_string(0,0,0," ") ;
       #ifdef DEBUG
        print_string(15,"                 ***** MON68 v1.1 ***** DEBUG compilation") ;
       #else
        print_string(15,"               ***** MON68 v1.1 ***** NON-DEBUG compilation") ;
       #endif
        print_string(0,"") ;

        print_string(_col_help,"h                       : this short help") ;
        print_string(_col_help,"t                       : trace over") ;
        print_string(_col_help,"z <steps>               : trace <n steps> into") ;
        print_string(_col_help,"d (adr)                 : disas") ;
        print_string(_col_help,"g (rasters)             : go (for n rasterlines)") ;
       #ifdef DEBUG
        print_string(_col_help,"bp (adr)                : view/(un)set breakpoint") ;
        print_string(_col_help,"ba|bar|baw (adr)        : view/(un)set breakaccess") ;
        print_string(_col_help,"bo <msk> <cmp>          : opcode breakpoint") ;
        print_string(_col_help,"trap                    : trap exceptions on/off") ;
       #endif
        print_string(_col_help,"m (adr)                 : dump memory") ;
        print_string(_col_help,"s reg=value             : set register") ;
        print_string(_col_help,"s [mem]=values          : set memory") ;
        print_string(_col_help,"nop <mem> <n>           : fill NOPs") ;
        print_string(_col_help,"lb file adress (size)   : load binary") ;
        print_string(_col_help,"sb file adress size     : save binary") ;
        print_string(_col_help,"e <expression>          : evaluate expression") ;
        print_string(_col_help,"history                 : history") ;
        print_string(0,"") ;
        print_string(0x10|_col_help,"f|ft <adr1> <adr2> <..> : find") ;
        print_string(0x10|_col_help,"s _var=value            : set variable") ;
        print_string(0x10|_col_help,"vars                    : show variables") ;

        print_string(0,"") ;

        print_string(_col_help,"reset [hard]            : reset 68000") ;
        #ifdef DEBUGPROFILE
        print_string(_col_help,"profile [on|off|clear]  : profile mode") ;
        #endif
        print_string(_col_help,"animate <nb>            : animate nb instructions") ;
        print_string(_col_help,"disa <start> <end>      : disassemble to LOGfile") ;
        print_string(_col_help,"status                  : display system status") ;
        print_string(_col_help,"kbd [bytes...]          : keyboard buffer") ;
        print_string(_col_help,"kbdelay <n>             : set keyboard delay") ;
        print_string(_col_help,"vol <volume>            : set global volume") ;
        print_string(_col_help,"pref [on|off]           : 68000 prefetch emulation") ;
        print_string(_col_help,"patch [off|joy]         : use joy to map fire to rmb") ;
        print_string(_col_help,"calib                   : Joystick Calibration") ;
        print_string(_col_help,"tos                     : LOAD another TOS") ;
        print_string(_col_help,"record [on|off]         : START/STOP recording") ;
        print_string(_col_help,"play <init> <end> <loop>: Play YM / Set range for saving") ;
        print_string(_col_help,"mfp                     : MFP status") ;
        print_string(0," ") ;
        print_string(_col_help,"fz/uz                   : Freeze/Unfreeze") ;

        getch() ;
        currenty = prev_currenty ;
        deinit_gfx() ;
}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                          CONFIGURATION
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_config()
{
        Config_Video() ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                            CHANGE DISK
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_changedisk()
{
        short *video = (short *)0xb8000;
        int x ;
        union REGS regs;
        extern int nb_images ;

        for (x=0;x<80*50;x++) sscreen[x] = *video++ ;

        disk_selector() ;

        regs.w.ax = 0x1202 ;
        regs.h.bl = 0x30 ;
        int386(0x10,&regs,&regs) ;
        regs.w.ax = 3 ;
        int386(0x10,&regs,&regs) ;
        regs.w.ax = 0x1112 ;
        regs.h.bl = 0 ;
        int386(0x10,&regs,&regs) ;

        video = (short *)0xb8000 ;
        for (x=0;x<80*50;x++) *video++ = sscreen[x] ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                             TRACE INTO
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_traceinto()
{
        int     nb ;
        int     abort = FALSE ;

        if (Read_Number(&nb,FALSE)||!nb) nb=1 ;

        Just_Enter_68000 = TRUE ;
        while (!abort) {
                Step_68000() ;
                abort = (--nb==0) ;
                if (processor->events_mask&MASK_IsException) {
                        abort = TRUE ;
                        print_exception_number(processor->ExceptionNumber) ;
                        }
        }
        display_registers() ;
        print_disa(processor->PC,1) ;

}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                             TRACE INTO
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_traceover()
{
        int     abort = FALSE ;
        int     siz ;
        char    dummy[80] ;
        unsigned int mn ;
        MPTR    pctoreach ;

        disa_instr(processor->PC,dummy,&siz) ;
        //mn = *(int *)(dummy) ;

        mn = (dummy[3]<<24)+(dummy[2]<<16)+(dummy[1]<<8)+dummy[0] ;

        if ((mn=='\tRSB')||(mn=='.RSB')||(mn=='\tRSJ')||(mn=='PART')||(mn=='W.CD')) {
                pctoreach = processor->PC+siz ;      // PC value to reach
                while ((!abort)&&(pctoreach!=processor->PC)&&(!kbhit())) {
                        Just_Enter_68000 = TRUE ;
                        Step_68000() ;
                        if (processor->events_mask&MASK_IsException) {
                                if ((processor->ExceptionNumber>255)||trapIRQs[processor->ExceptionNumber]) {
                                        abort = TRUE ;
                                        print_exception_number(processor->ExceptionNumber) ;
                                }
                        }
                }
                display_registers() ;
                print_disa(processor->PC,1) ;
                //while (kbhit) getch() ;
        }
        else    do_traceinto() ;

}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                            TRACE UNTIL
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_traceuntil()
{
        int     abort = FALSE ;
        int     siz ;
        char    dummy[80] ;
        MPTR    pctoreach ;

        disa_instr(processor->PC,dummy,&siz) ;
        pctoreach = processor->PC+siz ;      // PC value to reach
        while ((!abort)&&(pctoreach!=processor->PC)&&(!kbhit())) {
                Just_Enter_68000 = TRUE ;
                Step_68000() ;
                if (processor->events_mask&MASK_IsException) {
                        if ((processor->ExceptionNumber>255)||trapIRQs[processor->ExceptionNumber]) {
                                abort = TRUE ;
                                print_exception_number(processor->ExceptionNumber) ;
                        }
                }
        }
        display_registers() ;
        print_disa(processor->PC,1) ;

}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                              PROFILING
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

/*
// [fold]  [
static void do_profile()
{
        #ifdef DEBUGPROFILE
        char b[80] ;
        int l ;

        if (*parameters=='o')
                if (*(parameters+1)=='n') isprofile = TRUE ;
                else if (*(parameters+1)=='f') isprofile = FALSE ;
                else {print_string(_col_err,"what?") ; return; }

        if (*parameters=='c')
        {
                for (l=0;l<65536;l++) profile[l] = 0 ;
                print_string(_col_normal,"profile structures cleared.") ;
                return ;
        }


        wasprofile |= isprofile ;
        if (isprofile) print_string(_col_normal,"profile is on") ;
                else print_string(_col_normal,"profile is off") ;

        #endif
}

// [fold]  ]
*/

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                            LOAD BINARY
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_loadbinary()
{
        char filename[80],*name ;
        int addressst ;
        MPTR address, nbread, size ;
        FILE *fp ;

        name = filename ;
        while (*parameters && (*parameters!=' '))
                *name++ = *parameters++ ;
        *name = '\0' ;                              // read filename

        fp = fopen(filename,"rb") ;
        if (fp == NULL) {
                print_string(_col_err,"Error opening file.") ;
                return ;
        }

        if (Read_Number(&addressst,TRUE)) {
                print_string(_col_err,"Can't understand given adress.") ;
                fclose(fp) ;
                return ;
        }

        address = (MPTR)stmem_to_pc(addressst) ;
        if (address == -1) {
                print_string(_col_err,"Invalid adress.") ;
                fclose(fp) ;
                return ;
        }

        if (Read_Number(&size,FALSE))
                size = 0xffffff ;

        nbread = fread(address,1,size,fp) ;
        fclose(fp) ;
        sprintf(filename,"%d bytes read (%06x-%06x)",nbread,addressst,addressst+nbread-1) ;
        print_string(7,filename) ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                            SAVE BINARY
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_savebinary()
{
        char filename[80],*name ;
        MPTR address, nbsaved, size ;
        int stat,addressst;
        FILE *fp ;

        name = filename ;
        while (*parameters && (*parameters!=' '))
                *name++ = *parameters++ ;
        *name = '\0' ;                              // read filename

        fp = fopen(filename,"wb") ;
        if (fp == NULL) {
                print_string(_col_err,"Error opening file.") ;
                return ;
        }

        stat = Read_Number(&addressst,TRUE) ;
        if (!stat) stat = Read_Number(&size,TRUE) ;
        if (stat) {
                print_string(_col_err,"Can't understand parameters.") ;
                fclose(fp) ;
                return ;
        }

        address = (MPTR)stmem_to_pc(addressst) ;
        if (address == -1) {
                print_string(_col_err,"Invalid adress.") ;
                fclose(fp) ;
                return ;
        }

        nbsaved = fwrite(address,1,size,fp) ;
        fclose(fp) ;
        sprintf(filename,"%d bytes saved (%06x-%06x).",nbsaved,addressst,addressst+size) ;
        print_string(7,filename) ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                   68000 RESET/PREFETCH
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

#ifdef SOUND
extern void Reset_Sound(void) ;
#endif

extern void Reset_Keyboard(void) ;

// [fold]  [
static void do_reset()
{
        char *p = parameters ;

        if ((*p++=='h')&&(*p++=='a')&&(*p++=='r')&&(*p++=='d')) {
                print_string(7,"68000 hard-reseted") ;
                reset_machine(TRUE) ;
        }
        else {
                print_string(7,"68000 soft-reseted") ;
                reset_machine(FALSE) ;
        }
        display_registers() ;
}

// [fold]  ]

// [fold]  [
static void do_prefetch()
{
        char b[80],s[20] ;
        if (strstr(parameters,"off"))
                isPrefetch = FALSE ;
        else if (strstr(parameters,"on")) {
                isPrefetch = TRUE ;
                PrefetchPC = 0xffffffff ;
        }

        strcpy(s,"off") ; if (isPrefetch) strcpy(s,"on") ;
        sprintf(b,"68000 Prefetch emulation is %s",s) ;
        print_string(7,b) ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                              RUN UNTIL
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

int Break_Raster ;
int IsBreakOnRaster ;

extern void pause_sound();
extern void continue_sound() ;

extern int optim_cycles ;

// [fold]  [
static void do_go()
{
        MPTR lastpc;
        int raster ;
        int quitloop;
        int localpcvbls ;
        char *biosdata = (char *)(0x417) ;
        *biosdata++ &= 0xf0 ;
        *biosdata++ &= 0xfc ;

        if (IsBreakOnRaster = !Read_Number(&raster,FALSE))
                Break_Raster = raster+Total_Raster ;
          else Break_Raster = 0x7fffffff ;


rego:;
         quitloop = FALSE;
        Just_Enter_68000 = TRUE ;
        processor->events_mask &= ~MASK_IsException ;

        init_gfx() ;
        continue_sound() ;
        localpcvbls = Global_PC_VBLs ;
        while (localpcvbls==Global_PC_VBLs) ;
        while (!quitloop)
        {

        Run_68000() ;

                if (processor->events_mask&MASK_SoftReset) {
                        reset_machine(FALSE) ;
                        processor->events_mask&=~MASK_SoftReset ;
                        continue ;
                }
                if (processor->events_mask&MASK_HardReset) {
                        reset_machine(TRUE) ;
                        processor->events_mask&=~MASK_HardReset ;
                        continue ;
                }

                if ((processor->ExceptionNumber > 255)
                  ||(processor->events_mask&MASK_UserBreak)
                  ||(processor->events_mask&MASK_DiskSelector)
                  ||(processor->events_mask&MASK_DoubleBus))
                        quitloop = TRUE ;

        if (processor->events_mask&MASK_IsException) {
                if (istrap&&(processor->ExceptionNumber<256)&&trapIRQs[processor->ExceptionNumber])
                        quitloop = TRUE ;
/*
                if (processor->ExceptionNumber == _EXCEPTION_SOFTRESET) {
                        reset_machine(FALSE) ;
                        continue ;
                }

                if (processor->ExceptionNumber == _EXCEPTION_HARDRESET) {
                        reset_machine(TRUE) ;
                        continue ;
                }
*/
        }


        }

        if (processor->events_mask & MASK_UserBreak) {
                processor->events_mask &= ~MASK_UserBreak ;
                processor->events_mask |= MASK_IsException ;
                processor->ExceptionNumber = _EXCEPTION_USER ;
        }

        if (processor->events_mask & MASK_DoubleBus) {
                processor->events_mask &= ~MASK_DoubleBus ;
                processor->events_mask |= MASK_IsException ;
                processor->ExceptionNumber = _EXCEPTION_DOUBLEBUS ;
        }

        Nb_PC_VBLs += Global_PC_VBLs - localpcvbls -1 ;
        pause_sound() ;
        deinit_gfx() ;
/*
        if (processor->events_mask&MASK_IsException&&(processor->ExceptionNumber==_EXCEPTION_DISKSELECTOR)) {
                do_changedisk();
                processor->events_mask &= ~MASK_IsException ;
                goto rego ;
        }
*/
        if (processor->events_mask&MASK_DiskSelector) {
                do_changedisk();
                processor->events_mask &= ~MASK_DiskSelector ;
                goto rego ;
        }
/*
        if (processor->events_mask&MASK_DUMPSCREEN) {
                do_dumpscreen() ;
                processor->events_mask &= ~MASK_DUMPSCREEN ;
                goto rego ;
        }
*/
        if (processor->events_mask&MASK_IsException)
                {print_exception_number(processor->ExceptionNumber) ;
                 if ((processor->ExceptionNumber==_EXCEPTION_BREAKACCESS)||
                     (processor->ExceptionNumber==_EXCEPTION_BREAKOPCODE))
                    lastpc = adr_breakaccess ;
                 else
                 lastpc=processor->PC;}
        else {getch() ; print_string(7,"break from user") ; lastpc = processor->PC;}

        print_disa(lastpc,8) ;
        display_registers();
        if (processor->ExceptionNumber == _EXCEPTION_DOUBLEBUS) {
                Reset_68000() ;
                processor->PC = TOSbase ;
        }

	{
		char b[80] ;
		sprintf(b,"%d cycles. (%d rasters) - %d\%\n",
			     optim_cycles,
			     optim_cycles/512,
			     (100*optim_cycles)/(512*313)) ;

	print_string(15,b) ;
	}

}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                                ANIMATE
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_animate()
{
        int nb ;
        int nbtotal ;
        char buf[80] ;
        int lastneedcycles = needcycles ;
        int quitloop = FALSE ;
        needcycles = FALSE ;

        if ((Read_Number(&nb,TRUE))||!nb)
                nb=0x7fffffff ;

         nbtotal = nb ;
        sprintf(buf,"ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Start animate at %08x",processor->PC) ;
        OUTDEBUG(buf) ;
        while ((nb--)&&(!quitloop)&&(!kbhit()))
        {
                out_disa() ;
                processor->events_mask &= ~MASK_IsException ;
                Just_Enter_68000 = TRUE ;
                Step_68000() ;
                quitloop = ((processor->events_mask&MASK_IsException)&&(processor->ExceptionNumber > 255)) ;
                if (nbtotal!=0x7fffffff)
                        sprintf(buf,"%d%%",(100*(nbtotal-nb))/nbtotal) ;
                display_string(0,currenty,15,buf) ;
        }
        sprintf(buf,"*** end of animate *** ") ;
        if (processor->events_mask&MASK_IsException)
                if (processor->ExceptionNumber == _EXCEPTION_BREAKPOINT)
                   strcat(buf,"breakpoint reached") ;
                else
                if (processor->ExceptionNumber == _EXCEPTION_BREAKACCESS)
                   strcat(buf,"breakaccess reached") ;

        print_string(_col_brk,buf) ;
        OUTDEBUG(buf) ;

        print_disa(processor->PC,8) ;
        display_registers() ;
        needcycles = lastneedcycles ;
}


// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                             BREAKPOINT
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static int do_breakpoint()
{
        int b,c;
        char buf[80] ;
        char buf2[80] ;
        int adress ;

        sprintf(buf,"breakpoint:") ;
        if (!*parameters)               // list breakpoints
        {
                if (!Nb_Breakpoints) {print_string(_col_brk,"no breakpoints defined.") ; return FALSE;}
                for (b=0;b<Nb_Breakpoints;b++)
                        {sprintf(buf2," %08x",breakpoints[b]) ;
                         strcat(buf,buf2) ;}
                print_string(_col_brk,buf) ;
                return TRUE;
        }
        if (Read_Number(&adress,TRUE))
                return FALSE;


        if (b = is_in_breakpoints_list(adress)) {
                Nb_Breakpoints-- ;
                for (c=b-1;c<Nb_Breakpoints;c++)
                        breakpoints[c] = breakpoints[c+1] ;
                sprintf(buf,"breakpoint %08x removed.",adress) ;
                print_string(_col_brk,buf) ;
                return TRUE ;
        }

       // test if max reached

       if (Nb_Breakpoints==8)
        {sprintf(buf,"max number of breakpoints reached (8).") ;
         print_string(_col_brk,buf) ;
         return FALSE;
        }

       // must add breakpoint

        sprintf(buf,"breakpoint %08x added",adress) ;
        print_string(_col_brk,buf) ;
        breakpoints[Nb_Breakpoints++] = adress ;
        return TRUE ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                        BREAK ON ACCESS
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static int do_breakaccess()
{
        int b,c;
        char buf[80] ;
        char buf2[80] ;
        int adress ;
        char kind = ' ';

        if ((*parameters=='r')||(*parameters=='w'))
                kind = *parameters++ ;

        sprintf(buf,"breakaccess:") ;
        if (!*parameters)               // list
        {
                if (!Nb_Breakaccess) {print_string(_col_brk,"no breakaccess defined.") ; return FALSE;}
                for (b=0;b<Nb_Breakaccess;b++)
                        {sprintf(buf2," %08x",breakaccess[b]) ;
                         strcat(buf,buf2) ;}
                print_string(_col_brk,buf) ;
                return TRUE;
        }

        if (Read_Number(&adress,TRUE))
                return FALSE ;

        for (b=0;b<Nb_Breakaccess;b++)
                if (breakaccess[b] == adress)   // remove
                {
                        Nb_Breakaccess-- ;
                        for (c=b;c<Nb_Breakaccess;c++)
                                breakaccess[c] = breakaccess[c+1] ;
                        sprintf(buf,"breakaccess %08x removed.",adress) ;
                        print_string(_col_brk,buf) ;
                        return TRUE ;
                }

       // test if max reached

       if (Nb_Breakaccess==8)
        {sprintf(buf,"max number of breakaccess reached (8).") ;
         print_string(_col_brk,buf) ;
         return FALSE;
        }

       // must add breakpoint

        sprintf(buf,"breakaccess %08x added",adress) ;
        print_string(_col_brk,buf) ;
        breakaccess_rw[Nb_Breakaccess] = kind ;
        breakaccess[Nb_Breakaccess++] = adress ;
        return TRUE ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                        BREAK ON OPCODE
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_breakopcode(void)
{
        char b[80] ;
        int stat,msk,cmp ;

        if (!*parameters) {
                sprintf(b,"Break on opcode  Mask=%04x Cmp=%04x",breakopcode_msk,breakopcode_cmp) ;
                print_string(_col_brk,b) ;
                return;
        }

        stat = Read_Number(&msk,TRUE) ;
        if (!stat) Read_Number(&cmp,TRUE) ;
        if (stat) return ;

        breakopcode_msk = msk ;
        breakopcode_cmp = cmp ;

        sprintf(b,"opcode Mask=%04x Cmp=%04x will break execution flow.",msk,cmp) ;
        print_string(_col_brk,b) ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                            DISASSEMBLE
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_disa()
{
        int address ;
        int status ;

        status = Read_Number(&address,FALSE) ;
        if (!status)
                print_disa(address,8) ;
           else
                print_disa(lastdisa,8) ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                 DISASSEMBLE TO LOGFILE
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/


// [fold]  [
static void do_disafile()
{
        int address1,address2 ;
        int status ;
        int siz ;
        char st[256] ;
        extern FILE *fdebug ;


        status = Read_Number(&address1,TRUE) ;
        if (!status) {
                status = Read_Number(&address2,TRUE) ;
        }

        if (status) {
                print_string(0x70,"nothing done.") ;
                return ;
        }

        address1 &= 0xffffff ;
        address2 &= 0xffffff ;

        while (address1 < address2) {
                disa_instr(address1, st, &siz) ;
                fprintf(fdebug,"%08x : %s\n",address1,st) ;
                address1 += siz ;
        }
        print_string(0x70,"done.") ;
}

// [fold]  ]


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                            DUMP MEMORY
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_dump()
{
        int address ;
        int status ;

        status = Read_Number(&address,FALSE) ;
        if (!status)
                print_dump(address,8) ;
           else
                print_dump(lastdump,8) ;
}

// [fold]  ]



/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                         TRAP INTERRUPT
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
static void do_trap()
{
        char *p ;
        int nb ;
        p = parameters ;
        skip_spaces(&p) ;

        if (!(*p))     //          list TRAPs
        {
                int c[1] ; c[0] = 7 ; c[1] = 15 ;

                if (istrap) print_string(_col_normal,"Trapping is ON.") ;
                else print_string(_col_normal,"Trapping is OFF.") ;
                print_string(_col_help,"***** Current Trapping list *****") ;
                print_string(c[trapIRQs[_EXCEPTION_BUSERROR]],"0x02 - BUS ERROR") ;
                print_string(c[trapIRQs[_EXCEPTION_ADRESSERROR]],"0x03 - ADRESS ERROR") ;
                print_string(c[trapIRQs[_EXCEPTION_ILLEGALINSTRUCTION]],"0x04 - ILLEGAL") ;
                print_string(c[trapIRQs[_EXCEPTION_ZERODIVIDE]],"0x05 - ZERO DIVIDE") ;
                print_string(c[trapIRQs[_EXCEPTION_PRIVILEGEVIOLATION]],"0x08 - PRIVILEGE VIOLATION") ;
                print_string(c[trapIRQs[_EXCEPTION_LINEA]],"0x0a - LINE A") ;
                print_string(c[trapIRQs[_EXCEPTION_LINEF]],"0x0b - LINE F") ;
                print_string(c[trapIRQs[_EXCEPTION_HBL]],"0x1a - HBL") ;
                print_string(c[trapIRQs[_EXCEPTION_VBL]],"0x1c - VBL") ;
                print_string(c[trapIRQs[_EXCEPTION_ACIA]],"0x46 - ACIA") ;
                print_string(c[trapIRQs[_EXCEPTION_FDC]],"0x47 - FDC") ;
                print_string(c[trapIRQs[_EXCEPTION_TIMERA]],"0x4D - TIMER A") ;
                print_string(c[trapIRQs[_EXCEPTION_TIMERB]],"0x48 - TIMER B") ;
                print_string(c[trapIRQs[_EXCEPTION_TIMERC]],"0x45 - TIMER C") ;
                print_string(c[trapIRQs[_EXCEPTION_TIMERD]],"0x44 - TIMER D") ;
                print_string(c[trapIRQs[_EXCEPTION_TRAP+1]],"0x21 - TRAP #$1") ;
                print_string(c[trapIRQs[_EXCEPTION_TRAP+2]],"0x22 - TRAP #$2") ;
                print_string(c[trapIRQs[_EXCEPTION_TRAP+13]],"0x2d - TRAP #$D") ;
                print_string(c[trapIRQs[_EXCEPTION_TRAP+14]],"0x2e - TRAP #$E") ;
                return ;
        }

        if ((*p=='o')&&(*(p+1)=='n')) // TRAPping on
        {
                istrap = TRUE ;
                print_string(_col_normal,"Trapping is on.") ;
                return ;
        }

        if ((*p=='o')&&(*(p+1)=='f')) // TRAPping off
         {
                istrap = FALSE ;
                print_string(_col_normal,"Trapping is off.") ;
                return ;
         }

        if ((*p=='c')&&(*(p+1)=='l')) // TRapping clr
         {
                int i ;
                for (i=0;i<256;i++) trapIRQs[i] = FALSE ;
                print_string(_col_normal,"Trapping cleared.") ;
                return ;
         }

        if ((*p=='a')&&(*(p+1)=='l')) // TRapping all
         {
                int i ;
                for (i=0;i<256;i++) trapIRQs[i] = TRUE ;
                print_string(_col_normal,"Trapping for all IRQs.") ;
                return ;
         }

        if (!Read_Number(&nb,TRUE)&&(nb<256))
         {
                char b[64] ;
                if (trapIRQs[nb] = TRUE - trapIRQs[nb])
                        sprintf(b,"0x%02x will trap.",nb) ;
                else
                        sprintf(b,"0x%02x won't trap.",nb) ;
                print_string(_col_normal,b) ;
         }
        else
                print_string(_col_err,"???") ;


}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                 SET REGISTER OR MEMORY
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
static void do_set()
{
         int *reg ;        // register to modify
         int n,value ;
         int isok = TRUE,isvar=FALSE ;
         MPTR adress ;                  // adress in case of memory mod
         int ismemorymod = FALSE ;      // default is register setting
         char varname[20],c,*pv = 0 ;

        while (*parameters==' ') parameters++ ;        // skip spaces
        switch (*parameters) {

          case 'p' : if (*(1+parameters)=='c')              // is PC?
                     { reg = &processor->PC ;
                       parameters += 2 ; }
                     break ;
          case 'd' :if ((*(1+parameters)>='0')&&(*(1+parameters)<='7')) // Dx?
                     { reg = &processor->D[*(1+parameters)-'0'] ;
                       parameters += 2 ; }
                     break ;
          case 'a' :if ((*(1+parameters)>='0')&&(*(1+parameters)<='7')) // Ax?
                     { reg = &processor->A[*(1+parameters)-'0'] ;
                       parameters += 2 ; }
                     break ;
          case 'u' :if ((*(1+parameters)=='s')&&(*(2+parameters)=='p')) // USP?
                     { reg = &processor->A7 ;
                       parameters += 3 ; }
                     break ;
          case 's' :if ((*(1+parameters)=='r')) // SR ?
                     { reg = &processor->SR ;
                       parameters += 2 ; }
                     break ;

          case '_':     c = *(++parameters) ;
                        pv = &varname ;
                        *pv = 0 ;
                        n = 0 ;
                        while (((c>='0')&&(c<='9'))||
                                ((c>='a')&&(c<='z'))||
                                ((c>='A')&&(c<='Z'))||
                                (c=='_'))
                        {
                                if (n<12) *pv++ = c ;
                                        n++ ;
                                c = *(++parameters) ;
                        }
                        *pv++ = 0 ;
                        if ((varname[0]|0x20)<'A') {
                                print_string(_col_err,"Invalid variable name") ;
                                isok=FALSE ;
                        }
                        isvar = TRUE ;
                        break ;

          case '[':  parameters++ ;
                     if (!Read_Number(&adress,TRUE)) // memory?
                     { ismemorymod = TRUE ;
                       while (*parameters==' ') parameters++ ;// skip spaces
                       if (*parameters++!=']') isok = FALSE ;
                       break ;
                     }



          default :  print_string(_col_err,"set WHAT?") ; isok = FALSE ;
        }

        while (*parameters==' ') parameters++ ;        // skip spaces
        if ((*(parameters++) != '=')&&isok)
               { print_string(_col_err,"s <reg/mem>=<values>") ; isok = FALSE ; }

        if (isok) {

        //***************************************** set memory

            if (ismemorymod)
            {
                int n = 0;
                char b[80] ;
                MPTR ad0 = adress ;
                while (!Read_Number(&value,FALSE)) { // for each mod byte
                       n++ ;
                       write_st_byte(adress++,value) ;
                }
                sprintf(b,"%d byte(s) modified at %08x",n,ad0) ;
                print_string(_col_normal,b) ;

            } else

        //***************************************** set variable
           if (isvar) {
                char *msg ;
                skip_spaces(&parameters) ;
                if (!*parameters) {
                        if (dispose_variable(&varname,&msg))
                                print_string(9,"Variable disposed") ;
                        else print_string(9,msg) ;
                }
                else
                if (!Read_Number(&value,TRUE))
                        if (!affect_variable(varname,value,&msg))
                                print_string(_col_err,msg) ;
            } else

        //***************************************** set register

            if (!Read_Number(&value,TRUE))             // valid parameter?
            {
                *reg = value ;
            }


            else print_string(_col_err,"WHAT value?") ;
        }
        display_registers() ;
}

// [fold]  )


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                                 VOLUME
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_volume()
{
        char b[80] ;
        skip_spaces(&parameters) ;
        if (!*parameters)
                sprintf(b,"Current volume is %d of 255",globalvolume) ;
        else {
                globalvolume = 0xff&strtol(parameters,NULL,10) ;
                sprintf(b,"Volume set to %d",globalvolume) ;
        }
        print_string(15,b) ;

}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                                  PATCH
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_patch()
{
        char b[80] ;

        skip_spaces(&parameters) ;

        if (!stricmp(parameters,"off"))
                special_patch = SPECIALPATCH_NONE ;
        if (!stricmp(parameters,"joy"))
                special_patch = SPECIALPATCH_JOY ;

        switch(special_patch) {
                case SPECIALPATCH_NONE :
                        strcpy(b,"no special patch") ;
                        break ;
                case SPECIALPATCH_JOY :
                        strcpy(b,"Joystick button trigger RMB") ;
                        break ;
        }
        print_string(15,b) ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                               KEYBOARD
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/


// [fold]  [
static void do_kbd()
{
        int i,status ;
        int byte,nb ;
        char b[80],b2[10] ;

        nb = keyboard_next_outbuf-keyboard_inbuf ;
        sprintf(b,"currently %d byte(s) in 6301 buffer",nb) ;
        print_string(7,b) ;
        sprintf(b,"infbuf=%d outbuf=%d next_outbuf=%d",keyboard_inbuf,keyboard_outbuf,keyboard_next_outbuf,keyboard_wait) ;
        print_string(7,b) ;
        if (nb!=0) {
                b[0] = 0 ;
                if (nb > 20) nb = 20 ;
                for (i=0;i<nb;i++) {
                        sprintf(b2,"%02x ",keyboard_buffer[(keyboard_inbuf+i)&KBDMAXBUF]) ;
                        strcat(b,b2) ;
                }
                print_string(7,b) ;
        }

        skip_spaces(&parameters) ;
        if (!*parameters) return ;
        if (status = Read_Number(&byte,TRUE)) return ;

        i = 0 ;
        while (!status) {
                Keyboard_Write(byte) ;
                i++ ;
                status = Read_Number(&byte,FALSE) ;
        }
        sprintf(b,"%d bytes added to keyboard buffer",i) ;
        print_string(15,b) ;
}
// [fold]  ]

// [fold]  [
static void do_kbdelay()
{
        int n ;
        char b[80] ;
        if (!Read_Number(&n,TRUE)) keyboard_delay = n ;
        if (keyboard_delay>10) keyboard_delay=10 ;
        sprintf(b,"keyboard delay is %d",keyboard_delay) ;
        print_string(15,b) ;
}
// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                                    TOS
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
extern int load_tos(int ntos, int verbose) ;
extern void init_68000(void) ;

// [fold]  [
static void do_tos()
{
        char b[130] ;
        int i ;
        int c ;

        if (nb_tos==1) {
                print_string(12,"You must have several TOS directives in the INI file") ;
                print_string(12,"in order to use this function.") ;
                return ;
        }

        sprintf(b,"Current TOS is %d of %d (v%x.%02x at $%06x)",1+current_tos,nb_tos,TOStable[current_tos].v1,TOStable[current_tos].v2,TOStable[current_tos].base) ;
        print_string(12,b) ;
        for (i=0;i<nb_tos;i++) {
                c=(i==current_tos)?15:7 ;
                sprintf(b,"(%d) - %s",i+1,TOStable[i].comments) ;
                print_string(c,b) ;
                sprintf(b,"  file %s",TOStable[i].filename) ;
                print_string(7,b) ;
        }
        print_string(12,"What TOS to use (0=abort)? This will RESET the ST!") ;

        do c = getch()-'0' ;
        while ((c<0)||(c>nb_tos)) ;

        if (!c) {
                print_string(_col_normal,"no change") ;
                return ;
        }
        if (!load_tos(c-1,FALSE)) {
                print_string(_col_err,"Error Loading TOS") ;
                return ;
        }
        init_68000() ;
        reset_machine(TRUE) ;
        sprintf(b,"TOS is now %d of %d (v%x.%02x at $%06x)",1+current_tos,nb_tos,TOStable[current_tos].v1,TOStable[current_tos].v2,TOStable[current_tos].base) ;
        print_string(_col_normal,b) ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                                    NOP
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
static void do_nop()
{
        int stat,address0, address, count0, count ;
        char b[80] ;

        stat=Read_Number(&address,TRUE);
        if (!stat) stat=Read_Number(&count,TRUE) ;
        if (stat) {
                print_string(_col_err,"NOP <adr> <n>") ;
                return ;
        }

        count&=0xffff ;
        for (address0=address,count0=count;count;count--) {
                write_st_word(address,0x4e71) ;
                address+=2 ;
        }
        sprintf(b,"%d NOPs from %08X to %08X",count0,address0,address) ;
        print_string(15,b) ;
}

// [fold]  ]


// [fold]  [
static void do_mod()
{
        int modu ;

        if (!Read_Number(&modu,TRUE))
                modulo = modu&0x7f ;
}

// [fold]  ]


// [fold]  [
static void do_mody()
{
        int modu ;

        if (!Read_Number(&modu,TRUE))
                moduloy = (modu&0x7f)*160 ;
}

// [fold]  ]


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                                 RECORD
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

extern int YMbuffer_ptr ;
extern int save_YMrecord(char **name) ;

int ym_monitor = FALSE ;
int ym_pos_start ;
int ym_pos_end ;
int ym_pos_current ;
int ym_pos_loop ;

// [fold]  [
static void do_record()
{

        char b[256] ;
        int mi = YMbuffer_ptr/(50*60*14) ;
        int se = (YMbuffer_ptr-(mi*60*50*14))/(50*14) ;

        if (!isYMrecord) {
              print_string(_col_err,"Structures not alloctated - Restart PaCifiST") ;
                print_string(_col_err,"with the /ymrecord switch...") ;
                  return ;
        }

        sprintf(b,"Current YM buffer is %d bytes long (%d min %d sec)",YMbuffer_ptr,mi,se) ;
        print_string(7,b) ;

        skip_spaces(&parameters) ;
        if (*parameters) if (!stricmp(parameters,"on")) YMrecording = TRUE ;
                         else if (!stricmp(parameters,"off")) {

                int k,qui = 0 ;
                char *name ;
                YMrecording = FALSE ;


               strcpy(b,"Do you want to (P)ause (F)ree buffer (S)ave?") ;
                print_string(15,b) ;
                do {
                        k = getch()|0x20 ;
                        if (k=='f') {
                                YMbuffer_ptr = 0 ;
                                qui = TRUE ;
                                strcpy(b,"YM buffer cleared") ;
                                print_string(7,b) ;
                                ym_pos_start=ym_pos_end=ym_pos_loop=0;
                        }
                        else if (k=='s') {
                                if (save_YMrecord(&name)) {
                                        sprintf(b,"\"%s\" successfully created (%d-%d)",name,ym_pos_start,ym_pos_end) ;
                                        print_string(14,b) ;
                                        strcpy(b,"YM buffer saved and cleared") ;
                                }
                                else strcpy(b,"*** Error while saving YM buffer ***") ;
                                qui = TRUE ;
                                print_string(0x70,b) ;
                                YMbuffer_ptr = 0 ;
                                ym_pos_start=ym_pos_end=ym_pos_loop=0;
                        }
                        else if (k=='p') {
                                qui = TRUE ;
                                strcpy(b,"YM recording paused") ;
                                print_string(7,b) ;
                        }
                } while (!qui) ;
        }
         strcpy(b,"YM recording off") ;
        if (YMrecording) strcpy(b,"YM recording on") ;

        print_string(0x1c,b) ;

}

// [fold]  ]


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                                     YM
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/


extern char PSGRegs[16] ;
extern int YmReg13Write ;
extern char *YMbuffer ;

// [fold]  [
void periodic_ym(void)
{
        int i ;
        for (i=0;i<14;i++)
                PSGRegs[i] = YMbuffer[ym_pos_current*14+i] ;

                YmReg13Write = (PSGRegs[13]!=0xff) ;

//        if (YMbuffer[ym_pos_current*14+13] != 0xff) {
//                PSGRegs[13] = YMbuffer[ym_pos_current*14+13] ;
//                YmReg13Write= TRUE ;
//        }

        ym_pos_current++ ;
        if (ym_pos_current>ym_pos_end)
                ym_pos_current = ym_pos_loop ;

}

// [fold]  ]

// [fold]  [
static int Read_Param10(int *adress)
{
        int n = 0;
        skip_spaces(&parameters) ;
        if ((*parameters=='p')&&(*(parameters+1)=='c'))
                { *adress = processor->PC ; return TRUE;}
        if (!*parameters) return FALSE ;

        while ( (*parameters!=0)&&(*parameters!='=')&&(*parameters!=' ')&&
                (*parameters!=']'))
        {
                if ((*parameters >= '0')&&(*parameters<='9'))
                        n = (n*10)+*parameters-'0' ;
                        else return FALSE ;
                parameters++ ;
        }

        *adress = n ;
        return TRUE ;
}

// [fold]  ]


// [fold]  [
static void do_play()
{
        int wassamples = isSamples ;
        char b[80] ;
        int c ;

        if (!isYMrecord) {
                print_string(_col_err,"Structures not alloctated - Restart PaCifiST") ;
                print_string(_col_err,"with the /ymrecord switch...") ;
                return ;
        }
        isSamples = FALSE ;

        if (!Read_Param10(&ym_pos_start))
                ym_pos_start = 0 ;
        if (!Read_Param10(&ym_pos_end))
                ym_pos_end = YMbuffer_ptr/14 ;
        if (!Read_Param10(&ym_pos_loop))
                ym_pos_loop = ym_pos_start ;

        ym_pos_current = ym_pos_start ;

        continue_sound() ;
        ym_monitor = TRUE ;

        do {
                sprintf(b,"Start:%5d End:%5d Loop:%5d Current:%5d",ym_pos_start,ym_pos_end,ym_pos_loop,ym_pos_current) ;
                display_string(0,currenty,15,b) ;

                c = TRUE ;
                if (kbhit()) {
                        c = getch() ;
                        if (c == 0x20) {
                                periodic_ym() ;
                                periodic_ym() ;
                                periodic_ym() ;
                                periodic_ym() ;
                        }
                         else c=0 ;
                }

        } while(c) ; //kbhit()) ;

        //getch() ;

        ym_monitor = FALSE ;
        pause_sound();
        isSamples = wassamples ;
        print_string(0,"") ;
}
// [fold]  ]



// [fold]  [
void ym_load(char *name)
{
        char b[80] ;
        FILE *fp ;
        int siz ;
        int fnz,i ;
        char *p = YMbuffer ;

        if (!isYMrecord) return ;

//        fp = fopen("e:\\ym.dat","rb") ; if (fp==NULL) return ;
        fp = fopen(name,"rb") ; if (fp==NULL) return ;
        siz = fread(YMbuffer,1,840000,fp) ;
        fclose(fp) ;

        fnz = 0 ;
        while (fnz<siz) {
                if (p[8]||p[9]||p[10])
                        goto nzfound;
                p+=14 ;
                fnz+= 14 ;
        }
nzfound:;
        for (i=0;i<siz-fnz;i++)
                YMbuffer[i] = YMbuffer[fnz+i] ;

        siz -= fnz ;
        fnz /= 14 ;


        sprintf(b,"%d bytes YM file loaded in (fnz:%d)",siz,fnz) ;
        print_string(15,b) ;
        YMbuffer_ptr = siz ;
}

// [fold]  ]


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                            CALIBRATION
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

type_joy joystick1_vars ;

static int xjoy,yjoy ;
static type_joy *jk ;

// [fold]  [
void poll_joystick(void)
{
        int v ;
        int maxwait = 0 ;

        outp(0x201,0xff) ;
        xjoy = yjoy = 0 ;
        do {
                v = inp(0x201) ;
                xjoy+=(v&1);
                yjoy+=((v>>1)&1) ;
                maxwait++ ;
        }
        while ((maxwait!=65535)&&(v&3)) ;

        if (xjoy<jk->calib_xmin) jk->calib_xmin = xjoy ;
        if (yjoy<jk->calib_ymin) jk->calib_ymin = yjoy ;
        if (xjoy>jk->calib_xmax) jk->calib_xmax = xjoy ;
        if (yjoy>jk->calib_ymax) jk->calib_ymax = yjoy ;
}

// [fold]  ]

// [fold]  [
void draw_limit(int c)
{
        int i,x1,x2,y1,y2 ;

        x1 = ((jk->lim_xmin-jk->calib_xmin)*80)/((jk->calib_xmax-jk->calib_xmin+1)) ;
        x2 = ((jk->lim_xmax-jk->calib_xmin)*80)/((jk->calib_xmax-jk->calib_xmin+1)) ;
        y1 = ((jk->lim_ymin-jk->calib_ymin)*40)/((jk->calib_ymax-jk->calib_ymin+1))+5 ;
        y2 = ((jk->lim_ymax-jk->calib_ymin)*40)/((jk->calib_ymax-jk->calib_ymin+1))+5 ;

        if (x1>79) x1=79 ; if (y1>45) y1=45 ;
        if (x2>79) x2=79 ; if (y2>45) y2=45 ;

        if (x1<0) x1=0 ; if (y1<0) y1=0;
        if (x2<0) x2=0 ; if (y2<0) y2=0;


        for (i=x1;i<=x2;i++) {
                display_string(i,y1,c,"Ä") ;
                display_string(i,y2,c,"Ä") ;
        }
        for (i=y1;i<=y2;i++) {
                display_string(x1,i,c,"³") ;
                display_string(x2,i,c,"³") ;
        }

        display_string(x1,y1,c,"Ú") ;
        display_string(x2,y1,c,"¿") ;
        display_string(x1,y2,c,"À") ;
        display_string(x2,y2,c,"Ù") ;
}

// [fold]  ]

// [fold]  (
static void do_calibration(int wasdirect)
{
        union REGS regs ;
        char b[90];
        FILE *f ;
        char    *p=(char *)0xb8000 ;
        int     k ;
        int     quit = FALSE ;
        int     xcursor_st=20,ycursor_st=20 ;
        int     xcursor_pc=20,ycursor_pc=20 ;
        jk = &joystick1_vars ;

        jk->calib_xmin=jk->calib_ymin=0x7fff ;
        jk->calib_xmax=jk->calib_ymax=0 ;

        if (!nb_joysticks_detected) {
                print_string(_col_err,"no joystick were found...") ;
                return ;
        }

        if (!wasdirect) {
                init_gfx() ;
        }
        regs.w.ax = 0x1202 ;
        regs.h.bl = 0x30 ;
        int386(0x10,&regs,&regs) ;
        regs.w.ax = 3 ;
        int386(0x10,&regs,&regs) ;
        regs.w.ax = 0x1112 ;
        regs.h.bl = 0 ;
        int386(0x10,&regs,&regs) ;

        display_string(0,0,15,"Joystick Calibration - ESC to quit - SPACE to reset values") ;
        display_string(0,1,15,"Change horizontal sensitivity with / and *, vertical with - and +") ;
        display_string(0,2,14,"The light cursor indicates the emulated joystick position.") ;
        display_string(0,3,14,"The blue frame indicates the limit where movements are taken into account.") ;
        do {
                if (kbhit()) k=getch() ;
                switch(k) {
                        case 0x1b :
                                        quit = (k==0x1b) ;
                                        break ;
                        case 0x20 :
                                        jk->calib_xmin=jk->calib_ymin=0x7fff ;
                                        jk->calib_xmax=jk->calib_ymax=0 ;
                                        break ;
                        case '/' :      if (jk->sensitivity_xjoy>1) --(jk->sensitivity_xjoy) ;
                                        break ;
                        case '*' :      if (jk->sensitivity_xjoy<8) ++(jk->sensitivity_xjoy) ;
                                        break ;
                        case '-' :      if (jk->sensitivity_yjoy>1) --(jk->sensitivity_yjoy) ;
                                        break ;
                        case '+' :      if (jk->sensitivity_yjoy<8) ++(jk->sensitivity_yjoy) ;
                                        break ;
                }

                poll_joystick() ;

                k = Global_PC_VBLs ;
                while (k==Global_PC_VBLs) ;

                xcursor_st = 40 ; ycursor_st = 25 ;
                xcursor_pc = ((xjoy-jk->calib_xmin)*80)/((jk->calib_xmax-jk->calib_xmin+1)) ;
                ycursor_pc = ((yjoy-jk->calib_ymin)*40)/((jk->calib_ymax-jk->calib_ymin+1))+5 ;

                jk->lim_xmin = jk->calib_xmin+((jk->calib_xmax-jk->calib_xmin)*(jk->sensitivity_xjoy)/17) ;
                jk->lim_xmax = jk->calib_xmax-((jk->calib_xmax-jk->calib_xmin)*(jk->sensitivity_xjoy)/17) ;
                jk->lim_ymin = jk->calib_ymin+((jk->calib_ymax-jk->calib_ymin)*(jk->sensitivity_yjoy)/17) ;
                jk->lim_ymax = jk->calib_ymax-((jk->calib_ymax-jk->calib_ymin)*(jk->sensitivity_yjoy)/17) ;
                if (jk->lim_xmin < jk->calib_xmin) jk->lim_xmin = jk->calib_xmin ;
                if (jk->lim_xmax > jk->calib_xmax) jk->lim_xmax = jk->calib_xmax ;
                if (jk->lim_ymin < jk->calib_ymin) jk->lim_ymin = jk->calib_ymin ;
                if (jk->lim_ymax > jk->calib_ymax) jk->lim_ymax = jk->calib_ymax ;

                for (k=160*5;k<160*46;k++) p[k] = 0 ;
                sprintf(b,"X=%5d (min:%5d, max:%5d)   Sensitivity=%d of 8  ",xjoy,jk->calib_xmin,jk->calib_xmax,jk->sensitivity_xjoy) ;
                display_string(0,46,9,b) ;
                sprintf(b,"Y=%5d (min:%5d, max:%5d)   Sensitivity=%d of 8  ",yjoy,jk->calib_ymin,jk->calib_ymax,jk->sensitivity_yjoy) ;
                display_string(0,47,9,b) ;

                draw_limit(1) ;

                if (xjoy<jk->lim_xmin) xcursor_st=0 ;
                        else if (xjoy>jk->lim_xmax) xcursor_st=79 ;
                if (yjoy<jk->lim_ymin) ycursor_st=5 ;
                        else if (yjoy>jk->lim_ymax) ycursor_st=45 ;

                display_string(xcursor_pc,ycursor_pc,1,"±") ;
                display_string(xcursor_st,ycursor_st,0x1f,"±") ;

        }
        while (!quit) ;

        //if (!wasdirect)
                deinit_gfx() ;


        sprintf(b,"%s\\%s",startdir,"JOY.CFG") ;
        f = fopen(b,"wb") ;
        fwrite(jk,sizeof(type_joy),1,f) ;
        fclose(f) ;

}

// [fold]  )

extern char *STPort_Emu_Names[4] ;

// [fold]  [
static void do_joysticks()
{
        int i, c, c1, c2;
        int x, y ;
        union REGS regs;

        init_gfx() ;
        regs.w.ax = 3 ;
        int386(0x10,&regs,&regs) ;

        display_string(23,0,0x1f,"*** Joystick Ports Emulation ***") ;

        display_string(0,2,8,                   "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ´ST PORT #0ÃÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄ´ST PORT #1ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿") ;
        for (i=3;i<10;i++) display_string(0,i,8,"³                                   ³                                          ³") ;
        display_string(0,10,8,                  "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ") ;


        display_string(0,15,10,"Port #1 is the default Joystick port on a real ST") ;
        display_string(0,16,10,"Port #0 is generaly for mouse") ;
        display_string(0,17,10,"Dark choices are not supported - Red means selected") ;

        display_string(0,20,11,"ESC : Quit This Screen") ;
        display_string(0,21,11,"ARROWS : Move around the table") ;
        display_string(0,22,11,"C : Joystick Calibration") ;
        display_string(0,23,11,"SPACE : Select") ;

        x = y = 0 ;

        do {
                display_string(3+x*40,y+4,14,"--->") ;
                for (i=0;i<4;i++) {
                        c = STPort_Emu_Allowed&(1<<i)?7:8 ;

                        c1 = (STPort[0] == (1<<i))? c|0x40 : c;
                        c2 = (STPort[1] == (1<<i))? c|0x40 : c;

                        display_string(8,i+4,c1,STPort_Emu_Names[i]) ;
                        display_string(48,i+4,c2,STPort_Emu_Names[i]) ;
                }

                c = getch() ;
                display_string(3+x*40,y+4,14,"    ") ;

                switch(c) {
                        case 0x48 :     if (--y<0) y = 3 ; break ;
                        case 0x50 :     if (++y>3) y = 0 ; break ;
                        case 0x4b :
                        case 0x4d :     x = 1-x ; break ;

                        case 0x20 :     if (STPort_Emu_Allowed&(1<<y))
                                                STPort[x] = 1<<y ;
                                        break ;
                        case 'c' :      do_calibration(TRUE) ;
                                        c = 27 ;
                                        break ;
                }


        } while(c!=27) ;

        deinit_gfx() ;
}

// [fold]  ]


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                              CTRL-keys
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

static void ctrl_keys(int ch)
{
        parameters = &nullchar ;
        silent = TRUE ;
        switch(ch) {
                case 'z' : do_traceinto() ;
                           break ;
                case 't' : do_traceover() ;
                           break ;
                case 'u' : do_traceuntil() ;
                           break ;
                case 'g' : do_go() ;
        }
        silent = FALSE ;
        window_disa_base = processor->PC ;
        display_disa_window(window_disa_base,window_disa_start,window_disa_length) ;
}


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                                    MFP
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
/*
static void do_mfp()
{
        char b[] = "Not implemented in this verstion." ;
        print_string(2,b) ;

}
*/

char *mfp_names[16] = {
        "$13C Monochrome Detect   ",
        "$138 RS-232 Ring Detector",
        "$134 Timer A             ",
        "$130 Receive Buffer Full ",
        "$12c Receive Error       ",
        "$128 Send Buffer Empty   ",
        "$124 Send Error          ",
        "$120 Timer B             ",
        "$11c FDC                 ",
        "$118 ACIA                ",
        "$114 Timer C             ",
        "$110 Timer D             ",
        "$10c Blitter             ",
        "$108 RS-232 CTS          ",
        "$104 RS-232 DCD          ",
        "$100 Centronics Busy     "
} ;


char *mfptimer_names[4] = {
        "STOPPED    ",
        "DELAY      ",
        "EVENT COUNT",
        "PULSE WIDTH"
} ;


extern unsigned int timera_cycles_2_go ;
extern unsigned int timerb_cycles_2_go ;
extern unsigned int timerc_cycles_2_go ;
extern unsigned int timerd_cycles_2_go ;

// [fold]  (
static void do_mfp()
{
        char b[256] ;
        int i ;
        UWORD ier = mfp.ier.ab ;
        UWORD ipr = mfp.ipr.ab ;
        UWORD imr = mfp.imr.ab ;
        UWORD isr = mfp.isr.ab ;


        sprintf(b,"         MFP vector                  Ena   Msk   Pnd  Ins") ;
        print_string(0x2f,b) ;

        for (i=0;i<16;i++) {
                sprintf(b,"%06X - %s    %d     %d     %d    %d",0xffffff&read_st_long(0x100+4*(15-i)),mfp_names[i],ier>>15,imr>>15,ipr>>15,isr>>15) ;
                print_string(ier>>15?15:7,b) ;
                ier<<=1 ; ipr<<=1 ; imr<<=1 ; isr<<=1 ;
        }

        sprintf(b,"EOI:%s   TACR=%02x TBCR=%02x TCDCR=%02x           Init  Now  ",mfp.soft_eoi?"SOFT":"HARD",peek_tacr(),peek_tbcr(),peek_tcdcr()) ;
        print_string(0x2f,b) ;

        for (i=0;i<4;i++) {
                UBYTE v ;
                if (i==0) v = peek_tadr() ;
                        else if (i==1) v = peek_tbdr() ;
                                else if (i==2) v = peek_tcdr() ;
                                        else v=peek_tddr() ;
                sprintf(b,"TIMER %c - Mode %s - %7d Hz        %02X    %02X",'A'+i,mfptimer_names[mfp.timers[i].mode],mfp.timers[i].freq,mfp.timers[i].data,v/*mfp.timers[i].cycle2go*/) ;
                print_string(7,b) ;
        }

        sprintf(b,"Cycles: A=%8d  B=%8d  C=%8d  D=%8d",timera_cycles_2_go,timerb_cycles_2_go,timerc_cycles_2_go,timerd_cycles_2_go) ;
        print_string(11,b) ;
}

// [fold]  )



/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                                HISTORY
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

static void do_history()
{
        extern int prevpc_tbl[64] ;
        extern int prevpc_cur ;
        int i ;
        char b[80] ;

        for (i=0;i<64;i+=4) {
                sprintf(b,"%08x  %08x  %08x  %08x",
                          prevpc_tbl[(prevpc_cur-i-1)&63],
                          prevpc_tbl[(prevpc_cur-i-2)&63],
                          prevpc_tbl[(prevpc_cur-i-3)&63],
                          prevpc_tbl[(prevpc_cur-i-4)&63]) ;
                print_string(2,b) ;

        }
}


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                                   EVAL
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

static void do_eval()
{
        int res,stat;
        char *msg ;

        stat = evaluator(parameters,&res,&msg) ;
        print_string(15,msg) ;
}

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                    FREEZING/UNFREEZING
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

extern int freeze(char *filename,char **msg,char *comments) ;
extern int unfreeze(char *filename,char **msg) ;
extern char *remfreeze(char *filename) ;

/*
        name = filename ;
        while (*parameters && (*parameters!=' '))
                *name++ = *parameters++ ;
        *name = '\0' ;                              // read filename
*/
/*
char *fznames[10][80] ;
int nbfz ;

void list_freeze()
{
        DIR *dirp ;
        struct dirent *direntp ;
        char b[120] ;

        nbfz = 0;
        print_string(0x1f," *** Listing freezed files *** ") ;
        dirp = opendir("?.FRZ") ;
        if (dirp) {
                direntp = readdir(dirp) ;
                while (direntp&&(nbfrz<9) {

                        strcpy(fznames[nbfz++],direntp->d_name) ;
                        sprintf(b,"(%d) [%s] - %d Kb",nbfz,direntp->d_name,direntp->d_size>>10) ;
                        print_string(7,b) ;
                        direntp = readdir(dirp) ;
                }
                closedir(dirp) ;
        }
        sprintf(b,"%d existing freezed files found.",nbfz) ;
        print_string(0x1f,b) ;
}

void do_freeze()
{
        int k ;

        list_freeze() ;
        print_string(15,"Press a number to unfreeze or F to freeze.") ;
        do {
                k = getch() ;
                if ((k>='1')&&(k<='9')) {
                        k-='0' ;
                        if (k




                }

        } while (k!=27) ;


}
*/

void list_freeze()
{
        DIR *dirp ;
        struct dirent *direntp ;
        char b[120] ;

        print_string(0x1f," *** FReeZed files found *** ") ;
        dirp = opendir("*.FRZ") ;
        if (dirp) {
                direntp = readdir(dirp) ;
                while (direntp) {

                        sprintf(b,"[%s] - %s",direntp->d_name,remfreeze(direntp->d_name)) ;
                        print_string(7,b) ;
                        direntp = readdir(dirp) ;
                }
                closedir(dirp) ;
        }
}

void do_freeze()
{
        char *msg ;
        char realnamez[14],*realname ;

        realname = realnamez ;
        while (*parameters==' ') parameters++ ;
        while (*parameters && (*parameters!=' ') && (*parameters!='.'))
                *realname++ = *parameters++ ;
        *realname = '\0' ;                          // read filename

        if (!*realnamez) {
                print_string(4,"You must specify a filename (8 chars)") ;
                print_string(4,"    ...and also a comment if you wish") ;
                return ;
        }

        if (nb_drives>2) {
                print_string(0x28,"WARNING: You should *NEVER* freeze when using mounted") ;
                print_string(0x28,"         drives! It may crash badly when unfreezing!!") ;
        }

        if (freeze(realnamez,&msg,parameters))
                print_string(15,msg) ;
        else    print_string(7,msg) ;
}

void video_unfreeze(void) ;
void do_unfreeze()
{
        char *msg ;
        extern int just_unfreezed ;
        char realnamez[14],*realname ;

        realname = realnamez ;
        while (*parameters==' ') parameters++ ;
        while (*parameters && (*parameters!=' ') && (*parameters!='.'))
                *realname++ = *parameters++ ;
        *realname = '\0' ;                          // read filename

        if (!*realnamez) {
                list_freeze() ;
                return ;
        }

        if (unfreeze(realnamez,&msg)) {
                just_unfreezed = 1;
                video_unfreeze() ;
        }
        print_string(15,msg) ;
}


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                            FIND MEMORY
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

#define FIND_BYTES              0
#define FIND_TEXT               1
#define FIND_INSTRUCTION        2

static char searchbytes[64] ;   // string to be searched for
static int nbsearchbytes = 0 ;  // number of bytes in the search string
MPTR searchresults[128] ;       // array of memory locations found
int nbresults ;                 // number of memory locations found

static void do_find_results(int verbose)
{
        char buf[80] ;
        char buf2[10] ;
        int  i,nbl=0 ;
        buf[0] = 0 ;

        if (verbose)
                if (nbresults)
                        print_string(_col_err,"*** Current results list ***") ;
                else {
                        print_string(_col_err,"Empty results list") ;
                        return ;
                }

        for (i=0;i<nbresults;i++) {
                sprintf(buf2,"%06x ",searchresults[i]) ;
                strcat(buf,buf2) ;
                if (nbl++ == 8) {
                        print_string(_col_brk,buf) ;
                        buf[0] = 0;
                        nbl = 0 ;
                }
        }
        if (nbl)
               print_string(_col_brk,buf) ;

}

// [fold]  [
static void do_find(int searchwhat)
{
        MPTR curadr,borne1,borne2 ;
        int status ;
        char c1,c2,c3 ;
        char b[80] ;
        int relative ;
        int value,i,ok ;
        int nbsbytes =0;

        skip_spaces(&parameters) ;
        if (!*parameters) {
                do_find_results(TRUE) ;
                return ;
        }

        c1 = parameters[0]|0x20 ; c2 = parameters[1]|0x20 ; c3 = parameters[2]|0x20 ;
        if ((c1=='r')&&(c2=='a')&&(c3=='m')) {
                borne1 = 0 ;
                borne2 = processor->ramsize-1 ;
                parameters+= 3 ;
        } else
         if ((c1=='r')&&(c2=='o')&&(c3=='m')) {
                borne1 = TOSbase ;
                borne2 = TOSbaseMax ;
                parameters+=3 ;
        } else {
                skip_spaces(&parameters) ;
                status = Read_Number(&borne1,FALSE) ;
                if (status) {
                        print_string(_col_err,"Error parameter #1") ;
                        return ;
                }
                skip_spaces(&parameters) ;
                relative = (*parameters=='+') ;
                if (relative) parameters++ ;
                skip_spaces(&parameters) ;
                status = Read_Number(&borne2,FALSE) ;
                if (status) {
                        print_string(_col_err,"Error parameter #2") ;
                        return ;
                }
                if (relative)
                        borne2 += borne1 ;
        }

        if ((borne2<borne1)||    /* borne2 < borne1 */
           ((borne1<processor->ramsize)&&(borne2>processor->ramsize))/*RAM...*/
           ||((borne1<TOSbase)&&(borne2>TOSbase+1))/*..ROM */
           ||(borne2 >TOSbaseMax+1))
         {
                print_string(_col_err,"Error in range or out of RAM & TOS") ;
                return ;
        }

        /***************** search for instructions *****************/

        if (searchwhat == FIND_INSTRUCTION) {
                print_string(_col_err,"Not yet implemented") ;
                return ;
        }

        /***************** search for bytes/string *****************/

        nbsbytes = 0 ;
        skip_spaces(&parameters) ;

        if (searchwhat == FIND_BYTES)
                while ((nbsearchbytes < 64)&&!Read_Number(&value,FALSE))
                        searchbytes[nbsbytes++] = value ;
        else    while ((nbsearchbytes < 64)&&*parameters)
                        searchbytes[nbsbytes++] = *parameters++ ;

        if (!nbsbytes) {
                if (nbsearchbytes)
                        print_string(14,"Using previous search string") ;
                else {
                        print_string(_col_err,"No search string specified") ;
                        return ;
                }
        } else nbsearchbytes = nbsbytes ;

        sprintf(b,"Searching %d bytes in Range %06X-%06X",nbsearchbytes,borne1,borne2) ;
        print_string(15,b) ;

        nbresults = 0 ;

        curadr = borne1 ;
        while (curadr <= borne2-nbsearchbytes) {
                if (read_st_byte(curadr) == searchbytes[0]) {
                        ok = TRUE ;
                        for (i=1;i<nbsearchbytes;i++)
                                if (read_st_byte(curadr+i) != searchbytes[i])
                                        ok = FALSE ;
                        if (ok)
                                searchresults[nbresults++] = curadr ;
                        if (nbresults==128) {
                                print_string(15,"Maximum hits (128) reached") ;
                                curadr = borne2 ;
                        }
                }
                curadr++ ;
        }

        sprintf(b,"%d hits",nbresults) ;
        if (nbresults!=128) print_string(15,b) ;
        do_find_results(FALSE) ;
}

// [fold]  ]


static void do_vars(void)
{
        int i ;
        char b[80] ;

        if (!nb_variables) {
                print_string(9,"No variables defined.") ;
                return ;
        }

        for (i=0;i<nb_variables;i++) {
                sprintf(b,"%12s = $%08x",variables[i].name,variables[i].value,variables[i].value) ;
                print_string(10,b) ;
        }
}

static void init_variables(void)
{
        affect_sysvariable("TOS",1+TOSbase) ;
        affect_sysvariable("RAM",processor->ramsize) ;
}

static void do_flushlog(void)
{
        extern FILE *fdebug ;
        extern char logfile[] ;

        fclose(fdebug) ;
        fdebug = fopen(logfile,"wt+") ;
        print_string(10,"Log flushed") ;
}

void enter_monitor()
{
        int i ;
        for (i=0;i<128;i++) doskey[i][0] = 0;
        Nb_Breakpoints = 0 ;
        currenty = window_free_start ;
        #ifdef DEBUGPROFILE
         wasprofile = isprofile ;
        #endif


        init_variables() ;

        if (isAutoRun) do_go() ;

        window_disa_base = TOSbase ;

        display_registers() ;

/*
        #ifndef DEBUG
        print_string(0x30, "[This BINARY of PaCifiST was build without debug capabilities]") ;
        #else
        print_string(0x30, "[This BINARY of PaCifiST was build with debug capabilities]") ;
        #endif
*/
        print_string(15,"g : Go the Atari!!!") ;
        print_string(15,"x : eXit") ;

        print_string(0x1e,"*** New monitor functions: ***") ;
        print_string(14,"fz <filename> <comments>      - freeze emulated Atari ST") ;
        print_string(14,"uz <filename>                 - unfreeze emulated Atari ST") ;
        print_string(14,"uz                            - list available freezed files") ;
        print_string(14,"f/ft <adr1> <adr2> <bytes>    - search in memory") ;
        print_string(14,"     adr    +len   <byte>");
        print_string(14,"     RAM           <byte>");
        print_string(14,"     ROM           <byte>");


        display_disa_window(window_disa_base,window_disa_start,window_disa_length) ;

        //ym_load() ;

        input_string() ;
        printf("\n") ;
        while (1) {
                if (iscmd("x",cmd)) goto GoEnd;
                if (iscmd("trap",cmd)) {do_trap();goto nxt;}
                if (iscmd("reset",cmd)) {do_reset();goto nxt;}
                if (iscmd("patch",cmd)) {do_patch();goto nxt;}
        #ifdef DEBUGPROFILE
                if (iscmd("profile",cmd)) {do_profile();goto nxt;}
        #endif
                if (iscmd("calib",cmd))  {do_calibration(FALSE) ; goto nxt;}
                if (iscmd("animate",cmd)) {do_animate();goto nxt;}
                if (iscmd("record",cmd)) {do_record();goto nxt;}
                if (iscmd("status",cmd)) {do_status() ; goto nxt;}
                if (iscmd("flushlog",cmd)) {do_flushlog() ; goto nxt;}
                if (iscmd("config",cmd)) {do_config() ; goto nxt;}
                if (iscmd("disa",cmd)) {do_disafile() ; goto nxt;}
                if (iscmd("kbdelay",cmd)) {do_kbdelay() ; goto nxt ;}
                if (iscmd("kbd",cmd)) {do_kbd() ; goto nxt;}
                if (iscmd("pref",cmd)) {do_prefetch() ; goto nxt;}
                if (iscmd("nop",cmd)) {do_nop() ; goto nxt;}
                if (iscmd("mody",cmd)) {do_mody() ; goto nxt;}
                if (iscmd("mod",cmd)) {do_mod() ; goto nxt;}
                if (iscmd("mfp",cmd)) {do_mfp() ; goto nxt;}
                if (iscmd("tos",cmd)) {do_tos() ; goto nxt;}
                if (iscmd("play",cmd)) {do_play() ; goto nxt;}
                if (iscmd("var",cmd)) {do_vars() ; goto nxt;}
                if (iscmd("history",cmd)) {do_history() ; goto nxt;}

                if (iscmd("h",cmd)||iscmd("?",cmd))  {do_help() ; goto nxt ;}
                if (iscmd("e",cmd))  {do_eval() ; goto nxt ;}
                if (iscmd("t",cmd))  {do_traceover() ; goto nxt ;}
                if (iscmd("z",cmd))  {do_traceinto() ; goto nxt ;}
                if (iscmd("d",cmd))  {do_disa() ; goto nxt ;}
                if (iscmd("r",cmd))  {display_registers() ; goto nxt ;}
                if (iscmd("g",cmd))  {do_go() ; goto nxt ;}
                if (iscmd("bp",cmd))  {do_breakpoint() ; goto nxt;}
                if (iscmd("ba",cmd))  {do_breakaccess() ; goto nxt;}
                if (iscmd("bo",cmd))  {do_breakopcode() ; goto nxt;}
                if (iscmd("m",cmd))  {do_dump() ; goto nxt;}
                if (iscmd("lb",cmd))  {do_loadbinary() ; goto nxt;}
                if (iscmd("sb",cmd))  {do_savebinary() ; goto nxt;}
                if (iscmd("s",cmd))  {do_set() ; goto nxt;}
                if (iscmd("fz",cmd)) {do_freeze() ; goto nxt;}
                if (iscmd("uz",cmd)) {do_unfreeze() ; goto nxt;}
                if (iscmd("ft",cmd)) {do_find(FIND_TEXT); goto nxt;}
                if (iscmd("fi",cmd)) {do_find(FIND_INSTRUCTION); goto nxt;}
                if (iscmd("f",cmd)) {do_find(FIND_BYTES); goto nxt;}

//                if (iscmd("frz",cmd)) {do_freeze() ; goto nxt;}
                if (iscmd("vol",cmd))  {do_volume() ; goto nxt;}

                print_string(_col_err,"???") ;
nxt:
         window_disa_base = processor->PC ;
         display_disa_window(window_disa_base,window_disa_start,window_disa_length) ;
         display_registers() ;
         input_string() ;
        }

GoEnd: ;

}

// [fold]  60
