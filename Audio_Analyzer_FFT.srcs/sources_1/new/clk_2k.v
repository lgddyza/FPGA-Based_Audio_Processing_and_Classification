`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/23 20:54:26
// Design Name: 
// Module Name: clk_2k
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


module clk_2k (
    input  wire        sys_clk,   // 50MHz
    input  wire        rst_n,     // 异步低电平复位
    output reg         clk_2k     // 2kHz，50%占空比
);

reg [13:0] cnt;

always @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt    <= 14'd0;
        clk_2k <= 1'b0;
    end else if (cnt == 14'd12499) begin
        cnt    <= 14'd0;
        clk_2k <= ~clk_2k;
    end else begin
        cnt    <= cnt + 14'd1;
    end
end

endmodule