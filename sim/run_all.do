if {![info exists ::env(ALL_PROJECT_DIR)]} {puts stderr "ALL_PROJECT_DIR is not set"; quit -code 2 -f}
set project_dir [file normalize $::env(ALL_PROJECT_DIR)]
set sim_dir [file join $project_dir sim]
set build_dir [file join $sim_dir regression_build]
set log_file [file join $project_dir docs all_adders_regression.log]
set negative_mode [expr {[info exists ::env(ALL_NEGATIVE_TEST)] && $::env(ALL_NEGATIVE_TEST) eq "1"}]
cd $sim_dir
onerror {quit -code 1 -f}
transcript file $log_file
transcript on

file mkdir $build_dir
set libraries {rca_lib ks_lib bk_lib sparse2_lib sparse4_lib sparse8_lib hc_lib regression_work}
foreach lib $libraries {
    set lib_dir [file join $build_dir $lib]
    if {[file isdirectory $lib_dir]} {vdel -lib $lib_dir -all}
    vlib $lib_dir
    vmap $lib $lib_dir
}

vlog -vlog01compat -work rca_lib     [file join $project_dir rtl rca16.v]
vlog -vlog01compat -work ks_lib      [file join $project_dir rtl kogge_stone16.v]
vlog -vlog01compat -work bk_lib      [file join $project_dir rtl brent_kung16.v]
vlog -vlog01compat -work sparse2_lib [file join $project_dir rtl sparse2_16.v]
vlog -vlog01compat -work sparse4_lib [file join $project_dir rtl sparse4_16.v]
vlog -vlog01compat -work sparse8_lib [file join $project_dir rtl sparse8_16.v]
vlog -vlog01compat -work hc_lib      [file join $project_dir rtl han_carlson16.v]
vlog -vlog01compat -work regression_work [file join $project_dir tb tb_all_adders16.v]

set search_args {-L rca_lib -L ks_lib -L bk_lib -L sparse2_lib -L sparse4_lib -L sparse8_lib -L hc_lib}
if {$negative_mode} {
    eval vsim $search_args regression_work.tb_all_adders16 +NEGATIVE_TEST
} else {
    eval vsim $search_args regression_work.tb_all_adders16
}

set expected_bindings {
    dut_rca rca16
    dut_kogge_stone kogge_stone16
    dut_brent_kung brent_kung16
    dut_sparse2 sparse2_16
    dut_sparse4 sparse4_16
    dut_sparse8 sparse8_16
    dut_han_carlson han_carlson16
}
set top_instances [find instances /tb_all_adders16/*]
puts "REGRESSION_LIBRARY_SCHEME=one_logical_library_per_RTL"
puts "REGRESSION_INSTANCE_LIST=$top_instances"
foreach {instance module_name} $expected_bindings {
    set matched 0
    foreach item $top_instances {
        if {[string match "*/$instance*" $item] && [string match "*$module_name*" $item]} {set matched 1}
    }
    puts "BINDING_CHECK instance=$instance module=$module_name matched=$matched"
    if {!$matched} {puts stderr "BINDING_CHECK_FAIL instance=$instance module=$module_name"; quit -code 3 -f}
}

proc finish_status {} {
    set status [runStatus]
    set detail [runStatus -full]
    puts "MODELSIM_RUN_STATUS=$status"
    puts "MODELSIM_RUN_STATUS_FULL=$detail"
    if {$status ne "break" || ![string match {*simulation_stop*{$finish}*} $detail]} {
        puts stderr "MODELSIM_ABNORMAL_TERMINATION"; quit -code 2 -f
    }
    foreach name {directed_count random_count total_vectors total_dut_checks total_errors consistency_errors rca_error_count kogge_stone_error_count brent_kung_error_count sparse2_error_count sparse4_error_count sparse8_error_count han_carlson_error_count} {
        if {[catch {examine -radix decimal /tb_all_adders16/$name} value]} {
            puts stderr "COUNTER_READ_FAIL name=$name"; quit -code 2 -f
        }
        set counter($name) $value
        puts "MODELSIM_[string toupper $name]=$value"
    }
    if {$counter(directed_count) != 12 || $counter(random_count) != 10000 ||
        $counter(total_vectors) != 10012 || $counter(total_dut_checks) != 70084} {
        puts stderr "REGRESSION_COUNT_FAIL"; quit -code 4 -f
    }
    set failed [expr {$counter(total_errors) != 0 || $counter(consistency_errors) != 0}]
    foreach name {rca_error_count kogge_stone_error_count brent_kung_error_count sparse2_error_count sparse4_error_count sparse8_error_count han_carlson_error_count} {
        if {$counter($name) != 0} {set failed 1}
    }
    if {$failed} {puts "MODELSIM_EXIT_CODE=1"; quit -code 1 -f}
    puts "MODELSIM_EXIT_CODE=0"; quit -code 0 -f
}

onbreak {finish_status}
onfinish stop
run -all
