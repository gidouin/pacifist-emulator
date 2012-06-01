#include <stdio.h>
#include <i86.h>
#include <dos.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#include <direct.h>
#include "cpu68.h"
#include "kb.h"
#include "vbe.h"
#include "config.h"
#include "timer.h"
#include "disk.h"
#include "eval.h"

char *pacifist_release = "PaCiFiST/DOS v0.49 beta" ;

char pacifist_major = 0 ;
char pacifist_minor = 0x49 ;

int load_ym(char *name, int *rept) ;
int vbe_listmodes_option = 0 ;
unsigned short ramseg ;
unsigned short romseg ;
unsigned short cartseg ;
unsigned short ioseg ;

extern void Init_Video(void) ;
extern int internal_init_mouse(void) ;
extern int internal_deinit_mouse(void) ;
extern void init_gemdos(void) ;
extern void init_joysticks(void) ;
extern void install_debug(void) ;
extern void init_parallel(void) ;
extern void deinit_parallel(void) ;
#ifdef SOUND
extern void init_sound(void) ;
extern void deinit_sound(void) ;
extern void debug_sound(void) ;
#endif

extern int nb_images ;

int isTrueColor ;
int isAutoRun = FALSE;
int isTestJoystick = TRUE ;
int isloadym = FALSE ;
char ymname[128] = "e:\\ym.dat" ;
extern void *screen_physical ;
extern void *screen_linear ;
//UWORD screendescriptor ;

//extern int diskkind ;
extern void report_profile() ;
static char tosname[80] = "tos.rom" ;                   // default TOS filename
char logfile[80] = "debug.log" ;                 // default LOG filename
//char imagename[80] = "disk.st" ;
MPTR TOSbase = 0xfc0000 ;                        // default TOS address
MPTR TOSbaseMax = 0xfeffff ;
static int base_adress ;  // adress added to the loading base of .H68 files
int needcycles = TRUE ;

static int commandline_refresh = FALSE ;
static int commandline_mono = FALSE ;
static int commandline_autorun = FALSE ;
static int commandline_ramsize = FALSE ;
static int commandline_sound = FALSE ;
static int commandline_pcdrive = FALSE ;
static int commandline_render = FALSE ;
static int commandline_ste = FALSE ;
static int isInternalMouse = FALSE ;
static int commandline_vbemode = FALSE ;
int mousecom  = 1;

char inifilename[128] = "PACIFIST.INI" ;


struct DOSMEM lowmembuffer ;

FILE *fdebug ;
 void OUTDEBUG(char *string)
 {
        //return ;

        if (needcycles) {

                fprintf(fdebug,"\t\t\t\t\t\t\t\t [%x]\n%s",Nb_Cycles,string) ;
                }
        else
                fprintf(fdebug,"\n%s",string) ;

}


int allocdosmem(int paragraphs, struct DOSMEM *dosmem)
{
        union REGS regs;
//        struct SREGS sregs;
        int valid ;

        regs.w.ax = 0x100 ;             // DPMI function 0x100 = Alloc DOS Memory
        regs.w.bx = paragraphs ;
        int386(0x31,&regs,&regs) ;
        valid = ((regs.w.cflag & INTR_CF)==0) ; // carry set on error

        dosmem->realmode_segment = regs.w.ax ;
        dosmem->pmode_selector = regs.w.dx ;

        if (valid) {
                regs.w.ax = 6 ;         // DPMI function 6 = Get Seg Base Adr
                regs.w.bx = regs.w.dx ; // BX = descriptor of allocated mem
                int386(0x31,&regs,&regs) ;
                valid = ((regs.w.cflag & INTR_CF)==0) ; // carry set on error
                dosmem->linear_base = (regs.w.cx<<16)|regs.w.dx ;
        }
        return valid ;
}

void freedosmem(struct DOSMEM *dosmem)
{
        union REGS regs ;

        regs.w.ax = 0x101 ;
        regs.w.dx = dosmem->pmode_selector ;
        int386(0x31,&regs,&regs) ;

}


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÒÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
 *³Void load_object_file(char *Name, int base) º                          ³
 *ÆÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼                          ³
 *³                                                                       ³
 *³      Name: ^Name of object file (.h68) to load                        ³
 *³                                                                       ³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
 */

static int hex2int(char **ptr, int nb)
/*      ptr = ^^string containing hexadecimal value
        nb  = max number of nibble to process */
{
        int digit ;
        int val = 0 ;

        while ((**ptr)&&(nb--)) {
                if ((**ptr) <= '9') digit = (**ptr) - '0' ;
                 else if ((**ptr) <= 'F') digit = (**ptr) - 'A' + 10 ;
                  else digit = (**ptr) - 'a' + 10 ;
                val = (val<<4)+digit ;
                (*ptr)++ ;
        }
        return val ;
}

static int line2mem(char *ptr)
{
        int adress, size_adress,nb_bytes ;
        int i ;
        int b ;

        size_adress = hex2int(&ptr,1)+1 ;
        nb_bytes = hex2int(&ptr,2) - size_adress - 1;
        adress = base_adress + hex2int(&ptr,size_adress<<1) ;

        for (i=0;i<nb_bytes;i++)
        {
                b = hex2int(&ptr,2) ;
                if (adress >= 0xfa0000)
                        memcartridge[(adress++)-0xfa0000] = b ; // expansion ROM
                else
//                        mem[adress++] = b ;
                *(memory_ram+adress++) = b ;
        }

        return nb_bytes ;
}


static int load_object_file(char *Name, int base)
{
  FILE *fp ;
  char line[80],*ptr ;
  int islast ;
  int nbbytes ;
  int nb ;
  nb = nbbytes = 0 ;

  base_adress = base ;
  fp = fopen(Name,"rt") ;

  if (fp == NULL) {
        printf("%s Not Found. No object file loaded in.",Name) ;
        return FALSE;
  }
//  printf("\nObject file <%s> loaded in...\n",Name) ;

  while (fgets(line,80,fp)!=NULL) {
        nb++ ;
        ptr = line ;
        islast = FALSE ;
        if ((*ptr++) != 'S') {printf("Error line %d.\n",nb) ; goto fastexit;}
        if ((nb==1) && ((*ptr)!='0')) {printf("Not and S file.\n");goto fastexit;}

        switch (*ptr) {
                case '0' : break ;
                case '1' :
                case '2' :
                case '3' : nbbytes += line2mem(ptr) ;
                case '9' : islast = TRUE ; break ;
                default  : printf("Error line %d.\n",nb) ; goto fastexit ;
       }
  }

//  printf("%d bytes loaded in memory\n",nbbytes) ;
fastexit:
  fclose(fp) ;
  return TRUE ;
}

static int filesize (FILE *fp)
{
        int size_of_file , temp ;

        temp = ftell(fp) ;
        fseek(fp,0L,SEEK_END) ;
        size_of_file = ftell(fp) ;
        fseek(fp,temp,SEEK_SET) ;
        return (size_of_file) ;
}

int load_tos(int ntos, int verbose)
{
        FILE *fp ;
        int filesz ;

        if (ntos >= nb_tos) return FALSE ;
        fp = fopen(TOStable[ntos].filename,"rb") ; if (fp==NULL) return FALSE ;
        filesz = filesize(fp) ;
        fread(memtos,0x80000,1,fp) ;
        fclose(fp) ;
        TOSbase = TOStable[ntos].base ;
        TOSbaseMax = TOSbase+filesz-1 ;
        current_tos = ntos ;

        if (verbose)
                printf("TOS version %x.%02x loaded at $%06x.\n",TOStable[ntos].v1,TOStable[ntos].v2,TOSbase) ;
        return TRUE;
}

void init_screen_50()
{
        union REGS regs;
        regs.w.ax = 0x1202 ;
        regs.h.bl = 0x30 ;
        int386(0x10,&regs,&regs) ;
        regs.w.ax = 3 ;
        int386(0x10,&regs,&regs) ;
        regs.w.ax = 0x1112 ;
        regs.h.bl = 0 ;
        int386(0x10,&regs,&regs) ;

/*        regs.h.ah = 1 ;
        regs.w.cx = 0 ;
        int386(0x10,&regs,&regs) ;
*/
        regs.h.ah = 1 ;
        regs.w.cx = 0x0607 ;
        int386(0x10,&regs,&regs) ;
}



// [fold]  (
static void GoodBye() // display "GoodBye" Screen
{
        int loop ;
        register int x,y ;
        unsigned short *ptscreen = (unsigned short *)(0xb8000);
        unsigned short *BiosRowCol = (unsigned short *)(0x450) ;
        init_screen_50() ;


/*
        loop = 0 ;
            for (x=0;x<80-loop;x++)
            {
               for (y=0;y<25;y++)
                        ptscreen[y*80+x+loop] = GoodByeScreen[y*80+x] ;
            }

        *BiosRowCol = 0x0d00 ;
*/
}

// [fold]  )


/*  skip_spaces:
 *
 *     skip spaces and tabs in given string pointer
 */

static void skip_spaces(char **pt)
{
   while (**pt && ((**pt==' ')||(*pt=='\t')  /*||(*pt==13)||(*pt==10)*/   ))
            (*pt)++ ;
}

/*
 *  get_next_word:
 *
 *     read the next word (nxtword) in a given string (string)
 *
 */

static void get_next_word(char **string,char *nxtword)
{
   skip_spaces(string) ;

   while ((**string) && (**string!=' ') && (**string!='\t') && (**string!=10)&&(**string!=13) && (**string!='=')&& (**string!=','))
    *nxtword++ = *(*string)++ ;
   *nxtword = 0 ;
}

// [fold]  [
static int isentry(char *test, char *parameters)
{
        while (*test) {
                if (!*parameters) return FALSE ;
                if (*test++ != ((*parameters++)|0x20)) return FALSE ;
         }
         return TRUE ;
}

// [fold]  ]

static int parse_options()
{
        FILE *fini ;
        char line[200],*pt ;                     // read line
        char param[80] ;
        char entryname[32] ;                     // current line entry
        char sectionname[32] ;                   // current section
        int nbline = 0 ;
        int dummy ;

        fini = fopen(inifilename,"rt") ;
        if (fini==FALSE) {fprintf(stderr,"%s not found. trying defaults.\nBe sure you're running PaCifiST from its directory.\n",inifilename) ; return FALSE;}

        *sectionname = '?' ;
        *(sectionname+1) = 0 ;

  while (fgets(line,200,fini)!=NULL) {
         nbline++ ;
         pt = line ;

         get_next_word(&pt,entryname) ;          // read the first word
         if (*entryname=='[')                    // it is a section
              strcpy(sectionname,entryname) ;
         else if ((*entryname)&&(*entryname!=';'))
         {
           skip_spaces(&pt) ;
           if (*pt++ != '=')                       // error if no parameters
           {
               fprintf(stderr,"*** error in INI file section %s line %d. No parameters... ***\n",sectionname,nbline) ;
               goto nxtline ;
           }
               if (isentry("tosbase",entryname)) { get_next_word(&pt,entryname) ; TOSbase = strtol(entryname,NULL,0) ; goto nxtline;}
               if (isentry("refreshrate",entryname)) {if (commandline_refresh) goto nxtline ;get_next_word(&pt,entryname) ;
                                                        dummy = strtol(entryname,NULL,0) ;
                                                        RefreshRate = dummy&0xff ;
                                                        goto nxtline;}
               if (isentry("volume",entryname)) {get_next_word(&pt,entryname) ;
                                                        dummy = strtol(entryname,NULL,0) ;
                                                        if (dummy<=255) globalvolume = dummy&0xff ;
                                                        else fprintf(stderr,"*** error in INI file - Volume must be in range 0-255 ***\n",nbline) ;
                                                        goto nxtline;}
               if (isentry("ramsize",entryname)) {if (commandline_ramsize) goto nxtline ;get_next_word(&pt,entryname) ;
                                                        if (!stricmp(entryname,"512k"))
                                                                processor->ramsize = 512<<10 ;
                                                        else {
                                                                double rm ;
                                                                rm = strtod(entryname,NULL) ;
                                                                //processor->ramsize = strtol(entryname,NULL,0) ;
                                                                processor->ramsize = rm * 2 ;
                                                                if (processor->ramsize>28) processor->ramsize = 28 ;
                                                                if (processor->ramsize<1) processor->ramsize = 1 ;
                                                                //processor->ramsize<<=20 ;
                                                                processor->ramsize <<= 19 ;
                                                        }
                                                        goto nxtline;}
#ifdef DEBUGPROFILE
               if (isentry("profile",entryname)) {get_next_word(&pt,param) ; if (isentry("yes",param)) isprofile=TRUE ;
                                                        else  if (isentry("no",param)) isprofile=FALSE ;
                                                        else  fprintf(stderr,"*** error in INI file section %s line %d. ***\n",sectionname,nbline) ;
                                                        goto nxtline ;}
#endif
               if (isentry("monochrome",entryname)) {if (commandline_mono) goto nxtline; get_next_word(&pt,param) ; if (isentry("yes",param)) IsMonochrome = TRUE ;
                                                        else {IsMonochrome = FALSE ; if (!isentry("no",param)) fprintf(stderr,"*** error in INI file section line %d. ***\n",nbline) ;}
                                                        goto nxtline ;}

               if (isentry("fastvideo",entryname)) {get_next_word(&pt,param) ; if (isentry("yes",param)) IsFastVideo = TRUE ;
                                                        else {IsFastVideo = FALSE ; if (!isentry("no",param)) fprintf(stderr,"*** error in INI file section line %d. ***\n",nbline) ;}
                                                        goto nxtline ;}

               if (isentry("truecolor",entryname)) {get_next_word(&pt,param) ; if (isentry("yes",param)) isTrueColor = TRUE ;
                                                        else {isTrueColor = FALSE ; if (!isentry("no",param)) fprintf(stderr,"*** error in INI file section line %d. ***\n",nbline) ;}
                                                        goto nxtline ;}

               if (isentry("68030",entryname)) {get_next_word(&pt,param) ; if (isentry("yes",param)) is68030 = TRUE ;
                                                        else {is68030 = FALSE ; if (!isentry("no",param)) fprintf(stderr,"*** error in INI file section line %d. ***\n",nbline) ;}
                                                        goto nxtline ;}

               if (isentry("autorun",entryname)) {if (commandline_autorun) goto nxtline;get_next_word(&pt,param) ; if (isentry("yes",param)) isAutoRun = TRUE ;
                                                        else {isAutoRun = FALSE ; if (!isentry("no",param)) fprintf(stderr,"*** error in INI file section line %d. ***\n",nbline) ;}
                                                        goto nxtline ;}

               if (isentry("sound",entryname)) {if (commandline_sound) goto nxtline;get_next_word(&pt,param) ; if (isentry("yes",param)) isSound = TRUE ;
                                                        else {isSound = FALSE ; if (!isentry("no",param)) fprintf(stderr,"*** error in INI file section line %d. ***\n",nbline) ;}
                                                        goto nxtline ;}

               if (isentry("pcdrive",entryname)) {if (commandline_pcdrive) goto nxtline;get_next_word(&pt,param) ; if (isentry("yes",param)) isPCDrive = TRUE ;
                                                        else {isPCDrive = FALSE ; if (!isentry("no",param)) fprintf(stderr,"*** error in INI file section line %d. ***\n",nbline) ;}
                                                        goto nxtline ;}

               if (isentry("serial",entryname)) {get_next_word(&pt,param); if (isentry("yes",param)) isSerial = TRUE ;
                                                        else {isSerial = FALSE ; if (!isentry("no",param)) fprintf(stderr,"*** error in INI file section line %d. ***\n",nbline) ;}
                                                        goto nxtline ;}

               if (isentry("joystick",entryname)) {get_next_word(&pt,param); if (isentry("yes",param)) isTestJoystick = TRUE ;
                                                        else {isTestJoystick = FALSE ; if (!isentry("no",param)) fprintf(stderr,"*** error in INI file section line %d. ***\n",nbline) ;}
                                                        goto nxtline ;}

               if (isentry("parallel",entryname)) {get_next_word(&pt,param) ; if (isentry("yes",param)) isParallel = TRUE ;
                                                        else {isParallel = FALSE ; if (!isentry("no",param)) fprintf(stderr,"*** error in INI file section line %d. ***\n",nbline) ;}
                                                        goto nxtline ;}

               if (isentry("samples",entryname)) {get_next_word(&pt,param) ; if (isentry("yes",param)) isSamples = TRUE ;
                                                        else {isSamples = FALSE ; if (!isentry("no",param)) fprintf(stderr,"*** error in INI file section line %d. ***\n",nbline) ;}
                                                        goto nxtline ;}

               if (isentry("leds",entryname)) {get_next_word(&pt,param) ; if (isentry("yes",param)) isLeds = TRUE ;
                                                        else {isLeds = FALSE ; if (!isentry("no",param)) fprintf(stderr,"*** error in INI file section line %d. ***\n",nbline) ;}
                                                        goto nxtline ;}

               if (isentry("internalmouse",entryname)) {get_next_word(&pt,param) ; if (isentry("yes",param)) isInternalMouse = TRUE ;
                                                        else {isInternalMouse = FALSE ; if (!isentry("no",param)) fprintf(stderr,"*** error in INI file section line %d. ***\n",nbline) ;}
                                                        goto nxtline ;}

               if (isentry("laptop",entryname)) {get_next_word(&pt,param) ; if (isentry("yes",param))
                                                                                isLaptop = TRUE ;
                                                        goto nxtline ;}

               if (isentry("ste",entryname)) {if (commandline_ste) goto nxtline ;get_next_word(&pt,param) ; if (isentry("yes",param))
                                                        isSTE = TRUE ;
                                                        goto nxtline ;}

               if (isentry("midi",entryname)) {get_next_word(&pt,param) ; if (isentry("yes",param))
                                                        isMIDI = TRUE ;
                                                        goto nxtline ;}

               if (isentry("mousecom",entryname)) {get_next_word(&pt,entryname) ;
                                                        dummy = strtol(entryname,NULL,0) ;
                                                        if ((dummy==1)||(dummy==2)) mousecom = dummy ;
                                                        else fprintf(stderr,"*** error in INI file - Com can only be 1 or 2 ***\n",nbline) ;
                                                        goto nxtline;}

               if (isentry("sensibility",entryname)||
                  (isentry("sensitivity",entryname))) {get_next_word(&pt,entryname) ;
                                                        dummy = strtol(entryname,NULL,0) ;
                                                        if ((dummy>0)&&(dummy<=10)) MouseSensibility = dummy ;
                                                        else fprintf(stderr,"*** error in INI file - Sensibility must be in range 1-10 ***\n",nbline) ;
                                                        goto nxtline;}

               if (isentry("kbdelay",entryname)) { get_next_word(&pt,entryname) ;
                                                    dummy = strtol(entryname,NULL,0) ;
                                                    if ((dummy>0)&&(dummy<=10)) keyboard_delay = dummy ;
                                                    goto nxtline ; }

                if (isentry("vbemode",entryname)) {get_next_word(&pt,entryname) ;
                                                    if (commandline_vbemode) goto nxtline ;
                                                    if (!stricmp(entryname,"?")) vbe_listmodes_option = -1 ;
                                                        else vbe_listmodes_option= strtol(entryname,NULL,0) ;
                                                    goto nxtline ;}


               if (isentry("image",entryname)) { char path[128] ;
                                                 int drv = nb_images;
                                                 get_next_word(&pt,path) ;
                                                 skip_spaces(&pt) ;
                                                 if (*pt++==',') {
                                                        drv = ((*pt)|0x20)-'a' ;
                                                 skip_spaces(&pt) ;
                                                 }
                                                 if (!register_image_to_bios(path,drv))
                                                        fprintf(stderr,"*** error in INI file - Invalid image line %d. ***\n",nbline) ;
                                                 goto nxtline ;
                                               }


               //get_next_word(&pt,imagename) ; goto nxtline;}

               if (isentry("mount",entryname)) { char path[128] ;
                                                 get_next_word(&pt,path) ;
                                                 if (!register_drive_to_gemdos(path))
                                                        fprintf(stderr,"*** error in INI file - Invalid path line %d. ***\n",nbline) ;
                                                 goto nxtline ;
                                               }

                if (isentry("render",entryname)) {if (commandline_render) goto nxtline ;
                                                get_next_word(&pt,entryname) ;
                                                if (!stricmp(entryname,"SCREEN")) videoemu_type = VIDEOEMU_SCREEN ;
                                                  else if (!stricmp(entryname,"LINE")) videoemu_type = VIDEOEMU_LINE ;
                                                  else if (!stricmp(entryname,"MIXED")) videoemu_type = VIDEOEMU_MIXED ;
                                                  else if (!stricmp(entryname,"CUSTOM")) videoemu_type = VIDEOEMU_CUSTOM ;
                                                  else fprintf(stderr,"**** error in file - Invalid Video Mode line %d****\n",nbline) ;
                                                goto nxtline ;
                                                }



               if (isentry("tos",entryname)) {
                                                FILE *fp ;
                                                unsigned int vtos ;
                                                char *p = TOStable[nb_tos].comments ;
                                                if (nb_tos==8) goto nxtline ;
                                                get_next_word(&pt,tosname) ;
                                                skip_spaces(&pt) ;
                                                strcpy(TOStable[nb_tos].filename,tosname) ;

                                                fp = fopen(tosname,"rb") ;
                                                if (fp==NULL) {
                                                        fprintf(stderr,"**** error in INI file - TOS file \"%s\" not found\n****\n",tosname) ;
                                                        goto nxtline ;
                                                }
                                                fread(&vtos,4,1,fp) ;
                                                TOStable[nb_tos].v1 = (vtos>>16)&0xff ;
                                                TOStable[nb_tos].v2 = (vtos>>24)&0xff ;
                                                fread(&vtos,4,1,fp) ;
                                                fclose(fp) ;
                                                TOStable[nb_tos].base = (vtos&0xff00)<<8 ;
                                                skip_spaces(&pt) ;
                                                if (*pt==',') pt++ ;
                                                skip_spaces(&pt) ;
                                                if (*pt++=='\"')
                                                 while ((*pt!='\"')&&*pt) *p++=*pt++ ;
                                                *p = 0 ;
                                                nb_tos++ ;
                                                goto nxtline;
                                             }
               if (isentry("logfile",entryname)) {get_next_word(&pt,logfile) ;goto nxtline;}

               if (isentry("trapirq",entryname))
                   {
                       int l ;
                   nxttrap:
                       skip_spaces(&pt) ;
                       if (*pt==',') pt++ ;
                       get_next_word(&pt,param) ;
                       if ((!*param)||(*param==';')) goto nxtline;
                       if (isentry("all",param)) {for (l=0;l<256;l++) trapIRQs[l]=TRUE ; goto nxttrap;}
                       if (isentry("none",param)){for (l=0;l<256;l++) trapIRQs[l]=FALSE ; goto nxttrap;}
                       l = strtol(param,NULL,0) ;
                       if ((l>=0)&&(l<256)) trapIRQs[l] = TRUE ;
                           else if ((l<0)&&(l>-255))trapIRQs[-l] = FALSE ;
                       goto nxttrap;
                   }

               if (isentry("logirq",entryname))
                   {
                       int l ;
                   nxtlog:
                       skip_spaces(&pt) ;
                       if (*pt==',') pt++ ;
                       get_next_word(&pt,param) ;
                       if ((!*param)||(*param==';')) goto nxtline;
                       if (isentry("all",param)) {for (l=0;l<256;l++) logIRQs[l]=TRUE ; goto nxtlog;}
                       if (isentry("none",param)){for (l=0;l<256;l++) logIRQs[l]=FALSE ; goto nxtlog;}
                       l = strtol(param,NULL,0) ;
                       if ((l>=0)&&(l<256)) logIRQs[l] = TRUE ;
                           else if ((l<0)&&(l>-255))logIRQs[-l] = FALSE ;
                       goto nxtlog;
                   }

               fprintf(stderr,"*** error in INI file section %s line %d. Unknown entry %s ***\n",sectionname,nbline,entryname) ;
         }
nxtline:;
   }
        fclose(fini) ;
        return TRUE ;
}


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                            TIMER WORKs
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/


static void (__interrupt __far *prev_timer)() ;
static void (__interrupt __far *prev_ctrlbreak)() ;
static int skip_system_timer = 0 ;
static int skip_vbl = 0 ;
extern void PC_Timer_200Hz() ;
unsigned int nb_200Hz = 0;

#define PITCLOCK 1193180
#define timer_value (PITCLOCK/200)

extern void __interrupt __far criticalerror_handler() ;

static void __interrupt __far mytimer(void)
{

//        if (ModeST) periodic_leds() ;

        nb_200Hz++ ;
        skip_vbl += 50 ;
        skip_system_timer += 182 ;

        if (ModeST&NativeSpeed&&isSystemTimerC) {
                 processor->events_mask |= MASK_TIMERC ;
        }

        if (skip_vbl >= 200) {
                PC_Timer_VBL() ;
                skip_vbl -= 200 ;

        }

        PC_Timer_200Hz() ;

        if (skip_system_timer < 2000)
        {
                outp(0x20,0x20) ;
                return ;
        }

        skip_system_timer -= 2000 ;
        _chain_intr(prev_timer) ;
}


extern void reset_machine(int hard) ;
extern void fileselector_reset() ;

#pragma off (check_stack) ;
void __interrupt __far myctrlbreak(void)
{
        fileselector_reset() ;
        reset_machine(TRUE) ;
}
#pragma on (check_stack) ;



static void init_timer(void)
{
        prev_timer = _dos_getvect(8) ;
        _dos_setvect(8,mytimer) ;
        outp(0x43,0x36) ;
        outp(0x40,(timer_value&0xff)) ;
        outp(0x40,(timer_value>>8)&0xff) ;

        prev_ctrlbreak =  _dos_getvect(0x1b) ;
        _dos_setvect(0x1b,myctrlbreak) ;
        _dos_setvect(0x24,criticalerror_handler) ;
}

static void deinit_timer(void)
{
        outp(0x43,0x36) ;
        outp(0x40,0x0) ;
        outp(0x40,0x0) ;
        _dos_setvect(8,prev_timer) ;
        _dos_setvect(0x1b,prev_ctrlbreak) ;
}

unsigned int timer_read(void)
{
        unsigned int time ;
        unsigned int l,m ;

        outp(0x43,0) ;  // stop timer to read it
        l = inp(0x40) ;
        m = inp(0x40) ;

        time = timer_value - ((m<<8)+l) ;
        time = ((time<<16)/timer_value)+(nb_200Hz<<16) ;
        return time ;
}





extern short PacifistLogo ;

static void display_logo()
{
        int i ;
        short *ptr = (short *)(0xb8000) ;
        short *logo = &PacifistLogo ;

        init_screen_50() ;
        for (i=0;i<21;i++) printf("\n") ;
        for (i=0;i<1999;i++)
                *ptr++ = *logo++ ;
}

extern unsigned int Cycles_Per_RasterLine  ;
extern unsigned int Total_RasterLines ;

extern double allcycles ;
extern double localcycles ;

extern void init_serial(void) ;

int toto = 0;
extern void build_screen() ;



/*********************************************** Standard Mouse driver *****/

extern volatile int MouseX ;
extern volatile int MouseY ;
extern volatile int Mouse_Buttons ;
static volatile int MouseX_raw ;
static volatile int MouseY_raw ;

#pragma aux mouse_isr parm [esi] [edi] [ebx];
#pragma off (check_stack) ;
static void _loadds far mouse_isr(int xmickey, int ymickey, int buttons)
{
        processor->events_mask |= MASK_MOUSE ;
        MouseX_raw = MouseX = xmickey ;
        MouseY_raw = MouseY = ymickey ;

        buttons &= 3 ;
        Mouse_Buttons = ((buttons&2)>>1)|((buttons&1)<<1) ;
}
#pragma on (check_stack) ;


static int standard_init_mouse(void)
{
        union REGS regs ;
        struct SREGS sregs ;

        regs.x.eax = 0 ;
        int386(0x33,&regs,&regs) ;
        if (regs.w.ax != 0xffff) return FALSE ;

        memset(&sregs,0,sizeof(sregs)) ;
        regs.w.ax = 0xc ;
        regs.w.cx = 0x1f ;
        regs.x.edx = FP_OFF(mouse_isr) ;
        sregs.es = FP_SEG(mouse_isr) ;
        int386x(0x33,&regs,&regs,&sregs) ;

        regs.x.eax = 0x1a ;
        regs.x.ebx = regs.x.ecx = MouseSensibility*10 ;
        regs.x.edx = MouseSensibility*6 ;
        int386(0x33,&regs,&regs) ;
        return TRUE ;
}

static void standard_deinit_mouse(void)
{
        union REGS regs ;
        regs.w.ax = 0x21 ;
        int386(0x33,&regs,&regs) ;
}


static int init_mouse(void)
{
        if (isInternalMouse) {
                if (!internal_init_mouse()) {
                        printf("\n*** FATAL error. Internal Mouse Driver can't be installed.\n\n") ;
                        return FALSE ;
                } else  printf("\nInternal Mouse Driver (COM%d:) installed.\n",mousecom) ;
        } else {
                if (!standard_init_mouse()) {
                        printf("\n*** FATAL error. Standard Mouse Driver can't be installed.\n\n") ;
                        return FALSE ;
                } else  printf("\nStandard Mouse Driver installed with sensitivity %d of 10.\n",MouseSensibility) ;
        }
        return TRUE ;
}

static void deinit_mouse(void)
{
        if (isInternalMouse)
                internal_deinit_mouse() ;
        else standard_deinit_mouse() ;
}

/*************************************************************************/

struct OPT {
        char    *optname ;
        int     isparam ;
        int     optid ;
} ;

#define OPT_NONE        0x0000
#define OPT_USAGE       0x0001
#define OPT_IMAGE       0x0002
#define OPT_MOUNT       0x0003
#define OPT_RATE        0x0004
#define OPT_MONO        0x0005
#define OPT_AUTORUN     0x0006
#define OPT_RAMSIZE     0x0007
#define OPT_SOUND       0x0008
#define OPT_MAXSPEED    0x0009
#define OPT_LINE        0x000a
#define OPT_PCDRIVE     0x000b
#define OPT_YMRECORD    0x000c
#define OPT_INI         0x000d
#define OPT_RENDER      0x000e
#define OPT_STE         0x000f
#define OPT_YM          0x0010
#define OPT_VBEMODE     0x0011
char param[128] ;

struct OPT optlist[] = { {"help",0,OPT_USAGE},
                        {"h",0,OPT_USAGE},
                        {"?",0,OPT_USAGE},
                        {"image",1,OPT_IMAGE},
                        {"mount",1,OPT_MOUNT},
                        {"refreshrate",1,OPT_RATE},
                        {"mono",1,OPT_MONO},
                        {"autorun",1,OPT_AUTORUN},
                        {"ramsize",1,OPT_RAMSIZE},
                        {"sound",1,OPT_SOUND},
                        {"maxspeed",0,OPT_MAXSPEED},
                        {"line",0,OPT_LINE},
                        {"pcdrive",1,OPT_PCDRIVE},
                        {"ymrecord",0,OPT_YMRECORD},
                        {"ini",1,OPT_INI},
                        {"render",1,OPT_RENDER},
                        {"ste",1,OPT_STE},
                        {"ym",1,OPT_YM},
                        {"vbemode",1,OPT_VBEMODE},
                        {"",0,OPT_NONE}
} ;

void display_usage(void)
{
        printf("\nPACIFIST [options]\n") ;
        printf("Current valid options are:\n") ;
        printf("        /[h(elp)|?] this reminder\n") ;
        printf("        /ini <configuration file>\n") ;
        printf("        /refreshrate n\n") ;
        printf("        /mono [yes|no]\n") ;
        printf("        /image filename\n") ;
        printf("        /mount path\n") ;
        printf("        /autorun [yes|no]\n") ;
        printf("        /ramsize [n (Mb)|512k]\n") ;
        printf("        /sound [yes|no]\n") ;
        printf("        /maxspeed\n") ;
        printf("        /pcdrive [yes|no]\n") ;
        printf("        /render [screen|line|mixed|custom]\n") ;
        printf("        /ste [yes|no]\n") ;
        printf("        /ymrecord\n") ;
        printf("        /vbemode n (? to create a list)") ;
        exit(1) ;
}



// [fold]  [
int parse_arg(int argc,char **arg)
{
        static  int idx  = 1;
        char *optname ;
        struct OPT *opt = optlist ;
        int found = FALSE ;
        if (idx > argc) return FALSE ;  // no more arguments
        if ((arg[idx][0] != '-') && (arg[idx][0] != '/')) {
                printf("Unknown option %s\n",arg[idx]) ;
                return FALSE ;
        }
        optname = &arg[idx][1] ;
        idx++ ;

        while (opt->optid&&(!found)) {
                if (stricmp(optname, opt->optname) == 0) {
                        found = TRUE ;
                        if (!opt->isparam) return opt->optid ;  // if no param
                        if ((idx > argc)||(arg[idx][0]=='-')||(arg[idx][0]=='/')) {
                                printf("Option <%s> needs paramter\n",optname) ;
                                return FALSE ;
                        }
                        strcpy(param,arg[idx]) ;
                        idx++ ;
                        return opt->optid ;
                }
                opt++ ;
        }
        printf("Unknown option %s\n",optname) ;
        return FALSE ;

}

// [fold]  ]

// [fold]  (
int parse_commandline(int argc,char **argv)
{
        int     opt ;
        int     curdrv = 0 ;

        while  (opt = parse_arg(argc, argv)) {
                switch(opt) {
                        case OPT_USAGE: display_usage() ;
                                        break ;
                        case OPT_IMAGE: if (!register_image_to_bios(param,curdrv++)) {
                                         fprintf(stderr,"*** Invalid image \"%s\" ***\n",param) ;
                                         return FALSE ;
                                         }
                                        break ;
                        case OPT_MOUNT: if (!register_drive_to_gemdos(param)) {
                                         fprintf(stderr,"*** Invalid path \"%s\". ***\n",param) ;
                                         return FALSE ;
                                        }
                                        break ;
                        case OPT_RATE : commandline_refresh = TRUE ;
                                        RefreshRate = atoi(param) ;
                                        if (RefreshRate < 1) RefreshRate = 1 ;
                                        if (RefreshRate > 50) RefreshRate = 50 ;
                                        break ;
                        case OPT_MONO : commandline_mono = TRUE ;
                                        if (!stricmp(param,"YES")) IsMonochrome = TRUE ;
                                        else IsMonochrome = FALSE ;
                                        break ;
                        case OPT_AUTORUN: commandline_autorun = TRUE ;
                                        if (!stricmp(param,"YES")) isAutoRun = TRUE ;
                                        else isAutoRun = FALSE ;
                                        break ;
                        case OPT_RAMSIZE: commandline_ramsize = TRUE ;
                                        if (!stricmp(param,"512k"))
                                                processor->ramsize = 512<<10 ;
                                        else {
                                                double rm ;
                                                rm = strtod(param,NULL) ;
                                                processor->ramsize = rm*2 ;
                                                //processor->ramsize = atoi(param) ;
                                                if (processor->ramsize < 1) processor->ramsize = 1 ;
                                                if (processor->ramsize > 28) processor->ramsize = 28 ;
                                                processor->ramsize<<=19 ;
                                        }
                                        break ;
                        case OPT_SOUND: commandline_sound = TRUE ;
                                        if (!stricmp(param,"YES")) isSound = TRUE ;
                                        else isSound = FALSE ;
                                        break ;
                        case OPT_MAXSPEED:   NativeSpeed = TRUE ;
                                        break ;
                        case OPT_LINE:  if (vbe_ok) videoemu_type = VIDEOEMU_LINE ;
                                        else printf("Warning: Can't use Line Mode - No VBE2.0 driver found\n") ;
                                        break ;
                        case OPT_PCDRIVE: commandline_pcdrive = TRUE ;
                                        if (!stricmp(param,"YES")) isPCDrive = TRUE ;
                                        else isPCDrive = FALSE ;
                                        break ;
                        case OPT_YMRECORD: isYMrecord = TRUE ;
                                        break ;
                        case OPT_INI:   strcpy(inifilename,param) ;
                                        break ;
                        case OPT_RENDER:commandline_render= TRUE ;
                                        if (!stricmp(param,"SCREEN")) videoemu_type = VIDEOEMU_SCREEN ;
                                        else if (!stricmp(param,"LINE")) videoemu_type = VIDEOEMU_LINE ;
                                        else if (!stricmp(param,"MIXED")) videoemu_type = VIDEOEMU_MIXED ;
                                        else if (!stricmp(param,"CUSTOM")) videoemu_type = VIDEOEMU_CUSTOM ;
                                        else {
                                                fprintf(stderr,"\n*** Invalid VIDEO Parameter ***\n") ;
                                                return FALSE ;
                                        }
                                        break ;
                        case OPT_STE:   commandline_ste = TRUE ;
                                        if (!stricmp(param,"YES")) isSTE = TRUE ;
                                        else isSTE = FALSE ;
                                        break ;
                        case OPT_YM:
                                        isloadym = TRUE ;
                                        strcpy(ymname,param) ;
                                        break ;
                        case OPT_VBEMODE:
                                        commandline_vbemode = TRUE ;
                                        if (!stricmp(param,"?")) vbe_listmodes_option = -1 ;
                                         else vbe_listmodes_option= strtol(param,NULL,0) ;
                       }

        }
        return TRUE ;
}

// [fold]  )


unsigned short make_descriptor(void *base, int limit)
{
        union REGS regs ;
        short descriptor ;

        regs.x.eax = 0 ;        // DPMI function 0 - Allocate descriptor
        regs.x.ecx = 1 ;        // 1 descriptor to allocate
        int386(0x31,&regs,&regs) ;
        if (regs.w.cflag&1) return 0 ;
        descriptor = regs.w.ax ;

        regs.x.eax = 7 ;        // DPMI function 7 - Set Base Adress
        regs.w.bx = descriptor ;// segment
        regs.w.cx = (int)base>>16 ;
        regs.w.dx = (int)base&0xffff ;
        int386(0x31,&regs,&regs) ;
        if (regs.w.cflag&1) return 0 ;

        regs.x.eax = 8 ;        // DPMI function 8 - Set Segment Limit
        regs.w.bx = descriptor ;
        regs.w.cx = (limit-1)>>16 ;
        regs.w.dx = (limit-1)&0xffff ;
        int386(0x31,&regs,&regs) ;
        if (regs.w.cflag&1) return 0;
        return descriptor ;
}

#define LIMIT_CRASH 4096+65536

int init_memory()
{
        int i ;


/*
        static char r[512*1024] ;
        memory_ram = r ;
        processor->ramsize = 512*1024 ;
*/
        memory_ram=(char *)malloc(processor->ramsize+LIMIT_CRASH) ;

        if (memory_ram==0) {
                fprintf(stderr,"\nUnable to allocate %d Kb for ST RAM\n\n",processor->ramsize>>10) ;
                return FALSE ;
        }

        allocated_ram = processor->ramsize ;
        for (i=0;i<65536;i++)
                memio[i] = 0 ;

        for (i=0;i<processor->ramsize;i++) *(memory_ram+i) = 0 ;

        ramseg = make_descriptor(memory_ram,processor->ramsize+LIMIT_CRASH) ;
        romseg = make_descriptor(memtos,256*1024+LIMIT_CRASH) ;
        cartseg = make_descriptor(memcartridge,128*1024+LIMIT_CRASH) ;
        ioseg = make_descriptor(memio,64*1024+LIMIT_CRASH) ;
        if (ramseg&&romseg&&cartseg&&ioseg) {
                printf("\n%d Kb of Atari ST RAM allocated.\n",processor->ramsize>>10) ;
                return TRUE ;
        }

        fprintf(stderr,"\nUnable to allocate descriptor for ST ram\n\n") ;
        return FALSE ;
}

void load_joystick_config(void)
{
        FILE *f ;
        type_joy *jk ;
        jk = &joystick1_vars ;

        f=fopen("joy.cfg","rb") ;
        if (f) {
                fread(jk,sizeof(type_joy),1,f) ;
                fclose(f) ;
                printf("JOY.CFG loaded.\n\n") ;
        } else
        {
                printf("JOY.CFG not found. Type \"calib\" under monitor to calibrate your joystick...\n\n") ;

                jk->calib_xmin=jk->calib_ymin=0x7fff ;
                jk->calib_xmax=jk->calib_ymax=0 ;
                jk->sensitivity_xjoy = 6 ;
                jk->sensitivity_yjoy = 6 ;
        }

        jk->lim_xmin = jk->calib_xmin+((jk->calib_xmax-jk->calib_xmin)*(jk->sensitivity_xjoy)/17) ;
        jk->lim_xmax = jk->calib_xmax-((jk->calib_xmax-jk->calib_xmin)*(jk->sensitivity_xjoy)/17) ;
        jk->lim_ymin = jk->calib_ymin+((jk->calib_ymax-jk->calib_ymin)*(jk->sensitivity_yjoy)/17) ;
        jk->lim_ymax = jk->calib_ymax-((jk->calib_ymax-jk->calib_ymin)*(jk->sensitivity_yjoy)/17) ;
}

extern void Init_MFP() ;

main(int argc, char *argv[])
{
        char *p ;
        int i,k ;

        //connerie_de_gus() ;
        //exit(1) ;

        //is68030 = TRUE ;
/*
        Init_Evaluator() ;
        Eval() ;
        exit(1) ;
*/
        display_logo() ;


        printf("Pacifist v%x.%x beta - SPECIAL LGD3 - http://lgd.fatal-design.com\n Compiled 00:50pm 7th June 1998 with:",pacifist_major,pacifist_minor) ;
        printf("\n\t\t\t\t\t\t\tSOUND directive ") ;
        #ifdef SOUND
                printf("on") ;
        #else
                printf("off") ;
        #endif
        printf("\n\t\t\t\t\t\t\tPROFILE directive ") ;
        #ifdef PROFILE
                printf("on") ;
        #else
                printf("off") ;
        #endif
        printf("\n\t\t\t\t\t\t\tDEBUG directive ") ;
        #ifdef DEBUG
                printf("on") ;
        #else
                printf("off") ;
        #endif
        printf("\n\t\t\t\t\t\t\tGURU directive ") ;
        #ifdef GURU
                printf("on\n") ;
        #else
                printf("off\n") ;
        #endif

        processor = &base_processor ;
        processor->ramsize = 512*1024 ;
/*
{
        extern int get_key() ;
        int k ;
        kb_install() ;
        processor->events_mask = 0 ;
        ModeST = TRUE ;
        do {
                if (processor->events_mask&MASK_UserBreak) goto fin ;

                k = get_key() ;
                if (k) {
                        printf("%02X  ",k) ;
                        fflush(stdout) ;
                }
        } while (1);
fin: ;
        kb_deinstall() ;
        exit(1) ;
}
*/
        if (!allocdosmem(32*11,&lowmembuffer)) {
                fprintf(stderr,"Unable to allocable DOS memory for drive emulation buffer.\n") ;
                exit(3) ;
        }

        getcwd(startdir,256) ;
        if (startdir[strlen(startdir)-1] == '\\')
                startdir[strlen(startdir)-1] = 0 ;

        if (p=(char *)getenv("TEMP"))
                strncpy(tempdir,p,256) ;
        else {
                getcwd(tempdir,256) ;
        }
        if (tempdir[strlen(tempdir)-1] == '\\')
                tempdir[strlen(tempdir)-1] = 0 ;


        vbe_ok = VBE_init() ;

        for (i=0;i<256;i++) {
                logIRQs[i] = FALSE ;
                trapIRQs[i] = FALSE ;
        }

        init_gemdos() ;
        init_images() ;

        if (--argc) if (!parse_commandline(argc,argv)) exit(1);
        if (!parse_options())
                printf("error parsing INI file...\n") ;

        if (nb_images == 0) {
                printf("Warning: No image for drives A: & B:\n") ;
                if (isPCDrive) {
                        register_pcdrive_to_system(0) ;
                        printf("PC Drive A: is mapped on ST one at startup...\n") ;
                } else current_drive= 2 ;
        } else if (isPCDrive)
                printf("PC Drive A: can handle standard ST disks...\n") ;


        if (vbe_listmodes_option) {
                if (vbe_listmodes_option==-1)
                        VBE_listmodes() ;
                else
                        if (!VBE_cfg_initmode(vbe_listmodes_option))
                                printf("Unable to select VBE Mode 0x%04x",vbe_listmodes_option) ;
        }

        if (((videoemu_type==VIDEOEMU_MIXED)&&!vbemode_for_mixed)||
            ((videoemu_type==VIDEOEMU_CUSTOM)&&!vbemode_for_custom))
            videoemu_type=VIDEOEMU_SCREEN ;

        if (!init_memory()) exit(1) ;

        if (!load_tos(nb_tos-1,TRUE)) {
             fprintf(stderr,"\n*** FATAL error loading TOS.\n\n") ;
             exit(1) ;
        }

        printf("\nCONSTRUCTION OF OPCODEs TABLE...\n") ;
        Init_68000() ;
        if (is68030) printf("This binary of PaCifiST lacks 68030 support.\n") ;


#ifdef GURU
                install_debug() ;
#endif

        if (!load_object_file("patch.h68",0xfa0000))
                exit(3) ;

        Reset_68000() ;
        Init_MFP() ;
        Init_Video() ;

        fdebug = fopen(logfile,"wt+") ;

        if (isSerial) init_serial() ;
        if (isParallel) init_parallel() ;
        if (!init_mouse()) exit(2) ;

        STPort_Emu_Allowed = STPORT_EMU_NONE|STPORT_EMU_NUMERICPAD ;

        STPort[0] = STPORT_EMU_NONE ;
        STPort[1] = STPORT_EMU_NUMERICPAD ;

        if (isTestJoystick) {
                init_joysticks() ;
                printf("I detected %d joystick(s).\n",nb_joysticks_detected) ;
                if (nb_joysticks_detected) {
                        JoyEmu = FALSE ;
                        load_joystick_config() ;
                }
        } else printf("You will use Joystick Emulation.\n\n") ;
        if (nb_joysticks_detected > 0) {
                STPort_Emu_Allowed |= STPORT_EMU_PCJOY1 ;
                STPort[0] = STPort[1] ;
                STPort[1] = STPORT_EMU_PCJOY1 ;
        }
        JoyEmu = (STPort[0]|STPort[1])&STPORT_EMU_NUMERICPAD ;


        init_fileselector() ;

#ifdef SOUND
        init_sound() ;
//        init_midi() ;

        if (isSound&&isYMrecord)
        {
                int nbpos,rept ;
//                nbpos=load_ym(ymname,&rept) ;
                ym_load(ymname) ;
//                printf("***** %s loaded. Size=%d Rept=%d *****\n",ymname,nbpos,rept) ;

        }
#endif

        kb_install() ;
        init_timer();


/************************** TFMX *******************

        {
                FILE *fp ;

                load_object_file("tfmx\\tfmx2.h68",0) ;
                paula_init() ;

                init_tfmx() ;


                fp = fopen("a.tfx","rb") ;
                if (fp == NULL)
                        printf("Error opening .TFX\n") ;

                        fread((MPTR)stmem_to_pc(0x10000),1,0x100000,fp) ;
                        fclose(fp) ;

                fp = fopen("a.sam","rb") ;
                if (fp == NULL)
                        printf("Error opening .SAM\n") ;

                        fread((MPTR)stmem_to_pc(0x20000),1,0x100000,fp) ;
                        fclose(fp) ;

                processor->PC = 0x0f00 ;

        }


****************************************************/

        if (isSTE) printf("STE Shifter Emulation.\n") ;
        printf("\nReady to enter MoN68 v1.1 (G to go directly)\n") ;
        if (!isAutoRun) {
                k=getch() ;
                isAutoRun = ((k|0x20)=='g') ;
        }

        init_screen_50() ;

        enter_monitor() ;

        deinit_timer() ;
        kb_deinstall() ;
        deinit_mouse() ;
        VBE_deinit() ;
        Quit_68000() ;

        deinit_fileselector() ;

        GoodBye() ;

#ifdef SOUND
//        deinit_midi() ;
        deinit_sound() ;
#endif

        if (isParallel) deinit_parallel() ;

 #ifdef DEBUGPROFILE
        needcycles=0 ;
        if (wasprofile) report_profile() ;
 #endif
        fclose(fdebug) ;
        SystemClose() ;
        freedosmem(&lowmembuffer) ;

//        paula_end() ;



//        debug_sound() ;

/*
        fprintf(stderr,"Nb running VBLs:%d\n",Global_PC_VBLs) ;
        allcycles /= (Nb_VBLs+1) ;
        fprintf(stderr,"\nSession relative speed is about %#5.1f%% of a mere ATARI STF.\n",(100*allcycles)/(512*313)) ;

        printf("Timer During VBL:%f\n",(float)Relative_Speed) ;

*/

//        printf("toto=%d\n",toto) ;
}
// [fold]  4
