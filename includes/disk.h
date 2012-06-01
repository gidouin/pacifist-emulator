#define DRIVE_NONE      0
#define DRIVE_DIR       1
#define DRIVE_IMAGE     2
#define DRIVE_PCBIOS    3

typedef struct {
        int     kind ;
        int     letter ;
        int     handle ;
        char    basepath[128] ;
        char    currentpath[128] ;

        int     side ;
        int     track ;
        int     sector ;

        int     write_protected ;

        int     bios_one_side ;
        int     bios_sector ;
        int     bios_side ;

        int     changed ;
        int     empty ;

        int     pcdrive ;
        int     skiplen ;

        int     ro_file ;

        } tdrive ;

extern int nb_drives ;
extern tdrive drives[26] ;      // drives with types
extern int current_drive  ;


extern void register_pcdrive_to_system(int device) ;

extern int register_drive_to_gemdos(char *path) ;
extern int register_image_to_bios(char *name, int drive) ;
extern void read_disk_params(tdrive *drive, int verbose) ;
extern void init_images(void) ;

