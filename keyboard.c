#include "cpu68.h"
#include "kb.h"
#include <dos.h>
#include <conio.h>

static int kb_installed = FALSE ;
static void (__interrupt __far *bios_keyboard_handler)();

static int numlock = TRUE;

int specialkey ;
int isspecialkey ;

static int wait4return = FALSE ;
static int wait4what ;
static int released ;

//extern int ST_Joy1 ;
extern unsigned int numericpad_for_ST ;

int isctrl ;
int isalt ;
int isdel ;
int isshift ;

int prevkey ;
int isextendedkey ;

#pragma off (check_stack) ;
void __interrupt __far _loadds keyboard_handler()
{
        int a ;//, released ;
        int keycode ;
        int released ;

//        _enable() ;

        /////////////////// keyboard in ST mode...

        if (ModeST) {
                keyboard_st() ;
                return ;
        }

        keycode=inp(0x60);
        released = (keycode&0x80) ;

        /////////////////// keyboard in Monitor mode...

/*
        {
                short *  video = (short *)(0xb8000+78*2) ;
                int v ;

                v = (keycode>>4) ;
                if (v<10) *video++ = 0xf00+(v+'0') ;
                        else *video++ = 0xf00+(v+'A'-10) ;
                v = keycode & 15 ;
                if (v<10) *video = 0xf00+(v+'0') ;
                        else *video = 0xf00+(v+'A'-10) ;

        }
*/
        isextendedkey = (prevkey==0xe0) ;
        prevkey = keycode ;

        a = keycode ;
        if ((a==KEY_F1)||(a==KEY_F2)||(a==KEY_F3)||
            (a==KEY_F4)||(a==KEY_F10)||
            (a==KEY_F12)||(a==KEY_F6)||(a==KEY_F5)||(a==KEY_F7)

  //          (isextendedkey&&((a==KEY_UP)||(a==KEY_DOWN)))
           ){
                specialkey = keycode ;
                isspecialkey = TRUE ;
                a = inp(0x61) ;
                a |= 0x82 ;
                outp(0x61,a) ;
                outp(0x61,a&0x7f) ;
                outp(0x20,0x20);
                return ;
        }

        if ((keycode&0x7f)==0x1d) isctrl = (released==0) ;
        if ((keycode&0x7f)==0x38) isalt = (released==0) ;
        if ((keycode&0x7f)==0x46) isalt = (released==0) ;
        if ((keycode&0x7f)==0x53) isdel = (released==0) ;
        if ((keycode&0x7f)==0x2a) isshift = (released==0) ;     // shift 1
        if ((keycode&0x7f)==0x36) isshift = (released==0) ;     // shift 2


        if ((isalt)&&(isctrl)&&(isdel)) {
                outp(0x20,0x20) ;
                return ;
        }


         wait4return = TRUE ;
         wait4what = keycode ;
        _chain_intr(bios_keyboard_handler) ;

}
#pragma on (check_stack) ;



void ledon(int led) ;
#pragma aux ledon=\
        "       cmp     [isLeds],0      "\
        "       je      noled           "\
        "l1:    in      al,64h          "\
        "       test    al,2            "\
        "       jne     l1              "\
        "l2:    in      al,64h          "\
        "       test    al,2            "\
        "       jnz     l2              "\
        "l3:    in      al,64h          "\
        "       test    al,2            "\
        "       jnz     l3              "\
        "       mov     al,0xed         "\
        "       out     0x60,al         "\
        "l4:    in      al,64h          "\
        "       test    al,2            "\
        "       jnz     l4              "\
        "l5:    in      al,64h          "\
        "       test    al,2            "\
        "       jnz     l5              "\
        "l6:    in      al,64h          "\
        "       test    al,2            "\
        "       jnz     l6              "\
        "       mov     al,dl           "\
        "       out     0x60,al         "\
        "noled:                         "\
        parm [edx] ;
        /*
        "loo2:  in      al,64h          "\
        "       test    al,2            "\
        "       jnz     loo2            "\
        */

static int current_leds = 0x2 ;
static int prev_leds = 0 ;

static char *bios_leds = (char *)0x417 ;

void periodic_leds(void)
{

/*        if ((prev_leds!=current_leds)&&isLeds)
                ledon(current_leds) ;
        prev_leds = current_leds ;
*/
}

void disk_activity(int activ)
{
//        current_leds&=~1 ;
//        if (activ) current_leds++ ;

        if (activ) ledon(1+(numlock<<1)) ; else ledon(numlock<<1) ;
}


#define NP              0x0100
#define CTRL            0x0200
#define PAUSE           0x0400
#define SHIFT           0x0800
#define PTRSCR          0x1000
#define JOY             0x2000

int stscancodes[128] = {
0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, // ESC 0123456          00
0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, // 7890)= Bkspc Tab     08
0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, // AZERTYUI             10
0x18, 0x19, 0x1a, 0x1b,                         // OP^$                 18
0x1c, 0x1d|CTRL, 0x1e, 0x1f,                    // Return, CTRL, QS     1C
0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, // DFGHJKLM             20
0x28, 0x29, 0x2a|SHIFT, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, // —* shift WXCV        28
0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36|SHIFT, 0x66, // BN,;: / shift *      30
0x38, 0x39, 0x3a,                               // alt space capslock   38
0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, // F1-F8                3B
0x43, 0x44,                                     // F9 F10               43
0, PTRSCR,                                      // VerrNum ArretDefil   45
0x67|NP, 0x68|NP, 0x69|NP, 0x4a|NP,             // Numpad 7 8 9 -       47
0x6a|NP, 0x6b|NP, 0x6c|NP, 0x4e|NP,             // Numpad 4 5 6 +       4B
0x6d|NP, 0x6e|NP, 0x6f|NP, 0x70|NP,             // Numpad 1 2 3 0       4F
0x71|NP, 0      , 0      , 0x60,                // Numpad supr    >     53
0,    0,    0,    0,    0,    0,    0,    0,    //                      58
0,    0,    0,    0,    0,    0,    0,    0,    //                      60
0,    0,    0,    0,    0,    0,    0,    0,    //                      68
0,    0,    0,    0,    0,    0,    0,    0,    //                      70
0,    0,    0,    0,    0,    0,    0,    0     //                      78
} ;

// END (ext 4f sert pas)

int extended_stscancodes[128] = {
0,    0,    0,    0,    0,    0,    0,    0,    //                      00
0,    0,    0,    0,    0,    0,    0,    0,    //                      08
0,    0,    0,    0,    0,    0,    0,    0,    //                      10
0,    0,    0,    0,    0x72, 0x1d|NP|CTRL|JOY,0,0, //                  18
0,    0,    0,    0,    0,    0,    0,    0,    //                      20
0,    0,    0,    0,    0,    0,    0,    0,    //                      28
0,    0,    0,    0,    0,    0x65, 0,    0,    //                     30
0x38, 0,    0,    0,    0,    0,    0,    0,    //                      38
0,    0,    0,    0,    0,    0,    PAUSE,0x47, //                      40
0x48|JOY, 0x62, 0,    0x4b|JOY, 0,    0x4d|JOY, 0,    0,    //          48
0x50|JOY, 0x61, 0x52, 0x53, 0,    0,    0,    0,    //                  50
0,    0,    0,    0,    0,    0,    0,    0,    //                      58
0,    0,    0,    0,    0,    0,    0,    0,    //                      60
0,    0,    0,    0,    0,    0,    0,    0,    //                      68
0,    0,    0,    0,    0,    0,    0,    0,    //                      70
0,    0,    0,    0,    0,    0,    0,    0     //                      78
} ;


/*
0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,        //10
0x18,0x19,0x1a,0x1b,0x1c,0x1d,0x1e,0x1f,
0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,        //20
0x28,0x29,0x2a,0x2b,0x2c,0x2d,0x2e,0x2f,
0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,        //30
0x38,0x39,0x3a,0x3b,0x3c,0x3d,0x3e,0x3f,
0x40,0x41,0x42,0x43,0x44,0x45,0x46,0x47,        //40 - 62:help
0x48,0x62,0x4a,0x4b,0x4c,0x4d,0x4e,0x4f,
0x50,0x61,0x52,0x53,0x54,0x55,0x60,0x57,        //50 - 61:undo - 56: >
0x58,0x59,0x5a,0x5b,0x5c,0x5d,0x5e,0x5f,
0x60,0x61,0x62,0x63,0x64,0x65,0x66,0x67,        //60
0x68,0x69,0x6a,0x6b,0x6c,0x6d,0x6e,0x6f,
0x70,0x71,0x72,0x73,0x74,0x75,0x76,0x77,        //70
0x78,0x79,0x7a,0x7b,0x7c,0x7d,0x7e,0x7f
} ;

*/

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³                                                                         ³
//³                                                                         ³
//³                           KEYBOARD DURING EMULATION                     ³
//³                                                                         ³
//³                                                                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

int within_keyboard_interrupt = FALSE ;

void keyboard_st()
{
        int     a ;
        int keycode ;
        int stkeycode ;
        static int ispause;
        static int nextisextended = FALSE ;

        keycode=inp(0x60);
        released = (keycode&0x80) ;
        outp(0x20,0x20);
/*
        a = inp(0x61) ;
        a |= 0x82 ;
        outp(0x61,a) ;
        outp(0x61,a&0x7f) ;
*/
        if (nextisextended)
                stkeycode = extended_stscancodes[keycode&0x7f] ;
        else    stkeycode = stscancodes[keycode&0x7f] ;
        nextisextended = (keycode==0xe0) ;
        if (nextisextended) return ;


        if ((keycode&0x7f)==0x7a) return ; // led
        if ((wait4return)&&(keycode == wait4what|0x80)) {
                wait4return = FALSE ;
                return ;
        }
        if ((keycode&0x7f) == KEY_TILDE) {
                processor->events_mask |= MASK_UserBreak ;
                return ;
        }

        if ((keycode==KEY_F12)&&!withinselector) {
                processor->events_mask |= MASK_DiskSelector ;
                return ;
        }


        if (keycode == 0x45) {
                numlock = 1-numlock ;
                ledon(numlock<<1) ;
                return ;
        }

        if ((stkeycode&PTRSCR)/*==0xc6)&&!nextisextended*/) { // ScrollLock
                if (released) processor->events_mask |= MASK_PRTSCR ;
                return ;
        }


        if (stkeycode&CTRL) isctrl=(released==0) ;
        if (stkeycode&PAUSE) ispause=(released==0) ;
        if (stkeycode&SHIFT) isshift=(released==0) ;

        if (!stkeycode) return ;

        if ((stkeycode&JOY)&&!numlock/*&&JoyEmu*/) {             // Numeric Pad
            switch(stkeycode&0x7f) {

                case 0x48 : if (released) numericpad_for_ST&=0xfe ;
                                    else numericpad_for_ST|=0x01 ;
                            break ;
                case 0x50 : if (released) numericpad_for_ST&=0xfd ;
                                    else numericpad_for_ST|=0x02 ;
                            break ;
                case 0x4b : if (released) numericpad_for_ST&=0xfb ;
                                    else numericpad_for_ST|=0x04 ;
                            break ;
                case 0x4d : if (released) numericpad_for_ST&=0xf7 ;
                                    else numericpad_for_ST|=0x08 ;
                            break ;
                case 0x1d : if (released) numericpad_for_ST&=0x7f ;
                                    else numericpad_for_ST|=0x80 ;
                            break ;
            }
            return ;
        }


        if (isctrl&ispause) {
                if (isshift) processor->events_mask |= MASK_HardReset ;
                else  processor->events_mask |= MASK_SoftReset ;
                        isctrl = ispause = isshift = FALSE ;
                        return ;
        }


//        add_key((stkeycode&0x7f)|released) ;

        within_keyboard_interrupt = TRUE ;
        Keyboard_Write((stkeycode&0x7f)|released) ;
        within_keyboard_interrupt = FALSE ;
/*
        if (((stkeycode&0x7f)|released) != 0x4b)
                processor->events_mask |= MASK_UserBreak ;
*/
        return ;
}

void kb_install(void)
{
   if (kb_installed) return ;
   kb_installed = TRUE ;

   bios_keyboard_handler = _dos_getvect(0x9) ;
   _dos_setvect(0x9,keyboard_handler) ;


        if (isLaptop) {
                stscancodes[0x1d] |= JOY ;
                extended_stscancodes[0x1d] &= ~JOY ;
        }
}

void kb_deinstall(void)
{
   if (!kb_installed) return ;
   kb_installed = FALSE ;
   _dos_setvect(0x9,bios_keyboard_handler) ;
}
/*
static int nbk = 0 ;
static int tabk[100] ;

void add_key(int sc)
{
        if (nbk==100) return ;
        tabk[nbk++] = sc ;

}

int get_key(void)
{
        int i,k ;
//        if (processor->events_mask&MASK_UserBreak) return 0x100 ;
        if (nbk==0) return 0 ;
        k = tabk[0] ;
        for (i=0;i++;i<nbk)
                tabk[i] = tabk[i+1] ;
        nbk-- ;
        return k;
}
*/
