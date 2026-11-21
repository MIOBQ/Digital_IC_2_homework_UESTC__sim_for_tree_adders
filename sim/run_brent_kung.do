if {![info exists ::env(BK_PROJECT_DIR)]} {
    puts stderr "BK_PROJECT_DIR is not set. Run sim/run_brent_kung.ps1."
    quit -code 2 -f
}

set project_dir [file normalize $::env(BK_PROJECT_DIR)]
set script_dir  [file join $project_dir sim]
set rtl_file    [file join $project_dir rtl brent_kung16.v]
set tb_file     [file join $project_dir tb tb_brent_kung16.v]
set work_dir    [file join $script_dir work_brent_kung]
set log_file    [file join $project_dir docs brent_kung_simulation.log]

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
vsim work.tb_brent_kung16

set up_count 0
set down_count 0
set black_count 0
set gray_count 0
set stage_counts {0 0 0 0 0 0 0}
set expected_stage_counts {8 4 2 1 1 3 7}
set design_instances [find instances -recursive /tb_brent_kung16/dut/*]

foreach instance_name $design_instances {
    if {[string match "*/up_sweep*" $instance_name]} {incr up_count}
    if {[string match "*/down_sweep*" $instance_name]} {incr down_count}
    if {[string match "*bk_black_cell*" $instance_name]} {incr black_count}
    if {[string match "*bk_gray_cell*" $instance_name]} {incr gray_count}

    for {set stage 1} {$stage <= 7} {incr stage} {
        if {[string match "*stage$stage/*" $instance_name]} {
            set index [expr {$stage - 1}]
            lset stage_counts $index [expr {[lindex $stage_counts $index] + 1}]
        }
    }
}

set prefix_count [expr {$up_count + $down_count}]
puts "BRENT_KUNG_STAGE_COUNTS=[join $stage_counts ,]"
puts "BRENT_KUNG_UP_SWEEP_COUNT=$up_count"
puts "BRENT_KUNG_DOWN_SWEEP_COUNT=$down_count"
puts "BRENT_KUNG_BLACK_CELL_COUNT=$black_count"
puts "BRENT_KUNG_GRAY_CELL_COUNT=$gray_count"
puts "BRENT_KUNG_PREFIX_CELL_COUNT=$prefix_count"

if {$stage_counts ne $expected_stage_counts ||
    $up_count != 15 || $down_count != 11 || $prefix_count != 26 ||
    $black_count != 11 || $gray_count != 15} {
    puts stderr "BRENT_KUNG_STRUCTURE_FAIL"
    quit -code 3 -f
}
puts "BRENT_KUNG_STRUCTURE_PASS expected_up=15 expected_down=11 expected_total=26"

proc finish_with_test_status {} {
    set run_state [runStatus]
    set run_detail [runStatus -full]
    puts "MODELSIM_RUN_STATUS=$run_state"
    puts "MODELSIM_RUN_STATUS_FULL=$run_detail"

    if {$run_state == "error" ||
        [string match "*fatal_error*" $run_detail] ||
        [string match "*iteration_limit*" $run_detail] ||
        [string match "*gate_oscillation*" $run_detail]} {
        puts stderr "MODELSIM_SIMULATION_ERROR"
        quit -code 2 -f
    }

    if {[catch {examine -radix decimal /tb_brent_kung16/error_count} error_count]} {
        puts stderr "MODELSIM_ERROR_COUNT_READ_FAILED=$error_count"
        quit -code 2 -f
    }

    puts "MODELSIM_ERROR_COUNT=$error_count"
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
