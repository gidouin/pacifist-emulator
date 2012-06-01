#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "eval.h"
#include "cpu68.h"

extern MPTR searchresults[128] ;       // array of memory locations found
extern int nbresults ;                 // number of memory locations found



int search_variable(char *varname, int *idx) ;

int nb_variables = 0 ;


struct {
        char name[16] ;
        int attrib ;
        int value ;
} variables[MAX_NB_VARIABLES] ;





char  *p;
int     err_level;
char globalmsg[128] ;
void	set_error (int error) ;
int	eval(char *str, int *value) ;
int A();
int B();
int C();
int CD() ;
int D();
int E();

char next(void)
 {
      if (*p == 0)
         return toupper(*p);
      else
         return toupper(*(++p));
 };




int readInteger()
   { char c   = *p;
     int val = 0;

      while ((c >= '0') && (c <= '9'))
      {  val = val * 10 + (c - '0');
         c = next ();
      };
      return val;
   };


int	ishexa(char c)
{

	if ( (isdigit(c)) || ((c>='A') && (c<='F'))) return -1;
	return 0;

}

int	isregi(char c)
{
	if ((c>='0') && (c<='7')) return -1;
	return 0;
}


int testvariable(int *v)
{
        char varname[16] ;
        int nb ;
        int value ;

//        if ((*(2+p) >= '0')&&(*(2+p) <= 'F')) return FALSE ;

        switch (*p) {

          case 'P' : if (*(1+p)=='C')
                     { *v = processor->PC ;
                       p+=2 ;
                     } else return FALSE ;
                     break ;

          case 'D' : if ((*(1+p)>='0')&&(*(1+p)<='7')) // Dx?
                     { *v = processor->D[*(1+p)-'0'] ;
                       p+=2 ;
                     } else return FALSE ;
                     break ;

          case 'A' : if ((*(1+p)>='0')&&(*(1+p)<='7')) // Dx?
                     { *v = processor->A[*(1+p)-'0'] ;
                        p+=2 ;
                     } else return FALSE ;
                     break ;

          case 'U' :if ((*(1+p)=='S')&&(*(2+p)=='P')) // USP?
                     { *v = processor->A7 ;
                       p+=3 ;
                     } else return FALSE ;
                     break ;

          case 'S' :if ((*(1+p)=='R')) // SR ?
                     { *v = processor->SR ;
                       p+=2 ;
                     } else return FALSE ;
                     break ;
          case 'R':  value = 0 ;
                     p++ ;
                     while ((*p>='0')&&(*p<='9'))
                        value = value*10 + *p++ - '0' ;
                     if ((value <= nbresults)&&value)
                           *v = searchresults[value-1] ;
                        else  *v = 0 ;
                     break ;
          case '_':     p++ ;
                        nb = 0 ;
                        while (*p>='0')
                                varname[nb++] = *p++ ;
                        varname[nb] = 0 ;
                        if (nb&&(varname[0]>='A')) {
                                if (search_variable(varname, &value))
                                        *v = variables[value].value ;
                                else {
                                        set_error(ERR_VARIABLE) ;
                                        return FALSE ;
                                }
                        } else {
                                set_error(ERR_VARIABLE) ;
                                return FALSE ;
                        }
                        break ;
          default :
                     return FALSE ;
        }

        return TRUE ;
}


int     readImmediate(void)
{
        char	c;
        int	val=0,v;

        c=toupper(*p);


	if ((c=='\\') || (c=='#')) {
	//**********************************************************
	// Lit un decimal.
	//**********************************************************
	  c=next();
	  while (isdigit(c)) {
	    val=val*10 + (c-'0');
	    c=next();
	  }

	//**********************************************************
	// Variable?
	//**********************************************************

        } else if (testvariable(&v)) {
                        val = v ;

	//**********************************************************
	// Sinon tente de lire un hexa.
	//**********************************************************
	} else if ((ishexa(c))||(c=='$')) {
          if (c=='$') {
                p++ ;
                c =toupper(*p) ;
          }
	  do {
	    val<<=4;
	    if (isdigit(c))
	      val |= (c-'0') & 15;
	    else
	      val |= ((c-'A')+10) & 15;
	    c=next();
	  } while (ishexa(c));


	//**********************************************************
	// rajoute ici des trucs genre "Dn" ou "An"
	//**********************************************************
	//a faire...

	//**********************************************************
	// Sinon il y a une erreur.
	//**********************************************************
	} else {
	  next();
	  set_error (ERR_EVALIMM);
	}


	return val;
}

int A0()
{
        int res ;
        res = A() ;
        if ((*p == '=')&&(*(p+1)=='=')) {
                p+=2 ;
                return (res == A0()) ;
        }
        return res ;
}

int A ()
{
        int res;

        res = B ();
        if (*p == '+')
        {
                next ();
                return res + A();
         }
        else
          if (*p == '-')
          {
                next ();
                return res - A();
           }
            return res;
};


int B()
{
        int res;

        res = C();
        if (*p == '*')
        {
                next ();
                return res * B();
        }
        else return res ;
};

int C ()
{
        int res,tmp;
        res = CD();

        if (*p == '/')
        {
                next ();
	        tmp=C();
	        if (!tmp) {
	                set_error (ERR_EVALDIVZ);
	        return 0;
	        }
           else return (res / tmp);
       }
      else return res ;
};

int CD()
{
        int res ;
        res = D() ;
        switch(*p) {

         case '>' :
                next() ;
                if (*p == '>') {
                        next() ;
                        return (res >> CD()) ;
                } else if (*p == '=') {
                        next() ;
                        return (res >= CD()) ;
                }
                return (res > CD()) ;

         case '<':
                next() ;
                if (*p == '<') {
                        next() ;
                        return (res << CD()) ;
                } else if (*p == '=') {
                        next() ;
                        return (res <= CD()) ;
                }
                return (res < CD()) ;

        case '&' :
                next() ;
                if (*p == '&') {
                        next() ;
                        return (res&&CD()) ;
                } else return (res&CD()) ;

        case '|' :
                next() ;
                if (*p == '|') {
                        next() ;
                        return (res||CD()) ;
                } else return (res|CD()) ;

        case '^' :
                next() ;
                return (res^CD()) ;

        }
        return res ;
}

int D ()
{
        if (*p == '-')
        {
                next ();
                return -E();
        }
        else if (*p == '~')
        {
                next () ;
                return ~E() ;
        }

        return E() ;
};


int E ()
{
        int res;
        int mask = 0xffffffff;
        int shi = 0 ;
        int isbra = FALSE ;

        if (*p == '(')
        {
                p++ ;
                res = A();
                if (*p == ')')
                        p++ ;
                 else {
	                set_error (ERR_EVALPAR);
	                return 0;
                }
        }
        else if (*p == '[')
        {
                p++ ;
                res = A() ;
                if (*p == ']') {
                        p++ ;
                        res = read_st_long(res) ;
                        isbra=TRUE ;
                } else {
                        set_error(ERR_EVALBRA) ;
                        return 0;
                }
        }
        else res=readImmediate() ;

        if (*p=='.') {
                p++ ;
                switch (*p) {
                        case 'B' : mask &= 0xff ;
                                   shi = 24 ;
                                   break ;
                        case 'W' : mask &= 0xffff ;
                                   shi = 16 ;
                                   break ;
                        case 'L' : mask &= 0xffffffff ;
                                   break ;
                        default :  set_error(ERR_EVALSIZE) ;
                                   return 0 ;
                }
        }

        if (isbra) res>>=shi ;
        return res&mask ;
};


/************************************************************************
*
* Lancement de l'Evaluation d'expression
*
*
* A0:  A==B
* A:   B+A | B-A | B
* B:   C*B | C
* C:   D/C | D
* CD:                  << >>  >  < && || & | ^
* D:   -E  | E | ~E
* E:   (A) | integer | [A]
*
*
* # \  decimal
* $    hexadecimal
* d0-d7,a0-a6,pc,sr,usp
*
************************************************************************/

int	evaluator(char *str,int *value, char **msg)
{
        err_level=0;
        p = str;
        strupr(str) ;
	*value = A0();

        switch(err_level) {
                case ERR_EVALPAR :
                        sprintf(globalmsg,"() error- %s",str) ;
                        break ;
                case ERR_EVALDIVZ :
                        sprintf(globalmsg,"0 Div- %s",str) ;
                        break ;
                case ERR_EVALIMM :
                        sprintf(globalmsg,"imm error- %s",str) ;
                        break ;
                case ERR_EVALSIZE :
                        sprintf(globalmsg,"bad size- %s",str) ;
                        break ;
                case ERR_EVALBRA :
                        sprintf(globalmsg,"[] error- %s",str) ;
                        break ;
                case ERR_VARIABLE:
                        sprintf(globalmsg,"variable error") ;
                        break ;
                case 0 :
                        sprintf(globalmsg,"HEX : %08x DEC : %d", *value, *value) ;
                        break ;
        }
        *msg = globalmsg ;
        return err_level;
}


void	set_error (int error)
{
	if (!err_level)
	  err_level = error;
};


int search_variable(char *varname, int *idx)
{
        int i ;
        for (i=0;i<nb_variables;i++)
                if (variables[i].attrib)
                        if (!stricmp(varname,variables[i].name)) {
                                *idx = i ;
                                return TRUE ;
                        }
        return FALSE ;
}

char errmsg_uv[] = "Unknown Variable" ;
char errmsg_sv[] = "System Variable can't be disposed" ;
char errmsg_ca[] = "Can't change a System Variable" ;

int affect_variable(char *varname, int value, char **msg)
{
        int idx ;
        *msg = globalmsg ;
        globalmsg[0] = 0 ;

        if (!search_variable(varname,&idx)) {        // pas trouv‚, cr‚er
                if (nb_variables >= MAX_NB_VARIABLES) {
                        sprintf(globalmsg,"Maximum number of variables reached") ;
                        return FALSE ;
                }
                strncpy(variables[nb_variables].name,varname,13) ;
                variables[nb_variables].attrib = VARIABLE_USER ;
                variables[nb_variables].value = value ;
                nb_variables++ ;
                return TRUE ;
        }
        if (variables[idx].attrib == VARIABLE_SYSTEM) {
                *msg = errmsg_ca ;
                return FALSE ;
        }
        strncpy(variables[idx].name,varname,13) ;
        variables[idx].attrib = VARIABLE_USER ;
        variables[idx].value = value ;
        return TRUE ;
}


int dispose_variable(char *name,char **msg)
{
        int i,idx ;

        if (!search_variable(name,&idx)) {
                *msg = errmsg_uv ;
                return FALSE ;
        }
        if (variables[idx].attrib==VARIABLE_SYSTEM) {
                *msg = errmsg_sv ;
                return FALSE ;
        }

        if (nb_variables)
         for (i=idx;i<nb_variables-1;i++)
                variables[i] = variables[i+1] ;

        --nb_variables ;
        return TRUE ;
}

int affect_sysvariable(char *name, int value)
{
        strncpy(variables[nb_variables].name,name,13) ;
        variables[nb_variables].attrib = VARIABLE_SYSTEM ;
        variables[nb_variables].value = value ;
        nb_variables++ ;
        return TRUE ;
}

/*
void main()
{
        int v ;
        int errlevel = 0 ;
        char inpu[256] ;


        scanf("%s",inpu) ;
        while (*inpu) {

                errlevel = eval(inpu,&v) ;
                printf("errlevel=%d result=%d\n",errlevel,v) ;
                *inpu = 0 ;
                scanf("%s",inpu) ;
        }
}
*/
