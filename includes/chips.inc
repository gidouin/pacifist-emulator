
Timer_FREQBASE  EQU     2457600

TIMERMODE_STOP          EQU     0
TIMERMODE_DELAY         EQU     1
TIMERMODE_EVENTCOUNT    EQU     2
TIMERMODE_SIGNAL        EQU     3

IFNDEF FromHard
        EXTRN  Timer_B_Enabled
        EXTRN  Timer_B_Masked
        EXTRN  Timer_B_Data
        EXTRN  Timer_B_DataCurrent
        EXTRN  Timer_B_Prediv
        EXTRN  Timer_B_PredivI
        EXTRN   Timer_B_Mode
        EXTRN   Timer_B_Freq
        EXTRN   Timer_B_PredivisedFreq

        EXTRN   Timer_A_Enabled
        EXTRN   Timer_A_Masked
        EXTRN   Timer_A_Mode
        EXTRN   Timer_A_Freq
        EXTRN   Timer_A_Cumul
        EXTRN   Timer_A_Data

        EXTRN  Timer_D_PredivisedFreq
        EXTRN  Timer_D_Data
        EXTRN  Timer_D_Freq
        EXTRN  Timer_D_Enabled
        EXTRN  Timer_D_Masked

        EXTRN  Timer_C_PredivisedFreq
        EXTRN  Timer_C_Data
        EXTRN  Timer_C_Freq
        EXTRN  Timer_C_Enabled
        EXTRN  Timer_C_Masked


ENDIF

        _MFP_GPIP        EQU     (0fffa01h and 07fffh)
        _MFP_AER         EQU     (0fffa03h and 07fffh)
        _MFP_DDR         EQU     (0fffa05h and 07fffh)
        _MFP_IERA        EQU     (0fffa07h and 07fffh)
        _MFP_IERB        EQU     (0fffa09h and 07fffh)
        _MFP_IPRA        EQU     (0fffa0bh and 07fffh)
        _MFP_IPRB        EQU     (0fffa0dh and 07fffh)
        _MFP_ISRA        EQU     (0fffa0fh and 07fffh)
        _MFP_ISRB        EQU     (0fffa11h and 07fffh)
        _MFP_IMRA        EQU     (0fffa13h and 07fffh)
        _MFP_IMRB        EQU     (0fffa15h and 07fffh)
        _MFP_VR          EQU     (0fffa17h and 07fffh)
        _MFP_TACR        EQU     (0fffa19h and 07fffh)
        _MFP_TBCR        EQU     (0fffa1bh and 07fffh)
        _MFP_TCDCR       EQU     (0fffa1dh and 07fffh)
        _MFP_TADR        EQU     (0fffa1fh and 07fffh)
        _MFP_TBDR        EQU     (0fffa21h and 07fffh)
        _MFP_TCDR        EQU     (0fffa23h and 07fffh)
        _MFP_TDDR        EQU     (0fffa25h and 07fffh)
        _MFP_SCR         EQU     (0fffa27h and 07fffh)
        _MFP_UCR         EQU     (0fffa29h and 07fffh)
        _MFP_RSR         EQU     (0fffa2bh and 07fffh)
        _MFP_TSR         EQU     (0fffa2dh and 07fffh)
        _MFP_UDR         EQU     (0fffa2fh and 07fffh)

