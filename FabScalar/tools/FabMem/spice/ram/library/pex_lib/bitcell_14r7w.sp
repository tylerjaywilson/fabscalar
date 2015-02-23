* File: 14r7w_new.pex.netlist
* Created: Sat Oct 31 14:12:53 2009
* Program "Calibre xRC"
* Version "v2007.3_36.25"
* 
.subckt bitcell_14r7w  R1_WL R2_WL R3_WL R4_WL R5_WL R6_WL R7_WL R8_WL R9_WL R10_WL
+ R11_WL R12_WL R13_WL R14_WL W1_WL W2_WL W3_WL W4_WL W5_WL
+ W6_WL W7_WL R1_BTL R1_BTLB R2_BTL R2_BTLB R3_BTL R3_BTLB R4_BTL R4_BTLB
+ R5_BTL R5_BTLB R6_BTL R6_BTLB R7_BTL R7_BTLB R8_BTL R8_BTLB R9_BTL R9_BTLB
+ R10_BTL R10_BTLB R11_BTL R11_BTLB R12_BTL R12_BTLB R13_BTL R13_BTLB R14_BTL R14_BTLB
+ W1_BTL W1_BTLB W2_BTL W2_BTLB W3_BTL W3_BTLB W4_BTL W4_BTLB W5_BTL W5_BTLB
+ W6_BTL W6_BTLB W7_BTL  W7_BTLB
 
* 
MM3 VDD! q qbar VDD! PMOS_VTL L=5e-08 W=1.8e-07 AD=2.52e-14 AS=1.89e-14
+ PD=6.4e-07 PS=5.7e-07
MM2 q qbar VDD! VDD! PMOS_VTL L=5e-08 W=1.8e-07 AD=1.89e-14 AS=2.52e-14
+ PD=5.7e-07 PS=6.4e-07
MM60 R6_BTLB R6_WL qbar_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM40 W1_BTL W1_WL q GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM45 R9_BTL R9_WL q_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM61 R12_BTL R12_WL q_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM63 W7_BTL W7_WL q GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM52 W4_BTL W4_WL q GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM87 R9_BTLB R9_WL qbar_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=1.26e-14 PD=3.9e-07 PS=4.6e-07
MM90 R12_BTLB R12_WL qbar_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=1.26e-14 PD=3.9e-07 PS=4.6e-07
MM0 GND! q qbar GND! NMOS_VTL L=5e-08 W=9e-08 AD=1.26e-14 AS=9.45e-15
+ PD=4.6e-07 PS=3.9e-07
MM1 q qbar GND! GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=1.26e-14
+ PD=3.9e-07 PS=4.6e-07
MM81 R3_BTL R3_WL q_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=1.26e-14
+ PD=3.9e-07 PS=4.6e-07
MM82 R6_BTL R6_WL q_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=1.26e-14
+ PD=3.9e-07 PS=4.6e-07
MM78 R1_BTL R1_WL q_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM83 R5_BTL R5_WL q_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM85 R8_BTL R8_WL q_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM46 R11_BTL R11_WL q_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM38 W3_BTL W3_WL q GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM44 R13_BTL R13_WL q_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM59 W6_BTL W6_WL q GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM79 R2_BTL R2_WL q_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM80 R4_BTL R4_WL q_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM84 R7_BTL R7_WL q_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM56 R10_BTL R10_WL q_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM39 W2_BTL W2_WL q GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM64 R14_BTL R14_WL q_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM54 W5_BTL W5_WL q GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM94 qbar_new1 qbar GND! GND! NMOS_VTL L=5e-08 W=2.7e-07 AD=2.835e-14
+ AS=3.78e-14 PD=7.5e-07 PS=8.2e-07
MM97 GND! q q_new2 GND! NMOS_VTL L=5e-08 W=2.7e-07 AD=3.78e-14 AS=2.835e-14
+ PD=8.2e-07 PS=7.5e-07
MM96 GND! qbar qbar_new2 GND! NMOS_VTL L=5e-08 W=2.7e-07 AD=3.78e-14
+ AS=2.835e-14 PD=8.2e-07 PS=7.5e-07
MM95 q_new1 q GND! GND! NMOS_VTL L=5e-08 W=2.7e-07 AD=2.835e-14 AS=3.78e-14
+ PD=7.5e-07 PS=8.2e-07
MM41 qbar W1_WL W1_BTLB GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM53 qbar W4_WL W4_BTLB GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM62 qbar W7_WL W7_BTLB GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM49 R3_BTLB R3_WL qbar_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM88 R13_BTLB R13_WL qbar_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM68 R8_BTLB R8_WL qbar_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM86 R11_BTLB R11_WL qbar_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM43 qbar W3_WL W3_BTLB GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM58 qbar W6_WL W6_BTLB GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM47 R1_BTLB R1_WL qbar_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM57 R5_BTLB R5_WL qbar_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM93 R14_BTLB R14_WL qbar_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM65 R7_BTLB R7_WL qbar_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM91 R10_BTLB R10_WL qbar_new1 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM42 qbar W2_WL W2_BTLB GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM55 qbar W5_WL W5_BTLB GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=9.45e-15
+ PD=3.9e-07 PS=3.9e-07
MM48 R2_BTLB R2_WL qbar_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
MM51 R4_BTLB R4_WL qbar_new2 GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15
+ AS=9.45e-15 PD=3.9e-07 PS=3.9e-07
c_29 W3_BTLB 0 0.230292f
c_56 W2_BTLB 0 0.035435f
c_83 W1_BTLB 0 0.0672592f
c_146 W3_WL 0 0.169549f
c_210 W2_WL 0 0.166984f
c_263 W1_WL 0 0.241451f
c_292 W5_BTLB 0 0.0248939f
c_321 W4_BTLB 0 0.0270544f
c_377 W6_WL 0 0.144318f
c_435 W5_WL 0 0.145622f
c_465 W6_BTLB 0 0.259476f
c_520 W4_WL 0 0.137211f
c_576 W7_WL 0 0.135305f
c_631 R1_WL 0 0.15841f
c_689 R2_WL 0 0.13326f
c_719 W7_BTLB 0 0.0284377f
c_748 R1_BTLB 0 0.409055f
c_777 R2_BTLB 0 0.0279565f
c_833 R3_WL 0 0.120112f
c_861 R3_BTLB 0 0.0311555f
c_916 R5_WL 0 0.137373f
c_973 R4_WL 0 0.123214f
c_1003 R5_BTLB 0 0.243057f
c_1032 R4_BTLB 0 0.0334073f
c_1089 R7_WL 0 0.120012f
c_1118 R6_BTLB 0 0.0275409f
c_1173 R8_WL 0 0.128395f
c_1229 R6_WL 0 0.116805f
c_1260 R8_BTLB 0 0.237648f
c_1290 R7_BTLB 0 0.0364716f
c_1321 R9_BTLB 0 0.0324479f
c_1376 R9_WL 0 0.109454f
c_1431 R11_WL 0 0.120416f
c_1488 R10_WL 0 0.111731f
c_1519 R11_BTLB 0 0.249996f
c_1549 R10_BTLB 0 0.0350652f
c_1606 R12_WL 0 0.0961279f
c_1637 R12_BTLB 0 0.0316397f
c_1692 R13_WL 0 0.153626f
c_1749 R14_WL 0 0.0989206f
c_1780 R13_BTLB 0 0.252263f
c_1814 R14_BTLB 0 0.0323108f
c_1848 R1_BTL 0 0.260641f
c_1879 R2_BTL 0 0.0298459f
c_1910 R3_BTL 0 0.0323053f
c_1941 R5_BTL 0 0.25236f
c_1972 R4_BTL 0 0.0268159f
c_2003 R6_BTL 0 0.0312908f
c_2034 R7_BTL 0 0.0255925f
c_2064 R9_BTL 0 0.027835f
c_2095 R8_BTL 0 0.219917f
c_2124 R11_BTL 0 0.254226f
c_2154 R10_BTL 0 0.034787f
c_2183 R12_BTL 0 0.0347636f
c_2211 R14_BTL 0 0.0313613f
c_2240 R13_BTL 0 0.247856f
c_2270 W7_BTL 0 0.0267067f
c_2298 W5_BTL 0 0.0262857f
c_2327 W4_BTL 0 0.0240903f
c_2357 W6_BTL 0 0.256876f
c_2383 W2_BTL 0 0.0483272f
c_2410 W1_BTL 0 0.0261344f
c_2438 W3_BTL 0 0.261512f
c_2479 qbar_new2 0 0.262613f
c_2511 qbar_new1 0 0.629696f
c_2552 qbar 0 0.45747f
c_2572 GND! 0 0.0630831f
c_2622 VDD! 0 0.239398f
c_2662 q 0 0.375623f
c_2704 q_new1 0 0.422445f
c_2737 q_new2 0 0.211454f
*
.include "14r7w_new.pex.netlist.14R7W_NEW.pxi"
*
.ends
*
*