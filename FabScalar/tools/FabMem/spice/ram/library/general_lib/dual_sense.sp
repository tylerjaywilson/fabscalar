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
