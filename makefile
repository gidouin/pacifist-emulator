#       PACIFIST MAKEFILE
#
# clean : Efface tous les Objets
# lite :  Vire les tables de symboles & compresse l'executable
# asm :   Assemble les .68 en .H68
#
# 18/6/96   fichiers objets regroup‚s dans un r‚pertoire
# 23/6/96   Macros conditionnelles pour les options de compilations
# 25/6/96   Tous les programmes ASM convertis en mode IDEAL
#---------------------------------------------------------- macros g‚n‚rales

guru    = no
debug   = no
sound   = yes
profile = no
gus = no

EXE = ST                     # nom de l'ex‚cutable
OBJDIR = objects             # r‚pertoire pour objets
INCDIR = includes
LNK = $(OBJDIR)\$(EXE).lnk    # nom du fichier pour wlink
LIB1= gravis\ultra0wc.lib
LIB2= gravis\ultra1wc.lib

#------------------------------------------ options g‚n‚rales de compilation

ASMFLAGS = /m2 /z /zi /i$(INCDIR)
CFLAGS   = /zq /ox /4s /7 /d2 /s /zp4 /w3 /i=$(INCDIR)
#LNKOPT   = SYSTEM dos4g DEBUG all OPTION SYMFILE=$(EXE)
LNKOPT   = SYSTEM pmodew DEBUG all OPTION SYMFILE=$(EXE)

SIMU_OBJECTS = $(OBJDIR)\pchard.obj &
	       $(OBJDIR)\events.obj &
	       $(OBJDIR)\simu68.obj &
	       $(OBJDIR)\chips.obj &
	       $(OBJDIR)\i_move2.obj &
	       $(OBJDIR)\i_logic.obj &
	       $(OBJDIR)\i_maths.obj &
	       $(OBJDIR)\i_branch.obj &
	       $(OBJDIR)\i_movem.obj  &
	       $(OBJDIR)\opcodes.obj &
               $(OBJDIR)\filesel.obj &
               $(OBJDIR)\blitter.obj

OBJECTS =      $(OBJDIR)\general.obj &
	       $(OBJDIR)\disa.obj &
	       $(OBJDIR)\monitor.obj &
	       $(OBJDIR)\gemdos.obj &
	       $(OBJDIr)\main.obj &
	       $(OBJDIR)\guru.obj &
               $(OBJDIR)\sys.obj &
	       $(OBJDIR)\keyboard.obj &
	       $(OBJDIR)\timer.obj &
	       $(OBJDIR)\config.obj &
	       $(OBJDIR)\vbe.obj &
               $(OBJDIR)\eval.obj &
               $(OBJDIR)\freeze.obj &
               $(OBJDIR)\mfp.obj


SOUND_OBJECTS = $(OBJDIR)\ym2149.obj &
	       $(OBJDIR)\sound.obj 

INCLUDES = $(INCDIR)\cpu68.h $(INCDIR)\simu68.inc $(INCDIR)\chips.inc

!ifeq debug yes
ASMFLAGS += /dDEBUG
CFLAGS += /dDEBUG
!endif

!ifeq profile yes
ASMFLAGS += /dDEBUGPROFILE
CFLAGS += /dDEBUGPROFILE
!endif

!ifeq guru yes
ASMFLAGS += /dGURU
CFLAGS += /dGURU
!endif

!ifeq sound yes
CFLAGS += /dSOUND
ASMFLAGS += /dSOUND
!endif

!ifeq gus yes
SOUND_OBJECTS += $(OBJDIR)\gus.obj
LNKOPT += LIB $(LIB1) LIB $(LIB2)
!endif

$(EXE).exe: $(OBJECTS) $(SIMU_OBJECTS) $(SOUND_OBJECTS) $(INCLUDES) $(LNK)
	wlink $(LNKOPT) @$(LNK)

$(LNK): makefile
	%create $(LNK)
	for %i in ($(SIMU_OBJECTS)) do @%append $(LNK) file %i
	for %i in ($(OBJECTS)) do @%append $(LNK) file %i
	for %i in ($(SOUND_OBJECTS)) do @%append $(LNK) file %i
				%append $(LNK) name $(EXE)
                                %append $(LNK) option stack=20000
#                               %append $(LNK) option map=map



profile.obj: profile.h profile.c

profile.h: profile.hh
	utils\profile

$(OBJDIR)\blitter.obj: blitter.asm $(INCDIR)\simu68.inc $(INCDIR)\chips.inc


#$(OBJDIR)\blitter.obj: blitter.c
#        wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

$(OBJDIR)\events.obj: events.asm $(INCDIR)\simu68.inc

$(OBJDIR)\i_movem.obj: i_movem.asm $(INCDIR)\simu68.inc

$(OBJDIR)\i_move2.obj: i_move2.asm $(INCDIR)\simu68.inc

$(OBJDIR)\i_logic.obj: i_logic.asm $(INCDIR)\simu68.inc

$(OBJDIR)\i_branch.obj: i_branch.asm $(INCDIR)\simu68.inc

$(OBJDIR)\i_maths.obj: i_maths.asm $(INCDIR)\simu68.inc

$(OBJDIR)\opcodes.obj: opcodes.asm $(INCDIR)\simu68.inc

$(OBJDIR)\simu68.obj: simu68.asm $(INCDIR)\simu68.inc $(INCDIR)\chips.inc goodbye.asm

$(OBJDIR)\chips.obj: chips.asm $(INCDIR)\simu68.inc $(INCDIR)\chips.inc

$(OBJDIR)\pchard.obj: pchard.asm $(INCDIR)\simu68.inc $(INCDIR)\cpu68.h

$(OBJDIR)\snd.obj: snd.asm

$(OBJDIR)\snd_sb.obj: snd_sb.asm

$(OBJDIR)\main.obj: main.c $(INCDIR)\cpu68.h $(INCDIR)\vbe.h $(INCDIR)\timer.h $(INCDIR)\eval.h
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

$(OBJDIR)\timer.obj: timer.c $(INCDIR)\timer.h $(INCDIR)\cpu68.h $(INCDIR)\kb.h
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

$(OBJDIR)\monitor.obj: monitor.c $(INCDIR)\cpu68.h $(INCDIR)\kb.h
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&


$(OBJDIR)\sound.obj: sound.c
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

$(OBJDIR)\gus.obj: gus.c
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

$(OBJDIR)\mfp.obj: mfp.c $(INCDIR)\cpu68.h
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

$(OBJDIR)\sys.obj: sys.c $(INCDIR)\cpu68.h $(INCDIR)\disk.h
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

$(OBJDIR)\gemdos.obj: gemdos.c $(INCDIR)\cpu68.h $(INCDIR)\disk.h
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

$(OBJDIR)\vbe.obj: vbe.c $(INCDIR)\cpu68.h $(INCDIR)\vbe.h
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

$(OBJDIR)\filesel.obj: filesel.c $(INCDIR)\cpu68.h $(INCDIR)\disk.h
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

$(OBJDIR)\config.obj: config.c $(INCDIR)\config.h
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

$(OBJDIR)\general.obj: general.c $(INCDIR)\cpu68.h
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

$(OBJDIR)\eval.obj: eval.c $(INCDIR)\eval.h
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

$(OBJDIR)\ym2149.obj: ym2149.c $(INCDIR)\ym2149.h
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

.c.obj : $(INCDIR)\cpu68.h
	wcc386 $(CFLAGS) $^& -fo=$(OBJDIR)\$^&

keyboard.obj: keyboard.c $(INCDIR)\kb.h $(INCDIR)\cpu68.h

main.obj: main.c $(INCDIR)\kb.h $(INCDIR)\cpu68.h

.asm.obj : $(INCDIR)\simu68.inc
	tasm $(ASMFLAGS) $^&,$(OBJDIR)\$^&


clean:
	del d:\pacifist\objects\*.obj *.err *.bak

asm:
	echo                           Assembling STARTUP 68000 CODE
	utils\asm startup.68
	echo                           Assembling PATCH 68000 CODE
	utils\asm patch.68

makefile:
	del $(EXE).exe

6301:
	wcl386 6301.c

lite:
#	wstrip $(EXE).exe
  pmwlite /c4 $(EXE).exe

imgbuild.exe: imgbuild.c
	wcl386 $(CFLAGS) imgbuild.c -fo=$(OBJDIR)\$^&


