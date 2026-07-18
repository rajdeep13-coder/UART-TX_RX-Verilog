## Basys3 UART constraints template
##
## The Basys3 routes its USB-UART bridge through the Digilent USB-JTAG adapter.
## The FPGA-side UART pins vary by board revision and are accessed via the
## on-board FTDI chip. Consult the Basys3 Master XDC or reference manual for
## your specific board revision to get the correct PACKAGE_PIN values.
##
## Common Basys3 (Rev. D) USB-UART pins:
##   rx_serial -> PACKAGE_PIN B18  (usb_uart_rx on schematic)
##   tx_serial -> PACKAGE_PIN A18  (usb_uart_tx on schematic)
##
## System clock: 100 MHz on pin W5.
##
## To use: uncomment and fill in the correct PACKAGE_PIN for your revision.

## --- System Clock (100 MHz) ---
## set_property PACKAGE_PIN W5  [get_ports clk]
## set_property IOSTANDARD LVCMOS33 [get_ports clk]
## create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## --- USB-UART Bridge ---
## set_property PACKAGE_PIN B18 [get_ports rx_serial]
## set_property IOSTANDARD LVCMOS33 [get_ports rx_serial]

## set_property PACKAGE_PIN A18 [get_ports tx_serial]
## set_property IOSTANDARD LVCMOS33 [get_ports tx_serial]

## --- Active-low Reset (push-button BTNC) ---
## set_property PACKAGE_PIN U18 [get_ports rst_n]
## set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
