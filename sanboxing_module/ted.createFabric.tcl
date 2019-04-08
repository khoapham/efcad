package require ted 2
#-- begin configuration --
#tiles for which to create fabric, need at least one lut per output/input
#set tiles [get_tiles -filter {TILE_X>=204&&TILE_X<=301&&TILE_Y>=1&&TILE_Y<=59}]
set tiles [get_tiles -filter {TILE_X>=222&&TILE_X<=233&&TILE_Y>=1&&TILE_Y<=61}]

set partialPblock [get_pblocks pblock_PR_Kernel]
set gnd    [::ted::routing::getNetGND $parent]
set vcc    [::ted::routing::getNetVCC $parent]

create_clock -name pseudoClock -period 10 $clkNet

set buttonInWires [list \
	INT_X18Y31/WW4_E_BEG0 \
	INT_X18Y31/WW4_E_BEG1 \
	INT_X18Y31/WW4_E_BEG2 \
	INT_X18Y31/WW4_E_BEG3]
	
set ledOutWires [list \
	INT_X16Y31/EE4_E_BEG0 \
	INT_X16Y31/EE4_E_BEG1 \
	INT_X16Y31/EE4_E_BEG2 \
	INT_X16Y31/EE4_E_BEG3]

#-- end configuration --

#led and switch creation
## ADD Led support

set IOSTANDARD LVCMOS18
set ledPins    [list \
	R7 \
	T5 \
	T7 \
	T4 \
	T3 \
	U2 \
	U6 \
	U5 \
]
set switchPins [list \
	R2 \
	R1 \
	L2 \
	K2 \
]

set ledCount [llength $switchPins]
set ledRange [expr {$ledCount-1}]

set switchIn    [::ted::utility::createCellUnique [ted::utility::joinPath $parent switchIn] IBUF $ledCount]
set ledOut      [::ted::utility::createCellUnique [ted::utility::joinPath $parent led]      OBUF $ledCount]

set ledHarness         [::ted::utility::createNetUnique  [ted::utility::joinPath $parent ledHarness]  $ledCount]
set ledPortHarness     [::ted::utility::createNetUnique  [ted::utility::joinPath $parent switchPorts] $ledCount]
set switchPortHarness  [::ted::utility::createNetUnique  [ted::utility::joinPath $parent ledPorts]    $ledCount]

set ledPorts    [::ted::utility::createPortUnique leds    OUT -from 0 -to $ledRange]
set switchPorts [::ted::utility::createPortUnique buttons IN  -from 0 -to $ledRange]

set connectionList {}

foreach switch $switchIn led $ledOut net $ledHarness netSwitchPort $switchPortHarness netLedPort $ledPortHarness ledPin [lrange $ledPins 0 $ledRange] switchPin [lrange $switchPins 0 $ledRange] ledPort $ledPorts switchPort $switchPorts inWire [lrange $buttonInWires 0 $ledRange] outWire [lrange $ledOutWires 0 $ledRange] {
	lappend connectionList $netSwitchPort [list $switchPort $switch/I] $net [list $switch/O $led/I] $netLedPort [list $led/O $ledPort]
	set_property PACKAGE_PIN $ledPin    $ledPort
	set_property PACKAGE_PIN $switchPin $switchPort
	set_property ROUTE "$switch/O GAP $inWire GAP $outWire GAP $led/I" $net
}

set_property IOSTANDARD $IOSTANDARD $ledPorts
set_property IOSTANDARD $IOSTANDARD $switchPorts

connect_net -hierarchical -net_object_list $connectionList
# PL User LEDs
#
#set_property PACKAGE_PIN R7 [get_ports {PL_LED1}]	;# JX1_HP_DP_25_P
#set_property PACKAGE_PIN T5 [get_ports {PL_LED2}]	;# JX1_HP_DP_24_P
#set_property PACKAGE_PIN T7 [get_ports {PL_LED3}]	;# JX1_HP_DP_25_N
#set_property PACKAGE_PIN T4 [get_ports {PL_LED4}]	;# JX1_HP_DP_24_N
#set_property PACKAGE_PIN T3 [get_ports {PL_LED5}]	;# JX1_HP_DP_27_P
#set_property PACKAGE_PIN U2 [get_ports {PL_LED6}]	;# JX1_HP_DP_27_N
#set_property PACKAGE_PIN U6 [get_ports {PL_LED7}]	;# JX1_HP_DP_26_P
#set_property PACKAGE_PIN U5 [get_ports {PL_LED8}]	;# JX1_HP_DP_26_N

#set_property IOSTANDARD LVCMOS18 [get_ports {PL_LED1}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PL_LED2}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PL_LED3}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PL_LED4}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PL_LED5}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PL_LED6}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PL_LED7}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PL_LED8}]


# PL User Push Switches
#
#set_property PACKAGE_PIN R2 [get_ports {PL_PB1}]	;# JX1_HP_DP_39_P
#set_property PACKAGE_PIN R1 [get_ports {PL_PB2}]	;# JX1_HP_DP_39_N
#set_property PACKAGE_PIN L2 [get_ports {PL_PB3}]	;# JX1_HP_DP_41_P
#set_property PACKAGE_PIN K2 [get_ports {PL_PB4}]	;# JX1_HP_DP_41_N

#set_property IOSTANDARD LVCMOS18 [get_ports {PL_PB1}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PL_PB2}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PL_PB3}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PL_PB4}]

# fabric creation
set pblockLutsTotal [llength [get_bels -of_objects [get_sites -of_objects $partialPblock] -regexp -filter {TYPE=~.*_[A-H]6LUT}]]

set lutBels  [lsort -dictionary [get_bels -of_objects $tiles -regexp -filter {TYPE=~.*_[A-H]6LUT}]]
set flopBels [lsort -dictionary [get_bels -of_objects $tiles -regexp -filter {TYPE=~[A-H]FF2}]]

set usedUpLuts 0

foreach cell [get_cells -of_objects $partialPblock] {
	set usedUpLuts [expr {$usedUpLuts + [::ted::utility::scopeCode {llength [get_cells -hierarchical -filter IS_PRIMITIVE&&PRIMITIVE_SUBGROUP==LUT&&PARENT!~*/keeper_*&&STATUS!=FIXED&&STATUS!=PLACED]} $cell]}]
}

set lutsToCreate [expr {min([llength $lutBels],$pblockLutsTotal-$usedUpLuts)}]

set lutBels  [lrange $lutBels  0 [expr {$lutsToCreate-1}]]
set flopBels [lrange $flopBels 0 [expr {$lutsToCreate-1}]]

set luts    [::ted::utility::createCellUnique [ted::utility::joinPath $parent fabricLut ] LUT6 $lutsToCreate]
set flops   [::ted::utility::createCellUnique [ted::utility::joinPath $parent fabricFlop] FDCE $lutsToCreate]

set_property INIT A $luts

#while a bus could be created, this causes issues later in the flow
set netsLutharness [::ted::utility::createNetUnique [ted::utility::joinPath $parent lutInterconnect] [expr {2*[llength $lutBels]+2}] false]

set i 0
set connectionList {}
set placementList  {}

foreach lut $luts lutBel $lutBels flop $flops flopBel $flopBels {
	set previousLutNet [lindex $netsLutharness $i]
	set previousRegNet [lindex $netsLutharness [expr {$i+1}]]
	
	incr i 2
	
	set lutNet [lindex $netsLutharness $i]
	set regNet [lindex $netsLutharness [expr {$i+1}]]
	
	lappend placementList $lut $lutBel $flop $flopBel
	lappend connectionList $previousLutNet [list $lut/I0 $lut/I1 $lut/I2] $previousRegNet [list $lut/I3 $lut/I4 $lut/I5] $lutNet [list $lut/O $flop/D] $regNet $flop/Q $gnd $flop/CLR $vcc $flop/CE $clkNet $flop/C
}

place_cell $placementList
connect_net -net_object_list $connectionList

set sites [get_sites -of_objects $lutBels]
set slicel [filter $sites {SITE_TYPE==SLICEL}]
set slicem [filter $sites {SITE_TYPE==SLICEM}]

set site_pips [list                  \
	CLK1INV:CLK     \
	CLK2INV:CLK     \
	RST_ABCDINV:RST \
	RST_EFGHINV:RST \
]

foreach lutid {A B C D E F G H} {
	lappend site_pips {*}[format {
	%1$s6LUT:A1 \
	%1$s6LUT:A2 \
	%1$s6LUT:A3 \
	%1$s6LUT:A4 \
	%1$s6LUT:A5 \
	%1$s6LUT:A6 \
	FFMUX%1$s2:D6} $lutid]
}

if {[llength $slicel]} {
	set_property MANUAL_ROUTING SLICEL $slicel
}

if {[llength $slicem]} {
	set_property MANUAL_ROUTING SLICEM $slicem
}

foreach site $sites {
	set site_pips_for_site {}
	foreach site_pip $site_pips {
		lappend site_pips_for_site ${site}/${site_pip}
	}
	set_property SITE_PIPS $site_pips_for_site $site
}

connect_net -net [lindex $netsLutharness 0] -objects [::ted::utility::createCellUnique [ted::utility::joinPath $parent dummyDriver] GND]/G
connect_net -net [lindex $netsLutharness 1] -objects [::ted::utility::createCellUnique [ted::utility::joinPath $parent dummyDriver] GND]/G

# connect to external nets
set tieoffs [get_cells -hierarchical -filter ORIG_REF_NAME==dummyConnector||REF_NAME==dummyConnector]

set inPins  [get_pins -of_objects $tieoffs -filter "DIRECTION==IN &&NAME!~*/${clkNetName}"]
#set inPins  [get_pins -of_objects $tieoffs -filter DIRECTION==IN]
set outPins [get_pins -of_objects $tieoffs -filter DIRECTION==OUT]

set inNets  [lsort -dictionary [get_nets -of $inPins]]
set outNets [lsort -dictionary [get_nets -of $outPins]]

#disconnect nets
disconnect_net -objects $inPins
disconnect_net -objects $outPins

#reconnect outputs
set harnessPins    {}
set connectionList {}
set lutHarnessForOutput [lrange $netsLutharness [expr {[llength $netsLutharness]-[llength $outNets]}] end]

foreach outNet $outNets lutHarness $lutHarnessForOutput {
	set pins [get_pins -of_objects $lutHarness]
	lappend harnessPins {*}$pins
	lappend connectionList $outNet $pins
}

disconnect_net -objects $harnessPins
remove_net $lutHarnessForOutput
connect_net -net_object_list $connectionList

#reconnect inputs
set harnessPins    {}
set connectionList {}
set lutHarnessForInput $netsLutharness
lappend lutHarnessForInput {*}$outNets
set lutHarnessForInput [lrange $lutHarnessForInput 0 [expr {[llength $inNets]-1}]]

foreach inNet $inNets lutHarness $lutHarnessForInput {
	set pins [get_pins -of_objects $lutHarness -filter DIRECTION==IN&&(NAME=~*/I0||NAME=~*/I3)]
	#set pins [get_pins -of_objects $lutHarness -filter DIRECTION==IN]
	lappend harnessPins {*}$pins
	lappend connectionList $inNet $pins
}

disconnect_net -objects $harnessPins
#remove_net $lutHarnessForInput
connect_net -net_object_list $connectionList

#remove tieoffs
::ted::utility::removeCell $tieoffs

# force external routing
#This is BADDD, should we use createPlug?
set wiresPerTile 4
set wireType "EE2_*"
set totalWires 216

set nodes {}
set wiresPerTileLimit [expr {$wiresPerTile-1}]

#ignore the clk tile row in the middle
foreach tile [lsort -dictionary [get_tiles -filter NAME=~INT_X9Y*&&TILE_Y>=0&&TILE_Y<=61]] {
	lappend nodes {*}[lrange [lsort -dictionary [get_nodes -of_objects $tile -filter "NAME=~${tile}/$wireType"]] 0 $wiresPerTileLimit]
}


foreach net [lsort -dictionary [filter $inNets TYPE!=GROUND]] {
#	ted::routing::
}

select_objects $nodes