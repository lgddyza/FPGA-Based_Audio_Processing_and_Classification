module peak_classify #(
    parameter HIGH_PEAK_THRESH = 12'd60  // 高频峰值阈值
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        max,        // 指示信号，当max为0的时候，重置
    
    input  wire        in_valid,   // 峰值输入有效信号
    input  wire [11:0] in_index,   // 峰值索引

    output reg         voice,      // 语音特征明显
    output reg         music,      // 音乐特征明显
    output reg         busy        // 收集中=1；已判定保持=0
);

    // 简化：每次有效输入立即判断
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            voice <= 1'b0;
            music <= 1'b0;
            busy  <= 1'b0;
        end else if (max == 1'b0) begin
            // max=0时重置
            voice <= 1'b0;
            music <= 1'b0;
            busy  <= 1'b0;
        end else if (in_valid) begin
            // 有输入时立即判断
            if (in_index > HIGH_PEAK_THRESH) begin
                music <= 1'b1;
                voice <= 1'b0;
            end else begin
                music <= 1'b0;
                voice <= 1'b1;
            end
            busy <= 1'b0;  // 判断完成
        end
    end

endmodule