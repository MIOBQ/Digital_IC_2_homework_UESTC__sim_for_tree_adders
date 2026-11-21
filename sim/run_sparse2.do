if {![info exists ::env(SPARSE2_PROJECT_DIR)]} {
    puts stderr "SPARSE2_PROJECT_DIR is not set. Run sim/run_sparse2.ps1."
    quit -code 2 -f
}

set project_dir [file normalize $::env(SPARSE2_PROJECT_DIR)]
set script_dir  [file join $project_dir sim]
set rtl_file    [file join $project_dir rtl sparse2_16.v]
set tb_file     [file join $project_dir tb tb_sparse2_16.v]
set work_dir    [file join $script_dir work_sparse2]
set log_file    [file join $project_dir docs sparse2_simulation.log]

cd $script_dir

onerror {quit -code 1 -f}
transcript file $log_file
transcript on

if {[file isdirectory $work_dir]} {
    vdel -lib $work_dir -all
}
vlib $work_dir
vmap work $work_dir

vlog -vlog01compat $rtl_file $tb_file
vsim work.tb_sparse2_16

set group_count 0
set stage1_count 0
set stage2_count 0
set stage3_count 0
set longest_prefix_chain 0
set stage1_distances {}
set stage2_distances {}
set stage3_distances {}
set design_instances [find instances -recursive /tb_sparse2_16/dut/*]

foreach instance_name $design_instances {
    set instance_path [lindex $instance_name 0]

    if {[string match "*/group_preprocess*" $instance_path]} {incr group_count}
    if {[string match "*/intergroup_stage1*" $instance_path]} {incr stage1_count}
    if {[string match "*/intergroup_stage2*" $instance_path]} {incr stage2_count}
    if {[string match "*/intergroup_stage3*" $instance_path]} {incr stage3_count}

    set instance_depth [examine -radix decimal ${instance_path}/PREFIX_DEPTH]
    set instance_distance [examine -radix decimal ${instance_path}/DISTANCE]
    if {$instance_depth > $longest_prefix_chain} {
        set longest_prefix_chain $instance_depth
    }

    if {[string match "*/intergroup_stage1*" $instance_path]} {
        lappend stage1_distances $instance_distance
    }
    if {[string match "*/intergroup_stage2*" $instance_path]} {
        lappend stage2_distances $instance_distance
    }
    if {[string match "*/intergroup_stage3*" $instance_path]} {
        lappend stage3_distances $instance_distance
    }
}

set prefix_count [expr {$group_count + $stage1_count + $stage2_count + $stage3_count}]
set stage1_distance_set [lsort -unique $stage1_distances]
set stage2_distance_set [lsort -unique $stage2_distances]
set stage3_distance_set [lsort -unique $stage3_distances]

puts "SPARSE2_GROUP_PREFIX_COUNT=$group_count"
puts "SPARSE2_INTERGROUP_STAGE_COUNTS=$stage1_count,$stage2_count,$stage3_count"
puts "SPARSE2_PREFIX_CELL_COUNT=$prefix_count"
puts "SPARSE2_INTERGROUP_DISTANCE_SETS=$stage1_distance_set,$stage2_distance_set,$stage3_distance_set"
puts "SPARSE2_LONGEST_PREFIX_CELL_CHAIN=$longest_prefix_chain"

if {$group_count != 8 || $stage1_count != 7 ||
    $stage2_count != 6 || $stage3_count != 4 || $prefix_count != 25 ||
    $stage1_distance_set ne "1" || $stage2_distance_set ne "2" ||
    $stage3_distance_set ne "4" || $longest_prefix_chain != 4} {
    puts stderr "SPARSE2_STRUCTURE_FAIL"
    quit -code 3 -f
}
puts "SPARSE2_STRUCTURE_PASS expected_groups=8 expected_intergroup=7,6,4 expected_total=25"

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

    if {[catch {examine -radix decimal /tb_sparse2_16/error_count} error_count]} {
        puts stderr "MODELSIM_ERROR_COUNT_READ_FAILED=$error_count"
        quit -code 2 -f
    }
    if {[catch {examine -radix decimal /tb_sparse2_16/test_count} test_count]} {
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
