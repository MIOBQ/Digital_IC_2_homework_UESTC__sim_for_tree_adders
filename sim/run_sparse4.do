if {![info exists ::env(SPARSE4_PROJECT_DIR)]} {
    puts stderr "SPARSE4_PROJECT_DIR is not set. Run sim/run_sparse4.ps1."
    quit -code 2 -f
}

set project_dir [file normalize $::env(SPARSE4_PROJECT_DIR)]
set script_dir  [file join $project_dir sim]
set rtl_file    [file join $project_dir rtl sparse4_16.v]
set tb_file     [file join $project_dir tb tb_sparse4_16.v]
set work_dir    [file join $script_dir work_sparse4]
set log_file    [file join $project_dir docs sparse4_simulation.log]
cd $script_dir

onerror {quit -code 1 -f}
transcript file $log_file
transcript on

if {[file isdirectory $work_dir]} {vdel -lib $work_dir -all}
vlib $work_dir
vmap work $work_dir
vlog -vlog01compat $rtl_file $tb_file
vsim work.tb_sparse4_16

set group_count 0
set group_level1_count 0
set group_level2_count 0
set inter_stage1_count 0
set inter_stage2_count 0
set local_carry_count 0
set longest_prefix_chain 0
set longest_local_ripple_chain 0
set group_level1_connections {}
set group_level2_connections {}
set inter_stage1_connections {}
set inter_stage2_connections {}
set inter_stage1_distances {}
set inter_stage2_distances {}
set design_instances [find instances -recursive /tb_sparse4_16/dut/*]

foreach instance_name $design_instances {
    set instance_path [lindex $instance_name 0]

    if {[string match "*sparse4_prefix_cell*" $instance_name]} {
        set depth [examine -radix decimal ${instance_path}/PREFIX_DEPTH]
        set distance [examine -radix decimal ${instance_path}/DISTANCE]
        set high_index [examine -radix decimal ${instance_path}/HIGH_INDEX]
        set low_index [examine -radix decimal ${instance_path}/LOW_INDEX]
        if {$depth > $longest_prefix_chain} {set longest_prefix_chain $depth}

        if {[string match "*/group_tree*" $instance_path]} {
            incr group_count
            if {[string match "*/u_low_pair" $instance_path] ||
                [string match "*/u_high_pair" $instance_path]} {
                incr group_level1_count
                lappend group_level1_connections "$high_index:$low_index"
            } else {
                incr group_level2_count
                lappend group_level2_connections "$high_index:$low_index"
            }
        }
        if {[string match "*/intergroup_stage1*" $instance_path]} {
            incr inter_stage1_count
            lappend inter_stage1_distances $distance
            lappend inter_stage1_connections "$high_index:$low_index"
        }
        if {[string match "*/intergroup_stage2*" $instance_path]} {
            incr inter_stage2_count
            lappend inter_stage2_distances $distance
            lappend inter_stage2_connections "$high_index:$low_index"
        }
    }

    if {[string match "*sparse4_local_carry_cell*" $instance_name]} {
        incr local_carry_count
        set local_depth [examine -radix decimal ${instance_path}/LOCAL_DEPTH]
        if {$local_depth > $longest_local_ripple_chain} {
            set longest_local_ripple_chain $local_depth
        }
    }
}

set group_level1_connections [lsort -dictionary $group_level1_connections]
set group_level2_connections [lsort -dictionary $group_level2_connections]
set inter_stage1_connections [lsort -dictionary $inter_stage1_connections]
set inter_stage2_connections [lsort -dictionary $inter_stage2_connections]
set stage1_distance_set [lsort -unique $inter_stage1_distances]
set stage2_distance_set [lsort -unique $inter_stage2_distances]
set inter_count [expr {$inter_stage1_count + $inter_stage2_count}]
set prefix_count [expr {$group_count + $inter_count}]

set expected_group_level1 {1:0 3:2 5:4 7:6 9:8 11:10 13:12 15:14}
set expected_group_level2 {3:1 7:5 11:9 15:13}
set expected_inter_stage1 {1:0 2:1 3:2}
set expected_inter_stage2 {2:0 3:1}

puts "SPARSE4_GROUP_LEVEL_COUNTS=$group_level1_count,$group_level2_count"
puts "SPARSE4_GROUP_PREFIX_COUNT=$group_count"
puts "SPARSE4_INTERGROUP_STAGE_COUNTS=$inter_stage1_count,$inter_stage2_count"
puts "SPARSE4_INTERGROUP_PREFIX_COUNT=$inter_count"
puts "SPARSE4_PREFIX_CELL_COUNT=$prefix_count"
puts "SPARSE4_GROUP_LEVEL1_CONNECTIONS=[join $group_level1_connections ,]"
puts "SPARSE4_GROUP_LEVEL2_CONNECTIONS=[join $group_level2_connections ,]"
puts "SPARSE4_INTERGROUP_STAGE1_CONNECTIONS=[join $inter_stage1_connections ,]"
puts "SPARSE4_INTERGROUP_STAGE2_CONNECTIONS=[join $inter_stage2_connections ,]"
puts "SPARSE4_INTERGROUP_DISTANCE_SETS=$stage1_distance_set,$stage2_distance_set"
puts "SPARSE4_LONGEST_PREFIX_CELL_CHAIN=$longest_prefix_chain"
puts "SPARSE4_LOCAL_CARRY_CELL_COUNT=$local_carry_count"
puts "SPARSE4_LONGEST_LOCAL_RIPPLE_CHAIN=$longest_local_ripple_chain"

if {$group_level1_count != 8 || $group_level2_count != 4 ||
    $group_count != 12 || $inter_stage1_count != 3 ||
    $inter_stage2_count != 2 || $inter_count != 5 || $prefix_count != 17 ||
    $group_level1_connections ne $expected_group_level1 ||
    $group_level2_connections ne $expected_group_level2 ||
    $inter_stage1_connections ne $expected_inter_stage1 ||
    $inter_stage2_connections ne $expected_inter_stage2 ||
    $stage1_distance_set ne "1" || $stage2_distance_set ne "2" ||
    $longest_prefix_chain != 4 || $local_carry_count != 12 ||
    $longest_local_ripple_chain != 3} {
    puts stderr "SPARSE4_STRUCTURE_FAIL"
    quit -code 3 -f
}
puts "SPARSE4_STRUCTURE_PASS expected_group=12 expected_intergroup=5 expected_total=17"

proc finish_with_test_status {} {
    set run_state [runStatus]
    set run_detail [runStatus -full]
    puts "MODELSIM_RUN_STATUS=$run_state"
    puts "MODELSIM_RUN_STATUS_FULL=$run_detail"
    if {$run_state ne "break" ||
        ![string match {*simulation_stop*{$finish}*} $run_detail]} {
        puts stderr "MODELSIM_ABNORMAL_TERMINATION"
        quit -code 2 -f
    }
    if {[catch {examine -radix decimal /tb_sparse4_16/error_count} error_count]} {
        puts stderr "MODELSIM_ERROR_COUNT_READ_FAILED=$error_count"
        quit -code 2 -f
    }
    if {[catch {examine -radix decimal /tb_sparse4_16/test_count} test_count]} {
        puts stderr "MODELSIM_TEST_COUNT_READ_FAILED=$test_count"
        quit -code 2 -f
    }
    puts "MODELSIM_TEST_COUNT=$test_count"
    puts "MODELSIM_ERROR_COUNT=$error_count"
    if {$test_count != 10012} {
        puts stderr "MODELSIM_TEST_COUNT_MISMATCH expected=10012 actual=$test_count"
        quit -code 4 -f
    }
    if {$error_count == 0} {
        puts "MODELSIM_EXIT_CODE=0"
        quit -code 0 -f
    } else {
        puts "MODELSIM_EXIT_CODE=1"
        quit -code 1 -f
    }
}

onbreak {finish_with_test_status}
onfinish stop
run -all
