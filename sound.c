/*
 *   18 nov 1996 : started a YM soundchip emulation,
 *                 code ripped from STonX
 *  21 dec 1996  : added STF sampling
 *   2 feb 1997  : started STE DMA sound
 *  26 feb 1997  : converted YM emulation from Ulrich Doewich
 *   4 mar 1997  : merged YM emulation from Arnaud Carre
 *  12 mar 1997  : modified DMA irq from Arnaud Carre player
*/

#ifdef SOUND

#include <i86.h>
#include <stdlib.h>
#include <stdio.h>
#include <dos.h>
#include <conio.h>
#include <string.h>
#include <fcntl.h>
#include <io.h>
#include "cpu68.h"
#include "ym2149.h"

/////////////////////////////////////////////// variables used in SND.ASM

char PSGRegs[16] ;      // AY8910 registers
int YmReg13Write = TRUE;
static int recording_YmReg13Write = TRUE;

/////////////////////////////////////////////// functions from SND.ASM

int isSamples = FALSE ;

void    init_sound() ;
void    deinit_sound() ;
int     read_yamaha() ;
void    write_yamaha(int v) ;
void    periodic_sound() ;


#define RENDITIONFREQ 22050
//#define RENDITIONFREQ 22222
//#define RENDITIONFREQ 50*313

#define AUDIODEVICE_NONE                0
#define AUDIODEVICE_SOUNDBLASTER        1
#define AUDIODEVICE_GUS                 2

static int samples_to_generate = RENDITIONFREQ/50 ;

struct DOSMEM lowmemsample ;
int YM_reg ;

static int AudioDevice = AUDIODEVICE_NONE;
char *audio_buffer ;
char *audio_buffer1  ;
char *audio_buffer2  ;


struct {
        unsigned int port ;
        unsigned int dma ;
        unsigned int irq ;
        unsigned int vector ;
        unsigned int picport ;
        unsigned int maskirq ;
        unsigned int type ;
        unsigned int dspversion ;
        unsigned int mixer ;
} audio ;


#define SB8     0
#define SBPRO   1
#define SB16    2

static struct {
        unsigned int page ;
        unsigned int offset ;
        unsigned int length ;
} dmaports[4] = {{0x87,0x00,0x01},
                 {0x83,0x02,0x03},
                 {0x81,0x04,0x05},
                 {0x82,0x06,0x07}} ;


int read_yamaha(void)
{
        /*if (YM_reg = 14) return 0 ;
        else
        */
        return  PSGRegs[YM_reg] ;
}

void    write_yamaha(int v)
{
        switch (YM_reg) {
                case 13: YmReg13Write= TRUE ;
                         recording_YmReg13Write = TRUE;
                         PSGRegs[YM_reg] = v&15 ;
                         break ;
                case 0:case 1:case 2:case 3:
                case 4:case 5:case 6:case 7:
                case 8:case 9:case 10:case 11:
                case 12:  PSGRegs[YM_reg] = v ; break ;
                case 14:  break;
                case 15: break ;
        }
}

int detect_audiodevice(void) ;
void init_soundcard(void) ;
void pause_sound(void) ;
void continue_sound(void) ;
void ackirq(void) ;

static void (__interrupt __far *prev_sound_handler)();
static void __interrupt __far _loadds inthandler() ;

void init_sound(void)
{
        int audiodevice ;
        char *ptr ;

        init_record() ;

        if (!isSound) return ;
        audiodevice = detect_audiodevice() ;
        if (!audiodevice) {
                printf("Unable to found any suported soundcard.\n") ;
                isSound = FALSE ;
                return ;
        }


        if (!allocdosmem(samples_to_generate*2+65536+32, &lowmemsample)) {
                printf("*** Can't allocate lowmem area for sound emulation.\n") ;
                isSound = FALSE ;
                return ;
        }
        if (isMIDI&&(audiodevice == AUDIODEVICE_SOUNDBLASTER)) {
                printf("ST MIDI emulation enabled.\n") ;
                isSound = FALSE ;
                return ;
        }
        isMIDI = FALSE ;

        ptr = (char *)((lowmemsample.linear_base+65536)&0xffff0000) ;
        audio_buffer1 = ptr ;
        audio_buffer2 = audio_buffer1 + samples_to_generate ;
        memset(audio_buffer1,0x80,(samples_to_generate*2)+32) ;
        AudioDevice = audiodevice ;

        Reset_Sound() ;
        Ym2149Init() ;
        init_soundcard() ;

        if (AudioDevice == AUDIODEVICE_SOUNDBLASTER) {
                audio.vector = (audio.irq<8) ? audio.irq+8 : audio.irq+0x68 ;
                audio.picport= (audio.irq<8) ? 0x20 : 0xa0 ;
                audio.maskirq=1<<(audio.irq&7) ;
                prev_sound_handler = _dos_getvect(audio.vector) ;
                _dos_setvect(audio.vector,inthandler) ;
                outp(audio.picport+1,inp(audio.picport+1)&~audio.maskirq) ;
        }

        pause_sound() ;
        printf("soundchip emulation initialized. (c) Arnaud Carre.\n") ;
        if (isSamples)
                printf("STF samples support added (still *very* buggy - you've been warned)\n") ;
        else printf("no STF samples support.\n") ;
        printf("MIDI emulation disabled.\n") ;
}

void volumescale(char *buffer)
{
        register int i ;
        if (globalvolume==255) return ;
        for (i=0;i<samples_to_generate;i++) {
                *buffer = ((*buffer)*globalvolume)>>8 ;
                buffer++ ;
        }
}

char volume_buffer[512*4] ;//max entries:512
int nbVolumeEntries = 0 ;

extern int ym_monitor ;
extern void periodic_ym() ;

void common_sound_handler()
{
        if (ym_monitor) periodic_ym() ;
        Ym2149registerRead(PSGRegs,YmReg13Write) ;
        YmReg13Write = FALSE ;

        YmEmulator(audio_buffer2) ;

        volumescale((char *)audio_buffer2) ;
        nbVolumeEntries = 0 ;
        audio_buffer = audio_buffer2 ;
}

int nbsb = 0 ;

#pragma off (check_stack) ;
void __interrupt __far _loadds inthandler()
{
        int i ;
        ackirq() ;
        nbsb++ ;

        i = (int)audio_buffer1 ;         // swap buffer
        audio_buffer1 = audio_buffer2 ;
        audio_buffer2 = (unsigned char *)i ;

        dma_play() ;

        common_sound_handler() ;


        if (audio.irq>=8)
                outp(0xa0,0x20) ;
        outp(0x20,0x20) ;
}
#pragma on (check_stack) ;




static void uninstall_handler()
{
    if (!isSound) return ;
    outp(audio.picport+1,inp(audio.picport+1)|audio.maskirq) ;
    _dos_setvect(audio.vector,prev_sound_handler) ;
}


void deinit_sound()
{
        if (!isSound) return ;
        if (!AudioDevice) return ;
        freedosmem(&lowmemsample) ;

        switch(AudioDevice){
                case AUDIODEVICE_SOUNDBLASTER:
                        if (!isMIDI)
                                uninstall_handler() ;
                        SbDspReset() ;
                        break ;
                case AUDIODEVICE_GUS:
                        deinit_gus() ;
                        break ;
        }
}

void periodic_sound()
{
        if (!isSound) return ;
        if (!AudioDevice) return ;
}

void Reset_Sound()
{
        int i ;
        if (!isSound) return ;
        if (!AudioDevice) return ;
        for (i=0;i<13;i++) PSGRegs[i] = 0 ;
        for (i=0;i<512*4;i++) volume_buffer[i] = 0 ;
        memset(audio_buffer1,0x80,(samples_to_generate*2)+32) ;
}

int scan_env(char *penv, char id, unsigned int *value, int base)
{
        int found = FALSE ;
        char *p = penv ;
        unsigned int v = 0 ;
        while (*p && !found) {
                if ((*p==id) && ((p==penv)||(*(p-1)==' ')))
                {       p++ ;
                        found = TRUE ;
                        while (*p && (*p!=' ')) {
                                if (*p < '9') v = (v*base)+*p - '0' ;
                                else v = (v*base)+*p-'A'+10 ;
                                p++ ;
                        }
                }
                p++ ;
        }
        *value = v ;
        return found ;
}

#ifdef gus
extern int  detect_gus(void) ;
extern int init_gus(void) ;
extern void deinit_gus(void) ;
extern void pause_gus(void) ;
extern void continue_gus(void) ;
#else
//
// to allow linking without gus support 
//
static int detect_gus(void) {
    return 0;
}
static int init_gus(void) {
    return -1;
}
static void deinit_gus(void) {}
static void pause_gus(void) {}
static void continue_gus(void) {}
#endif

int detect_sb() ;


// [fold]  [
int detect_audiodevice(void)
{

        if (detect_gus()) return AUDIODEVICE_GUS;
        else if (detect_sb()) return AUDIODEVICE_SOUNDBLASTER  ;
        return AUDIODEVICE_NONE ;


}

// [fold]  ]


/*旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
 *�
 *�                                                    Sound Cards Drivers
 *�
 *읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
*/

int detect_sb()
{
        char *penv ;

        if ((penv = (char *)getenv("BLASTER"))) {
                if (!(scan_env(penv,'A',&audio.port,16)&&
                      scan_env(penv,'D',&audio.dma,10)&&
                      scan_env(penv,'I',&audio.irq,10)))

                        printf("BLASTER environment found, but it seems corrupted.\n") ;
                else
                {
                 printf("SoundBlaster found at Port 0x%3x with Dma channel %d and Irq %d.\n",
                        audio.port, audio.dma, audio.irq) ;

                if (!SbDetect()) {
                        printf("Failed to init DSP.\n") ;
                        return FALSE ;
                }
                else    return TRUE ;
                }
        }
        return FALSE ;
}

// [fold]  [
int     SbDelay(void)
{
        int    a,i;
        i=256;
        a=0;

        do a+=inp(audio.port+0x6);
        while (--i);
        return a;
}

// [fold]  ]

// [fold]  [
void    SbDspWrite(UB data)
{
        int i = 32000;
        while ((inp(audio.port+0xc)&0x80)&&(--i));
        if (i) outp(audio.port+0xc,data);

}

// [fold]  ]

// [fold]  [
int     SbDspReset(void)
{
/*        int    i,j,d;

        j=64;
        do {
                outp(audio.port+0x6,1);
                SbDelay();
        delay(10) ;
                outp(audio.port+0x6,0);
                i=0x400;
                while ( (!(inp(audio.port+0xe)&0x80)) && (i--))
                d=inp(audio.port+0xa);
        }
        while ((d!=0xaa) && (--j));
        if (d==0xaa) return TRUE;
        return FALSE;
*/
        outp(audio.port+0x6,1) ;
        delay(10) ;
        outp(audio.port+0x6,0) ;
        delay(100) ;
        return (inp(audio.port+0xa)==0xaa);
}

// [fold]  ]

// [fold]  [
void    SbMixerReset(void)
{
        outp(audio.port+4,0);
        SbDelay();
        outp(audio.port+5,0);
}

// [fold]  ]

// [fold]  [
void    SbSetGeneralVolume(UB vol)
{
          SbMixerWrite(0x30,vol);
          SbMixerWrite(0x31,vol);
}

// [fold]  ]

// [fold]  [
void    SbSetSampleVolume(UB vol)
{
          SbMixerWrite(0x32,vol);
          SbMixerWrite(0x33,vol);
}

// [fold]  ]

// [fold]  [
void    SbSetBalance(int v)
{
        int     left=12 ;
        int     right=12;

        if (audio.type==SB16)
        {
          if (v<12) right = v;
          if (v>12) left = 24-v;
          SbMixerWrite(50,left<<4);
          SbMixerWrite(51,right<<4);
        }
}

// [fold]  ]

// [fold]  [
void    SbMixerWrite(UB reg,UB data)
{
        outp(audio.port+4,reg);
        outp(audio.port+5,data);
}

// [fold]  ]

// [fold]  [
int     SbMixerRead(UB reg)
{
        outp(audio.port+4,reg);
        return (inp(audio.port+5));
}

// [fold]  ]

// [fold]  [
int     SbDspRead(void)
{
        while (!(inp(audio.port+0xe)&0x80));
        return inp(audio.port+0xa);
}

// [fold]  ]

// [fold]  [
int     SbDetect(void)
{
        int     old;

        if (!SbDspReset())
                return FALSE ;

                // Detecte la puce MIXER.
        audio.mixer = FALSE;
        old=SbMixerRead(0x22);
        SbMixerWrite(0x22,243);
        if (SbMixerRead(0x22)==243) {
                SbMixerWrite(0x22,old);
                audio.mixer = TRUE;
        }
                // Detecte la version du DSP sur la carte
        audio.dspversion=0;
        SbDspWrite(0xe1);       // Get version number.
        audio.dspversion =  SbDspRead()<<8;
        audio.dspversion |= SbDspRead();
                // Determine le type de carte (8,PRO ou 16)
        if (!audio.mixer) audio.type=SB8;
        else {
                if (audio.dspversion<0x0400) audio.type=SBPRO;
                else audio.type=SB16;
        }
                // DEBUG: Pour l'instant on sucre la SB-PRO !!
        if (audio.type==SBPRO) {
                audio.type=SB8;
                audio.mixer=FALSE;
        }
        return TRUE ;
}

// [fold]  ]

void    SbDspSpeakOn(void)
{
        SbDspWrite(0xd1);
}

void    SbDspSpeakOff(void)
{
        SbDspWrite(0xd3);
}

void    SbDspDmaContinue(void)
{
        SbDspWrite(0xd4);
}

void    SbDspDmaStop(void)
{
        SbDspWrite(0xd0);
}

void init_soundcard()
{
        switch(AudioDevice) {
                case AUDIODEVICE_NONE :
                        break ;
                case AUDIODEVICE_SOUNDBLASTER: ;

                        outp(0x0a,4+audio.dma);
                        outp(0x0c,0x00);
                        outp(0x0b,0x48 + audio.dma);

                        outp(dmaports[audio.dma].offset,((int)audio_buffer1)&0xff) ;
                        outp(dmaports[audio.dma].offset,((int)audio_buffer1>>8)&0xff) ;
                        outp(dmaports[audio.dma].page,((int)audio_buffer1>>16)&0xf) ;
                        outp(dmaports[audio.dma].length,(samples_to_generate-1)&0xff) ;
                        outp(dmaports[audio.dma].length,((samples_to_generate-1)>>8)&0xff) ;
                        outp(0x0a,audio.dma) ;         // clear DMA mask bit

                        SbDspWrite(0x40);
                        SbDspWrite(256-1000000L/RENDITIONFREQ); //playback rate

                        switch (audio.type)
                        {
                         case SB8:
                                SbDspWrite(0x14);
                                SbDspWrite(samples_to_generate-1);
                                SbDspWrite((samples_to_generate-1)>>8);
                                break;

                         case SBPRO:
                                SbDspWrite(0x48);
                                SbDspWrite(samples_to_generate-1);
                                SbDspWrite((samples_to_generate-1)>>8);
                                SbDspWrite(0x91);
                                break;

                         case SB16:
                                SbDspWrite(0xc6);               // Play DMA 8 bits AUTO-LOOP (0xb6 pour 16bits)
                                SbDspWrite(0x00);               // 0x20 si STEREO
                                SbDspWrite(samples_to_generate-1);
                                SbDspWrite((samples_to_generate-1)>>8);
                                break;
                        }

                        // Autorise sortie son.
                        SbDspSpeakOn();


//                        senddsp(audio.port,0xd1) ; // turn on speaker ;
//                        senddsp(audio.port,0x40) ; // set playback rate
//                        senddsp(audio.port,211) ;
                        break ;
                case AUDIODEVICE_GUS :
                        if (init_gus())
                                        printf("GUS seems OK...Cheers! ^_^\n\n") ;
                        else {
                                printf("GUS problem. :(\n\n") ;
                                AudioDevice=AUDIODEVICE_NONE ;
                        }
                        break ;
        }
}

void pause_sound()
{
        if (!isSound) return ;
        switch(AudioDevice) {
                case AUDIODEVICE_SOUNDBLASTER:
//                        senddsp(audio.port,0xd3) ;
//                        senddsp(audio.port,0xd0) ;

                        SbDspDmaStop() ;

                        break ;
                case AUDIODEVICE_NONE:
                        break ;
                case AUDIODEVICE_GUS:
                        pause_gus() ;
                        break ;
        }
}



void continue_sound()
{
        int i ;
        if (!isSound) return ;
        for (i=0;i<512*4;i++) volume_buffer[i] = 0 ;
        memset(audio_buffer1,0x80,(samples_to_generate*2)+32) ;

        switch(AudioDevice) {
                case AUDIODEVICE_SOUNDBLASTER:
                        continue_sb() ;
//                        SbDspDmaContinue() ;

                        break ;
                case AUDIODEVICE_NONE:
                        break ;
                case AUDIODEVICE_GUS:
                        continue_gus() ;
                        break ;
        }
}

void continue_sb()
{
        if (!AudioDevice) return ;
        init_soundcard() ;
//        outp(audio.picport+1,inp(audio.picport+1)&~audio.maskirq) ;
//        dma_play() ;

}

//---------------------------------------------------- play sample with DMA
void dma_play(void)
{

        if (!AudioDevice) return ;


        outp(0x0a,4+audio.dma) ;        // set mask bit channel
        outp(0x0c,0) ;                   // clear byte ptr
        outp(0x0b,0x48+audio.dma) ;     // set DMA transfer mode
        outp(dmaports[audio.dma].offset,((int)audio_buffer1)&0xff) ;
        outp(dmaports[audio.dma].offset,((int)audio_buffer1>>8)&0xff) ;
        outp(dmaports[audio.dma].page,((int)audio_buffer1>>16)&0xf) ;
        outp(dmaports[audio.dma].length,(samples_to_generate-1)&0xff) ;
        outp(dmaports[audio.dma].length,((samples_to_generate-1)>>8)&0xff) ;
        outp(0x0a,audio.dma) ;         // clear DMA mask bit

        switch(AudioDevice) {

                case AUDIODEVICE_NONE :
                        return ;

                case AUDIODEVICE_SOUNDBLASTER :

                        switch (audio.type) {
                                case SB8:
                                        SbDspWrite(0x14);
                                        SbDspWrite(samples_to_generate-1);
                                        SbDspWrite((samples_to_generate-1)>>8);
                                        break;
                                case SBPRO:
                                        SbDspWrite(0x48);
                                        SbDspWrite(samples_to_generate-1);
                                        SbDspWrite((samples_to_generate-1)>>8);
                                        SbDspWrite(0x91);
                                        break;
                                case SB16:
                                        SbDspWrite(0x45);             // DMA continue.
                                        break;
                        }

/*                        senddsp(audio.port,0x14) ; // DSP func  8 bit DAC
                        senddsp(audio.port,(samples_to_generate)&0xff) ;
                        senddsp(audio.port,(samples_to_generate>>8)&0xff) ;
*/
                        break ;
        }
}



void ackirq(void)
{
        switch(AudioDevice) {

                case AUDIODEVICE_NONE:
                        break ;

                case AUDIODEVICE_SOUNDBLASTER:
                        inp(audio.port+0xe) ;
                        break ;
        }
}

#define MAXYMBUFFER (14*60*50)*20

char *YMbuffer ;
char *YMlinear ;


extern int ym_pos_start ;
extern int ym_pos_end ;
extern int ym_pos_loop ;

void init_record()
{
        if (!isYMrecord) return ;
        YMbuffer = (char *)malloc(MAXYMBUFFER+14) ;
        YMlinear = (char *)malloc(MAXYMBUFFER/14) ;
        if (!(YMbuffer&&YMlinear)) {
                printf("not enought memory to record YM registers\n") ;
                isYMrecord = FALSE ;
        }
        printf("%d bytes allocated for YM registers recording\n",MAXYMBUFFER) ;

        ym_pos_start = ym_pos_end = ym_pos_loop = 0 ;

}

int YMbuffer_ptr = 0 ;

void YMrecord(void)
{
        int i ;
        char *ymb = YMbuffer + YMbuffer_ptr;
        char *psgb = (char *) PSGRegs;

        if (!isYMrecord) return ;

        ym_pos_end++ ;

        if (YMbuffer_ptr>=MAXYMBUFFER) {
                YMrecording = FALSE ;
        }
        if (!YMrecording) return ;

        YMbuffer_ptr += 14 ;

        for (i=0;i<13;i++)
                *ymb++ = *psgb++ ;

        if (recording_YmReg13Write)
                *ymb = *psgb ;
        else *ymb = 0xff ;

        recording_YmReg13Write = FALSE ;
}

char pcstid[] = "Generated with PaCifiST v0.49" ;
//char pcstid[] = "Generated by Frederic Gidouin with a tweaked CPE" ;

void save_value(int fil, unsigned int nb, int siz)
{
        int i ;
        char *p = (char *) &nb ;
        for (i=0;i<siz;i++)
                write(fil,(p+siz-i-1),1) ;

}

#define YM5


int save_YMrecord(char **pname)
{
        char static name[256] ;
        int fil ;
        int r,i, nb,dummy ;
        static int YMfiles_saved = 0 ;

        YMfiles_saved++ ;
        sprintf(name,"%s\\YM_%03d.BIN",startdir,YMfiles_saved) ;
        *pname = &name ;

        remove(name) ;
        fil = open(name,O_CREAT|O_BINARY|O_RDWR,0) ;
        if (fil==0) return FALSE ;

        nb = ym_pos_end-ym_pos_start ;

//        nb = YMbuffer_ptr/14 ;

#ifdef YM5

        write(fil,"YM5!",4) ;           // format
        write(fil,"LeOnArD!",8) ;       // id
        save_value(fil,nb,4) ;          // number of VBL
        save_value(fil,1,4) ;           // song Attributes: interleaved
        save_value(fil,0,2) ;            // nb digidrums
//       save_value(fil,2000000,4) ;   // 2000000Hz => ST
        save_value(fil,1000000,4) ;     // 1000000Hz => CPC
        save_value(fil,50,2) ;          // 50KHz
        save_value(fil,ym_pos_loop-ym_pos_start,4) ; // VBL Loop
        dummy=0 ;
        write(fil,&dummy,2) ;           // Size extra data
        write(fil,&dummy,1) ;           // NTS song name
        write(fil,&dummy,1) ;           // NTS name author
        write(fil,pcstid,sizeof(pcstid)) ;
#else
        write(fil,"YM3!",4) ;
#endif
/*        for (i=0;i<nb;i++) {
                YMbuffer[i*14+1] &= 0x0f ;
                YMbuffer[i*14+3] &= 0x0f ;
                YMbuffer[i*14+5] &= 0x0f ;
                YMbuffer[i*14+6] &= 0x1f ;
                YMbuffer[i*14+7] &= 0x3f ;
                YMbuffer[i*14+8] &= 0x1f ;
                YMbuffer[i*14+9] &= 0x1f ;
                YMbuffer[i*14+10] &= 0x1f ;
                if (YMbuffer[i*14+13] != 0xff)
                        YMbuffer[i*14+13] &= 0xf ;
        }
*/
        for (r=0;r<14;r++) {
                for (i=0;i<nb;i++)
                        YMlinear[i] = YMbuffer[(i+ym_pos_start)*14+r] ;
                write(fil,YMlinear,nb) ;
        }

#ifdef YM5
        for (i=0;i<nb;i++)
                YMlinear[i] = 0 ;
        write(fil,YMlinear,nb) ;
        write(fil,YMlinear,nb) ;

        write(fil,"End!",4) ;
#endif
        close(fil) ;
        return TRUE ;
}

read_dword(int fil, int *integ)
{
        int i ;
        char *p=(char *)integ+4 ;
        for (i=0;i<4;i++)
                read(fil,--p,1) ;
}

/*
int load_ym(char *name, int *repeat)
{
        int fil ;
        int nbvbls;
        int dw,i ;
        char b ;

        *repeat = 0 ;

        fil = open(name,O_BINARY|O_RDONLY,0) ;
        if (fil==0) return FALSE ;
        read(fil,&dw,4) ;
        if (dw!=0x21354d59) return FALSE ;
        read(fil,YMlinear,8) ;
        read_dword(fil,&nbvbls) ;
        read(fil,YMlinear,4+2+4+2) ;
        read_dword(fil,repeat) ;
        read(fil,YMlinear,2) ;

        for (i=0;i<3;i++)
         do {
                read(fil,&b,1) ;
         } while (b) ;

        for (dw=0;dw<14;dw++) {
                read(fil,YMlinear,nbvbls) ;
                for (i=0;i<nbvbls;i++) {
                        YMbuffer[i*14+dw] = YMlinear[i] ;
                }

        }
        close(fil) ;
        ym_pos_start = 0 ;
        ym_pos_end = nbvbls ;
        ym_pos_loop = repeat ;
        YMbuffer_ptr = nbvbls*14 ;

        return nbvbls ;
}
*/

/*
int save_YMrecord(char **pname)
{
        char static name[256] ;
        int fil ;
        int r,i, nb ;
        static int YMfiles_saved = 0 ;

        YMfiles_saved++ ;
        sprintf(name,"%s\\YM_%03d.BIN",startdir,YMfiles_saved) ;
        *pname = &name ;

        remove(name) ;
        fil = open(name,O_CREAT|O_BINARY|O_RDWR,0) ;
        if (fil==0) return FALSE ;

        nb = YMbuffer_ptr/14 ;

        write(fil,"YM3!",4) ;           // format

        for (r=0;r<14;r++) {
                for (i=0;i<nb;i++)
                        YMlinear[i] = YMbuffer[i*14+r] ;

                write(fil,YMlinear,nb) ;
        }
        close(fil) ;
        return TRUE ;
}
*/
/******************************************************* MIDI EMULATION *****/

#define MPU401_RESET      0xff
#define MPU401_UART       0x3f
#define MPU401_CMDOK      0xfe
#define MPU401_OK2WR      0x40
#define MPU401_OK2RD      0x80

/*
int midiport = 0x330 ;


void write_mpu401_cmd(char cmd)
{
        while (inp(midiport+1)&MPU401_OK2WR) ;
        outp(midiport+1,cmd) ;
}

int read_mpu401_data()
{
        while (inp(midiport+1)&MPU401_OK2RD) ;
        return inp(midiport) ;
}


int mpu401_UART_mode(int state)
{
        if (state) {                        // ON

                write_mpu401_cmd(MPU401_UART) ;
                return (read_mpu401_data()==MPU401_CMDOK) ;
        }
        else {                              // OFF

                write_mpu401_cmd(MPU401_RESET) ;
                return TRUE ;
        }
}

int reset_mpu401()
{
        int i ;
        write_mpu401_cmd(MPU401_RESET) ;

        for (i=0;i<60000;i++)
                if (read_mpu401_data()==MPU401_CMDOK) return TRUE ;
        return FALSE ;
}

int wait_mpu(int mask)
{
        int i ;
        for (i=0;i<0x7fff;i++)
                if (inp(midiport+1)&mask) return TRUE ;
        return FALSE ;
}


int detect_midi()
{
        outp(midiport+1,0xff) ; // reset MPU
        inp(midiport) ;
        return TRUE ;

}

int init_midi()
{
        int v ;
        reset_mpu401() ;
        if (!detect_midi()) return ;
        printf("MPU401 detected at 0x%3x - Midi output emulation enabled.\n",midiport) ;
        outp(midiport+1,0x3f) ; // UART mode
        inp(midiport) ;
}


int deinit_midi()
{
}

*/

void midi_out(int v)
{
/*
        char b[80] ;
        sprintf(b,"midi out %2x",v&0xff) ;
        OUTDEBUG(b) ;
*/
    SbDspWrite(0x38) ;
    SbDspWrite(v&0xff) ;
}


int init_midi()
{
    return 0;
}

int deinit_midi()
{
    return 0;
}


#endif // SOUND


// [fold]  12
