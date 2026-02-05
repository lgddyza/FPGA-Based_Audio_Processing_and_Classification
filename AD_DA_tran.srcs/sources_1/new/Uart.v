`timescale 1ns / 1ps

module Uart (
    input  wire       sys_clk,     // 50MHz 系统时钟
    input  wire       rst_n,       // 低电平有效的全局复位
    input  wire       uart_rxd,    // UART 接收数据线
    output wire       uart_txd     // UART 发送数据线
);

// 参数定义
parameter CLK_FREQ = 50_000_000;  // 系统时钟频率 50MHz
parameter UART_BPS = 115200;       // 串口波特率

// 内部连线定义
wire [7:0] rx_data;              // 接收模块输出的8位数据
wire       rx_done;              // 接收完成标志，高电平有效
wire       tx_idle;              // 发送模块空闲标志，高电平有效

// 实例化接收模块
Uart_rx #(
    .CLK_FREQ (CLK_FREQ),
    .UART_BPS (UART_BPS)
) u_Uart_rx (
    .clk      (sys_clk),
    .rst_n    (rst_n),
    .uart_rxd (uart_rxd),
    .rx_data  (rx_data),
    .rx_done  (rx_done)
);

// 实例化发送模块
Uart_tx #(
    .CLK_FREQ (CLK_FREQ),
    .UART_BPS (UART_BPS)
) u_Uart_tx (
    .clk      (sys_clk),
    .rst_n    (rst_n),
    .tx_data  (rx_data),  // 将接收到的数据直接作为发送数据
    .tx_en    (rx_done),  // 当接收完成时，触发发送使能
    .uart_txd (uart_txd),
    .tx_idle  (tx_idle)
);

endmodule
