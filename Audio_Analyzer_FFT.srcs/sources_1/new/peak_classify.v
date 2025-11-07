module peak_classify #(
    parameter NUM_PEAKS    = 8,   // 收集峰的数量
    parameter THRESH_DIFF  = 3     // 两边数量差阈值
)(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        in_valid,   // 峰值输入有效信号
    input  wire [11:0] in_index,   // 峰值索引

    output reg         voice,      // 语音特征明显（保持到下一次判定）
    output reg         music,      // 音乐特征明显（保持到下一次判定）
    output reg         busy        // 收集中=1；已判定保持=0
);

    // === 上升沿检测 ===
    reg  in_valid_d;
    wire valid_rise;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) in_valid_d <= 1'b0;
        else        in_valid_d <= in_valid;
    end
    assign valid_rise = (in_valid & ~in_valid_d);

    // === 计数器 ===
    reg [5:0] total_cnt;   // 已接收峰数量
    reg [5:0] cnt_low;     // index < 70
    reg [5:0] cnt_high;    // index > 70

    // === NEW: 最大峰索引 ===
    reg  [11:0] max_idx;   // 本轮收集到的最大峰索引

    // 预计算“下一拍”的计数（把当前峰也算进去）
    wire is_low  = (in_index < 12'd90);
    wire is_high = (in_index > 12'd90);

    wire [5:0]  total_next  = total_cnt + (valid_rise ? 6'd1 : 6'd0);
    wire [5:0]  low_next    = cnt_low  + ((valid_rise && is_low ) ? 6'd1 : 6'd0);
    wire [5:0]  high_next   = cnt_high + ((valid_rise && is_high) ? 6'd1 : 6'd0);
    wire [5:0]  diff_next   = (low_next > high_next) ? (low_next - high_next)
                                                     : (high_next - low_next);

    // NEW: 含当前峰后的最大索引
    wire [11:0] max_idx_next = (valid_rise && (in_index > max_idx)) ? in_index : max_idx;

    // === 状态机 ===
    localparam S_COLLECT = 1'b0;
    localparam S_HOLD    = 1'b1;
    reg state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_COLLECT;
            busy      <= 1'b1;
            total_cnt <= 6'd0;
            cnt_low   <= 6'd0;
            cnt_high  <= 6'd0;
            voice     <= 1'b0;
            music     <= 1'b0;
            max_idx   <= 12'd0;           // NEW
        end else begin
            case (state)
                // -------- 收集与判定 --------
                S_COLLECT: begin
                    busy <= 1'b1;

                    // 计数递增
                    if (valid_rise) begin
                        total_cnt <= total_next;
                        cnt_low   <= low_next;
                        cnt_high  <= high_next;
                        max_idx   <= max_idx_next;    // NEW: 记录最大峰索引
                    end

                    // 达到数量 -> 先检查最大索引快速通道，再走原来差值判定
                    if ((total_next >= NUM_PEAKS) && valid_rise) begin
                        if (max_idx_next > 12'd100) begin       // NEW: 最高优先级
                            voice <= 1'b0;
                            music <= 1'b1;
                            // 清计数，转入保持
                            total_cnt <= 6'd0;
                            cnt_low   <= 6'd0;
                            cnt_high  <= 6'd0;
                            max_idx   <= 12'd0;                 // NEW: 清零
                            state     <= S_HOLD;
                            busy      <= 1'b0;
                        end else if (diff_next > THRESH_DIFF) begin
                            if (low_next > high_next) begin
                                voice <= 1'b1;
                                music <= 1'b0;
                            end else begin
                                voice <= 1'b0;
                                music <= 1'b1;
                            end
                            // 清计数，转入保持
                            total_cnt <= 6'd0;
                            cnt_low   <= 6'd0;
                            cnt_high  <= 6'd0;
                            max_idx   <= 12'd0;                 // NEW: 清零
                            state     <= S_HOLD;
                            busy      <= 1'b0;
                        end
                    end
                end

                // -------- 保持输出，直到下一次开始收集 --------
                S_HOLD: begin
                    busy <= 1'b0;
                    // 输出 voice/music 在 HOLD 期间不变

                    // 看到下一次峰，代表新一轮开始
                    if (valid_rise) begin
                        state   <= S_COLLECT;
                        busy    <= 1'b1;
                        // 计数在下一拍按 valid_rise 正常累加
                        // max_idx 已在进入 HOLD 时清零
                    end
                end
            endcase
        end
    end
endmodule
