if {![info exists ::env(HC_PROJECT_DIR)]} {puts stderr "HC_PROJECT_DIR is not set";quit -code 2 -f}
set project_dir [file normalize $::env(HC_PROJECT_DIR)]
set script_dir [file join $project_dir sim]
set rtl_file [file join $project_dir rtl han_carlson16.v]
set tb_file [file join $project_dir tb tb_han_carlson16.v]
set work_dir [file join $script_dir work_han_carlson]
set log_file [file join $project_dir docs han_carlson_simulation.log]
cd $script_dir
onerror {quit -code 1 -f}
transcript file $log_file
transcript on
if {[file isdirectory $work_dir]} {vdel -lib $work_dir -all}
vlib $work_dir; vmap work $work_dir
vlog -vlog01compat $rtl_file $tb_file
vsim work.tb_han_carlson16

array set node_high {}; array set node_low {}; array set depth_cache {}
set ids {}; set black_count 0; set gray_count 0
set stage_counts {0 0 0 0 0}; set stage_connections {{} {} {} {} {}}
set instances [find instances -recursive /tb_han_carlson16/dut/*]
foreach item $instances {
 set path [lindex $item 0]
 if {[string match "*hc_black_cell*" $item] || [string match "*hc_gray_cell*" $item]} {
  set id [examine -radix decimal ${path}/NODE_ID]
  set node_high($id) [examine -radix decimal ${path}/HIGH_SOURCE_ID]
  set node_low($id) [examine -radix decimal ${path}/LOW_SOURCE_ID]
  set hi [examine -radix decimal ${path}/HIGH_INDEX]
  set lo [examine -radix decimal ${path}/LOW_INDEX]
  set stage [examine -radix decimal ${path}/STAGE]
  lappend ids $id
  lset stage_counts [expr {$stage-1}] [expr {[lindex $stage_counts [expr {$stage-1}]]+1}]
  set connections [lindex $stage_connections [expr {$stage-1}]]
  lappend connections "$hi:$lo"
  lset stage_connections [expr {$stage-1}] $connections
  if {[string match "*hc_black_cell*" $item]} {incr black_count} else {incr gray_count}
 }
}
proc node_depth {id} {
 global node_high node_low depth_cache
 if {$id<0} {return 0}
 if {[info exists depth_cache($id)]} {return $depth_cache($id)}
 if {![info exists node_high($id)]} {error "Missing node $id"}
 set dh [node_depth $node_high($id)]; set dl [node_depth $node_low($id)]
 set d [expr {1+(($dh>$dl)?$dh:$dl)}]; set depth_cache($id) $d; return $d
}
set longest 0
foreach id $ids {set d [node_depth $id]; if {$d>$longest} {set longest $d}}
for {set i 0} {$i<5} {incr i} {lset stage_connections $i [lsort -dictionary [lindex $stage_connections $i]]}
set ids [lsort -integer $ids]
set expected_ids {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31}
set expected_s1 {1:0 3:2 5:4 7:6 9:8 11:10 13:12 15:14}
set expected_s2 {1:0 2:1 3:2 4:3 5:4 6:5 7:6}
set expected_s3 {2:0 3:1 4:2 5:3 6:4 7:5}
set expected_s4 {4:0 5:1 6:2 7:3}
set expected_s5 {2:1 4:3 6:5 8:7 10:9 12:11 14:13}
puts "HAN_CARLSON_STAGE_COUNTS=[join $stage_counts ,]"
puts "HAN_CARLSON_BLACK_CELL_COUNT=$black_count"
puts "HAN_CARLSON_GRAY_CELL_COUNT=$gray_count"
puts "HAN_CARLSON_PREFIX_CELL_COUNT=[llength $ids]"
for {set i 0} {$i<5} {incr i} {puts "HAN_CARLSON_STAGE[expr {$i+1}]_CONNECTIONS=[join [lindex $stage_connections $i] ,]"}
puts "HAN_CARLSON_LONGEST_PREFIX_CHAIN=$longest"
if {$stage_counts ne {8 7 6 4 7} || $black_count!=17 || $gray_count!=15 ||
    [llength $ids]!=32 || $ids ne $expected_ids ||
    [lindex $stage_connections 0] ne $expected_s1 || [lindex $stage_connections 1] ne $expected_s2 ||
    [lindex $stage_connections 2] ne $expected_s3 || [lindex $stage_connections 3] ne $expected_s4 ||
    [lindex $stage_connections 4] ne $expected_s5 || $longest!=5} {
 puts stderr "HAN_CARLSON_STRUCTURE_FAIL";quit -code 3 -f
}
puts "HAN_CARLSON_STRUCTURE_PASS expected_total=32"

proc finish_status {} {
 set s [runStatus];set d [runStatus -full]
 puts "MODELSIM_RUN_STATUS=$s";puts "MODELSIM_RUN_STATUS_FULL=$d"
 if {$s ne "break" || ![string match {*simulation_stop*{$finish}*} $d]} {puts stderr "MODELSIM_ABNORMAL_TERMINATION";quit -code 2 -f}
 if {[catch {examine -radix decimal /tb_han_carlson16/test_count} t]} {quit -code 2 -f}
 if {[catch {examine -radix decimal /tb_han_carlson16/error_count} e]} {quit -code 2 -f}
 puts "MODELSIM_TEST_COUNT=$t";puts "MODELSIM_ERROR_COUNT=$e"
 if {$t!=10012} {quit -code 4 -f}
 if {$e==0} {puts "MODELSIM_EXIT_CODE=0";quit -code 0 -f} else {puts "MODELSIM_EXIT_CODE=1";quit -code 1 -f}
}
onbreak {finish_status}
onfinish stop
run -all
