`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/22 18:55:27
// Design Name: 
// Module Name: TOP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module AD_DA_t(
    input  wire        sys_clk,
    input  wire        sys_rst_n,

    input  wire [7:0]  adc_data,   // ADC 输入数据
    output wire [7:0]  dac_data,   // DAC 输出数据

    output wire        ad_clk,      //AD频率控制
    output wire        da_clk,      //DA频率控制
    output wire        pulse_out
    );

wire clk_out1;
wire div_clk_48;
wire clk_out2;

pll_ip u_pll_ip (
    .clk_in1(sys_clk),
    .clk_out1(clk_out1),
    .resetn(sys_rst_n)
);

clock_div u_clock_div (
    .clk_in(clk_out1),
    .rst_n(sys_rst_n),
    .clk_out(div_clk_48),
    .pulse_out(pulse_out)
);

AD_DA_tran u_AD_DA_tran (
    .sys_clk(sys_clk),
    .tran_clk(div_clk_48),
    .sys_rst_n(sys_rst_n),
    .ad_clk(ad_clk),
    .da_clk(da_clk),
    .adc_data(adc_data),
    .dac_data(dac_data)
);

//ila_0 u_ila_0 (
//    .clk(sys_clk),
//    .probe0(ad_clk),
//    .probe1(da_clk),
//    .probe2(adc_data),
//    .probe3(dac_data)
//);

endmodule
