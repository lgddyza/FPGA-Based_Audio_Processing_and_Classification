module clock_div(
    input  wire        clk_in,     // 48MHz输入时钟
    input  wire        rst_n,      // 异步复位，低电平有效
    output wire        clk_out,    // 48kHz输出时钟
    output wire        pulse_out   // 48kHz脉冲信号(相位延迟90度)
);

    reg [9:0] counter;    // 分频计数器
    reg clk_out_reg;                   // 时钟输出寄存器
    reg pulse_out_reg;                 // 脉冲输出寄存器
    
    // 分频计数器逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out_reg <= 0;
            pulse_out_reg <= 0;
        end else begin
            if (counter == 10'd999) begin
                counter <= 0;
                clk_out_reg <= ~clk_out_reg;  // 时钟翻转
            end else begin
                counter <= counter + 1;
            end
            
            // 生成脉冲：在计数器的特定位置产生单周期脉冲
            // 通过调整脉冲产生的位置来控制相位
            if (counter == 10'd249) begin  // 90度相位偏移
                pulse_out_reg <= 1'b1;
            end else begin
                pulse_out_reg <= 1'b0;
            end
        end
    end
    
    assign clk_out = clk_out_reg;
    assign pulse_out = pulse_out_reg;

endmodule