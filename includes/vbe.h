#define VBEMODE_320_200_15      0x10d
#define VBEMODE_320_200_16      0x10e

extern int  vbemode ;                                  // choosen videomode
extern int  vbemode_x ;                                // resolution x
extern int  vbemode_y ;                                // resolution y
extern int  vbemode_bpp ;                              // resolution bpp
extern int  vbemode_linewidth ;
extern int vbe_ok ;

extern struct VBEINFO *vbeinfo ;                // VBE driver info

extern int     vbemode_for_mixed ;
extern int     vbemode_for_mixed_y ;
extern int     vbemode_for_custom  ;
extern int     vbemode_for_custom_linewidth ;

typedef struct VBEINFO {
#pragma pack (1) ;
        unsigned int    signature ;
        unsigned short    version;
        void 	         *oemstring;
        unsigned int    capabilities;
        unsigned short  *videomodelist;
        unsigned short   totalmemory;
        unsigned int    oemsoftwarerevision;
        void        *oemvendorname;
        void        *oemproductname;
        void        *oemproductrevision;
        char            reserved[222+256];
} ;

typedef struct VBEPMODEINTERFACE {
#pragma pack (2) ;
        unsigned short SetWindow ;
        unsigned short SetDisplayStart ;
        unsigned short SetPrimaryPalette ;
        unsigned short PortsMemory ;
} ;

/*typedef struct try {
	int toto ;
	char t ;
} ;*/

typedef struct VBEMODEINFO {
      unsigned short modeattributes;
      unsigned char __windowaattributes;
      unsigned char __windowbattributes;
      unsigned short __windowgranularity;
      unsigned short __windowsize;
unsigned short windowasegment;
unsigned short windowbsegment;

//      void far *__windowfunction;
        int windowfunction ;

      unsigned short bytesperscanline;

short     xresolution;
short     yresolution;
      unsigned char __xcharactersize;
      unsigned char __ycharactersize;
      unsigned char __numberofplanes;
char    bitsperpixel;
      unsigned char __numberofbanks;
      unsigned char __memorymodel;
      unsigned char __banksize;
      unsigned char __numberofimagepages;
      unsigned char __reserved1;

      unsigned char __redmasksize;
      unsigned char __redfieldposition;
      unsigned char __greenmasksize;
      unsigned char __greenfieldposition;
      unsigned char __bluemasksize;
      unsigned char __bluefieldposition;
      unsigned char __reservedmasksize;
      unsigned char __reservedfieldposition;
      unsigned char __directcolormodeinfo;

      //void far *physicalbaseaddress;

void *physicalbaseaddress ;

int     offscreenmemoryoffset;

//      void far *__offscreenmemoryoffset;
      unsigned int __offscreenmemorysize;

      unsigned char __reserved2[206];
} ;


int VBE_init() ;
//int VBE_getmodeinfo(int mode,struct VBEMODEINFO *vbemodeinfo) ;
int VBE_setmode(int mode) ;
void VBE_deinit(void) ;
//void *VBE_testmode(int mode) ;
//
//void VBE_list_modes() ;


