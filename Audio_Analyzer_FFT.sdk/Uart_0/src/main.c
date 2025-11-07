#include <stdio.h>
#include "xparameters.h"
#include "xgpiops.h"
#include "xil_printf.h"
#include "sleep.h"

#define EMIO_FIRST_PIN 54  // EMIO起始引脚编号

static XGpioPs gpio;

static inline u32 read_index_bits(void) {
    u32 value = 0;
    // 假定 58 对应 index[0]，69 对应 index[11]
    for (int bit = 0; bit < 12; bit++) {
        u32 pin_val = XGpioPs_ReadPin(&gpio, EMIO_FIRST_PIN + 4 + bit); // 54+4=58
        value |= (pin_val & 0x1) << bit;
    }
    return value;
}

// 读取PL端信号状态
void read_pl_signals(void) {
    u32 voice_state = XGpioPs_ReadPin(&gpio, EMIO_FIRST_PIN + 0);
    u32 music_state = XGpioPs_ReadPin(&gpio, EMIO_FIRST_PIN + 1);
    u32 busy_state  = XGpioPs_ReadPin(&gpio, EMIO_FIRST_PIN + 2);
    u32 max_state   = XGpioPs_ReadPin(&gpio, EMIO_FIRST_PIN + 3);
    u32 index_value = read_index_bits();

    u32 index = index_value*11.7;

    // === 输出标准化JSON格式（网页使用） ===
    printf("{\"voice\":%d,\"music\":%d,\"busy\":%d,\"max\":%d,\"index\":%u}\r\n",
               voice_state, music_state, busy_state, max_state, index);

    // === 可选：同时输出人类可读提示 ===
    if (voice_state) {
        printf("检测到语音信号\r\n");
    }
    if (music_state) {
        printf("检测到音乐信号\r\n");
    }
    if (busy_state) {
        printf("FFTing\r\n");
    }
}

int main() {
    XGpioPs_Config *config;
    int status;

    // 初始化GPIO
    config = XGpioPs_LookupConfig(XPAR_PS7_GPIO_0_DEVICE_ID);
    status = XGpioPs_CfgInitialize(&gpio, config, config->BaseAddr);
    if (status != XST_SUCCESS) {
        xil_printf("GPIO初始化失败\r\n");
        return XST_FAILURE;
    }

    // 配置EMIO引脚为输入（54,55,56 对应 voice,music,busy）
    for (int i = 0; i < 16; i++) {
        XGpioPs_SetDirectionPin(&gpio, EMIO_FIRST_PIN + i, 0);  // 输入
        XGpioPs_SetOutputEnablePin(&gpio, EMIO_FIRST_PIN + i, 0);
    }

    xil_printf("开始监控PL端FFT处理状态...\r\n");

    while (1) {
        read_pl_signals();
        usleep(300000);
    }

    return 0;
}
