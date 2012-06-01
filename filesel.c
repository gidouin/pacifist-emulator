#include <stdlib.h>
#include <stdio.h>
#include <i86.h>
#include <direct.h>
#include <string.h>
#include <fcntl.h>
#include <io.h>
#include <dos.h>
#include <conio.h>
#include <ctype.h>
#include "disk.h"
#include "cpu68.h"
#include "kb.h"

#define FALSE 0
#define TRUE 1

#define MAXITEMS 600

#define ITEM_FILE       0
#define ITEM_DIR        1
#define ITEM_LETTER     2
#define ITEM_EMPTY      3
#define ITEM_ZIP        4
#define ITEM_PCDRIVE    5
#define ITEM_RAR        6

#define WITHIN_NOTHING  0
#define WITHIN_ZIP      1
#define WITHIN_RAR      2

typedef struct  {
        int     kind ;
        int     size ;
        char    name[16] ;
} item ;

static item    items[MAXITEMS] ;
static int     nb_items ;

static char thispath[256] ;
static char b[256] ;

static void print(int x, int y, int col, char *text)
{
        short *screen = (short *)(0xb8000+x*2+y*160) ;
        while (*text) {
                if (*text == 'æ') {
                        text++ ;
                        col = col&0xf0 | (*text++)-'A' ;
                }
                *screen++ = (col<<8)+(*text++) ;
        }
}

static int scan_fixeddrives()
{
        int i,mask ;
        union REGS regs ;

        mask = 0 ;
        for (i=26;i>0;i--) {
                regs.h.ah = 0x44 ;
                regs.h.al = 9;
                regs.x.ebx = i ;
                int386(0x21,&regs,&regs) ;
                mask<<=1 ;
                if ((!regs.w.cflag&1)/*&&(regs.w.ax==1)*/)
                        mask |= 1 ;
        }
        mask&=0xfffffffc ;
        return mask ;
}

int withinselector = 0 ;
static int first ;
static int current ;
static int selected_unit = 0;
static int withinarchive ;
static char curdirinarc[256] ;
static char archivename[256] ;

static short savescreen[80*50] ;


void fileselector_reset(void)
{
        if (withinselector)
                print(26,24,0x4f,"   Atari ST restarted   ") ;
}

static int  initialdrive ;
static int  fixeddrives ;

static char initialpaths[26][256] ;
static char currentpaths[26][256] ;
static int currentdrive ;

void set_unit(int u)
{
        union REGS regs ;
        regs.h.ah = 0x0e ;
        regs.x.edx = u ;
        int386(0x21,&regs,&regs) ;
}

void init_fileselector(void)
{
        union REGS regs ;
        int i,m ;
        fixeddrives = scan_fixeddrives() ;
        regs.h.ah = 0x19 ;
        int386(0x21,&regs,&regs) ;
        initialdrive = regs.h.al ;      // drive at start
        currentdrive = initialdrive ;

        for (i=0,m=fixeddrives;i<26;i++,m>>=1)
         if (m&1) {
                set_unit(i) ;
                getcwd(initialpaths[i],256) ;
                strcpy(currentpaths[i],initialpaths[i]) ;
        }
        set_unit(initialdrive) ;
}

void deinit_fileselector(void)
{
        int i,m ;
        for (i=0,m=fixeddrives;i<26;i++,m>>=1)
         if (m&1) {
                set_unit(i) ;
                chdir(initialpaths[i]) ;
        }
        set_unit(initialdrive) ;
}

void enter_fileselector(void)
{
        int i,m ;
        for (i=0,m=fixeddrives;i<26;i++,m>>=1)
         if (m&1) {
                set_unit(i) ;
                chdir(currentpaths[i]) ;
        }
        set_unit(currentdrive) ;
}

void exit_fileselector(void)
{
        union REGS regs ;
        int i,m ;

        regs.h.ah = 0x19 ;
        int386(0x21,&regs,&regs) ;
        currentdrive = regs.h.al ;

        for (i=0,m=fixeddrives;i<26;i++,m>>=1)
         if (m&1) {
                set_unit(i) ;
                getcwd(currentpaths[i],256) ;
                chdir(initialpaths[i]) ;
        }

        set_unit(initialdrive) ;
}



void display_fileselector()
{
        int i ;
        item *pitem ;
//        char b[128] ;
        int col1,col2 ;

        pitem = &items[first] ;
        for (i=0;i<25;i++) {
                if (i+first < nb_items)
                 switch(pitem->kind) {
                      case ITEM_FILE :  sprintf(b," %-13s %6d Kb ",pitem->name,pitem->size>>10) ;
                                       col1 = 15 ; col2 = 0x1f ;
                                       break ;
                      case ITEM_DIR  :  sprintf(b," %-13s       DIR ",pitem->name) ;
                                       col1 = 7 ; col2 = 0x17 ;
                                       break ;
                      case ITEM_ZIP :
                      case ITEM_RAR :  sprintf(b," %-13s %6d Kb ",pitem->name,pitem->size>>10) ;
                                       col1 = 9 ; col2 = 0x19 ;
                                       break ;
                      case ITEM_LETTER: sprintf(b," [%s]                    ",(pitem->name)) ;
                                       col1 = 15 ; col2 = 0x1f ;
                                       break ;
                      case ITEM_EMPTY:  sprintf(b,"******* eject disk ******") ;
                                       col1 = 10 ; col2 = 0x1a ;
                                       break ;
                      case ITEM_PCDRIVE:sprintf(b," [ST Disk in PC Drive A]") ;
                                       col1 = 14 ; col2 = 0x1e ;
                                       break ;
                 }
                else
                        strcpy(b,"                         ") ;

                if (i+first==current)
                        print(0,i,col2,b) ;
                else
                        print(0,i,col1,b) ;
                pitem++ ;
        }

        print(26,1,15,"                                              ") ;

        if (withinarchive!=WITHIN_NOTHING)
         print(26,1,15,curdirinarc) ;       // current PATH in ZIPFILE
        else
         print(26,1,15,thispath) ;       // current PATH


        if (selected_unit==0) {
                col1 = 0x2f ;
                col2 = 15 ;
        } else {
                col1 = 15 ;
                col2 = 0x2f ;
        }

        print(26,3,col1," ST Drive A:                                          ") ;
        print(26,11,col2," ST Drive B:                                          ") ;

        print(26,24,13,"                                        ") ;
        print(26,4,0,"                                   ") ;
        print(28,6,0,"                                   ") ;
        print(28,7,0,"                                   ") ;
        print(28,8,0,"                                   ") ;
        print(26,12,0,"                                   ") ;
        print(28,14,0,"                                   ") ;
        print(28,15,0,"                                   ") ;
        print(28,16,0,"                                   ") ;

        if (drives[0].empty)
                strcpy(b,"[no disk in drive]") ;
        else    strcpy(b,drives[0].basepath) ;
        print(28,4,7,b) ;


        if (!drives[0].empty) {
                sprintf(b,"Heads:%2d  Tracks:%3d  Sectors:%3d",drives[0].side,drives[0].track,drives[0].sector) ;
                print(28,6,10,b) ;
                print(28,7,7,drives[0].ro_file?
                       "Disk Image is Read/Write":"Disk Image is Read Only") ;
                print(28,8,7,drives[0].write_protected?
                        "Drive is Write Protected    ":"Disk is not Write Protected") ;
        }


        if (drives[1].empty)
                strcpy(b,"[no disk in drive]") ;
        else    strcpy(b,drives[1].basepath) ;
        print(28,12,7,b) ;


        if (!drives[1].empty) {
                sprintf(b,"Heads:%2d  Tracks:%3d  Sectors:%3d",drives[1].side,drives[1].track,drives[1].sector) ;
                print(28,14,10,b) ;
                print(28,15,7,drives[1].ro_file?
                        "Disk Image is Read/Write":"Disk Image is Read Only") ;
                print(28,16,7,drives[1].write_protected?
                        "Drive is Write Protected    ":"Disk is not Write Protected") ;
        }

        if (bootexec)
                print(68,23,0x1f,"Keep BOOT") ;
           else print(68,23,0x1f,"Skip BOOT") ;

}

static char filename[256] ;



void select_archive()
{
        tdrive *drv ;
        int file ;
        int c;

        print(26,24,0x4f,"  <processing archive>  ") ;
        if (withinarchive==WITHIN_ZIP)
                sprintf(b,"pkunzip -o %s %s%s %s >NUL:",archivename,curdirinarc,items[current].name,tempdir) ;
        else    sprintf(b,"rar e %s %s%s %s >NUL:",archivename,curdirinarc,items[current].name,tempdir) ;

        if (c=system(b)) {
                sprintf(b,"   Error %d while extracting  ",c) ;
                print(26,24,0x4f,b) ;
                return ;
        }

        sprintf(b,"%s\\%s",tempdir,items[current].name) ;
        sprintf(filename,"%s\\pcstimg%i.tmp",tempdir,selected_unit+1) ;
        remove(filename) ;
        rename(b,filename) ;

        file = open(filename,O_RDWR|O_BINARY) ;
        if (file==-1) {
                     print(26,24,0x4f,"Error opening File") ;
                     return ;
        }

        drv = &drives[selected_unit] ;
        if ((drv->kind==DRIVE_IMAGE)&&!drv->empty) close(drv->handle) ;
        drv->handle = file ;
        drv->letter = selected_unit+'A' ;
        drv->kind = DRIVE_IMAGE ;
        strcpy(&drv->basepath,items[current].name) ;
        read_disk_params(drv,FALSE) ;
        drv->empty = FALSE ;
        drv->changed = TRUE ;
        display_fileselector() ;
        sprintf(b,"  %s extracted in %c:  ",items[current].name,selected_unit+'A') ;
        print(26,24,0x4f,b) ;
}



void select_file()
{
        tdrive *drv ;
//        char b[256] ;
        int file ;

        drv = &drives[selected_unit] ;

        file = open(items[current].name,O_RDWR|O_BINARY) ;
        if (file==-1) {
                file = open(items[current].name,O_BINARY) ;
                if (file==-1) {
                        print(26,24,0x4f,"    Error opening File    ") ;
                        return ;
                }
                drv->ro_file = FALSE ;
                drv->write_protected = TRUE ;
        } else {
                drv->ro_file = TRUE ;
                drv->write_protected = FALSE ;
        }

        if ((drv->kind==DRIVE_IMAGE)&&!drv->empty) close(drv->handle) ;
        drv->handle = file ;
        drv->kind = DRIVE_IMAGE ;
        drv->letter = selected_unit+'A' ;
        strcpy(&drv->basepath,items[current].name) ;
        read_disk_params(drv,FALSE) ;
        drv->empty = FALSE ;
        drv->changed = TRUE ;
        display_fileselector() ;
        sprintf(b,"%s inserted in %c: %s",items[current].name,selected_unit+'A',
                drv->ro_file?" ":"(Read Only)") ;
        print(26,24,0x4f,b) ;
        return ;
}

struct {
        char *dp_name ;
        int dp_sides ;
        int dp_tracks ;
        int dp_sectors ;
} dp[7] = {
        "360 Kb",1,9,80,
        "720 Kb",2,9,80,
        "400 Kb",1,10,80,
        "800 Kb",2,10,80,
        "440 Kb",1,11,80,
        "880 Kb",2,11,80,
        "Custom",0,0,0
} ;


void swap_screens(int dir)
{
        short *p1 = savescreen, *p2 = (short *)0xb8000 ;
        int i ;
        for (i=0;i<80*50;i++)
                if (dir) *p1++ = *p2++;
                else *p2++ = *p1++ ;
}

static int file_exists(char *name)
{
        struct find_t dta ;
        return _dos_findfirst(name,0,&dta)?0:1 ;
}

static int readkey(void)
{
        while (!isspecialkey&&!kbhit()) ;
        if (!isspecialkey) return getch() ;
        if (kbhit()) getch() ;
        return specialkey ;
}


void create_image(void)
{
        int finito = FALSE ;
        char name[9] ;
        char fullname[13] ;
        int curpos = 0 ;
        int i,c ;
        int totalsectors,side,sector,track ;
        int trk,hd,sect,nb =0;
        char b[512] ;
        FILE *f ;

        swap_screens(TRUE) ;


/*************** SAISIE DU NOM ***************/

        name[0] = 0 ;
        while(!finito) {
                print(47,18,0xa,"Enter name: [        ]") ;
                print(60,18,0x1f,name) ;

                c = toupper(getch()) ;
                if (!isextendedkey&&(((c>='A' && c<='Z')||(c>='0' && c<='9')||(c=='_')||(c=='-')||(c=='!')))
                        && (curpos<8)) {
                        name[curpos++] = c ;
                        name[curpos] = 0 ;
                }
                else switch(c) {
                        case 0x1b :
                        case 0x0d :
                                finito = TRUE ;
                                break ;
                        case 0x8 :
                                if ((!isextendedkey)&&(curpos>0))
                                        name[--curpos] = 0 ;
                                break ;

                }
        }

        if ((c==0x1b)||(!name[0])) {
                swap_screens(FALSE) ;
                print(26,24,0x4f,"Image not created            ") ;
                return ;
        }

        sprintf(fullname,"%s.ST",name) ;
        if (file_exists(fullname)) {
                swap_screens(FALSE) ;
                print(26,24,0x4f,"Image already exists         ") ;
                return ;
        }

        for (i=0;i<7;i++) {
                sprintf(b,"³ [F%d ] Size:%2s - Side:%d Tracks:%2d Sectors:%2d ³",1+i,dp[i].dp_name,dp[i].dp_sides,dp[i].dp_tracks,dp[i].dp_sectors) ;
                print(20,i+10,0x1f,b) ;

        }
        print(20,9,0x1f,"ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Select Format  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿") ;
        print(20,17,0x1f,"ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ") ;

        finito = FALSE ;
        while (!finito)
        {
                c = readkey() ;
                if (isspecialkey) {
                        isspecialkey = FALSE ;
                        if ((c>=KEY_F1)&&(c<=KEY_F6))
                                finito = TRUE ;

                }
                if (c==0x1b) {
                        swap_screens(FALSE) ;
                        print(26,24,0x4f,"Image not created            ") ;
                        return ;
                }
        };

        side = dp[c-KEY_F1].dp_sides ;
        track = dp[c-KEY_F1].dp_tracks ;
        sector = dp[c-KEY_F1].dp_sectors ;
        totalsectors = side*sector*track ;


        f = fopen(fullname,"wb") ;
        if (f == NULL) {
                swap_screens(FALSE) ;
                print(26,24,0x4f,"Error creating file            ") ;
                return ;
        }


        for (i=0;i<512;i++) b[i] = 0 ;

        b[0x0b] = 0x00 ; b[0x0c] = 0x02 ;       // 512 bytes per sector
        b[0x0d] = 0x00 ;                        // 2 sectors per cluster
        b[0x0e] = 0x01 ; b[0x0f] = 0x00 ;       // 1 reserved sector (boot)
        b[0x10] = 0x02 ;                        // 2 FATs
        b[0x11] = 0x70 ; b[0x12] = 0x00 ;       // 112 default root dir entries
        b[0x13] = totalsectors&0xff ;
        b[0x14] = totalsectors>>8 ;             // 1440 default total sectors
        b[0x15] = 0xf8 ;                        // MEDIA DESCRIPTOR HD


        if ((side > 2)||(track > 82)||(sector > 11))
                b[0x15] = 0xf1 ; // OWN MEDIA DESCRIPTOR

        b[0x16] = 0x05 ; b[0x17] = 0x00 ;       // default 5 sectors/FAT
        b[0x18] = sector&0xff ;
        b[0x19] = sector>>8 ;                   // default 9 sectors/Track
        b[0x1a] = side&0xff ;
        b[0x1b] = side>>8 ;                     // default 2 heads
        b[0x1c] = 0x00 ; b[0x1d] = 0x00 ;       // no hiddent sectors

        for (trk=0;trk<track;trk++)
         for (hd=0;hd<side;hd++)
          for (sect=1;sect<=sector;sect++) {
                fwrite(b,512,1,f) ;
                if (nb==0)
                        for (i=0;i<512;i++)
                                b[i] = 0 ;
                nb++ ;
          }

        fclose(f) ;
        swap_screens(FALSE) ;
        scandir(".") ;
        display_fileselector() ;
        print(26,24,0x4f,"Image created            ") ;
}

void disk_selector(void)
{
        int c ;
        int uc ;
        int moved ;
        union REGS regs ;
        tdrive *drv ;
//        char b[60] ;

        withinselector = TRUE ;
        withinarchive = WITHIN_NOTHING ; // not in ZIP file at first

        regs.w.ax = 0x3 ;
        int386(0x10,&regs,&regs) ;

        enter_fileselector() ;

        scandir(".") ;

        for (c=0;c<25;c++) print(25,c,8,"³") ;
        print(25,0,8,"ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ PATH ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ") ;
        print(25,2,8,"ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ") ;
        print(25,10,8,"ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ") ;
        print(25,17,8,"ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ") ;
        print(26,18,11,"æG+ æP- æLNew Image") ;
        print(26,19,11,"æMEscape æP- æLQuit this screen     æM* æP- æLbypass boots") ;
        print(26,20,11,"æMUp,Down,Home,End,PgUp,PgDwn æP- æLNavigate in selector") ;
        print(26,21,11,"æMTab, Left, Right æP- æLChoose Drive A: or Drive B:") ;
        print(26,22,11,"æMENTER æP- æLSelect  æMSPACE æP- æLToggle Write Protection") ;
        print(26,23,11,"æM0-Z æP- æLSelect first matching filename") ;

        display_fileselector() ;


        while((c=getch())!=27) {
                moved = FALSE ;
                uc = toupper(c) ;


         if (!isextendedkey&&((uc>='0')&&(uc<='_'))) {
                int i ;
                for (i=0;(i<nb_items)&&!moved;i++)
                        if (items[i].name[0]==uc) {
                                current = i ;
                                moved = TRUE ;
                        }
         } else
         switch(c) {
                case '+' :  if (!withinarchive)
                                    create_image() ;
                            break ;
                case 0x48 : current-- ; moved = 1 ;
                            break ;
                case 0x50 : current++ ; moved = 1 ;
                            break ;
                case 0x47 : current = 0  ; moved = 1 ;
                            break ;
                case 0x4f : current = nb_items-1 ; moved = 1 ;
                            break ;
                case 0x49 : current -= 24 ; moved = 1 ;
                            break ;
                case 0x51 : current += 24 ; moved = 1 ;
                            break ;
                case 0x4b : selected_unit = 0 ; moved = 1 ;
                            break ;
                case 0x4d : selected_unit = 1 ; moved = 1 ;
                            break ;
                case 0x09 : selected_unit = 1-selected_unit ; moved = 1 ;
                            break ;
/*
                case 0x20 : drives[selected_unit].write_protected ^= 1 ; moved = 1 ;
                            break ;
*/
                case '*' :  bootexec = TRUE-bootexec ; moved = 1 ;
                            break ;
                case ' ' :  if (!drives[selected_unit].ro_file)
                                     print(26,24,0x4f,"Can't toggle               ") ;
                            else drives[selected_unit].write_protected ^= 1 ;
                            moved = 1 ;
                            break ;
                case 0x0d : switch(items[current].kind) {
                     case ITEM_DIR :
                                switch(withinarchive) {
                                  case WITHIN_ZIP:
                                     if (!scanzip(items[current].name)) scandir(".") ;
                                     break ;
                                  case WITHIN_RAR:
                                     if (!scanrar(items[current].name)) scandir(".") ;
                                     break ;
                                  case WITHIN_NOTHING:
                                     chdir(items[current].name) ;
                                     scandir(".") ;
                                     break ;
                                }
                                break ;
                     case ITEM_LETTER :
                             regs.h.ah = 0xe ;
                             regs.x.edx = items[current].name[0]-'A' ;
                             int386(0x21,&regs,&regs) ;
                             scandir(".") ;
                             break ;
                     case ITEM_FILE :
                                switch(withinarchive) {
                                  case WITHIN_ZIP:
                                  case WITHIN_RAR:
                                        select_archive() ;
                                        continue ;
                                  case WITHIN_NOTHING:
                                        select_file() ;
                                        continue ;
                                }
                                break ;
                     case ITEM_EMPTY :
                             drv = &drives[selected_unit] ;
                             if ((drv->kind==DRIVE_IMAGE)&&!drv->empty) close(drv->handle) ;
                             drv->kind = DRIVE_IMAGE ;
                             drv->empty = TRUE ;
                             drv->sector = drv->side = drv->track = 0;
                             display_fileselector() ;
                             sprintf(b,"ejected disk in drive %c:",selected_unit+'A') ;
                             print(26,24,0x4f,b) ;
                             continue ;
                             break ;
                     case ITEM_ZIP :
                             withinarchive = WITHIN_ZIP ;
                             *curdirinarc = 0 ;
                             strcpy(archivename,items[current].name) ;
                             if (!scanzip("")) {
                                     scandir(".") ;
                             }
                             break ;
                     case ITEM_RAR :
                             withinarchive = WITHIN_RAR ;
                             *curdirinarc = 0 ;
                             strcpy(archivename,items[current].name) ;
                             if (!scanrar("")) {
                                        scandir(".") ;
                             }
                             break ;
                     case ITEM_PCDRIVE:
                             drv = &drives[selected_unit] ;
                             register_pcdrive_to_system(selected_unit) ;
                             sprintf(b,"PC drive A: is now ST %c:",selected_unit+'A') ;
                             print(26,24,0x4f,b) ;
                             continue ;
                     }
                   moved = 1 ;
                   break ;
         }
                if (current<0) current = 0 ;
                if (current>nb_items-1) current = nb_items-1 ;
                if (first>current) first=current ;
                if (first+24<current) first=current-24 ;
                if (moved) display_fileselector() ;

        }

//        regs.h.ah = 0x0e ;
//        regs.x.edx = initialdrive ;
//        int386(0x21,&regs,&regs) ;
//        chdir(initialpath) ;

        exit_fileselector() ;
        withinselector = FALSE ;
}


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                              NORMAL DIRECTORY HANDLING
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

static int removed_items ;

static int cmpitem(const void *op1, const void *op2)
{
        const item *p1 = (const item *)op1 ;
        const item *p2 = (const item *)op2 ;
        return (strcmp(p1->name,p2->name)) ;
}

static void scancommon()
{
        item *pitem ;
        int ma,i ;

        first = 0 ;
        current = 0 ;
        removed_items = 0 ;
        qsort(items,nb_items,sizeof(item),cmpitem) ;
        nb_items -= removed_items ;

        pitem= &items[nb_items] ;

        ma = fixeddrives ;

        for (i=0;i<26;i++)
         if ((ma>>i)&1) {
                pitem->kind = ITEM_LETTER ;
                pitem->name[0] = i+'A' ;
                pitem->name[1] = ':' ;
                pitem->name[2] = 0 ;
                pitem++ ;
                nb_items++ ;
        }

        if (isPCDrive) {
                pitem->kind = ITEM_PCDRIVE ;
                pitem++ ; nb_items++ ;
        }

        pitem->kind = ITEM_EMPTY ;
        pitem++ ; nb_items++ ;
}


static void scandir(char *path)
{
        DIR *dirp ;
        struct dirent *direntp ;
        item *pitem ;
        char joker[256] ;

        withinarchive = WITHIN_NOTHING ;

        strcpy(joker,path) ;
        strcat(joker,"\\*.*") ;
        getcwd(thispath,256) ;

        dirp = opendir(joker) ;
        nb_items = 0 ;
        pitem = items ;

        while ((direntp = readdir(dirp))||(nb_items>MAXITEMS)) {

                if (!strcmp(dirp->d_name,".")) continue ; // skip "."
                if (dirp->d_attr&_A_SUBDIR) goto isdir ;


                if (strstr(dirp->d_name,".ZIP")) {

                        strcpy(&pitem->name,dirp->d_name) ;
                        pitem->size = dirp->d_size ;
                        pitem->kind = ITEM_ZIP ;
                        nb_items++ ;
                        pitem++ ;
                        continue ;
                }

                if (strstr(dirp->d_name,".RAR")) {

                        strcpy(&pitem->name,dirp->d_name) ;
                        pitem->size = dirp->d_size ;
                        pitem->kind = ITEM_RAR ;
                        nb_items++ ;
                        pitem++ ;
                        continue ;
                }


               if ((!strstr(dirp->d_name,".ST"))&&
                   (!strstr(dirp->d_name,".DIM"))&&
                   (!strstr(dirp->d_name,".MSA"))) continue ;
isdir:;
                strcpy(&pitem->name,dirp->d_name) ;
                pitem->size = dirp->d_size ;

                if (dirp->d_attr&_A_SUBDIR)
                        pitem->kind = ITEM_DIR ;
                else
                        pitem->kind = ITEM_FILE ;
                nb_items++ ;
                pitem++ ;
        }

        scancommon() ;
}



/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                      ZIP FILE HANDLING
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

#define lsig 0x04034b50
#define csig 0x02014b50

typedef struct {                                        // LOCAL ZIP HEADER
#pragma pack (1) ;
        long    signature ;     // Signature
        short   version ;       // version of ZIP Utility
        short   gpflag ;        // general purpose flags
        short   compress ;      // compression method
        short   time, date ;    // time & date of file
        long    crc32 ;         // crc-32
        long    csize ;         // compressed size
        long    usize ;         // uncompressed size
        short   fnamelen ;      // filename length
        short   extrafield ;    // extrafield length
} ZIP_localheader ;

typedef struct {                                        // CENTRAL ZIP HEADER
#pragma pack (1)
        long    signature ;     // signature
        short   version ;       // version of ZIP Utility
        short   vneeded ;       // version needed to extract
        char    gpflags[2] ;    // general-purpose flags
        short   compress ;      // compressions method
        short   time, date ;    // time & date of file
        long    crc32 ;         // crc-32
        long    csize ;         // compressed size
        long    usize ;         // uncompressed size
        short   fnamelen ;      // filename length
        short   extrafield ;    // extra field length
        short   fcl ;           // file comment length
        short   dns ;           // disk number start
        short   ifa ;           // internal file attributes
        char    efa[4] ;        // external file attributes
        long    roolh ;         // relative offset of local header
} ZIP_centralheader ;

static FILE *fp ;
static int  numfiles = 0 ;
static char archivedname[256] ;

int seekc() // seek to central
{
        int curpos ;
        ZIP_localheader lheader ;
        curpos = 0 ;
        fread(&lheader,sizeof(ZIP_localheader),1,fp) ;
        while (lheader.signature == lsig) {
                numfiles++ ;
                curpos = ftell(fp)+lheader.fnamelen+lheader.extrafield+lheader.csize ;
                fseek(fp,curpos,SEEK_SET) ;
                fread(&lheader,sizeof(ZIP_localheader),1,fp) ;
        }

        fseek(fp,curpos,SEEK_SET) ;
        return (lheader.signature==csig) ;
}


static int scanzip(char *dirinzip)
{
        ZIP_centralheader cheader ;
        int z = 0;
        int i ;
        char *firstslash ;
        char *name ;
        item *pitem ;

        if (!strcmp(dirinzip,"..")) {
                char *p1 = strchr(curdirinarc,'/') ; // first occurence
                char *p2 = strrchr(curdirinarc,'/') ; // last occurence
                if (!*curdirinarc) return FALSE ;

                *p2 = 0 ;
                if (p1==p2)
                        *curdirinarc = 0 ;      // root dir
                else
                        *(strrchr(curdirinarc,'/')+1) = 0 ;

        }
        else  strcat(curdirinarc,dirinzip) ;


        nb_items = 0 ;
        pitem = items ;

        pitem->kind = ITEM_DIR ;
        strcpy(pitem->name,"..") ;
        pitem++ ;
        nb_items++ ;

        fp = fopen(archivename,"rb") ;
        if (!seekc()) {
                fclose(fp) ;
                return FALSE ;
        }

        do {
                fread(&cheader,sizeof(ZIP_centralheader),1,fp) ;
                fread(archivedname,cheader.fnamelen,1,fp) ;
                archivedname[cheader.fnamelen] = 0 ;
                strupr(archivedname) ;
                if (cheader.signature!=csig) continue ;

                name = strstr(archivedname,curdirinarc) ;       // in path?
                if (name==0) goto next ;                        // no

                strcpy(name,&name[strlen(curdirinarc)]) ;       // skip path
                if (!*name) goto next ;                         // nothing?

                firstslash = strchr(name,'/') ;                 // first '/'

                if (firstslash==0) {                    // file

                        if ((!strstr(name,".ST"))&&
                            (!strstr(name,".DIM"))&&
                            (!strstr(name,".MSA"))) goto next ;

                        for (i=0;i<nb_items;i++)
                         if (!strcmp(items[i].name,name)) goto next;

                        pitem->size = cheader.usize ;
                        pitem->kind = ITEM_FILE ;
                        strncpy(pitem->name,name,12) ;
                        pitem++ ;
                        nb_items++ ;
                        goto next ;
                 }

               *(firstslash+1) = 0 ;

                if ((firstslash==&name[strlen(name)-1])||       // DIR
                    (strrchr(name,'/')==&name[strlen(name)-1])) // DIR/DIR
                {
                        for (i=0;i<nb_items;i++)
                         if (!strcmp(items[i].name,name)) goto next;

                        pitem->kind = ITEM_DIR ;
                        strncpy(pitem->name,name,12) ;
                        pitem++ ;
                        nb_items++ ;
                        goto next ;
                }



next:           fseek(fp,cheader.extrafield+cheader.fcl,SEEK_CUR) ;
        } while ((cheader.signature==csig)&&!feof(fp)&&(z!=numfiles)&&(nb_items<MAXITEMS)) ;

        fclose(fp) ;
        scancommon() ;
        return TRUE ;
}

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³                                                      RAR FILE HANDLING
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

typedef struct {
#pragma pack (1)
        long    packsize;
        long    unpacksize;
        char    HostOS ;
        long    FileCRC ;
        short   mod_time ;
        short   mod_date ;
        char    rarver ;
        char    method ;
        short   fnamesize ;
        long    attr ;
} RAR_REC ;

static int initrar()
{
        char t[12] ;
        unsigned short skip ;
        fread(t,12,1,fp) ;
        fread(&skip,2,1,fp) ;
        fread(t,6,1,fp) ;
        fseek(fp,skip-13,SEEK_CUR) ;
        return TRUE;
}


static int scanrar(char *dirinrar)
{
        item *pitem ;
        char hrar[5] ;
        char *name ;
        char *firstslash ;
        int i;
        unsigned short skip ;
        RAR_REC rar ;

        if (!strcmp(dirinrar,"..")) {
                char *p1 = strchr(curdirinarc,'/') ; // first occurence
                char *p2 = strrchr(curdirinarc,'/') ; // last occurence
                if (!*curdirinarc) return FALSE ;

                *p2 = 0 ;
                if (p1==p2)
                        *curdirinarc = 0 ;      // root dir
                else
                        *(strrchr(curdirinarc,'/')+1) = 0 ;

        }
        else  strcat(curdirinarc,dirinrar) ;

        nb_items = 0 ;
        pitem = items ;

        pitem->kind = ITEM_DIR ;
        strcpy(pitem->name,"..") ;
        pitem++ ;
        nb_items++ ;

        fp = fopen(archivename,"rb") ;
        if (!initrar()) {
                fclose(fp) ;
                return FALSE ;
        }

        do {
                fread(hrar,5,1,fp) ;
                if (hrar[2]!=0x74) goto ze_end ;//return FALSE ;
                fread(&skip,2,1,fp) ;
                fread(&rar,sizeof(rar),1,fp) ;
                fread(archivedname,rar.fnamesize,1,fp) ;
                archivedname[rar.fnamesize] = 0 ;
                strupr(archivedname) ;

                name = strstr(archivedname,curdirinarc) ;       // in path?
                if (name==0) goto next ;                        // no

                strcpy(name,&name[strlen(curdirinarc)]) ;       // skip path
                if (!*name) goto next ;                         // nothing?

                firstslash = strchr(name,'\\') ;                 // first '/'
                if (firstslash==0) {                    // file

                        if ((!strstr(name,".ST"))&&
                            (!strstr(name,".DIM"))&&
                            (!strstr(name,".MSA"))) goto next ;

                        for (i=0;i<nb_items;i++)
                         if (!strcmp(items[i].name,name)) goto next;

                        pitem->size = rar.unpacksize ;
                        pitem->kind = ITEM_FILE ;
                        strncpy(pitem->name,name,12) ;
                        pitem++ ;
                        nb_items++ ;
                        goto next ;
                 }

               *(firstslash+1) = 0 ;

                if ((firstslash==&name[strlen(name)-1])||       // DIR
                    (strrchr(name,'/')==&name[strlen(name)-1])) // DIR/DIR
                {
                        for (i=0;i<nb_items;i++)
                         if (!strcmp(items[i].name,name)) goto next;

                        pitem->kind = ITEM_DIR ;
                        strncpy(pitem->name,name,12) ;
                        pitem++ ;
                        nb_items++ ;
                        goto next ;
                }




next:
                fseek(fp,skip-(sizeof(rar)+7+rar.fnamesize),SEEK_CUR) ;
                fseek(fp,rar.packsize,SEEK_CUR) ;
        } while (!feof(fp)&&(nb_items<MAXITEMS)) ;

ze_end:
        fclose(fp) ;
        scancommon() ;
        return TRUE ;
}


