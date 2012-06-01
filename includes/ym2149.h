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
//	Finalement il reste plus grand chose...
//
//
//
*****************************************************************************/

#ifndef __YM__
#define __YM__

typedef unsigned char	UB;			// Unsigned Byte
typedef unsigned short	UW;			//     "    Word
typedef unsigned long	UD;			//     "    Dword
typedef signed char		SB;			// Signed   Byte
typedef signed short	SW;			//   "      Word
typedef signed long		SD;			//   "      Dword
#ifndef BOOL
typedef int		BOOL;
#endif

//-------------------------- PROTOS --------------------------------
extern	void		Ym2149Init(void);												// Appeller une fois en init du prog.
extern	void		Ym2149Compute(void *pDataOut,SD _nbSample);						// Calcul les _nbSample prochains sample dans pDataOut.
extern	void		Ym2149registerRead(unsigned char *pYmRegister,BOOL bReg13Write);// Lit les registres YM2149 et update les registres de l'emulateur.



#define	VERSION	"v3.3"

#define	ST_RATE		50		// Frequence du player ST.
#define	PLAYRATE	(22050)		// Replay
#define	MAX_SAMPLEAMP	256
#define	MAX_SAMPLEVALUE	(MAX_SAMPLEAMP-1)
#define	ENV_SIZE	256		// Taille d'une rampe d'envellope
#define	ENV_START	(0)

//#define	TIMEC		(256-(1000000L/PLAYRATE))
//#define	RPLAYRATE	(1000000L/(256-TIMEC))
#define	NBSAMPLE	(PLAYRATE/ST_RATE)

#define	FREQBASE	(2000000L/PLAYRATE)			// 2E6 : Frequence du YM2149 sur le ST.
//#define	FREQBASE	(1000000L/PLAYRATE)			// 2E6 : Frequence du YM2149 sur le ST.

#define	TUNESIZE	256		// Taille en echantillons d'une periode
#define	PI		(3.141592654)
#define	TUNESHIFT	24
#define	SPEAKER_PORT	0x61		// Pour essai version DOS sur le speaker PC.
#define PIT_CONTROL		0x43
#define	PIT_CHANNEL0	0x40
#define	PIT_CHANNEL2	0x42
#define	PIT_FREQ		0x1234DDL

#define	MAX_DIGIDRUM	128
#define	VOICE_A			0
#define	VOICE_B			1
#define	VOICE_C			2

#define	SHOW		0

#ifndef FALSE
#define FALSE	0
#endif
#ifndef TRUE
#define TRUE	(!FALSE)
#endif

typedef enum {
	SONG_NOERROR,
	MALLOC_ERROR,
	SONG_DEPACKERROR,
	SONG_BADFORMAT,
	SONG_NOTFOUND,
	SONG_CORRUPTED,
	INVALID_ERROR,
	YM2149_MAXERR,
} YmError_t;

enum
{
	_000=0,
	_001,
	_010,
	_011,
	_100,
	_101,
	_110,
	_111,
        _1000
};

#define	NOISESIZE	16384
#define MIDVOL          170

typedef struct
{
	unsigned int finetune;
	unsigned int crsetune;
	unsigned int Volume;
	UD	CurrentPos;
	BOOL	VoiceOn;			// Voie ON/OFF
	BOOL	voiceSample;		// Digi-drum playing.
	UB	*sampleAd;				// Adresse sample courant (digi-drum)
	SD	samplePos;				// Position courante dans le sample (digi-drum)
	SD	sampleLen;				// Taille courante du sample.
	SD	samplePente;
} voice_t;

// Header d'un fichier pack‚ LZH.
typedef struct
{
	UB	size;
	UB	sum;
	char	id[6];
	UD	packed;
	UD	original;
	UB	level;
	UB	name_lenght;
	char	*name;
	UW	checksum;
} lzhheader_t;

// Structure representant le YM2149 complet:
typedef struct
{
	voice_t Channel[3];					// Trois voies.
	unsigned int NoiseControl;			// reg 6
	unsigned int MixerControl;			// reg 7
	unsigned int EnvLowPeriod;			// reg 11
	unsigned int EnvHighPeriod;			// reg 12
	unsigned int EnvShape;				// reg 13 (Forme d'enveloppe)
} ymreg_t;

// Permet l'allocation de memoire conventionelle sous DOS4G
typedef struct
{
	UW	Segment;	//The real mode segment (offset is 0).
	UW	Selector;	//In protected mode, you need to chuck this dude into a segment register and use an offset 0.
} RealPointer;

// Entete d'un fichier .WAV pour option "direct-to-disk"
typedef struct {
    UD   RIFFMagic;
    UD   FileLength;
    UD   FileType;
    UD   FormMagic;
    UD   FormLength;
    UW    SampleFormat;
    UW    NumChannels;
    UD   PlayRate;
    UD   BytesPerSec;
    UW    Pad;
    UW    BitsPerSample;
    UD   DataMagic;
    UD   DataLength;
} WAVHeader;

typedef enum {
	NONE,
	SNDB,
	GUS,
} DEVICE_T;

#define ID_RIFF 0x46464952
#define ID_WAVE 0x45564157
#define ID_FMT  0x20746D66
#define ID_DATA 0x61746164

enum
{
	T_SQUARE = 0,
	T_SIN,
	T_TRI,
	T_SCIE1,
	T_SCIE2,
	T_MAX,
};

enum
{
	T_LOGA=0,
	T_LOGB,
	T_LINEAR,
};

/*
#define	K_LEFT		(75<<8)
#define	K_RIGHT		(77<<8)
#define	K_F1		(59<<8)
#define	K_F2		(60<<8)
#define	K_F3		(61<<8)
#define	K_F4		(62<<8)
#define	K_F5		(63<<8)
*/

/***********************************************************************
// Formes d'enveloppes:

0 0 x x   \________

	   ________
0 1 x x   /


1 0 0 0   \\\\\\\\\


1 0 1 0   \________

	   ________
1 0 1 1   \


1 1 0 0   /////////

	   ________
1 1 0 1   /


1 1 1 0   /\/\/\/\/


1 1 1 1   /________


***********************************************************************/

#endif
