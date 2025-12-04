## This file is a general .xdc for the Basys3 rev B board
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project
## Xilinx part number XC7A35T-1CPG236C (from Reference Manual)
## Xilinx part number xc7a35tcpg236-1 (from Xilinx Vivado)

## Clock signal
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Switches (11 used here + 4 mode_select + 1 cal_switch)
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports {switches_inputs[0]}]
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports {switches_inputs[1]}]
# SW2 now used as cal_switch, not switches_inputs[2]
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports {cal_switch}]
set_property -dict { PACKAGE_PIN W17   IOSTANDARD LVCMOS33 } [get_ports {switches_inputs[3]}]
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports {switches_inputs[4]}]
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports {switches_inputs[5]}]
set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports {switches_inputs[6]}]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports {switches_inputs[7]}]
set_property -dict { PACKAGE_PIN V2    IOSTANDARD LVCMOS33 } [get_ports {switches_inputs[8]}]
set_property -dict { PACKAGE_PIN T3    IOSTANDARD LVCMOS33 } [get_ports {switches_inputs[9]}]
set_property -dict { PACKAGE_PIN T2    IOSTANDARD LVCMOS33 } [get_ports {switches_inputs[10]}]
set_property -dict { PACKAGE_PIN R3    IOSTANDARD LVCMOS33 } [get_ports {switches_inputs[11]}]

set_property -dict { PACKAGE_PIN W2    IOSTANDARD LVCMOS33 } [get_ports {mode_select[0]}]
set_property -dict { PACKAGE_PIN U1    IOSTANDARD LVCMOS33 } [get_ports {mode_select[1]}]
set_property -dict { PACKAGE_PIN T1    IOSTANDARD LVCMOS33 } [get_ports {mode_select[2]}]
set_property -dict { PACKAGE_PIN R2    IOSTANDARD LVCMOS33 } [get_ports {mode_select[3]}]

## 7 Segment Display
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports {CA}]
set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports {CB}]
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports {CC}]
set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports {CD}]
set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports {CE}]
set_property -dict { PACKAGE_PIN V5   IOSTANDARD LVCMOS33 } [get_ports {CF}]
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports {CG}]

set_property -dict { PACKAGE_PIN V7   IOSTANDARD LVCMOS33 } [get_ports DP]

set_property -dict { PACKAGE_PIN U2   IOSTANDARD LVCMOS33 } [get_ports {AN1}]
set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS33 } [get_ports {AN2}]
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS33 } [get_ports {AN3}]
set_property -dict { PACKAGE_PIN W4   IOSTANDARD LVCMOS33 } [get_ports {AN4}]

## Buttons
# Basys3 pushbuttons are normally 0, and 1 when pushed down
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports reset]
set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports decimal_selection]
# New calibration button on BTNU (T18)
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports cal_button]
# (BTNL/BTNR not used)
# set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports ...]
# set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports ...]


## Pmod Header JB: R2R_output
set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33 } [get_ports {R2R_output[0]}] ;# JB1
set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33 } [get_ports {R2R_output[1]}] ;# JB2
set_property -dict { PACKAGE_PIN B15   IOSTANDARD LVCMOS33 } [get_ports {R2R_output[2]}] ;# JB3
set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS33 } [get_ports {R2R_output[3]}] ;# JB4
set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS33 } [get_ports {R2R_output[4]}] ;# JB7
set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports {R2R_output[5]}] ;# JB8
set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports {R2R_output[6]}] ;# JB9
set_property -dict { PACKAGE_PIN C16   IOSTANDARD LVCMOS33 } [get_ports {R2R_output[7]}] ;# JB10

## Pmod Header JXADC
set_property -dict { PACKAGE_PIN J3   IOSTANDARD LVCMOS33 } [get_ports PWM_out]   ;# XA1_P
set_property -dict { PACKAGE_PIN N2   IOSTANDARD LVCMOS33 } [get_ports {vauxp15}] ;# XA4_P
set_property -dict { PACKAGE_PIN K3   IOSTANDARD LVCMOS33 } [get_ports {compare1}];# XA1_N
set_property -dict { PACKAGE_PIN M3   IOSTANDARD LVCMOS33 } [get_ports {compare2}];# XA2_N
set_property -dict { PACKAGE_PIN N1   IOSTANDARD LVCMOS33 } [get_ports {vauxn15}];# XA4_N

### Configuration options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## SPI configuration mode options for QSPI boot
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
