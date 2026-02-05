`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/23 14:32:05
// Design Name: 
// Module Name: ad_fifo
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


module ad_fifo(
    input  wire        sys_clk,
    input  wire        sys_rst_n,

    input  wire [7:0]  adc_data,
    output wire [7:0]  dac_data,

    output wire        ad_clk,
    output wire        da_clk,
    //以上是ADC——DAC传输线
    //以下是FIFO信号线
    //写时钟——2khz
    input  wire        wr_en,//fifo_in_valid
    output wire        data_tlast,
    output wire [7:0]  fifo_data,
    output wire  [12:0] rd_data_count,
    output wire        fifo_in_ready,
    input  wire        fifo_out_ready,
    output wire        fifo_out_valid,
    output wire        pulse_out
    );

    //wire [12:0] rd_data_count;

    clk_2k u_clk_2k(
        .sys_clk(sys_clk),
        .rst_n(sys_rst_n),
        .clk_2k(wr_clk)
    );

    AD_DA_t u_ad_da_t(
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),

        .adc_data(adc_data),
        .dac_data(dac_data),

        .ad_clk(ad_clk),
        .da_clk(da_clk),
        .pulse_out(pulse_out)
    );

    fft_fifo u_fft_fifo(
        .rst_n(sys_rst_n),
        //读写时钟,48khz
        .clk_48(ad_clk),
        //输入数据
        .adc_data(dac_data),
        //读写使能端有效,按键使能
        .s_axis_tvalid(~wr_en),
        .s_axis_tready(fifo_in_ready),//给个小灯，表示可以写fifo
        //输出数据
        .m_axis_tdata(fifo_data),
        .axis_data_count(rd_data_count),
        .data_tlast(data_tlast),
        .m_axis_tready(fifo_out_ready),//输入信号，代表下级可用
        .m_axis_tvalid(fifo_out_valid)

    );

    //ila_1 u_ila_1 (
    //    .clk(sys_clk),
    //    .probe0(ad_clk),
    //    .probe1(data_tlast),
    //    .probe2(fifo_data),
    //    .probe3(rd_data_count),
    //    .probe4(dac_data)
    //);

endmodule
