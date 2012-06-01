/*
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³ ST Disk Image MAKER                                                      ³
³                                                                          ³
³       20/12/96  Started to rewrite all                                   ³
³       25/12/96  Added sector by sector read method (for broken disks)    ³
³       26/12/96  Added BLANK command to make new empty images             ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
*/

#include <stdio.h>
#include <i86.h>

#define MAXSECTORS 18
#define MAXRETRIES 10

#define TRUE    1
#define FALSE   0

#define COMMAND_NONE    0
#define COMMAND_READ    1
#define COMMAND_BLANK   2
#define COMMAND_USAGE   3
#define COMMAND_QUIT    4

#define OPT_NONE        0
#define OPT_NAME        1
#define OPT_READ        2
#define OPT_BLANK       3
#define OPT_AUTO        4
#define OPT_SIDE        5
#define OPT_TRACK       6
#define OPT_SECTOR      7
#define OPT_USAGE       8
#define OPT_SLOW        9
#define OPT_HEAD2      10

typedef unsigned int ULONG ;
typedef unsigned short UWORD ;

struct DOSMEM {
        UWORD   realmode_segment ;
        UWORD   pmode_selector ;
        ULONG   linear_base ;
} ;

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

struct OPT {
        char    *optname ;
        int     isparam ;
        int     optid ;
} ;


/**************************************************** Global Variables ***/

int     command = COMMAND_NONE ;        // specified command
int     autodetect = TRUE ;             // must autodetect ?
int     slow = FALSE ;
int     side = 2 ;                      // default is 2 sides
int     track = 80 ;                    // default is 80 tracks (0-79)
int     sector = 9 ;                    // default is 9 sectors
int     disksize = 2*80*9*512 ;
int     totalsectors = 2*80*9 ;
int     head2 = 0 ;
char    *ptsector ;
int     nberrors = 0 ;
char    imagename[128] = "DISK.ST" ;    // default image name

struct OPT optlist[] = {{"name",1,OPT_NAME},            // valid options
                        {"read",0,OPT_READ},
                        {"blank",0,OPT_BLANK},
                        {"auto",0,OPT_AUTO},
                        {"slow",0,OPT_SLOW},
                        {"side",1,OPT_SIDE},
                        {"track",1,OPT_TRACK},
                        {"sector",1,OPT_SECTOR},
                        {"help",0,OPT_USAGE},
                        {"head2",0,OPT_HEAD2},
                        {"h",0,OPT_USAGE},
                        {"?",0,OPT_USAGE},
                        {"",0,OPT_NONE}
} ;

char    param[128] ;                    // current parameter
struct  DOSMEM lowmem ;                 // lowmem area for BIOS I/O
struct  RMREGS rmregs ;                 // Real mode registers for DPMI 0x300
struct  SREGS sregs ;
union   REGS regs ;


// [fold]  [
int allocdosmem(int paragraphs, struct DOSMEM *dosmem)
{
        union REGS regs;
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

// [fold]  ]

// [fold]  [
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
}

// [fold]  ]

// [fold]  [
int fileexists(char *name)
{
        FILE *f ;
        f = fopen(name,"rb") ;
        if (f != NULL) fclose(f) ;
        return (f!=NULL) ;
}

// [fold]  ]

// [fold]  [
void display_usage()
{
        printf("\nIMAGE [options]\n") ;
        printf("Valid options are:\n") ;
        printf("        /name       give the name of image (default is DIST.ST)\n") ;
        printf("        /read       create an image from disk (A:)\n") ;
        printf("        /blank      create a blank image\n") ;
        printf("        /auto       try to autodetect disk parameters (override)\n") ;
        printf("        /slow       read each sectors (not full track)\n") ;
        printf("                    use it on broken disks to minimize errors\n") ;
        printf("        /side n     specify side number\n") ;
        printf("        /track n    specify track number\n") ;
        printf("        /sector n   specify sector bumber\n") ;
        printf("        /head2      force reading side 2 of the disk.\n") ;
        printf("        /[h(elp)|?] this reminder\n") ;
        printf("\nA few examples:\n\n") ;
        printf("IMAGE /blank /name new.st         : create a new (720Kb) formated Image\n") ;
        printf("IMAGE /read /auto /name mydisk.st : create MYDISK.ST from ST disk in A:\n\n") ;
}

// [fold]  ]


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

// [fold]  [
void parse_commandline(int argc,char **argv)
{
        int     opt ;

        while  (opt = parse_arg(argc, argv)) {
                switch(opt) {
                        case OPT_NONE : return ;

                        case OPT_NAME : strcpy(imagename,param) ;
                                        break ;
                        case OPT_READ : command = COMMAND_READ ;
                                        break ;
                        case OPT_BLANK: command = COMMAND_BLANK ;
                                        break ;
                        case OPT_AUTO:  autodetect = TRUE ;
                                        break ;
                        case OPT_SLOW:  slow = TRUE ;
                                        break ;
                        case OPT_SIDE:  side = atoi(param) ;
                                        autodetect = FALSE ;
                                        break ;
                        case OPT_TRACK: track = atoi(param) ;
                                        autodetect = FALSE ;
                                        break ;
                        case OPT_SECTOR:sector = atoi(param) ;
                                        autodetect = FALSE ;
                                        break ;
                        case OPT_USAGE: command = COMMAND_USAGE ;
                                        break ;
                        case OPT_HEAD2: head2 = TRUE ;
                                        break ;
                }
        }

        if ((command == COMMAND_READ)&&((side<1)||(side>2)||
                                        (track<1)||(track>82)||
                                        (sector<1)||(sector>MAXSECTORS))) {
                command = COMMAND_QUIT ;
                printf("Invalid specified disk format\n") ;
        }
}

// [fold]  ]

// [fold]  [
int read_sector(int head, int track, int sector)
{
        int i ;
        int status = -1 ;
        int retry = 0 ;

        while ((status != 0)&&(retry++<MAXRETRIES)) {

                head &= 0xff ;
                track &= 0xff ;
                sector &= 0xff ;

                rmregs.ss = 0 ;
                rmregs.sp = 0 ;
                rmregs.eax = 0x201 ;         // ah = 2, READ SECTORS, al = nb
                rmregs.edx = head<<8 ;          // dh = head
                rmregs.ecx = (track<<8)|sector ;// ch = track, cl = sector

                rmregs.es = lowmem.realmode_segment ;
                rmregs.ebx = 0 ;

                regs.x.eax = 0x300 ;     // DPMI 0x300, call real mode int
                regs.x.ebx = 0x13 ;      // DISK BIO
                regs.x.ecx = 0 ;         // Stack
                sregs.es = FP_SEG(&rmregs) ;
                regs.x.edi = FP_OFF(&rmregs );
                int386x(0x31,&regs,&regs,&sregs) ;

                if (rmregs.flags&1) status = rmregs.eax >> 8 ;
                        else status = 0 ;

/*                if (status == 0x80) {
                        printf("No disk in drive                                                         \n") ;
                        exit(4) ;
                }
*/
                if (retry>1) printf("Error 0x%02x sector %d, track %d, head %d - retrying %d of %d.%c",status,sector,track,head,retry,MAXRETRIES,13) ;
                fflush(stdout) ;
        }

        printf("%c                                                            %c",13,13) ;

        if (status) {
                for (i=0;i<512;i++) ptsector[i] = 0 ;
                nberrors++ ;
        }

        return (!status) ;
}

// [fold]  ]

// [fold]  [
int read_sectors(int head, int track, int nb)
{
        int i ;
        int status = -1 ;
        int retry = 0 ;

        while ((status != 0)&&(retry++<MAXRETRIES)) {

                head &= 0xff ;
                track &= 0xff ;

                rmregs.ss = 0 ;
                rmregs.sp = 0 ;
                rmregs.eax = 0x200|nb ;         // ah = 2, READ SECTORS, al = nb
                rmregs.edx = head<<8 ;          // dh = head
                rmregs.ecx = (track<<8)|1 ;     // ch = track, cl = sector

                rmregs.es = lowmem.realmode_segment ;
                rmregs.ebx = 0 ;

                regs.x.eax = 0x300 ;     // DPMI 0x300, call real mode int
                regs.x.ebx = 0x13 ;      // DISK BIO
                regs.x.ecx = 0 ;         // Stack
                sregs.es = FP_SEG(&rmregs) ;
                regs.x.edi = FP_OFF(&rmregs );
                int386x(0x31,&regs,&regs,&sregs) ;

                if (rmregs.flags&1) status = rmregs.eax >> 8 ;
                        else status = 0 ;
/*
                if (status == 0x80) {
                        printf("No disk in drive                                                         \n") ;
                        exit(4) ;
                }
*/
                if (retry>1) printf("Error 0x%02x track %d, head %d - retrying %d of %d.%c",status,track,head,retry,MAXRETRIES,13) ;
                fflush(stdout) ;
        }

        printf("%c                                                             %c",13,13) ;

        if (status) {
                for (i=0;i<512*nb;i++) ptsector[i] = 0 ;
                nberrors += nb ;
        }

        return (!status) ;
}

// [fold]  ]

// [fold]  [
void autodetect_disk(int head)
{
        int sectsize ;
        char *b=ptsector ;

        printf("disk format autodection...\n\n") ;
        if (!read_sector(head,0,1)) {
                printf("Can't read Boot sector, use default values...\n\n") ;
                return ;
        }

        sectsize=b[0xb]+(b[0xc]<<8) ;
        sector = b[0x18]+(b[0x19]<<8) ;
        side = b[0x1a]+(b[0x1b]<<8) ;
        totalsectors = b[0x13]+(b[0x14]<<8) ;
        if ((side != 0)&&(sector!=0))
                track = totalsectors/(sector*side) ;
        else    track = 0 ;

        if ((sector > 18)||(side>2)||(track>99)) {
                printf("Boot sector informations are completly bogus, use default values...\n\n") ;
                sector = 9 ;
                side = 2 ;
                track = 80 ;
        }

}

// [fold]  ]

// [fold]  [
void read_image(void)
{
        int c ;
        int trk,sect,hd ;
        int nb = 0 ;
        int firstside = 0 ;
        FILE *f ;

//------------------------------------------ alloc low mem area for BIOS I/O

        if (allocdosmem((512*MAXSECTORS+0x10000)>>4,&lowmem)) {
                lowmem.realmode_segment = (lowmem.realmode_segment+0x1000)&0xf000 ;
                lowmem.linear_base = (lowmem.linear_base+0x10000)&0xffff0000 ;
        } else {
                printf("Unable to allocate low mem area\n") ;
                exit(2) ;
        }


        if (head2) firstside = 1 ;

        ptsector=lowmem.linear_base ;
        if (autodetect) autodetect_disk(firstside) ;

        if (head2) side = 2 ;


        totalsectors = side*sector*track ;
        disksize = 512*totalsectors ;
        printf("DISK IS %d Kb  -  SIDE:%d  TRACKS:%d  SECTORS:%d\n\n",disksize>>10,side,track,sector) ;

//------------------------------------------ test if file exists

        if (fileexists(imagename)) {
                printf("image file \"%s\" already exists. process anyway (y/n)?\n",imagename) ;
                c=getch()|0x20 ;
                while ((c!='y')&&(c!='n'))
                        c=getch()|0x20 ;
                if (c!='y') exit(1) ;
        }

        printf("Creating image file \"%s\".\n\n",imagename) ;

//------------------------------------------ read disk

        f = fopen(imagename,"wb") ;
        if (f == NULL) {
                printf("Error opening file \"%s\".\n",imagename) ;
                fflush(stdout) ;
                exit(3) ;
        }

        for (trk=0;trk<track;trk++)
        for (hd=firstside;hd<side;hd++) {

                if (slow)
                        for (sect=1;sect<=sector;sect++) {
                                printf("%cProgression: %d%% - SIDE %d  TRACK %d  SECTOR %d %c",13,(100*nb)/totalsectors,hd,trk,sect,13) ;
                                fflush(stdout) ;
                                read_sector(hd,trk,sect) ;
                                fwrite(ptsector,512,1,f) ;
                                nb++ ;
                        }
                else {
                                printf("%cProgression: %d%% - SIDE %d  TRACK %d %c",13,(100*nb)/totalsectors,hd,trk,13) ;
                                fflush(stdout) ;
                                read_sectors(hd,trk,sector) ;
                                fwrite(ptsector,512,sector,f) ;
                                nb+=sector ;



                }

        }

        printf("%c                                                        %c",13,13) ;
        if (nberrors)
                printf("%d sectors couldn't have been read.\n",nberrors) ;
        else
                printf("No errors.\n") ;
        fclose(f) ;
}

// [fold]  ]

// [fold]  (
void blank_image(void)
{
        int i ;
        int nb = 0;
        char b[512] ;
        int trk ;
        int sect ;
        int hd ;
        char c ;
        FILE *f ;

        totalsectors = side*sector*track ;
        disksize = 512*totalsectors ;
        printf("DISK IS %d Kb  -  SIDE:%d  TRACKS:%d  SECTORS:%d\n\n",disksize>>10,side,track,sector) ;

//------------------------------------------ test if file exists

        if (fileexists(imagename)) {
                printf("image file \"%s\" already exists. process anyway (y/n)?\n",imagename) ;
                c=getch()|0x20 ;
                while ((c!='y')&&(c!='n'))
                        c=getch()|0x20 ;
                if (c!='y') exit(1) ;
        }

        printf("Formating image file \"%s\".\n\n",imagename) ;

        f = fopen(imagename,"wb") ;
        if (f == NULL) {
                printf("Error opening file \"%s\".\n",imagename) ;
                fflush(stdout) ;
                exit(3) ;
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
                printf("%cProgression: %d%% - SIDE %d  TRACK %d %c",13,(100*nb)/totalsectors,hd,trk,13) ;
                fflush(stdout) ;
                fwrite(b,512,1,f) ;
                if (nb==0)
                        for (i=0;i<512;i++)
                                b[i] = 0 ;
                nb++ ;
          }

        fclose(f) ;
}

// [fold]  )

void main(int argc,char **argv)
{
        memset(&sregs,0,sizeof(sregs)) ;
        init_screen_50() ;
        printf("ST Disk Image Reader v0.31\n\n") ;
        parse_commandline(argc-1,argv) ;
        switch(command) {
                case COMMAND_NONE : printf("You must specify option READ or BLANK\n") ;
                case COMMAND_USAGE: display_usage() ;
                                    break ;
                case COMMAND_READ : read_image() ;
                                    break ;
                case COMMAND_BLANK: blank_image() ;
                                    break ;
        }
}




// [fold]  11
