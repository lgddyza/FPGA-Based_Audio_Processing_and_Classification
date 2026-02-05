`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/22 21:45:31
// Design Name: 
// Module Name: fft_t
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

module fft_t(
    input    wire          aclk,
    input    wire          aresetn,

    input    wire   [7:0]  adc_data,
    input    wire          s_axis_data_tvalid,
    input    wire          s_axis_data_tlast,
    output   wire          s_axis_data_tready,
    // AXIS data out
    output   wire  [15:0]  m_axis_data_tdata,   
    output   wire          m_axis_data_tvalid,
    output   wire          m_axis_data_tlast,
    output   wire  [11:0]  m_axis_data_tuser,    // 宽度依 IP 设置；12
    output   wire          tlast_unexpected,
    output   wire          tlast_missing,
    output   wire          fft_start,
    output   wire          status_channel_halt,
    output   wire          data_in_channel_halt,
    output   wire          data_out_channel_halt
);

  // 固定配置
  wire [15:0] s_axis_config_tdata =  1'b1;
  wire        s_axis_config_tvalid = 1'b1;
  wire        s_axis_config_tready;

  // 拼接输入复数数据（Im=0, Re=adc_data）
  wire [15:0] s_axis_data_tdata = {8'd0, adc_data-8'd128};

//配置FFT变换核
xfft_0 fft_inst (
  .aclk(aclk),
  .aresetn(aresetn),
  //配置
  .s_axis_config_tdata(s_axis_config_tdata),
  .s_axis_config_tvalid(s_axis_config_tvalid),
  .s_axis_config_tready(s_axis_config_tready),
  //数据输入input
  .s_axis_data_tdata(s_axis_data_tdata),
  //输入数据有效信号 信号input
  .s_axis_data_tvalid(s_axis_data_tvalid),
  //可以接受外来信号 信号output
  .s_axis_data_tready(s_axis_data_tready),
  //输入数据最后一个信号 信号input
  .s_axis_data_tlast(s_axis_data_tlast),
  //输出数据（0-7Re，8-15Im）
  .m_axis_data_tdata(m_axis_data_tdata),
  //输出数据索引 信号output（0-4096）
  .m_axis_data_tuser(m_axis_data_tuser),
  //输出数据有效信号 信号output
  .m_axis_data_tvalid(m_axis_data_tvalid),
  //从机可以接受信号 信号input
  .m_axis_data_tready(1'b1),
  //输出数据最后一个信号 信号output
  .m_axis_data_tlast(m_axis_data_tlast),
  //状态有效信号
  .m_axis_status_tready(1'b1),
  //其他事件信号
  .event_frame_started(fft_start),
  .event_tlast_unexpected(tlast_unexpected),
  .event_tlast_missing(tlast_missing),
  .event_status_channel_halt(status_channel_halt),
  .event_data_in_channel_halt(data_in_channel_halt),
  .event_data_out_channel_halt(data_out_channel_halt)
);

endmodule



