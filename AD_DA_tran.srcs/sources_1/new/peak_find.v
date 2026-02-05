module peak_find #(
    parameter THRESH  = 32'd1700,         // 功率阈值（用于即时 out_valid）
    parameter SOUND_THRESHOLD = 32'd2000, // 声音阈值：一帧最大功率超过此值认为有声音
    parameter HOLD_FRAMES = 3           // 连续无声帧数，达到此帧数才判定为无声
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        switch_pulse,   // 状态切换脉冲，上升沿有效

    input  wire        valid_in,        // 输入数据有效
    input  wire [11:0] index_in,        // 当前点索引（递增）
    input  wire [31:0] power_in,        // 当前功率值

    output reg         out_valid,       // 阈值即时输出：有效
    output reg [11:0]  out_index,       // 阈值即时输出：索引
    output reg [31:0]  out_power,       // 阈值即时输出：功率

    // 输出：最近两帧的最大功率索引（取两帧中的最大）
    output reg         max,             // 有声音（带滞回机制）
    output reg [11:0]  index,           // 最近两帧内最大功率的索引
    output reg [7:0]   third_harmonic,  // 新增：三次谐波大小（8位，0-255）
    output reg [7:0]   second_harmonic, // 新增：二次谐波大小（8位，0-255）
    
    output reg         range_mode       // 新增：当前范围模式指示 0:窄范围 1:宽范围
);

    // ===== 当前帧最大值跟踪 =====
    reg [31:0] cur_max_power;
    reg [11:0] cur_max_index;
    
    // 新增：基波搜索相关
    reg [11:0] fundamental_idx_reg;     // 基波索引寄存器
    reg [31:0] fundamental_pwr_reg;     // 基波功率寄存器
    reg        fundamental_found;       // 基波找到标志

    // ===== 最近两帧峰值缓存 =====
    reg [31:0] frame_power [0:1];  // 保存最近2帧的最大功率
    reg [11:0] frame_index [0:1];  // 保存最近2帧的峰值索引
    reg        frame_has_voice [0:1]; // 每帧是否有声音

    reg        frame_ptr;          // 写指针：0/1
    reg [11:0] prev_index;
    
    // ===== 新增：即时声音检测 =====
    reg        instant_voice_detected;  // 当前帧内是否检测到即时声音

    // ===== 音频判断保持逻辑 =====
    reg [HOLD_FRAMES-1:0] silence_cnt; // 连续无声帧计数器（长度为 HOLD_FRAMES）
    reg [HOLD_FRAMES-1:0] silence_cnt_d; // 延迟版本，用于max逻辑
    
    // 新增：用于max判断的信号
    reg        frame_has_voice_0_d, frame_has_voice_1_d; // 延迟的帧声音标志
    reg        instant_voice_detected_d; // 延迟的即时声音检测
    reg        frame_end_pulse; // 帧结束脉冲
    reg        frame_end_pulse_d1; // 帧结束脉冲延迟1拍
    
    // 新增：状态切换逻辑
    reg        range_mode_reg;  // 内部范围模式寄存器
    wire       in_range;        // 范围判断信号
    reg        switch_pulse_d1, switch_pulse_d2; // 脉冲同步和边沿检测

    // ===== 新增：谐波相关信号 =====
    reg [11:0] last_fundamental_idx;   // 上一帧的基波索引
    reg [31:0] last_fundamental_pwr;   // 上一帧的基波功率
    reg        last_fundamental_valid; // 上一帧基波信息有效
    
    reg [11:0] target_second_harmonic_idx;  // 二次谐波目标索引
    reg [11:0] target_third_harmonic_idx;   // 三次谐波目标索引
    reg        search_harmonics;            // 谐波搜索使能
    reg        search_second;               // 搜索二次谐波标志
    reg        search_third;                // 搜索三次谐波标志
    
    // 分别跟踪二次和三次谐波的最大功率
    reg [31:0] cur_second_harmonic_power;  // 当前帧二次谐波功率
    reg [31:0] cur_third_harmonic_power;   // 当前帧三次谐波功率
    
    // 新增：输出保持相关信号
    reg [7:0]  second_harmonic_hold;  // 二次谐波保持值
    reg [7:0]  third_harmonic_hold;   // 三次谐波保持值
    reg [31:0] out_power_hold;        // 基波功率保持值
    reg        out_power_hold_valid;  // 基波功率保持有效标志
    reg        second_harmonic_hold_valid; // 二次谐波保持有效标志
    reg        third_harmonic_hold_valid;  // 三次谐波保持有效标志
    
    // 新增：缩放相关参数
    reg [31:0] second_harmonic_scaled;  // 二次谐波缩放后值
    reg [31:0] third_harmonic_scaled;   // 三次谐波缩放后值
    wire [31:0] second_ratio;           // 二次谐波缩放比例
    wire [31:0] third_ratio;            // 三次谐波缩放比例
    
    // 功率参考值，用于缩放
    parameter POWER_REF = 32'd4000;     // 参考功率值，超过此值就输出255
    
    integer i;
    
    // 根据range_mode_reg选择范围
    assign in_range = (range_mode_reg == 1'b0) ?  // 窄范围模式
                     ((index_in < 12'd100) && (index_in > 12'd5)) :  // 窄范围：5-99
                     ((index_in < 12'd430) && (index_in > 12'd5));  // 宽范围：5-1200

    // 功率缩放计算：将32位功率值缩放到0-255
    // 公式：scaled_value = (power * 255) / POWER_REF
    // 使用乘法实现
    wire [31:0] second_power_scaled = (cur_second_harmonic_power * 32'd255) / POWER_REF;
    wire [31:0] third_power_scaled = (cur_third_harmonic_power * 32'd255) / POWER_REF;
    
    // 限幅到0-255
    wire [7:0] second_clamped = (|second_power_scaled[31:8]) ? 8'd255 : second_power_scaled[7:0];
    wire [7:0] third_clamped = (|third_power_scaled[31:8]) ? 8'd255 : third_power_scaled[7:0];

    // switch脉冲边沿检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            switch_pulse_d1 <= 1'b0;
            switch_pulse_d2 <= 1'b0;
        end else begin
            switch_pulse_d1 <= switch_pulse;
            switch_pulse_d2 <= switch_pulse_d1;
        end
    end
    
    wire switch_rising_edge = switch_pulse_d1 && !switch_pulse_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid              <= 1'b0;
            out_index              <= 12'd0;
            out_power              <= 32'd0;

            index                  <= 12'd0;
            third_harmonic         <= 8'd0;  // 新增
            second_harmonic        <= 8'd0;  // 新增
            range_mode             <= 1'b0;  // 默认为窄范围模式
            range_mode_reg         <= 1'b0;  // 默认为窄范围模式

            cur_max_power          <= 32'd0;
            cur_max_index          <= 12'd0;
            
            fundamental_idx_reg    <= 12'd0;
            fundamental_pwr_reg    <= 32'd0;
            fundamental_found      <= 1'b0;

            frame_ptr              <= 1'b0;
            silence_cnt            <= {HOLD_FRAMES{1'b0}}; // 全部置零
            instant_voice_detected <= 1'b0;  // 新增
            
            frame_end_pulse        <= 1'b0;
            frame_end_pulse_d1     <= 1'b0;
            instant_voice_detected_d <= 1'b0;
            frame_has_voice_0_d    <= 1'b0;
            frame_has_voice_1_d    <= 1'b0;
            silence_cnt_d          <= {HOLD_FRAMES{1'b0}};
            
            // 新增：谐波相关初始化
            last_fundamental_idx   <= 12'd0;
            last_fundamental_pwr   <= 32'd0;
            last_fundamental_valid <= 1'b0;
            target_second_harmonic_idx <= 12'd0;
            target_third_harmonic_idx <= 12'd0;
            search_harmonics       <= 1'b0;
            search_second          <= 1'b0;
            search_third           <= 1'b0;
            cur_second_harmonic_power <= 32'd0;
            cur_third_harmonic_power <= 32'd0;
            
            // 新增：输出保持相关初始化
            second_harmonic_hold   <= 8'd0;
            third_harmonic_hold    <= 8'd0;
            out_power_hold         <= 32'd0;
            out_power_hold_valid   <= 1'b0;
            second_harmonic_hold_valid <= 1'b0;
            third_harmonic_hold_valid <= 1'b0;
            
            // 新增：缩放相关初始化
            second_harmonic_scaled <= 32'd0;
            third_harmonic_scaled  <= 32'd0;

            for (i = 0; i < 2; i = i + 1) begin
                frame_power[i] <= 32'd0;
                frame_index[i] <= 12'd0;
                frame_has_voice[i] <= 1'b0;
            end

            prev_index <= 12'd0;

        end else begin
            out_valid <= 1'b0;
            frame_end_pulse <= 1'b0;
            instant_voice_detected_d <= instant_voice_detected;
            frame_has_voice_0_d <= frame_has_voice[0];
            frame_has_voice_1_d <= frame_has_voice[1];
            silence_cnt_d <= silence_cnt;
            frame_end_pulse_d1 <= frame_end_pulse;
            
            // 处理状态切换
            if (switch_rising_edge) begin
                range_mode_reg <= ~range_mode_reg;  // 切换范围模式
                range_mode <= range_mode_reg;       // 输出当前模式
            end
            
            if (valid_in) begin
                // 帧开始检测
                if (index_in < prev_index) begin
                    // 帧结束，处理搜索逻辑
                    if (search_harmonics) begin
                        if (search_second) begin
                            // 二次谐波搜索完成
                            search_second <= 1'b0;
                            
                            // 保存二次谐波结果（使用缩放后的值）
                            if (cur_second_harmonic_power > 32'd5) begin
                                // 使用缩放计算
                                second_harmonic_scaled <= (cur_second_harmonic_power * 32'd255) / POWER_REF;
                                
                                // 限幅到0-255
                                if (second_harmonic_scaled > 32'd255) begin
                                    second_harmonic_hold <= 8'd255;
                                end else begin
                                    second_harmonic_hold <= second_harmonic_scaled[7:0];
                                end
                                second_harmonic_hold_valid <= 1'b1;
                            end else begin
                                second_harmonic_hold_valid <= 1'b0;
                            end
                            
                            // 开始搜索三次谐波
                            search_third <= 1'b1;
                            cur_third_harmonic_power <= 32'd0;
                        end 
                        else if (search_third) begin
                            // 三次谐波搜索完成
                            search_third <= 1'b0;
                            search_harmonics <= 1'b0;
                            
                            // 保存基波信息
                            last_fundamental_idx <= fundamental_idx_reg;
                            last_fundamental_pwr <= fundamental_pwr_reg;
                            last_fundamental_valid <= fundamental_found;
                            
                            // 保存三次谐波结果（使用缩放后的值）
                            if (cur_third_harmonic_power > 32'd5) begin
                                // 使用缩放计算
                                third_harmonic_scaled <= (cur_third_harmonic_power * 32'd255) / POWER_REF;
                                
                                // 限幅到0-255
                                if (third_harmonic_scaled > 32'd255) begin
                                    third_harmonic_hold <= 8'd255;
                                end else begin
                                    third_harmonic_hold <= third_harmonic_scaled[7:0];
                                end
                                third_harmonic_hold_valid <= 1'b1;
                            end else begin
                                third_harmonic_hold_valid <= 1'b0;
                            end
                        end
                    end
                    
                    // 重置基波搜索
                    fundamental_found <= 1'b0;
                    fundamental_pwr_reg <= 32'd0;
                end
                
                // 搜索基波
                if (!search_harmonics) begin
                    if (in_range && power_in > THRESH) begin
                        if (power_in > fundamental_pwr_reg) begin
                            fundamental_pwr_reg <= power_in;
                            fundamental_idx_reg <= index_in;
                            fundamental_found <= 1'b1;
                        end
                    end
                end
                
                // 搜索谐波
                if (search_harmonics) begin
                    // 搜索二次谐波
                    if (search_second) begin
                        if (index_in >= (target_second_harmonic_idx - 4) &&  // 扩大搜索范围
                            index_in <= (target_second_harmonic_idx + 4)) begin
                            if (power_in > cur_second_harmonic_power) begin
                                cur_second_harmonic_power <= power_in;
                            end
                        end
                    end
                    
                    // 搜索三次谐波
                    if (search_third) begin
                        if (index_in >= (target_third_harmonic_idx - 4) &&  // 扩大搜索范围
                            index_in <= (target_third_harmonic_idx + 4)) begin
                            if (power_in > cur_third_harmonic_power) begin
                                cur_third_harmonic_power <= power_in;
                            end
                        end
                    end
                end
                
                // 即时阈值输出
                if (power_in > THRESH && in_range) begin
                    out_valid <= 1'b1;
                    out_index <= index_in;
                    out_power <= power_in;
                end
                
                // 同帧内更新最大值（用于声音检测）
                if (in_range && power_in > cur_max_power) begin
                    cur_max_power <= power_in;
                    cur_max_index <= index_in;
                end
                
                // 即时声音检测
                if (power_in > SOUND_THRESHOLD && in_range) begin
                    instant_voice_detected <= 1'b1;  // 标记当前帧有声音
                end
                
                prev_index <= index_in;
            end
            
            // 帧结束处理
            if (valid_in && index_in < prev_index) begin
                // 帧是否有声音 = 帧最大功率超过阈值 OR 即时检测到声音
                frame_has_voice[frame_ptr] <= (cur_max_power > SOUND_THRESHOLD) || instant_voice_detected;
                
                // 重置即时声音检测标志
                instant_voice_detected <= 1'b0;
                
                frame_power[frame_ptr] <= cur_max_power;
                frame_index[frame_ptr] <= cur_max_index;
                
                // 产生帧结束脉冲
                frame_end_pulse <= 1'b1;

                // —— 最近两帧取最大值输出 ——
                if (frame_power[0] >= frame_power[1]) begin
                    index <= frame_index[0];
                end else begin
                    index <= frame_index[1];
                end
                
                // 基波功率门限检查
                if (cur_max_power > 32'd1500) begin
                    out_power_hold <= cur_max_power;
                    out_power_hold_valid <= 1'b1;
                end else begin
                    out_power_hold_valid <= 1'b0;
                end
                
                // 如果找到了基波，开始谐波搜索
                if (fundamental_found && !search_harmonics) begin
                    // 计算谐波索引
                    target_second_harmonic_idx <= fundamental_idx_reg * 2;
                    target_third_harmonic_idx <= fundamental_idx_reg * 3;
                    
                    // 检查索引是否在有效范围内
                    if (target_second_harmonic_idx < 12'd2048 && target_third_harmonic_idx < 12'd2048) begin
                        // 开始谐波搜索
                        search_harmonics <= 1'b1;
                        search_second <= 1'b1;
                        cur_second_harmonic_power <= 32'd0;
                        cur_third_harmonic_power <= 32'd0;
                    end
                end

                // —— 声音检测滞回逻辑（只用于静音检测）——
                if (frame_has_voice[0] || frame_has_voice[1]) begin
                    silence_cnt <= {HOLD_FRAMES{1'b0}};
                end else begin
                    silence_cnt <= {silence_cnt[HOLD_FRAMES-2:0], 1'b1};
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
            end
            
            // 输出保持逻辑
            if (out_power_hold_valid) begin
                out_power <= out_power_hold;
            end else begin
                out_power <= 32'd0;
            end
            
            if (second_harmonic_hold_valid && second_harmonic_hold > 8'd2) begin
                second_harmonic <= second_harmonic_hold;
            end else begin
                second_harmonic <= 8'd0;
            end
            
            if (third_harmonic_hold_valid && third_harmonic_hold > 8'd2) begin
                third_harmonic <= third_harmonic_hold;
            end else begin
                third_harmonic <= 8'd0;
            end
        end
    end
    
    // ===== 单独处理max信号的always块 =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max <= 1'b0;
        end else begin
            if (instant_voice_detected_d) begin
                max <= 1'b1;
            end
            else if (frame_end_pulse_d1) begin
                if (frame_has_voice_0_d || frame_has_voice_1_d) begin
                    max <= 1'b1;
                end
                else begin
                    if (silence_cnt_d == {HOLD_FRAMES{1'b1}}) begin
                        max <= 1'b0;
                    end
                end
            end
        end
    end

endmodule