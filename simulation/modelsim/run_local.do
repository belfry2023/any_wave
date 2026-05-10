transcript on

# Local ModelSim script for the original project.
# Run from the repository root:
#   vsim.exe -do "do simulation/modelsim/run_local.do"
# To keep key1/key2/key3 toggling forever:
#   vsim.exe -do "do simulation/modelsim/run_local.do; run -all"

set QUARTUS_ROOT "C:/Users/belfry/intelFPGA_lite/17.1/quartus"
set PROJECT_ROOT "C:/Users/belfry/github/any_wave"

# Compile Intel/Quartus simulation libraries used by the generated ROM IP.
if ![file isdirectory verilog_libs] {
	file mkdir verilog_libs
}

vlib verilog_libs/altera_ver
vmap altera_ver ./verilog_libs/altera_ver
vlog -vlog01compat -work altera_ver "$QUARTUS_ROOT/eda/sim_lib/altera_primitives.v"

vlib verilog_libs/lpm_ver
vmap lpm_ver ./verilog_libs/lpm_ver
vlog -vlog01compat -work lpm_ver "$QUARTUS_ROOT/eda/sim_lib/220model.v"

vlib verilog_libs/sgate_ver
vmap sgate_ver ./verilog_libs/sgate_ver
vlog -vlog01compat -work sgate_ver "$QUARTUS_ROOT/eda/sim_lib/sgate.v"

vlib verilog_libs/altera_mf_ver
vmap altera_mf_ver ./verilog_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver "$QUARTUS_ROOT/eda/sim_lib/altera_mf.v"

vlib verilog_libs/altera_lnsim_ver
vmap altera_lnsim_ver ./verilog_libs/altera_lnsim_ver
vlog -sv -work altera_lnsim_ver "$QUARTUS_ROOT/eda/sim_lib/altera_lnsim.sv"

vlib verilog_libs/cycloneive_ver
vmap cycloneive_ver ./verilog_libs/cycloneive_ver
vlog -vlog01compat -work cycloneive_ver "$QUARTUS_ROOT/eda/sim_lib/cycloneive_atoms.v"

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

# Compile original RTL, ROM IP, and the original Quartus-generated testbench.
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/srv "$PROJECT_ROOT/srv/key_negedge.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/ip_config "$PROJECT_ROOT/ip_config/sin.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/ip_config "$PROJECT_ROOT/ip_config/square.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/ip_config "$PROJECT_ROOT/ip_config/triangular.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/ip_config "$PROJECT_ROOT/ip_config/sawtooth.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/srv "$PROJECT_ROOT/srv/any_wave.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/srv "$PROJECT_ROOT/srv/count.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/srv "$PROJECT_ROOT/srv/ax_debounce.v"
vlog -vlog01compat -work work +incdir+$PROJECT_ROOT/simulation/modelsim "$PROJECT_ROOT/simulation/modelsim/any_wave.vt"

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc" any_wave_vlg_tst

# Add the most useful top-level and internal DUT signals to the wave window.
add wave -divider "testbench"
add wave sim:/any_wave_vlg_tst/clk
add wave sim:/any_wave_vlg_tst/rst_n
add wave sim:/any_wave_vlg_tst/key1
add wave sim:/any_wave_vlg_tst/key2
add wave sim:/any_wave_vlg_tst/key3
add wave -radix unsigned sim:/any_wave_vlg_tst/dout
add wave -divider "dut"
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/count_key1
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/count_key2
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/count_key3
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/address
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/sin_wave
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/square_wave
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/sawtooth_wave
add wave -radix unsigned sim:/any_wave_vlg_tst/i1/triangular_wave

view wave
view structure
view signals

# The testbench toggles key1/key2/key3 forever. This fixed run leaves the
# waveform at a useful point; append "run -all" from the command line for
# continuous simulation.
run 2000000 ps
wave zoom full
