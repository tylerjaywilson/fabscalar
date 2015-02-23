*************************************************************************************
.SUBCKT read_precharge pc btl
.param w1= 720n
M1 btl pc VDD_prec VDD_prec pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
.ENDS
**************************************************************************************

*************************************************************************************
.SUBCKT read_precharge_pow pc btl
.param w1= 720n
M1 btl pc VDD_prec_p VDD_prec_p pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
.ENDS
**************************************************************************************


********************       WRITE    DATA       ************************
.SUBCKT write_data btlb btl data clk wr_en
.param w1 = 360n
.param w2 = 360n
.param w3 = 180n
.param w4 = 90n
.param w5 = 720n

M5 data_i data VDD_wckt VDD_wckt pmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+w3' PS='210n+w3'
M6 data_i data GND! GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'

M1 btl2 clk VDD_wckt VDD_wckt pmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+w3' PS='210n+w3'
M3 btl2 data_i net2 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'
M22 net2 wr_en net3 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'
M4 net3 clk GND! GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'

M7 btlb2 clk VDD_wckt VDD_wckt pmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+w3' PS='210n+w3'
M9 net5 data btlb2 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'
M23 net5 wr_en net6 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'
M10 net6 clk GND! GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'

M12 btlb1 btlb2 VDD_wckt VDD_wckt pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+w2' PS='210n+w2'
M13 btlb1 btlb2 GND! GND! nmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+w3' PS='210n+w3'

M15 btlb btlb1 VDD_wckt VDD_wckt pmos_vtl L='50n' W=w5 AD='105n*w5' AS='105n*w5' PD='210n+w5' PS='210n+w5'
M16 btlb btlb1 GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'

M19 btl1 btl2 VDD_wckt VDD_wckt pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+w2' PS='210n+w2'
M20 btl1 btl2 GND! GND! nmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+w3' PS='210n+w3'

M17 btl btl1 VDD_wckt VDD_wckt pmos_vtl L='50n' W=w5 AD='105n*w5' AS='105n*w5' PD='210n+w5' PS='210n+w5'
M18 btl btl1 GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'


.ENDS
*************************************************************************************


********************       WRITE    DATA  POWER     ************************
.SUBCKT write_data_power btlb btl data clk wr_en
.param w1 = 360n
.param w2 = 360n
.param w3 = 180n
.param w4 = 90n
.param w5 = 720n

M5 data_i data VDD_wckt_P VDD_wckt_P pmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+w3' PS='210n+w3'
M6 data_i data GND! GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'

M1 btl2 clk VDD_wckt_P VDD_wckt_P pmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+w3' PS='210n+w3'
M3 btl2 data_i net2 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'
M22 net2 wr_en net3 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'
M4 net3 clk GND! GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'

M7 btlb2 clk VDD_wckt_P VDD_wckt_P pmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+w3' PS='210n+w3'
M9 net5 data btlb2 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'
M23 net5 wr_en net6 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'
M10 net6 clk GND! GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+w4' PS='210n+w4'

M12 btlb1 btlb2 VDD_wckt_P VDD_wckt_P pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+w2' PS='210n+w2'
M13 btlb1 btlb2 GND! GND! nmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+w3' PS='210n+w3'

M15 btlb btlb1 VDD_wckt_P VDD_wckt_P pmos_vtl L='50n' W=w5 AD='105n*w5' AS='105n*w5' PD='210n+w5' PS='210n+w5'
M16 btlb btlb1 GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'

M19 btl1 btl2 VDD_wckt_P VDD_wckt_P pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+w2' PS='210n+w2'
M20 btl1 btl2 GND! GND! nmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+w3' PS='210n+w3'

M17 btl btl1 VDD_wckt_P VDD_wckt_P pmos_vtl L='50n' W=w5 AD='105n*w5' AS='105n*w5' PD='210n+w5' PS='210n+w5'
M18 btl btl1 GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'


.ENDS
*************************************************************************************

************************ SL Driver **************************************************

.SUBCKT SL_driver sl_pre cw sl slb
.param w1 = 180n
.param w2 = 270n
.param w3 = 90n
.param w4 = 180n 
.param w5 = 360n
.param w6 = 720n 


M13 cwi cw VDD_SL VDD_SL pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M14 cwi cw GND! GND! nmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+w3' PS='210n+w3'

M1 sl1 sl_pre VDD_SL VDD_SL pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M2 sl1 cw VDD_SL VDD_SL pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M3 sl1 sl_pre net1 GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M4 net1 cw GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'

M5 sl sl1 VDD_SL VDD_SL pmos_vtl L='50n' W=w6 AD='105n*w6' AS='105n*w6' PD='210n+w6' PS='210n+w6'
M6 sl sl1 GND! GND! nmos_vtl L='50n' W=w5 AD='105n*w5' AS='105n*w5' PD='210n+w5' PS='210n+w5'

M7 slb1 sl_pre VDD_SL VDD_SL pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M8 slb1 cwi VDD_SL VDD_SL pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M9 slb1 sl_pre net2 GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M10 net2 cwi GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'

M11 slb slb1 VDD_SL VDD_SL pmos_vtl L='50n' W=w6 AD='105n*w6' AS='105n*w6' PD='210n+w6' PS='210n+w6'
M12 slb slb1 GND! GND! nmos_vtl L='50n' W=w5 AD='105n*w5' AS='105n*w5' PD='210n+w5' PS='210n+w5'

.ENDS

*************************************************************************************


************************ SL Driver Power**************************************************

.SUBCKT SL_driver_power sl_pre cw sl slb
.param w1 = 180n
.param w2 = 270n
.param w3 = 90n
.param w4 = 180n 
.param w5 = 360n
.param w6 = 720n 


M13 cwi cw VDD_SL_P VDD_SL_P pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M14 cwi cw GND! GND! nmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+w3' PS='210n+w3'

M1 sl1 sl_pre VDD_SL_P VDD_SL_P pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M2 sl1 cw VDD_SL_P VDD_SL_P pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M3 sl1 sl_pre net1 GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M4 net1 cw GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'

M5 sl sl1 VDD_SL_P VDD_SL_P pmos_vtl L='50n' W=w6 AD='105n*w6' AS='105n*w6' PD='210n+w6' PS='210n+w6'
M6 sl sl1 GND! GND! nmos_vtl L='50n' W=w5 AD='105n*w5' AS='105n*w5' PD='210n+w5' PS='210n+w5'

M7 slb1 sl_pre VDD_SL_P VDD_SL_P pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M8 slb1 cwi VDD_SL_P VDD_SL_P pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M9 slb1 sl_pre net2 GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M10 net2 cwi GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'

M11 slb slb1 VDD_SL_P VDD_SL_P pmos_vtl L='50n' W=w6 AD='105n*w6' AS='105n*w6' PD='210n+w6' PS='210n+w6'
M12 slb slb1 GND! GND! nmos_vtl L='50n' W=w5 AD='105n*w5' AS='105n*w5' PD='210n+w5' PS='210n+w5'

.ENDS

*************************************************************************************

******************************    INVERTER     **************************************
.SUBCKT inverter in out
.param w1 = 90n
.param w2 = 180n
M1 out in VDD_inv VDD_inv pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+w2' PS='210n+w2'
M2 out in GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
.ENDS
*************************************************************************************
******************************    INVERTER     **************************************
.SUBCKT inverter_pow in out
.param w1 = 90n
.param w2 = 180n
M1 out in VDD_inv_p VDD_inv pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+w2' PS='210n+w2'
M2 out in GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
.ENDS
*************************************************************************************

