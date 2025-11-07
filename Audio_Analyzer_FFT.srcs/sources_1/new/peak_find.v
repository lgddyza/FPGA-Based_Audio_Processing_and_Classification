module peak_find #(
    parameter THRESH  = 32'd30,         // 功率阈值（用于即时 out_valid）
    parameter SOUND_THRESHOLD = 32'd42, // 声音阈值：一帧最大功率超过此值认为有声音
    parameter HOLD_FRAMES = 6          // 连续无声帧数，达到此帧数才判定为无声
)(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        valid_in,       // 输入数据有效
    input  wire [11:0] index_in,       // 当前点索引（递增）
    input  wire [31:0] power_in,       // 当前功率值

    output reg         out_valid,      // 阈值即时输出：有效
    output reg [11:0]  out_index,      // 阈值即时输出：索引
    output reg [31:0]  out_power,      // 阈值即时输出：功率

    // 输出：最近两帧的最大功率索引（取两帧中的最大）
    output reg         max,            // 有声音（带滞回机制）
    output reg [11:0]  index           // 最近两帧内最大功率的索引
);

    // ===== 当前帧最大值跟踪 =====
    reg [31:0] cur_max_power;
    reg [11:0] cur_max_index;

    // ===== 最近两帧峰值缓存 =====
    reg [31:0] frame_power [0:1];  // 保存最近2帧的最大功率
    reg [11:0] frame_index [0:1];  // 保存最近2帧的峰值索引
    reg        frame_has_voice [0:1]; // 每帧是否有声音

    reg        frame_ptr;          // 写指针：0/1
    reg [11:0] prev_index;

    // ===== 音频判断保持逻辑 =====
    reg [HOLD_FRAMES-1:0] silence_cnt; // 连续无声帧计数器（长度为 HOLD_FRAMES）

    wire in_range = (index_in < 12'd2048) && (index_in > 12'd5);

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid      <= 1'b0;
            out_index      <= 12'd0;
            out_power      <= 32'd0;

            max            <= 1'b0;
            index          <= 12'd0;

            cur_max_power  <= 32'd0;
            cur_max_index  <= 12'd0;

            frame_ptr      <= 1'b0;
            silence_cnt    <= {HOLD_FRAMES{1'b0}}; // 全部置零

            for (i = 0; i < 2; i = i + 1) begin
                frame_power[i] <= 32'd0;
                frame_index[i] <= 12'd0;
                frame_has_voice[i] <= 1'b0;
            end

            prev_index <= 12'd0;

        end else begin
            out_valid <= 1'b0;

            // 即时阈值输出
            if (valid_in) begin
                if (power_in > THRESH && in_range) begin
                    out_valid <= 1'b1;
                    out_index <= index_in;
                    out_power <= power_in;
                end
            end

            if (valid_in) begin
                if (index_in < prev_index) begin
                    // —— 一帧结束，更新帧级统计 ——
                    frame_power[frame_ptr]     <= cur_max_power;
                    frame_index[frame_ptr]     <= cur_max_index;
                    frame_has_voice[frame_ptr] <= (cur_max_power > SOUND_THRESHOLD);

                    // —— 最近两帧取最大值输出 ——
                    if (frame_power[0] >= frame_power[1]) begin
                        index <= frame_index[0];
                    end else begin
                        index <= frame_index[1];
                    end

                    // —— 声音检测滞回逻辑 ——
                    if (frame_has_voice[0] || frame_has_voice[1]) begin
                        // 只要最近两帧中有一帧有声音，就认为仍然有声
                        max <= 1'b1;
                        silence_cnt <= {HOLD_FRAMES{1'b0}}; // 重置计数器
                    end else begin
                        // 连续无声帧计数
                        silence_cnt <= {silence_cnt[HOLD_FRAMES-2:0], 1'b1}; // 右移并加1（无声）
                        if (silence_cnt == {HOLD_FRAMES{1'b1}}) begin
                            max <= 1'b0; // 连续10帧无声才判为无声
                        end
                    end

                    // 翻转帧指针
                    frame_ptr <= ~frame_ptr;

                    // 初始化下一帧最大值
                    if (in_range) begin
                        cur_max_power <= power_in;
                        cur_max_index <= index_in;
                    end else begin
                        cur_max_power <= 32'd0;
                        cur_max_index <= 12'd0;
                    end
                end else begin
                    // 同帧内更新最大值
                    if (in_range && power_in > cur_max_power) begin
                        cur_max_power <= power_in;
                        cur_max_index <= index_in;
                    end
                end
                prev_index <= index_in;
            end
        end
    end

endmodule
