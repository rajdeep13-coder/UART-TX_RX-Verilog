## Arty A7-35T / A7-100T UART constraints
## Source: Digilent Arty-A7-35-Master.xdc (official Digilent reference)
##
## Naming note (from the Arty A7 schematic):
##   uart_rxd_out = data going OUT from FPGA to PC  -> maps to uart_top's tx_serial
##   uart_txd_in  = data coming IN  from PC to FPGA -> maps to uart_top's rx_serial
##
## To use: uncomment the lines below and ensure top-level port names match
##         uart_top.v (rx_serial, tx_serial, clk, rst_n).

## --- System Clock (100 MHz) ---
set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

## --- USB-UART Bridge ---
## FPGA receives serial data from PC on pin A9  (uart_txd_in on schematic)
set_property -dict { PACKAGE_PIN A9  IOSTANDARD LVCMOS33 } [get_ports { rx_serial }];

## FPGA sends serial data to PC on pin D10 (uart_rxd_out on schematic)
set_property -dict { PACKAGE_PIN D10 IOSTANDARD LVCMOS33 } [get_ports { tx_serial }];

## --- Active-low Reset (push-button BTN0) ---
## Optional: wire rst_n to a button for manual reset during bring-up.
#set_property -dict { PACKAGE_PIN C2  IOSTANDARD LVCMOS33 } [get_ports { rst_n }];
