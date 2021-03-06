* File: 6r6w.pex.netlist
* Created: Sat Oct 31 01:26:49 2009
* Program "Calibre xRC"
* Version "v2007.3_36.25"
* 
.subckt bitcell_6r6w
+ W1_WL W2_WL W3_WL W4_WL W5_WL W6_WL
+ ML1 ML2 ML3 ML4 ML5 ML6
+ W1_BTL W1_BTLB W2_BTL W2_BTLB W3_BTL W3_BTLB W4_BTL W4_BTLB
+ W5_BTL W5_BTLB W6_BTL W6_BTLB
+ SL_1 SLB_1 SL_2 SLB_2 SL_3 SLB_3 SL_4 SLB_4
+ SL_5 SLB_5 SL_6 SLB_6
* 
MM3 VDD! D Dbar VDD! PMOS_VTL L=5e-08 W=1.8e-07 AD=2.52e-14 AS=1.89e-14
+ PD=6.4e-07 PS=5.7e-07
MM2 D Dbar VDD! VDD! PMOS_VTL L=5e-08 W=1.8e-07 AD=1.89e-14 AS=2.52e-14
+ PD=5.7e-07 PS=6.4e-07
MM43 Dbar W3_WL W3_BTLB GND! NMOS_VTL L=5e-08 W=9e-08 AD=1.26e-14 AS=9.45e-15
+ PD=4.6e-07 PS=3.9e-07
MM58 Dbar W6_WL W6_BTLB GND! NMOS_VTL L=5e-08 W=9e-08 AD=1.26e-14 AS=9.45e-15
+ PD=4.6e-07 PS=3.9e-07
MM42 Dbar W2_WL W2_BTLB GND! NMOS_VTL L=5e-08 W=9e-08 AD=1.26e-14 AS=9.45e-15
+ PD=4.6e-07 PS=3.9e-07
MM55 Dbar W5_WL W5_BTLB GND! NMOS_VTL L=5e-08 W=9e-08 AD=1.26e-14 AS=9.45e-15
+ PD=4.6e-07 PS=3.9e-07
MM41 Dbar W1_WL W1_BTLB GND! NMOS_VTL L=5e-08 W=9e-08 AD=1.26e-14 AS=9.45e-15
+ PD=4.6e-07 PS=3.9e-07
MM53 Dbar W4_WL W4_BTLB GND! NMOS_VTL L=5e-08 W=9e-08 AD=1.26e-14 AS=9.45e-15
+ PD=4.6e-07 PS=3.9e-07
MM0 GND! D Dbar GND! NMOS_VTL L=5e-08 W=9e-08 AD=1.26e-14 AS=9.45e-15
+ PD=4.6e-07 PS=3.9e-07
MM1 D Dbar GND! GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=1.26e-14
+ PD=3.9e-07 PS=4.6e-07
MM38 W3_BTL W3_WL D GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=1.26e-14
+ PD=3.9e-07 PS=4.6e-07
MM59 W6_BTL W6_WL D GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=1.26e-14
+ PD=3.9e-07 PS=4.6e-07
MM39 W2_BTL W2_WL D GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=1.26e-14
+ PD=3.9e-07 PS=4.6e-07
MM54 W5_BTL W5_WL D GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=1.26e-14
+ PD=3.9e-07 PS=4.6e-07
MM40 W1_BTL W1_WL D GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=1.26e-14
+ PD=3.9e-07 PS=4.6e-07
MM52 W4_BTL W4_WL D GND! NMOS_VTL L=5e-08 W=9e-08 AD=9.45e-15 AS=1.26e-14
+ PD=3.9e-07 PS=4.6e-07
MM154 net0172 SLB_2 GND! GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=5.04e-14
+ AS=3.78e-14 PD=1e-06 PS=9.3e-07
MM155 ML2 D net0172 GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=3.78e-14 AS=5.04e-14
+ PD=9.3e-07 PS=1e-06
MM150 net0128 SLB_4 GND! GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=5.04e-14
+ AS=3.78e-14 PD=1e-06 PS=9.3e-07
MM151 ML4 D net0128 GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=3.78e-14 AS=5.04e-14
+ PD=9.3e-07 PS=1e-06
MM157 net0179 SLB_1 GND! GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=5.04e-14
+ AS=3.78e-14 PD=1e-06 PS=9.3e-07
MM156 ML1 D net0179 GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=3.78e-14 AS=5.04e-14
+ PD=9.3e-07 PS=1e-06
MM149 net0167 SLB_5 GND! GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=5.04e-14
+ AS=3.78e-14 PD=1e-06 PS=9.3e-07
MM148 ML5 D net0167 GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=3.78e-14 AS=5.04e-14
+ PD=9.3e-07 PS=1e-06
MM153 net0177 SLB_3 GND! GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=5.04e-14
+ AS=3.78e-14 PD=1e-06 PS=9.3e-07
MM152 ML3 D net0177 GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=3.78e-14 AS=5.04e-14
+ PD=9.3e-07 PS=1e-06
MM146 net0163 SLB_6 GND! GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=5.04e-14
+ AS=3.78e-14 PD=1e-06 PS=9.3e-07
MM147 ML6 D net0163 GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=3.78e-14 AS=5.04e-14
+ PD=9.3e-07 PS=1e-06
MM128 net0116 SL_2 GND! GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=5.04e-14 AS=3.78e-14
+ PD=1e-06 PS=9.3e-07
MM129 ML2 Dbar net0116 GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=3.78e-14 AS=5.04e-14
+ PD=9.3e-07 PS=1e-06
MM133 net0124 SL_4 GND! GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=5.04e-14 AS=3.78e-14
+ PD=1e-06 PS=9.3e-07
MM132 ML4 Dbar net0124 GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=3.78e-14 AS=5.04e-14
+ PD=9.3e-07 PS=1e-06
MM96 net109 SL_1 GND! GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=5.04e-14 AS=3.78e-14
+ PD=1e-06 PS=9.3e-07
MM127 ML1 Dbar net109 GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=3.78e-14 AS=5.04e-14
+ PD=9.3e-07 PS=1e-06
MM135 net098 SL_5 GND! GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=5.04e-14 AS=3.78e-14
+ PD=1e-06 PS=9.3e-07
MM134 ML5 Dbar net098 GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=3.78e-14 AS=5.04e-14
+ PD=9.3e-07 PS=1e-06
MM130 net0117 SL_3 GND! GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=5.04e-14 AS=3.78e-14
+ PD=1e-06 PS=9.3e-07
MM131 ML3 Dbar net0117 GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=3.78e-14 AS=5.04e-14
+ PD=9.3e-07 PS=1e-06
MM136 net0131 SL_6 GND! GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=5.04e-14 AS=3.78e-14
+ PD=1e-06 PS=9.3e-07
MM137 ML6 Dbar net0131 GND! NMOS_VTL L=5e-08 W=3.6e-07 AD=3.78e-14 AS=5.04e-14
+ PD=9.3e-07 PS=1e-06
c_17 W1_BTLB 0 0.0745553f
c_37 W3_BTLB 0 0.0239779f
c_55 W2_BTLB 0 0.0298726f
c_88 W2_WL 0 0.093314f
c_119 W3_WL 0 0.0960325f
c_151 W1_WL 0 0.0999824f
c_173 W5_BTLB 0 0.0210943f
c_194 W6_BTLB 0 0.0333736f
c_213 W4_BTLB 0 0.0272691f
c_236 SL_3 0 0.0701344f
c_266 Dbar 0 0.488492f
c_285 SL_1 0 0.0716008f
c_307 SL_2 0 0.0580737f
c_326 SL_4 0 0.0651524f
c_359 ML4 0 0.0740513f
c_380 SL_5 0 0.0724583f
c_413 ML5 0 0.0828317f
c_444 ML6 0 0.0895861f
c_467 SL_6 0 0.113227f
c_490 SLB_6 0 0.118712f
c_511 SLB_5 0 0.0723338f
c_540 D 0 0.484823f
c_561 SLB_4 0 0.0649384f
c_583 SLB_2 0 0.0580217f
c_602 SLB_1 0 0.0713824f
c_625 SLB_3 0 0.0703365f
c_646 W6_BTL 0 0.0333869f
c_665 W4_BTL 0 0.0272976f
c_687 W5_BTL 0 0.021075f
c_707 W3_BTL 0 0.0239848f
c_725 W2_BTL 0 0.0303125f
c_742 W1_BTL 0 0.080216f
c_774 W4_WL 0 0.0891056f
c_806 ML2 0 0.0488984f
c_839 ML1 0 0.0512677f
c_871 ML3 0 0.059335f
c_882 VDD! 0 0.0127212f
c_922 GND! 0 0.435068f
c_953 W6_WL 0 0.0839079f
c_986 W5_WL 0 0.0835339f
*
.include "6r6w.pex.netlist.6R6W.pxi"
*
.ends
*
*
