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


module AD(
    input wire sys_clk,
    input wire ad_clk,
    input wire sys_rst_n,
    input wire [7:0] adc_data,
    output reg [7:0] adc_data_sync
    );

    //ADC采集
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if(!sys_rst_n)
            adc_data_sync <= 8'd0;
        else if(ad_clk)
            adc_data_sync <= adc_data;
        else
            adc_data_sync <= adc_data_sync;
    end
endmodule
