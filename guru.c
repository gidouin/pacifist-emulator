/*      "GURU": CRASH PROGRAM TERMINATION (from pmwfix)
 *
 * 10/8/96 : first version, display registers and exception type
 * 11/8/96 : added last 68000 PC location (if compiled with "GURU" setted)
 * 14/3/96 : use DPMI to install handlers
*/

#ifdef GURU


#include <i86.h>
#include <stdio.h>
#include "cpu68.h"
#include "vbe.h"

extern unsigned int lastEA ;

static int  wasthereanyguru = FALSE ;

void (__interrupt __far *oldint[0xf])();

static char *name[15] = {
        "Divide Error",             // 0
        "Debug Exception",          // 1
        "NMI",                      // 2
        "BreakPoint",               // 3
        "INTO instruction",         // 4
        "BOUND instruction",        // 5
        "Invalid Opcode",           // 6
        "No FPU",                   // 7
        "Double Fault",             // 8
        "FPU Segment Overrun",      // 9
        "Invalid TSS",              // 10
        "Segment not Present",      // 11
        "Stack Fault",              // 12
        "General Protection Fault", // 13
        "Page Fault"                // 14
} ;

char ec[0xf] = { 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1 };

#pragma aux exception aborts;
void exception( int num, union INTPACK __far *r )
{
        int c, d, e, f;
        char buffer[6*80];
        extern FILE *fdebug ;

        if (wasthereanyguru) exit(2) ;
        wasthereanyguru = TRUE ;

        init_screen_50() ;

        if( !ec[num] )
        {
                c = r->x.cs&0xffff;
                d = 0;
                e = r->x.eip;
                f = r->x.flags;
        }
        else
        {
                c = r->x.flags;
                d = r->x.eip;
                e = r->x.cs&0xffff;
                f = *(int*)&r[1];
        }


        sprintf(buffer,"[GURU MEDITATION v0.5] 0x%02x %-30s\n" \
                       "[cs:eip=%04x:%08x]\n" \
                       "EAX=%08x   EBX=%08x   ECX=%08x   EDX=%08x\n" \
                       "ESI=%08x   EDI=%08x   ESP=%08x   EBP=%08x\n" \
                       "DS=%04x  ES=%04x  FS=%04x  GS=%04x",
                       num,name[num],c,e,
                       r->x.eax,r->x.ebx,r->x.ecx,r->x.edx,
                       r->x.esi,r->x.edi,r->x.esp,r->x.ebp,
                       r->x.ds&0xffff,r->x.es&0xffff,
                       r->x.fs&0xffff,r->x.gs&0xffff
                       ) ;
        printf("\n%s\n",buffer) ;

        sprintf(buffer,"\n컴컴컴컴컴컴컴컴컴 68000 registers 컴컴컴컴컴컴컴컴컴\n\n" \
                       "D0=%08x D1=%08x D2=%08x D3=%08x\n"\
                       "D4=%08x D5=%08x D6=%08x D7=%08x\n"\
                       "A0=%08x A1=%08x A2=%08x A3=%08x\n"\
                       "A4=%08x A5=%08x A6=%08x A7=%08x A7'=%08x\n"\
                       "PC=%08x SR=%04x Cycles = %08x\n(last EA perhaps was %08x)\n",
                       processor->D[0],processor->D[1],processor->D[2],processor->D[3],
                       processor->D[4],processor->D[5],processor->D[6],processor->D[7],
                       processor->A[0],processor->A[1],processor->A[2],processor->A[3],
                       processor->A[4],processor->A[5],processor->A[6],processor->A[7],processor->A7,
                       processor->PC,processor->SR,
                       Nb_Cycles,lastEA) ;

        printf("%s\n",buffer) ;
        fclose(fdebug) ;
        exit(1);
}


void __interrupt __far int00( union INTPACK regs )
{
        exception( 0, &regs );        // zero divide
}


void __interrupt __far int01( union INTPACK regs )
{
        exception( 1, &regs );
}


void __interrupt __far int02( union INTPACK regs )
{
        exception( 2, &regs );
}


void __interrupt __far int03( union INTPACK regs )
{
        exception( 3, &regs );
}


void __interrupt __far int04( union INTPACK regs )
{
        exception( 4, &regs );
}


void __interrupt __far int05( union INTPACK regs )
{
        exception( 5, &regs );
}


void __interrupt __far int06( union INTPACK regs )
{
        exception( 6, &regs );
}


void __interrupt __far int07( union INTPACK regs )
{
        exception( 7, &regs );
}


/*      This interrupt might be an IRQ. The PIC knows, so we ask him.  */
void __interrupt __far int08( union INTPACK regs )
{
        outp( 0x20, 0x0b );
        if( inp( 0x20 ) == 0x01 )
                (*oldint[8])();
        else
                exception( 8, &regs );
}


void __interrupt __far int09( union INTPACK regs )
{
        outp( 0x20, 0x0b );
        if( inp( 0x20 ) == 0x02 )
                (*oldint[9])();
        else
                exception( 9, &regs );
}


void __interrupt __far int0a( union INTPACK regs )
{
        outp( 0x20, 0x0b );
        if( inp( 0x20 ) == 0x04 )
                (*oldint[0xa])();
        else
                exception( 0xa, &regs );
}


void __interrupt __far int0b( union INTPACK regs )
{
        outp( 0x20, 0x0b );
        if( inp( 0x20 ) == 0x08 )
                (*oldint[0xb])();
        else
                exception( 0xb, &regs );
}


void __interrupt __far int0c( union INTPACK regs )
{
        outp( 0x20, 0x0b );
        if( inp( 0x20 ) == 0x10 )
                (*oldint[0xc])();
        else
                exception( 0xc, &regs );
}


void __interrupt __far int0d( union INTPACK regs )
{
        outp( 0x20, 0x0b );
        if( inp( 0x20 ) == 0x20 )
                (*oldint[0xd])();
        else
                exception( 0xd, &regs );
}


void __interrupt __far int0e( union INTPACK regs )
{
        outp( 0x20, 0x0b );
        if( inp( 0x20 ) == 0x40 )
                (*oldint[0xe])();
        else
                exception( 0xe, &regs );
}

void (__interrupt __far *guruint[0xf])() =
{
        int00, int01, int02, int03,
        int04, int05, int06, int07,
        int08, int09, int0a, int0b,
        int0c, int0d, int0e
};


void install_debug(void)
{
        int a;
        union REGS regs ;

        for( a = 0; a < 0xf; a++ )
          if ((a!=8)&&(a!=9)&&(a!=12))
                {
                        regs.x.eax = 0x203 ;
                        regs.x.ebx = a ;
                        regs.x.ecx = FP_SEG(guruint[a]) ;
                        regs.x.edx = FP_OFF(guruint[a]) ;
                        int386x(0x31,&regs,&regs) ;


/*
                oldint[a] = _dos_getvect(a);
                _dos_setvect(a,guruint[a]);
*/
                }
}

#endif

