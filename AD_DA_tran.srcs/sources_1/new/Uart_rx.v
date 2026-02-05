`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/03 19:09:37
// Design Name: 
// Module Name: Uart_rx
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

module Uart_rx #(
    parameter CLK_FREQ = 50_000_000,
    parameter UART_BPS = 115200
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rxd,
    output reg  [7:0] rx_data,
    output reg        rx_done
);

    // 计算一个波特周期需要的时钟数
    localparam BPS_CNT_MAX = CLK_FREQ / UART_BPS;
    localparam BPS_CNT_HALF = BPS_CNT_MAX / 2;

    reg [15:0] bps_cnt;      // 波特率计数器
    reg [3:0]  bit_cnt;      // 已接收比特数计数器 (0-8)
    reg        rx_flag;      // 接收过程标志
    reg        uart_rxd_d0;  // 对输入信号打一拍，消除亚稳态
    reg        uart_rxd_d1;  // 再打一拍，用于边沿检测
    reg [7:0]  rx_data_reg;  // 接收数据移位寄存器

    // 输入信号同步与边沿检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_rxd_d0 <= 1'b1;
            uart_rxd_d1 <= 1'b1;
        end else begin
            uart_rxd_d0 <= uart_rxd;
            uart_rxd_d1 <= uart_rxd_d0;
        end
    end

    // 检测起始位（下降沿）
    wire start_bit_detected = (uart_rxd_d1 && !uart_rxd_d0);

    // 控制接收过程
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_flag <= 1'b0;
        end else begin
            if (start_bit_detected && !rx_flag) begin
                rx_flag <= 1'b1;  // 检测到起始位，开始接收
            end else if (bit_cnt == 4'd8 && bps_cnt == BPS_CNT_MAX) begin
                rx_flag <= 1'b0;  // 8位数据接收完成，结束接收过程
            end
        end
    end

    // 波特率计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bps_cnt <= 16'd0;
        end else if (rx_flag) begin
            if (bps_cnt < BPS_CNT_MAX - 1) begin
                bps_cnt <= bps_cnt + 1'b1;
            end else begin
                bps_cnt <= 16'd0;
            end
        end else begin
            bps_cnt <= 16'd0;
        end
    end

    // 比特计数器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt <= 4'd0;
        end else if (rx_flag) begin
            if (bps_cnt == BPS_CNT_MAX) begin
                bit_cnt <= bit_cnt + 1'b1;
            end
        end else begin
            bit_cnt <= 4'd0;
        end
    end

    // 在数据位中间点采样，并将数据移入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data_reg <= 8'd0;
        end else if (rx_flag && (bps_cnt == BPS_CNT_HALF)) begin
            case (bit_cnt)
                4'd1: rx_data_reg[0] <= uart_rxd_d1;
                4'd2: rx_data_reg[1] <= uart_rxd_d1;
                4'd3: rx_data_reg[2] <= uart_rxd_d1;
                4'd4: rx_data_reg[3] <= uart_rxd_d1;
                4'd5: rx_data_reg[4] <= uart_rxd_d1;
                4'd6: rx_data_reg[5] <= uart_rxd_d1;
                4'd7: rx_data_reg[6] <= uart_rxd_d1;
                4'd8: rx_data_reg[7] <= uart_rxd_d1;
                default: ;
            endcase
        end
    end

    // 产生接收完成信号，并输出数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_done <= 1'b0;
            rx_data <= 8'd0;
        end else if (bit_cnt == 4'd8 && bps_cnt == BPS_CNT_MAX) begin
            rx_done <= 1'b1;        // 产生一个时钟周期的高脉冲
            rx_data <= rx_data_reg; // 锁存数据
        end else begin
            rx_done <= 1'b0;
        end
    end

endmodule