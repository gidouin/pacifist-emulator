/*********************************************************************r*****
*
*        Simulation of System & Peripherals
*
*                * Direct Access to Disk Images (BIOS level)
*
*                * keyboard
*
*                * BIOS-level serial (26/12/96)
*
**************************************************************************/

#include <io.h>
#include <stdio.h>
#include <fcntl.h>
#include <i86.h>
#include <dos.h>
#include <string.h>
#include <bios.h>
#include "cpu68.h"
#include "disk.h"

int drivebits = 3;             // mask of mounted drives
int nb_drives = 2;
tdrive drives[26] ;      // drives with types

int nb_images = 0 ;

void init_images()
{
        int i ;
        for (i=0;i<2;i++) {
                drives[i].kind = DRIVE_IMAGE ;
                drives[i].changed = TRUE ;
                drives[i].empty = TRUE ;
                drives[i].sector = 0 ;
                drives[i].side = 0 ;
                drives[i].track = 0 ;
                drives[i].write_protected = FALSE ;
                drives[i].skiplen = 0 ;
        }
}

unsigned char trackbuffer[11*512] ; // compressed
unsigned char utrackbuffer[11*512] ; // uncompressed

void read_disk_params(tdrive *drive, int verbose)
{
        char b[32] ;
        int sector,side,totalsectors,track ;
        int media,filesize ;
        int found ;
        int ismsa,isdim ;
        int bios_sides ;

        if (drive->kind != DRIVE_IMAGE)
                return ;

        isdim = (int)(strstr(drive->basepath,"DIM")) ;
        if (isdim) drive->skiplen = 32 ;
                else drive->skiplen = 0 ;

        lseek(drive->handle,/*0*/drive->skiplen,SEEK_SET) ;     // DIM
        read(drive->handle,b,32) ;

        ismsa = (((b[0]<<8)|b[1])==0x0e0f) ;
        if (ismsa) {
                char newname[120] ;
                int newfile ;
                int sectorspertrack, nbsides, starttrack, endtrack ;
                int i, j, k ;
                unsigned short tracksize,nb ;
                int iscompressed = FALSE ;
                int corrupted = FALSE ;

                unsigned char byt,*p,*up ;

                sectorspertrack = (b[2]<<8)+b[3] ;
                nbsides = (b[4]<<8)+b[5] ;
                starttrack = (b[6]<<8)+b[7] ;
                endtrack = (b[8]<<8)+b[9] ;

                lseek(drive->handle,10,SEEK_SET) ;

                if (verbose) printf("\t\tMSA file - Sectors: %d - Sides: %d - Tracks: %d-%d\n",sectorspertrack,nbsides+1,starttrack,endtrack) ;
                sprintf(newname,"%s\\pcstimg%d.tmp",tempdir,3+drive->letter-'A') ;

                remove(newname) ;
                    newfile = open(newname,O_CREAT|O_BINARY|O_RDWR,0) ;
                    if (newfile==-1) {
                        if (verbose) printf("\t\tError creating ST file\n") ;
                        goto rdp_abort ;
                }

                 for (i=starttrack;i<=endtrack;i++)
                 for (j=0;j<=nbsides;j++) {
                        int nsrc = 0 ;
                        read(drive->handle,&nb,2) ; // len of track
                        tracksize = (nb>>8)+((nb&0xff)<<8) ;
                        read(drive->handle,trackbuffer,tracksize) ; // cdata
                        corrupted |= (tracksize>(sectorspertrack<<9)) ;
                        if (corrupted) goto msabort ;
                        if (tracksize != sectorspertrack<<9) {
                                iscompressed = TRUE ;
                                p = trackbuffer ;
                                up = utrackbuffer ;
                                k = 0 ;
                                while ((k<(sectorspertrack<<9)&&(nsrc<tracksize))) {
                                        if (*p==0xe5) {
                                                p++ ;
                                                byt = *p++ ; // byte to repeat
                                                nb = ((*p++)<<8)+(*p++) ;
                                                //k += nb;
                                                while ((nb--)&&(k++<(sectorspertrack<<9))) *up++ = byt ;
                                                nsrc+=4 ;
                                        }
                                        else {
                                                nsrc++ ;
                                                *up++=*p++ ;
                                                k++ ;
                                        }
                                }
                        corrupted |= (nsrc!=tracksize) ;
                        write(newfile,utrackbuffer,sectorspertrack<<9) ;
                        }
                        else write(newfile,trackbuffer,sectorspertrack<<9) ;
                }

msabort:
                if (verbose&&corrupted)
                        printf("*** I'm not sure this file is valid ***\n") ;

                if (verbose&&iscompressed)
                        printf("\t\tMSA file is compressed - changes won't be reflected\n") ;

                close(drive->handle) ;
                drive->handle = newfile ;
                strcpy(drive->basepath,newname) ;
                lseek(drive->handle,0,SEEK_SET) ;
                read(drive->handle,b,32) ;
        }

        lseek(drive->handle,0,SEEK_END) ;   //DIM
        filesize = tell(drive->handle) - drive->skiplen ;       // DIM

        media = b[0x15] ;      // MEDIA DESCRIPTOR (0xf1 => IMGBUILD /BLANK)
        sector = b[0x18]+(b[0x19]<<8) ;
        side = b[0x1a]+(b[0x1b]<<8) ;
        totalsectors = b[0x13]+(b[0x14]<<8) ;
        if (sector*side != 0)
                track = totalsectors/(sector*side) ;
        else    track = 0 ;

        drive->sector = drive->bios_sector = sector ;
        drive->side = drive->bios_side = bios_sides = side ;
        drive->track = track ;
        drive->empty = FALSE ;

        if (verbose) printf("\t\t(boot sector indicates SIDE:%d  TRACK:%d  SECTOR:%d)\n",side,track,sector) ;

        if (b[0x15] == 0xf1) {
                if (verbose) printf("\t\tDisk seems to have been created with IMGBUILD.\n") ;
                return ;
        }

        filesize >>= 9 ;        // number of sectors
        drive->bios_one_side= FALSE ;

        if ((sector*side*track == filesize)&&(sector <=11)&&(side<=2)&&(track<=82)) return ;

//------------------------------------- trying to guest disk paramters


        found = FALSE ;
        for (side=1;side<=2;side++)
         for (track=78;track<86;track++)
          for (sector=9;sector<12;sector++)
           if (side*sector*track == filesize) {
                drive->sector = sector ;
                drive->side = side ;
                drive->track = track ;
                found = TRUE ;
        }

        if (found) {
                if (verbose) printf("\t\tIn fact, it should be SIDE:%d  TRACK:%d  SECTOR:%d\n",drive->side,drive->track,drive->sector) ;
                if ((drive->side==2)&&(bios_sides==1)) {
                        drive->bios_one_side = TRUE ;
                        if (verbose) printf("\t\tBios will believe it to be one-sided disk. :)\n") ;
                }
                return ;
        }

        if (verbose) printf("\t\t\Can't guess the real values, sorry\n") ;
rdp_abort:
        drive->sector = 0 ;
        drive->side = 0 ;
        drive->track = 0 ;
}

void register_pcdrive_to_system(int device)
{
        if ((drives[device].kind == DRIVE_IMAGE)&&!drives[device].empty)
                close(drives[device].handle) ;  // close previous image

        drives[device].kind = DRIVE_PCBIOS ;
        drives[device].empty = FALSE ;
        drives[device].changed = TRUE ;
        drives[device].pcdrive = 0 ;    // A:
        drives[device].track = drives[device].sector = drives[device].side = 0 ;
        sprintf(drives[device].basepath,"PC Drive %c:",drives[device].pcdrive+'A') ;
        _bios_disk(_DISK_RESET,NULL) ;
}

int filleddrives = 0;
int register_image_to_bios(char *name, int drv)
{
        struct find_t buffer ;
        char *pt ;
        int file ;

        if (drv == 2) {
                fprintf(stderr,"\tOnly two images allowed, Can't use \"%s\".\n",name) ;
                return FALSE ;
        }

        if (_dos_findfirst(name,_A_NORMAL,&buffer)) {
                fprintf(stderr,"\tCan't state disk image \"%s\".\n",name) ;
                return FALSE ;
        }

        file = open(name,O_RDWR|O_BINARY) ;
        if (file==-1)
                {
                        file = open(name,O_BINARY) ;
                        if (file==-1) {
                                fprintf(stderr,"\tError opening file \"%s\".\n",name) ;
                                return FALSE ;
                        }
                        drives[drv].ro_file = FALSE ;
                        drives[drv].write_protected = TRUE ;
        } else {
                drives[drv].ro_file = TRUE ;
                drives[drv].write_protected = FALSE ;
        }

        drives[drv].handle = file ;
        drives[drv].kind = DRIVE_IMAGE ;
        drives[drv].letter = 'A'+drv ;
        drives[drv].changed = TRUE ;

        pt = &drives[drv].basepath ;
        while (*name) *pt++ = *name++ ;
        *pt = 0 ;
        strupr(&drives[drv].basepath) ;

        printf("- image %s inserted in %c: %s\n",drives[drv].basepath,drv+'A',
                drives[drv].write_protected?"(Read Only)":"(Read/Write)") ;

        read_disk_params(&drives[drv],TRUE) ;

        if (!(filleddrives&(1<<drv)))
                nb_images++ ;
        filleddrives |= 1<<drv ;

        return TRUE ;
}

#ifdef DEBUG
static char buf[1024] ;      // string for temporary debugging info
#endif
static char *sectorbuffer ;
extern struct DOSMEM lowmembuffer ;

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
//�                                                                READ/WRITE
//�                                                                        in
//�                                                                Disk Image
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

static int Image_ReadSector(int dev, int first, int nb, MPTR buffer)
{
        if (drives[dev].empty) return -2 ;
        disk_activity(TRUE) ;
        lseek(drives[dev].handle,(first<<9) + drives[dev].skiplen ,SEEK_SET) ; //DIM
        read(drives[dev].handle, (char *) buffer,nb<<9) ;
        disk_activity(FALSE) ;

        if ((first==0)&&!bootexec) {
                char *p = (char *)(buffer+511) ;
                (*p)++ ;
        }

        return 0 ; // no error
}

static int Image_WriteSector(int dev, int first, int nb, MPTR buffer)
{
        if (drives[dev].empty) return -2 ;
        if (drives[dev].write_protected) return -13 ;
        disk_activity(TRUE) ;
        lseek(drives[dev].handle,(first<<9) + drives[dev].skiplen ,SEEK_SET) ; //DIM
        write(drives[dev].handle, (char *) buffer,nb<<9) ;
        disk_activity(FALSE) ;
        return 0 ; // no error
}

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
//�                                                                READ/WRITE
//�                                                                        in
//�                                                                  PC Drive
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

int PCBios_Read1Sector(int dev, int sec, MPTR buffer)
{
        static struct diskinfo_t di ;
        int result ;


        if (sec==0) {           // Special Case for boot sector 0
                char *b = (char*)buffer;
                int totalsectors ;

                di.drive = drives[dev].pcdrive ;
                di.head = 0 ;
                di.track = 0 ;
                di.sector = 1 ;
                di.nsectors = 1 ;
                di.buffer = (void *)buffer ;
                result = (_bios_disk(_DISK_READ,&di))>>8 ; ;

                drives[dev].sector = b[0x18]+(b[0x19]<<8) ;
                drives[dev].side = b[0x1a]+(b[0x1b]<<8) ;
                totalsectors = b[0x13]+(b[0x14]<<8) ;
                if ((drives[dev].side != 0)&&(drives[dev].sector!=0))
                        drives[dev].track = totalsectors/(drives[dev].sector*drives[dev].side) ;
                else drives[dev].track = 0 ;


              #ifdef DEBUG
                sprintf(buf,"\tRecognized Disk Parameters are:\n\ttracks=%d heads=%d sectors=%d\n",drives[dev].track,drives[dev].side,drives[dev].sector) ;
                OUTDEBUG(buf) ;
                #endif
        }
        else {
                if (drives[dev].track==0) {
                        result = PCBios_Read1Sector(dev,0,buffer) ; // try to read boot
                        if (result||drives[dev].track==0) return -2 ; // drive not ready
                }

                di.drive = drives[dev].pcdrive ;
                di.track = (sec/(drives[dev].side*drives[dev].sector)) ;
                di.head = (sec-di.track*drives[dev].side*drives[dev].sector)/drives[dev].sector ;
                di.sector = 1+sec-(di.track*drives[dev].side*drives[dev].sector+di.head*drives[dev].sector) ;
                di.nsectors = 1 ;
                di.buffer = (void *)buffer ;
                result =  (_bios_disk(_DISK_READ,&di))>8 ;
        }

        if ((sec==0)&&!bootexec) {
                char *p = (char *)(buffer+511) ;
                (*p)++ ;
        }
      return result ;
}

int PCBios_Write1Sector(int dev, int sec, MPTR buffer)
{
        static struct diskinfo_t di ;
        int result ;

        if (drives[dev].track==0) {
                result = PCBios_Read1Sector(dev,0,buffer) ; // try to read boot
                if (result||drives[dev].track==0) return -2 ; // drive not ready
        }

        di.drive = drives[dev].pcdrive ;
        di.track = (sec/(drives[dev].side*drives[dev].sector)) ;
        di.head = (sec-di.track*drives[dev].side*drives[dev].sector)/drives[dev].sector ;
        di.sector = 1+sec-(di.track*drives[dev].side*drives[dev].sector+di.head*drives[dev].sector) ;
        di.nsectors = 1 ;
        di.buffer = (void *)buffer ;
        result =  (_bios_disk(_DISK_WRITE,&di))>>8 ;
       return result ;
}


int PCBios_ReadSector(int dev, int first, int nb, MPTR buffer)
{
        int i ;
        int result ;

      #ifdef DEBUG
        sprintf(buf,"PCCBios_ReadSector dev=%d recno=%d count=%d\n",dev,first,nb) ;
        OUTDEBUG(buf) ;
      #endif

        for (i=0;i<nb;i++) {
                result = PCBios_Read1Sector(dev, first+i, buffer) ;
                if (result) return result ;
                buffer += 0x200 ;
        }
        return 0 ;
}

int PCBios_WriteSector(int dev, int first, int nb, MPTR buffer)
{
        int i ;
        int result ;

      #ifdef DEBUG
        sprintf(buf,"PCCBios_WriteSector dev=%d recno=%d count=%d\n",dev,first,nb) ;
        OUTDEBUG(buf) ;
      #endif

        for (i=0;i<nb;i++) {
                result = PCBios_Write1Sector(dev, first+i, buffer) ;
                if (result) return result ;
                buffer += 0x200 ;
        }
        return 0 ;
}



//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
//�                                                                READ/WRITE
//�                                                                        in
//�                                                                   General
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

// [fold]  [
void Do_SystemBoot(int dev)
{
        memset(sectorbuffer,0,512) ;
        switch(drives[dev].kind) {
                case DRIVE_IMAGE :
                        if (drives[dev].empty) return ;
                        Image_ReadSector(dev,0,1,(MPTR)sectorbuffer) ;
                        break ;
                case DRIVE_PCBIOS :
                        PCBios_Read1Sector(dev,0,(MPTR)sectorbuffer) ;
                        break ;
        }
}

// [fold]  ]

// [fold]  (
int Do_SystemDiskRW(int dev, int recno, int count, MPTR buffer, int rwflags, int alreadyside1)
{
        int status =0;

        if (drives[dev].bios_one_side&&alreadyside1) {
                int biossector, biostrack ;
                biostrack = recno/(drives[dev].bios_sector|8) ;
                biossector = recno-(biostrack*drives[dev].bios_sector) ;
                recno = (2*biostrack*drives[dev].sector)+biossector ;

        #ifdef DEBUG
        sprintf(buf,"\n \
                ***** Special BIOS conversion *****\n \
                \t biossector=%d\n \
                \t biostrack=%d\n \
                \t new reco=%d\n",
                biossector,biostrack,recno) ;
        OUTDEBUG(buf) ;
        #endif
        }

        if (buffer > processor->ramsize) {

              #ifdef DEBUG
                sprintf(buf,"\tSYSTEM DISK ACCESS AT ILLEGAL MEMORY LOCATION\n") ;
                OUTDEBUG(buf) ;
                #endif
                return -64; // range error (???)
        }

        switch(drives[dev].kind) {
                case DRIVE_IMAGE :
                        if (rwflags&1)
                                status= Image_WriteSector(dev,recno,count,(MPTR)(memory_ram+buffer)) ;
                        else
                                status = Image_ReadSector(dev,recno,count,(MPTR)(memory_ram+buffer)) ;
                        break ;

                case DRIVE_PCBIOS :
                        if (rwflags&1)
                                status = PCBios_WriteSector(dev,recno,count,(MPTR)(memory_ram+buffer)) ;
                        else
                                status = PCBios_ReadSector(dev,recno,count,(MPTR)(memory_ram+buffer)) ;

                        switch(status) {
                                case 0x04 : status = -8  ; // sector not found
                                            break ;
                                case 0x03 :
                                case 0x01 : status = -13 ; // write protect
                                            break ;
                                case 0x0a : status = -16 ; // bad sector
                                            break ;
                                case 0xaa : status = -2  ; // disk not ready
                                            break ;
                                case 0x06 : status = -14 ; // diskette changed
                                            drives[dev].changed = TRUE ;
                                            break ;
                        }
                        break ;
                        //if (status) _bios_disk(_DISK_RESET,NULL) ; // TRY...

        }

        return processor->D[0] = status ;      // OK
}

// [fold]  )

// [fold]  [
int Do_FDCRead(int dev, int recno, MPTR buffer)
{
        int status = 0;
        if (buffer > processor->ramsize) {

              #ifdef DEBUG
                sprintf(buf,"\tFDC DISK READ AT ILLEGAL MEMORY LOCATION\n") ;
                OUTDEBUG(buf) ;
                #endif
                return -1 ;
        }

        switch(drives[dev].kind) {
                case DRIVE_IMAGE :
                        status= Image_ReadSector(dev,recno,1,(MPTR)(memory_ram+buffer)) ;
                        break ;

                case DRIVE_PCBIOS :
                        status = PCBios_Read1Sector(dev,recno,(MPTR)(memory_ram+buffer)) ;
                        switch(status) {
                                case 0x04 : status = -8  ; // sector not found
                                            break ;
                                case 0x03 : status = -13 ; // write protect
                                            break ;
                                case 0x0a : status = -16 ; // bad sector
                                            break ;
                                case 0xaa : status = -2  ; // disk not ready
                                            break ;
                                case 0x06 : status = -14 ; // diskette changed
                                            drives[dev].changed = TRUE ;
                                            break ;
                        }
                        break ;
        }

        return status ;      // OK
}

// [fold]  ]

// [fold]  [
int Do_FDCWrite(int dev, int recno, MPTR buffer)
{
        int status = 0;
        if (buffer > processor->ramsize) {

              #ifdef DEBUG
                sprintf(buf,"\tFDC DISK WRITE AT ILLEGAL MEMORY LOCATION\n") ;
                OUTDEBUG(buf) ;
                #endif
                return -1 ;
        }

        switch(drives[dev].kind) {
                case DRIVE_IMAGE :
                        status= Image_WriteSector(dev,recno,1,(MPTR)(memory_ram+buffer)) ;
                        break ;

                case DRIVE_PCBIOS :
                        status = PCBios_Write1Sector(dev,recno,(MPTR)(memory_ram+buffer)) ;
                        switch(status) {
                                case 0x04 : status = -8  ; // sector not found
                                            break ;
                                case 0x03 : status = -13 ; // write protect
                                            break ;
                                case 0x0a : status = -16 ; // bad sector
                                            break ;
                                case 0xaa : status = -2  ; // disk not ready
                                            break ;
                                case 0x06 : status = -14 ; // diskette changed
                                            drives[dev].changed = TRUE ;
                                            break ;
                        }
                        break ;
        }

        return status ;      // OK
}

// [fold]  ]

///////////////////////////////////////////////////// General Disk Emulation

static        UWORD bytes_per_sector ;
static        BYTE sectors_per_cluster ;
static        UWORD nb_reserved_sectors ;
static        BYTE nb_FATs ;
static        UWORD nb_root_dir ;
static        UWORD nb_total_sectors ;
static        UBYTE media_descriptor ;
static        UWORD sectors_per_FAT ;
static        UWORD sectors_per_track ;
static        UWORD nb_heads ;
static        UWORD nb_hidden_sectors ;

// [fold]  [
void SystemInit()       //converted
{
        sectorbuffer = (char *)lowmembuffer.linear_base ;
        write_st_long(0x4c2,drivebits) ;
        write_st_word(0x4a6,2/*nb_images*/) ;
        write_st_byte(0x484,read_st_byte(0x484)&0xfd) ;
}

// [fold]  ]

// [fold]  [
void SystemClose()      //converted
{
        int i ;
        for (i=0;i<26;i++)
                if ((drives[i].kind==DRIVE_IMAGE)&&(!drives[i].empty))
                        close(drives[i].handle) ;

}

// [fold]  ]

// [fold]  [
void SystemBoot()
{
        int dev ;
        MPTR adress ;
        int cpt ;
        char *sbuffer;

        memset(sectorbuffer,0,512) ;
        dev = read_st_word(processor->A[7]+4) ;
        dev= 0 ;
        adress = read_st_long(0x4c6) ;

        #ifdef DEBUG
           sprintf(buf,"SystemBoot for drive %d\n",dev) ;
           OUTDEBUG(buf) ;
           sprintf(buf,"\tloading bootsector at adress %08x...\n",adress)  ;
           OUTDEBUG(buf) ;
        #endif

        if (adress > processor->ramsize - 512)
                return ;

        if (drives[dev].kind > DRIVE_DIR) //== DRIVE_IMAGE
                if (!drives[dev].empty)
                        Do_SystemBoot(dev) ;
                else    {
                        *(memory_ram+adress) += 1 ;
                        processor->D[0] = 3 ;
                }

        sbuffer = sectorbuffer ;
        for (cpt=0;cpt<512;cpt++)
                *(memory_ram+adress+cpt) = *sbuffer++ ;

        #ifdef DEBUG
            sprintf(buf,"\t%08x%08x...\n\n",read_st_long(adress),read_st_long(adress+4)) ;
            OUTDEBUG(buf);
        #endif

}

// [fold]  ]

// [fold]  [
void SystemDiskRW()
{
        int rwflags ;
        ULONG buffer ;
        int count, recno, dev ;

        rwflags = read_st_word(processor->A[7]+4) ;
        buffer = read_st_long(processor->A[7]+6) ;
        count = read_st_word(processor->A[7]+10) ;
        recno = read_st_word(processor->A[7]+12) ;
        dev = read_st_word(processor->A[7]+14) ;

      #ifdef DEBUG
        sprintf(buf,"SystemDiskRW \n\trwflags=%d \n\tbuffer=%08x \n\tcount=%d \
        \n\trecno=%d \n\tdevice=%d\n",rwflags,buffer,count,recno,dev);
        OUTDEBUG(buf) ;
      #endif

        if (buffer>processor->ramsize-(count<<9)) {
                processor->D[0] = -1 ;
                return ;
        }

        memset(memory_ram+buffer,count*512, 0) ;

        if (drives[dev].kind <= DRIVE_DIR) { // != DRIVE_IMAGE
                processor->D[0] = -15 ; // unknown peripheral
                return ;
        }

        if (buffer==0) {
                drives[dev].changed = 1-count ;
                processor->D[0] = 0 ;
                return ; // change disk
        }

/*
        if (drives[dev].empty) {
//                processor->D[0] = -8;
                processor->D[0] = -2 ;
                 ;    // unit not ready
                return ;
        }
*/
        processor->D[0] = Do_SystemDiskRW(dev, recno, count, buffer, rwflags, TRUE) ;

        //processor->D[0] = 0 ;

      #ifdef DEBUG
        sprintf(buf,"BUFFER is %08x%08x\n\n",read_st_long(buffer),read_st_long(buffer+4)) ;
        OUTDEBUG(buf) ;
      #endif

}

// [fold]  ]

// [fold]  [
void SystemDiskBPB()
{
        int dev ;
        MPTR ad = 0 ;   // error if no DEV 0 or 1

        dev = read_st_word(processor->A[7]+4) ;   // device number
#ifdef DEBUG
        sprintf(buf,"SystemDiskBPB for device %d\n",dev) ;
        OUTDEBUG(buf) ;         // display debug info
#endif
        if (dev==0) ad = 0xfa0fc0 ;else//0x4dce ; else
        if (dev==1) ad = 0xfa0fe0 ;//0x4dee ;

        if ((dev>=2)&&(drives[dev].kind== DRIVE_DIR)) {
                ad = 0xfa0fa0 ;
                processor->D[0] = 0 ;
                return ;
        }

        if (drives[dev].empty) {
                processor->D[0]=0 ;
                processor->D[1]=-6 ;
                return ;
        }


        if (drives[dev].kind <= DRIVE_DIR) return ; // new

        if (ad) {
                UBYTE *pt ;
                Do_SystemBoot(dev) ;
                pt = sectorbuffer ;

                bytes_per_sector = pt[0xb]+(pt[0xc]<<8) ;
                sectors_per_cluster = pt[0xd] ;
                nb_reserved_sectors = pt[0xe]+(pt[0xf]<<8) ;
                nb_FATs = pt[0x10] ;
                nb_root_dir= pt[0x11]+(pt[0x12]<<8) ;
                nb_total_sectors = pt[0x13]+(pt[0x14]<<8) ;
                media_descriptor = pt[0x15] ;
                sectors_per_FAT = pt[0x16]+(pt[0x17]<<8) ;
                sectors_per_track = pt[0x18]+(pt[0x19]<<8) ;
                nb_heads = pt[0x1a]+(pt[0x1b]<<8) ;
                nb_hidden_sectors = pt[0x1c]+(pt[0x1d]<<8) ;

                if (sectors_per_cluster == 0) sectors_per_cluster++ ;
                if (sectors_per_track == 0) sectors_per_track++ ;
                if (nb_heads==0) nb_heads++ ;

                write_st_word(ad,bytes_per_sector) ;
                write_st_word(ad+2,sectors_per_cluster) ;
                write_st_word(ad+4,(sectors_per_cluster*bytes_per_sector)) ;
                write_st_word(ad+6,nb_root_dir/16) ;
                write_st_word(ad+8,sectors_per_FAT) ;
                write_st_word(ad+10,sectors_per_FAT+1) ;
                write_st_word(ad+12,((nb_root_dir/16)+sectors_per_FAT*2+1)) ;
                write_st_word(ad+14,((nb_total_sectors)-((nb_root_dir/16)+sectors_per_FAT*2+1))/sectors_per_cluster) ;
                write_st_word(ad+16,0) ;        // 12 bits flags

                //-------- the following are pure speculations!!!

/*
                write_st_word(ad+0x12,drives[dev].track) ; // tracks?
                write_st_word(ad+0x14,drives[dev].side) ; // sides?
                write_st_word(ad+0x16,drives[dev].side*drives[dev].sector) ;//sectors*side
                write_st_word(ad+0x18,drives[dev].sector) ;
*/

                write_st_word(ad+0x12,nb_total_sectors/(sectors_per_track*nb_heads)) ;
                write_st_word(ad+0x14,nb_heads) ;
                write_st_word(ad+0x16,nb_heads*sectors_per_track) ;
                write_st_word(ad+0x18,sectors_per_track) ;

                write_st_word(ad+0x1a,0) ;
                write_st_long(ad+0x1c,(pt[8]<<24)+(pt[9]<<16)+(pt[10]<<8)+pt[11]);

                processor->D[0] = ad ;
        } else processor->D[0] = 0 ;

#ifdef DEBUG
        sprintf(buf,"\n \
                \t bytes per sector=%d\n \
                \t sectors per cluster=%d\n \
                \t number of reserved sectors=%d\n \
                \t number of FATs=%d\n \
                \t number of root dir=%d\n \
                \t number total of sectors=%d\n \
                \t media descriptor=%d\n \
                \t sectors per FAT=%d\n \
                \t sectors per track=%d\n \
                \t number of heads=%d\n \
                \t number of hidden sectors=%d\n",
                bytes_per_sector, sectors_per_cluster,
                nb_reserved_sectors, nb_FATs,
                nb_root_dir, nb_total_sectors,
                media_descriptor, sectors_per_FAT,
                sectors_per_track, nb_heads, nb_hidden_sectors) ;
        OUTDEBUG(buf) ;
#endif
}

// [fold]  ]

// [fold]  (
void SystemXbios_Read_Write()
{
        int     func ;
        MPTR    buffer ;
        int     dummy ;
        int     dev ;
        int     sector ;
        int     track ;
        int     head ;
        int     count ;
        int     linear ;

        func = read_st_word(processor->A[7]) ;
        buffer = read_st_long(processor->A[7]+2) ;
        dummy = read_st_long(processor->A[7]+6) ;
        dev = read_st_word(processor->A[7]+10) ;
        sector = read_st_word(processor->A[7]+12)&255 ;
        track = read_st_word(processor->A[7]+14)&255 ;
        head = read_st_word(processor->A[7]+16)&255 ;
        count = read_st_word(processor->A[7]+18)&255 ;

                /// comments because else Jimpower dont run

/*        if (head==0)
                linear = track*(drives[dev].sector*drives[dev].bios_side)+
                         head*(drives[dev].sector)+
                        sector-1 ;
        else
*/
                 linear = track*(drives[dev].sector*drives[dev].side)+
                 head*(drives[dev].sector)+
                 sector-1 ;


        #ifdef DEBUG
        sprintf(buf,"\n \
                ***** XBIOS PATCH ***** function 0x%02x\n \
                \t buffer=%08x\n \
                \t dummy=%d\n \
                \t dev=%d\n \
                \t sector=%d\n \
                \t track=%d\n \
                \t head=%d\n \
                \t count=%d\n",
                func, buffer, dummy, dev, sector, track, head, count) ;
        OUTDEBUG(buf) ;
        sprintf(buf,"disk structure: heads:%d tracks:%d sectors:%d - linear=0x%08x\n",
                drives[dev].side,drives[dev].track,drives[dev].sector,linear) ;
        OUTDEBUG(buf) ;
        #endif

        if (drives[dev].kind <= DRIVE_DIR) { // != DRIVE_IMAGE
                processor->D[0] = -1 ; // error
                return ;
        }

        if (drives[dev].empty) {
                processor->D[0] = -2 ; // unit non ready
                return ;
        }

        processor->D[0] = Do_SystemDiskRW(dev, linear, count, buffer, func&1,head==1) ;
}

// [fold]  )

void SystemXbios_Format()
{
        MPTR    buffer ;
        int     dev ;
        int     spt;

        buffer = read_st_long(processor->A[7]+2) ;
        dev = read_st_word(processor->A[7]+10) ;
        spt = read_st_word(processor->A[7]+12) ;


        #ifdef DEBUG
        sprintf(buf,"\n \
                ***** XBIOS PATCH ***** Flopfmt (0xa)\n \
                \t buffer=%08x\n \
                \t dev=%d\n \
                \t sectors=%d\n",
                buffer, dev, spt) ;
        OUTDEBUG(buf) ;
        #endif

        if (drives[dev].kind <= DRIVE_DIR) { // != DRIVE_IMAGE
                processor->D[0] = -8 ; // sector not found
                return ;
        }

        if (drives[dev].empty) {
                processor->D[0] = -17 ; // insert disk
                return ;
        }

        if (drives[dev].write_protected) {
                processor->D[0] = -13 ; // write protected
                return ;
        }

        if (spt!=drives[dev].sector) {
                processor->D[0] = -8 ;
                return ;
        }

        processor->D[0] = 0 ; // ok
}

// [fold]  [
void SystemXbios()
{
        int     func ;

        func=read_st_word(processor->A[7]) ;
        switch (func) {
                case 0x8 :
                case 0x9 :
                        SystemXbios_Read_Write() ;
                        break ;
                case 0xa :
                        SystemXbios_Format() ;
                case 0xf :
                        SystemXbios_Rsconf() ;
        }
}

// [fold]  ]

void SystemMediaChange()
{
        int unit ;
        union REGS regs ;

        processor->D[0] = 0 ;   // no is default
        unit = read_st_word(processor->A[7]+4) ;

        switch(drives[unit].kind) {
                case DRIVE_IMAGE :
                        if (drives[unit].changed) processor->D[0] = 2 ;
                        drives[unit].changed = FALSE ;
                        break ;
                case DRIVE_PCBIOS :
                        regs.h.ah = 0x16 ;
                        regs.h.dl = drives[unit].pcdrive ;  // drive A:
                        int386(0x13,&regs,&regs) ;
                        if (regs.h.ah!=0) {
                                drives[unit].changed = TRUE ;
                                processor->D[0] = 2 ;
                        }
                        else processor->D[0] = 0 ;
        }

        #ifdef DEBUG
           sprintf(buf,"Mediachange test for drive %d - return %d\n",unit,processor->D[0]!=0) ;
           OUTDEBUG(buf) ;
        #endif

}


// [fold]  [
void Reset_System()
{
//        Image_SystemClose() ;

}

// [fold]  ]

/*旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
 *�
 *�                                                               Keyboard
 *�
 *읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
*/

int nb_kbd_params = 0 ; // number of parameters for current keyboard action
int pt_kbd_params = 0 ; // current parameters number
int kbd_command = 0;
char kbd_params[16] ;   // list of parameters


#define MOUSEMODE_NONE          0
#define MOUSEMODE_RELATIVE      1
#define MOUSEMODE_ABSOLUTE      2
#define MOUSEMODE_CURSORS       3

#define MOUSECURSOR_LEFT        1
#define MOUSECURSOR_RIGHT       2
#define MOUSECURSOR_UP          3
#define MOUSECURSOR_DOWN        4

int MouseMode = MOUSEMODE_RELATIVE ;


int Keyboard_Read(void) ;
void Keyboard_Write(int value) ;
void Keyboard_Send(int value) ;

static int last_mousex ;
static int last_mousey ;
static int last_buttons ;
static int rmb,lmb,prmb,plmb ;

static int MouseCursorX ;
static int MouseCursorY ;

static int MouseButtonsAction ; // action on mousebuttons

static signed int Abs_MouseX = 160;
static signed int Abs_MouseY = 100;
static signed int Abs_MouseX_max = 320 ;
static signed int Abs_MouseY_max = 200 ;

static int Y_Direction = 1 ;

int MouseX       ;
int MouseY       ;
int Mouse_Buttons  ;


void Periodic_Mouse_Works(int doevents) ;

void Send_Mouse_Absolute(void)
{
        int v = 0 ;
        static int abs_plmb = 0 ;
        static int abs_prmb = 0 ;

        Periodic_Mouse_Works(FALSE) ; // don't generate events, only update


        if (rmb&&!abs_prmb) v |= 1 ;
        if (!rmb&&abs_prmb) v |= 2 ;
        if (lmb&&!abs_plmb) v |= 4 ;
        if (!lmb&&abs_plmb) v |= 8 ;


        abs_prmb = rmb ;
        abs_plmb = lmb ;

        Keyboard_Write(0xf7) ;
        Keyboard_Write(v) ;
        Keyboard_Write(Abs_MouseX>>8) ;
        Keyboard_Write(Abs_MouseX&0xff) ;
        Keyboard_Write(Abs_MouseY>>8) ;
        Keyboard_Write(Abs_MouseY&0xff) ;
}

void Send_Mouse_Cursor(int mousecursor, int nb)
{
        int i ;

        nb = (nb>>1)+1 ;

              #ifdef DEBUG
              { char b[80] ;
              sprintf(b,"\tCURSOR MOUSE - Case %d (%d times)\n",mousecursor,nb) ;
              OUTDEBUG(b) ;}
              #endif


        for (i=0;i<nb;i++)
        switch(mousecursor) {
                case MOUSECURSOR_LEFT :
                        Keyboard_Write(0x4b) ;
                        Keyboard_Write(0x4b|0x80) ;
                        break ;
                case MOUSECURSOR_RIGHT :
                        Keyboard_Write(0x4d) ;
                        Keyboard_Write(0x4d|0x80) ;
                        break ;
                case MOUSECURSOR_UP :
                        Keyboard_Write(0x48) ;
                        Keyboard_Write(0x48|0x80) ;
                        break ;
                case MOUSECURSOR_DOWN :
                        Keyboard_Write(0x50) ;
                        Keyboard_Write(0x50|0x80) ;
                        break ;
        }
}

void simul_mouse(void)
{
        Keyboard_Write(0xf8) ;
        Keyboard_Write(0) ;
        Keyboard_Write(1) ;
        Keyboard_Write(0x45) ;
        Keyboard_Write(0x85) ;

}

void Periodic_Mouse(void)
{
        Periodic_Mouse_Works(TRUE) ; // TRUE -> generate mouse events
}

void Periodic_Mouse_Works(int doevents)
{
        int     v ;
        int     deltax,deltay ;

        deltax = MouseX - last_mousex ;
        deltay = MouseY - last_mousey ;

        prmb = rmb ;
        plmb = lmb ;
        rmb = Mouse_Buttons&1 ;
        lmb = Mouse_Buttons&2 ;

        if (!(deltax||deltay||(Mouse_Buttons!=last_buttons))) goto conti ;

        Abs_MouseX += deltax ;
        if (Abs_MouseX < 0) Abs_MouseX = 0 ;
        if (Abs_MouseX > Abs_MouseX_max) Abs_MouseX = Abs_MouseX_max ;
        Abs_MouseY += deltay ;
        if (Abs_MouseY < 0) Abs_MouseY = 0 ;
        if (Abs_MouseY > Abs_MouseY_max) Abs_MouseY = Abs_MouseY_max ;


        if (doevents)
         switch(MouseMode) {

                case MOUSEMODE_RELATIVE :
                                        v = 0xf8|(Mouse_Buttons&3) ;
                                        Keyboard_Write(v) ;
                                        Keyboard_Write(deltax) ;
                                        Keyboard_Write(deltay*Y_Direction) ;
                                        break ;
/*
                case MOUSEMODE_ABSOLUTE :
                                        v = 0xa ;
//                                        v=0 ;
                                        if (lmb&&(rmb==prmb==plmb==0))
                                                v = 4 ; // left mouse button

                                        if (rmb&&(lmb==plmb==prmb==0))
                                                v = 1 ; // right mouse button

                                        if (lmb&&rmb&&!plmb&&!prmb)
                                                v = 5 ; // left & right buttons

                                        Keyboard_Write(0xf7) ;
                                        Keyboard_Write(v) ;
                                        Keyboard_Write(Abs_MouseX>>8) ;
                                        Keyboard_Write(Abs_MouseX&0xff) ;
                                        Keyboard_Write(Abs_MouseY>>8) ;
                                        Keyboard_Write(Abs_MouseY&0xff) ;
// global now                                        if (MouseButtonsAction) MouseAbsolute_Buttons() ;
                                        break ;
*/
                case MOUSEMODE_CURSORS:
                                        if (Mouse_Buttons) MouseAbsolute_Buttons() ;

                                        #ifdef DEBUG
                                        { char b[80] ;
                                        sprintf(b,"\tCURSOR MOUSE deltax=%d deltay=%d\n",deltax,deltay) ;
                                        OUTDEBUG(b) ;}
                                        #endif

                                        if (deltax>=MouseCursorX)
                                                Send_Mouse_Cursor(MOUSECURSOR_RIGHT,(deltax-MouseCursorX)+1) ;
                                        else if (deltax<= -MouseCursorX)
                                                Send_Mouse_Cursor(MOUSECURSOR_LEFT,(-deltax+MouseCursorX)+1) ;

                                        if (deltay>=MouseCursorY)
                                                Send_Mouse_Cursor(MOUSECURSOR_UP,(deltay-MouseCursorY)+1) ;
                                        else if (deltay<= -MouseCursorY)
                                                Send_Mouse_Cursor(MOUSECURSOR_DOWN,(-deltay+MouseCursorY)+1) ;
                                        break ;
       }
        if (MouseButtonsAction) MouseAbsolute_Buttons() ;

conti: ;
        last_buttons = Mouse_Buttons ;
        last_mousex = MouseX ;
        last_mousey = MouseY ;

}

void MouseAbsolute_Buttons()    // called in Absolute Mouse if special action
{
        if ((MouseButtonsAction&4)==4)
        {
                if (lmb&&!plmb) Keyboard_Write(0x74) ;
                if (rmb&&!prmb) Keyboard_Write(0x75) ;
                if (!lmb&&plmb) Keyboard_Write(0x74|0x80) ;
                if (!rmb&&prmb) Keyboard_Write(0x75|0x80) ;
        }

        /* else {
                int v=0xf8|(Mouse_Buttons&3) ;
                Keyboard_Write(v) ;
                Keyboard_Write(0) ;
                Keyboard_Write(0) ;
        }*/

}

/*************************** Joystick ********************/

int SendJoystickPacketNow = 0 ; // if set, send joystick ASAP
extern int ST_Joy0 ;    // Joystick on Port 0 (mouse/joy)
extern int ST_Joy1 ;    // Joystick on Port 1 (joystick)
static int prev_ST_Joy0 ;
static int prev_ST_Joy1 ;
static int autojoy = TRUE ;



unsigned int numericpad_for_ST ;
unsigned int PCJoy1_for_ST ;


unsigned int ST_JoyPort(int port)
{
        int v = 0 ;
        switch (STPort[port]&STPort_Emu_Allowed) {

                case STPORT_EMU_NUMERICPAD :
                        v = numericpad_for_ST ;
                        break ;

                case STPORT_EMU_PCJOY1:
                        v = PCJoy1_for_ST ;
                        break ;
        }
        return v ;

}

void Send_Joystick_Packet(int joynb)
{
        int isbutton ;
        static prevjb = 0 ;
        switch(joynb) {
                case 0 : Keyboard_Write(0xfe) ;
                         Keyboard_Write(ST_JoyPort(0)) ;
                         break ;
                case 1 : Keyboard_Write(0xff) ;
                         Keyboard_Write(ST_JoyPort(1)) ;
                         if ((special_patch==SPECIALPATCH_JOY)&&(prevjb!=(ST_JoyPort(1)&0x80))) {
                                isbutton = (prevjb&0x80) != 0 ;
                                prevjb = ST_JoyPort(1)&0x80 ;
                                Keyboard_Write(0xf8|isbutton) ;  // rmb
                                Keyboard_Write(0) ;
                                Keyboard_Write(0) ;



              #ifdef DEBUG
              { char b[80] ;
              sprintf(b,"\t****joy****") ;
              OUTDEBUG(b) ;}
              #endif

                         }
                         break ;
        }
}

void Periodic_Joystick(void)
{
        if (SendJoystickPacketNow) {
                Send_Joystick_Packet_Now() ;
                SendJoystickPacketNow = FALSE ;
                return ;
        }

        if (autojoy) {
                if (prev_ST_Joy0 != ST_JoyPort(0)) {
                        Send_Joystick_Packet(0) ;
                }
                prev_ST_Joy0 = ST_JoyPort(0) ;

                if (prev_ST_Joy1 != ST_JoyPort(1)) {
                        Send_Joystick_Packet(1) ;
                }
                prev_ST_Joy1 = ST_JoyPort(1) ;
        }
}

void Send_Joystick_Packet_Now(void)
{

        Keyboard_Write(0xfd) ;
                Keyboard_Write(ST_JoyPort(0)) ; // new

//        Keyboard_Write(0) ;
        Keyboard_Write(ST_JoyPort(1)) ;

}

void Ask_TimeofDay(void)
{
        union REGS regs ;
        regs.h.ah = 4 ; // RealTime Clock - Ask Date
        int386(0x1a,&regs,&regs) ;

        Keyboard_Write(0xfc) ;
        Keyboard_Write(regs.h.cl) ;     // Year BCD
        Keyboard_Write(regs.h.dh) ;     // mois BCD
        Keyboard_Write(regs.h.dl) ;     // day BCD

        regs.h.ah = 2 ; // RealTime Clock - Ask Time
        int386(0x1a,&regs,&regs) ;

        Keyboard_Write(regs.h.ch) ;     // hours BCD
        Keyboard_Write(regs.h.cl) ;     // minutes BCD
        Keyboard_Write(regs.h.dh) ;     // seconds BCD
}

int keyboard_inbuf = 0 ;                // next byte to be read
int keyboard_next_outbuf = 0 ;          // next byte to be written
int keyboard_outbuf = 0 ;               // max byte available to read
int keyboard_wait = 0 ;                 // nb rasterlines before bufferization
int keyboard_delay = 3 ;                // delay for keyboard

char keyboard_buffer[KBDMAXBUF] = {0xa2};

void ack_6301()
{
/*
        int x ;
        if ((read_st_byte(0xfffa09) & 0x40) == 0) {
                processor->events_mask &= ~MASK_ACIA ;
                return ;
        }

        x = read_st_byte(0xfffa01) ;
        x &= ~0x10 ;
        write_st_byte(0xfffa01,x) ;     // GPIP/I4

        x = read_st_byte(0xfffa11) ;
        x |= 0x40 ;
        write_st_byte(0xfffa11,x) ;

        processor->events_mask |= MASK_ACIA ;
*/
        mfp.gpip &= ~0x10 ;

        mfp_request(MFP_ACIA) ;


}


// [fold]  [
int Keyboard_Read(void)
{
        UBYTE x ;
        x = keyboard_buffer[keyboard_inbuf&KBDMAXBUF] ;
        memio[0x7c00] = 2 ;

        if (keyboard_inbuf < keyboard_outbuf)
                keyboard_inbuf++ ;
        else x = keyboard_buffer[(keyboard_inbuf-1)&KBDMAXBUF] ;

        if (keyboard_inbuf == keyboard_outbuf) {
              memio[0x7c00] = 2 ;
//              memio[0x7a01] |= 0x10 ;
                mfp.gpip  |= 0x10 ;
        }
        else {
                memio[0x7c00] = 0x81 ;
/*
 int v;
                if ((read_st_byte(0xfffa09) & 0x40) == 0) {
                        processor->events_mask &= ~MASK_ACIA ;
                        return x ;
                }

                processor->events_mask |= MASK_ACIA ;
                v = read_st_byte(0xfffa11) ;
                v |= 0x40 ;
                write_st_byte(0xfffa11,v) ;
*/
                ack_6301() ;


/* modified for CARRIER COMMAND, before was using ack_6301() */

        }
        return x ;
}

// [fold]  ]

// [fold]  [
void Keyboard_Write(int value)
{
        UBYTE   x ;
        extern int within_keyboard_interrupt ;
        value &= 0xff ;
        keyboard_buffer[keyboard_next_outbuf&KBDMAXBUF] = value ;
                keyboard_next_outbuf++ ;

        x = read_st_byte(0xfffc00) ;
        x = 0x83 ;                            //try lem2
        write_st_byte(0xfffc00,x) ;

        ack_6301() ;

        if (keyboard_delay > 1) {
                if (keyboard_outbuf == keyboard_inbuf)
                        keyboard_outbuf++ ;
                else    keyboard_wait = keyboard_delay ;
        } else keyboard_outbuf = keyboard_next_outbuf ;



/*              #ifdef DEBUG
              if (!within_keyboard_interrupt)
              { char b[80] ;
              sprintf(b,"\--- KBD PUT %02x",value) ;
              OUTDEBUG(b) ;}
              #endif
*/

}

// [fold]  ]

void Keyboard_ShiftBuffer(void)
{
        int x;
        if (keyboard_outbuf < keyboard_next_outbuf) {
                keyboard_outbuf++ ;

                x = read_st_byte(0xfffc00) ;
                x = 0x83 ;                            //try lem2
                write_st_byte(0xfffc00,x) ;
                ack_6301() ;

                if (keyboard_outbuf < keyboard_next_outbuf)
                        keyboard_wait = keyboard_delay ;
       }
}

void Reset_Keyboard(void)
{
        keyboard_inbuf = 0 ;
        keyboard_outbuf = 0 ;
        keyboard_next_outbuf = 0 ;
}


// [fold]  [
void Keyboard_Send(int value)
{
        int p1 ;
        value &= 0xff ;

                #ifdef DEBUG
                { char b[80] ;
                  sprintf(b,"KBD Command 0x%x from %08x\n",value,processor->PC) ;
                  OUTDEBUG(b) ;}
                #endif


// are there any parameters to get before command to be processed?

        if (nb_kbd_params) {
                --nb_kbd_params ;
                kbd_params[pt_kbd_params++] = value ;
                if (nb_kbd_params) return ;
                switch(kbd_command) {

                        case 0x09 : Abs_MouseX_max = (kbd_params[0]<<8)+kbd_params[1] ;
                                    Abs_MouseY_max = (kbd_params[2]<<8)+kbd_params[3] ;
                                    MouseMode = MOUSEMODE_ABSOLUTE ;
                                        #ifdef DEBUG
                                        { char b[80] ;
                                        sprintf(b,"\tABSOLUTE MOUSE Mode (%d,%d)\n",Abs_MouseX_max,Abs_MouseY_max) ;
                                        OUTDEBUG(b) ;}
                                        #endif
                                    break ;

                        case 0x0a : MouseMode = MOUSEMODE_CURSORS ;
                                    MouseCursorX = kbd_params[0] ;
                                    MouseCursorY = kbd_params[1] ;

                                        #ifdef DEBUG
                                        { char b[80] ;
                                          sprintf(b,"\tCURSORS MOUSE MODE (%d,%d)\n",MouseCursorX,MouseCursorY) ;
                                          OUTDEBUG(b) ;}
                                        #endif
                                     break ;

                        case 0x07 : p1 = kbd_params[0] ;

                                        #ifdef DEBUG
                                        { char b[80] ;
                                        sprintf(b,"\tSEND ABSOLUTE MOUSE On Move %d\n",p1) ;
                                        OUTDEBUG(b) ;}
                                        #endif

                                        MouseButtonsAction = p1 ;
                                    break ;

                        case 0x0e : MouseX = last_mousex = (kbd_params[1]<<8)+kbd_params[2] ;
                                    MouseY = last_mousey = (kbd_params[3]<<8)+kbd_params[4] ;
                                    MouseMode = MOUSEMODE_ABSOLUTE ;
                                        #ifdef DEBUG
                                        { char b[80] ;
                                        sprintf(b,"\tSET ABSOLUTE MOUSE POS (%d,%d)\n",MouseX,MouseY) ;
                                        OUTDEBUG(b) ;}
                                        #endif
                                    break ;

                }

                return ;
        } else pt_kbd_params = 0 ; // next params will be zero

        kbd_command = value ;

        switch(value) {
         case 0x08 : MouseMode = MOUSEMODE_RELATIVE ;
                                #ifdef DEBUG
                                { char b[80] ;
                                  sprintf(b,"\tRELATIVE MOUSE MODE\n") ;
                                  OUTDEBUG(b) ;}
                                #endif
                     MouseButtonsAction = 0 ;
                     break ;
         case 0x09 : nb_kbd_params = 4 ; // 2 words
                     break ;

         case 0x0a : nb_kbd_params = 2 ;
                     break ;
         case 0x07 : nb_kbd_params = 1 ;
                     break ;
         case 0x0d :

                                #ifdef DEBUG
                                { char b[80] ;
                                  sprintf(b,"\tSEND MOUSE ABSOLUTE\n") ;
                                  OUTDEBUG(b) ;}
                                #endif
                                Send_Mouse_Absolute() ;
                     break ;
         case 0x0e : nb_kbd_params = 5 ;
                     break ;
         case 0x0f : Y_Direction = -1 ;

                                #ifdef DEBUG
                                { char b[80] ;
                                  sprintf(b,"\tY origin is DOWN\n") ;
                                  OUTDEBUG(b) ;}
                                #endif
                     break ;
         case 0x10 : Y_Direction = 1 ;

                                #ifdef DEBUG
                                { char b[80] ;
                                  sprintf(b,"\tY Origin is UP\n") ;
                                  OUTDEBUG(b) ;}
                                #endif

                     break ;
         case 0x14 : autojoy = TRUE ;

                                #ifdef DEBUG
                                { char b[80] ;
                                  sprintf(b,"\tAUTOJOYSTICK ON\n") ;
                                  OUTDEBUG(b) ;}
                                #endif

                     break ;   // autojoy, send joys moves
         case 0x15 : autojoy = FALSE ;

                                #ifdef DEBUG
                                { char b[80] ;
                                  sprintf(b,"\tAUTOJOYSTICK OFF\n") ;
                                  OUTDEBUG(b) ;}
                                #endif


                     break ;  // no more joyauto mode
         case 0x16 :

                                #ifdef DEBUG
                                { char b[80] ;
                                  sprintf(b,"\tJOYSTICK TEST - SEND PACKET NOW\n") ;
                                  OUTDEBUG(b) ;}
                                #endif

                      SendJoystickPacketNow = TRUE ; // if set, send joystick ASAP
                     //Send_Joystick_Packet_Now() ;
                     break ;
         case 0x1c :
                                #ifdef DEBUG
                                { char b[80] ;
                                  sprintf(b,"\tASK TIME OF DAY\n") ;
                                  OUTDEBUG(b) ;}
                                #endif

                     Ask_TimeofDay() ;
                     break ;

        case 0x88 :                             // ASK mouse mode
        case 0x89 :
                        Keyboard_Write(0xf6) ;
                        if (MouseMode == MOUSEMODE_ABSOLUTE)
                                Keyboard_Write(0x9) ;
                        else    Keyboard_Write(0x8) ;
                        break ;

        case 0x94 :
        case 0x95 :
                    Keyboard_Write(0xf6) ;      // ASK joystick mode
                    if (autojoy) Keyboard_Write(0x14) ;
                    else Keyboard_Write(0x15) ;
                    break ;
        }

}

// [fold]  ]


//////////////////////////////////////////////////////////////// log print

#ifdef DEBUG
void sendlog(char *st,unsigned int v)
{
        char b[128] ;
        sprintf(b,"*****  %s : 0x%x  *****\n",st,v) ;
        OUTDEBUG(b) ;
}
#endif

/*旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
 *�
 *�                                                           BIOS PATCHes
 *�26/12/96 - Serial commucations
 *읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
*/


#define BIOS_BCONSTAT   0x0001
#define BIOS_BCONIN     0x0002
#define BIOS_BCONOUT    0x0003
#define BIOS_BCOSTAT    0x0008

void bios_bconstat() ;
void bios_bconin() ;
void bios_bconout(int v) ;
void bios_bcostat() ;
void init_serial() ;
union REGS regs ;

void SystemXbios_Rsconf(void)
{
#ifdef DEBUG
        MPTR stack =  processor->A[7] ;
        UWORD baud =  read_st_word(stack+2) ;
        UWORD ctrl =  read_st_word(stack+4) ;
        UWORD ucr  =  read_st_word(stack+6) ;
        UWORD rsr  =  read_st_word(stack+8) ;
        UWORD tsr  =  read_st_word(stack+10) ;
        UWORD scr  =  read_st_word(stack+12) ;

        char b[300] ;
        sprintf(b,"***** XBIOS function #15 : RSCONF.\n\t" \
                  "baud=%x ctrl=%x ucr=%x rsr=%x tsr=%x scr=%x\n",
                  baud,ctrl,ucr,rsr,tsr,scr) ;
        OUTDEBUG(b) ;
#endif

        regs.h.ah  = 4 ;        //init etendu


}

void SystemBIOS(void)
{
        MPTR stack = processor->A[7] ;
        int func = read_st_word(stack) ;
        switch (func) {
            case BIOS_BCONSTAT: bios_bconstat() ;
                                break ;
            case BIOS_BCONIN  : bios_bconin() ;
                                break ;
            case BIOS_BCONOUT : bios_bconout(read_st_word(stack+4)) ;
                                break ;
            case BIOS_BCOSTAT : bios_bcostat() ;
                                break ;
        }

}

void init_serial()
{
        if (!isSerial) return ;
        regs.h.ah = 0 ;         // set params
//        regs.h.al = 0xef ;      // 9600 bauds, 8 bits, no stop, odd parity
        regs.h.al = 0xeb ;      // 9600 bauds, 8 bits, no stop, odd parity
        regs.x.edx = 1 ;        // PORT COM2
        int386(0x14,&regs,&regs) ;
}

void bios_bconstat()
{
        if (!isSerial) {
                processor->D[0] = 0 ;
                return ;
        }

        regs.h.ah = 3 ;         // status
        regs.h.al = 0 ;
        regs.x.edx = 1 ;        // COM2
        int386(0x14,&regs,&regs) ;

        if ((regs.h.ah&1)!=0)
                processor->D[0] = -1 ;    // char ready
        else
                processor->D[0] = 0 ;     // no char
}

void bios_bconin()
{
        if (!isSerial) {
                processor->D[0] = 0 ;
                return ;
        }

        regs.h.ah = 2 ;         // read char
        regs.x.edx = 1 ;        // COM2
        int386(0x14,&regs,&regs) ;

        processor->D[0] = regs.h.al&0xff ;

}

void bios_bconout(int v)
{
        if (!isSerial) {
//                _D[0] = 0 ;
                return ;
        }

        regs.h.ah = 1 ;         // send char
        regs.h.al = v ;
        regs.x.edx = 1 ;        //COM2
        int386(0x14,&regs,&regs) ;
}

void bios_bcostat()
{
        if (!isSerial) {
                processor->D[0] = -1 ;
                return ;
        }

        regs.h.ah = 3 ;         // status
        regs.x.edx = 1 ;        // COM2
        int386(0x14,&regs,&regs) ;

//        if ((regs.h.al&0x10)==0x10)
        if ((regs.h.al&0x60)!=0)
                processor->D[0] = -1 ;
        else
                processor->D[0] = 0 ;

}

/*旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
 *�
 *�                                                          FDC Emulation
 *�30/12/96 - FDC Emulation started
 *�31/12/96 - drive/side Selection. Added STEP command
 *� 1/01/96 - added bit M (multiple) support for READSECTOR command
 *�           FDC Interrupt supported now!!!
 *� 3/01/96 - added FDC emulation for 2 drives
 *�17/04/96 - rewriten some FDC emulation
 *읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
*/

extern MPTR FDC_DMA_Ptr ;
extern unsigned short   FDC_Data ;
extern unsigned short   FDC_Cmd ;

static int     Reg_Data ;
static int     Reg_Track ;
static int     Reg_Sector ;
static int     FDC_Status = 0 ;
static int     DMA_Status = 0 ;

int     sector_count ;
int     current_track = 0 ;
int     current_sector = 0 ;
int     current_side = 0 ;
int     current_unit = 1 ;
int     current_direction = 1 ;
int     current_command ;
int     isDMAonHDC = FALSE ;
int     rasters_till_periodic_FDC = 0 ;

void Perform_FDC_Command(int cmd) ;
int  SYS_FDC_getregister() ;
void FDC_Interrupt_Trigger() ;
void Periodic_FDC() ;

void FDC_Command_RESTORE() ;
void FDC_Command_SEEK() ;
void FDC_Command_STEP() ;
void FDC_Command_STEPIN() ;
void FDC_Command_STEPOUT() ;
void FDC_Command_READSECTOR(int cmd) ;
void FDC_Command_WRITESECTOR() ;
void FDC_Command_READADRESS() ;
void FDC_Command_READTRACK() ;
void FDC_Command_WRITETRACK() ;
void FDC_Command_FORCEINTERRUPT() ;

#define REG_CMD         0x0000
#define REG_TRACK       0x0001
#define REG_SECTOR      0x0002
#define REG_DATA        0x0003

#define CMD_RESTORE             0x0000
#define CMD_SEEK                0x0010
#define CMD_STEPa               0x0020
#define CMD_STEPb               0x0030
#define CMD_STEPINa             0x0040
#define CMD_STEPINb             0x0050
#define CMD_STEPOUTa            0x0060
#define CMD_STEPOUTb            0x0070
#define CMD_READSECTOR          0x0080
#define CMD_READSECTORa         0x0080
#define CMD_READSECTORb         0x0090
#define CMD_WRITESECTORa        0x00a0
#define CMD_WRITESECTORb        0x00b0
#define CMD_READADRESS          0x00c0
#define CMD_READTRACK           0x00e0
#define CMD_WRITETRACK          0x00f0
#define CMD_FORCEINTERRUPT      0x00d0

int dont_trigger_fdc = FALSE;


// FF8604 : FDC_Data
// FF8606 : FDC_CMD
// static int cleared_dma_status = FALSE;

void Sys_FDC()          // called on writed ff8604
{
        int     rw ;            // bit 8 command R/W
        int     hdc ;           // hdc = 1, fdc = 0
        int     sc ;            // sector count bit (?)
        int     a0a1 ;          // register accessed

        rw = ((FDC_Cmd&0x0100)==0x100) ;        // r=0, w=1
        hdc = ((FDC_Cmd&0x0088)==0x0008) ;      // FDC or HDC?
        sc = ((FDC_Cmd&0x0010)==0x0010) ;
        a0a1 = ((FDC_Cmd>>1)&0x0003) ;          // a0a1 -> register selected

        if (sc) {
                sector_count = FDC_Data ;
                #ifdef DEBUG
                 {char b[120] ;
                 sprintf(b,"\t[FDC] Sector Count = %d",sector_count) ;
                 OUTDEBUG(b) ;}
                #endif
                return ;
        }

        isDMAonHDC = hdc ;

        if (/*rw||*/hdc||sc) {

                #ifdef DEBUG
                 {char b[120] ;
                 sprintf(b,"[FDC] Cmd=%04x - Data=%04x (rw=%x,hdc=%x,sc=%x), ignored\n",FDC_Cmd,FDC_Data,rw,hdc,sc) ;
                 OUTDEBUG(b) ;}
                #endif
                return ;
        }

        if (isDMAonHDC) return ;

        switch (a0a1) {         // register selected

                case REG_TRACK : Reg_Track = FDC_Data ;
                                        #ifdef DEBUG
                                        {char b[100] ;
                                        sprintf(b,"\t[FDC] Track register = %d",Reg_Track) ;
                                        OUTDEBUG(b) ;}
                                        #endif

                                 break ;
                case REG_SECTOR: Reg_Sector = FDC_Data ;
                                        #ifdef DEBUG
                                        {char b[100] ;
                                        sprintf(b,"\t[FDC] Sector register = %d",Reg_Sector) ;
                                        OUTDEBUG(b) ;}
                                        #endif
                                 break ;
                case REG_DATA :  Reg_Data = FDC_Data ;
                                       #ifdef DEBUG
                                        {char b[100] ;
                                        sprintf(b,"\t[FDC] Data register = %d",Reg_Data) ;
                                        OUTDEBUG(b) ;}
                                        #endif
                                 break ;
                case REG_CMD :   Perform_FDC_Command(FDC_Data) ;
                                 break ;
        }

}

int SYS_FDC_getregister()       // read ff8604
{
        switch ((FDC_Cmd>>1)&3) {
                case REG_TRACK :

                        #ifdef DEBUG
                        {char b[100] ;
                        sprintf(b,"\[FDC] read track register=%x at %08x\n",Reg_Track,processor->PC) ;
                        OUTDEBUG(b) ;}
                        #endif

                        return Reg_Track ;
                case REG_SECTOR:

                        #ifdef DEBUG
                        {char b[100] ;
                        sprintf(b,"\[FDC] read sector register=%x at %08x\n",Reg_Sector,processor->PC) ;
                        OUTDEBUG(b) ;}
                        #endif

                        return Reg_Sector ;
                case REG_DATA  :

                        #ifdef DEBUG
                        {char b[100] ;
                        sprintf(b,"\[FDC] read data register=%x at %08x\n",Reg_Data,processor->PC) ;
                        OUTDEBUG(b) ;}
                        #endif

                        return Reg_Data ;
                case REG_CMD   :
/*
                        #ifdef DEBUG
                        {char b[100] ;
                        sprintf(b,"\[FDC] read status register=%x at %08x\n",FDC_Status,processor->PC) ;
                        OUTDEBUG(b) ;}
                        #endif
*/

/*      Status Register

                bit 7 : Motor on
                bit 6 : write protect
                bit 5 : motor spin up finish / Data Mark
                bit 4 : record not found
                bit 3 : CRC error
                bit 2 : track 0
                bit 1 :
                bit 0 : busy
*/

//                return (current_track==0)<<2 ;
        return FDC_Status ; //new
//                          return sector_count ;
        }
        return 0 ;
}

#define FDC_Status_MotorOn              0x0080
#define FDC_Status_WriteProtect         0x0040
#define FDC_Status_SPinUp               0x0020
#define FDC_Status_RecordType           0x0020
#define FDC_Status_RecordNotFound       0x0010
#define FDC_Status_CrcError             0x0008
#define FDC_Status_LostData             0x0004
#define FDC_Status_Track0               0x0004
#define FDC_Status_DataRequest          0x0002
#define FDC_Status_Index                0x0002
#define FDC_Status_Busy                 0x0001

#define PERIODIC_READSECTOR             0x0001
#define PERIODIC_BUSY                   0x0002
//static int Periodic_Command = 0 ; // what to do
static int        Periodic_Command = PERIODIC_BUSY ;

void Periodic_FDC()
{
        return ;
/*    
        switch (Periodic_Command) {

                case 0 :                   rasters_till_periodic_FDC = 0 ;
                                           break ;


                case PERIODIC_READSECTOR : Periodic_READSECTOR() ;
                                           break ;

                case PERIODIC_BUSY :       FDC_Status &= ~(FDC_Status_Busy|FDC_Status_MotorOn) ;
                                           break ;
        }
*/
}


int SYS_DMA_getstatus()         // read ff8606
{
        return (DMA_Status|0xf0) ;
}

void SYS_FDC_driveside(int v)
{
        current_side = 1-(v&1) ;        // 1 or 0

        if ((v&6)==2) current_unit = 2 ;
         else if ((v&6)==4) current_unit = 1 ;
          //else current_unit = -1 ;
/*
        #ifdef DEBUG
        {char b[100] ;
        sprintf(b,"\[FDC] poking %d in 8802.w reg 14 -> Drive=%d  Side=%d\n",v&0xff,current_unit,current_side) ;
        OUTDEBUG(b) ;}
        #endif
*/
}

void Perform_FDC_Command(int cmd)
{
        disk_activity(TRUE) ;
        current_command = cmd ;
        Periodic_Command = 0 ;

        FDC_Status = 0 ;
        dont_trigger_fdc = FALSE ;

        switch (cmd&0x00f0) {
                case CMD_RESTORE          :     FDC_Command_RESTORE() ;
                                                FDC_Interrupt_Trigger() ;
                                                break ;

                case CMD_SEEK             :     FDC_Command_SEEK() ;
                                                FDC_Interrupt_Trigger() ;
                                                break ;

                case CMD_STEPa            :
                case CMD_STEPb            :     FDC_Command_STEP(cmd) ;
                                                FDC_Interrupt_Trigger() ;
                                                break ;

                case CMD_STEPINa          :
                case CMD_STEPINb          :     FDC_Command_STEPIN(cmd) ;
                                                FDC_Interrupt_Trigger() ;
                                                break ;

                case CMD_STEPOUTa         :
                case CMD_STEPOUTb         :     FDC_Command_STEPOUT(cmd) ;
                                                FDC_Interrupt_Trigger() ;
                                                break ;

                case CMD_READSECTORa      :
                case CMD_READSECTORb      :     FDC_Command_READSECTOR(cmd) ;
                                                FDC_Interrupt_Trigger() ;
                                                break ;

                case CMD_WRITESECTORa     :
                case CMD_WRITESECTORb     :     FDC_Command_WRITESECTOR(cmd) ;
                                                FDC_Interrupt_Trigger() ;
                                                break ;

                case CMD_READADRESS       :     FDC_Command_READADRESS() ;
                                                FDC_Interrupt_Trigger() ;
                                                break ;

                case CMD_READTRACK        :     FDC_Command_READTRACK() ;
                                                FDC_Interrupt_Trigger() ;
                                                break ;

                case CMD_WRITETRACK       :     FDC_Command_WRITETRACK() ;
                                                FDC_Interrupt_Trigger() ;
                                                break ;

                case CMD_FORCEINTERRUPT   :     FDC_Command_FORCEINTERRUPT() ;
                                                FDC_Interrupt_Trigger() ;
                                                break ;
        }
        disk_activity(FALSE) ;
}

void FDC_Interrupt_Trigger()
{
        /* trigger FDC interrupt if IERB & IMRB bit 7 is set */
        //memio[0x7a01] |= 0x20 ;        //GPIP bit 5 = 1 : no DMA Irq.
//                processor->events_mask |= MASK_FDC ;

        extern int waitfdc ;

        processor->events_mask |= MASK_FDC2 ;

        mfp.gpip |= 0x20 ;
//        mfp_request(MFP_FDC) ;
        waitfdc = 400 ;
}

void FDC_Command_RESTORE()
{
        #ifdef DEBUG
        {char b[100] ;
        sprintf(b,"\tRESTORE\n") ;
        OUTDEBUG(b) ;}
        #endif

        FDC_Status = 0x24 ;     // NEW

        current_track = 0 ;
        current_sector = 0 ;
        Reg_Track = 0 ;
}

void FDC_Command_SEEK()
{
        current_track = Reg_Data ;
        Reg_Track = Reg_Data ;

        #ifdef DEBUG
        {char b[100] ;
        sprintf(b,"\tSEEK to track %d\n",current_track) ;
        OUTDEBUG(b) ;}
        #endif

        FDC_Status = 0x20 ;
        if (Reg_Track==0) FDC_Status|=4 ;
}

void FDC_Command_STEP(int cmd)
{
        #ifdef DEBUG
        {char b[140] ;
        sprintf(b,"\tSTEP in direction %d from track %d to %d\n",current_direction,current_track,current_track+current_direction) ;
        OUTDEBUG(b) ;}
        #endif

        current_track += current_direction ;
        if (cmd&0x10) Reg_Track += current_direction ;  // bit U NEW..

        FDC_Status = 0x20 ;
        if (Reg_Track==0) FDC_Status|=4 ;
}

void FDC_Command_STEPIN(int cmd)
{
        #ifdef DEBUG
        {char b[100] ;
        sprintf(b,"\tSTEP IN from track %d to %d\n",current_track,current_track+1) ;
        OUTDEBUG(b) ;}
        #endif
        current_track++ ;
        current_direction = 1 ;

        if (cmd&0x10) Reg_Track++ ;  // bit U New

        FDC_Status = 0x20 ;
}

void FDC_Command_STEPOUT(int cmd)
{
        #ifdef DEBUG
        {char b[100] ;
        sprintf(b,"\tSTEP OUT from track %d to %d\n",current_track,current_track-1) ;
        OUTDEBUG(b) ;}
        #endif
        current_track-- ;
        current_direction = -1 ;
        if (cmd&0x10) Reg_Track-- ;  // bit U New

        if (current_track<0) current_track = 0 ;
        if (Reg_Track<0) Reg_Track = 0 ;

        FDC_Status = 0x20 ;
        if (Reg_Track==0) FDC_Status|=4 ;
}
/*
void Periodic_READSECTOR()
{
        FDC_Command_READSECTOR(current_command) ;
        rasters_till_periodic_FDC = 10 ;
}
*/

void FDC_Command_READSECTOR(int cmd)
{
        tdrive *drive ;
        unsigned absolute ;
        int bitm ;

        bitm = ((cmd&0x10)==0x10) ;     // bit M: multiple sector
        drive = &drives[current_unit-1] ;

        #ifdef DEBUG
        {char b[200] ;
        sprintf(b,"\tREAD SECTOR [m=%d] at %08x drive %d side=%d track=%d sector=%d (count=%d)\n",bitm,FDC_DMA_Ptr,current_unit,current_side,current_track,Reg_Sector,sector_count) ;
        OUTDEBUG(b) ;
        }
        #endif

        if ((current_unit==-1)||(drive->empty)||(drive->side<current_side)||(current_track<0)||(current_track>drive->track)||(FDC_DMA_Ptr > processor->ramsize-512)) {
                #ifdef DEBUG
                {char b[60] ;
                sprintf(b,"\t\t*** error ***\n") ;
                OUTDEBUG(b) ;
                }
                #endif
                return ;
        }

        absolute = (current_track) * (drive->side*drive->sector) + (current_side*drive->sector)+Reg_Sector-1;

        DMA_Status = 0 ;
        FDC_Status = 0 ;

        if ((Reg_Sector<1)||(Reg_Sector>drive->sector)) { // Sector out of range
                FDC_Status = 0x10 ;
                DMA_Status |= 1 ;
                dont_trigger_fdc = TRUE ;
                goto end_readsector;
        }

        if (!bitm) {
        //-------------------------- multiple bit is OFF
                FDC_Status = 0 ;
                if (sector_count) {
                        Do_FDCRead(current_unit-1,absolute,FDC_DMA_Ptr) ;
                        DMA_Status|=1 ;
                        FDC_DMA_Ptr+=0x200 ;
                        sector_count-- ;
                }
        }
        else {                  // multiple sector bit set
                int i ;
                int tillend ; //nb sector to read

                tillend = (drive->sector-Reg_Sector)+1 ;
                if (tillend<0) tillend=0 ;
                if (tillend>sector_count) {
                        tillend = sector_count ;
                }
                DMA_Status |=1 ;//not normal

                for (i=0;i<tillend;i++) {
                        Do_FDCRead(current_unit-1,absolute,FDC_DMA_Ptr) ;
                        FDC_DMA_Ptr+=0x200 ;
                        absolute++ ;
                        sector_count-- ;
                }

                Reg_Sector = drive->sector+1 ;  // last sector+1
                FDC_Status = 0x10 ;             // Record not found
//                dont_trigger_fdc = TRUE ;

                #ifdef DEBUG
                {char b[200] ;
                sprintf(b,"\t\tAfter: DMA Ptr=%x sector=%d (count=%d)\n",FDC_DMA_Ptr,Reg_Sector,sector_count) ;
                OUTDEBUG(b) ;
                }
                #endif
        }

end_readsector:;
        if (sector_count) DMA_Status|=2 ;
                else DMA_Status&=~2 ;
}

void FDC_Command_WRITESECTOR(int cmd)
{
        tdrive *drive ;
        unsigned absolute ;
        int bitm ;

        bitm = ((cmd&0x10)==0x10) ;     // bit M: multiple sector
        drive = &drives[current_unit-1] ;

        #ifdef DEBUG
        {char b[200] ;
        sprintf(b,"\tWRITE SECTOR [m=%d] at %08x drive %d side=%d track=%d sector=%d (count=%d)\n",bitm,FDC_DMA_Ptr,current_unit,current_side,current_track,Reg_Sector,sector_count) ;
        OUTDEBUG(b) ;
        }
        #endif

        if ((current_unit==-1)||(drive->empty)||(drive->side<current_side)||(current_track<0)||(current_track>drive->track)||(FDC_DMA_Ptr > processor->ramsize-512)) {
                #ifdef DEBUG
                {char b[60] ;
                sprintf(b,"\t\t*** error ***\n") ;
                OUTDEBUG(b) ;
                }
                #endif
                return ;
        }

        absolute = (current_track) * (drive->side*drive->sector) + (current_side*drive->sector)+Reg_Sector-1;

        DMA_Status = 0 ;
        FDC_Status = 0 ;

        if ((Reg_Sector<1)||(Reg_Sector>drive->sector)) { // Sector out of range
                FDC_Status = 0x10 ;
                DMA_Status |= 1 ;
                dont_trigger_fdc = TRUE ;
                goto end_writesector;
        }

        if (drive->write_protected) {
                FDC_Status = 0xc0 ;
                goto end_writesector ;
        }

        if (!bitm) {
        //-------------------------- multiple bit is OFF
                FDC_Status = 0 ;
                if (sector_count) {
                        Do_FDCWrite(current_unit-1,absolute,FDC_DMA_Ptr) ;
                        DMA_Status|=1 ;
                        FDC_DMA_Ptr+=0x200 ;
                        sector_count-- ;
                }
        }
        else {                  // multiple sector bit set
                int i ;
                int tillend ; //nb sector to read

                tillend = (drive->sector-Reg_Sector)+1 ;
                if (tillend<0) tillend=0 ;
                if (tillend>sector_count) {
                        tillend = sector_count ;
                }
                DMA_Status |=1 ;//not normal

                for (i=0;i<tillend;i++) {
                        Do_FDCWrite(current_unit-1,absolute,FDC_DMA_Ptr) ;
                        FDC_DMA_Ptr+=0x200 ;
                        absolute++ ;
                        sector_count-- ;
                }

                Reg_Sector = drive->sector+1 ;  // last sector+1
                FDC_Status = 0x10 ;             // Record not found
  //              dont_trigger_fdc = TRUE ;

                #ifdef DEBUG
                {char b[200] ;
                sprintf(b,"\t\tAfter: DMA Ptr=%x sector=%d (count=%d)\n",FDC_DMA_Ptr,Reg_Sector,sector_count) ;
                OUTDEBUG(b) ;
                }
                #endif
        }

end_writesector:;
        if (sector_count) DMA_Status|=2 ;
                else DMA_Status&=~2 ;
}

void FDC_Command_READADRESS()
{
        #ifdef DEBUG
        {char b[80] ;
        sprintf(b,"\tREAD ADRESS - yet unsupported\n") ;
        OUTDEBUG(b) ;
        }
        #endif
}


void FDC_Command_READTRACK()
{
        #ifdef DEBUG
        {char b[80] ;
        sprintf(b,"\tREAD TRACK - yet unsupported\n") ;
        OUTDEBUG(b) ;
        }
        #endif
}

void FDC_Command_WRITETRACK()
{
        #ifdef DEBUG
        {char b[80] ;
        sprintf(b,"\tWRITE TRACK - faked\n") ;
        OUTDEBUG(b) ;
        }
        #endif
        FDC_Status = 0x80 ;
}

void FDC_Command_FORCEINTERRUPT()
{
        #ifdef DEBUG
        {char b[80] ;
        sprintf(b,"\tFORCE INTERRUPT\n") ;
        OUTDEBUG(b) ;
        }
        #endif
//        Periodic_Command = PERIODIC_BUSY ;
}

/*
#ifdef DEBUG

extern short Halftone_Memory[16] ;
extern int Size_X ;
extern int Size_Y ;
extern unsigned short Mask1 ;
extern unsigned short Mask2 ;
extern unsigned short Mask3 ;
extern int HOp ;
extern int LOp ;
extern int Line_Number ;
extern int Source_Shift ;
extern int NFSR ;
extern int FXSR ;


extern int Adr_Source ;
extern int Adr_Destination ;
extern int Inc_Source_X ;
extern int Inc_Source_Y ;
extern int Inc_Destination_X ;
extern int Inc_Destination_Y ;
extern int Blitter_Control ;

void debug_blitter(void)
{
        char b[512] ;
        sprintf(b,"**** BLITTER OPERATION ****\n"\
        "Source     =%08x  incX=%08x incY=%08x\n"\
        "Destination=%08x  incX=%08x incY=%08x\n"\
        "NFSR=%x FXSR=%x  Shifting %d bits\n"\
        "Masks: %04x  %04x  %04x\n"\
        "Size X=%08x\n"\
        "Size Y=%08x\n"\
        "LOp=%x  HOp=%x  Control=%x\n",
        Adr_Source, Inc_Source_X, Inc_Source_Y,
        Adr_Destination, Inc_Destination_X, Inc_Destination_Y,
        NFSR,FXSR,Source_Shift,
        Mask1,Mask2,Mask3,
        Size_X, Size_Y,
        LOp,HOp,Blitter_Control) ;
        OUTDEBUG(b) ;
}
#endif
*/

extern int lineabase ;
extern int vdi_parameters ;
extern int ST_Screen_Ptr ;

void SystemVDI()
{

        MPTR vdi_control = read_st_long(vdi_parameters) ;
        MPTR vdi_intout = read_st_long(vdi_parameters+12) ;
        int scrsize ;
        int memtop ;

        if (videoemu_type!=VIDEOEMU_CUSTOM) return ;
        if (read_st_word(vdi_control)==1) {
                char b[100] ;
                sprintf(b,"VDI Fixed - LineA=%8x  intout=%8c\n",lineabase,vdi_intout) ;
                OUTDEBUG(b) ;

                write_st_word(vdi_intout,640) ;
                write_st_word(vdi_intout+2,480) ;

                write_st_word(lineabase,4);
                write_st_word(lineabase+2,320) ;
                write_st_word(lineabase-2,320) ;
                write_st_word(lineabase-12,640) ;
                write_st_word(lineabase-4,480) ;

                write_st_word(lineabase-0x2b4,639) ;
                write_st_word(lineabase-0x2b2,479) ;
                write_st_word(lineabase+0x03c,639) ;
                write_st_word(lineabase+0x03e,479) ;


                scrsize = (640*480*4)>>3 ;
                scrsize = (scrsize+255)&0xfff000 ;
                memtop = processor->ramsize-scrsize ;
                write_st_long(0x436,memtop) ;
                write_st_long(0x44e,memtop) ;


                memio[0x201] = (memtop>>8)&0xff ;
                memio[0x203] = (memtop>>16)&0xff ;
                ST_Screen_Ptr = memtop ;

        }
}

FILE *fpar ;

void SystemPrtStatus()
{
//        union REGS regs ;
        if (!isParallel) {
                processor->D[0] = 0 ;
                return ;
        }
        processor->D[0] = 0xffffffff ;
/*
        regs.h.ah = 2 ;
        regs.x.edx = 0 ;
        int386(0x17,&regs,&regs) ;

        if (regs.h.ah&0x80)
                processor->D[0] = 0xffffffff ;
        else    processor->D[0] = 0 ;


        {char b[80] ;
        sprintf(b,"\tPRINTER STATUS=%x\n",processor->D[0]) ;
        OUTDEBUG(b) ;
        }
*/
}

void SystemPrtOut()
{
//        union REGS regs ;
        if (!isParallel) {
                processor->D[0] = 0 ;
                return ;
        }

        fputc(read_st_byte(processor->A[7]+7),fpar) ;
        processor->D[0] = 0xffffffff ;
/*
        SystemPrtStatus() ;
        if (!processor->D[0]) return ;

        regs.h.ah = 0 ;
        regs.h.al = read_st_byte(processor->A[7]+7) ;

        {char b[80] ;
        sprintf(b,"\tPRINTER OUTPUT %d\n",regs.h.al) ;
        OUTDEBUG(b) ;
        }

        regs.x.edx = 0 ;
        int386(0x17,&regs,&regs) ;


        if (regs.h.ah&0x80)
                processor->D[0] = 0xffffffff ;
*/

}

void init_parallel()
{
        fpar = fopen("parallel.out","wb") ;
        if (fpar==NULL)
                isParallel=FALSE ;

}

void deinit_parallel()
{
        fclose(fpar) ;
}

// [fold]  15
