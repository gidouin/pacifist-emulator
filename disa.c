#include <string.h>
#include "cpu68.h"

char *DesaPtr ;

static void cat_hexa_nibble(int val)
{
        if (val<10)
                *DesaPtr++ = val+48 ;
        else
                *DesaPtr++ = val+65-10 ;
}

static void cat_hexa_byte(int val)
{
        *DesaPtr++ = '$' ;
        cat_hexa_nibble((val>>4)&15) ;
        cat_hexa_nibble(val&15) ;
}

static void cat_hexa_word(int val)
{
        int i ;
        *DesaPtr++ = '$' ;
        for (i=0;i<4;i++)
        {
                cat_hexa_nibble((val>>12)&15) ;
                val = val << 4 ;
        }
}

static void cat_hexa_long(int val)
{
        int i ;
        *DesaPtr++ = '$' ;
        for (i=0;i<8;i++)
        {
                cat_hexa_nibble((val>>28)&15) ;
                val = val << 4 ;
        }
}

///////////////////////////////////////////////////////////// Traitements EA


static void cat_size(int siz)
{
        *DesaPtr++ = '.' ;
        switch(siz) {
                case 0 : *DesaPtr++ = 'B' ; break ;
                case 1 : *DesaPtr++ = 'W' ; break ;
                case 2 : *DesaPtr++ = 'L' ; break ;
                case 3 : *DesaPtr++ = '?' ;
        }
        *DesaPtr++ = ' ' ;
}

static void cat_size_wl(int siz)
{
        *DesaPtr++ = '.' ;
        switch(siz) {
                case 0 : *DesaPtr++ = 'W' ; break ;
                case 1 : *DesaPtr++ = 'L' ; break ;
//                         *DesaPtr++ = '?' ;
        }
        *DesaPtr++ = ' ' ;
}

static void cat_Dreg(int reg)
{
        *DesaPtr++ = 'D' ;
        *DesaPtr++ = reg+0x30 ;
}

static void cat_Areg(int reg)
{
        *DesaPtr++ = 'A' ;
        *DesaPtr++ = reg+0x30 ;
}

static void cat_Aind(int reg)
{
        *DesaPtr++ = '(' ;
        *DesaPtr++ = 'A' ;
        *DesaPtr++ = reg+0x30 ;
        *DesaPtr++ = ')' ;
}

static void cat_Aipi(int reg)
{
        cat_Aind(reg) ;
        *DesaPtr++ = '+' ;
}

static void cat_Aipd(int reg)
{
        *DesaPtr++ = '-' ;
        cat_Aind(reg) ;
}

static void cat_Ad16(int reg, MPTR *pc)
{
        cat_hexa_word(read_st_word(*pc))  ;
        *pc+=2 ;
        cat_Aind(reg) ;
}

static void cat_Absw(MPTR *pc)
{
        cat_hexa_word(read_st_word(*pc)) ;
        *pc+=2 ;
        *DesaPtr++='.' ;
        *DesaPtr++='W' ;
}

static void cat_AbsL(MPTR *pc)
{
        cat_hexa_long(read_st_long(*pc)) ;
        *pc+=4 ;
}

static void cat_Pc16(MPTR *pc)
{
        cat_hexa_long(*pc + (signed int)(signed short)read_st_word(*pc)) ;
        *pc+=2 ;
        *DesaPtr++='(' ;
        *DesaPtr++='P' ;
        *DesaPtr++='C' ;
        *DesaPtr++=')' ;
}


static void cat_Ad8r(int reg, MPTR *pc)
{
        int code ;
        code = read_st_byte(*pc) ;
        cat_hexa_byte(read_st_byte(1+*pc)) ;
        *pc+=2 ;
        *DesaPtr++ = '(' ;
        *DesaPtr++ = 'A' ;
        *DesaPtr++ = reg+0x30 ;
        *DesaPtr++ = ',' ;
        if (code&0x80) *DesaPtr++ = 'A' ;
                else *DesaPtr++ = 'D' ;
        *DesaPtr++ = ((code>>4)&7)+0x30 ;
        *DesaPtr++ = '.' ;
        if (code&8) *DesaPtr++ = 'L' ;
                else *DesaPtr++ = 'W' ;
        *DesaPtr++ = ')' ;
}

static void cat_Pc8r(MPTR *pc)
{
        int code ;
        code = read_st_byte(*pc) ;
        cat_hexa_byte(read_st_byte(1+*pc)) ;
        *pc+=2 ;
        *DesaPtr++ = '(' ;
        *DesaPtr++ = 'P' ;
        *DesaPtr++ = 'C' ;
        *DesaPtr++ = ',' ;
        if (code&0x80) *DesaPtr++ = 'A' ;
                else *DesaPtr++ = 'D' ;
        *DesaPtr++ = ((code>>4)&7)+0x30 ;
        *DesaPtr++ = '.' ;
        if (code&8) *DesaPtr++ = 'L' ;
                else *DesaPtr++ = 'W' ;
        *DesaPtr++ = ')' ;
}

static void cat_Imme(int siz, MPTR *pc)
{
        *DesaPtr++ = '#' ;
        if (siz) {
          cat_hexa_long(read_st_long(*pc)) ;
          *pc += 4 ;
        }
        else {
          cat_hexa_word(read_st_word(*pc)) ;
          *pc += 2 ;
        }
}

        int do_decal(int d, int s)
        {
          if (s)
            return d>>1 ;
           else
            return d<<1 ;
        } ;

static void cat_regmask(int regmaski, int ispredecrem) // mask inverted if -(Ax)
{
        int i ;
        int testmask ;
        int testbit ;
        int decal ;
        int msk = regmaski ;

        if (ispredecrem) {
                testmask = 0xff00 ;
                testbit = 0x8000 ;
                decal = 0 ;
        } else {
                testmask = 0x00ff ;
                testbit = 0x0001 ;
                decal = 1 ;
        }

                if (msk&testmask) {
                        *DesaPtr++ = 'D' ;
                        for (i='0';i<'8';i++,msk = do_decal(msk,decal))
                                if (msk&testbit) *DesaPtr++ = i ;
                if (msk&testmask) *DesaPtr++ = '/' ;
                }
                        if (msk&testmask) {
                        *DesaPtr++ = 'A' ;
                        for (i='0';i<'8';i++,msk = do_decal(msk,decal))
                                if (msk&testbit) *DesaPtr++ = i ;
        }
}

static void cat_ea(int ea, MPTR *pc)
{
        int mode, reg, siz ;
        mode = (ea>>3)&7 ;
        reg = ea&7 ;
        siz = (ea>>8)&1 ;

        switch(mode) {
                case 0: cat_Dreg(reg) ; break ;
                case 1: cat_Areg(reg) ; break ;
                case 2: cat_Aind(reg) ; break ;
                case 3: cat_Aipi(reg) ; break ;
                case 4: cat_Aipd(reg) ; break ;
                case 5: cat_Ad16(reg, pc) ; break ;
                case 6: cat_Ad8r(reg, pc) ; break ;
                case 7: switch(reg) {
                        case 0: cat_Absw(pc) ; break ;
                        case 1: cat_AbsL(pc) ; break ;
                        case 2: cat_Pc16(pc) ; break ;
                        case 3: cat_Pc8r(pc) ; break ;
                        case 4: cat_Imme(siz,pc) ; break ;
                }
        } ;
}

/////////////////////////////////////////////////////////////////////////////

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "NONE"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ */
static void disa_Type_None(UWORD Instr, MPTR *pc)
{
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "ABCD"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA9 8 7654   3 210   R/M = 0 -> data register     Dy,Dx
ฺฤฤฤฤยฤฤฤยฤยฤฤฤฤยฤฤฤยฤฤฤฟ  R/M = 1 -> adresse register -(Ay),-(Ax)
ณ####ณRx ณ#ณ####ณR/MณRy ณ  Rx : destination register
ภฤฤฤฤมฤฤฤมฤมฤฤฤฤมฤฤฤมฤฤฤู  Ry : source register
*/

static void disa_Type_ABCD(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        if ((Instr&8)==8) {     // type -(Ay),-(Ax)
                cat_Aipd(Instr&7) ;
                *DesaPtr++ = ',' ;
                cat_Aipd((Instr>>9)&7) ;
        } else {
                cat_Dreg(Instr&7) ;
                *DesaPtr++ = ',' ;
                cat_Dreg((Instr>>9)&7) ;
        }
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "ADD"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC  B  A  9   8 7 6   543   2 1 0                     .b     .w      .l
ฺฤฤฤฤยฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ####ณRegistre ณOP-ModeณModeณRegisterณ Op-Modes:        000     001     010     Dn + EA -> Dn
ภฤฤฤฤมฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู                  100     101     110     EA + Dn -> EA

*/

static void disa_Type_ADD(UWORD Instr, MPTR *pc)
{
        //int fakesize = Instr;
        int datasrc = (Instr>>8)&1 ;
        cat_size((Instr>>6)&3) ;
        //if (!(Instr&0x40)) fakesize=0x100 ;
        //Instr = (Instr&0xfeff)|fakesize ;

        if (Instr&0x40) Instr|=0x100 ;
        else Instr&=~0x100 ;


        *DesaPtr++='\t' ;
        if (datasrc)           // Bit 3 OpMode … 1 => Dn source
                {
                        cat_Dreg((Instr>>9)&7) ;
                        *DesaPtr++ = ',' ;
                        cat_ea(Instr,pc) ;
                }
                        else
                {
                        cat_ea(Instr,pc) ;
                        *DesaPtr++ = ',' ;
                        cat_Dreg((Instr>>9)&7) ;
                }

}


/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "ADDA"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC  B  A  9   8 7 6   543   2 1 0
ฺฤฤฤฤยฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ####ณRegistre ณOP-ModeณModeณRegisterณ   ADDA <AE>, An
ภฤฤฤฤมฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
                 s 1 1  \___ E.A. __/

*/

static void disa_Type_ADDA(UWORD Instr, MPTR *pc)
{
        cat_size_wl((Instr>>8)&1) ;
        *DesaPtr++='\t' ;
        cat_ea(Instr,pc) ;
        *DesaPtr++ = ',' ;
        cat_Areg((Instr>>9)&7) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "ADDI"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDCBA98  76   543   2 1 0
ฺฤฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ########ณSizeณModeณRegisterณ   ADDI #nnnn, EA
ภฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู

*/

static void disa_Type_ADDI(Instr,pc)
UWORD Instr ;
MPTR *pc ;
{
        int siz = ((Instr>>6)&3) ;
        cat_size(siz) ;
        *DesaPtr++='\t' ;
        *DesaPtr++ = '#' ;
        switch(siz) {
                case 0 : cat_hexa_byte(read_st_byte(1+*pc)) ; *pc += 2 ; break ;
                case 1 : cat_hexa_word(read_st_word(*pc)) ; *pc += 2 ; break ;
                case 2 : cat_hexa_long(read_st_long(*pc)) ; *pc += 4 ; break ;
                default:
                        *DesaPtr++ = '?' ;
        }
        *DesaPtr++ = ',' ;
        cat_ea(Instr,pc) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "ADDQ"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC  BA9  8  76  543   2 1 0
ฺฤฤฤฤยฤฤฤฤฤยฤยฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ####ณValueณ#ณSizeณModeณRegisterณ
ภฤฤฤฤมฤฤฤฤฤมฤมฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู

*/

static void disa_Type_ADDQ(UWORD Instr, MPTR *pc)
{
        int value = (Instr>>9)&7 ;
        if (value==0) value = 8 ;
        cat_size((Instr>>6)&3) ;
        *DesaPtr++='\t';
        *DesaPtr++='#' ;
        cat_hexa_byte(value) ;
        *DesaPtr++ = ',' ;
        cat_ea(Instr,pc) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "ADDX"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA9 8 7654   3 210   R/M = 0 -> data register     Dy,Dx
ฺฤฤฤฤยฤฤฤยฤยฤฤฤฤยฤฤฤยฤฤฤฟ  R/M = 1 -> adresse register -(Ay),-(Ax)
ณ####ณRx ณ#ณ####ณR/MณRy ณ  Rx : destination register
ภฤฤฤฤมฤฤฤมฤมฤฤฤฤมฤฤฤมฤฤฤู  Ry : source register

                .b      .w      .l
        Sizes:  00      01      10

*/
static void disa_Type_ADDX(UWORD Instr, MPTR *pc)
{
        cat_size((Instr>>6)&3) ;
        disa_Type_ABCD(Instr,pc) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "AND"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC  B  A  9   8 7 6   543   2 1 0                     .b     .w      .l
ฺฤฤฤฤยฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ  Op-Modes:       000     001     010     Dn & EA -> Dn
ณ####ณRegistre ณOP-ModeณModeณRegisterณ                  100     101     110     EA & Dn -> EA
ภฤฤฤฤมฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
        Dn              \___ E.A. __/

*/

static void disa_Type_AND(UWORD Instr, MPTR *pc)
{
        disa_Type_ADD(Instr,pc) ;       // Identique sauf pour AND Ax,..
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "i2CCR"                         บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ
        (ANDI to CCR)
*/
static void disa_Type_i2CCR(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        *DesaPtr++ = '#' ;
        cat_hexa_byte(read_st_byte(*pc+1)) ;
        *DesaPtr++ = ',' ;
        *DesaPtr++ = 'C' ;
        *DesaPtr++ = 'C' ;
        *DesaPtr++ = 'R' ;
        *pc += 2 ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "i2SR"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ
        (ANDI to SR, EORI to SR)
*/

static void disa_Type_i2SR(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        *DesaPtr++ = '#' ;
        cat_hexa_word(read_st_word(*pc)) ;
        *DesaPtr++ = ',' ;
        *DesaPtr++ = 'S' ;
        *DesaPtr++ = 'R' ;
        *pc += 2 ;

}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "ASL_Dx"                        บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC  BA9    8   76  5   43   2 1 0            dir: (0=right, 1=left)
ฺฤฤฤฤยฤฤฤฤฤฤยฤฤฤยฤฤฤฤยฤฤฤยฤฤยฤฤฤฤฤฤฤฤฟ          .b      .w      .l
ณ####ณNb/RegณdirณSizeณi/rณ##ณRegisterณ  Size:   00      01      10
ภฤฤฤฤมฤฤฤฤฤฤมฤฤฤมฤฤฤฤมฤฤฤมฤฤมฤฤฤฤฤฤฤฤู  i/r:    0 = #nb shifts
                                                                                                                                                                        1 = Dx  shifts
*/

static void disa_Type_ASL_Dx(UWORD Instr, MPTR *pc)
{
        int reg = ((Instr>>9)&7) ;
        cat_size((Instr>>6)&3) ;
        *DesaPtr++='\t' ;
        if (Instr&0x20) {               // Dx
                cat_Dreg(reg) ;
        } else {                        // #
                *DesaPtr++ = '#' ;
                cat_hexa_byte(reg) ;
        }
        *DesaPtr++ = ',' ;
        cat_Dreg(Instr&7) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "ASL_EA"                        บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ
 FEDCBA9  8  76  543   2 1 0
ฺฤฤฤฤฤฤฤยฤฤฤยฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ#######ณdirณ##ณModeณRegistreณ
ภฤฤฤฤฤฤฤมฤฤฤมฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
                \___ E.A. __/
*/

static void disa_Type_ASL_EA(UWORD Instr, MPTR *pc)
{
        cat_size(1)     ; // always on word
        *DesaPtr++='\t' ;
        cat_ea(Instr,pc) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "BRA"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC     BA98     76543210
ฺฤฤฤฤยฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
ณ####ณConditiongณ8 bits offsetณ
รฤฤฤฤมฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤด
ณ        16 bits offset       ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

*/

static void disa_Type_BRA(UWORD Instr, MPTR *pc)
{
        MPTR pc2 = *pc;
        signed int offset ;

        if (Instr&0xff) {               //short branch
                *DesaPtr++ = '.' ;
                *DesaPtr++ = 'S' ;
                offset = (signed int)(signed short)(signed char)(Instr&0xff) ;
        } else {
                offset = (signed int)(signed short)read_st_word(*pc) ;
                *pc += 2 ;
        }
        *DesaPtr++='\t' ;
        cat_hexa_long(pc2+offset) ;
}


/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "BCHG_Dx"                       บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA9 876  543  2 1 0
ฺฤฤฤฤยฤฤฤยฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ####ณDx ณ###ณModeณRegisterณ
ภฤฤฤฤมฤฤฤมฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
              \___ E.A. __/
*/

static void disa_Type_BCHG_Dx(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        cat_Dreg((Instr>>9)&7) ;
        *DesaPtr ++ = ',' ;
        cat_ea(Instr,pc) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "BCHG_n"                        บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDCBA9876  543  2 1 0
ฺฤฤฤฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ##########ณModeณRegisterณ>EA
รฤฤฤฤฤฤฤฤฤฤลฤฤฤฤมฤฤฤฤฤฤฤฤด
ณ##########ณ bit number  ณ
ภฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤู

*/

static void disa_Type_BCHG_n(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        *DesaPtr++ = '#' ;
        cat_hexa_byte(read_st_byte(1+*pc)) ;
        *DesaPtr++ = ',' ;
        *pc += 2 ;
        cat_ea(Instr,pc) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "CHK"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC   B A 9  876  543  2 1 0
ฺฤฤฤฤยฤฤฤฤฤฤฤฤยฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ####ณRegisterณ###ณModeณRegisterณ
ภฤฤฤฤมฤฤฤฤฤฤฤฤมฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
                   \___ E.A. __/
*/

static void disa_Type_CHK(UWORD Instr, MPTR *pc)
{
        int fakesize = (Instr&0x3f);
        *DesaPtr++='\t' ;
        cat_ea(fakesize,pc) ;
        *DesaPtr++ = ',' ;
        cat_Dreg((Instr>>9)&7) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "CLR"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ
 FEDCBA98  76  543  2 1 0
ฺฤฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ b  00
ณ########ณSizeณModeณRegisterณ w  01
ภฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู l  10
               \___ E.A. __/
*/

static void disa_Type_CLR(UWORD Instr, MPTR *pc)
{
        cat_size((Instr>>6)&3) ;
        *DesaPtr++='\t' ;
        cat_ea(Instr,pc) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "CMP"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ
 FEDC  B  A  9   8 7 6   543   2 1 0
ฺฤฤฤฤยฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ####ณRegistre ณOP-ModeณModeณRegisterณ CMP <EA>, Dn
ภฤฤฤฤมฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
        Dn              \___ E.A. __/                   .b      .w      .l
                                       Op-Modes:        000     001     010

*/

static void disa_Type_CMP(UWORD Instr, MPTR *pc)
{
        cat_size((Instr>>6)&3) ;
        *DesaPtr++='\t' ;

        cat_ea(Instr,pc) ;
        *DesaPtr++ = ',' ;
        cat_Dreg((Instr>>9)&7) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "CMPM"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA9 8  76  543 210        CMPM (Ay)+,(Ax)+
ฺฤฤฤฤยฤฤฤยฤยฤฤฤฤยฤฤฤยฤฤฤฟ
ณ####ณAx ณ#ณSizeณ###ณAy ณ  Ax : destination register
ภฤฤฤฤมฤฤฤมฤมฤฤฤฤมฤฤฤมฤฤฤู  Ay : source register

*/

static void disa_Type_CMPM(UWORD Instr, MPTR *pc)
{
        cat_size((Instr>>6)&3) ;
        *DesaPtr++='\t' ;
        cat_Aipi(Instr&7) ;
        *DesaPtr++ = ',' ;
        cat_Aipi((Instr>>9)&7) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "DBF"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC    BA98    76543    210
ฺฤฤฤฤยฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ####ณConditiongณ#####ณRegisterณ
รฤฤฤฤมฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤมฤฤฤฤฤฤฤฤด
ณ        16 bits offset        ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

*/

static void disa_Type_DBF(UWORD Instr, MPTR *pc)
{
        signed int offset = (signed int)(signed short)read_st_word(*pc) ;
        *DesaPtr++= '\t' ;
        cat_Dreg(Instr&7) ;
        *DesaPtr++ = ',' ;
        cat_hexa_long(offset+*pc) ;
        *pc += 2 ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "EOR"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC  B  A  9   8 7 6   543   2 1 0
ฺฤฤฤฤยฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ                   .b     .w      .l
ณ####ณRegistre ณOP-ModeณModeณRegisterณ Op-Modes:        100     101     110     EA & Dn -> EA
ภฤฤฤฤมฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
        Dn              \___ E.A. __/

*/

static void disa_Type_EOR(UWORD Instr, MPTR *pc)
{
        disa_Type_AND(Instr,pc) ;       // identique mais TOUJOURS <AE> destination
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "EXG"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA9 8  76543  210
ฺฤฤฤฤยฤฤฤยฤยฤฤฤฤฤฤฤยฤฤฤฟ
ณ####ณRx ณ#ณOP-ModeณRy ณ  Rx : data register
ภฤฤฤฤมฤฤฤมฤมฤฤฤฤฤฤฤมฤฤฤู  Ry : address / data register

 OP-Modes:      01000 -> data registers
                01001 -> address registers
                10001 -> data & address registers
*/

static void disa_Type_EXG(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        switch((Instr>>3)&0x1f) {       // type des registres
                case 0x08 :     cat_Dreg((Instr>>9)&7) ;
                                *DesaPtr++ = ',' ;
                                cat_Dreg(Instr&7) ;
                                break ;
                case 0x09 :     cat_Areg((Instr>>9)&7) ;
                                *DesaPtr++ = ',' ;
                                cat_Areg(Instr&7) ;
                                break ;
                case 0x11 :     cat_Dreg((Instr>>9)&7) ;
                                *DesaPtr++ = ',' ;
                                cat_Areg(Instr&7) ;
                                break ;
                default:
                                *DesaPtr++ = '?' ;
        }
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "EXT"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDCBA9   876   543   210
ฺฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤยฤฤฤฤฤฤฤฤฟ  OP-Modes:       010 byte to word
ณ#######ณOP-Modeณ###ณRegisterณ            011 word to longword
ภฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤมฤฤฤฤฤฤฤฤู

*/

static void disa_Type_EXT(UWORD Instr, MPTR *pc)
{
        *DesaPtr++ = '.' ;
        if (Instr&0x40) *DesaPtr++='L' ; else *DesaPtr++='W' ;
        *DesaPtr++='\t' ;
        cat_ea(Instr&7,pc) ;
}


/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "JMP"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA98 76
ฺฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ#### #### ##ณModeณRegisterณ
ภฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
              \___ E.A. __/
*/

static void disa_Type_JMP(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        cat_ea(Instr,pc) ;
}


/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "LEA"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC  B  A  9  876 543   2 1 0
ฺฤฤฤฤยฤฤฤฤฤฤฤฤฤยฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ####ณRegister ณ###ณModeณRegisterณ
ภฤฤฤฤมฤฤฤฤฤฤฤฤฤมฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
        An          \___ E.A. __/
*/

static void disa_Type_LEA(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        cat_ea(Instr,pc) ;
        *DesaPtr++ = ',' ;
        cat_Areg((Instr>>9)&7) ;
}


/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "LINK"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA98 7654 3    210
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ#### #### #### #ณRegisterณ
รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤด
ณ          Offset         ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

*/

static void disa_Type_LINK(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        cat_Areg(Instr&7) ;
        *DesaPtr++ = ',' ;
        *DesaPtr++ = '#' ;
        cat_hexa_word(read_st_word(*pc)) ;
        *pc += 2 ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "MOVE"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FE   DC  B  A  9   8 7 6   543   2 1 0
ฺฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ####ณSizeณRegisterณModeณModeณRegisterณ Size:  01=b, 11=w, 10=l
ภฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
           \destination/|   source   /
            \__ E.A.__/  \__ E.A. __/
*/

static void disa_Type_MOVE(UWORD Instr, MPTR *pc)
{
        int mode, reg ;
        int fakeinstr ;

        fakeinstr = Instr ; // on triche pour la taille en bit 8


        *DesaPtr++ = '.' ;
        switch((Instr>>12)&3) {
                case 1: *DesaPtr++ = 'B' ; break ;
                case 2: *DesaPtr++ = 'L' ; fakeinstr|=0x100 ;break ;
                case 3: *DesaPtr++ = 'W' ;
        }
        *DesaPtr++='\t' ;

        if ((Instr&0x3f)==0x3c)         // immediate
        {
                *DesaPtr++ = '#' ;
                switch ((Instr>>12)&3)
                {
                        case 1 : cat_hexa_byte(read_st_byte(1+*pc)) ; *pc += 2 ; break ;
                        case 2 : cat_hexa_long(read_st_long(*pc)) ; *pc += 4 ; break;
                        case 3 : cat_hexa_word(read_st_word(*pc)) ; *pc += 2 ; break ;
                }

        } else         cat_ea(fakeinstr,pc) ;


        *DesaPtr++ = ',' ;
        mode = (Instr>>6)&7 ;
        reg = (Instr>>9)&7 ;
        cat_ea((mode<<3)+reg,pc) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "2CCR"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA98 76
ฺฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ#### #### ##ณModeณRegisterณ
ภฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
              \___ E.A. __/

*/

static void disa_Type_2CCR(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        cat_ea(Instr,pc) ;
        *DesaPtr++ = ',' ;
        *DesaPtr++ = 'C' ;
        *DesaPtr++ = 'C' ;
        *DesaPtr++ = 'R' ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "MOVEA"                         บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FE    DC    BA9    876  543   2 1 0
ฺฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤยฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ####ณSizeณRegistreณ###ณModeณRegisterณ   MOVEA <AE>, An
ภฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤมฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
                        \___ E.A. __/
*/

static void disa_Type_MOVEA(UWORD Instr, MPTR *pc)
{
        int fakesize = (Instr&0x3f);   // fake instruction to work with <ea>

        *DesaPtr++ = '.' ;
        if ((Instr&0xf000)==0x3000)
                *DesaPtr++ = 'W' ;
                else { *DesaPtr++ = 'L' ; fakesize |=0x100 ; }
        *DesaPtr++='\t' ;
        cat_ea(fakesize,pc) ;
        *DesaPtr++ = ',' ;
        cat_Areg((Instr>>9)&7) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "2USP"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA98 7654 3  2 1 0
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ#### #### #### #ณRegisterณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤู
                                                                                An
*/

static void disa_Type_2USP(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        cat_Areg(Instr&7) ;
        *DesaPtr++ = ',' ;
        *DesaPtr++ = 'U' ;
        *DesaPtr++ = 'S' ;
        *DesaPtr++ = 'P' ;
}


/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "USP2"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA98 7654 3  2 1 0
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ#### #### #### #ณRegisterณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤู
                                                                                An
*/

static void disa_Type_USP2(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        *DesaPtr++ = 'U' ;
        *DesaPtr++ = 'S' ;
        *DesaPtr++ = 'P' ;
        *DesaPtr++ = ',' ;
        cat_Areg(Instr&7) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "SR2"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA98 76 543    2 1 0
ฺฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ#### #### ##ณModeณRegisterณ
ภฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
              \___ E.A. __/
*/

static void disa_Type_SR2(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        *DesaPtr++ = 'S' ;
        *DesaPtr++ = 'R' ;
        *DesaPtr++ = ',' ;
        cat_ea(Instr,pc) ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "2SR"                           บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA98 76 543    2 1 0
ฺฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ#### #### ##ณModeณRegisterณ
ภฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
              \___ E.A. __/
*/

static void disa_Type_2SR(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        cat_ea(Instr,pc) ;
        *DesaPtr++ = ',' ;
        *DesaPtr++ = 'S' ;
        *DesaPtr++ = 'R' ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "MOVEM2mem"                     บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA98 7  6    543   2 1 0
ฺฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ#### #### #ณSizeณModeณRegisterณ  Size: 0=word 1=longword
รฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤด
ณ       Registers mask         ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
                  \___ E.A.___/
*/

static void disa_Type_MOVEM2mem(UWORD Instr, MPTR *pc)
{
        int regmask = read_st_word(*pc) ;
        *pc += 2 ;
        *DesaPtr++ = '.' ;
        if (Instr&0x40) //taille
                *DesaPtr++ = 'L' ;
         else
                *DesaPtr++ = 'W' ;
        *DesaPtr++='\t' ;
        cat_regmask(regmask,((Instr&0x38)==0x20)) ; //is it -(Ax) adressing mode?
        *DesaPtr++ = ',' ;
        cat_ea(Instr,pc) ;
}


/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "MOVEMmem2"                     บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA98 7  6    543   2 1 0
ฺฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ#### #### #ณSizeณModeณRegisterณ Size: 0=word 1=longword
รฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤด
ณ       Registers mask         ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
                  \___ E.A.___/
*/

static void disa_Type_MOVEMmem2(UWORD Instr, MPTR *pc)
{
        int regmask = read_st_word(*pc) ;
        *pc += 2 ;
        *DesaPtr++ = '.' ;
        if (Instr&0x40) //taille
                *DesaPtr++ = 'L' ;
         else
                *DesaPtr++ = 'W' ;
        *DesaPtr++='\t' ;
        cat_ea(Instr,pc) ;
        *DesaPtr++ = ',' ;
        cat_regmask(regmask,0) ;

}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "MOVEP_2Dx"                     บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

FEDC BA9 87   6  543 210
ฺฤฤฤฤยฤฤฤยฤฤยฤฤฤฤยฤฤฤยฤฤฤฟ
ณ####ณDx ณ10ณSizeณ###ณAy ณ
รฤฤฤฤมฤฤฤมฤฤมฤฤฤฤมฤฤฤมฤฤฤด
ณ      16 bits offset    ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

*/

static void disa_Type_MOVEP_2Dx(UWORD Instr, MPTR *pc)
{
        *DesaPtr++ = '.' ;
        if ((Instr&0x40))
                *DesaPtr++ = 'L' ;
          else *DesaPtr++ = 'W' ;
        *DesaPtr++='\t' ;
        cat_Ad16(Instr&7,pc) ;
        *DesaPtr++ = ',' ;
        cat_Dreg((Instr>>9)&7) ;
}


/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "MOVEP_Dx2"                     บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

ฺฤฤฤฤยฤฤฤยฤฤยฤฤฤฤยฤฤฤยฤฤฤฟ
ณ####ณDx ณ11ณSizeณ###ณAy ณ
รฤฤฤฤมฤฤฤมฤฤมฤฤฤฤมฤฤฤมฤฤฤด
ณ      16 bits offset    ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

*/
static void disa_Type_MOVEP_Dx2(UWORD Instr, MPTR *pc)
{
        *DesaPtr++ = '.' ;
        if ((Instr&0x40))
                *DesaPtr++ = 'L' ;
          else *DesaPtr++ = 'W' ;
        *DesaPtr++='\t' ;
        cat_Dreg((Instr>>9)&7) ;
        *DesaPtr++ = ',' ;
        cat_Ad16(Instr&7,pc) ;
}


/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "MOVEQ"                         บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC    BA9   8 76543210
ฺฤฤฤฤยฤฤฤฤฤฤฤฤยฤยฤฤฤฤฤฤฤฤฟ
ณ####ณRegisterณ#ณ  Data  ณ
ภฤฤฤฤมฤฤฤฤฤฤฤฤมฤมฤฤฤฤฤฤฤฤู

*/

static void disa_Type_MOVEQ(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        *DesaPtr++ = '#' ;
        cat_hexa_byte(Instr&0xff) ;
        *DesaPtr++ = ',' ;
        cat_Dreg((Instr>>9)&7) ;
}


/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "NBCD"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA98 76
ฺฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ#### #### ##ณModeณRegisterณ
ภฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤมฤฤฤฤฤฤฤฤู
              \___ E.A. __/

*/

static void disa_Type_NBCD(UWORD Instr, MPTR *pc)
{
        disa_Type_JMP(Instr,pc) ;// identique sauf pour certains modes d'adr.
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "STOP"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC  BA98  7654  3210
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
ณ ####  ####  ####  #### ณ
รฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด
ณ      16 bits value     ณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
*/

static void disa_Type_STOP(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        *DesaPtr++ = '#' ;
//        *DesaPtr++ = '$' ;
        cat_hexa_word(read_st_word(*pc)) ;
        *pc += 2 ;
}

/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "SWAP"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA98 7654 3   210
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ#### #### #### #ณRegisterณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤู
*/

static void disa_Type_SWAP(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        cat_ea(Instr&7,pc) ;
}


/*                              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                                บ   Dsassemblage  ณ Type "TRAP"                          บ
                                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

FEDC BA98 7654  3210
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฟ
ณ#### #### ####ณVectorณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤู

*/

static void disa_Type_TRAP(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        *DesaPtr++ = '#' ;
        *DesaPtr++ = '$' ;
        cat_hexa_nibble(Instr&15) ;

}


/*              ษออออออออออออออออออัออออออออออออออออออออออออออออออออออออออป
                บ   Dsassemblage  ณ Type "UNLK"                          บ
                ศออออออออออออออออออฯออออออออออออออออออออออออออออออออออออออผ

 FEDC BA98 7654 3   210
ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฟ
ณ#### #### #### #ณRegisterณ
ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤู

*/

static void disa_Type_UNLK(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        cat_Areg(Instr&7) ;
}

static void disa_Type_DATA(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        cat_hexa_word(Instr) ;
}

static void disa_Type_PATCH(UWORD Instr, MPTR *pc)
{
        *DesaPtr++='\t' ;
        cat_hexa_word(read_st_word(*pc)) ;
        *pc+=2 ;
}

static void cat_Rc(int RC)
{
        switch(RC) {
                case 0x000 : strcpy(DesaPtr,"SFC ") ;
                             break ;
                case 0x001 : strcpy(DesaPtr,"DFC ") ;
                             break ;
                case 0x002 : strcpy(DesaPtr,"CACR") ;
                             break ;
                case 0x800 : strcpy(DesaPtr,"USP ") ;
                             break ;
                case 0x801 : strcpy(DesaPtr,"VBR ") ;
                             break ;
                case 0x802 : strcpy(DesaPtr,"CAAR") ;
                             break ;
                case 0x803 : strcpy(DesaPtr,"MSP ") ;
                             break ;
                case 0x804 : strcpy(DesaPtr,"ISP ") ;
                             break ;
                default :    strcpy(DesaPtr,"??? ") ;
        }
        DesaPtr+=4 ;
}

static void disa_Type_MOVEC(UWORD Instr, MPTR *pc)
{
        int param ;
        char r ;

        *DesaPtr++='\t' ;
        param = read_st_word(*pc) ;
        *pc+= 2 ;

        if (param&0x8000) r = 'A' ; else r = 'D' ;


        if (Instr&1) {
                        // Rn to Rc
                *DesaPtr++ = r ;
                *DesaPtr++ = ((param>>12)&7)+'0' ;
                *DesaPtr++ = ',' ;
                cat_Rc(param&0xfff) ;
        } else {
                cat_Rc(param&0xfff) ;
                *DesaPtr++ = ',' ;
                *DesaPtr++ = r ;
                *DesaPtr++ = ((param>>12)&7)+'0' ;
        }

}

static void disa_Type_FPU(UWORD Instr, MPTR *pc)
{
        *pc+=2 ;
        *DesaPtr++ = '\t' ;
        cat_ea(Instr&0x3f,pc) ;
}

/////////////////////////////////////////////////////////////////////////////

typedef char *foncd(UWORD, MPTR *) ;
static foncd *Foncs_Desa[] =
 {
        disa_Type_None, disa_Type_ABCD, disa_Type_ADD,
        disa_Type_ADDA, disa_Type_ADDI, disa_Type_ADDQ,
        disa_Type_ADDX, disa_Type_AND, disa_Type_i2CCR,
        disa_Type_i2SR, disa_Type_ASL_Dx, disa_Type_ASL_EA,
        disa_Type_BRA, disa_Type_BCHG_Dx, disa_Type_BCHG_n,
        disa_Type_CHK, disa_Type_CLR, disa_Type_CMP,
        disa_Type_CMPM, disa_Type_DBF,disa_Type_EOR,
        disa_Type_EXG, disa_Type_EXT, disa_Type_JMP,
        disa_Type_LEA, disa_Type_LINK, disa_Type_MOVE,
        disa_Type_2CCR, disa_Type_MOVEA, disa_Type_2USP,
        disa_Type_USP2, disa_Type_SR2, disa_Type_2SR,
        disa_Type_MOVEM2mem, disa_Type_MOVEMmem2, disa_Type_MOVEP_2Dx,
        disa_Type_MOVEP_Dx2, disa_Type_MOVEQ, disa_Type_NBCD,
        disa_Type_STOP, disa_Type_SWAP, disa_Type_TRAP,
        disa_Type_UNLK, disa_Type_DATA, disa_Type_PATCH,
        disa_Type_MOVEC, disa_Type_FPU
 } ;

char DesaString[80] ;


/*ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤาฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
 *ณVoid disa_instr(MPTR adr, char *disa_string, int *siz) บ               ณ
 *ฦอออออออออออออออออออออออออออออออออออออออออออออออออออออออผ               ณ
 *ณ                                                                       ณ
 *ณ      adr: Adress of the instruction to disasm                         ณ
 *ณ                                                                       ณ
 *ณ      Disa_String: ^Disassembly string                                 ณ
 *ณ                                                                       ณ
 *ณ      size: taille de l'instruction                                    ณ
 *ณ                                                                       ณ
 *ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
 */

void disa_instr(MPTR adr, char *disa_string, int *siz)
 {
  struct Entry_Instr_68000 *p ;
  UWORD opcode ;
  UWORD andmask ;
  MPTR adr0 ;
  int i ;

        adr0 = adr ;
        opcode = read_st_word(adr) ;
        p = Table_Instr_68000 ;

        while ((andmask=p->AndMask)&&((andmask&opcode)!=p->CmpMask)) p++ ;

        adr+=2 ;
        DesaPtr = DesaString ;
        for (i=0;i<6;i++)
                if (p->InstrName[i]!=' ')
                *DesaPtr++=p->InstrName[i] ;
                (*Foncs_Desa[p->Coding])(opcode,&adr) ;
                *DesaPtr++ = 0 ;

        *siz = adr - adr0 ;
        strcpy(disa_string,DesaString) ;
 }

