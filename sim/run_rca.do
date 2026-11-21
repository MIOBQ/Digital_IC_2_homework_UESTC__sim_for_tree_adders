if {![info exists ::env(RCA_PROJECT_DIR)]} {
    puts stderr "RCA_PROJECT_DIR is not set. Run sim/run_rca.ps1."
    quit -code 2 -f
}

set project_dir [file normalize $::env(RCA_PROJECT_DIR)]
set script_dir  [file join $project_dir sim]
set rtl_file    [file join $project_dir rtl rca16.v]
set tb_file     [file join $project_dir tb tb_rca16.v]
set work_dir    [file join $script_dir work]
set log_file    [file join $project_dir docs rca_simulation.log]

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

vsim work.tb_rca16

proc finish_with_test_status {} {
    set error_count [examine -radix decimal /tb_rca16/error_count]
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
