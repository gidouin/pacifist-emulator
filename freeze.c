#include <stdio.h>
#include <string.h>
#include "cpu68.h"
#include "disk.h"

#define ID_HEADER1      'iCaP'
#define ID_HEADER2      '!Zrf'

#define ID_681          '6-cm'
#define ID_682          '0008'

#define ID_IO1          ' o-i'
#define ID_IO2          'aera'

#define ID_RAM1         'mem<'
#define ID_RAM2         '>yro'

#define ID_MFP1         0x010890600
#define ID_MFP2         'enoZ'

#define ID_SHI1         'fIHS'
#define ID_SHI2         '!reT'

#define ID_END1         0xaaaaaaaa
#define ID_END2         0x55555555

typedef struct {
#pragma pack (1) ;
        unsigned int header1 ;                  // "PaCi"
        unsigned int header2 ;                  // "frZ!"
        char major ;                            // major version
        char minor ;                            // minor version
        char ramsize ;                          // memory size
        char nbdrives ;
        char dummy[34] ;
        char text[82] ;                         // texte
} HEADER_FREEZE ;

typedef struct {
#pragma pack (1) ;
        unsigned int header1 ;                  // Chunk Header
        unsigned int header2 ;                  // Chunk Header
        unsigned short crc ;
        unsigned int size ;                     // Chunk size
        unsigned short attributes ;             // Chunk attributes
} CHUNK_FREEZE ;

extern void *STRUCT_WORK_START ;
extern int  STRUCT_WORK_SIZE ;

extern void *STRUCT_MFP_START ;
extern int  STRUCT_MFP_SIZE ;


//static char msg_ok[] =          "ok." ;
static char msg_ok[128] ;
static char msg_err_open[] =    "Error while opening FRZ file." ;
static char msg_err_reading[] = "Error while reading FRZ file." ;
static char msg_err_writing[] = "Error while writing FRZ file." ;
static char msg_err_ram[] =     "Not enough ST RAM allocated at startup." ;

static FILE *fp ;
static char b[80] ;
static nb_saved_chunks ;

int just_unfreezed ;

int save_chunk(int id1,int id2,int attr,void *ptr, int size)
{
        int nb ;
        CHUNK_FREEZE cfreeze ;
        cfreeze.header1 = id1 ;
        cfreeze.header2 = id2 ;
        cfreeze.crc = 0 ;
        cfreeze.size = size + sizeof(CHUNK_FREEZE) ;
        cfreeze.attributes = attr ;
        nb = fwrite(&cfreeze,1,sizeof(CHUNK_FREEZE),fp) ;
        nb+= fwrite(ptr,1,size,fp) ;
        nb_saved_chunks++ ;
        return (nb==(size+sizeof(CHUNK_FREEZE))) ;
}

int load_chunk(CHUNK_FREEZE *cfreeze)
{
        int size = cfreeze->size - sizeof(CHUNK_FREEZE) ;

        if ((cfreeze->header1==ID_681)&&(cfreeze->header2==ID_682)) {

                fread(processor,1,size,fp) ;

//        } else if ((cfreeze->header1==ID_MFP1)&&(cfreeze->header2==ID_MFP2)) {

//                fread(&mfp,1,size,fp) ;

        } else if ((cfreeze->header1==ID_IO1)&&(cfreeze->header2==ID_IO2)) {

                fread(memio,1,size,fp) ;

        } else if ((cfreeze->header1==ID_RAM1)&&(cfreeze->header2==ID_RAM2)) {

                fread(memory_ram,1,size,fp) ;

        } else if ((cfreeze->header1==ID_SHI1)&&(cfreeze->header2==ID_SHI2)) {

                fread(&STRUCT_WORK_START,1,size,fp) ;

        } else if ((cfreeze->header1==ID_MFP1)&&(cfreeze->header2==ID_MFP2)) {

                fread(&STRUCT_MFP_START,1,size,fp) ;

        } else {
                fseek(fp,size,SEEK_CUR) ;
                return FALSE ;
        }
        return TRUE ;
}


int freeze(char *filename,char **msg,char *comments)
{
        HEADER_FREEZE hfreeze ;
        int nb;
        char realname8[10] ;
        char realname[16] ;

        nb_saved_chunks = 0 ;
        memset(&hfreeze,0,sizeof(HEADER_FREEZE)) ;
        memset(realname8,0,10) ;

        hfreeze.header1 = ID_HEADER1 ;
        hfreeze.header2 = ID_HEADER2 ;
        hfreeze.major = pacifist_major ;
        hfreeze.minor = pacifist_minor ;
        hfreeze.ramsize = (processor->ramsize)>>19 ;
        hfreeze.nbdrives = nb_drives ;

        strncpy(hfreeze.text,comments,80) ;
        strncpy(realname8,filename,8) ;
        sprintf(realname,"%s.FRZ",realname8) ;
        strupr(realname,realname) ;

        //fp = fopen("TRYING.FRZ","wb") ;
        fp = fopen(realname,"wb") ;
        if (fp==NULL) {
                *msg = msg_err_open ;
                return FALSE ;
        }

        *msg = msg_err_writing ;        // default message now

        nb = fwrite(&hfreeze,1,sizeof(HEADER_FREEZE),fp) ;
        if (nb != sizeof(HEADER_FREEZE))
                return FALSE;

//*************************** PROCESSOR *****************************

        if (!save_chunk(ID_681,ID_682,0,processor,sizeof(struct tprocessor)))
                return FALSE ;


//****************************** MFP *********************************

        if (!save_chunk(ID_MFP1,ID_MFP2,0,&STRUCT_MFP_START,STRUCT_MFP_SIZE))
               return FALSE ;

//        if (!save_chunk(ID_MFP1,ID_MFP2,0,&mfp,sizeof(mfp)))
//               return FALSE ;

//*************************** SHIFTER *********************************

        if (!save_chunk(ID_SHI1,ID_SHI2,0,&STRUCT_WORK_START,STRUCT_WORK_SIZE))
               return FALSE ;

//****************************** IO *********************************

        if (!save_chunk(ID_IO1,ID_IO2,0,memio,32768))
                return FALSE ;

//****************************** RAM *********************************

        if (!save_chunk(ID_RAM1,ID_RAM2,0,memory_ram,processor->ramsize))
                return FALSE ;

//****************************** END *********************************

        if (!save_chunk(ID_END1,ID_END2,0,&nb_saved_chunks,4))
                return FALSE ;

        sprintf(msg_ok,"Freezing as %s done.",realname) ;
        *msg = msg_ok ;
        fclose(fp) ;
        return TRUE ;
}


int unfreeze(char *filename,char **msg)
{
        HEADER_FREEZE hfreeze ;
        CHUNK_FREEZE cfreeze ;
        int nb ;
        int nb_chunks = 0 ;
        int nb_chunks_in_file = 0 ;
        int last_chunk = FALSE ;
        char realname8[10] ;
        char realname[18] ;
        memset(realname8,0,10) ;

        strncpy(realname8,filename,8) ;
        sprintf(realname,"%s.FRZ",realname8) ;
//        strupr(realname,realname) ;

//        fp=fopen("TRYING.FRZ","rb") ;

        fp = fopen(realname,"rb") ;
        if (fp==NULL) {
                *msg = msg_err_open ;
                return FALSE ;
        }

        *msg = msg_err_reading ;        // default message now

        nb=fread(&hfreeze,1,sizeof(HEADER_FREEZE),fp) ;
        if (nb!=sizeof(HEADER_FREEZE))
                return FALSE ;

        if (allocated_ram < (hfreeze.ramsize<<19)) {
                *msg = msg_err_ram ;
                return FALSE ;
        }


        while (!last_chunk) {
                nb = fread(&cfreeze,1,sizeof(CHUNK_FREEZE),fp) ;

                if (nb!=sizeof(CHUNK_FREEZE))
                        return FALSE ;

                if ((cfreeze.header1 == ID_END1)&&(cfreeze.header2 == ID_END2)) {
                        last_chunk = TRUE ;
                        fread(&nb_chunks_in_file,1,4,fp);
                        }
                else
                        if (load_chunk(&cfreeze))
                                nb_chunks++ ;
        }

        fclose(fp) ;
        sprintf(b,"%d chunks loaded in.",nb_chunks) ;
        *msg = b ;
        return TRUE ;
}

char *remfreeze(char *filename)
{
        int nb ;
        HEADER_FREEZE hfreeze ;
        *b = 0 ;

        fp = fopen(filename,"rb") ;
        if (fp!=NULL) {
                nb=fread(&hfreeze,1,sizeof(HEADER_FREEZE),fp) ;
                if (nb==sizeof(HEADER_FREEZE))
                        strcpy(b,hfreeze.text) ;
                fclose(fp) ;
        }
        return b ;
}

