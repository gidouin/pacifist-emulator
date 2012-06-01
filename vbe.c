/*旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
 *�
 *�                                                             VBE Driver
 *�04/01/97 - Driver completly rewritten
 *읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
*/
#include <stdio.h>
#include <i86.h>
#include <stdlib.h>
#include <string.h>
#include "vbe.h"
#include "cpu68.h"

/*旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
 *�                                                     EXPORTED VARIABLES
 *읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
*/

void *screen_linear = 0xa0000 ;                 // screen linear pointer
void *screen_physical ;                         // screen physical pointer

int  vbemode ;                                  // choosen videomode
int  vbemode_x = 320;                           // resolution x
int  vbemode_y = 200;                           // resolution y
int  vbemode_bpp = 8;                           // resolution bpp
int  vbemode_linewidth =320;
int  vbe_ok = 0 ;
struct VBEINFO *vbeinfo ;                       // VBE driver info

int     vbemode_for_mixed = 0;
int     vbemode_for_mixed_y ;
int     vbemode_for_mixed_linewidth ;

int     vbemode_for_custom = 0 ;
int     vbemode_for_custom_linewidth ;

/*旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
 *�                                                        LOCAL VARIABLES
 *읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
*/

static struct VBEMODEINFO *vbemodeinfo ;        // VBE videomode info
static struct DOSMEM lowmemvbeinfo ;            // dosmem VBE driver info
static struct DOSMEM lowmemvbemodeinfo ;        // dosmem VBE videomode info

static union REGS regs ;                        // data registers struct
static struct SREGS sregs ;                     // segment registers struct
static RMREGS rmregs ;                          // DPMI registers dtruct

static int isVESA = FALSE ;                     // is VESA present?
static int VESAversion = 0 ;                    // VESA driver version
static int memoryallocations = 0 ;              // number of DOS allocations

/*旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
 *�                                                   FUNCTIONS PROTOTYPES
 *읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
*/

void *DPMI_FreeAccess ( void* Adress , DWORD Count ) {
    union REGS Regs;
    struct SREGS SegRegs;
    memset ( &SegRegs , 0 , sizeof ( SegRegs ) );
    Regs.w.ax = 0x0800;
    Regs.w.bx = (WORD)( (DWORD)Adress >> 16 );
    Regs.w.cx = (WORD)( (DWORD)Adress );
    Regs.w.si = (WORD)( Count >> 16 );
    Regs.w.di = (WORD)( Count );
    int386x ( 0x31 , &Regs , &Regs , &SegRegs );
    return (void*)( ( (DWORD)(Regs.w.bx) << 16 ) + Regs.w.cx );
};


void DPMI_CloseAccess ( void* Adress ) {
    union REGS Regs;
    struct SREGS SegRegs;
    memset ( &SegRegs , 0 , sizeof ( SegRegs ) );
    Regs.w.ax = 0x0801;
    Regs.w.bx = (WORD)( (DWORD)Adress >> 16 );
    Regs.w.cx = (WORD)( (DWORD)Adress );
    int386x ( 0x31 , &Regs , &Regs , &SegRegs );
};


int VBE_searchmode(int x,int y,int bpp) ;

int VBE_getmodeinfo(int mode,struct VBEMODEINFO *modeinfo)
{
        if (!isVESA) return FALSE ;

	memset (&sregs,0,sizeof(sregs));

        rmregs.eax = 0x4f01 ;                   // VBE function 1 = getmodeinfo
        rmregs.edi = 0 ;
        rmregs.es = lowmemvbemodeinfo.realmode_segment ;// ^VBEMODEINFO
        rmregs.ecx = mode ;                     // VBE video mode

        rmregs.ss = 0 ;
        rmregs.sp = 0 ;

        regs.w.ax = 0x300 ;
        regs.w.bx = 0x10 ;
        regs.w.cx = 0;
        sregs.es = FP_SEG(&rmregs) ;
        regs.x.edi = FP_OFF(&rmregs) ;
        int386x(0x31,&regs,&regs,&sregs) ;

        if ((rmregs.eax&0xffff) != 0x004f) return FALSE ;
        memcpy(modeinfo,vbemodeinfo,sizeof(struct VBEMODEINFO)) ;
        return TRUE ;
}

static void scan_vbe_modes()
{
        struct VBEMODEINFO mi ;
        int     rez ;
        int     okdepth,okx,oky,okgfx,oklinear ;
        unsigned short *pmodes ;
        int is400 = 0, is480 = 0 ;
        int linewidth400,linewidth480 ;

        if (!isVESA) return ;

        pmodes = (unsigned short *)((((unsigned int)vbeinfo->videomodelist>>16)<<4)+(unsigned short)vbeinfo->videomodelist) ;
        while (*pmodes!=0xffff) {

                rez = VBE_getmodeinfo(*pmodes,&mi) ;
                okdepth = ((mi.bitsperpixel==8)||(mi.bitsperpixel==15)||(mi.bitsperpixel==16)) ;
                okx = (mi.xresolution <=640) ;
                oky = (mi.yresolution <=480) ;
                okgfx = (mi.modeattributes&0x10) ;
                oklinear = (mi.modeattributes&0x80) ;

                if ((mi.xresolution==640)&&
                    (mi.yresolution==400)&&
                    (mi.bitsperpixel==8)&&
                    (oklinear&&okgfx)) {
                        is400 = *pmodes ;
                        linewidth400 = mi.bytesperscanline ;
                }
                        //vbemode_for_mixed = *pmodes ;
                else if ((mi.xresolution==640)&&
                    (mi.yresolution==480)&&
                    (mi.bitsperpixel==8)&&
                    (oklinear&&okgfx)) {
                        is480 = *pmodes ;
                        linewidth480 = mi.bytesperscanline ;
                }
/*
                if (rez&&okdepth&&okgfx&&okx&&oky) {
                        printf("mode %04x (%4d x %4d) %2d bits | linear=%s\n",*pmodes,mi.xresolution,mi.yresolution,mi.bitsperpixel,(mi.modeattributes&0x80)?"yes":"no") ;
                }
*/
                pmodes++ ;
        }

        if (is400) {
                printf("Mixed Mode allowed, using 640x400x256 VBE2.0 LFB mode.\n") ;
                vbemode_for_mixed = is400 ;
                vbemode_for_mixed_y = 400 ;
                vbemode_for_mixed_linewidth = linewidth400 ;
        } else if (is480) {
                printf("Mixed Mode allowed, using 640x480x256 VBE2.0 LFB mode.\n") ;
                vbemode_for_mixed = is480 ;
                vbemode_for_mixed_y = 480 ;
                vbemode_for_mixed_linewidth = linewidth480 ;
        } else {
                printf("Mixed video mode not supported (you need linear 640x480x256 or 640x400x256.\n") ;
                if (videoemu_type==VIDEOEMU_MIXED)
                        videoemu_type=VIDEOEMU_SCREEN ;
        }

        if (is480) {
                vbemode_for_custom = is480 ;
                vbemode_for_custom_linewidth = linewidth480 ;
        }
        else if (videoemu_type==VIDEOEMU_CUSTOM)
                videoemu_type = VIDEOEMU_SCREEN ;

}


int VBE_init()       // returns 0 if no VBE, else returns version
{
	struct VBEMODEINFO mi ;

        if (isVESA) return VESAversion ;

                        // alloc dos memory for VBEINFO & VBEMODEINFO

        if (!allocdosmem((512)>>4,&lowmemvbeinfo)) {
                fprintf(stderr,"*** Can't allocate low memory for VBE detection. ***\n") ;
                return 0 ;
        }
        memoryallocations++ ;

        if (!allocdosmem((256)>>4,&lowmemvbemodeinfo)) {
                fprintf(stderr,"*** Can't allocate low memory for VBE detection. ***\n") ;
                return 0 ;
        }
        memoryallocations++ ;

        vbeinfo = (struct VBEINFO *)lowmemvbeinfo.linear_base ;
        vbemodeinfo = (struct VBEMODEINFO *)(lowmemvbemodeinfo.linear_base) ;
        vbeinfo->signature = '2EBV';            // default signature

	memset (&sregs,0,sizeof(sregs));
        rmregs.eax = 0x4f00 ;                   // VBE function 0 = getinfo
        rmregs.edi = 0 ;
        rmregs.es = lowmemvbeinfo.realmode_segment ;// address of VBEINFO struct

        rmregs.ss = 0 ;                         // prevents crash!
        rmregs.sp = 0 ;
        regs.w.ax = 0x300 ;                     // DPMI - Call RealMode INT
        regs.w.bx = 0x10 ;                      // bios VIDEO
        regs.w.cx = 0 ;                         // ? stack
        sregs.es = FP_SEG(&rmregs) ;
        regs.x.edi = FP_OFF(&rmregs) ;
        int386x(0x31,&regs,&regs,&sregs) ;

        if (((rmregs.eax&0xffff) != 0x004f)||(vbeinfo->signature!='ASEV')) {
                printf("VBE2.0 not detected.\n") ;
                return 0 ;
        }


        VESAversion = vbeinfo->version ;
        printf("VBE driver (%d.%d) found.\n",(VESAversion>>8),VESAversion&0xff) ;

        isVESA = TRUE ;
        if (!(vbemode=VBE_search_a_mode())) {
                //printf("This version still NEEDS a linear VBE mode for line-oriented screens.\n") ;
                printf("Very limited and flashy line-mode support using standard VGA resolution.\n") ;
                return 0 ;
        }

	VBE_getmodeinfo(vbemode,&mi) ;

	screen_physical = mi.physicalbaseaddress ;//,0x800000 ;
	screen_linear = DPMI_FreeAccess(screen_physical,0x80000) ;

        vbemode_x = mi.xresolution ;
        vbemode_y = mi.yresolution ;
        vbemode_bpp = mi.bitsperpixel ;
        vbemode_linewidth = mi.bytesperscanline ;

        scan_vbe_modes() ;

/*
        regs.w.ax = 0x4f0a ; //Get PMode inferface
        regs.w.bx = 0 ;
        memset(&sregs,0,sizeof(sregs)) ;
        int386x(0x10,&regs,&regs,&sregs) ;
        if (regs.w.ax != 0x004f) {
                printf("Can't initialize Protected Mode VBE interface\n") ;
                return 0 ;
        }

        vbepmode = (struct VBEPMODEINTERFACE *)(malloc(regs.w.cx)) ; // alloc mem
        memcpy(vbepmode,(sregs.es<<4)+regs.w.di,regs.w.cx) ;
        VBE_PMSetPalette = (unsigned int)vbepmode+vbepmode->SetPrimaryPalette ;
        if (!allocdosmem((256*4)>>4,&lowmempalette)) {
                fprintf(stderr,"*** Can't allocate low memory for palette. ***\n") ;
                return 0 ;
        }
        memoryallocations++ ;
        VBE_Palette = lowmempalette.linear_base ;
        VBE_Palette_realmode_segment = lowmempalette.realmode_segment ;
*/
        return vbeinfo->version ;
}


int VBE_search_a_mode(void)
{
        int rez ;
        struct VBEMODEINFO mi ;
	unsigned short *pmodes = (unsigned short *)((((unsigned int)vbeinfo->videomodelist>>16)<<4)+(unsigned short)vbeinfo->videomodelist) ;

	while (*pmodes!=0xffff) {
		rez = VBE_getmodeinfo(*pmodes,&mi) ;
		if (rez&&(mi.xresolution==320)&&(mi.bitsperpixel==8))
                        return *pmodes ;
		pmodes++ ;
	}
        return 0 ;
}

int VBE_setmode(int mode)
{
        char *p = screen_linear ;
        int i ;
        struct VBEMODEINFO mi ;
        if (VBE_getmodeinfo(mode&0x3fff,&mi)) {
                vbemode_linewidth = mi.bytesperscanline ;
        }

        regs.x.eax = 0x4f02 ;
        regs.x.ebx = mode ;   // 320x200x32768
        int386(0x10,&regs,&regs) ;

//        for (i=0;i<256*1024;i++) *p++ = 0 ;


        return (regs.w.ax == 0x004f) ;

}

void *VBE_testmode(int mode) // returns 0 if not supported, else base
{
        struct VBEMODEINFO mi ;

        if (!VBE_getmodeinfo(mode,&mi)) return 0 ;
        printf("phi=%x\n",mi.physicalbaseaddress) ;
        return (mi.physicalbaseaddress) ;

}

void VBE_deinit(void)
{
	if (!isVESA) return ;
	DPMI_CloseAccess(screen_linear) ;

        if (memoryallocations--) freedosmem(&lowmemvbeinfo) ;
        if (memoryallocations--) freedosmem(&lowmemvbemodeinfo) ;
//        if (memoryallocations--) freedosmem(&lowmempalette) ;
}

void VBE_listmodes() // ok avec s3vbe20, d괹onne avec univbe!!!!!
{
        FILE *fp ;
	int rez ;
	struct VBEMODEINFO mi ;
	unsigned short *pmodes = (unsigned short *)((((unsigned int)vbeinfo->videomodelist>>16)<<4)+(unsigned short)vbeinfo->videomodelist) ;
        int okdepth, okgfx, oklinear,okxy ;
        int nbsup = 0 ;

        fp = fopen("VBEMODES.LST","wt") ;
        fprintf(fp,"--- PaCifiST authorized VBE Modes ---\n" ) ;
        if (!vbe_ok) {
                printf("*** No VBE 2.0 driver installed - No VBE modes to list ****\n") ;
        }
        else {
                        while (*pmodes!=0xffff) {
        		rez = VBE_getmodeinfo(*pmodes,&mi) ;
                        if (rez) {
                                okdepth = ((mi.bitsperpixel==8)||(mi.bitsperpixel==15)||(mi.bitsperpixel==16)) ;
                                okgfx = (mi.modeattributes&0x10) ;
                                oklinear = (mi.modeattributes&0x80) ;
                                okxy = (mi.xresolution <=800) ;

        		        if (okdepth&&okgfx&&oklinear&&okxy) {
                			fprintf(fp,"0x%04x  %4d  %4d  %4d\n",*pmodes,mi.xresolution,mi.yresolution,mi.bitsperpixel) ;
                                        nbsup++ ;
                                }
                        }
             		pmodes++ ;
        	}
                printf("%d different VBE modes allowed\n",nbsup) ;
        }
        fclose(fp) ;
}

int VBE_cfg_initmode(int thismode)
{
        int rez ;
	struct VBEMODEINFO mi ;
        int okdepth, okgfx, oklinear,okxy ;

	rez = VBE_getmodeinfo(thismode,&mi) ;

        if (rez) {
               okdepth = ((mi.bitsperpixel==8)||(mi.bitsperpixel==15)||(mi.bitsperpixel==16)) ;
               okgfx = (mi.modeattributes&0x10) ;
               oklinear = (mi.modeattributes&0x80) ;
               okxy = (mi.xresolution <=800) ;
               if (okdepth&&okgfx&&oklinear&&okxy) {
                        vbemode = thismode ;
        	        screen_physical = mi.physicalbaseaddress ;//,0x800000 ;
	                screen_linear = DPMI_FreeAccess(screen_physical,0x80000) ;
                        vbemode_x = mi.xresolution ;
                        vbemode_y = mi.yresolution ;
                        vbemode_bpp = mi.bitsperpixel ;
                        vbemode_linewidth = mi.bytesperscanline ;
                        printf("Default VBEMODE is 0x%04x [%dx%d with %d colors]\n",vbemode,vbemode_x,vbemode_y,1<<vbemode_bpp) ;
                        return TRUE ;
                }
        }
        return FALSE ;
}


