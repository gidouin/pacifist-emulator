#define MAXVALIDMODES 64

#define K_UP            72
#define K_DOWN          80
#define K_LEFT          75
#define K_RIGHT         77
#define K_ENTER         13
#define K_ESC           27
#define K_PAGEUP        73
#define K_PAGEDOWN      81
#define K_END           79
#define K_HOME          71


typedef struct TValidMode {
        int     mode ;
        int     x ;
        int     y ;
        int     bpp ;
        unsigned int     nbcolors ;
        int     linear ;
        int     linewidth ;
} ;

extern struct TValidMode ValidModes[MAXVALIDMODES] ;
extern int NbValidModes ;

//extern void select() ;
extern void Config_Video() ;
extern void Config_Image(char *imagename) ;

