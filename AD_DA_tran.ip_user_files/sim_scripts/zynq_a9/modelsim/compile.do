vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xilinx_vip
vlib modelsim_lib/msim/xil_defaultlib
vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/axi_infrastructure_v1_1_0
vlib modelsim_lib/msim/axi_vip_v1_1_4
vlib modelsim_lib/msim/processing_system7_vip_v1_0_6

vmap xilinx_vip modelsim_lib/msim/xilinx_vip
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib
vmap xpm modelsim_lib/msim/xpm
vmap axi_infrastructure_v1_1_0 modelsim_lib/msim/axi_infrastructure_v1_1_0
vmap axi_vip_v1_1_4 modelsim_lib/msim/axi_vip_v1_1_4
vmap processing_system7_vip_v1_0_6 modelsim_lib/msim/processing_system7_vip_v1_0_6

vlog -work xilinx_vip -64 -incr -sv -L axi_vip_v1_1_4 -L processing_system7_vip_v1_0_6 -L xilinx_vip "+incdir+F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/include" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi_vip_if.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/clk_vip_if.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xil_defaultlib -64 -incr -sv -L axi_vip_v1_1_4 -L processing_system7_vip_v1_0_6 -L xilinx_vip "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/ec67/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/70cf/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ip/zynq_a9_processing_system7_0_0" "+incdir+F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/include" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93 \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work axi_infrastructure_v1_1_0 -64 -incr "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/ec67/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/70cf/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ip/zynq_a9_processing_system7_0_0" "+incdir+F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/include" \
"../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_vip_v1_1_4 -64 -incr -sv -L axi_vip_v1_1_4 -L processing_system7_vip_v1_0_6 -L xilinx_vip "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/ec67/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/70cf/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ip/zynq_a9_processing_system7_0_0" "+incdir+F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/include" \
"../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/98af/hdl/axi_vip_v1_1_vl_rfs.sv" \

vlog -work processing_system7_vip_v1_0_6 -64 -incr -sv -L axi_vip_v1_1_4 -L processing_system7_vip_v1_0_6 -L xilinx_vip "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/ec67/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/70cf/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ip/zynq_a9_processing_system7_0_0" "+incdir+F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/include" \
"../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/70cf/hdl/processing_system7_vip_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib -64 -incr "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/ec67/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/70cf/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ip/zynq_a9_processing_system7_0_0" "+incdir+F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/include" \
"../../../bd/zynq_a9/ip/zynq_a9_processing_system7_0_0/sim/zynq_a9_processing_system7_0_0.v" \
"../../../bd/zynq_a9/sim/zynq_a9.v" \

vlog -work xil_defaultlib \
"glbl.v"

