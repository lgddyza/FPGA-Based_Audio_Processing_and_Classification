`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/21 19:55:46
// Design Name: 
// Module Name: multiple
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


module multiple_power (
    input wire clk,
    input wire rst_n,
    
    // FFT结果输入接口 (与你的位宽匹配)
    input wire [15:0] fft_tdata,  // [15:8]: 虚部(imag), [7:0]: 实部(real)
    input wire [11:0] fft_tuser,  // XK_INDEX，频率点索引
    input wire fft_tvalid,        // 输入数据有效信号
    
    // 功率谱输出接口
    output reg [31:0] power_value, // 计算出的功率值 (real^2 + imag^2)
    output reg [11:0] power_index, // 对应的频率索引
    output reg power_valid         // 功率值有效信号
);

    // 定义输入数据的实部和虚部
    wire signed [7:0] fft_real; // 有符号数
    wire signed [7:0] fft_imag; // 有符号数
    
    assign fft_real = fft_tdata[7:0];   // 低8位为实部
    assign fft_imag = fft_tdata[15:8];  // 高8位为虚部

    // 中间信号：计算实部和虚部的平方
    wire [15:0] real_squared;
    wire [15:0] imag_squared;

    assign real_squared = fft_real * fft_real;
    assign imag_squared = fft_imag * fft_imag;

    // 核心计算逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            power_value <= 32'd0;
            power_index <= 12'd0;
            power_valid <= 1'b0;
        end else begin
            // 当FFT输入数据有效时，进行计算
            if (fft_tvalid) begin
                // 功率谱 = 实部的平方 + 虚部的平方
                power_value <= real_squared + imag_squared;
                // 将当前频率索引传递下去
                power_index <= fft_tuser;
                // 生成一级流水线的有效信号
                power_valid <= 1'b1;
            end else begin
                power_valid <= 1'b0;
                power_index <= 12'd0;
            end
        end
    end

endmodule
