vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xpm
vlib questa_lib/msim/xil_defaultlib

vmap xpm questa_lib/msim/xpm
vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu  -sv "+incdir+../../../ENEL 453 Final Project.gen/sources_1/ip/clk_wiz_0" \
"C:/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm  -93  \
"C:/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../ENEL 453 Final Project.gen/sources_1/ip/clk_wiz_0" \
"../../../ENEL 453 Final Project.gen/sources_1/ip/xadc_wiz_0/xadc_wiz_0.v" \
"../../../ENEL 453 Final Project.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_clk_wiz.v" \
"../../../ENEL 453 Final Project.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.v" \

vlog -work xil_defaultlib  -incr -mfcu  -sv "+incdir+../../../ENEL 453 Final Project.gen/sources_1/ip/clk_wiz_0" \
"../../../../Data_Selecting_Mux.sv" \
"../../../../Data_Selection_Subsystem.sv" \
"../../../../Fall_Detector1.sv" \
"../../../../Fall_Detector2.sv" \
"../../../../Output_FSM.sv" \
"../../../../PWM_mux.sv" \
"../../../../R2R_mux.sv" \
"../../../../XADC_Mux.sv" \
"../../../../XADC_Subsystem.sv" \
"../../../../auto_cal.sv" \
"../../../../averager.sv" \
"../../../../averager_pwm.sv" \
"../../../../averager_subsystem.sv" \
"../../../../averager_subsystem2.sv" \
"../../../../bin_to_bcd.sv" \
"../../../../cal_button_pulse.sv" \
"../../../../digit_multiplexor.sv" \
"../../../../downcounter.sv" \
"../../../../pwm.sv" \
"../../../../pwm_from_code.sv" \
"../../../../sar_adc_fsm.sv" \
"../../../../sawtooth_generator.sv" \
"../../../../sawtooth_generator2.sv" \
"../../../../sawtooth_subsystem.sv" \
"../../../../sawtooth_subsystem2.sv" \
"../../../../seven_segment_decoder.sv" \
"../../../../seven_segment_digit_selector.sv" \
"../../../../seven_segment_display_subsystem.sv" \
"../../../../switch_logic.sv" \
"../../../../Lab7_Top_Level.sv" \

vlog -work xil_defaultlib \
"glbl.v"

