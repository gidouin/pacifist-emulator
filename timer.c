#include <dos.h>
#include <io.h>
#include <conio.h>
#include <fcntl.h>
#include <stdio.h>
#include "cpu68.h"
#include "timer.h"
#include "vbe.h"


unsigned int Cycles_Per_RasterLine = 512 ;

extern unsigned int Nb_RasterLines_Last_VBL ;
extern unsigned int Total_RasterLines ;

#define cv 313*512

static int lastcycles[50] = {cv,cv,cv,cv,cv,cv,cv,cv,cv,cv,
                                cv,cv,cv,cv,cv,cv,cv,cv,cv,cv,
                                cv,cv,cv,cv,cv,cv,cv,cv,cv,cv,
                                cv,cv,cv,cv,cv,cv,cv,cv,cv,cv,
                                cv,cv,cv,cv,cv,cv,cv,cv,cv,cv
                       } ;
static int sumcycles = 50*313*512 ;
static int currentlastcycles = 0 ;

double allcycles = 0.0 ;
double localcycles = 0.0 ;

unsigned int Cycles_Calculation = 0 ;
int stop_cycles = 0 ;

//extern int RasterLine ;

int nb_redrawn_screen = 1;
int redrawing_screen = 0 ;

unsigned int dummy ;
extern unsigned int toto ;

extern int wait_50hz ;

void PC_Timer_VBL(void)
{
#ifdef SOUND
        periodic_sound() ;
#endif
        Global_PC_VBLs++ ;
        wait_50hz++ ;

        if (!ModeST) return ;

        if (nb_joysticks_detected/*&&!JoyEmu*/) Test_PC_Joysticks() ;

//----------------------------------------------- each VBL under emulation
        wait_50hz++ ;
        nb_redrawn_screen = 0 ;
        Nb_VBLs++ ;

        if (!NativeSpeed) return ;

        processor->events_mask |= MASK_VBL ;
        RasterLine = 0 ;

        sumcycles -= lastcycles[currentlastcycles] ;
        sumcycles += Cycles_Calculation ;
        lastcycles[currentlastcycles] = Cycles_Calculation ;

        currentlastcycles++ ;
        if (currentlastcycles>=50) currentlastcycles = 0 ;


        Cycles_Per_RasterLine = sumcycles/(50*313) ;
        Cycles_Calculation = 0 ;

/*
        if (!redrawing_screen) {

        allcycles += (Nb_RasterLines_Last_VBL*Cycles_Per_RasterLine) ;

        localcycles -= lastcycles[currentlastcycles] ;
        lastcycles[currentlastcycles] = (Nb_RasterLines_Last_VBL*Cycles_Per_RasterLine) ;
        localcycles += lastcycles[currentlastcycles] ;
        if ((++currentlastcycles) == 50) {
                currentlastcycles = 0 ;

                stop_cycles = Cycles_Calculation ;

                Cycles_Calculation = 0 ;        // reset all 50 VBLs
        }


        if (Nb_RasterLines_Last_VBL > 313)
                Cycles_Per_RasterLine += 20 ;
        else
        if (Nb_RasterLines_Last_VBL < 313)
                Cycles_Per_RasterLine -= 20 ;

        Total_RasterLines += Nb_RasterLines_Last_VBL ;
        Nb_RasterLines_Last_VBL = 0 ;
        RasterLine = 0 ;
        }
*/

//        events_mask |= MASK_VBL ;

}

void PC_Timer_200Hz(void)
{
//                if (memio[0x7a09]&0x20)
//                        events_mask |= MASK_TIMERC ;
}


double Calc_Local_Speed()
{

        return 100*(localcycles/50)/(512*313) ;



}

/*旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
 *�
 *�                                                            DUMP SCREEN
 *�
 *읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
*/

typedef struct {
#pragma pack (1) ;
        char    id ;                    // ID
        char    version ;               // PCX version
        char    encoding ;              // encoding
        char    bpp ;                   // bits per pixel
        short   xmin,ymin,xmax,ymax ;   // window
        short   hdpi,vdpi ;             // h & v DPI
        char    colormap[48] ;          // colormap
        char    zero ;                  // 0
        char    nbplanes ;              // planes
        short   bytesperline ;          // line length
        short   paletteinfo ;           // 0=Gray 1=BW/Col
        short   hscreen ;               // hscreen
        short   vscreen ;               // vscreen
        char    filler[54] ;            // nothing
} tpcx;

int file_exists(char *name)
{
        struct find_t dta ;
        return _dos_findfirst(name,0,&dta)?0:1 ;
}

static int effective_mode ;
static tpcx pcx ;
static char *pcvideoptr ;
static unsigned int screenwidth ;
extern char *screen_linear ;
extern vbemode_for_mixed_linewidth ;
extern unsigned char VGA_Palette[] ;

extern int lowraster_max ;

void putpcx(int fil,char c)
{
        write(fil,&c,1) ;
}

char getpixelmed(char *p,int d) ;
#pragma aux getpixelmed parm [ebx] [ecx] value [al] = \
        "mov    ax,0x004        "\
        "mov    dx,0x3ce        "\
        "out    dx,ax           "\
        "mov    ch,[ebx]        "\
        "mov    ah,1            "\
        "jmp    flush           "\
        "flush:                 "\
        "out    dx,ax           "\
        "jmp    flush2          "\
        "flush2:                "\
        "mov    al,ch           "\
        "mov    ah,[ebx]        "\
        "shr    ax,cl           "\
        "and    ax,0x101        "\
        "shl    ah,1            "\
        "or     al,ah           " ;


char getpixel(int x,int y,int plan,int bits24)
{
        char *p ;
        volatile char c;
        int x1;

        if (bits24) {
                        // TRUE COLOR PCX
                unsigned short v ;
                p = pcvideoptr+y*screenwidth+x*2 ;
                v = *(short *)p ;
                c = 0 ;

                if (vbemode_bpp==15)    // 15 bits
                 switch (plan) {
                        case 0 :
                                c = ((v>>0xa)&0x1f)<<3 ;
                                break ;
                        case 1 :
                                c = ((v>>0x5)&0x1f)<<3 ;
                                break ;
                        case 2 :
                                c = ((v>>0x0)&0x1f)<<3 ;
                                break ;
                 }
                 else switch(plan) {    // 16 bits
                        case 0 :
                                c = ((v>>0xb)&0x1f)<<3 ;
                                break ;
                        case 1 :
                                c = ((v>>0x6)&0x1f)<<3 ;
                                break ;
                        case 2 :
                                c = ((v>>0x0)&0x1f)<<3 ;
                                break ;
                }
        }
        else switch (effective_mode&3) { // PALETTE PCX
                case 0 : case 3 :
                        p = pcvideoptr+y*screenwidth+x ;
                        c = *p ;
                        break ;
                case 1 :/*
                        outp(0x3c4,1) ;
                        p = (pcvideoptr)+y*80+(x>>3) ;
                        x1 = 7-(x&7) ;
                        c = (*p>>x1)&1 ;
                        c2 = (*p>>x1)&1 ;
                        c = (c<<1)|c2 ;*/
                        p = (pcvideoptr)+y*80+(x>>3) ;
                        x1 = 7-(x&7) ;
                        c = getpixelmed(p,x1) ;
                        break ;
                case 2 :
                        p = (pcvideoptr+3200)+y*80+(x>>3) ;
                        x = 7-(x&7) ;
                        c = 1-(((*p)>>x)&1) ;
                        break ;
                default:
                        c = 0 ;
        }
        return c ;
}

void savepal(int fil)
{
        int i ;
        switch (effective_mode&3) {
                case 0 :
                case 1 :
                        for (i=0;i<256;i++) {
                                putpcx(fil,VGA_Palette[i*3]<<2) ;
                                putpcx(fil,VGA_Palette[i*3+1]<<2) ;
                                putpcx(fil,VGA_Palette[i*3+2]<<2) ;
                        }
                        break ;

                case 2 :
                        putpcx(fil,0) ;
                        putpcx(fil,0) ;
                        putpcx(fil,0) ;
                        putpcx(fil,255) ;
                        putpcx(fil,255) ;
                        putpcx(fil,255) ;
                        for (i=0;i<254*3;i++)
                                putpcx(fil,0) ;
                        break ;
       }
}

struct  {
        int x ;
        int y ;
} stmodeinfo[4] = {320,200,640,200,640,400,320,200} ;

void do_dumpscreen(void)
{
        static int nb_saved = 0 ;
        char static name[256] ;
        int fil,i,x,y ;
        int runcount, runchar ;
        char ch ;
        char outbuf[1000] ;
        int total ;
        int mode_x, mode_y ;
        int p,plane = 1 ;
        int bits24 = FALSE ;
        pcvideoptr = (char*)0xa0000 ;  // default

        effective_mode = VideoMode&3 ;

        screenwidth=mode_x = stmodeinfo[effective_mode].x ;
        mode_y = stmodeinfo[effective_mode].y ;

         switch(videoemu_type) {
                case VIDEOEMU_MIXED :
                                effective_mode = 0 ;
                                pcvideoptr = screen_linear ;
                                screenwidth = vbemode_for_mixed_linewidth ;
                                mode_x = 640 ;
                                mode_y = 400 ;
                                break ;
                case VIDEOEMU_LINE:
                                if (effective_mode==0) {
                                        if (vbe_ok)
                                                bits24 = (vbemode_bpp!=8) ;
                                        pcvideoptr = screen_linear ;
                                        screenwidth = vbemode_linewidth ;
                                        if ((effective_mode == 0)&&(lowraster_max != 0xf9))
                                                mode_y = 240 ;
                                }
                                break ;
        }

        do {
                nb_saved++ ;
                sprintf(name,"%s\\PCST_%03d.PCX",startdir,nb_saved) ;
        } while (file_exists(name)) ;

        //if (bits24) return ;


        fil = open(name,O_CREAT|O_BINARY|O_RDWR,0) ;
        if (fil==0) return ;

        pcx.id = 10 ;
        pcx.version = 5 ;
        pcx.encoding = 1 ;
        pcx.xmin = 0 ;
        pcx.ymin = 0 ;
        pcx.zero = 0 ;
        pcx.hdpi = pcx.hscreen = pcx.bytesperline = mode_x ;
        pcx.vdpi = pcx.vscreen = mode_y ;
        pcx.xmax = mode_x-1 ;
        pcx.ymax = mode_y-1 ;

        if (bits24) {
                pcx.paletteinfo = 0 ;
                pcx.nbplanes= 3 ;
                pcx.bpp = 8 ;
                plane = 3 ;
        }
        else {
                pcx.paletteinfo = 1 ;
                pcx.nbplanes= 1 ;
                pcx.bpp = 8 ;
        }

        for (i=0;i<54;i++) pcx.filler[i] = 0;
        write(fil,&pcx,128) ;

        for (y=0;y<mode_y;y++)
         for(p=0;p<plane;p++) {
          runcount = 0 ;
          runchar = 0;
          total = 0 ;
          for (x=0; x<mode_x; x++) {
                ch=getpixel(x,y,p,bits24) ;
                if (runcount==0) {
                    runcount=1 ;
                    runchar=ch;
                }
                else {
                    if ((ch!=runchar)||(runcount>=0x3f)) {
                        if ((runcount>1)||((runchar&0xc0)==0xc0))
                                outbuf[total++] = 0xc0|runcount ;
                        outbuf[total++] = runchar ;
                        runcount=1 ;
                        runchar=ch ;
                    }
                    else
                        runcount++ ;
                }
           }
           if ((runcount>1)||((runchar&0xc0)==0xc0))
                outbuf[total++] = 0xc0|runcount ;
           outbuf[total++] = runchar ;
           write(fil,outbuf,total);
        }

        if (!bits24) {
                putpcx(fil,12) ;
                savepal(fil) ;
        }
        close(fil) ;
}

