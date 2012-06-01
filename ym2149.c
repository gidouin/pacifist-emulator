/*****************************************************************************
//
//                ЫЫї ЫЫї Ыї   Ыї  ЫЫЫЫї    ЫЫї   ЫЫї      ЫЫЫЫї
//                ЫЫі ЫЫі ЫЫї ЫЫі ЫЫЪДЫЫї  ЫЫЫі   ЫЫіЫЫї  ЫЫЪДЫЫї
//                АЫЫЫЫЪЩ ЫЫЫЫЫЫі АДЩЫЫЪЩ ЫЫЫЫі   ЫЫЫЫЫЫї АЫЫЫЫЫі
//                 АЫЫЪЩ  ЫЫЪДЫЫі   ЫЫЪЩ  АДЫЫі   АДДЫЫЪЩ  АДДЫЫі
//                  ЫЫі   ЫЫі ЫЫі ЫЫЫЫЫЫї ЫЫЫЫЫЫї    ЫЫі  ЫЫЫЫЫЪЩ
//                  АДЩ   АДЩ АДЩ АДДДДДЩ АДДДДДЩ    АДЩ  АДДДДЩ
//
//        ЫЫЫЫЫЫї Ыї   Ыї ЫЫї ЫЫї ЫЫї     ЫЫЫЫЫЫї ЫЫЫЫЫЫї ЫЫЫЫЫЫї ЫЫЫЫЫЫї
//        ЫЫЪДДДЩ ЫЫї ЫЫі ЫЫі ЫЫі ЫЫі     ЫЫЪДЫЫі АДЫЫЪДЩ ЫЫЪДЫЫі ЫЫЪДЫЫі
//        ЫЫЫЫЫї  ЫЫЫЫЫЫі ЫЫі ЫЫі ЫЫі     ЫЫЫЫЫЫі   ЫЫі   ЫЫі ЫЫі ЫЫЫЫЫЫі
//        ЫЫЪДДЩ  ЫЫЪДЫЫі ЫЫі ЫЫі ЫЫі     ЫЫЪДЫЫі   ЫЫі   ЫЫі ЫЫі ЫЫЪЫЫЪЩ
//        ЫЫЫЫЫЫї ЫЫі ЫЫі ЫЫЫЫЫЫі ЫЫЫЫЫЫї ЫЫі ЫЫі   ЫЫі   ЫЫЫЫЫЫі ЫЫіАЫЫї
//        АДДДДДЩ АДЩ АДЩ АДДДДДЩ АДДДДДЩ АДЩ АДЩ   АДЩ   АДДДДДЩ АДЩ АДЩ
//
//
//			   (C) Written by Arnaud Carre (Leonard/OXYGENE)
//
//	Version ‚pur‚e pour PaCiFiSt:
//	Removed:
//
//		- Plus de gestion du player.
//		- R‚solution des echantillons fixe. (8bits)
//		- Plus de digidrum MADMAX.
//		- Plus de gestion des fichiers YM. (Decompression LHArc)
//		- Plus de type de synthese differents. (que du carr‚)
//
//	Finalement il reste plus grand chose !!!!
//
//
*****************************************************************************/
#include <stdlib.h>
#include <stdio.h>

#include "ym2149.h"					// Emulation YM2149

//-----------------------------------------------------------
// Globales
//-----------------------------------------------------------
static	ymreg_t YmRegs;
static	int	BufferVoice[1024*3];
static	int	Noise[1024];
static	int	BufferEnv[1024];
static	int	PredefEnv[16*(ENV_SIZE*4)];
static	SW	mixTabBuffer[256*3];
static	UB	*pMix8 = ((UB*)mixTabBuffer);
static	int	NoiseTable[NOISESIZE];
static	UD	NoisePos,StepNoise;
static	SD	EnvPos,StepEnv;
static	SD	sampleToCompute = 22050/50 ;

//static	SD	sampleToCompute = 22222/50 ;

static	int	innerSamplePos = 0;
static	UB	*innerOutDataPtr;
static	int	ymVersion;


// YM-Emulation Add parameters.
static	int	*tuneWave=NULL;
static	int	SquareWave[TUNESIZE];
// Table des volumes logarithmiques mesur‚s … l'oscillo:
#define	MKW(a)	((a*65535)/0x40)
int	volumeTableA[16];
int volumeTableB[16]={MKW(0x00),MKW(0x01),MKW(0x02),MKW(0x03),MKW(0x04),MKW(0x06),MKW(0x08),MKW(0x0a),
					 MKW(0x0b),MKW(0x0d),MKW(0x0f),MKW(0x10),MKW(0x13),MKW(0x1e),MKW(0x2c),MKW(0x40)};
int	volumeTableC[16]={0<<12,1<<12,2<<12,3<<12,4<<12,5<<12,6<<12,7<<12,8<<12,9<<12,10<<12,11<<12,12<<12,13<<12,14<<12,15<<12};
static	int	*pVolumeTable = volumeTableA;
// Codage des 16 formes d'enveloppe.
UB Env00xx[8]={ 1,0,0,0,0,0,0,0 };
UB Env01xx[8]={ 0,1,0,0,0,0,0,0 };
UB Env1000[8]={ 1,0,1,0,1,0,1,0 };
UB Env1001[8]={ 1,0,0,0,0,0,0,0 };
UB Env1010[8]={ 1,0,0,1,1,0,0,1 };
UB Env1011[8]={ 1,0,1,1,1,1,1,1 };
UB Env1100[8]={ 0,1,0,1,0,1,0,1 };
UB Env1101[8]={ 0,1,1,1,1,1,1,1 };
UB Env1110[8]={ 0,1,1,0,0,1,1,0 };
UB Env1111[8]={ 0,1,0,0,0,0,0,0 };
UB *EnvWave[16] = {	&Env00xx,&Env00xx,&Env00xx,&Env00xx,
					&Env01xx,&Env01xx,&Env01xx,&Env01xx,
					&Env1000,&Env1001,&Env1010,&Env1011,
					&Env1100,&Env1101,&Env1110,&Env1111};
static	char	*copyright="Yamaha 2149 Chip emulator written by Arnaud Carre (LEONARD/OXYGENE).";




//*****************************************************************************
//                ЫЫї ЫЫї Ыї   Ыї  ЫЫЫЫї    ЫЫї   ЫЫї      ЫЫЫЫї
//                ЫЫі ЫЫі ЫЫї ЫЫі ЫЫЪДЫЫї  ЫЫЫі   ЫЫіЫЫї  ЫЫЪДЫЫї
//                АЫЫЫЫЪЩ ЫЫЫЫЫЫі АДЩЫЫЪЩ ЫЫЫЫі   ЫЫЫЫЫЫї АЫЫЫЫЫі
//                 АЫЫЪЩ  ЫЫЪДЫЫі   ЫЫЪЩ  АДЫЫі   АДДЫЫЪЩ  АДДЫЫі
//                  ЫЫі   ЫЫі ЫЫі ЫЫЫЫЫЫї ЫЫЫЫЫЫї    ЫЫі  ЫЫЫЫЫЪЩ
//                  АДЩ   АДЩ АДЩ АДДДДДЩ АДДДДДЩ    АДЩ  АДДДДЩ
//*****************************************************************************

/*
void	Ym2149Compute(void *pDataOut,SD _nbSample)
 {


		innerOutDataPtr = (UB*)pDataOut;
		do
		{
			// Nb de sample … calculer avant l'appel de Player
			sampleToCompute = NBSAMPLE-innerSamplePos;
			// Test si la fin du buffer arrive avant la fin de sampleToCompute
			if (sampleToCompute>_nbSample)
			{
				sampleToCompute = _nbSample;
			}
			innerSamplePos += sampleToCompute;
			if (innerSamplePos>=NBSAMPLE)
			{
//				Player();			// Lecture de la partition.
				innerSamplePos -= NBSAMPLE;
			}
			if (sampleToCompute>0)
			{
				YmEmulator();		// Creation du micro-sample.
			}
			_nbSample -= sampleToCompute;
		}
		while (_nbSample>0);
 }
*/

void	Ym2149Init(void)
 {
 int	i;
 UD	n=65535;


		for (i=0;i<256*3;i++)
		{
//			pMix8[i]=i/3;
			pMix8[i]=((i*2)/9) + 42;			// 2/3 de puissance.
		}

		memset(&YmRegs,0,sizeof(ymreg_t));
		YmRegs.Channel[VOICE_A].VoiceOn = TRUE;
		YmRegs.Channel[VOICE_B].VoiceOn = TRUE;
		YmRegs.Channel[VOICE_C].VoiceOn = TRUE;

		for (i=0;i<16;i++)
		{
			volumeTableA[15-i] = n;
			n = (n*46341)>>16;			// (1/sqr(2))<<16 = 46341
		}

		NoiseInit();
		TuneInit();
		EnvInit();
		tuneWave=SquareWave;
 }

void	Ym2149registerRead(unsigned char *ptr,BOOL bReg13Write)
{
		YmRegs.Channel[VOICE_A].finetune = ptr[0];
		YmRegs.Channel[VOICE_A].crsetune = ptr[1]&0xf;
		YmRegs.Channel[VOICE_B].finetune = ptr[2];
		YmRegs.Channel[VOICE_B].crsetune = ptr[3]&0xf;
		YmRegs.Channel[VOICE_C].finetune = ptr[4];
		YmRegs.Channel[VOICE_C].crsetune = ptr[5]&0xf;
		YmRegs.NoiseControl = ptr[6]&0x1f;
		YmRegs.MixerControl = ptr[7];
		YmRegs.Channel[VOICE_A].Volume = ptr[ 8]&0x1f;
		YmRegs.Channel[VOICE_B].Volume = ptr[ 9]&0x1f;
		YmRegs.Channel[VOICE_C].Volume = ptr[10]&0x1f;
	    YmRegs.EnvLowPeriod      = ptr[11];
	    YmRegs.EnvHighPeriod     = ptr[12];
		if (bReg13Write)
		{
			EnvPos = (ENV_START<<16);		// Restart l'enveloppe quand ecriture dans registre 13.
	    	YmRegs.EnvShape = ptr[13]&0xf;
		}
}



void	YmEmulator(char *buffer)
 {
 int	i;
 int	*pEnv,*pEnv2;
 UD	EnvPeriod;



		// Calcul la table de bruit blanc pour la VBL courante.
		if ((YmRegs.MixerControl&0x38)!=0x38)
		{
			if (YmRegs.NoiseControl>0)
			{
				StepNoise=(FREQBASE<<12)/YmRegs.NoiseControl;
			}
			else
			{
				StepNoise=0;
			}
			for (i=0;i<sampleToCompute;i++)
			{
				Noise[i] = NoiseTable[(NoisePos>>16)&(NOISESIZE-1)];
				NoisePos+=StepNoise;
			}
		}

	//--------------------------------------------------------------------
	// Gestion de l'enveloppe.
	//--------------------------------------------------------------------
		EnvPeriod = (YmRegs.EnvHighPeriod<<8) + YmRegs.EnvLowPeriod;
		StepEnv=0;
		if (EnvPeriod) StepEnv = (FREQBASE<<16)/EnvPeriod;

		// Calcul la courbe d'enveloppe courante.
		pEnv=&PredefEnv[(YmRegs.EnvShape&0xf)*(ENV_SIZE*4)];
		pEnv2=BufferEnv;
		i=sampleToCompute;
		do
		{
			*pEnv2++ = pEnv[EnvPos>>16];
			EnvPos += StepEnv;
			if (EnvPos >= ((ENV_SIZE*4)<<16))
			{
				EnvPos &= (((ENV_SIZE*2)<<16)-1);
				EnvPos += (ENV_SIZE*2)<<16;
			}
		}
		while (--i);

		// Calcul les trois buffers de digits de chaque voix YM.
		CalcVoice(0,BufferVoice);
		CalcVoice(1,BufferVoice+1024);
		CalcVoice(2,BufferVoice+1024*2);

		// Puis mixage des trois buffers.
/*		MixVoice8(innerOutDataPtr);
		innerOutDataPtr += sampleToCompute;
*/
        MixVoice8(buffer) ;


}


//extern unsigned char *volume_buffer2 ;
extern char volume_buffer[512*4] ;//max entries:512
extern int nbVolumeEntries ;
static unsigned char *pvolume_voice ;

void	CalcVoice(int nvoice,int *dest)
{
 UD	steptune;
 float	ftune;
 voice_t *pVoice;
 int	n;
 int	j;
 int	vol;
 int	code;


	pVoice = &YmRegs.Channel[nvoice];

	// Code voie.
	code=0;
	if (pVoice->VoiceOn)
	{
	  if (pVoice->Volume&0x10) code|=4;			// Enveloppe
	  if (!(YmRegs.MixerControl & (1<<nvoice))) code |= 2;	// Tone
	  if (!(YmRegs.MixerControl & (1<<(nvoice+3)))) code |=1; // Noise
	}


        vol = pVolumeTable[pVoice->Volume&0xf]>>8;
        pvolume_voice = volume_buffer+nvoice ; // add

	// Calcul les pentes pour synthese.
	ftune = pVoice->finetune + (pVoice->crsetune<<8);
	steptune=0;
	if (ftune)
	{
	  ftune = ((float)FREQBASE * 65536*256*16) / ftune;
	  steptune = ftune;
	}


	n=sampleToCompute;

        if ((code== _110) & (steptune==0))
        {
                code== _1000 ;
        }

	switch (code)
	{
                extern int isSamples ;

 //***********************************************************************
	case _000:	// Nada, niet, quedal
                j=0 ;
        	do
		{
                        if (isSamples) {
                                *dest++ = pVolumeTable[*(pvolume_voice+(((j*nbVolumeEntries)/sampleToCompute)<<2))]>>8 ;
                                j++ ;
                        }
                        else *dest++ = 0 ;
		}
		while (--n);
		break;

 //***********************************************************************
	case _001:	// Noise
		j=0;

if (isSamples) do
               {
                  vol = pVolumeTable[*(pvolume_voice+(((j*nbVolumeEntries)/sampleToCompute)<<2))]>>8 ;//ADD
                  *dest++ = (Noise[j++]*vol)>>8;
               }
               while (--n) ;

else           do
		{
                  *dest++ = (Noise[j++]*vol)>>8;
		}
		while (--n);
		break;


 //***********************************************************************
	case _010:	// Tone
                j = 0 ;

if (isSamples) do
               {
                 vol = pVolumeTable[*(pvolume_voice+(((j*nbVolumeEntries)/sampleToCompute)<<2))]>>8 ;//ADD
	  	  *dest++ = (tuneWave[pVoice->CurrentPos>>TUNESHIFT]*vol)>>8;
	  	  pVoice->CurrentPos += steptune;
                  j++ ;
		}
		while (--n);
else   		do
		{
	  	  *dest++ = (tuneWave[pVoice->CurrentPos>>TUNESHIFT]*vol)>>8;
	  	  pVoice->CurrentPos += steptune;
                  j++ ;
		}
		while (--n);
		break;

 //***********************************************************************
	case _011:	// Noise + Tone
		j=0;
if (isSamples) do
               {
                 vol = pVolumeTable[*(pvolume_voice+(((j*nbVolumeEntries)/sampleToCompute)<<2))]>>8 ;//ADD

	  	  *dest++ = (((tuneWave[pVoice->CurrentPos>>TUNESHIFT] * Noise[j++])>>8) * vol) >>8;
	  	  pVoice->CurrentPos += steptune;
                  j++ ;
		}
		while (--n);
else		do
		{
	  	  *dest++ = (((tuneWave[pVoice->CurrentPos>>TUNESHIFT] * Noise[j++])>>8) * vol) >>8;
	  	  pVoice->CurrentPos += steptune;
                  j++ ;
		}
		while (--n);
		break;
 //***********************************************************************
	case _100:	// Env
		do
		{
	  	  dest[n-1] = BufferEnv[n-1];
		}
		while (--n);
		break;
 //***********************************************************************
	case _101:	// Env + Noise
		j=0;
		do
		{
	  	  *dest++ = (BufferEnv[j] * Noise[j]) >>8;
		  j++;
		}
		while (--n);
		break;
 //***********************************************************************
	case _110:	// Env + Tone
		j=0;
		do
		{
	  	  *dest++ = (tuneWave[pVoice->CurrentPos>>TUNESHIFT] * BufferEnv[j++]) >>8;
	  	  pVoice->CurrentPos += steptune;
		}
		while (--n);
		break;
 //***********************************************************************
	case _111:	// Env + Tone + Noise
		j=0;
		do
		{
			*dest++ = (BufferEnv[j] * (	(tuneWave[pVoice->CurrentPos>>TUNESHIFT]*Noise[j]) >>8)) >>8;
			pVoice->CurrentPos += steptune;
			j++;
		}
		while (--n);
		break;

        case _1000:
                do
                {
                        dest[n-1] = (BufferEnv[n-1]*MIDVOL)>>8 ;
                } while (--n) ;
                break ;
	}

 }

void	MixVoice8(UB *dest)
 {
 int	*v;
 UB *pEnd;

	v = BufferVoice;
	// Code tordu mais boucle optimale avec WATCOM PC.
	pEnd = dest + sampleToCompute;
	do
	{
		*dest++ = pMix8[v[0] + v[1024] + v[2048]];
		v++;
	}
	while (dest!=pEnd);
 }


void	EnvInit(void)
 {
 int	*pEnv;
 int	env,part,pos;
 int	a,b;
 SD	c,cPente;
 UB *pTab;


		pEnv = PredefEnv;
		for (env=0;env<16;env++)
		{
			pTab = EnvWave[env];
			for (part=0;part<4;part++)
			{
				a=pTab[part*2]*MAX_SAMPLEVALUE;	// Depart
				b=pTab[part*2+1]*MAX_SAMPLEVALUE;	// Fin
				cPente = ((b-a)<<16)/ENV_SIZE;
				c=(a<<16);
				for (pos=0;pos<ENV_SIZE;pos++)
				{
					*pEnv++ = volumeTableA[(c>>(16+4))]>>8;
					c+=cPente;
	  			}
			}
		}
		EnvPos=(ENV_START<<16);
 }


void	TuneInit(void)
 {
 int	i;	// Mettre volatile: bug du compilo 10.5 en /onatexl+
 float	a;


	//-------------------------------------------------
	// SQUARE TUNE
	//-------------------------------------------------
	for (i=0;i<128;i++) SquareWave[i]=0;
	for (i=128;i<256;i++) SquareWave[i]=255;

 }


//--------------------------------------------------------
//
//	Rien de mieux que rand() pour le bruit blanc.
//	Trouver la vrai doc du YM2149 concernant le bruit.
//
//--------------------------------------------------------
void	NoiseInit(void)
 {
 int i;

	for (i=0;i<NOISESIZE;i++)
	{
		NoiseTable[i] = (rand()&255);
	}
	NoisePos=0;
 }



/*****************************************************************************

					END OF FILE

*****************************************************************************/
