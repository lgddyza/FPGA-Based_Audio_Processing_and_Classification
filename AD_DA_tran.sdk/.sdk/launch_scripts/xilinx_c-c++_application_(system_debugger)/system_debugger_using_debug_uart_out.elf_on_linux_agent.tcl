connect -url tcp:127.0.0.1:3121
source F:/FPGA/work_space/AD_DA_tran/AD_DA_tran.sdk/FFT_OUT_hw_platform_0/ps7_init.tcl
targets -set -filter {jtag_cable_name =~ "Digilent JTAG-SMT3 210357A7D00EA" && level==0} -index 1
fpga -file F:/FPGA/work_space/AD_DA_tran/AD_DA_tran.sdk/FFT_OUT_hw_platform_0/FFT_OUT.bit
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent JTAG-SMT3 210357A7D00EA"} -index 0
loadhw -hw F:/FPGA/work_space/AD_DA_tran/AD_DA_tran.sdk/FFT_OUT_hw_platform_0/system.hdf -mem-ranges [list {0x40000000 0xbfffffff}]
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent JTAG-SMT3 210357A7D00EA"} -index 0
stop
ps7_init
configparams force-mem-access 0
