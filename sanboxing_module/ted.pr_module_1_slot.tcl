# setting top_module
#set top_module vadd

lappend auto_path ./tedtcl/
package require ted 2

#configuration

set parent nodeultra_top_i/PR_SLOT_0_0/U0/inst_PR_WRP/PR_Kernel
set clkNetName ap_clk

#end configuration

open_checkpoint ./Synth/Static/static_syn.dcp

set clkNet [get_nets [ted::utility::joinPath $parent $clkNetName]]

create_pblock pblock_0
resize_pblock pblock_0 -add {SLICE_X0Y0:SLICE_X4Y179 DSP48E2_X0Y0:DSP48E2_X0Y71 RAMB18_X0Y0:RAMB18_X0Y71 RAMB36_X0Y0:RAMB36_X0Y35}
add_cells_to_pblock pblock_0 [get_cells [list nodeultra_top_i/pr_decoupler_0 nodeultra_top_i/ps8_0_axi_periph nodeultra_top_i/rst_ps8_0_99M nodeultra_top_i/util_vector_logic_0 nodeultra_top_i/util_vector_logic_1 nodeultra_top_i/zynq_ultra_ps_e_0]] -clear_locs

# add module checkpoint to static's blackbox

read_checkpoint -cell nodeultra_top_i/PR_SLOT_0_0/U0/inst_PR_WRP/PR_Kernel ./Synth/reconfig_modules/${top_module}.dcp

create_pblock pblock_PR_Kernel
resize_pblock pblock_PR_Kernel -add  {SLICE_X15Y0:SLICE_X48Y59 DSP48E2_X1Y0:DSP48E2_X4Y23 RAMB18_X2Y0:RAMB18_X5Y23 RAMB36_X2Y0:RAMB36_X5Y11}
add_cells_to_pblock pblock_PR_Kernel [get_cells [list nodeultra_top_i/PR_SLOT_0_0/U0/inst_PR_WRP]]

opt_design

# pre-place the connection macros
source place_pre_0.tcl
source place_pre_3.tcl

source ./ted.createFabric.tcl

place_design

# pre-route the connection macros
source route_pre_0.tcl
source route_pre_3.tcl

# adding blocker
set blockerNet [ted::routing::getNetVCC]

set fixedRoutePips {}

foreach line [get_tiles -filter {TYPE == RCLK_INT_L && GRID_POINT_X>181 && GRID_POINT_Y == 155}] {
	for {set j 0} {$j<32} {incr j} 	{
		if {$j==0 || $j==10} continue
		lappend fixedRoutePips "$line/RCLK_INT_L.CLK_LEAF_SITES_$j\_CLK_IN->>CLK_LEAF_SITES_$j\_CLK_LEAF"
	}
}

foreach line [get_tiles -filter {TYPE == RCLK_INT_R && GRID_POINT_Y == 155}] {
	for {set j 0} {$j<32} {incr j} 	{
		if {$j==0 || $j==10} continue
		lappend fixedRoutePips "$line/RCLK_INT_R.CLK_LEAF_SITES_$j\_CLK_IN->>CLK_LEAF_SITES_$j\_CLK_LEAF"
	}
}
set_property FIXED_ROUTE "{[join $fixedRoutePips "} {"]}" $blockerNet

route_design -net $clkNet

#the one shot line crashes vivado
#ted::routing::blockFreeNodes $net        [get_nodes -of_objects [get_tiles -filter {(TILE_Y<63&&(TILE_X==188||TILE_X==303))||(TILE_X>188&&(TILE_Y==0||TILE_Y==62)&&TILE_X<303)}]]
ted::routing::blockFreeNodes $blockerNet [get_nodes -of_objects [get_tiles -filter {(TILE_Y<63&&(TILE_X==188||TILE_X==303))||(TILE_X>188&&(TILE_Y==0||TILE_Y==62)&&TILE_X<303)}] -filter !IS_GND&&!IS_VCC&&NAME!~HDIO_*&&NAME!~HPIO_*]

#ted::routing::blockFreeNodes $blockerNet [get_nodes -of_objects [get_tiles -filter {TILE_Y<63&&TILE_X==188}] -filter !IS_GND&&!IS_VCC&&NAME!~HDIO_*&&NAME!~HPIO_*]
#ted::routing::blockFreeNodes $blockerNet [get_nodes -of_objects [get_tiles -filter {TILE_Y<63&&TILE_X==303}] -filter !IS_GND&&!IS_VCC&&NAME!~HDIO_*&&NAME!~HPIO_*]
#ted::routing::blockFreeNodes $blockerNet [get_nodes -of_objects [get_tiles -filter {TILE_X>188&&TILE_Y==0 &&TILE_X<303}] -filter !IS_GND&&!IS_VCC&&NAME!~HDIO_*&&NAME!~HPIO_*]
#ted::routing::blockFreeNodes $blockerNet [get_nodes -of_objects [get_tiles -filter {TILE_X>188&&TILE_Y==62&&TILE_X<303}] -filter !IS_GND&&!IS_VCC&&NAME!~HDIO_*&&NAME!~HPIO_*]

route_design

write_checkpoint -force ./DCPs/${top_module}_route_w_blocker

# remove the blocker
ted::routing::unroute $blockerNet true
route_design  -physical_nets

write_checkpoint -force ./DCPs/${top_module}_route_final

# generate bitstream
set_property BITSTREAM.GENERAL.CRC DISABLE [current_design]

write_bitstream -bin_file ./${top_module}_full