`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/22 18:35:25
// Design Name: 
// Module Name: AD_DA_tran
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


module AD_DA_tran(
    input  wire        sys_clk,
    input  wire        tran_clk,    //48kHz输入时钟
    input  wire        sys_rst_n,
    input  wire [7:0]  adc_data,   // ADC 输入数据
    output wire [7:0]  dac_data,   // DAC 输出数据

    output wire        ad_clk,      //AD频率控制
    output wire        da_clk       //DA频率控制
    );

    //时钟分配
    assign ad_clk = tran_clk;
    //assign da_clk = tran_clk;//相差180相位

    assign da_clk = ~tran_clk;//相差180相位

    wire  [7:0] adc_data_sync;

    AD u_AD (
        .sys_clk(sys_clk),
        .ad_clk(ad_clk),
        .sys_rst_n(sys_rst_n),
        .adc_data(adc_data),
        .adc_data_sync(adc_data_sync)
    );

    DA u_DA (
        .sys_clk(sys_clk),
        .da_clk(da_clk),
        .adc_data_sync(adc_data_sync),
        .sys_rst_n(sys_rst_n),
        .dac_data(dac_data)
    );

endmodule
