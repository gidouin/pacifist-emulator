#ifndef __EVAL__
#define __EVAL__


#define	ERR_EVALPAR	-1
#define ERR_EVALDIVZ	-2
#define ERR_EVALIMM	-3
#define ERR_EVALSIZE    -4
#define ERR_EVALBRA     -5
#define ERR_VARIABLE    -6

//extern int	eval(char *str,int *value);

extern int	evaluator(char *str, int *value, char **msg);
extern int      affect_variable(char *name,int value, char **msg) ;
extern int      dispose_variable(char *name,char **msg) ;
extern int      affect_sysvariable(char *name, int value) ;

#define MAX_NB_VARIABLES 1024

#define VARIABLE_FREE   0
#define VARIABLE_SYSTEM 1
#define VARIABLE_USER   2

#endif

