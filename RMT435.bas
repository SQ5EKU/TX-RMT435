' Program do sterowania PLL TBB206 + prescaler :64 w nadajniku RMT435
' Wymienic uC na 89C2051 , uklad przelacznia napiec wymaga modyfikacji.
' Dolutowac do uC uklad HT7044B (reset)
' Czestotliwosc pracy: 432.500 MHz lub 439.150 MHz
' http://sq5eku.blogspot.com

$regfile = "89c2051.dat"
$crystal = 12800000                                           ' zegar 12.8 MHz

Dim Tmp As Bit                                                ' odcinanie nadawania po jednej rundzie
Dim C As Byte
Dim A As Byte

' jumper'y:
Jp1 Alias P3.0                                                ' pin 2  , JP1
Jp2 Alias P3.1                                                ' pin 3  , JP2
Jp3 Alias P1.4                                                ' pin 16 , JP3
Jp4 Alias P1.3                                                ' pin 15 , JP4
Jp5 Alias P3.2                                                ' pin 6  , JP5
Jp6 Alias P3.3                                                ' pin 7  , JP6
Jp7 Alias P3.4                                                ' pin 8  , JP7
Jp8 Alias P3.5                                                ' pin 9  , JP8

Ptt Alias P3.7                                                ' pin 11 , PTT H=wylaczone , L=zalaczone
Vco Alias P1.6                                                ' pin 18 , zasilanie VCO H=zalaczone , L=wylaczone
Drv Alias P1.7                                                ' pin 19, wzmacniacz w.cz. H=wylaczony , L=zalaczony

Le Alias P1.0                                                 ' pin 12 TBB206 pin 3 (LE)
Data Alias P1.1                                               ' pin 13 TBB206 pin 4 (DATA)
Clk Alias P1.2                                                ' pin 14 TBB206 pin 5 (CLOCK)

Declare Sub Tbb_tx
Declare Sub Tbb_r
Declare Sub Tbb_stat
Declare Sub Tbb_stat1
Declare Sub Zegarek1
Declare Sub Zegarek2
Declare Sub Le_pulse

Jp1 = 0
Jp2 = 0
Jp3 = 0
Jp4 = 0
Jp5 = 0
Jp6 = 0
Jp7 = 0
Jp8 = 0

Set Ptt
Reset Vco
Tmp = 1
Set Drv

Reset Le
Reset Data
Reset Clk

Waitms 100                                                    ' inicjalizacja po wlaczeniu zasilania
Gosub Tbb_stat1
Delay
Gosub Tbb_r

'-------------------------------------------------------------  glowna petla

Do
If Tmp = 0 Then
 If Ptt = 0 Then
  Vco = 1
  Waitms 10
  Gosub Tbb_stat
  Delay
  Gosub Tbb_tx
  Waitms 10
  Drv = 0
  Tmp = 1
 End If
End If
If Tmp = 1 Then
 If Ptt = 1 Then
  Vco = 0
  Gosub Tbb_r
  Delay
  Gosub Tbb_stat1
  Drv = 1
  Tmp = 0
 End If
End If

Loop
End

'-------------------------------------------------------------  koniec glownej petli

Tbb_r:
Restore Dat_r
 For A = 1 To 19
 Read C
  If C = 1 Then
   Gosub Zegarek1
  Else
   Gosub Zegarek2
  End If
 Next A
 Gosub Le_pulse
Return

Tbb_tx:
Restore Dat_tx
 For A = 1 To 22
 Read C
  If C = 1 Then
   Gosub Zegarek1
  Else
   Gosub Zegarek2
  End If
 Next A
 Gosub Le_pulse
Return

Tbb_stat:
Restore Dat_s1
 For A = 1 To 16
 Read C
  If C = 1 Then
   Gosub Zegarek1
  Else
   Gosub Zegarek2
  End If
 Next A
 Gosub Le_pulse
Return

Tbb_stat1:
Restore Dat_s2
 For A = 1 To 16
 Read C
  If C = 1 Then
   Gosub Zegarek1
  Else
   Gosub Zegarek2
  End If
 Next A
 Gosub Le_pulse
Return

Zegarek1:
 Set Data
 nop
 Set Clk
 nop
 Reset Clk
 nop
 Reset Data
Return

Zegarek2:
 Set Clk
 nop
 Reset Clk
 nop
Return

Le_pulse:
 nop
 Set Le
 nop
 Reset Le
 nop
 Reset Data
Return

'_______________________________________________________________________________
' 19 bitowy rejestr R:
Dat_r:
'
' REF: 12.8MHz , krok PLL: 12.5kHz , R=1024
'    |------------------------------R----------------------------|   |-adres-|
Data 0 , 0 , 0 , 0 , 0 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 1 , 0 , 0       ' 16 bitow R , 3 bity adresu

'_______________________________________________________________________________
' 16 bitowy rejestr STATUS2:
Dat_s1:
'
'    |--------------------STAT2----------------------|   |-adres-|
Data 1 , 0 , 1 , 0 , 1 , 1 , 0 , 0 , 1 , 1 , 1 , 1 , 1 , 0 , 1 , 0       ' 13 bitow konfiguracyjnych STATUS2 , 3 bity adresu

'_______________________________________________________________________________
' 16 bitowy rejestr STATUS2:
Dat_s2:
'
'    |--------------------STAT2----------------------|   |-adres-|
Data 1 , 0 , 1 , 0 , 1 , 1 , 0 , 0 , 1 , 1 , 0 , 1 , 1 , 0 , 1 , 0       ' 13 bitow konfiguracyjnych STATUS2 , 3 bity adresu (stan spoczynku)

'_______________________________________________________________________________
' 22 bitowy rejestr N/A:
'Dat_na:
'
' TX: 432.500 MHz , krok PLL: 12.5kHz , N/A=34600
' 34600 : 64 = 540 (N) , 34600 mod 64 = 40 (A)
'     |-----------A-----------|   |---------------------N---------------------|   |-adres-|
'Data 0 , 1 , 0 , 1 , 0 , 0 , 0 , 0 , 0 , 1 , 0 , 0 , 0 , 0 , 1 , 1 , 1 , 0 , 0 , 1 , 1 , 1       ' 19 bitow N/A , 3 bity adresu

'_______________________________________________________________________________
' 22 bitowy rejestr N/A:
Dat_tx:
'
' TX: 439.150 MHz , krok PLL: 12.5kHz , N/A=35132
' 35132 : 64 = 548 (N) , 35132 mod 64 = 60 (A)
'    |-----------A-----------|   |---------------------N---------------------|   |-adres-|
Data 0 , 1 , 1 , 1 , 1 , 0 , 0 , 0 , 0 , 1 , 0 , 0 , 0 , 1 , 0 , 0 , 1 , 0 , 0 , 1 , 1 , 1       ' 19 bitow N/A , 3 bity adresu
