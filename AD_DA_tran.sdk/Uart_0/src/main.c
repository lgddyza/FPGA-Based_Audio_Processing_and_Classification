#include <stdio.h>
#include <stdlib.h>
#include "xparameters.h"
#include "xgpiops.h"
#include "xil_printf.h"
#include "sleep.h"

#define EMIO_FIRST_PIN     54    // EMIO起始引脚编号
#define WINDOW_SIZE        15    // 滑动窗口大小
#define SAMPLE_DELAY_US    200000 // 采样间隔(100ms)

#define MIN_VALID_SAMPLES  2

// ====== 滞回阈值 ======
#define VOICE_THRESHOLD_LOW    300
#define MUSIC_THRESHOLD_HIGH   600

#define CONFIRM_COUNT          6   // 连续满足切换条件多少次才真正切换

// ====== 你要求的两条逻辑 ======
#define START_GATE_THRESHOLD       100   // 进入窗口启动门槛：index>=200才入窗
#define FIRST_VALUE_MUSIC_PRIORITY 900   // 新段第一个入窗值>700，优先直接判音乐

// ====== 新增：谐波门限阈值 ======
#define HARMONIC_THRESHOLD     10     // 谐波存在门限（幅值>5认为存在）

// ====== 新增：频率阈值 ======
#define HIGH_FREQ_THRESHOLD    2000  // 高频阈值(Hz)，高于此值应用新逻辑
#define INDEX_TO_HZ            117   // index到Hz的转换系数 (index * 117 / 10 = Hz)

// ====== 新增：二次谐波计数阈值 ======
#define SECOND_HARMONIC_COUNT_THRESHOLD 15  // 高频时需要检测到10次二次谐波

// ====== 新增：频率锁定参数 ======
#define INITIAL_FREQ_COUNT_THRESHOLD 5     // 初始频率需要出现5次才锁定
#define FREQ_DOUBLE_RATIO_LOW  1.8f        // 接近2倍的判断下限
#define FREQ_DOUBLE_RATIO_HIGH 2.2f        // 接近2倍的判断上限
#define FREQ_TRIPLE_RATIO_LOW  2.8f        // 接近3倍的判断下限
#define FREQ_TRIPLE_RATIO_HIGH 3.2f        // 接近3倍的判断上限
#define FREQ_TOLERANCE_PERCENT 10          // 频率变化容差百分比

// ====== 新增：频率辅助音乐判断窗口参数 ======
#define FREQ_MUSIC_WINDOW_SIZE 12  // 频率音乐判断窗口大小
#define FREQ_MUSIC_THRESHOLD   295 // 频率音乐判断阈值
#define FREQ_MUSIC_PERCENT     80  // 80%的样本需要大于阈值

// ====== 新增：波形类型枚举 ======
typedef enum {
    WAVE_UNKNOWN = 0,  // 未知波形
    WAVE_SINE,         // 正弦波 -> 对应数字1
    WAVE_SQUARE,       // 方波/矩形波 -> 对应数字2
    WAVE_SAWTOOTH,     // 锯齿波 -> 对应数字3
    WAVE_COMPLEX       // 复杂波形
} WaveType;

static XGpioPs gpio;

typedef struct {
    u32 voice_state;
    u32 music_state;
    u32 busy_state;
    u32 max_state;
    u32 index;
    u32 fundamental_amp;    // 基波幅度（12位）
    u32 second_harmonic_amp; // 新增：二次谐波幅度（8位）
    u32 third_harmonic_amp;  // 三次谐波幅度（8位）
} FFT_Data;

typedef struct {
    u32 buffer[WINDOW_SIZE];
    u32 count;
    u32 index;
} SlidingWindow;

static SlidingWindow index_window = {0};
static SlidingWindow busy_window  = {0};
static SlidingWindow max_window   = {0};
static SlidingWindow fundamental_amp_window = {0};   // 基波幅度窗口
static SlidingWindow second_harmonic_window = {0};   // 新增：二次谐波窗口
static SlidingWindow third_harmonic_window  = {0};   // 三次谐波窗口

// ====== 新增：频率音乐判断窗口 ======
static SlidingWindow freq_music_window = {0};

static u32 prev_max_state = 0;
static u32 prev_busy_state = 0;

// ====== 分类状态机 ======
typedef enum {
    CLASS_NONE = 0,
    CLASS_VOICE,
    CLASS_MUSIC
} AudioClass;

static AudioClass current_class = CLASS_NONE;
static u32 switch_counter = 0;

// ====== 新段/强制音乐标记 ======
static u8 new_segment   = 0;  // max 0->1 后置1：等待本段第一个"入窗index"
static u8 forced_music  = 0;  // 本段被强制判音乐（直到max变0结束）

// ====== 新增：频率辅助强制音乐标记 ======
static u8 freq_forced_music = 0;  // 频率窗口强制判音乐

// ====== 新增：锯齿波标记 ======
static u8 forced_sawtooth = 0;  // 本段被强制判锯齿波（直到max变0结束）

// ====== 新增：二次谐波计数 ======
static u32 second_harmonic_count = 0;  // 本段内检测到二次谐波的次数

// ====== 新增：频率锁定相关变量 ======
static u8 initial_freq_locked = 0;      // 初始频率是否已锁定
static u32 locked_initial_freq = 0;     // 锁定的初始频率(Hz)
static u32 locked_initial_index = 0;    // 锁定的初始index
static u32 initial_freq_count = 0;      // 当前频率出现次数
static u32 current_stable_freq = 0;     // 当前稳定的频率
static u32 current_stable_index = 0;    // 当前稳定的index
static u8 sawtooth_detected_by_freq = 0;  // 通过频率倍频检测到锯齿波
static u8 square_detected_by_freq = 0;    // 通过频率倍频检测到矩形波

// ====== 窗口函数 ======
void init_window(SlidingWindow* window) {
    window->count = 0;
    window->index = 0;
    for (int i = 0; i < window->count; i++) {
        window->buffer[i] = 0;
    }
}

static inline void add_to_window(SlidingWindow* window, u32 value) {
    window->buffer[window->index] = value;
    window->index = (window->index + 1) % WINDOW_SIZE;
    if (window->count < WINDOW_SIZE) {
        window->count++;
    }
}

u32 calculate_average(const SlidingWindow* window) {
    if (window->count == 0) return 0;

    u32 sum = 0;
    for (u32 i = 0; i < window->count; i++) {
        sum += window->buffer[i];
    }
    return sum / window->count;
}

u32 calculate_majority(const SlidingWindow* window) {
    if (window->count == 0) return 0;

    u32 ones = 0;
    for (u32 i = 0; i < window->count; i++) {
        if (window->buffer[i]) ones++;
    }
    return (ones > window->count / 2) ? 1 : 0;
}

// ====== 新增：计算频率音乐判断窗口内大于阈值的比例 ======
static u32 calculate_freq_music_ratio(const SlidingWindow* window) {
    if (window->count == 0) return 0;

    u32 high_freq_count = 0;
    for (u32 i = 0; i < window->count; i++) {
        if (window->buffer[i] > FREQ_MUSIC_THRESHOLD) {
            high_freq_count++;
        }
    }

    // 返回百分比
    return (high_freq_count * 100) / window->count;
}

// ====== 新增：检查是否应该强制判为音乐 ======
static u8 should_force_music_by_freq(const SlidingWindow* window) {
    if (window->count < FREQ_MUSIC_WINDOW_SIZE) {
        return 0;  // 窗口未满，不判断
    }

    u32 ratio = calculate_freq_music_ratio(window);
    return (ratio >= FREQ_MUSIC_PERCENT);
}

// ====== 读12bit index ======
static inline u32 read_index_bits(void) {
    u32 value = 0;
    for (int bit = 0; bit < 12; bit++) {
        u32 pin_val = XGpioPs_ReadPin(&gpio, EMIO_FIRST_PIN + 4 + bit);
        value |= (pin_val & 0x1) << bit;
    }
    return value;
}

// ====== 读12位基波幅度 (EMIO引脚78-89) ======
static inline u32 read_fundamental_amp_bits(void) {
    u32 value = 0;
    for (int bit = 0; bit < 12; bit++) {
        // EMIO引脚78-89对应fundamental_amp[11:0]
        u32 pin_val = XGpioPs_ReadPin(&gpio, EMIO_FIRST_PIN + 24 + bit);
        value |= (pin_val & 0x1) << bit;
    }
    return value;
}

// ====== 新增：读8位二次谐波幅度 (EMIO引脚90-97) ======
static inline u32 read_second_harmonic_bits(void) {
    u32 value = 0;
    for (int bit = 0; bit < 8; bit++) {
        // EMIO引脚90-97对应second_harmonic[7:0]
        u32 pin_val = XGpioPs_ReadPin(&gpio, EMIO_FIRST_PIN + 36 + bit);
        value |= (pin_val & 0x1) << bit;
    }
    return value;
}

// ====== 读8位三次谐波幅度 (EMIO引脚70-77) ======
static inline u32 read_third_harmonic_bits(void) {
    u32 value = 0;
    for (int bit = 0; bit < 8; bit++) {
        // EMIO引脚70-77对应third_harmonic[7:0]
        u32 pin_val = XGpioPs_ReadPin(&gpio, EMIO_FIRST_PIN + 16 + bit);
        value |= (pin_val & 0x1) << bit;
    }
    return value;
}

// ====== 新增：计算频率(Hz) ======
static inline u32 calculate_frequency_hz(u32 index_value) {
    return (index_value * INDEX_TO_HZ) / 10U;
}

// ====== 新增：检查频率是否接近 ======
static u8 is_frequency_close(u32 freq1, u32 freq2, float percent_tolerance) {
    if (freq1 == 0 || freq2 == 0) return 0;

    float ratio = (freq1 > freq2) ? (float)freq1 / freq2 : (float)freq2 / freq1;
    float max_ratio = 1.0f + (percent_tolerance / 100.0f);

    return (ratio <= max_ratio);
}

// ====== 新增：检查频率是否为倍频 ======
static u8 check_frequency_double(u32 freq, u32 base_freq) {
    if (base_freq == 0) return 0;

    float ratio = (float)freq / base_freq;
    return (ratio >= FREQ_DOUBLE_RATIO_LOW && ratio <= FREQ_DOUBLE_RATIO_HIGH);
}

static u8 check_frequency_triple(u32 freq, u32 base_freq) {
    if (base_freq == 0) return 0;

    float ratio = (float)freq / base_freq;
    return (ratio >= FREQ_TRIPLE_RATIO_LOW && ratio <= FREQ_TRIPLE_RATIO_HIGH);
}

// ====== 新增：波形判断函数 ======
static WaveType determine_wave_type(u32 second_harmonic, u32 third_harmonic, u32 freq_hz) {
    u8 has_second = (second_harmonic > HARMONIC_THRESHOLD);
    u8 has_third = (third_harmonic > HARMONIC_THRESHOLD);

    // 优先检查频率倍频检测结果
    if (sawtooth_detected_by_freq) {
        return WAVE_SAWTOOTH;  // 频率倍频检测到锯齿波
    } else if (square_detected_by_freq) {
        return WAVE_SQUARE;    // 频率倍频检测到矩形波
    }

    // 原有逻辑
    if (has_second && has_third) {
        return WAVE_SAWTOOTH;    // 二次、三次均有值 -> 锯齿波
    } else if (has_second) {
        return WAVE_SAWTOOTH;    // 只有二次谐波 -> 锯齿波
    } else if (has_third) {
        return WAVE_SQUARE;      // 只有三次谐波 -> 矩形波
    } else {
        return WAVE_SINE;        // 二次、三次都无值 -> 正弦波
    }
}

// ====== 滞回 + 连续确认分类器 ======
static AudioClass classify_with_hysteresis(u32 index_avg, u32 max_state) {
    if (max_state == 0) {
        current_class = CLASS_NONE;
        switch_counter = 0;
        return CLASS_NONE;
    }

    if (current_class == CLASS_NONE) {
        if (index_avg >= MUSIC_THRESHOLD_HIGH) current_class = CLASS_MUSIC;
        else if (index_avg <= VOICE_THRESHOLD_LOW) current_class = CLASS_VOICE;
        else current_class = CLASS_MUSIC;
        switch_counter = 0;
        return current_class;
    }

    if (current_class == CLASS_MUSIC) {
        if (index_avg <= VOICE_THRESHOLD_LOW) {
            switch_counter++;
            if (switch_counter >= CONFIRM_COUNT) {
                current_class = CLASS_VOICE;
                switch_counter = 0;
            }
        } else {
            switch_counter = 0;
        }
    } else if (current_class == CLASS_VOICE) {
        if (index_avg >= MUSIC_THRESHOLD_HIGH) {
            switch_counter++;
            if (switch_counter >= CONFIRM_COUNT) {
                current_class = CLASS_MUSIC;
                switch_counter = 0;
            }
        } else {
            switch_counter = 0;
        }
    }

    return current_class;
}

/*
 * 处理频率锁定逻辑
 */
static void process_frequency_locking(FFT_Data* raw_data) {
    u32 current_freq = calculate_frequency_hz(raw_data->index);

    // 只在busy=0时处理频率锁定
    if (raw_data->busy_state == 0 && raw_data->max_state == 1) {
        // 如果初始频率未锁定
        if (!initial_freq_locked) {
            // 检查频率是否稳定
            if (current_stable_freq == 0) {
                // 第一次检测到频率
                current_stable_freq = current_freq;
                current_stable_index = raw_data->index;
                initial_freq_count = 1;
            } else if (is_frequency_close(current_freq, current_stable_freq, FREQ_TOLERANCE_PERCENT)) {
                // 频率接近，增加计数
                initial_freq_count++;

                // 如果达到阈值，锁定初始频率
                if (initial_freq_count >= INITIAL_FREQ_COUNT_THRESHOLD) {
                    locked_initial_freq = current_stable_freq;
                    locked_initial_index = current_stable_index;
                    initial_freq_locked = 1;
                }
            } else {
                // 频率变化太大，重置
                current_stable_freq = current_freq;
                current_stable_index = raw_data->index;
                initial_freq_count = 1;
            }
        } else {
            // 初始频率已锁定，检查是否出现倍频
            if (current_freq > locked_initial_freq) {
                if (check_frequency_double(current_freq, locked_initial_freq)) {
                    // 检测到接近2倍频，可能是锯齿波
                    sawtooth_detected_by_freq = 1;
                    square_detected_by_freq = 0;
                } else if (check_frequency_triple(current_freq, locked_initial_freq)) {
                    // 检测到接近3倍频，可能是矩形波
                    square_detected_by_freq = 1;
                    sawtooth_detected_by_freq = 0;
                }
            }
        }
    }
}

/*
 * 处理频率音乐判断
 */
static void process_freq_music_judgment(FFT_Data* raw_data) {
    // 只在max=1时处理
    if (raw_data->max_state == 1 && raw_data->index >= START_GATE_THRESHOLD) {
        // 将当前index加入频率音乐判断窗口
        add_to_window(&freq_music_window, raw_data->index);

        // 检查是否应该强制判为音乐
        freq_forced_music = should_force_music_by_freq(&freq_music_window);
    }
}

/*
 * 读取原始PL信号 + 更新窗口
 */
FFT_Data detect_pl_signals(void) {
    FFT_Data raw_data = {0};

    raw_data.busy_state = XGpioPs_ReadPin(&gpio, EMIO_FIRST_PIN + 2);
    raw_data.max_state  = XGpioPs_ReadPin(&gpio, EMIO_FIRST_PIN + 3);

    u32 index_value = read_index_bits();
    raw_data.index = (index_value * 117U) / 10U;

    // 读取基波幅度和所有谐波幅度
    raw_data.fundamental_amp = read_fundamental_amp_bits();   // 12位
    raw_data.second_harmonic_amp = read_second_harmonic_bits(); // 新增：8位二次谐波
    raw_data.third_harmonic_amp = read_third_harmonic_bits(); // 8位三次谐波

    // 处理频率锁定逻辑
    process_frequency_locking(&raw_data);

    // 处理频率音乐判断
    process_freq_music_judgment(&raw_data);

    // 段结束：max 1->0 清空窗口+状态
    if (prev_max_state == 1 && raw_data.max_state == 0) {
        init_window(&index_window);
        init_window(&busy_window);
        init_window(&max_window);
        init_window(&fundamental_amp_window);
        init_window(&second_harmonic_window);  // 新增
        init_window(&third_harmonic_window);

        // 新增：清空频率音乐判断窗口
        init_window(&freq_music_window);

        current_class = CLASS_NONE;
        switch_counter = 0;
        new_segment = 0;
        forced_music = 0;
        freq_forced_music = 0;  // 新增：重置频率强制音乐标记
        forced_sawtooth = 0;  // 新增：重置强制锯齿波标记
        second_harmonic_count = 0;  // 新增：重置二次谐波计数

        // 新增：重置频率锁定相关状态
        initial_freq_locked = 0;
        locked_initial_freq = 0;
        locked_initial_index = 0;
        initial_freq_count = 0;
        current_stable_freq = 0;
        current_stable_index = 0;
        sawtooth_detected_by_freq = 0;
        square_detected_by_freq = 0;
    }

    // 段开始：max 0->1 标记新段（等待第一个"入窗值"）
    if (prev_max_state == 0 && raw_data.max_state == 1) {
        init_window(&index_window);
        init_window(&busy_window);
        init_window(&max_window);
        init_window(&fundamental_amp_window);
        init_window(&second_harmonic_window);  // 新增
        init_window(&third_harmonic_window);

        // 新增：清空频率音乐判断窗口
        init_window(&freq_music_window);

        current_class = CLASS_NONE;
        switch_counter = 0;
        new_segment = 1;
        forced_music = 0;
        freq_forced_music = 0;  // 新增：重置频率强制音乐标记
        forced_sawtooth = 0;  // 新增：重置强制锯齿波标记
        second_harmonic_count = 0;  // 新增：重置二次谐波计数

        // 新增：重置频率锁定相关状态
        initial_freq_locked = 0;
        locked_initial_freq = 0;
        locked_initial_index = 0;
        initial_freq_count = 0;
        current_stable_freq = 0;
        current_stable_index = 0;
        sawtooth_detected_by_freq = 0;
        square_detected_by_freq = 0;
    }

    // 只在 max==1 有效期间处理
    if (raw_data.max_state == 1) {
        // 计算当前频率(Hz)
        u32 freq_hz = calculate_frequency_hz(index_value);

        // 新增：高频(>2000Hz)且检测到二次谐波，增加计数
        if (freq_hz > HIGH_FREQ_THRESHOLD && raw_data.second_harmonic_amp > HARMONIC_THRESHOLD) {
            second_harmonic_count++;  // 增加二次谐波计数

            // 当达到3次时，标记本段为锯齿波
            if (second_harmonic_count >= SECOND_HARMONIC_COUNT_THRESHOLD) {
                forced_sawtooth = 1;  // 标记本段为强制锯齿波
            }
        }

        // 进入窗口门槛：<200 直接丢弃（不进窗、不影响均值）
        if (raw_data.index < START_GATE_THRESHOLD) {
            prev_max_state = raw_data.max_state;
            return raw_data;
        }

        // 新段的第一个"入窗值">700：优先直接判定音乐（本段强制音乐）
        if (new_segment) {
            if (raw_data.index > FIRST_VALUE_MUSIC_PRIORITY) {
                forced_music = 1;
                current_class = CLASS_MUSIC;   // 直接置音乐，避免起始误判语音
                switch_counter = 0;
            }
            new_segment = 0;
        }

        // 正常入窗
        add_to_window(&index_window, raw_data.index);
        add_to_window(&busy_window,  raw_data.busy_state);
        add_to_window(&max_window,   raw_data.max_state);
        add_to_window(&fundamental_amp_window, raw_data.fundamental_amp);
        add_to_window(&second_harmonic_window, raw_data.second_harmonic_amp);  // 新增
        add_to_window(&third_harmonic_window, raw_data.third_harmonic_amp);
    }

    prev_max_state = raw_data.max_state;
    prev_busy_state = raw_data.busy_state;
    return raw_data;
}

FFT_Data get_filtered_data(const FFT_Data* raw) {
    FFT_Data filtered = {0};

    if (index_window.count == 0) {
        filtered.busy_state  = raw->busy_state;
        filtered.max_state   = raw->max_state;
        filtered.index       = raw->index;
        filtered.fundamental_amp = raw->fundamental_amp;
        filtered.second_harmonic_amp = raw->second_harmonic_amp;  // 新增
        filtered.third_harmonic_amp = raw->third_harmonic_amp;
        filtered.voice_state = 0;
        filtered.music_state = 0;
        return filtered;
    }

    filtered.busy_state = calculate_majority(&busy_window);
    filtered.max_state  = calculate_majority(&max_window);

    u32 index_avg = calculate_average(&index_window);

    // 频率锁定逻辑：如果初始频率已锁定，使用锁定频率
    if (initial_freq_locked && filtered.max_state == 1) {
        filtered.index = locked_initial_index;  // 使用锁定的index
    } else {
        filtered.index = index_avg;
    }

    // 计算基波和谐波平均值
    u32 fundamental_avg = calculate_average(&fundamental_amp_window);
    u32 second_harmonic_avg = calculate_average(&second_harmonic_window);  // 新增
    u32 third_harmonic_avg = calculate_average(&third_harmonic_window);
    filtered.fundamental_amp = fundamental_avg;
    filtered.second_harmonic_amp = second_harmonic_avg;  // 新增
    filtered.third_harmonic_amp = third_harmonic_avg;

    if (index_window.count < MIN_VALID_SAMPLES) {
        filtered.voice_state = 0;
        filtered.music_state = 0;
        return filtered;
    }

    // ====== 新增：当max=0时，清零二次和三次谐波幅度 ======
    if (filtered.max_state == 0) {
        filtered.second_harmonic_amp = 0;
        filtered.third_harmonic_amp = 0;
    }

    // ====== 新增：频率音乐判断优先 ======
    // 如果频率窗口判断为音乐，强制判为音乐
    if (freq_forced_music && filtered.max_state == 1) {
        filtered.voice_state = 0;
        filtered.music_state = 1;
        return filtered;
    }

    // ====== 你要的"优先音乐输出" ======
    // 一旦本段触发 forced_music，则本段内直接输出音乐（直到max变0段结束）
    if (forced_music && filtered.max_state == 1) {
        filtered.voice_state = 0;
        filtered.music_state = 1;
        return filtered;
    }

    // 否则走原来的 滞回+确认 逻辑（基于平均值）
    AudioClass cls = classify_with_hysteresis(index_avg, filtered.max_state);

    if (cls == CLASS_VOICE) {
        filtered.voice_state = 1;
        filtered.music_state = 0;
    } else if (cls == CLASS_MUSIC) {
        filtered.voice_state = 0;
        filtered.music_state = 1;
    } else {
        filtered.voice_state = 0;
        filtered.music_state = 0;
    }

    return filtered;
}

void output_json_data(const FFT_Data* raw, const FFT_Data* filtered) {
    // 新增：计算波形类型
    u32 freq_hz = calculate_frequency_hz(raw->index);
    WaveType wave_type = determine_wave_type(filtered->second_harmonic_amp,
                                            filtered->third_harmonic_amp,
                                            freq_hz);

    // 新增：强制锯齿波逻辑
    if (forced_sawtooth && filtered->max_state == 1) {
        wave_type = WAVE_SAWTOOTH;  // 强制覆盖为锯齿波
    }

    // 将波形类型转换为数字：1-正弦，2-矩形，3-锯齿
    u32 wave_type_number = 0;
    switch (wave_type) {
        case WAVE_SINE:     wave_type_number = 1; break;  // 正弦波 -> 1
        case WAVE_SQUARE:   wave_type_number = 2; break;  // 矩形波 -> 2
        case WAVE_SAWTOOTH: wave_type_number = 3; break;  // 锯齿波 -> 3
        default:           wave_type_number = 0; break;  // 未知波形
    }

    // 确定输出的index
    u32 output_index = raw->index;  // 默认使用原始index

    // 如果busy=0且初始频率已锁定，使用锁定的index
    if (raw->busy_state == 0 && initial_freq_locked) {
        output_index = locked_initial_index;
    }

    // 输出JSON格式
    printf("{\"voice\":%d,\"music\":%d,\"busy\":%d,\"max\":%d,"
           "\"index\":%u,\"fundamental\":%u,\"second_harmonic\":%u,\"third_harmonic\":%u,\"wave_type\":%u}\r\n",
           filtered->voice_state, filtered->music_state,
           filtered->busy_state, filtered->max_state,
           output_index,  // 使用确定的index
           raw->fundamental_amp,      // 原始基波幅度（12位）
           raw->second_harmonic_amp,  // 原始二次谐波幅度（8位）
           raw->third_harmonic_amp,   // 原始三次谐波幅度（8位）
           wave_type_number);         // 波形类型：1=正弦，2=矩形，3=锯齿
}

int main() {
    XGpioPs_Config *config;
    int status;

    config = XGpioPs_LookupConfig(XPAR_PS7_GPIO_0_DEVICE_ID);
    status = XGpioPs_CfgInitialize(&gpio, config, config->BaseAddr);
    if (status != XST_SUCCESS) {
        xil_printf("GPIO初始化失败\r\n");
        return XST_FAILURE;
    }

    // 配置 busy/max 输入
    for (int i = 2; i < 4; i++) {
        XGpioPs_SetDirectionPin(&gpio, EMIO_FIRST_PIN + i, 0);
        XGpioPs_SetOutputEnablePin(&gpio, EMIO_FIRST_PIN + i, 0);
    }

    // 配置 index 12bit 输入
    for (int i = 4; i < 16; i++) {
        XGpioPs_SetDirectionPin(&gpio, EMIO_FIRST_PIN + i, 0);
        XGpioPs_SetOutputEnablePin(&gpio, EMIO_FIRST_PIN + i, 0);
    }

    // 配置三次谐波8bit输入 (EMIO引脚70-77)
    for (int i = 16; i < 24; i++) {  // 16-23对应third_harmonic[7:0]
        XGpioPs_SetDirectionPin(&gpio, EMIO_FIRST_PIN + i, 0);
        XGpioPs_SetOutputEnablePin(&gpio, EMIO_FIRST_PIN + i, 0);
    }

    // 新增：配置二次谐波8bit输入 (EMIO引脚90-97)
    for (int i = 36; i < 44; i++) {  // 36-43对应second_harmonic[7:0]
        XGpioPs_SetDirectionPin(&gpio, EMIO_FIRST_PIN + i, 0);
        XGpioPs_SetOutputEnablePin(&gpio, EMIO_FIRST_PIN + i, 0);
    }

    // 配置基波幅度12bit输入 (EMIO引脚78-89)
    for (int i = 24; i < 36; i++) {  // 24-35对应fundamental_amp[11:0] (12位)
        XGpioPs_SetDirectionPin(&gpio, EMIO_FIRST_PIN + i, 0);
        XGpioPs_SetOutputEnablePin(&gpio, EMIO_FIRST_PIN + i, 0);
    }

    init_window(&index_window);
    init_window(&busy_window);
    init_window(&max_window);
    init_window(&fundamental_amp_window);
    init_window(&second_harmonic_window);  // 新增
    init_window(&third_harmonic_window);

    // 新增：初始化频率音乐判断窗口
    freq_music_window.count = 0;
    freq_music_window.index = 0;
    for (int i = 0; i < FREQ_MUSIC_WINDOW_SIZE; i++) {
        freq_music_window.buffer[i] = 0;
    }

    prev_max_state = 0;
    prev_busy_state = 0;
    current_class = CLASS_NONE;
    switch_counter = 0;
    new_segment = 0;
    forced_music = 0;
    freq_forced_music = 0;  // 新增
    forced_sawtooth = 0;  // 新增
    second_harmonic_count = 0;  // 新增
    initial_freq_locked = 0;
    locked_initial_freq = 0;
    locked_initial_index = 0;
    initial_freq_count = 0;
    current_stable_freq = 0;
    current_stable_index = 0;
    sawtooth_detected_by_freq = 0;
    square_detected_by_freq = 0;

    while (1) {
        FFT_Data raw = detect_pl_signals();
        FFT_Data filtered = get_filtered_data(&raw);
        output_json_data(&raw, &filtered);
        usleep(SAMPLE_DELAY_US);
    }

    return 0;
}
