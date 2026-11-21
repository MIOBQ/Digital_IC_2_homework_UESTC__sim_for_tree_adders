if {![info exists ::env(SPARSE8_PROJECT_DIR)]} {
    puts stderr "SPARSE8_PROJECT_DIR is not set. Run sim/run_sparse8.ps1."
    quit -code 2 -f
}
set project_dir [file normalize $::env(SPARSE8_PROJECT_DIR)]
set script_dir [file join $project_dir sim]
set rtl_file [file join $project_dir rtl sparse8_16.v]
set tb_file [file join $project_dir tb tb_sparse8_16.v]
set work_dir [file join $script_dir work_sparse8]
set log_file [file join $project_dir docs sparse8_simulation.log]
cd $script_dir
onerror {quit -code 1 -f}
transcript file $log_file
transcript on
if {[file isdirectory $work_dir]} {vdel -lib $work_dir -all}
vlib $work_dir
vmap work $work_dir
vlog -vlog01compat $rtl_file $tb_file
vsim work.tb_sparse8_16

array set prefix_high {}
array set prefix_low {}
array set prefix_depth_cache {}
array set local_prev {}
array set local_boundary {}
array set local_depth_cache {}
array set mixed_depth_cache {}
set prefix_ids {}
set local_ids {}
set level1_count 0
set level2_count 0
set level3_count 0
set inter_count 0
set local_count 0
set level1_connections {}
set level2_connections {}
set level3_connections {}
set inter_connections {}

set design_instances [find instances -recursive /tb_sparse8_16/dut/*]
foreach instance_name $design_instances {
    set path [lindex $instance_name 0]
    if {[string match "*sparse8_prefix_cell*" $instance_name]} {
        set id [examine -radix decimal ${path}/NODE_ID]
        set prefix_high($id) [examine -radix decimal ${path}/HIGH_SOURCE_ID]
        set prefix_low($id) [examine -radix decimal ${path}/LOW_SOURCE_ID]
        set hi [examine -radix decimal ${path}/HIGH_INDEX]
        set lo [examine -radix decimal ${path}/LOW_INDEX]
        lappend prefix_ids $id
        if {[string match "*/level1*" $path]} {incr level1_count; lappend level1_connections "$hi:$lo"}
        if {[string match "*/group_level2*" $path]} {incr level2_count; lappend level2_connections "$hi:$lo"}
        if {[string match "*/group_level3*" $path]} {incr level3_count; lappend level3_connections "$hi:$lo"}
        if {[string match "*/intergroup_stage1*" $path]} {incr inter_count; lappend inter_connections "$hi:$lo"}
    }
    if {[string match "*sparse8_local_carry_cell*" $instance_name]} {
        set id [examine -radix decimal ${path}/NODE_ID]
        set local_prev($id) [examine -radix decimal ${path}/PREV_LOCAL_ID]
        set local_boundary($id) [examine -radix decimal ${path}/BOUNDARY_PREFIX_ID]
        lappend local_ids $id
        incr local_count
    }
}

proc prefix_depth {id} {
    global prefix_high prefix_low prefix_depth_cache
    if {$id < 0} {return 0}
    if {[info exists prefix_depth_cache($id)]} {return $prefix_depth_cache($id)}
    if {![info exists prefix_high($id)]} {error "Missing prefix node $id"}
    set dh [prefix_depth $prefix_high($id)]
    set dl [prefix_depth $prefix_low($id)]
    set d [expr {1 + (($dh > $dl) ? $dh : $dl)}]
    set prefix_depth_cache($id) $d
    return $d
}
proc local_depth {id} {
    global local_prev local_depth_cache
    if {$id < 0} {return 0}
    if {[info exists local_depth_cache($id)]} {return $local_depth_cache($id)}
    set d [expr {1 + [local_depth $local_prev($id)]}]
    set local_depth_cache($id) $d
    return $d
}
proc mixed_depth {id} {
    global local_prev local_boundary mixed_depth_cache
    if {$id < 0} {return 0}
    if {[info exists mixed_depth_cache($id)]} {return $mixed_depth_cache($id)}
    if {$local_prev($id) >= 0} {set base [mixed_depth $local_prev($id)]} else {set base [prefix_depth $local_boundary($id)]}
    set d [expr {$base + 1}]
    set mixed_depth_cache($id) $d
    return $d
}

set longest_prefix 0
foreach id $prefix_ids {set d [prefix_depth $id]; if {$d > $longest_prefix} {set longest_prefix $d}}
set longest_local 0
set longest_sum_dependency 0
foreach id $local_ids {
    set ld [local_depth $id]; if {$ld > $longest_local} {set longest_local $ld}
    set md [mixed_depth $id]; if {$md > $longest_sum_dependency} {set longest_sum_dependency $md}
}
set c8_prefix_depth [prefix_depth 6]
set c16_prefix_depth [prefix_depth 14]

set level1_connections [lsort -dictionary $level1_connections]
set level2_connections [lsort -dictionary $level2_connections]
set level3_connections [lsort -dictionary $level3_connections]
set inter_connections [lsort -dictionary $inter_connections]
set prefix_ids [lsort -integer $prefix_ids]
set local_ids [lsort -integer $local_ids]
set expected_l1 {1:0 3:2 5:4 7:6 9:8 11:10 13:12 15:14}
set expected_l2 {3:1 7:5 11:9 15:13}
set expected_l3 {7:3 15:11}
set expected_inter {15:7}
set expected_prefix_ids {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14}
set expected_local_ids {0 1 2 3 4 5 6 7 8 9 10 11 12 13}

set group_count [expr {$level1_count+$level2_count+$level3_count}]
set prefix_count [expr {$group_count+$inter_count}]
puts "SPARSE8_GROUP_LEVEL_COUNTS=$level1_count,$level2_count,$level3_count"
puts "SPARSE8_GROUP_PREFIX_COUNT=$group_count"
puts "SPARSE8_INTERGROUP_PREFIX_COUNT=$inter_count"
puts "SPARSE8_PREFIX_CELL_COUNT=$prefix_count"
puts "SPARSE8_LEVEL1_CONNECTIONS=[join $level1_connections ,]"
puts "SPARSE8_LEVEL2_CONNECTIONS=[join $level2_connections ,]"
puts "SPARSE8_LEVEL3_CONNECTIONS=[join $level3_connections ,]"
puts "SPARSE8_INTERGROUP_CONNECTIONS=[join $inter_connections ,]"
puts "SPARSE8_LOCAL_CARRY_CELL_COUNT=$local_count"
puts "SPARSE8_LONGEST_PREFIX_CELL_CHAIN=$longest_prefix"
puts "SPARSE8_LONGEST_LOCAL_RIPPLE_CHAIN=$longest_local"
puts "SPARSE8_C8_PREFIX_DEPTH=$c8_prefix_depth"
puts "SPARSE8_C16_PREFIX_DEPTH=$c16_prefix_depth"
puts "SPARSE8_LONGEST_SUM_DEPENDENCY_CELL_CHAIN=$longest_sum_dependency"

if {$level1_count != 8 || $level2_count != 4 || $level3_count != 2 ||
    $group_count != 14 || $inter_count != 1 || $prefix_count != 15 ||
    $local_count != 14 || $level1_connections ne $expected_l1 ||
    $level2_connections ne $expected_l2 || $level3_connections ne $expected_l3 ||
    $inter_connections ne $expected_inter || $prefix_ids ne $expected_prefix_ids ||
    $local_ids ne $expected_local_ids || $longest_prefix != 4 ||
    $longest_local != 7 || $c8_prefix_depth != 3 ||
    $c16_prefix_depth != 4 || $longest_sum_dependency != 10} {
    puts stderr "SPARSE8_STRUCTURE_FAIL"
    quit -code 3 -f
}
puts "SPARSE8_STRUCTURE_PASS expected_group=14 expected_intergroup=1 expected_total=15"

proc finish_with_test_status {} {
    set state [runStatus]
    set detail [runStatus -full]
    puts "MODELSIM_RUN_STATUS=$state"
    puts "MODELSIM_RUN_STATUS_FULL=$detail"
    if {$state ne "break" || ![string match {*simulation_stop*{$finish}*} $detail]} {puts stderr "MODELSIM_ABNORMAL_TERMINATION"; quit -code 2 -f}
    if {[catch {examine -radix decimal /tb_sparse8_16/error_count} errors]} {puts stderr "MODELSIM_ERROR_COUNT_READ_FAILED=$errors"; quit -code 2 -f}
    if {[catch {examine -radix decimal /tb_sparse8_16/test_count} tests]} {puts stderr "MODELSIM_TEST_COUNT_READ_FAILED=$tests"; quit -code 2 -f}
    puts "MODELSIM_TEST_COUNT=$tests"
    puts "MODELSIM_ERROR_COUNT=$errors"
    if {$tests != 10012} {puts stderr "MODELSIM_TEST_COUNT_MISMATCH expected=10012 actual=$tests"; quit -code 4 -f}
    if {$errors == 0} {puts "MODELSIM_EXIT_CODE=0"; quit -code 0 -f} else {puts "MODELSIM_EXIT_CODE=1"; quit -code 1 -f}
}
onbreak {finish_with_test_status}
onfinish stop
run -all
