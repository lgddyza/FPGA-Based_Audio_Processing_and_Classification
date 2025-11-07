`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/23 23:30:56
// Design Name: 
// Module Name: fifo_FFT
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


module FIFO_to_FFT(
        input  wire sys_clk,
        input  wire sys_rst_n,
        input  wire [7:0] adc_data,
        output wire [7:0] dac_data,
        output wire ad_clk,
        output wire da_clk,
        //按键输入、输出
        //input wire wr_en,
        //FIFO的状态指示灯
        //output wire fifo_in_ready
        //输出功率谱
        //output wire  [31:0] power_value,
        //output wire  [11:0] power_index
        output wire voice,
        output wire music,
        output wire busy,
        output wire max,
        output wire [11:0] index
    );



    wire [7:0] fifo_data;
    wire [12:0] rd_data_count;
    wire data_tlast;
    wire [15:0] m_axis_data_tdata;
    wire m_axis_data_tvalid;
    wire [11:0] m_axis_data_tuser;
    wire s_axis_data_tready;
    wire m_axis_data_tlast;
    wire [7:0] real_data;
    wire [7:0] imag_data;
    assign real_data = m_axis_data_tdata[7:0];
    assign imag_data = m_axis_data_tdata[15:8];
    wire  power_valid;

    wire fifo_out_ready;
    wire fifo_in_ready;
    wire fifo_out_valid;
    wire pulse_out;

    ad_fifo  u_ad_fifo (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),

        .adc_data(adc_data),
        .dac_data(dac_data),

        .ad_clk(ad_clk),
        .da_clk(da_clk),
        //以上是ADC——DAC传输线
        //以下是FIFO信号线
        //写时钟——2khz
        .wr_en(1'b0),
        .data_tlast(data_tlast),
        .fifo_data(fifo_data),
        .fifo_in_ready(fifo_in_ready),
        .fifo_out_ready(fifo_out_ready),
        .fifo_out_valid(fifo_out_valid),
        .rd_data_count(rd_data_count),
        .pulse_out(pulse_out)//脉冲输出48k
    );

    wire tlast_unexpected;
    wire tlast_missing;
    wire fft_start;
    wire status_channel_halt;
    wire data_in_channel_halt;
    wire data_out_channel_halt;

    fft_t u_fft_t (   
        .aclk(pulse_out),
        .aresetn(sys_rst_n),
        .adc_data(fifo_data),
        .s_axis_data_tvalid(fifo_out_valid),
        .s_axis_data_tlast(data_tlast),
        .s_axis_data_tready(fifo_out_ready),//输出，准备好的信号
        // AXIS data out
        .m_axis_data_tdata(m_axis_data_tdata),   
        .m_axis_data_tvalid(m_axis_data_tvalid),
        .m_axis_data_tlast(m_axis_data_tlast),
        .m_axis_data_tuser(m_axis_data_tuser),
        .tlast_unexpected(tlast_unexpected),
        .tlast_missing(tlast_missing),
        .fft_start(fft_start),
        .status_channel_halt(status_channel_halt),
        .data_in_channel_halt(data_in_channel_halt),
        .data_out_channel_halt(data_out_channel_halt)
    );

    wire  [31:0] power_value;
    wire  [11:0] power_index;

    multiple_power u_multiple_power (
        .clk(pulse_out),
        .rst_n(sys_rst_n),
        .fft_tdata(m_axis_data_tdata),
        .fft_tuser(m_axis_data_tuser),
        .fft_tvalid(m_axis_data_tvalid),
        .power_value(power_value),
        .power_index(power_index),
        .power_valid(power_valid)
    );

    wire  [11:0]  peak_index;
    wire  [31:0]  peak_power;
    wire          peak_valid;

    peak_find u_peak_find (
        .clk(sys_clk),
        .rst_n(sys_rst_n),
        .index_in(power_index),
        .power_in(power_value),
        .valid_in(power_valid),
        .out_valid(peak_valid),
        .out_power(peak_power),
        .out_index(peak_index),
        .max(max),
        .index(index)
    );


    peak_classify u_peak_classify (
        .clk(sys_clk),
        .rst_n(sys_rst_n),
        .in_valid(peak_valid),
        .in_index(peak_index),
        .voice(voice),
        .music(music),
        .busy(busy)
    );

    ila_2 u_ila_2 (
        .clk(sys_clk),
        .probe0(max),//1位
        .probe1(peak_power),//8位
        .probe2(index),//12位
        .probe3(voice),
        .probe4(music),
        .probe5(busy)
        //.probe3(rd_data_count)//12位
        //.probe4(power_valid)//1位
    );
endmodule
