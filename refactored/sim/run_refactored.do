transcript on

set QUARTUS_ROOT "C:/Users/belfry/intelFPGA_lite/17.1/quartus"
set PROJECT_ROOT "C:/Users/belfry/github/any_wave"
set SIM_ROOT "$PROJECT_ROOT/refactored/sim"

if ![file isdirectory $SIM_ROOT/work_libs] {
	file mkdir $SIM_ROOT/work_libs
}

vlib $SIM_ROOT/work_libs/altera_mf_ver
vmap altera_mf_ver $SIM_ROOT/work_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver "$QUARTUS_ROOT/eda/sim_lib/altera_mf.v"

if {[file exists $SIM_ROOT/work]} {
	vdel -lib $SIM_ROOT/work -all
}
vlib $SIM_ROOT/work
vmap work $SIM_ROOT/work

vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/ip_config "$PROJECT_ROOT/ip_config/sin.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/ip_config "$PROJECT_ROOT/ip_config/square.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/ip_config "$PROJECT_ROOT/ip_config/sawtooth.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/ip_config "$PROJECT_ROOT/ip_config/triangular.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/refactored/rtl "$PROJECT_ROOT/refactored/rtl/edge_pulse.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/refactored/rtl "$PROJECT_ROOT/refactored/rtl/mod4_counter.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/refactored/rtl "$PROJECT_ROOT/refactored/rtl/any_wave_refactored.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/refactored/sim "$PROJECT_ROOT/refactored/sim/any_wave_refactored_tb.v"

vsim -t 1ps -L altera_mf_ver -L work -voptargs="+acc" any_wave_refactored_tb

add wave -divider "inputs"
add wave sim:/any_wave_refactored_tb/clk
add wave sim:/any_wave_refactored_tb/rst_n
add wave sim:/any_wave_refactored_tb/key1
add wave sim:/any_wave_refactored_tb/key2
add wave sim:/any_wave_refactored_tb/key3
add wave -divider "outputs"
add wave -radix unsigned sim:/any_wave_refactored_tb/dout
add wave -divider "internal state"
add wave -radix unsigned sim:/any_wave_refactored_tb/dut/wave_sel
add wave -radix unsigned sim:/any_wave_refactored_tb/dut/amp_sel
add wave -radix unsigned sim:/any_wave_refactored_tb/dut/freq_sel
add wave -radix unsigned sim:/any_wave_refactored_tb/dut/freq_step
add wave -radix unsigned sim:/any_wave_refactored_tb/dut/address
add wave -radix unsigned sim:/any_wave_refactored_tb/dut/sin_data
add wave -radix unsigned sim:/any_wave_refactored_tb/dut/square_data
add wave -radix unsigned sim:/any_wave_refactored_tb/dut/sawtooth_data
add wave -radix unsigned sim:/any_wave_refactored_tb/dut/triangular_data

view wave
run 2000000 ps
wave zoom full
