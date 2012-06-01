/* MFP 68901 Emulation
 *
 * 30 april 97 - Started
 *
*/

#include <stdio.h>
#include <assert.h>
#include <conio.h>
#include "cpu68.h"

/*
 * IERA-IERB:
 *
 * Chaque Channel peut etre Authorise/Inhibe en ecrivant un 1 ou un 0
 * dans les Interrupt Enable Registers (iera, ierb). Quand elle est
 * desactivee, une channel est inactive. Tout ce qui declenche normalement
 * une IRQ est ignoree. Toutes les pending interrupts sont effacees.
 * Desactiver un channel n'a pas d'effet sur le bit in-service (isra,isrb).
 *
 * IPRA-IPRB:
 *
 * Quand une interruption survient sur une channel authorisee, son bit du
 * pending register set mis … 1. Quand la channel est acknoledged, le bit
 * correspondant est effacee. Une pending interrupt peut aussi etre effacee
 * sans passer par la phase d'acknoledgement en ecrivant un ZERO dans le bit
 * correspondant. (Ecrire un UN ne fait rien). Lecture authorise.
 *
 *
 * IMRA-IMRB:
 *
 * Sont utilises pour empecher une channel de faire une Interrupt Request.
 * Ecrire un zero dans le bit correspondant de (imra, imrb) autorisera le
 * canal a recevoir une interrupt et a le latcher dans son pending bit (si
 * le canal est authorise par iera-ierb) MAIS l'empechera de faire une
 * Interrupt Request (si elle est en train de le faire au momment du passage
 * du bit imra-imrb … zero, l'Interrupt Request est supprim‚e). Si le mask
 * (imra, imrb) est remis a 1, les pending interrupts reprennent dans la
 * mesure des priorites. Lecture Authorise.
 *
 *
 * ISRA-ISRB:
 *
 * Il y a 2 MODES DE FIN D'INTERRUPTION: Automatique & software, selectionne
 * en ecrivant un 1 ou 0 dans le bit S du Vector Register.
 * Si S=1, on est en software end-of-interrupt mode. Si le bit S est a 0,
 * tous les canaux operent en mode automatique, et un reset est fait sur tous
 * les in-service bits. En mode automatique, le pending-bit est efface des
 * que le canal passe son vecteur: A ce momment la, il n'y a plus de trace de
 * cette interruption dans le MFP.
 * En mode software, le in-service bit est mis et le pending bit est efface
 * quand le canal passe son vecteur. Avec le in-service bit mis, les canaux
 * de plus basse priorite ne sont pas authorises a passer leur vecteur ou
 * faire un Interrupt Request. Le bit in-service doit etre efface a la fin
 * de l'interruption. Si une autre interruption survient pendant que le bit
 * in-service est mis, elle est quand meme latchee dans le pending bit, et
 * en attente. isra-isrb ne peuvent pas etre mis a un par software.
 *
 * Tous les canaux repondent avec un vecteur 8 bits qd acknoledge. Les 4 bits
 * de poids forts proviennent de VR, les 4 bits de poids faibles dependent du
 * canal.
 *
*/

/*
extern void mfp_request(int channel) ;
extern void mfp_acknoledge(int channel) ;

struct ttimer {
#pragma pack (1) ;
        UBYTE mode;
        UBYTE data ;
        UWORD channel ;
        int cycle2go;
        unsigned int freq;
        unsigned int predivisedfreq ;
        unsigned int cyclecumul ;
        unsigned int cycleperiod ;
        unsigned int cyclestart ;
        unsigned int cycleend ;
} ;

struct info_mfp {
#pragma pack (1) ;

        UBYTE   gpip ;
        UBYTE   aer ;
        UBYTE   ddr ;

        union iregister ier ;
        union iregister ipr ;
        union iregister isr ;
        union iregister imr ;

        union iregister rasterline_events ;

        UBYTE   vr ;

        UBYTE   tacr ;
        UBYTE   tbcr ;
        UBYTE   tcdcr ;

        UBYTE  tbdr ;
        UBYTE  soft_eoi ;

        struct ttimer timers[4] ;

        int     next_timer ;     // timer number for next event
        int     next_cycles ;


        char dummy[64] ;
} ;


extern int timer_cycle2go ;
extern int timer_cycle2go_start  ;
extern int nbtimer_cycle2go ;
*/



char temp[100] ;

extern int lowraster_max ;

struct {int mode; int prediv;} Timer_Table[16] = {
        {TIMERMODE_STOPPED, 0},
        {TIMERMODE_DELAY, 4},
        {TIMERMODE_DELAY, 10},
        {TIMERMODE_DELAY, 16},
        {TIMERMODE_DELAY, 50},
        {TIMERMODE_DELAY, 64},
        {TIMERMODE_DELAY, 100},
        {TIMERMODE_DELAY, 200},
        {TIMERMODE_EVENTCOUNT, 1},
        {TIMERMODE_PULSEWIDTH, 4},
        {TIMERMODE_PULSEWIDTH, 10},
        {TIMERMODE_PULSEWIDTH, 16},
        {TIMERMODE_PULSEWIDTH, 50},
        {TIMERMODE_PULSEWIDTH, 64},
        {TIMERMODE_PULSEWIDTH, 100},
        {TIMERMODE_PULSEWIDTH, 200}
} ;

extern unsigned int Cycles_Per_RasterLine ;
struct ttimer *tima,*timb, *timc, *timd ;

/* Variables r‚element importantes */

unsigned int event_cycles_2_go ;
unsigned int event_cycles_2_go_base ;
unsigned int event_type ;        //1=timer a, 2=timer b..
unsigned int event_timer_mask ;  // 16 bits, suivant chaque channel,
                                // indique les channels des timers non stopp‚s


unsigned int timera_cycles_2_go = 10000;
unsigned int timerb_cycles_2_go = 10000;
unsigned int timerc_cycles_2_go = 10000;
unsigned int timerd_cycles_2_go = 10000;

/****************************************/



///////////////////////////////////
int timers_this_raster = 0;
int next_timer_this_raster = 0 ;
        /*
                timers_this_raster = ma ;
                next_timer_this_raster = ti ;
                processor->Cycles_2_Go = c2go ;
        } else processor->Cycles_2_Go = 9999999 ;
//////////////////////////////////*/

void rethink_mfp()
{

}

void calc_timer_freq(int timer, int control)
{
        unsigned int freq = 0 ;
        struct ttimer *ttime = &mfp.timers[timer] ;
        unsigned int div = mfp.timers[timer].data ;

        if (!div) div=0x100 ;
        switch (ttime->mode = Timer_Table[control].mode) {
                case TIMERMODE_DELAY :
                case TIMERMODE_EVENTCOUNT:
                case TIMERMODE_PULSEWIDTH:

                        freq = MFP_FREQ / Timer_Table[control].prediv ;
                        ttime->predivisedfreq = freq ;
                        freq /= div ;
                        ttime->freq = freq ;

                        mfp.timers[timer].cyclecumul = 0 ;
                        ttime->cycleperiod = ((50*313*512)/freq)+1 ;

                        ttime->cycle2go = ttime->cycleperiod ;
                        ttime->cyclestart = total_cycles
                                          + Cycles_Per_RasterLine
                                          - processor->Cycles_2_Go ;


                        /* par d‚faut, le timer courrant est utilis‚ */

//                        if (event_cycles_2_go)


//                        ttime->cyclestart = total_cycles + thisraster_cycles ;
//                        ttime->cycleend= ttime->cyclestart+ttime->cycleperiod ;
//
//                        mfp_timers_rethink() ;
//                        mfp_timers_sort() ;

                        break ;
                case TIMERMODE_STOPPED :
                        ttime->cycleperiod = 0 ;
                        ttime->cycle2go = 0x7fffff ;
                        break ;

                }
                /* si c'etait le timer prochain, annuler et recalculer
                        if (event_type == ttime->channel) {
                                event_mask &= ~(1<<ttime->channel)
                                event_type = 0 ;
                                rethink_mfp() ;

                        }
                        break ;
*/
        switch(timer) {
                case 0 : timera_cycles_2_go = ttime->cycle2go ; break ;
                case 1 : timera_cycles_2_go = ttime->cycle2go ; break ;
                case 2 : timera_cycles_2_go = ttime->cycle2go ; break ;
                case 3 : timera_cycles_2_go = ttime->cycle2go ; break ;
        }
#ifdef DEBUG
{ char b[80] ;
sprintf(b,"\tTIMER %c FREQ SET - mode=0x%02x data=0x%02x frq=%d cycles=%d",timer+'A',Timer_Table[control].mode,div,freq,ttime->cycle2go) ;
OUTDEBUG(b) ;}
#endif

}

UBYTE calc_timer_data(int timer)
{
        UBYTE v ;
        struct ttimer *pt = &mfp.timers[timer] ;


        switch(timer) {
                case 0 : pt->cycle2go = timera_cycles_2_go ; break ;
                case 1 : pt->cycle2go = timerb_cycles_2_go ; break ;
                case 2 : pt->cycle2go = timerc_cycles_2_go ; break ;
                case 3 : pt->cycle2go = timerd_cycles_2_go ; break ;
        } ;

        if (!pt->mode)
                v=pt->data ;

        else if ((timer==1)&&(pt->mode == TIMERMODE_EVENTCOUNT))
                v=mfp.tbdr ;

        else v = pt->data - (pt->data*pt->cycle2go/pt->cycleperiod) ;

/*
        #ifdef DEBUG
        { char b[80] ;
        sprintf(b,"\tTimer %c DATA = %x",timer+'A',v) ;
        OUTDEBUG(b) ;}
        #endif
*/


//        assert(v<=pt->data) ;

        return v ;
}

void Init_MFP(void)
{
        tima = &mfp.timers[0] ;
        timb = &mfp.timers[1] ;
        timc = &mfp.timers[2] ;
        timd = &mfp.timers[3] ;

        mfp.ier.ab = mfp.ipr.ab = mfp.imr.ab = 0 ;
        mfp.soft_eoi = TRUE ;

        tima->channel = MFP_TIMERA ;
        timb->channel = MFP_TIMERB ;
        timc->channel = MFP_TIMERC ;
        timd->channel = MFP_TIMERD ;

        timer_cycle2go_start = 0x7fffffff ;
        timer_cycle2go = 0x7fffffff ;
}

void mfp_trigger(int channel)
{
        switch (channel) {
                case MFP_TIMERA:
                        processor->events_mask |= MASK_TIMERA ;
                        break ;
                case MFP_TIMERB:
                        processor->events_mask |= MASK_TIMERB ;
                        break ;
                case MFP_TIMERC:
                        processor->events_mask |= MASK_TIMERC ;
                        break ;
                case MFP_TIMERD:
                        processor->events_mask |= MASK_TIMERD ;
                        break ;
                case MFP_ACIA:
                        processor->events_mask |= MASK_ACIA ;
                        break ;
                case MFP_FDC:
        #ifdef DEBUG
        { char b[80] ;
        sprintf(b,"\tMFP FDC triggered") ;
        OUTDEBUG(b) ;}
        #endif

                        processor->events_mask |= MASK_FDC ;
                        break ;
       }

}


void mfp_request(int channel)
{
        UWORD msk = 1<<channel ;

        if (channel >4)
        #ifdef DEBUG
        { char b[80] ;
        sprintf(b,"\tMFP request channel %d",channel) ;
        OUTDEBUG(b) ;}
        #endif


        if (!(mfp.ier.ab&msk))           // not enabled -> nothing
                return ;

        if ((mfp.ipr.ab&msk))             // already pending
                return ;

        mfp.ipr.ab |= msk ;

        if (!(mfp.imr.ab&msk))             // not masked -> no irq
                return ;

        if (mfp.soft_eoi&&(mfp.isr.ab&msk))
                return ;

        mfp_trigger(channel) ;
}

void mfp_acknoledge(int channel)
{
        UWORD msk = 1<<channel ;

        mfp.ipr.ab &= ~msk ;   // no more pending
        if (mfp.soft_eoi)
                mfp.isr.ab |= msk ;    // in service
}

/*
void mfp_something_happens(void)
{
        int channel ;
        int i ;

        if (nbtimer_cycle2go > 3) {
                timer_cycle2go = 0x7ffffff ;
                return ;
        }

        channel = mfp.timers[nbtimer_cycle2go].channel ;
        mfp_request(channel) ;

        if ((tima->mode&1)&&(mfp.ier.ab&(1<<MFP_TIMERA)))
                if (nbtimer_cycle2go == 0)
                        tima->cycle2go = timer_cycle2go+tima->cycleperiod ;
                else
                        tima->cycle2go -= timer_cycle2go_start ;

        if ((timb->mode&1)&&(mfp.ier.ab&(1<<MFP_TIMERB)))
                if (nbtimer_cycle2go == 1)
                        timb->cycle2go = timer_cycle2go+timb->cycleperiod ;
                else
                        timb->cycle2go -= timer_cycle2go_start ;

        if ((timc->mode&1)&&(mfp.ier.ab&(1<<MFP_TIMERC)))
                if (nbtimer_cycle2go == 2)
                        timc->cycle2go = timer_cycle2go+timc->cycleperiod ;
                else
                        timc->cycle2go -= timer_cycle2go_start ;

        if ((timd->mode&1)&&(mfp.ier.ab&(1<<MFP_TIMERD)))
                if (nbtimer_cycle2go == 3)
                        timd->cycle2go = timer_cycle2go+timd->cycleperiod ;
                else
                        timd->cycle2go -= timer_cycle2go_start ;

        mfp_timers_sort() ;
        return ;
}
*/


void timers_on_rasterline(void)
{
        if (!tima->mode||(!mfp.ier.ab&(1<<MFP_TIMERA)))
                timera_cycles_2_go = 0x7ffff ;
        if (!timc->mode||(!mfp.ier.ab&(1<<MFP_TIMERC)))
                timerc_cycles_2_go = 0x7ffff ;
        if (!timd->mode||(!mfp.ier.ab&(1<<MFP_TIMERD)))
                timera_cycles_2_go = 0x7ffff ;

         switch(timb->mode) {
                case TIMERMODE_DELAY:
                case TIMERMODE_PULSEWIDTH:
                        break ;
                case TIMERMODE_EVENTCOUNT:
                        if ((RasterLine>=0x34)&&(RasterLine<=0xf9)) {
                                if (mfp.tbdr-- == 1) {
                                        mfp.tbdr = timb->data ;
                                }
                        }
                        break ;
                case TIMERMODE_STOPPED:
                        timerb_cycles_2_go = 0x7ffff ;
                        break ;
        }
}

void event_timer_a_c()
{

        #ifdef DEBUG
        { char b[80] ;
        sprintf(b,"\tTIMERA reached") ;
        OUTDEBUG(b) ;}
        #endif

        if (!tima->mode||(!mfp.ier.ab&(1<<MFP_TIMERA)))
                timera_cycles_2_go = 0x7ffff ;
        else    timera_cycles_2_go += tima->cycleperiod ;


        mfp_request(tima->channel) ;
}
void event_timer_b_c()
{
        #ifdef DEBUG
        { char b[80] ;
        sprintf(b,"\tTIMERB reached") ;
        OUTDEBUG(b) ;}
        #endif

        if (!tima->mode||(!mfp.ier.ab&(1<<MFP_TIMERA)))
                timerb_cycles_2_go = 0x7ffff ;
        else    timerb_cycles_2_go += timb->cycleperiod ;

        mfp_request(timb->channel) ;}

void event_timer_c_c()
{
        #ifdef DEBUG
        { char b[80] ;
        sprintf(b,"\tTIMERC reached") ;
        OUTDEBUG(b) ;}
        #endif

        if (!timc->mode||(!mfp.ier.ab&(1<<MFP_TIMERC)))
                timerc_cycles_2_go = 0x7ffff ;
        else    timerc_cycles_2_go += timc->cycleperiod ;

        mfp_request(timc->channel) ;
}

void event_timer_d_c()
{
/*
        #ifdef DEBUG
        { char b[80] ;
        sprintf(b,"\tTIMERD reached") ;
        OUTDEBUG(b) ;}
        #endif
*/
        if (!timd->mode||(!mfp.ier.ab&(1<<MFP_TIMERD)))
                timerd_cycles_2_go = 0x7ffff ;
        else    timerd_cycles_2_go += timd->cycleperiod ;

        mfp_request(timd->channel) ;
}


void Timer_Works(void)
{
//        int i ;
        int c2go,ti ;
        int ma = 0 ;
//        struct ttimer *pt ;

        c2go = 513 ;

        if (tima->mode&&(mfp.ier.ab&(1<<MFP_TIMERA))) {
                tima->cycle2go -= 512 ;
                if (tima->cycle2go < c2go) {
                        ti = 1 ;
                        ma |= 1 ;
                        c2go = tima->cycle2go ;
                }
        }

         switch(timb->mode) {
                case TIMERMODE_DELAY:
                case TIMERMODE_PULSEWIDTH:
                        timb->cycle2go -= 512 ;
                        if (timb->cycle2go < c2go) {
                                ti = 2 ;
                                ma |= 2 ;
                                c2go = timb->cycle2go ;
                        }
                        break ;
                case TIMERMODE_EVENTCOUNT:
                        if ((RasterLine>=0x34)&&(RasterLine<=0xf9)) {
                                if (mfp.tbdr-- == 1) {
                                        mfp.tbdr = timb->data ;
                                        ma |= 2 ;
                                        ti = 2 ;
                                        c2go = 1 ;
                                }
                        }
                        break ;
        }


        if (timc->mode&&(mfp.ier.ab&(1<<MFP_TIMERC))) {
                timc->cycle2go -= 512 ;
                if (timc->cycle2go < c2go) {
                        ti = 3 ;
                        ma |= 4 ;
                        c2go = timc->cycle2go ;
                }
        }

        if (ma) {
                timers_this_raster = ma ;
                next_timer_this_raster = ti ;
                processor->Cycles_2_Go = c2go ;
        } else processor->Cycles_2_Go = 9999999 ;


#ifdef DEBUG
{ char b[80] ;
sprintf(b,"\tTIMER WORKS RASTER %d timers=%x nbtimer=%x cycles=%d",RasterLine,ma,ti,processor->Cycles_2_Go) ;
OUTDEBUG(b) ;}
#endif

}
/*
	elapsed_cycles = 512 (ou cycles_2_go_start) - cycles_2_go

	si timer_latched[min_nb_timer_raster]
		-> pending

	fsi

	timer_x_cycles_2_go += timer_x_cycles_period
	si timer_x_cycles_2_go < cycles_2_go

		; une autre occurence de *CE* timer avant la fin

	else
		; sinon supprime le mask

		mask_timer_raster &= 1<<x

	endif


	si mask_timer_raster != 0

		; un autre timer avant la fin

		min_cycles_timer_raster = 512 ;

		si mask&1

			min_cycles_timer_raster = timer_a_cycles_2_go-elapsed_cycles ;
			min_nb_timer_raster = 1 ;
			ASSERT(min_cycles_timer_raster >0)
		fsi
		si mask&2
			si min_cycles_timer_raster > timer_b_cycles_2_go-elapsed_cycles
				min_cycles_timer_raster = timer_b_cycles_2_go-elapsed_cycles
				min_nb_timer_raster = 2 ;

		fsi
		....

	fsi

*/

void mfp_timer_reached()
{

#ifdef DEBUG
{ char b[80] ;
sprintf(b,"\tMFP TIMER REACHED") ;
OUTDEBUG(b) ;}
#endif


        if (next_timer_this_raster==1) {
                mfp_request(MFP_TIMERA) ;
                tima->cycle2go += tima->cycleperiod ;
                if (tima->cycle2go > processor->Cycles_This_Raster)
                        timers_this_raster &= ~1 ;
        }
        else if (next_timer_this_raster==2) {
                mfp_request(MFP_TIMERB) ;
                timers_this_raster &= ~2 ;

        }
        else if (next_timer_this_raster==3) {
                mfp_request(MFP_TIMERC) ;
                timc->cycle2go += timc->cycleperiod ;
                if (timc->cycle2go > processor->Cycles_This_Raster)
                        timers_this_raster &= ~4 ;

        }
        else if (next_timer_this_raster==4) {
                mfp_request(MFP_TIMERD) ;

        }

        processor->Cycles_2_Go = 10000 ;
        if (!timers_this_raster) {
                return ;
        }

        if (timers_this_raster&1)
                if (processor->Cycles_2_Go > tima->cycle2go) {
                        processor->Cycles_2_Go = tima->cycle2go ;
                        next_timer_this_raster = 0 ;
                }

        if (timers_this_raster&4)
                if (processor->Cycles_2_Go > timc->cycle2go) {
                        processor->Cycles_2_Go = timc->cycle2go ;
                        next_timer_this_raster = 2 ;
                }
}

void latch_pending(UWORD latchmask)   // latch previous pending
{
        int i ;

        for (i=0;i<16;i++)
                if (latchmask&(1<<i)) mfp_trigger(i) ;
}

void poke_imra(UBYTE b)
{
        union iregister prev ;

        prev.ab = mfp.imr.ab ;
        mfp.imr.a = b ;

        if ((mfp.imr.a&~prev.a)&mfp.ier.a&mfp.ipr.a&~mfp.isr.a)
                latch_pending(mfp.imr.ab&mfp.ipr.ab&~prev.ab) ;
}

void poke_imrb(UBYTE b)
{
        union iregister prev ;
        prev.ab = mfp.imr.ab ;
        mfp.imr.b = b ;

        if ((mfp.imr.b&~prev.b)&mfp.ier.a&mfp.ipr.b&~mfp.isr.b)
                latch_pending(mfp.imr.ab&mfp.ipr.ab&~prev.ab) ;
}

void poke_iera(UBYTE b)
{
        mfp.ier.a = b ;
        mfp.ipr.a &= b ;        // clear pendings
}

void poke_ierb(UBYTE b)
{
        mfp.ier.b = b ;
        mfp.ipr.a &= b ;        // clear pendings

}

UBYTE peek_iera(void)
{
        return mfp.ier.a ;
}

UBYTE peek_ierb(void)
{
        return mfp.ier.b ;
}

void poke_ipra(UBYTE b)
{
        mfp.ipr.a &= b ;
}

void poke_iprb(UBYTE b)
{
        mfp.ipr.b &= b ;
}

UBYTE peek_ipra(void)
{
        return mfp.ipr.a ;
}

UBYTE peek_iprb(void)
{
        return mfp.ipr.b ;
}


UBYTE peek_imra()
{
        return mfp.imr.a ;
}

UBYTE peek_imrb()
{
        return mfp.imr.b ;
}

void poke_isra(UBYTE b)
{
        union iregister needlatch ;
        mfp.isr.a &= b ;

        needlatch.ab = (mfp.ier.ab&mfp.imr.ab&mfp.ipr.ab&~mfp.isr.ab) ;

        if (needlatch.a)
                latch_pending(needlatch.ab) ;
}

void poke_isrb(UBYTE b)
{
        union iregister needlatch ;
        mfp.isr.b &= b ;
/*
        if (mfp.ier.ab&mfp.imr.ab&mfp.ipr.ab&~mfp.isr.ab)
                latch_pending(mfp.ipr.ab) ;
*/
        needlatch.ab = (mfp.ier.ab&mfp.imr.ab&mfp.ipr.ab&~mfp.isr.ab) ;

        if (needlatch.b)
                latch_pending(needlatch.ab) ;

}

UBYTE peek_isra()
{
        return mfp.isr.a ;
}

UBYTE peek_isrb()
{
        return mfp.isr.b ;
}

void poke_vr(UBYTE b)
{
        mfp.vr = b ;
        mfp.soft_eoi = (mfp.vr&8)==8 ;
}

UBYTE peek_vr()
{
        return mfp.vr ;
}

void poke_tacr(UBYTE b)
{
        mfp.tacr = b ;
        calc_timer_freq(0,mfp.tacr&15) ;
}

void poke_tbcr(UBYTE b)
{
        mfp.tbcr = b ;
        calc_timer_freq(1,mfp.tbcr&15) ;
}

void poke_tcdcr(UBYTE b)
{
        mfp.tcdcr = b ;
        calc_timer_freq(2,(mfp.tcdcr>>4)&7) ;
        calc_timer_freq(3,mfp.tcdcr&7) ;
}

UBYTE peek_tacr()
{
        return mfp.tacr ;
}

UBYTE peek_tbcr()
{
        return mfp.tbcr ;
}

UBYTE peek_tcdcr()
{
        return mfp.tcdcr ;
}

void poke_tadr(UBYTE b)
{
        mfp.timers[0].data = b ;
        calc_timer_freq(0,mfp.tacr&15) ;
}
void poke_tbdr(UBYTE b)
{
        mfp.timers[1].data = b ;
        if (!mfp.timers[1].mode) mfp.tbdr = b ;
        calc_timer_freq(1,mfp.tbcr&15) ;
}
void poke_tcdr(UBYTE b)
{
        mfp.timers[2].data = b ;
        calc_timer_freq(2,(mfp.tcdcr>>4)&7) ;
}
void poke_tddr(UBYTE b)
{
        mfp.timers[3].data = b ;
        calc_timer_freq(3,mfp.tcdcr&7) ;
}

UBYTE peek_tadr(void)
{
        return calc_timer_data(0) ;
}

UBYTE peek_tbdr(void)
{
        return calc_timer_data(1) ;
}
UBYTE peek_tcdr(void)
{
        return calc_timer_data(2) ;
}
UBYTE peek_tddr(void)
{
        return calc_timer_data(3) ;
}

UBYTE peek_gpip(void)
{
        UBYTE v,p ;

        v=IsMonochrome?0:0x80 ;

        if (isParallel) {
                p=inp(0x379) ;    // printer status reg
                if (!(p&0x10)) v++ ;
        }

        return (mfp.gpip&~0x81)|v ;
}


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³                                                               POKE MFP
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

void poke_mfp(MPTR ad, UBYTE b)
{
        switch(ad&0x3f) {
                case 0x01 :
                case 0x03 :
                case 0x05 :
                        break ;
                case 0x07 :
                        poke_iera(b) ;
                        break ;
                case 0x09 :
                        poke_ierb(b) ;
                        break ;
                case 0x0b :
                        poke_ipra(b) ;
                        break ;
                case 0x0d :
                        poke_iprb(b) ;
                        break ;
                case 0x0f :
                        poke_isra(b) ;
                        break ;
                case 0x11 :
                        poke_isrb(b) ;
                        break ;
                case 0x13 :
                        poke_imra(b) ;
                        break ;
                case 0x15 :
                        poke_imrb(b) ;
                        break ;
                case 0x17 :
                        poke_vr(b) ;
                        break ;
                case 0x19 :
                        poke_tacr(b) ;
                        break ;
                case 0x1b :
                        poke_tbcr(b) ;
                        break ;
                case 0x1d :
                        poke_tcdcr(b) ;
                        break ;
                case 0x1f :
                        poke_tadr(b) ;
                        break ;
                case 0x21 :
                        poke_tbdr(b) ;
                        break ;
                case 0x23 :
                        poke_tcdr(b) ;
                        break ;
                case 0x25 :
                        poke_tddr(b) ;
                        break ;
                case 0x27 :
                case 0x29 :
                case 0x2b :
                case 0x2d :
                case 0x2f :
                        break ;
        }
}

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³                                                               PEEK MFP
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

UBYTE peek_mfp(MPTR ad)
{
        switch(ad&0x3f) {
                case 0x01 :
                        return peek_gpip() ;
                case 0x03 :
                case 0x05 :
                        break ;
                case 0x07 :
                        return peek_iera() ;
                case 0x09 :
                        return peek_ierb() ;
                case 0x0b :
                        return peek_ipra() ;
                case 0x0d :
                        return peek_iprb() ;
                case 0x0f :
                        return peek_isra() ;
                case 0x11 :
                        return peek_isrb() ;
                case 0x13 :
                        return peek_imra() ;
                case 0x15 :
                        return peek_imrb() ;
                case 0x17 :
                        return peek_vr() ;
                case 0x19 :
                        return peek_tacr() ;
                case 0x1b :
                        return peek_tbcr() ;
                case 0x1d :
                        return peek_tcdcr() ;
                case 0x1f :
                        return peek_tadr() ;
                case 0x21 :
                        return peek_tbdr() ;
                case 0x23 :
                        return peek_tcdr() ;
                case 0x25 :
                        return peek_tddr() ;
                case 0x27 :
                case 0x29 :
                case 0x2b :
                case 0x2d :
                case 0x2f :
                        break ;
        }
        return 0 ;
}


/*
void mfp_timers_rethink()
{
        int i ;
        for (i=0;i<4;i++) if ((mfp.timers[i].mode&1)&&(mfp.ier.ab&(1<<mfp.timers[i].channel)))
                mfp.timers[i].cycle2go -= timer_cycle2go_start-timer_cycle2go ;
}
*/
/*
void mfp_timers_sort() // reorder timer
{
        int i ;
        timer_cycle2go = 0x7fffffff ;

        nbtimer_cycle2go = 5 ;
        for (i=0;i<4;i++)
                if ((mfp.timers[i].mode&1)&&
                    (mfp.timers[i].cycle2go < timer_cycle2go))
                {
                        nbtimer_cycle2go = i ;
                        timer_cycle2go = mfp.timers[i].cycle2go ;
                }
        timer_cycle2go_start = timer_cycle2go ;
}
*/

