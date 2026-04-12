design notes:

* inductor L1: rp2354b pcb design documentation suggest this inductor to be used since the inductor is specifically designed for the mcu, requires no ground/signal underneath the pads
* boost circuitry required to boost +4.5V/+5V to +5.9V for the LCD backlight, otherwise the LCD will not turn on properly (not bright enough)
* boost circuitry components are really sensitive to heat
* since the lcd is technically flipped, the connector required should be a top connector, NOT a bottom connector
* components selection noted is section below
* ldo to step input voltages down to +4V required for more stable input for the neopixel leds (known to have one green led light up out of nowhere)



component sourcing notes:

* top connector for LCD: 

  * original: https://jlcpcb.com/partdetail/HRS\_Hirose-FH12A\_15S\_0\_5SH\_55/C3169884 (currently 62 in stock)
  * alternative top connector: n/a
  * have to buy on digikey if want top connector
  * alternative double connector: https://jlcpcb.com/partdetail/JUSHUO-AFC24\_S15FIA00/C6709462
  * not tested, need to further verify dimensions (currently 5692 in stock)
* light sensor (U6): 

  * original: https://jlcpcb.com/partdetail/EverlightElec-PT26\_21CTR8/C73930 (0 in stock)
  * digikey: https://www.digikey.com/en/products/detail/everlight-electronics-co-ltd/PT26-21C-TR8/2675877 (9549 in stock)
* audio amplifier (LS1): 

  * original: https://jlcpcb.com/partdetail/CUI-CMT\_7525\_80\_SMTTR/C3151660 (0 in stock)
  * digikey: https://www.digikey.com/en/products/detail/same-sky-formerly-cui-devices/CMT-7525-80-SMT-TR/10326185 (17033 in stock)
* tactile switches (A1, B1, SELECT, START): 

  * original: https://jlcpcb.com/partdetail/CK-PTS645SL43SMTR92LFS/C221875 (0 in stock)
  * digikey: https://www.digikey.com/en/products/detail/c-k/PTS645SL43SMTR92-LFS/3861373?s=N4IgTCBcDaIMIGkByBGADADg2uAVAtEgCIgC6AvkA (24678 in stock)
* joystick (U5): 

  * original: https://jlcpcb.com/partdetail/TEConnectivity-24257551/C7502489 (25 in stock)
  * digikey: https://www.digikey.com/en/products/detail/te-connectivity-alcoswitch-switches/2425755-1/17829533 (4903 in stock)
* smd battery pack (U4): 

  * original: https://jlcpcb.com/partdetail/MYOUNG-BH\_AAAB5AA005/C2979170 (77 in stock)
  * digikey: n/a
* 500 ohm resistor (R31): 

  * original: https://jlcpcb.com/partdetail/YAGEO-RT0603BRC07500RL/C860931 (10 in stock)
  * alternative: https://jlcpcb.com/partdetail/YAGEO-RT0603BRD07500RL/C6207671 (14129 in stock) 
  * original has +-15ppm/degC while alternative has +-25ppm/degC 
* pmos (Q1): 

  * original: https://jlcpcb.com/partdetail/AnBon-AS3401/C492072 (31 in stock) 
  * alternative: https://jlcpcb.com/partdetail/Leiditech-SE3401/C782882 (3183 in stock)
  * alternative has similar specs
* rp2354b (IC1): 

  * original: https://jlcpcb.com/partdetail/RaspberryPi-RP2354B/C39843328 (141 in stock)
  * alternative: n/a

