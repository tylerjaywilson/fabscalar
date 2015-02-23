
********************       WRITE    DATA       ************************
.SUBCKT write_data btlb btl data col clk wr_en
.param w1 = 360n
.param w2 = 360n
.param w3 = 180n
.param w4 = 90n
.param w5 = 720n

M5 data_i data VDD_wckt VDD_wckt pmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+2*w3' PS='210n+2*w3'
M6 data_i data GND! GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'

M1 btl2 clk VDD_wckt VDD_wckt pmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+2*w3' PS='210n+2*w3'
M2 btl2 col net1 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'
M3 net1 data_i net2 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'
M22 net2 wr_en net3 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'
M4 net3 clk GND! GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'

M7 btlb2 clk VDD_wckt VDD_wckt pmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+2*w3' PS='210n+2*w3'
M8 btlb2 col net4 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'
M9 net5 data net4 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'
M23 net5 wr_en net6 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'
M10 net6 clk GND! GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'

M12 btlb1 btlb2 VDD_wckt VDD_wckt pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M13 btlb1 btlb2 GND! GND! nmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+2*w3' PS='210n+2*w3'

M15 btlb btlb1 VDD_wckt VDD_wckt pmos_vtl L='50n' W=w5 AD='105n*w5' AS='105n*w5' PD='210n+2*w5' PS='210n+2*w5'
M16 btlb btlb1 GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+2*w1' PS='210n+2*w1'

M19 btl1 btl2 VDD_wckt VDD_wckt pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M20 btl1 btl2 GND! GND! nmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+2*w3' PS='210n+2*w3'

M17 btl btl1 VDD_wckt VDD_wckt pmos_vtl L='50n' W=w5 AD='105n*w5' AS='105n*w5' PD='210n+2*w5' PS='210n+2*w5'
M18 btl btl1 GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+2*w1' PS='210n+2*w1'

.ENDS
*************************************************************************************
********************       WRITE    DATA       ************************
.SUBCKT write_data_power btlb btl data col clk wr_en
.param w1 = 360n
.param w2 = 360n
.param w3 = 180n
.param w4 = 90n
.param w5 = 720n

M5 data_i data VDD_wckt_p VDD_wckt_p pmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+2*w3' PS='210n+2*w3'
M6 data_i data GND! GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'

M1 btl2 clk VDD_wckt_p VDD_wckt_p pmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+2*w3' PS='210n+2*w3'
M2 btl2 col net1 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'
M3 net1 data_i net2 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'
M22 net2 wr_en net3 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'
M4 net3 clk GND! GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'

M7 btlb2 clk VDD_wckt_p VDD_wckt_p pmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+2*w3' PS='210n+2*w3'
M8 btlb2 col net4 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'
M9 net5 data net4 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'
M23 net5 wr_en net6 GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'
M10 net6 clk GND! GND! nmos_vtl L='50n' W=w4 AD='105n*w4' AS='105n*w4' PD='210n+2*w4' PS='210n+2*w4'

M12 btlb1 btlb2 VDD_wckt_p VDD_wckt_p pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M13 btlb1 btlb2 GND! GND! nmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+2*w3' PS='210n+2*w3'

M15 btlb btlb1 VDD_wckt_p VDD_wckt_p pmos_vtl L='50n' W=w5 AD='105n*w5' AS='105n*w5' PD='210n+2*w5' PS='210n+2*w5'
M16 btlb btlb1 GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+2*w1' PS='210n+2*w1'

M19 btl1 btl2 VDD_wckt_p VDD_wckt_p pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M20 btl1 btl2 GND! GND! nmos_vtl L='50n' W=w3 AD='105n*w3' AS='105n*w3' PD='210n+2*w3' PS='210n+2*w3'

M17 btl btl1 VDD_wckt_p VDD_wckt_p pmos_vtl L='50n' W=w5 AD='105n*w5' AS='105n*w5' PD='210n+2*w5' PS='210n+2*w5'
M18 btl btl1 GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+2*w1' PS='210n+2*w1'

.ENDS
*************************************************************************************


******************************    INVERTER     **************************************
.SUBCKT inverter in out
.param w1 = 90n
.param w2 = 180n
M1 out in VDD_inv VDD_inv pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M2 out in GND! GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+2*w1' PS='210n+2*w1'
.ENDS
*************************************************************************************


