*************************************************************************************
.SUBCKT read_precharge pc btlb btl
.param w1 = 720n
.param w2 = 180n
M1 btl pc VDD_prec VDD_prec pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+2*w1' PS='210n+2*w1'
M2 btlb pc VDD_prec VDD_prec pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+2*w1' PS='210n+2*w1'
.ENDS
*************************************************************************************

*************************************************************************************
.SUBCKT read_precharge_power pc btlb btl
.param w1 = 720n
.param w2 = 180n
M1 btl pc VDD_prec_p VDD_prec_p pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+2*w1' PS='210n+2*w1'
M2 btlb pc VDD_prec_p VDD_prec_p pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+2*w1' PS='210n+2*w1'
.ENDS
*************************************************************************************

****************************    COLUMN MUX  2X1 ****************************************
.SUBCKT r_columnmux_2x1 sel selb line1 line2 outline
.param w1 = 180n
.param w2 = 180n

M1 line1 sel outline GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+2*w1' PS='210n+2*w1'
M3 line1 selb outline VDD_col pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M2 line2 selb outline GND! nmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+2*w1' PS='210n+2*w1'
M4 line2 sel outline VDD_col pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
.ENDS

*************************************************************************************

*************************************************************************************************************
.SUBCKT dual_sense btlb btl se
.param w1 = 720n
.param w2 = 360n
.param w3 = 90n
.param w4 = 180n

M1 btl  btlb VDD_sense VDD_sense pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M2 btl  btlb net_2 GND! nmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M3 btlb btl VDD_sense VDD_sense pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M4 btlb btl net_2 GND! nmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M5 net_2 se GND! GND! nmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'

.ENDS
*************************************************************************************************************

*************************************************************************************************************
.SUBCKT dual_sense_power btlb btl se
.param w1 = 720n
.param w2 = 360n
.param w3 = 90n
.param w4 = 180n

M1 btl  btlb VDD_sense_p VDD_sense_p pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M2 btl  btlb net_2 GND! nmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M3 btlb btl VDD_sense_p VDD_sense_p pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M4 btlb btl net_2 GND! nmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'
M5 net_2 se GND! GND! nmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+2*w2' PS='210n+2*w2'

.ENDS
*************************************************************************************************************

******************************    INVERTER     **************************************
.SUBCKT rd_inverter in out
.param w1 = 90n
.param w2 = 180n
M1 out in VDD_rinv VDD_rinv pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+w2' PS='210n+w2'
M2 out in GND! GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
.ENDS
*************************************************************************************

******************************    INVERTER     **************************************
.SUBCKT op_inverter in out
.param w1 = 90n
.param w2 = 180n
M1 out in VDD_op VDD_op pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+w2' PS='210n+w2'
M2 out in GND! GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
.ENDS
*************************************************************************************

******************************    INVERTER     **************************************
.SUBCKT rd_inverter_power in out
.param w1 = 90n
.param w2 = 180n
M1 out in VDD_rinv_p VDD_rinv_p pmos_vtl L='50n' W=w2 AD='105n*w2' AS='105n*w2' PD='210n+w2' PS='210n+w2'
M2 out in GND! GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
.ENDS
*************************************************************************************

.SUBCKT Rdecoder_1 clk A0 WL_in
.param w1 = 180n
.param w2 = 90n

M0 WL_in CLK VDD_rdecode VDD_rdecode pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M1 WL_in A0 net1 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M2 net1 CLK GND! GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7

.ENDS

******************************************************************************************************

.SUBCKT Rdecoder_2 clk A0 A1 WL_in
.param w1 = 180n
.param w2 = 90n

M0 WL_in CLK VDD_rdecode VDD_rdecode pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M1 WL_in A1 net1 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M2 net1 A0 net2 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M3 net2 CLK GND! GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7

.ENDS

******************************************************************************************************

.SUBCKT Rdecoder_3 clk A0 A1 A2 WL_in
.param w1 = 360n
.param w2 = 90n

M0 WL_in CLK VDD_rdecode VDD_rdecode pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M1 WL_in A2 net1 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M4 net1 A1 net2 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M2 net2 A0 net3 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M3 net3 CLK GND! GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7

.ENDS
******************************************************************************************************

.SUBCKT Rdecoder_4 clk A0 A1 A2 A3 WL_in
.param w1 = 360n
.param w2 = 90n

M0 WL_in CLK VDD_rdecode VDD_rdecode pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M1 WL_in A3 net1 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M4 net1 A2 net2 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M2 net2 A1 net3 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M5 net3 A0 net4 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M3 net4 CLK GND! GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7

.ENDS
******************************************************************************************************

.SUBCKT Rdecoder_5 clk A0 A1 A2 A3 A4 WL_in
.param w1 = 360n
.param w2 = 90n

M0 WL_in CLK VDD_rdecode VDD_rdecode pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M1 WL_in A4 net1 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M4 net1 A3 net2 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M2 net2 A2 net3 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M5 net3 A1 net4 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M6 net4 A0 net5 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M3 net5 CLK GND! GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7

.ENDS

******************************************************************************************************
.SUBCKT Rdecoder_6 clk A0 A1 A2 A3 A4 A5 WL_in
.param w1 = 720n
.param w2 = 90n

M0 WL_in CLK VDD_rdecode VDD_rdecode pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M1 WL_in A5 net1 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M4 net1 A4 net2 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M2 net2 A3 net3 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M5 net3 A2 net4 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M6 net4 A1 net5 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M7 net5 A0 net6 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M3 net6 CLK GND! GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7

.ENDS
******************************************************************************************************
.SUBCKT Rdecoder_7 clk A0 A1 A2 A3 A4 A5 A6 WL_in
.param w1 = 720n
.param w2 = 90n

M0 WL_in CLK VDD_rdecode VDD_rdecode pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M1 WL_in A6 net1 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M4 net1 A5 net2 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M2 net2 A4 net3 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M5 net3 A3 net4 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M6 net4 A2 net5 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M7 net5 A1 net6 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M8 net6 A0 net7 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M3 net7 CLK GND! GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7

.ENDS
******************************************************************************************************

.SUBCKT Rdecoder_8 clk A0 A1 A2 A3 A4 A5 A6 A7 WL_in
.param w1 = 720n
.param w2 = 90n

M0 WL_in CLK VDD_rdecode VDD_rdecode pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M1 WL_in A7 net1 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M4 net1 A6 net2 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M2 net2 A5 net3 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M5 net3 A4 net4 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M6 net4 A3 net5 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M7 net5 A2 net6 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M8 net6 A1 net7 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M9 net7 A0 net8 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M3 net8 CLK GND! GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
.ENDS

******************************************************************************************************
.SUBCKT Rdecoder_9 clk A0 A1 A2 A3 A4 A5 A6 A7 A8 WL_in
.param w1 = 720n
.param w2 = 90n

M0 WL_in CLK VDD_rdecode VDD_rdecode pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M10 WL_in A8 net1 GND! nmos_vtl L='50n'  W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M1 net1 A7 net2 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M4 net2 A6 net3 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M2 net3 A5 net4 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M5 net4 A4 net5 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M6 net5 A3 net6 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M7 net6 A2 net7 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M8 net7 A1 net8 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M9 net8 A0 net9 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M3 net9 CLK GND! GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
.ENDS

******************************************************************************************************
.SUBCKT Rdecoder_10 clk A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 WL_in
.param w1 = 720n
.param w2 = 90n

M0 WL_in CLK VDD_rdecode VDD_rdecode pmos_vtl L='50n' W=w1 AD='105n*w1' AS='105n*w1' PD='210n+w1' PS='210n+w1'
M10 WL_in A9 net1 GND! nmos_vtl L='50n'  W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M1 net1 A8 net2 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M4 net2 A7 net3 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M2 net3 A6 net4 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M5 net4 A5 net5 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M6 net5 A4 net6 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M7 net6 A3 net7 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M8 net7 A2 net8 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M9 net8 A1 net9 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M11 net9 A0 net10 GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
M12 net10 CLK GND! GND! nmos_vtl L='50n' W=w2 AD=2.475e-14 AS=2.475e-14 PD=7.3e-7 PS=7.3e-7
.ENDS

