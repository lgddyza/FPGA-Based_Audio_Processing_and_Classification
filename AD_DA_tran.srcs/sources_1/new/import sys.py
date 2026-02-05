import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import serial
import serial.tools.list_ports
import threading
import re
import json
from datetime import datetime

class SerialMonitorApp:
    def __init__(self, root):
        self.root = root
        self.root.title("PL信号检测监控")
        self.root.geometry("600x500")
        self.root.configure(bg="#f5f5f5")

        self.serial_port = None
        self.running = False
        self.current_signal = {"voice": 0, "music": 0, "busy": 0}
        self.last_update_time = None

        # 串口选择区
        top_frame = tk.Frame(root, bg="#f5f5f5")
        top_frame.pack(pady=10)

        tk.Label(top_frame, text="串口号：", bg="#f5f5f5", fg="black").pack(side=tk.LEFT)
        self.port_combo = ttk.Combobox(top_frame, width=15)
        self.port_combo.pack(side=tk.LEFT, padx=5)

        tk.Label(top_frame, text="波特率：", bg="#f5f5f5", fg="black").pack(side=tk.LEFT)
        self.baud_combo = ttk.Combobox(top_frame, values=["9600", "115200", "230400"], width=10)
        self.baud_combo.current(1)
        self.baud_combo.pack(side=tk.LEFT, padx=5)

        ttk.Button(top_frame, text="刷新", command=self.refresh_ports).pack(side=tk.LEFT, padx=5)
        self.connect_btn = ttk.Button(top_frame, text="连接", command=self.toggle_connection)
        self.connect_btn.pack(side=tk.LEFT, padx=5)

        # 信号状态显示区
        self.status_frame = tk.Frame(root, bg="#f5f5f5")
        self.status_frame.pack(pady=20)

        # Voice信号显示
        self.voice_frame = tk.Frame(self.status_frame, bg="#f5f5f5")
        self.voice_frame.pack(side=tk.LEFT, padx=10)
        self.voice_led = tk.Label(self.voice_frame, text="●", font=("Arial", 24), fg="red")
        self.voice_led.pack()
        tk.Label(self.voice_frame, text="语音信号", bg="#f5f5f5").pack()

        # Music信号显示
        self.music_frame = tk.Frame(self.status_frame, bg="#f5f5f5")
        self.music_frame.pack(side=tk.LEFT, padx=10)
        self.music_led = tk.Label(self.music_frame, text="●", font=("Arial", 24), fg="red")
        self.music_led.pack()
        tk.Label(self.music_frame, text="音乐信号", bg="#f5f5f5").pack()

        # Busy状态显示
        self.busy_frame = tk.Frame(self.status_frame, bg="#f5f5f5")
        self.busy_frame.pack(side=tk.LEFT, padx=10)
        self.busy_led = tk.Label(self.busy_frame, text="●", font=("Arial", 24), fg="red")
        self.busy_led.pack()
        tk.Label(self.busy_frame, text="处理状态", bg="#f5f5f5").pack()

        # 活动强度显示
        self.activity_bar = ttk.Progressbar(root, length=300, mode="determinate")
        self.activity_bar.pack(pady=10)
        tk.Label(root, text="活动强度", bg="#f5f5f5").pack()

        # 日志窗口
        log_label = tk.Label(root, text="串口日志输出：", bg="#f5f5f5", fg="black")
        log_label.pack(pady=(20, 5))

        self.log_text = scrolledtext.ScrolledText(root, width=70, height=12, bg="white", fg="black", wrap=tk.WORD)
        self.log_text.pack(padx=10, pady=5)

        self.refresh_ports()

    def refresh_ports(self):
        ports = [port.device for port in serial.tools.list_ports.comports()]
        self.port_combo["values"] = ports
        if ports:
            self.port_combo.current(0)

    def toggle_connection(self):
        if self.serial_port and self.serial_port.is_open:
            self.running = False
            self.serial_port.close()
            self.connect_btn.config(text="连接")
            self.log_text.insert(tk.END, "\n--- 串口已断开 ---\n")
        else:
            port = self.port_combo.get()
            baud = self.baud_combo.get()
            try:
                self.serial_port = serial.Serial(port, baudrate=int(baud), timeout=1)
                self.running = True
                self.connect_btn.config(text="断开")
                threading.Thread(target=self.read_serial, daemon=True).start()
                self.log_text.insert(tk.END, f"--- 已连接 {port} @ {baud} ---\n")
            except Exception as e:
                messagebox.showerror("错误", f"无法打开串口：{e}")

    def read_serial(self):
        while self.running:
            try:
                line = self.serial_port.readline().decode(errors="ignore").strip()
                if line:
                    self.log_text.insert(tk.END, line + "\n")
                    self.log_text.see(tk.END)
                    self.parse_signal(line)
            except Exception:
                pass

    def parse_signal(self, text):
        try:
            # 尝试解析JSON格式数据
            if text.startswith("{") and text.endswith("}"):
                data = json.loads(text)
                self.current_signal["voice"] = int(data.get("voice", 0))
                self.current_signal["music"] = int(data.get("music", 0))
                self.current_signal["busy"] = int(data.get("busy", 0))
                self.last_update_time = datetime.now().strftime("%H:%M:%S")
                self.log_text.insert(tk.END, f"[{self.last_update_time}] 状态更新\n")
            
            # 处理附加信息行
            elif "检测到语音信号" in text:
                self.current_signal["voice"] = 1
                self.log_text.insert(tk.END, f"[{datetime.now().strftime('%H:%M:%S')}] 语音信号检测\n")
            
            elif "检测到音乐信号" in text:
                self.current_signal["music"] = 1
                self.log_text.insert(tk.END, f"[{datetime.now().strftime('%H:%M:%S')}] 音乐信号检测\n")
            
            elif "FFTing" in text:
                self.current_signal["busy"] = 1
                self.log_text.insert(tk.END, f"[{datetime.now().strftime('%H:%M:%S')}] FFT处理中\n")
            
            # 更新UI
            self.update_display()
            
        except json.JSONDecodeError:
            # 如果不是JSON格式，尝试旧版解析
            if "Voice:" in text and "Music:" in text and "Busy:" in text:
                match = re.search(r'Voice:\s*(\d+)\s*,\s*Music:\s*(\d+)\s*,\s*Busy:\s*(\d+)', text)
                if match:
                    self.current_signal["voice"] = int(match.group(1))
                    self.current_signal["music"] = int(match.group(2))
                    self.current_signal["busy"] = int(match.group(3))
                    self.last_update_time = datetime.now().strftime("%H:%M:%S")
                    self.log_text.insert(tk.END, f"[{self.last_update_time}] 状态更新\n")
                    self.update_display()

    def update_display(self):
        # 更新LED指示灯
        voice_color = "green" if self.current_signal["voice"] else "red"
        music_color = "green" if self.current_signal["music"] else "red"
        busy_color = "green" if self.current_signal["busy"] else "red"
        
        self.voice_led.config(fg=voice_color)
        self.music_led.config(fg=music_color)
        self.busy_led.config(fg=busy_color)
        
        # 更新活动强度
        activity = (self.current_signal["voice"] + self.current_signal["music"]) * 50
        self.activity_bar["value"] = activity

if __name__ == "__main__":
    root = tk.Tk()
    app = SerialMonitorApp(root)
    root.mainloop()
