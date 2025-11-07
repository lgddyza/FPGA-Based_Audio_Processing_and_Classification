`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 4096 点一帧：在第 4096 次 AXIS 读握手时产生 data_tlast=1
//////////////////////////////////////////////////////////////////////////////////
module fft_fifo #(
    parameter integer FRAME_LEN = 4096  // 帧长，默认 4096
)(
    input  wire        clk_48,
    input  wire        rst_n,

    // 写侧（ADC -> FIFO）
    input  wire        s_axis_tvalid,
    input  wire [7:0]  adc_data,
    output wire        s_axis_tready,

    // 读侧（FIFO -> 下游）
    input  wire        m_axis_tready,  
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tvalid,

    // 其他状态信号
    output wire        wr_rst_busy,
    output wire        rd_rst_busy,
    output wire [12:0] axis_data_count, // FIFO 计数

    // 每 4096 个点给一个 TLAST 脉冲
    output wire        data_tlast
);

    // -----------------------------
    // FIFO IP 实例
    // -----------------------------
    fifo_generator_0 u_fifo_generator_0 (
        .wr_rst_busy     (wr_rst_busy),
        .rd_rst_busy     (rd_rst_busy),
        .s_aclk          (clk_48),
        .s_aresetn       (rst_n),

        // 写 AXIS（ADC -> FIFO）
        .s_axis_tvalid   (s_axis_tvalid),
        .s_axis_tready   (s_axis_tready),
        .s_axis_tdata    (adc_data),

        // 读 AXIS（FIFO -> 下游）
        .m_axis_tvalid   (m_axis_tvalid),
        .m_axis_tready   (m_axis_tready),
        .m_axis_tdata    (m_axis_tdata),

        // 计数
        .axis_data_count (axis_data_count)
    );

    // -----------------------------
    // TLAST 产生逻辑（读出侧对齐）
    // 在每一次 m_axis_tvalid && m_axis_tready 的有效传输计数；
    // 当计到第 FRAME_LEN 个拍（即 4096）时，data_tlast=1（仅 1 个 clk）
    // -----------------------------
    reg [12:0] rd_cnt;          // 0..4095 计数（需要 13 bit 表示 4096）
    reg        in_frame;        // 处于一帧中
    reg        tlast_r;

    wire handshake = m_axis_tvalid && m_axis_tready;

    always @(posedge clk_48 or negedge rst_n) begin
        if (!rst_n) begin
            rd_cnt   <= 13'd0;
            in_frame <= 1'b0;
            tlast_r  <= 1'b0;
        end else begin
            tlast_r <= 1'b0; // 缺省拉低，仅在命中时拉高 1 个拍

            if (!in_frame) begin
                // 等待帧首个有效读握手，开始计数
                if (handshake) begin
                    in_frame <= 1'b1;
                    // 第一拍计为 1
                    if (FRAME_LEN == 13'd1) begin
                        // 单点帧的极端情况
                        tlast_r  <= 1'b1;
                        in_frame <= 1'b0;
                        rd_cnt   <= 13'd0;
                    end else begin
                        rd_cnt <= 13'd1;
                    end
                end
            end else begin
                // 帧内：仅在有效握手时累计
                if (handshake) begin
                    if (rd_cnt == (FRAME_LEN-1)) begin
                        // 本拍是第 FRAME_LEN 个点：拉高 TLAST，并结束本帧
                        tlast_r  <= 1'b1;
                        in_frame <= 1'b0;
                        rd_cnt   <= 13'd0;
                    end else begin
                        rd_cnt <= rd_cnt + 13'd1;
                    end
                end
            end
        end
    end

    assign data_tlast = tlast_r;

endmodule
