-makelib xcelium_lib/xilinx_vip -sv \
  "F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
  "F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
  "F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
  "F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
  "F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
  "F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
  "F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/axi_vip_if.sv" \
  "F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/clk_vip_if.sv" \
  "F:/FPGA/Vivado18.3/Vivado/2018.3/data/xilinx_vip/hdl/rst_vip_if.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "F:/FPGA/Vivado18.3/Vivado/2018.3/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "F:/FPGA/Vivado18.3/Vivado/2018.3/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "F:/FPGA/Vivado18.3/Vivado/2018.3/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/axi_infrastructure_v1_1_0 \
  "../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/axi_vip_v1_1_4 -sv \
  "../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/98af/hdl/axi_vip_v1_1_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/processing_system7_vip_v1_0_6 -sv \
  "../../../../AD_DA_tran.srcs/sources_1/bd/zynq_a9/ipshared/70cf/hdl/processing_system7_vip_v1_0_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../bd/zynq_a9/ip/zynq_a9_processing_system7_0_0/sim/zynq_a9_processing_system7_0_0.v" \
  "../../../bd/zynq_a9/sim/zynq_a9.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

