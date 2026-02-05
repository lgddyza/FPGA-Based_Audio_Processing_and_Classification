`timescale 1ns / 1ps



module Uart_tx #(
    parameter CLK_FREQ = 50_000_000,
    parameter UART_BPS = 115200
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] tx_data,
    input  wire       tx_en,
    output reg        uart_txd,
    output reg        tx_idle
);

    // 计算一个波特周期需要的时钟数
    localparam BPS_CNT_MAX = CLK_FREQ / UART_BPS;

    reg [15:0] bps_cnt;      // 波特率计数器
    reg [3:0]  bit_cnt;      // 已发送比特数计数器 (0-10, 包含起始和停止位)
    reg [7:0]  tx_data_reg;  // 发送数据寄存器

    // 状态机简化：空闲态或发送态
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_idle <= 1'b1;
            uart_txd <= 1'b1; // 空闲时TX为高电平
            bps_cnt <= 16'd0;
            bit_cnt <= 4'd0;
            tx_data_reg <= 8'd0;
        end else begin
            if (tx_idle) begin
                uart_txd <= 1'b1;
                if (tx_en) begin // 收到发送使能信号
                    tx_idle <= 1'b0;
                    tx_data_reg <= tx_data; // 锁存待发送数据
                    bit_cnt <= 4'd0;
                    bps_cnt <= 16'd0;
                end
            end else begin
                // 发送状态
                if (bps_cnt < BPS_CNT_MAX - 1) begin
                    bps_cnt <= bps_cnt + 1'b1;
                end else begin
                    bps_cnt <= 16'd0;
                    bit_cnt <= bit_cnt + 1'b1;

                    case (bit_cnt)
                        4'd0:  uart_txd <= 1'b0;         // 起始位
                        4'd1:  uart_txd <= tx_data_reg[0]; // 发送 bit0 (LSB)
                        4'd2:  uart_txd <= tx_data_reg[1];
                        4'd3:  uart_txd <= tx_data_reg[2];
                        4'd4:  uart_txd <= tx_data_reg[3];
                        4'd5:  uart_txd <= tx_data_reg[4];
                        4'd6:  uart_txd <= tx_data_reg[5];
                        4'd7:  uart_txd <= tx_data_reg[6];
                        4'd8:  uart_txd <= tx_data_reg[7]; // 发送 bit7 (MSB)
                        4'd9:  uart_txd <= 1'b1;         // 停止位
                        4'd10: begin                     // 发送结束，回到空闲
                            tx_idle <= 1'b1;
                            uart_txd <= 1'b1;
                        end
                        default: uart_txd <= 1'b1;
                    endcase
                end
            end
        end
    end

endmodule