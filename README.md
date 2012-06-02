pacifist-emulator
=================

PaCifiST, Atari ST Emulator on PC, back in 1996.

Twitter: [gidouin](https://twitter.com/gidouin)

Mail:    gidouin atgmaildotcom

The last release of PaCifiST was on 1998-06-07 (0.49b), and unfortunately, I was not able to retrieve the sets of source from this version. :(
The sources are dated from 1998-11-20, and the emulator is not working properly. Mainly, the MFP emulation is broken and at this time I can't understand it back.
Too bad I was not using a proper VCS back them.

Be warned: The sources are a big mess of C and i386 assembler. I'm only publishing them for digital preservation.

Thanks to Arnaud Carré, coder of YM2149 and SoundBlaster part for permission to distribute the code he wrote.

To build the executable, you will need some legacy tools:
* TASM      (tested: Turbo Assembler 4)
* Watcom C  (tested: Watcom C 10.0)
* Gravis ultrasound SDK in gravis/ folder (not sure yet if I can distribute them)

dos4gw and pmode/w dos extenders are supported. You can use DOSBox or a DOS prompt if still have one.

The produced executable need a pacifist.ini and a TOS. If you already used PaCifiST in the past, you know these.
