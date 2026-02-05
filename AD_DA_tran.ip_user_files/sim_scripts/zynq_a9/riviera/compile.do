vlib work
vlib riviera

vlib riviera/xilinx_vip
vlib riviera/xil_defaultlib
vlib riviera/xpm
vlib riviera/axi_infrastructure_v1_1_0
vlib riviera/axi_vip_v1_1_4
vlib riviera/processing_system7_vip_v1_0_6

vmap xilinx_vip riviera/xilinx_vip
vmap xil_defaultlib riviera/xil_defaultlib
vmap xpm riviera/xpm
vmap axi_infrastructure_v1_1_0 riviera/axi_infrastructure_v1_1_0
vmap axi_vip_v1_1_4 riviera/axi_vip_v1_1_4
vmap processing_system7_vip_v1_0_6 riviera/processing_system7_vip_v1_0_6

vlog -work xilinx_vip  -sv2k12 "+incdir+F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/include" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi_vip_if.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/clk_vip_if.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/ec67/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/70cf/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ip/zynq_a9_processing_system7_0_0" "+incdir+F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/include" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"F:/FPGA/Vivado18.3/Vivado/2018.3/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work axi_infrastructure_v1_1_0  -v2k5 "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/ec67/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/70cf/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ip/zynq_a9_processing_system7_0_0" "+incdir+F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/include" \
"../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_vip_v1_1_4  -sv2k12 "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/ec67/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/70cf/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ip/zynq_a9_processing_system7_0_0" "+incdir+F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/include" \
"../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/98af/hdl/axi_vip_v1_1_vl_rfs.sv" \

vlog -work processing_system7_vip_v1_0_6  -sv2k12 "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/ec67/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/70cf/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ip/zynq_a9_processing_system7_0_0" "+incdir+F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/include" \
"../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/70cf/hdl/processing_system7_vip_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/ec67/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/70cf/hdl" "+incdir+../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ip/zynq_a9_processing_system7_0_0" "+incdir+F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/include" \
"../../../bd/zynq_a9/ip/zynq_a9_processing_system7_0_0/sim/zynq_a9_processing_system7_0_0.v" \
"../../../bd/zynq_a9/sim/zynq_a9.v" \

vlog -work xil_defaultlib \
"glbl.v"

