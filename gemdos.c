/*      GEMDOS Emulation
 *
 *  7/8/96 : dgetdrv
 *  7/7/96 : a few functions are well emulated: Dsetdrv, Fsetdta, Dsetdta,
 *           Fsfirst, Fsnext.
 * 12/7/96 : added  Fopen, Fclose, Fread, Fseek
 *           *** problem *** : Fread can only read 64 Kb once.
 * 14/7/96 : corrected error codes PC -> ST conversion
 *           added fwrite, fcreate, fdelete, dcreate, ddelete
 * 30/11/96: added fdatime, dfree, frename
 *           BIG WORK! mounting a directory as a drive now possible.
 *           most of functions corrected to allow this possibility
 * 26/12/96: fixed a bug in fsetdta()
 * 15/01/96: added DGETPATH() support
 * 16/01/96: fixed DSETPATH() when path doesn't exist
 *
 * REST TO EMULATE...
 *
 * 2a tgetdate
 * 2b tsetdate
 * 2c tgettime
 * 2d tsettime
 * 43 fattrib
 *
 *
*/

#include <dos.h>
#include <i86.h>
#include <stdio.h>
#include <sys\stat.h>
#include <direct.h>
#include <string.h>
#include "cpu68.h"
#include "disk.h"

#define MOUNTEDHANDLE 0x60

int IsTrappedGemdos ;
int IsTrappedPexec ;

static int func ;
MPTR dta ;
static union  REGS regs ;
static struct SREGS sregs ;
static gemdos_search_active = FALSE ;   // true if fsfirst() on mouted drive

int register_drive_to_gemdos(char *path) ;

void gemdos_dsetdrv(short drv) ;                                        //
void gemdos_dcreate(MPTR fname) ;                                       //o
void gemdos_ddelete(MPTR fname) ;                                       //o
void gemdos_fsetdta(MPTR bufdta) ;                                      //o
void gemdos_dfree(MPTR buffer, short drive) ;                           //
void gemdos_dsetpath(MPTR path) ;                                       //o
void gemdos_fcreate(MPTR fname, short attr) ;                           //o
void gemdos_fopen(MPTR fname, short mode) ;                             //o
void gemdos_fclose(short handle) ;                                      //o
void gemdos_fread(short handle, unsigned int count, MPTR filebuf) ;     //o
void gemdos_fwrite(short handle, unsigned int count, MPTR filebuf) ;    //o
void gemdos_fdelete(MPTR fname) ;                                       //o
void gemdos_fseek(signed int offset, short handle, short seekmode) ;    //o
void gemdos_dgetpath(MPTR buffer, int drive) ;                          //
void gemdos_pexec(short mode, MPTR prg, MPTR cmdl, MPTR envp) ;         //o
void gemdos_fsfirst(MPTR fname, short attr) ;                           //o
void gemdos_fsnext(void) ;                                              //o
void gemdos_frename(MPTR oldname, MPTR newname) ;                       //
void gemdos_fdatime(MPTR timeptr, short handle, short flag) ;           //

extern int nb_drives ;
extern int drivebits ;
extern tdrive drives[26] ;


void init_gemdos()
{
        int i ;
        nb_drives = 2 ;

        for (i=2;i<26;i++) {
                drives[i].kind= DRIVE_NONE ;
                drives[i].handle = 0 ;
        }

}

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                           MOUNT A DIRECTORY AS A DRIVE
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
int register_drive_to_gemdos(char *path)
{
        char *pt ;
        struct find_t buffer ;

        if (!(*path &&(*(path+1)==':')&&(*(path+2)=='\\'))) {
                fprintf(stderr,"\tPath \"%s\" should be absolute, with a drive letter.\n",path) ;
                return FALSE ;
        }

        if (*(path+3)) // avoid error if c:\ stated
        if (_dos_findfirst(path,_A_SUBDIR|_A_VOLID,&buffer)) {
                fprintf(stderr,"\tCan't state path \"%s\".\n",path) ;
                return FALSE ;
        }

        drives[nb_drives].empty = FALSE ;

        drives[nb_drives].kind = DRIVE_DIR ;
        drives[nb_drives].letter = 'A'+nb_drives ;

//        drives[nb_drives].currentpath[0] = '.' ;
//        drives[nb_drives].currentpath[1] = '\\' ;
//        drives[nb_drives].currentpath[2] = 0 ;

        strcat(drives[nb_drives].currentpath,"\\") ;

        pt = &drives[nb_drives].basepath ;
        while (*path) *pt++ = *path++ ;
//        if (*(path-1)!='\\')
//                *pt++='\\' ;
        *pt = '\0' ;


        printf("- %c drive is mounted path %s\n",nb_drives+'A',drives[nb_drives].basepath) ;

        nb_drives++ ;
        drivebits = (drivebits<<1)+1 ;

        return TRUE ;

}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                       CONVERT AN ATARI MOUNTED FILENAME TO HIS PC FORM
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
void mountedname_to_pcname(char *mountedname, char *pcname)
{
        char *p2 = pcname ;
        char *p3 ;
        int thisdrive  ;

// teste si unit‚ pr‚cis‚e dedans...

        if (*(mountedname+1) == ':') {
                thisdrive = *mountedname-'A' ;
                mountedname += 2 ;      // skip letter

        } else thisdrive = current_drive ;

        p3 = &drives[thisdrive].basepath ;
        while (*p3)
                *pcname++ = *p3++ ;


        if (*mountedname != '\\') {
                p3 = &drives[thisdrive].currentpath ;
                while (*p3)
                        *pcname++ = *p3++ ;
                *pcname++ = '\\' ;
        }

        while (*mountedname)
                *pcname++ = *mountedname++ ;

        if ((*(pcname-1)=='\\')&&(*(pcname-2)!=':'))
                pcname-- ;
        *pcname = 0 ;

        pcname = p2 ;
        p3 = p2 ;
        while (*pcname!='\0') {
                if ((*pcname == '\\')&&((*(pcname+1))=='\\')) pcname++ ;
                *p3++ = *pcname++;
        }
        *p3 = 0 ;


#ifdef DEBUG
        {
        char buf[128] ;

        sprintf(buf,"base=\"%s\"   current=\"%s\"\n",drives[thisdrive].basepath,drives[thisdrive].currentpath) ;
        OUTDEBUG(buf) ;

        sprintf(buf,"\iNtErNaL tTrAnSlAtIoN \"%s\" -> \"%s\"\n",p1,p2) ;
        OUTDEBUG(buf) ;
        }
#endif

}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                    Check if file is on a mounted drive
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
int isfileonmounteddrive(char *fname)
{
#ifdef DEBUG
{
        sprintf(buf,"checking for \"%s\" while current unit is %d:\n",fname,current_drive) ;
        OUTDEBUG(buf) ;
        switch (drives[current_drive].kind) {
                case DRIVE_IMAGE : sprintf(buf,"drive %c is an Image\n",current_drive+'A') ;
                                   break ;
                case DRIVE_DIR :   sprintf(buf,"drive %c is a Mounted Directory\n",current_drive+'A') ;
                                   break ;
                case DRIVE_PCBIOS :sprintf(buf,"drive %c is PC Drive A:\n",current_drive+'A') ;
                                   break ;
                default :          sprintf(buf,"drive %c is... NOTHING!!!\n",current_drive+'A') ;
        }
        OUTDEBUG(buf) ;
}
#endif
        if (*fname && *(fname+1))
        {
                if (*(fname+1) == ':' )          // drive specified
                        if ((*fname >= 'C') && (drives[(*fname)-'A'].kind==DRIVE_DIR))
                                return TRUE ;
                        else
                                return FALSE ;
        }


        if ((current_drive >= 2) && (drives[current_drive].kind==DRIVE_DIR))
                return TRUE ;
        else
                return FALSE ;
}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                           CHDIR IN A MOUNTED DIRECTORY
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
int compress_path (char *path)
{
        char *d=path ;
        char *p=path ;
/*
                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"\tbefore compressing: %s\n",path) ;
                OUTDEBUG(b) ;}
                #endif
*/
        while (*p) {

                if (*p == '\\')
                {
                        if (strncmp(p,"\\..\\",4) == 0)
                        {
                                while (--d>=path && *d != '\\');
                                if (d<path)
                                {
  //                                      fprintf (stderr,"FATAL error in compress_path: \\..\\\n");
//                                        exit(1);
                                        return FALSE ;
                                }
                                p += 3;
                        }
                        else if (strncmp(p,"\\.\\",3) == 0)
                        {
                                p += 2;
                        }
                        else
                        {
                                while (*++p == '\\');
                                *d++ = '\\';
                        }
                }
                else *d++=*p++;
        }
        if (d != path && *(d-1) == '\\') d--;
        *d=0;
/*
                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"\tafter compressing: %s\n",path) ;
                OUTDEBUG(b) ;}
                #endif
*/
        return TRUE ;
}



// [fold]  (
int mounted_chdir(char *mountedname)
{
        int thisdrive ;

        if (*(mountedname+1) == ':') {
                thisdrive = *mountedname-'A' ;
                mountedname += 2 ;      // skip letter
        } else thisdrive = current_drive ;

        if (*mountedname == '\\') {
                strcpy(drives[thisdrive].currentpath,mountedname) ;
        }
        else {
                strcat(drives[thisdrive].currentpath,"\\") ;
                strcat(drives[thisdrive].currentpath,mountedname) ;
                strcat(drives[thisdrive].currentpath,"\\") ;
        }
        if (!compress_path(drives[thisdrive].currentpath)) return FALSE ;


                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"\tswitching to %s\n",drives[thisdrive].currentpath) ;
                OUTDEBUG(b) ;}
                #endif
        return TRUE ;
}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                            GEMDOS FUNCTIONS DISPATCHER
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

void SystemGemdos()
{
        MPTR stack = processor->A[7] ;

        IsTrappedPexec = 0 ;
        if ((read_st_long(0x84)&0xffffff) < processor->ramsize)
                return ;


        func = read_st_word(stack) ;


        switch (func) {
            case 0x0e : gemdos_dsetdrv(read_st_word(stack+2)) ;
                        break ;
            case 0x19 : gemdos_dgetdrv() ;
                        break ;
            case 0x1a : gemdos_fsetdta(read_st_long(stack+2)) ;
                        break ;
            case 0x36 : gemdos_dfree(read_st_long(stack+2),read_st_word(stack+6)) ;
                        break ;
            case 0x39 : gemdos_dcreate(read_st_long(stack+2)) ;
                        break ;
            case 0x3a : gemdos_ddelete(read_st_long(stack+2)) ;
                        break ;
            case 0x3b : gemdos_dsetpath(read_st_long(stack+2)) ;
                        break ;
            case 0x3c : gemdos_fcreate(read_st_long(stack+2), read_st_word(stack+6)) ;
                        break ;
            case 0x3d : gemdos_fopen(read_st_long(stack+2), read_st_word(stack+6)) ;
                        break ;
            case 0x3e : gemdos_fclose(read_st_word(stack+2)) ;
                        break ;
            case 0x3f : gemdos_fread(read_st_word(stack+2), read_st_long(stack+4), read_st_long(stack+8)) ;
                        break ;
            case 0x40 : gemdos_fwrite(read_st_word(stack+2), read_st_long(stack+4), read_st_long(stack+8)) ;
                        break ;
            case 0x41 : gemdos_fdelete(read_st_long(stack+2)) ;
                        break ;
            case 0x42 : gemdos_fseek(read_st_long(stack+2),  read_st_word(stack+6), read_st_word(stack+8)) ;
                        break ;
            case 0x47 : gemdos_dgetpath(read_st_long(stack+2), read_st_word(stack+6)) ;
                        break ;
            case 0x4b : gemdos_pexec(read_st_word(stack+2), read_st_long(stack+4),read_st_long(stack+8),read_st_long(stack+12)) ;
                        break ;
            case 0x4e : gemdos_fsfirst(read_st_long(stack+2),read_st_word(stack+6)) ;
                        break ;
            case 0x4f : gemdos_fsnext() ;
                        break ;
            case 0x56 : gemdos_frename(read_st_long(stack+4),read_st_long(stack+8)) ;
                        break ;
            case 0x57 : gemdos_fdatime(read_st_long(stack+2), read_st_word(stack+6), read_st_word(stack+8)) ;
                        break ;
        }
}

#ifdef DEBUG
gemdos_debug(char *text)
{
        sprintf(buf,"\n\n\t##### GEMDOS function 0x%04x trapped \n\t##### %s\n\n",func,text) ;
        OUTDEBUG(buf) ;
}
#endif

// [fold]  (
void convert_dta_size()                 // PC DTA -> ST DTA conversion
{
        MPTR dummy ;
        int i ;
        dummy = read_st_long(dta+0x1a) ;        // invert bytes order SIZE

        for (i=0;i<4;i++) {
                write_st_byte(dta+i+0x1a,dummy&0xff) ;
                dummy >>=8 ;
        }

        dummy = read_st_word(dta+0x16) ;        // idem TIME
        write_st_byte(dta+0x16,dummy&0xff) ;
        write_st_byte(dta+0x17,(dummy>>8)&0xff) ;
        dummy = read_st_word(dta+0x18) ;        // idem DATE
        write_st_byte(dta+0x18,dummy&0xff) ;
        write_st_byte(dta+0x19,(dummy>>8)&0xff) ;
}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                         GEMDOS FUNCTION 0x0E - DSETDRV
 *³
 *³  move.w #drive,-(sp)
 *³  move.w #$0e,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

void gemdos_dgetdrv()
{
        #ifdef DEBUG
        {char b[256] ;
        sprintf(b,"DGetDrv() returns %d",current_drive) ;
        gemdos_debug(b) ;}
        #endif

        processor->D[0] = current_drive ;
}

// [fold]  (
void gemdos_dsetdrv(short drv)
{
        drv&=0xff ;
                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"DSetDrv(%d)",drv) ;
                gemdos_debug(b) ;}
                #endif

        if (drives[drv].kind != DRIVE_NONE)
                current_drive = drv ;
}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                         GEMDOS FUNCTION 0x1A - FSETDTA
 *³
 *³  pea    bufdta
 *³  move.w #$1a,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 */


void gemdos_forcedta()
{
        regs.h.ah = 0x1a ;
          regs.x.edx = FP_OFF(stmem_to_pc(dta)) ;
          sregs.ds = FP_SEG(stmem_to_pc(dta)) ;

        int386x(0x21,&regs,&regs,&sregs) ;

}

// [fold]  (
void gemdos_fsetdta(MPTR bufdta)
{
                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"FsetDTA(%08x)",bufdta) ;
                gemdos_debug(b) ;}
                #endif

        dta = bufdta ; // continue for system to take effects...
        //gemdos_search_active = FALSE ;
/*
        regs.h.ah = 0x1a ;
          regs.x.edx = FP_OFF(stmem_to_pc(bufdta)) ;
          sregs.ds = FP_SEG(stmem_to_pc(bufdta)) ;

        int386x(0x21,&regs,&regs,&sregs) ;


*/
        gemdos_forcedta() ;
}

// [fold]  )


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                           GEMDOS FUNCTION 0x36 - DFREE
 *³
 *³  move.w #drive,-(sp)
 *³  pea    buffer
 *³  move.w #$36,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 */

// [fold]  (
void gemdos_dfree(MPTR buffer, short drive)
{
        if (!(((drive == 0) && (current_drive == 2))||(drive > 2)))
                return ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Dfree(%d)",drive) ;
                gemdos_debug(b) ;}
                #endif

        if (drives[drive-1].kind != DRIVE_DIR) {
                processor->D[0] = -46 ;//invalid unit
                return ;
        }


        if (drive==0) drive = drives[current_drive].basepath[0] ;
                else  drive = drives[drive-1].basepath[0] ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"drive=%c",drive) ;
                gemdos_debug(b) ;}
                #endif



        drive = (drive|0x20)-'a'+1 ;

        regs.h.ah = 0x36 ;
        regs.x.edx = drive ;
        int386(0x21,&regs,&regs) ;

        if ((regs.w.cflag & INTR_CF)==0)
                        processor->D[0] = 0 ;
                else
                        processor->D[0] = -(regs.w.ax+31);


        write_st_long(buffer,regs.w.bx) ;    // available clusters
        write_st_long(buffer+4,regs.w.dx) ;  // total  clusters
        write_st_long(buffer+8,regs.w.cx) ;  // bytes per cluster
        write_st_long(buffer+12,regs.w.ax) ; // physical sectors

        IsTrappedGemdos = TRUE ;
}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                         GEMDOS FUNCTION 0x39 - DCREATE
 *³
 *³  pea    path
 *³  move.w #$39,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 */

// [fold]  [
void gemdos_dcreate(MPTR fname)
{
        char *string ;
        char pcfilename[128] ;
        string = (char *)stmem_to_pc(fname) ;

        if (!isfileonmounteddrive(string)) return ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Dcreate('%s')",string) ;
                gemdos_debug(b) ;}
                #endif

        mountedname_to_pcname(string,pcfilename) ;

        regs.h.ah = 0x39 ;
        regs.x.edx = FP_OFF(pcfilename) ;
        sregs.ds = FP_SEG(pcfilename) ;
        int386x(0x21,&regs,&regs,&sregs) ;

        if ((regs.w.cflag & INTR_CF)==0)
                        processor->D[0] = 0 ;
                else
                        processor->D[0] = -(regs.w.ax+31);

        IsTrappedGemdos = TRUE ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                         GEMDOS FUNCTION 0x3A - DDELETE
 *³
 *³  pea    path
 *³  move.w #$3a,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
void gemdos_ddelete(MPTR fname)
{
        char *string ;
        char pcfilename[128] ;
        string = (char *)stmem_to_pc(fname) ;

        if (!isfileonmounteddrive(string)) return ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Ddelete('%s')",string) ;
                gemdos_debug(b) ;}
                #endif

        mountedname_to_pcname(string,pcfilename) ;

        regs.h.ah = 0x3a ;
        regs.x.edx = FP_OFF(pcfilename) ;
        sregs.ds = FP_SEG(pcfilename) ;
        int386x(0x21,&regs,&regs,&sregs) ;

        if ((regs.w.cflag & INTR_CF)==0)
                        processor->D[0] = 0 ;
                else
                        processor->D[0] = -(regs.w.ax+31);

        convert_dta_size() ;
        IsTrappedGemdos = TRUE ;
}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                        GEMDOS FUNCTION 0x3B - DSETPATH
 *³
 *³  pea    path
 *³  move.w #$3b,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
void gemdos_dsetpath(MPTR path)
{
        char *string ;
        char pcfilename[128] ;
        char dummy[128] ;
        struct stat buf ;

        string = (char *)stmem_to_pc(path) ;

        IsTrappedGemdos = isfileonmounteddrive(string) ;
        if (!IsTrappedGemdos) return ;

        mountedname_to_pcname(string, pcfilename) ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"DsetPath('%s') [%s]",string,pcfilename) ;
                gemdos_debug(b) ;}
                #endif

        regs.h.ah = 0x1a ;
        regs.x.edx = FP_OFF(dummy) ;
        sregs.ds = FP_SEG(dummy) ;
        int386x(0x21,&regs,&regs,&sregs) ;

        if ((stat(pcfilename,&buf)<0) && !S_ISDIR(buf.st_mode)) {

        regs.h.ah = 0x1a ;
        regs.x.edx = FP_OFF(stmem_to_pc(dta)) ;
        sregs.ds = FP_SEG(stmem_to_pc(dta)) ;
        int386x(0x21,&regs,&regs,&sregs) ;

                processor->D[0] = 0xffffffde ;
                return ;
        }

        regs.h.ah = 0x1a ;
        regs.x.edx = FP_OFF(stmem_to_pc(dta)) ;
        sregs.ds = FP_SEG(stmem_to_pc(dta)) ;
        int386x(0x21,&regs,&regs,&sregs) ;

        if (mounted_chdir(string))
                processor->D[0] = 0 ;
        else    processor->D[0] = 0xffffffff ;

}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                         GEMDOS FUNCTION 0x3C - FCREATE
 *³
 *³  move.w #ATTRIB,-(sp)
 *³  pea    fname
 *³  move.w #$3c,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
void gemdos_fcreate(MPTR fname, short attr)
{
        char *string ;
        char pcfilename[128] ;
        string = (char *)stmem_to_pc(fname) ;

        if (!isfileonmounteddrive(string)) return ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Fcreate('%s',%d)",string,attr) ;
                gemdos_debug(b) ;}
                #endif

        mountedname_to_pcname(string,pcfilename) ;

        regs.h.ah = 0x3c ;
        regs.w.cx = attr ;
        regs.x.edx = FP_OFF(pcfilename) ;
        sregs.ds = FP_SEG(pcfilename) ;
        int386x(0x21,&regs,&regs,&sregs) ;

        if ((regs.w.cflag & INTR_CF)==0)
                        processor->D[0] = MOUNTEDHANDLE + regs.w.ax ;
                else                            // else...
                        processor->D[0] = -(regs.w.ax+31);

        IsTrappedGemdos = TRUE ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                           GEMDOS FUNCTION 0x3D - FOPEN
 *³
 *³  move.w #mode,-(sp)
 *³  pea    fname
 *³  move.w #$3d,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
void gemdos_fopen(MPTR fname, short mode)
{
        char pcfilename[128] ;
        char *string ;
        string = (char *)stmem_to_pc(fname) ;

        if (!isfileonmounteddrive(string)) return ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Fopen('%s',%d)",string,mode) ;
                gemdos_debug(b) ;}
                #endif

        mountedname_to_pcname(string, pcfilename) ;

        regs.h.ah = 0x3d ;
        regs.h.al = mode ;
        regs.x.edx = FP_OFF(pcfilename) ;
        sregs.ds = FP_SEG(pcfilename) ;
        int386x(0x21,&regs,&regs,&sregs) ;

        if ((regs.w.cflag & INTR_CF)==0)        // no error, so return handle
                        processor->D[0] = MOUNTEDHANDLE + regs.w.ax ;
                else                            // else...
                        processor->D[0] = -(regs.w.ax+31);

        IsTrappedGemdos = TRUE ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                          GEMDOS FUNCTION 0x3E - FCLOSE
 *³
 *³  move.w fhandle,-(sp)
 *³  move.w #$3e,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
void gemdos_fclose(short handle)
{
       if (handle < MOUNTEDHANDLE) return ;
       IsTrappedGemdos = TRUE ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Fclose(%d)",handle) ;
                gemdos_debug(b) ;}
                #endif

       regs.h.ah = 0x3e ;
       regs.x.ebx = handle-MOUNTEDHANDLE ;
       int386(0x21,&regs,&regs) ;
       if ((regs.w.cflag & INTR_CF)==0)
                processor->D[0] = 0 ;
       else
                processor->D[0] = -(regs.w.ax+31);

}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                           GEMDOS FUNCTION 0x3F - FREAD
 *³
 *³  pea    buff
 *³  move.w #count,-(sp)
 *³  move.w handle,-(sp)
 *³  move.w #$3f,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
void gemdos_fread(short handle, unsigned int count, MPTR filebuf)
{
        char *filebuffer = (char *)stmem_to_pc(filebuf) ;

       if (handle < MOUNTEDHANDLE) return ;
        IsTrappedGemdos = TRUE ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Fread(%d,%x,%08x)",handle, count, filebuf) ;
                gemdos_debug(b) ;}
                #endif

        disk_activity(TRUE) ;

        regs.h.ah = 0x3f ;
        regs.x.ebx = handle-MOUNTEDHANDLE ;
        regs.x.ecx = count ;
        regs.x.edx = FP_OFF(filebuffer) ;
        sregs.ds = FP_SEG(filebuffer) ;
        int386x(0x21,&regs,&regs,&sregs) ;

        if ((regs.w.cflag & INTR_CF)==0)  // no error
                processor->D[0] = regs.x.eax ;
        else
                processor->D[0] = -(regs.w.ax+31) ;

        disk_activity(FALSE) ;

}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                          GEMDOS FUNCTION 0x40 - FWRITE
 *³
 *³  pea    buff
 *³  move.w #count,-(sp)
 *³  move.w handle,-(sp)
 *³  move.w #$40,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
void gemdos_fwrite(short handle, unsigned int count, MPTR filebuf)
{
        char *filebuffer = (char *)stmem_to_pc(filebuf) ;


       if (handle < MOUNTEDHANDLE) return ;
        IsTrappedGemdos = TRUE ;

        disk_activity(TRUE) ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Fwrite(%d,%x,%08x)",handle, count, filebuf) ;
                gemdos_debug(b) ;}
                #endif


        regs.h.ah = 0x40 ;
        regs.x.ebx = handle-MOUNTEDHANDLE ;
        regs.x.ecx = count ;
        regs.x.edx = FP_OFF(filebuffer) ;
        sregs.ds = FP_SEG(filebuffer) ;
        int386x(0x21,&regs,&regs,&sregs) ;

        if ((regs.w.cflag & INTR_CF)==0)  // no error
                processor->D[0] = regs.x.eax ;
        else
                processor->D[0] = -(regs.w.ax+31) ;

        disk_activity(FALSE) ;

}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                         GEMDOS FUNCTION 0x41 - FDELETE
 *³
 *³  pea    fname
 *³  move.w #$41,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
void gemdos_fdelete(MPTR fname)
{
        char *string ;
        char pcfilename[128] ;
        string = (char *)stmem_to_pc(fname) ;

        if (!isfileonmounteddrive(string)) return ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Fdelete('%s')",string) ;
                gemdos_debug(b) ;}
                #endif

        mountedname_to_pcname(string, pcfilename) ;

        regs.h.ah = 0x41 ;
        regs.x.edx = FP_OFF(pcfilename) ;
        sregs.ds = FP_SEG(pcfilename) ;
        int386x(0x21,&regs,&regs,&sregs) ;

        if ((regs.w.cflag & INTR_CF)==0)
                        processor->D[0] = 0 ;
                else
                        processor->D[0] = -(regs.w.ax+31);

        IsTrappedGemdos = TRUE ;
}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                           GEMDOS FUNCTION 0x42 - FSEEK
 *³
 *³  move.w #seekmode,-(sp)
 *³  move.w handle,-(sp)
 *³  move.l offset,-(sp)
 *³  move.w #$42,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  [
void gemdos_fseek(signed int offset, short handle, short seekmode)
{
       if (handle < MOUNTEDHANDLE) return ;
       IsTrappedGemdos = TRUE ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Fseek(%d,%d,%d)",offset,handle,seekmode) ;
                gemdos_debug(b) ;}
                #endif

       regs.h.ah = 0x42 ;
       regs.h.al = seekmode ;
       regs.x.ebx = handle-MOUNTEDHANDLE ;
       regs.w.cx = (offset>>16) ;
       regs.w.dx = (offset&65535) ;

       int386x(0x21,&regs,&regs, &sregs) ;
       if ((regs.w.cflag & INTR_CF)==0)
                processor->D[0] = (regs.w.dx<<16)|(regs.w.ax) ;
       else
                processor->D[0] = -(regs.w.ax+31) ;

}

// [fold]  ]

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                        GEMDOS FUNCTION 0x47 - DGETPATH
 *³
 *³  move.w #drive,-(sp)
 *³  pea    buffer
 *³  move.w #$41,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
void gemdos_dgetpath(MPTR buffer, int drive)
{
        char *string ;
        int thisdrive ;

        string=stmem_to_pc(buffer) ;

        if (drive) thisdrive = drive-1 ;        //-1 added
        else thisdrive = current_drive ;

        if ((thisdrive >= 26)||(drives[thisdrive].kind != DRIVE_DIR))
                return ;
        IsTrappedGemdos = TRUE ;

        strcpy(string,drives[thisdrive].currentpath) ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"DGetPath(0x%08x,%d)\n\t\t\"%s\"\n",buffer,drive,string) ;
                gemdos_debug(b) ;}
                #endif

        processor->D[0] = 0 ;
}

// [fold]  )


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                           GEMDOS FUNCTION 0x4B - PEXEC
 *³
 *³  pea    env
 *³  pea    cmdl
 *³  pea    prg
 *³  move.w #$4b,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
void gemdos_pexec(short mode, MPTR prg, MPTR cmdl, MPTR envp)
{
        char *string ;
        string = (char *)stmem_to_pc(prg) ;
        if (((mode!=0)&&(mode!=3))||(!isfileonmounteddrive(string))) return ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Pexec(%d,'%s',%08x,%08x)",mode,string,cmdl,envp) ;
                gemdos_debug(b) ;}
                #endif

        IsTrappedPexec = TRUE ;
}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                         GEMDOS FUNCTION 0x4E - FSFIRST
 *³
 *³  move.w attr,-(sp)
 *³  pea    fname
 *³  move.w #$4e,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
void gemdos_fsfirst(MPTR fname, short attr)
{
        char *string ;
        char pcfilename[128] ;

        string = (char *)stmem_to_pc(fname) ;
        if (isfileonmounteddrive(string))
        {
                mountedname_to_pcname(string, pcfilename) ;

                IsTrappedGemdos = TRUE ;

                regs.h.ah = 0x4e ;
                regs.w.cx = attr ;
                regs.x.edx = FP_OFF(pcfilename) ;
                sregs.ds = FP_SEG(pcfilename) ;
                int386x(0x21,&regs,&regs,&sregs) ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Fsfirst(0x%08x ('%s'),0x%x) [dta=%08x]",fname,string,attr,dta) ;
                gemdos_debug(b) ;}
                #endif

                if ((regs.w.cflag & INTR_CF)==0) {
                        processor->D[0] = 0 ;
                        convert_dta_size() ;
                }
                else {
                        processor->D[0] = -(regs.w.ax+31) ;

                        if (processor->D[0] == -49)     // no more file
                                processor->D[0] = -33 ; // -> no file!!!

                }

                gemdos_search_active = TRUE ;
        }
        else    gemdos_search_active = FALSE ;


}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                         GEMDOS FUNCTION 0x4F - FSNEXT
 *³
 *³  move.w #$4e,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
void gemdos_fsnext(void)
{
        struct find_t *fileinfo ;
        fileinfo = (struct find_t*)stmem_to_pc(dta) ;

        if (!gemdos_search_active) return ;
        IsTrappedGemdos = TRUE ;

        regs.h.ah = 0x4f ;
        int386(0x21,&regs,&regs) ;
                if ((regs.w.cflag & INTR_CF)==0) {
                        processor->D[0] = 0 ;
                        convert_dta_size() ;
                }
                else
                        processor->D[0] = -(regs.w.ax+31);

        #ifdef DEBUG
        {char b[256] ;
        sprintf(b,"Fsnext() \"%s\" (0x%x)",fileinfo->name,fileinfo->attrib) ;
        gemdos_debug(b) ;}
        #endif

}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                         GEMDOS FUNCTION 0x56 - FRENAME
 *³
 *³  pea    newname
 *³  pea    oldname
 *³  move.w #0,-(sp)
 *³  move.w #$56,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
void gemdos_frename(MPTR oldname, MPTR newname)
{
        char *pold, *pnew ;
        char oldpcfilename[128] ;
        char newpcfilename[128] ;
        pold = (char *)stmem_to_pc(oldname) ;
        pnew = (char *)stmem_to_pc(newname) ;

        if (!isfileonmounteddrive(pold)) return ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Frename(%s,%s)",pold,pnew) ;
                gemdos_debug(b) ;}
                #endif

        mountedname_to_pcname(pold,oldpcfilename) ;
        mountedname_to_pcname(pnew,newpcfilename) ;

        regs.h.ah = 0x56 ;
        regs.x.edx = FP_OFF(oldpcfilename) ;
        sregs.ds = FP_SEG(oldpcfilename) ;
        regs.x.edi = FP_OFF(newpcfilename) ;
        sregs.es = FP_SEG(newpcfilename) ;
        int386x(0x21,&regs,&regs,&sregs) ;

        if ((regs.w.cflag & INTR_CF)==0)
                        processor->D[0] = 0 ;
                else
                        processor->D[0] = -(regs.w.ax+31);

        IsTrappedGemdos = TRUE ;

}

// [fold]  )

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                         GEMDOS FUNCTION 0x57 - FDATIME
 *³
 *³  move.w flag,-(sp)
 *³  move.w handle,-(sp)
 *³  pea    timeptr
 *³  move.w #$57,-(sp)
 *³  trap   #1
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

// [fold]  (
void gemdos_fdatime(MPTR timeptr, short handle, short flag)
{
       if (handle < MOUNTEDHANDLE) return ;
       IsTrappedGemdos = TRUE ;

                #ifdef DEBUG
                {char b[256] ;
                sprintf(b,"Fdatime(%d,%d,%08x)",flag,handle,timeptr) ;
                gemdos_debug(b) ;}
                #endif


        switch(flag) {

                case 1 :
                        regs.w.ax = 0x5701 ;
                        regs.x.ebx = handle-MOUNTEDHANDLE ;
                        regs.w.cx = read_st_word(timeptr) ;
                        regs.w.dx = read_st_word(timeptr+2) ;
                        int386(0x21,&regs,&regs) ;
                        break ;
                 case 0 :

                        regs.w.ax = 0x5700 ;
                        regs.x.ebx = handle-MOUNTEDHANDLE ;
                        int386(0x21,&regs,&regs) ;
                        write_st_word(timeptr,regs.w.cx) ;
                        write_st_word(timeptr+2,regs.w.dx) ;
                        break ;

//                default:
//                        processor->D[0] = -32 ;   // incorrect function call
//                        return ;
       }
/*
       if ((regs.w.cflag & INTR_CF)==0)
                processor->D[0] = 0 ;
       else
                processor->D[0] = -(regs.w.ax+31);
*/
}

// [fold]  )

// [fold]  24
