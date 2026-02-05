connect -url tcp:127.0.0.1:3121
source F:/FPGA/work_space/AD_DA_tran/AD_DA_tran.sdk/FFT_OUT_hw_platform_0/ps7_init.tcl
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent JTAG-SMT3 210357A7D00EA"} -index 0
loadhw -hw F:/FPGA/work_space/AD_DA_tran/AD_DA_tran.sdk/FFT_OUT_hw_platform_0/system.hdf -mem-ranges [list {0x40000000 0xbfffffff}]
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent JTAG-SMT3 210357A7D00EA"} -index 0
stop
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent JTAG-SMT3 210357A7D00EA"} -index 0
rst -processor
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent JTAG-SMT3 210357A7D00EA"} -index 0
dow F:/FPGA/work_space/AD_DA_tran/AD_DA_tran.sdk/Uart_0/Debug/Uart_0.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent JTAG-SMT3 210357A7D00EA"} -index 0
con
