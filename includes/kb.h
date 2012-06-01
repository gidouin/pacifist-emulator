#ifndef KBH
#define KBH

extern int specialkey ;
extern int isspecialkey ;
extern int isextendedkey ;
// functions defined in keyboard.c

void kb_install(void) ;
void kb_deinstall(void) ;
void periodic_leds(void) ;
/*
 *    Mapping of PC keyboard
 *
 *    0x00 -> 0x53  for normal scancodes
 *    0x54 -> 0x7f  for extended scancodes
*/

#define KEY_ESC        0x01
#define KEY_BACKPACE   0x0e
#define KEY_TAB        0x0f
#define KEY_RETURN     0x1c
#define KEY_LCTRL      0x1d
#define KEY_RSHIFT     0x36
#define KEY_LSHIFT     0x2a
#define KEY_CAPSLOCK   0x3a
#define KEY_RCTRL      0x37
#define KEY_NUMLOCK    0x45
#define KEY_SCROLLLOCK 0x46
#define KEY_F1         0x3b
#define KEY_F2         0x3c
#define KEY_F3         0x3d
#define KEY_F4         0x3e
#define KEY_F5         0x3f
#define KEY_F6         0x40
#define KEY_F7         0x41
#define KEY_F8         0x42
#define KEY_F9         0x43
#define KEY_F10        0x44

#define KEY_UP          0x48
#define KEY_DOWN        0x50

#define KEY_F12        0x58

#define KEY_TILDE      0x29

/* ST Keyboard Mapping


    F1   F2   F3   F4   F5   F6   F7   F8   F9  F10
   [3B] [3C] [3D] [3E] [3F] [40] [41] [42] [43] [44]

 ESC  1   2   3   4   5   6   7   8   9   0   )   -   œ  Basckspace
 [01][02][03][04][05][06][07][08][09][0A][0B][0C][0D][29][0E]

 TAB   A   Z   E   R   T   Y   U   I   O   P   ^   $   Delete
 [0F] [10][11][12][13][14][15][16][17][18][19][1A][1B][53]

 Ctrl  Q   S   D   F   G   H   J   K   L   M   %   Enter #
 [1D] [1E][1F][20][21][22][23][24][25][26][27][28][1C]  [2B]

 Shift <   W   X   C   V   B   N   ,   ;   :   !  Shift
 [2A] [60][2C][2D][2E][2F][30][31][32][33][34][35][36]

  Alt                      Space                 Alt
  [38]                     [39]                  [3A]

    HELP  UNDO           (   )    /    *
    [62]  [61]         [63] [64] [65] [66]

   Ins  Up Home         7    8    9     -
   [52][48][47]        [67] [68] [69] [4A]

   Lft Dwn Rght         4    5    6    +
   [4B][50][4D]        [6A] [6B] [6C] [4E]

                        1    2    3
                       [6D] [6E] [6F] enter

                        0         .   [72]
                       [70]      [71]

*/


#endif
