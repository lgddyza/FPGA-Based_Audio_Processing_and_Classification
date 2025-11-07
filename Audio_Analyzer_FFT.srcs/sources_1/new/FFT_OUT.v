`timescale 1ns / 1ps

module FFT_OUT(
    input  wire        sys_clk,
    input  wire        sys_rst_n,
    input  wire [7:0]  adc_data,
    output wire [7:0]  dac_data,
    output wire        ad_clk,
    output wire        da_clk,
    output wire        voice,
    output wire        music,
    output wire        busy,
    output wire        max,

    // Zynq PS端接口（inout端口）
    inout  wire [14:0] DDR_0_addr,
    inout  wire [2:0]  DDR_0_ba,
    inout  wire        DDR_0_cas_n,
    inout  wire        DDR_0_ck_n,
    inout  wire        DDR_0_ck_p,
    inout  wire        DDR_0_cke,
    inout  wire        DDR_0_cs_n,
    inout  wire [3:0]  DDR_0_dm,
    inout  wire [31:0] DDR_0_dq,
    inout  wire [3:0]  DDR_0_dqs_n,
    inout  wire [3:0]  DDR_0_dqs_p,
    inout  wire        DDR_0_odt,
    inout  wire        DDR_0_ras_n,
    inout  wire        DDR_0_reset_n,
    inout  wire        DDR_0_we_n,
    inout  wire        FIXED_IO_0_ddr_vrn,
    inout  wire        FIXED_IO_0_ddr_vrp,
    inout  wire [53:0] FIXED_IO_0_mio,
    inout  wire        FIXED_IO_0_ps_clk,
    inout  wire        FIXED_IO_0_ps_porb,
    inout  wire        FIXED_IO_0_ps_srstb
);

    wire [11:0] index;

//--------------------------------------------------
// 将voice, music, busy信号打包成3位向量连接到EMIO
//--------------------------------------------------
wire [15:0] pl_to_ps_signals;

assign pl_to_ps_signals[0] = voice;  // EMIO引脚54
assign pl_to_ps_signals[1] = music;  // EMIO引脚55  
assign pl_to_ps_signals[2] = busy;   // EMIO引脚56
assign pl_to_ps_signals[3] = max;    // EMIO引脚57
assign pl_to_ps_signals[15:4] = index;  // EMIO引脚58-69

//--------------------------------------------------
// FFT处理模块实例化
//--------------------------------------------------
FIFO_to_FFT u_FIFO_to_FFT (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .adc_data(adc_data),
    .dac_data(dac_data),
    .ad_clk(ad_clk),
    .da_clk(da_clk),
    .voice(voice),
    .music(music),
    .busy(busy),
    .max(max),
    .index(index)
);

//--------------------------------------------------
// Zynq PS系统wrapper实例化
//--------------------------------------------------
zynq_a9_wrapper zynq_a9_wrapper_i (
    // DDR和固定IO接口（必须连接）
    .DDR_0_addr          (DDR_0_addr),
    .DDR_0_ba            (DDR_0_ba),
    .DDR_0_cas_n         (DDR_0_cas_n),
    .DDR_0_ck_n          (DDR_0_ck_n),
    .DDR_0_ck_p          (DDR_0_ck_p),
    .DDR_0_cke           (DDR_0_cke),
    .DDR_0_cs_n          (DDR_0_cs_n),
    .DDR_0_dm            (DDR_0_dm),
    .DDR_0_dq            (DDR_0_dq),
    .DDR_0_dqs_n         (DDR_0_dqs_n),
    .DDR_0_dqs_p         (DDR_0_dqs_p),
    .DDR_0_odt           (DDR_0_odt),
    .DDR_0_ras_n         (DDR_0_ras_n),
    .DDR_0_reset_n       (DDR_0_reset_n),
    .DDR_0_we_n          (DDR_0_we_n),
    
    .FIXED_IO_0_ddr_vrn  (FIXED_IO_0_ddr_vrn),
    .FIXED_IO_0_ddr_vrp  (FIXED_IO_0_ddr_vrp),
    .FIXED_IO_0_mio      (FIXED_IO_0_mio),
    .FIXED_IO_0_ps_clk   (FIXED_IO_0_ps_clk),
    .FIXED_IO_0_ps_porb  (FIXED_IO_0_ps_porb),
    .FIXED_IO_0_ps_srstb (FIXED_IO_0_ps_srstb),
    
    // EMIO输入 - 连接到PL端的voice, music, busy信号
    .GPIO_I_1            (pl_to_ps_signals)  // 16位信号向量
);

endmodule