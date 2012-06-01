#ifdef SOUND
#include <stdlib.h>
#include <stdio.h>

#include "gravis\forte.h"
#include "gravis\gf1proto.h"
#include "gravis\extern.h"
#include "gravis\ultraerr.h"

#define FREQ 22050

ULTRA_CFG config ;               /* configuration (IRQs, DMAs...) de la GUS */
static unsigned long dram_played;/* adr en DRAM du sample jou‚ */
static unsigned long dram_dmaed ;/* adr en DRAM du sample en train d'etre rempli */
static int is16bitdma ;          /* cas special quand on utilise un DMA 16 bit */
static int voice ;               /* voie allou‚e */
static int serving = 0 ;         /* drapeau pour l'IRQ */
extern char *audio_buffer1  ;    /* 2 samples */
extern char *audio_buffer2  ;
extern void common_sound_handler() ;/* routine commune a toutes les cartes son */


int detect_gus(void)            /* teste la pr‚sence d'une GUS, par lecture
                                   de la variable d'environement */
{
        char *penv ;
        if ((penv= (char *)getenv("ULTRASND"))) /* GUS CONFIG */
         if (sscanf(penv,"%x,%d,%d,%d,%d",&config.base_port,
                                          &config.dram_dma_chan,
                                          &config.adc_dma_chan,
                                          &config.gf1_irq_num,
                                          &config.midi_irq_num)) {

                is16bitdma = config.dram_dma_chan > 3 ; /* Cas special DMA 16 bit */
                printf("GRAVIS Ultrasound Detected on Port 0x%3x with Dma channel %d and Irq %d.\n",
                        config.base_port, config.dram_dma_chan, config.gf1_irq_num) ;

                if ((UltraProbe(config.base_port) == NO_ULTRA)||
                    (UltraOpen(&config,14) != ULTRA_OK)) {
                        printf("Failed to init Gravis Ultrasound.\n") ;
                        return 0 ;
                }
        return 1 ;      /* GUS ok */
        }
        return 0 ;      /* Pas de GUS, essayer une autre carte */
}

void WaveHandler(int v)
{
        unsigned int dummy ;

        if ((v!=voice)||serving) return ;       /* evite une eventuelle reentrance */
        serving = 1 ;                           /* pose flag*/

        dummy = dram_played ;                   /* swap les 2 zones de DRAM */
        dram_played = dram_dmaed ;
        dram_dmaed = dummy;
                                                /* joue le sample deja
                                                   copie en DRAM */

        UltraStartVoice(voice,dram_played,dram_played,dram_played+440,0x20) ;
        UltraSetFrequency(voice,FREQ) ;

                                                /* upload le sample1 precedent
                                                   dans la DRAM par DMA */

        UltraDownload(audio_buffer1,0x80,dram_dmaed,441<<is16bitdma,0) ;

                                                /* genere le sample2 */
        common_sound_handler() ;

        dummy = (int)audio_buffer1 ;            /* swap samples */
        audio_buffer1 = audio_buffer2 ;
        audio_buffer2 = (char *)dummy ;
        serving = 0 ;                           /* autorise une autre IRQ */
}

int init_gus()
{
        int i ;

        /* Initialisations diverses
         * Allocation d'une voie
         * Reservation de 2 zones en DRAM pour jouer a 22Khz
         * Installation du Handler
        */

        UltraClearVoices() ;
        for (i=0;i<16;i++) UltraSetVolume(i,0) ;
        if (UltraAllocVoice(-1,&voice)!=ULTRA_OK) return 0 ;
        UltraSetBalance(voice,7) ;
        UltraSetFrequency(voice,FREQ) ;
        UltraSetVolume(voice,4095) ;

        if ((UltraMemAlloc(441<<is16bitdma,&dram_played) != ULTRA_OK)||
            (UltraMemAlloc(441<<is16bitdma,&dram_dmaed) != ULTRA_OK)) return 0 ;

        for (i=0;i<441;i++) {
                UltraPokeData(config.base_port,dram_played+i,0x80) ;
                UltraPokeData(config.base_port,dram_dmaed+i,0x80) ;
        }

        UltraWaveHandler(WaveHandler) ;
        return 1 ;
}

void deinit_gus()
{
        UltraSetVolume(voice,0) ;
        UltraClearVoices() ;
        UltraFreeVoice(voice) ;
        UltraClose() ;
}

void pause_gus(void)
{
        UltraDisableOutput() ;
        UltraStopVoice(voice) ;
}

void continue_gus(void)
{
        UltraEnableOutput() ;
        UltraSetVolume(voice,4095) ;
        UltraStartVoice(voice,dram_played,dram_played,dram_played+440,0x20) ;
}


#endif
