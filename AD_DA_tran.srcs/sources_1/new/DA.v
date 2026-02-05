`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/23 17:22:13
// Design Name: 
// Module Name: DA
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


module DA(
    input wire  sys_clk,
    input wire  da_clk,
    input wire  sys_rst_n,
    input wire  [7:0] adc_data_sync,
    output reg  [7:0] dac_data
    );

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if(!sys_rst_n)
            dac_data <= 8'd0;
        else if(da_clk)
            dac_data <= adc_data_sync;
        else
            dac_data <= dac_data;
    end
endmodule
