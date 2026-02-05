module fft_filter #(
    parameter DEPTH = 16,       // 平均 16 帧
    parameter POINTS = 4096     // 每帧功率点个数
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [11:0] index_in,   // 0~4095
    input  wire [31:0] power_in,
    input  wire        valid_in,   // 每个功率点有效
    output reg  [11:0] index_out,
    output reg  [31:0] power_out,
    output reg         valid_out
);

    // === 基本寄存器 ===
    reg [31:0] acc [0:POINTS-1];  // 累加寄存器（保存16帧和）
    reg [3:0]  frame_cnt;         // 帧计数器
    integer i;

    // 初始化
    initial begin
        for (i = 0; i < POINTS; i = i + 1)
            acc[i] = 32'd0;
        frame_cnt = 0;
    end

    // 滑动累加平均（每16帧）
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            frame_cnt <= 0;
            valid_out <= 0;
        end else if(valid_in) begin
            // 累加功率
            acc[index_in] <= acc[index_in] + power_in;

            // 当最后一个点（4095）时，更新帧计数
            if(index_in == POINTS-1) begin
                frame_cnt <= frame_cnt + 1'b1;
            end

            // 输出滤波结果（在第16帧时输出平均值）
            if(frame_cnt == (DEPTH - 1)) begin
                power_out <= acc[index_in] / DEPTH;
                index_out <= index_in;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end

            // 当16帧结束，清空累加器，重新开始下一轮
            if(index_in == POINTS-1 && frame_cnt == (DEPTH - 1)) begin
                for (i = 0; i < POINTS; i = i + 1)
                    acc[i] <= 32'd0;
                frame_cnt <= 0;
            end
        end
    end

endmodule
