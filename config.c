#include <i86.h>
#include <direct.h>
#include "cpu68.h"
#include "config.h"
#include "vbe.h"


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³
 *³
 *³                                                                sorta GUI
 *³
 *³
 *³
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/


#define MAXWINDOWS 10


typedef struct TWindow {
        int handle ;
        char *title ;
        int attr ;
        int col ;
        int xpos ;
        int ypos ;
        int xsize ;
        int ysize ;
        struct TWindow *next ;

        void (*Window_RedrawEvent)(struct TWindow *win) ;
        void (*Window_KeypressedEvent)(struct TWindow *win,int c) ;

        int param1 ;
        int param2 ;
} ;

/*
typedef struct TWindowList {
        int handle ;
        struct TWindowList *next ;
} ;

struct TWindow Windows[MAXWINDOWS] ;
struct TWindowList *WindowsList ;
*/

unsigned short *screen = (unsigned short *)(0xb8000) ;

struct TWindow *Windows ;
int windowhandle = 0 ;          // next window handle

void outcar(int car,int col,int x,int y)
{
        if ((x>=0)&&(x<80)&&(y>=0)&&(y<50))
                *(screen+x+y*80) = car+(col<<8) ;
}

unsigned short savedscreen[80*50] ;

void Save_Screen(void)
{
        unsigned short *screen = (unsigned short *)(0xb8000) ;
        int i ;
        for (i=0;i<80*50;i++) savedscreen[i] = *screen++ ;
}


void Restore_Screen(void)
{
        unsigned short *screen = (unsigned short *)(0xb8000) ;
        int i ;
        for (i=0;i<80*50;i++) *screen++ = savedscreen[i] ;
}


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//³                                             Print string within a Window
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

void Window_PrintLine(struct TWindow *win,int col,int y,char *text)
{
        int x = win->xpos ;
        if (y>=win->ysize)
                return ;
        while (*text && (x<win->xpos+win->xsize)) {
                outcar(*text,col,x,y+win->ypos) ;
                text++ ;
                x++ ;
        }
}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//³                                                          Redraw a Window
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

void Redraw_Window(struct TWindow *w)
{
        int i,j ;
        int c ;

        for (i=w->xpos-1;i<=w->xpos+w->xsize;i++)
          for (j=w->ypos-1;j<=w->ypos+w->ysize;j++)
                outcar(' ',w->col,i,j) ;

        for (i=w->xpos-1;i<=w->xpos+w->xsize;i++) {
                outcar('±',w->col,i,w->ypos-1) ;
                outcar('°',w->col,i,w->ypos+w->ysize) ;
        }
        for (i=w->ypos-1;i<=w->ypos+w->ysize;i++) {
                outcar('±',w->col,w->xpos-1,i) ;
                outcar('±',w->col,w->xpos+w->xsize,i) ;
        }
        w->Window_RedrawEvent(w) ;
}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//³                                                       Redraw all Windows
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

void Redraw_Windows(void)
{
        struct TWindow *wins = Windows ;
        while (wins) {
                Redraw_Window(wins) ;
                wins = wins->next ;
        }
}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//³                                                       Display Status bar
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

void Status_Bar(char *bar)
{
        int x = 0;
        while (*bar&&(x<80)) {
                outcar(*bar,0x2f,x,49) ;
                bar++ ;
                x++ ;
        }
        while (x<80) outcar('°',0x2f,x++,49) ;
}


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//³                                                        Open a new Window
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

int Open_Window(char *title,
                int attr, int col,
                int xpos, int ypos,
                int xsize, int ysize,
                void (*Window_RedrawEvent)(),
                void (*Window_KeypressedEvent)() )

{
        struct TWindow *newwin ;
        newwin = (struct TWindow *)malloc(sizeof(struct TWindow)) ;
        if (newwin==0) return 0 ;
        ++windowhandle ;

        newwin->handle = windowhandle ;
        newwin->title = title ;
        newwin->attr = attr ;
        newwin->col = col ;
        newwin->xpos = xpos ;
        newwin->ypos = ypos ;
        newwin->xsize = xsize ;
        newwin->ysize = ysize ;
        newwin->Window_RedrawEvent = Window_RedrawEvent ;
        newwin->Window_KeypressedEvent = Window_KeypressedEvent ;

        newwin->param1 = 0 ;
        newwin->param2 = 0 ;

        newwin->next = Windows ;
        Windows = newwin ;              // new windows start of list

        Redraw_Windows() ;

        return windowhandle ;
}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//³                                                           Close a Window
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

void Close_Window(struct TWindow *win)
{
        /////// WORKS ONLY FOR THE ACTIVE WINDOW !!!

        if (win==Windows)
                Windows = Windows->next ;
}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//³                                                         KEYPRESSED Event
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

void Window_KeypressedEvent(int c)
{
        if (Windows == 0) return ;      // nothing to do if no windows
        Windows->Window_KeypressedEvent(Windows,c) ;
}

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//³                                                      WINDOWS EVENTS LOOP
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

void Window_EventsLoop()
{
        int c ;
        c = getch() ;
        while ((c!=27)&&Windows) {

                Window_KeypressedEvent(c) ;
                Redraw_Windows() ;

                if (Windows) c = getch() ;
        }
}


/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³
 *³
 *³                                                      VIDEO CONFIGURATION
 *³
 *³
 *³
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

static int NbValidModes ;
static struct TValidMode ValidModes[MAXVALIDMODES] ;

void scan_vbe_modes()
{
        struct VBEMODEINFO mi ;
        int     rez ;
        int     okdepth,okx,oky,okgfx,oklinear ;
        struct TValidMode *pvalid ;
        unsigned short *pmodes ;

        NbValidModes = 0 ;
        pvalid = ValidModes ;

        if (!vbe_ok) return ;

        pmodes = (unsigned short *)((((unsigned int)vbeinfo->videomodelist>>16)<<4)+(unsigned short)vbeinfo->videomodelist) ;
        while (*pmodes!=0xffff) {

                rez = VBE_getmodeinfo(*pmodes,&mi) ;

                okdepth = ((mi.bitsperpixel==8)||(mi.bitsperpixel==15)||(mi.bitsperpixel==16)) ;
//                okx = ((mi.xresolution==320)||(mi.xresolution==360)||(mi.xresolution==512)||(mi.xresolution==640)) ;
//                oky = ((mi.yresolution==200)||(mi.yresolution==240)||(mi.yresolution==640)) ;
                okx = oky = TRUE ;
                okgfx = (mi.modeattributes&0x10) ;
                oklinear = (mi.modeattributes&0x80) ;

                if (rez&&okgfx&&okdepth&&okx&&oky&&oklinear) {
                        pvalid->mode = *pmodes ;
                        pvalid->x = mi.xresolution ;
                        pvalid->y = mi.yresolution ;
                        pvalid->bpp = mi.bitsperpixel ;
                        pvalid->nbcolors = 1<<mi.bitsperpixel ;
                        pvalid->linear = TRUE ;
                        pvalid->linewidth = mi.bytesperscanline ;
                        NbValidModes++ ;
                        pvalid++ ;
                }
                pmodes++ ;
        }
}


void Window_ConfigVideo_RedrawEvent(struct TWindow *win)
{
        int i ;
        char b[80] ;
        int col ;

        for (i=0;i<win->ysize;i++) {
                if (i+win->param2 < NbValidModes)
                        sprintf(b," Mode %04x %dx%d %5d Colors ",ValidModes[i+win->param2].mode,ValidModes[i+win->param2].x,ValidModes[i+win->param2].y,ValidModes[i+win->param2].nbcolors) ;
                else
                        sprintf(b,"") ;
                if (i+win->param2 == win->param1) col = 0x71 ;
                else col = win->col ;
                Window_PrintLine(win,col,i,b) ;
        }
}

void Window_ConfigVideo_KeypressedEvent(struct TWindow *win,int c)
{
        int prevp = win->param1 ;
        int destroy = FALSE ;
        switch(c) {
                case K_UP       : win->param1-- ; break ;
                case K_DOWN     : win->param1++ ; break ;
                case K_PAGEUP   : win->param1-=win->ysize ; break ;
                case K_PAGEDOWN : win->param1+=win->ysize ; break ;
                case K_HOME     : win->param1 = 0 ; break ;
                case K_END      : win->param1 = 0x7fff ; break ;
                case K_ESC      : destroy = TRUE ; break ;
                case K_ENTER    : destroy = TRUE ;
                                  vbemode = ValidModes[win->param1].mode ;
                                  vbemode_x = ValidModes[win->param1].x ;
                                  vbemode_y = ValidModes[win->param1].y ;
                                  vbemode_bpp = ValidModes[win->param1].bpp;
                                  vbemode_linewidth = ValidModes[win->param1].linewidth ;
                                  break ;
        }

        if (win->param1<0) win->param1 = 0 ;
        if (win->param1>NbValidModes-1) win->param1 = NbValidModes-1 ;
        if (win->param2 > win->param1) win->param2 = win->param1 ;
        if (win->param2 < win->param1-win->ysize+1) win->param2 = win->param1-win->ysize+1 ;

        if (destroy) Close_Window(win) ;
}

void Config_Video()
{
        int handle ;
        scan_vbe_modes() ;
        if (NbValidModes==0) return ;

        Save_Screen() ;

        handle = Open_Window("titre",0,0x1f,10,10,32,10,
                 Window_ConfigVideo_RedrawEvent,
                 Window_ConfigVideo_KeypressedEvent) ;

        Window_EventsLoop() ;
//        Close_Window(handle) ;
        Windows = 0 ;
        Restore_Screen() ;

}

/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
 *³
 *³
 *³
 *³                                                DISK IMAGES CONFIGURATION
 *³
 *³
 *³
 *ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

/*
#define MAXITEMS 256
#define MAXITEMNAMELENGTH 16

#define ITEM_FILE       0
#define ITEM_DIR        1
#define ITEM_LETTER     2

typedef struct  {
        int     kind ;
        int     size ;
        char    name[MAXITEMNAMELENGTH] ;
} item ;

item    items[MAXITEMS] ;
int     nb_items ;

int     fixeddrives ;

char    selectedfile[256] ;
char    currentpath[256] ;

void scan_currentdir()
{
        DIR *dirp ;
        struct dirent *direntp ;
        int rez,i ;
        item *pitem ;

        pitem = items ;
        nb_items = 0 ;

        for (i=0;i<26;i++)
                if (fixeddrives&(1<<i)) {
                pitem->name[0] = i+'A' ;
                pitem->kind = ITEM_LETTER ;
                pitem++ ;
                nb_items++ ;
        }

        dirp = opendir("*.*") ;
        if (dirp) {
                direntp = readdir(dirp) ;
                while (direntp) {
                        if (direntp->d_name[0] == '.')
                                if (direntp->d_name[1] == 0) goto nxt ;

                        strcpy(pitem->name,direntp->d_name) ;
                        pitem->size = direntp->d_size ;

                        if (direntp->d_attr&_A_SUBDIR)
                                pitem->kind = ITEM_DIR ;

                        else    {
                                if (!strstr(direntp->d_name,".ST"))
                                        goto nxt ;
                                pitem->kind = ITEM_FILE ;
                        }
                        nb_items++ ;
                        pitem++ ;
nxt:
                        direntp = readdir(dirp) ;
                }
                closedir(dirp) ;
        }
}

void Window_ConfigImages_RedrawEvent(struct TWindow *win)
{
        int i ;
        char b[256] ;
        int col ;
        item *pitem ;

        sprintf(b,"current path is %s",currentpath) ;
        Status_Bar(b) ;

        pitem = &items[win->param2] ;

        for (i=0;i<win->ysize;i++) {
                if (i+win->param2 < nb_items)
                 switch(pitem->kind) {
                      case ITEM_FILE : sprintf(b,"%-13s %6d Kb",pitem->name,pitem->size>>10) ;
                                       break ;
                      case ITEM_DIR  : sprintf(b,"%-13s       DIR",pitem->name) ;
                                       break ;
                      case ITEM_LETTER:sprintf(b,"[%c:]",*(pitem->name)) ;
                                       break ;
                 }
                else
                        sprintf(b,"") ;

                if (i+win->param2 == win->param1) col = 0x13 ;
                else col = win->col ;
                Window_PrintLine(win,col,i,b) ;
                pitem++ ;
        }
}

int ConfigImages_onEnter(struct TWindow *win)
{
        char newpath ;

        if (items[win->param1].kind == ITEM_FILE) {
                strcpy(selectedfile,items[win->param1].name) ;
                return TRUE ;
        }

        if (items[win->param1].kind == ITEM_LETTER) {
                union REGS regs ;
                regs.h.ah = 0xe ;
                regs.x.edx = items[win->param1].name[0]-'A' ;
                int386(0x21,&regs,&regs) ;
                getcwd(currentpath,256) ;
                scan_currentdir() ;
                win->param1 = win->param2 = 0 ;
                return FALSE ;
        }

        chdir(items[win->param1].name) ;
        getcwd(currentpath,256) ;
        scan_currentdir() ;
        win->param1 = win->param2 = 0 ;

        return FALSE ;
}

void Window_ConfigImages_KeypressedEvent(struct TWindow *win,int c)
{
        int prevp = win->param1 ;
        int destroy = FALSE ;
        switch(c) {
                case K_UP       : win->param1-- ; break ;
                case K_DOWN     : win->param1++ ; break ;
                case K_PAGEUP   : win->param1-=win->ysize ; break ;
                case K_PAGEDOWN : win->param1+=win->ysize ; break ;
                case K_HOME     : win->param1 = 0 ; break ;
                case K_END      : win->param1 = 0x7fff ; break ;
                case K_ESC      : destroy = TRUE ;
                                  break ;
                case K_ENTER    : destroy = ConfigImages_onEnter(win) ;
                                  break ;
        }

        if (win->param1<0) win->param1 = 0 ;
        if (win->param1>nb_items-1) win->param1 = nb_items-1 ;
        if (win->param2 > win->param1) win->param2 = win->param1 ;
        if (win->param2 < win->param1-win->ysize+1) win->param2 = win->param1-win->ysize+1 ;

        if (destroy) Close_Window(win) ;
}

int scan_fixeddrives()
{
        int i,mask ;
        union REGS regs ;

        mask = 0 ;
        for (i=26;i>0;i--) {
                regs.h.ah = 0x44 ;
                regs.h.al = 8 ;
                regs.x.ebx = i ;
                int386(0x21,&regs,&regs) ;
                mask<<=1 ;
                if ((!regs.w.cflag&1)&&(regs.w.ax==1))
                        mask |= 1 ;
        }
        return mask ;
}


void Config_Image(char *imagename)
{
        int handle ;
        char initialpath[256] ;

        Save_Screen() ;

        *selectedfile = 0 ;
        getcwd(initialpath,256) ;
        strcpy(currentpath,initialpath) ;

        fixeddrives = scan_fixeddrives() ;

        scan_currentdir() ;
        handle = Open_Window("titre",0,0x0f,10,10,23,32,
                 Window_ConfigImages_RedrawEvent,
                 Window_ConfigImages_KeypressedEvent) ;

        Window_EventsLoop() ;


//        printf("you selected <%s>\n",selectedfile) ;
        chdir(initialpath) ;
//        exit(1) ;

        strcpy(imagename,selectedfile) ;
        Windows = 0 ;
//        Close_Window(handle) ;
        Restore_Screen() ;

}
*/
void select()
{


}

