#ifdef DEBUGPROFILE

#include "cpu68.h"
#include "profile.h"


void report_profile(void)
{
        int l,dummy ;
        int allinstructions = 0;
        int allopcodes = 0 ;
        char buf[100],b2[80] ;
        struct Entry_Instr_68000 *p ;
        UWORD andmask ;
        int instructions[nb_profiles] ;
        double l1,l2 ;

        printf("Profiling....\n") ;

        for (l=0;l<nb_profiles;l++) instructions[l]=0 ;
        OUTDEBUG("ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ PROFILE") ;
        for (l=0;l<65536;l++) {
                allinstructions+=profile[l] ;
                if (profile[l]!=0) allopcodes++ ;
        }

        for (l=0;l<256;l++) mem[l] = 0 ;

        for (l=0;l<65536;l++)
         if (profile[l]) {
/*
                write_st_word(0,l) ;
                disa_instr(0,b2,&dummy);
                sprintf(buf,"%04X %-44s  %12d",l,b2,profile[l]) ;
                OUTDEBUG(buf) ;
*/
                p = Table_Instr_68000 ;
                while ((andmask=p->AndMask)&&((andmask&l)!=p->CmpMask))
                        { p++ ;
                        }
                instructions[p->InstrInfo] += profile[l] ;
        }

        profile_all_functions() ;

        sprintf(buf,"ษอออออออออออัอออออออออออออัอออออออออออออป %d different opcodes",allopcodes) ;
        OUTDEBUG(buf) ;
        for (l=0;l<nb_profiles;l++) {
                int k ;
                char name[10],*pt ;
                pt = name ;
                for (k = 0;k<8;k++)
                        *pt++ = profiles_group[l][k] ;
                *pt++ = 0 ;

                l1 = (double)instructions[l] ;
                if (!(l2 = (double)allinstructions)) l2 = 1 ;
                l1 = (1000000*l1)/l2 ;
                sprintf(buf,"บ  %s ณ%#12d ณ\t%7.0f\tบ",name,instructions[l],l1);
                OUTDEBUG(buf) ;
        }
        sprintf(buf,"ศอออออออออออฯอออออออออออออฯอออออออออออออผ %d instructions",allinstructions) ;
        OUTDEBUG(buf);
}


#endif































































