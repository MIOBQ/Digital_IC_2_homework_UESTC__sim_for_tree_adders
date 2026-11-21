if {![info exists ::env(KS_PROJECT_DIR)]} {
    puts stderr "KS_PROJECT_DIR is not set. Run sim/run_kogge_stone.ps1."
    quit -code 2 -f
}

set project_dir [file normalize $::env(KS_PROJECT_DIR)]
set script_dir  [file join $project_dir sim]
set rtl_file    [file join $project_dir rtl kogge_stone16.v]
set tb_file     [file join $project_dir tb tb_kogge_stone16.v]
set work_dir    [file join $script_dir work_kogge_stone]
set log_file    [file join $project_dir docs kogge_stone_simulation.log]

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

vsim work.tb_kogge_stone16

set prefix_count 0
set stage1_count 0
set stage2_count 0
set stage3_count 0
set stage4_count 0
set design_instances [find instances -recursive /tb_kogge_stone16/dut/*]
foreach instance_name $design_instances {
    if {[string match "*/u_prefix*" $instance_name]} {
        incr prefix_count
    }
    if {[string match "*/stage1*/u_prefix*" $instance_name]} {incr stage1_count}
    if {[string match "*/stage2*/u_prefix*" $instance_name]} {incr stage2_count}
    if {[string match "*/stage3*/u_prefix*" $instance_name]} {incr stage3_count}
    if {[string match "*/stage4*/u_prefix*" $instance_name]} {incr stage4_count}
}
puts "KOGGE_STONE_STAGE_COUNTS=$stage1_count,$stage2_count,$stage3_count,$stage4_count"
puts "KOGGE_STONE_PREFIX_CELL_COUNT=$prefix_count"

if {$stage1_count != 15 || $stage2_count != 14 ||
    $stage3_count != 12 || $stage4_count != 8 || $prefix_count != 49} {
    puts stderr "KOGGE_STONE_STRUCTURE_FAIL expected=15,14,12,8/49 actual=$stage1_count,$stage2_count,$stage3_count,$stage4_count/$prefix_count"
    quit -code 3 -f
}
puts "KOGGE_STONE_STRUCTURE_PASS expected=49 actual=$prefix_count"

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

    if {[catch {examine -radix decimal /tb_kogge_stone16/error_count} error_count]} {
        puts stderr "MODELSIM_ERROR_COUNT_READ_FAILED=$error_count"
        quit -code 2 -f
    }

    puts "MODELSIM_ERROR_COUNT=$error_count"

    if {$error_count == 0} {
        set exit_code 0
        puts "MODELSIM_EXIT_CODE=0"
    } else {
        set exit_code 1
        puts "MODELSIM_EXIT_CODE=1"
    }

    quit -code $exit_code -f
}

onbreak {finish_with_test_status}
onfinish stop
run -all
