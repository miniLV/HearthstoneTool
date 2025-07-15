#!/usr/bin/env python3
"""
改进版炉石拔线工具
- 支持keychain密码存储
- 添加快捷键支持
- 炉石进程检测
- 更好的错误处理
"""

import tkinter as tk
from tkinter import messagebox, ttk
import subprocess
import os
import sys
import threading
import time
import json
from pathlib import Path
import psutil
import signal

class HearthstoneDisconnectTool:
    def __init__(self):
        self.root = tk.Tk()
        self.setup_window()
        self.setup_ui()
        self.setup_keychain()
        self.setup_shortcuts()
        self.setup_process_monitor()
        
        # 状态变量
        self.is_disconnecting = False
        self.hearthstone_running = False
        self.drag_start_x = 0
        self.drag_start_y = 0
        self.is_dragging = False
        
        # 配置文件路径
        self.config_path = Path.home() / ".hearthstone_tool_config.json"
        self.load_config()
        
    def setup_window(self):
        """设置窗口属性"""
        self.root.title("炉石拔线工具")
        self.root.geometry("160x80")
        self.root.resizable(False, False)
        self.root.attributes("-topmost", True)
        self.root.overrideredirect(True)
        
        # 设置窗口位置
        self.root.geometry("+100+100")
        
    def setup_ui(self):
        """设置UI界面"""
        # 主框架
        main_frame = tk.Frame(self.root, bg="#2c3e50")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # 状态显示
        self.status_var = tk.StringVar()
        self.status_var.set("就绪")
        self.status_label = tk.Label(
            main_frame, 
            textvariable=self.status_var,
            fg="white", 
            bg="#2c3e50",
            font=("Arial", 9)
        )
        self.status_label.pack(pady=2)
        
        # 按钮框架
        button_frame = tk.Frame(main_frame, bg="#2c3e50")
        button_frame.pack(fill=tk.X, padx=5, pady=2)
        
        # 拔线按钮
        self.disconnect_btn = tk.Button(
            button_frame,
            text="拔线",
            command=self.disconnect_network,
            bg="#e74c3c",
            fg="white",
            font=("Arial", 10, "bold"),
            relief=tk.FLAT,
            width=8
        )
        self.disconnect_btn.pack(side=tk.LEFT, padx=2)
        
        # 设置按钮
        self.settings_btn = tk.Button(
            button_frame,
            text="设置",
            command=self.show_settings,
            bg="#3498db",
            fg="white",
            font=("Arial", 9),
            relief=tk.FLAT,
            width=6
        )
        self.settings_btn.pack(side=tk.RIGHT, padx=2)
        
        # 进程状态指示器
        self.process_indicator = tk.Label(
            main_frame,
            text="●",
            fg="red",
            bg="#2c3e50",
            font=("Arial", 12)
        )
        self.process_indicator.pack(side=tk.BOTTOM, pady=1)
        
        # 绑定拖拽事件
        self.bind_drag_events(main_frame)
        
    def bind_drag_events(self, widget):
        """绑定窗口拖拽事件"""
        widget.bind("<Button-1>", self.start_drag)
        widget.bind("<B1-Motion>", self.do_drag)
        widget.bind("<ButtonRelease-1>", self.stop_drag)
        
        # 递归绑定子控件
        for child in widget.winfo_children():
            if isinstance(child, (tk.Label, tk.Frame)):
                self.bind_drag_events(child)
    
    def start_drag(self, event):
        """开始拖拽"""
        self.drag_start_x = event.x_root
        self.drag_start_y = event.y_root
        self.is_dragging = False
        
    def do_drag(self, event):
        """执行拖拽"""
        if abs(event.x_root - self.drag_start_x) > 5 or abs(event.y_root - self.drag_start_y) > 5:
            self.is_dragging = True
            x = self.root.winfo_x() + (event.x_root - self.drag_start_x)
            y = self.root.winfo_y() + (event.y_root - self.drag_start_y)
            self.root.geometry(f"+{x}+{y}")
            self.drag_start_x = event.x_root
            self.drag_start_y = event.y_root
    
    def stop_drag(self, event):
        """停止拖拽"""
        self.is_dragging = False
        
    def setup_keychain(self):
        """设置keychain密码管理"""
        self.keychain_service = "hearthstone-disconnect-tool"
        self.keychain_account = "sudo-password"
        
    def setup_shortcuts(self):
        """设置快捷键"""
        # 全局快捷键需要额外的库，这里先实现窗口内快捷键
        self.root.bind("<Control-d>", lambda e: self.disconnect_network())
        self.root.bind("<Control-q>", lambda e: self.quit_app())
        self.root.bind("<Escape>", lambda e: self.quit_app())
        
    def setup_process_monitor(self):
        """设置进程监控"""
        self.monitor_thread = threading.Thread(target=self.monitor_hearthstone, daemon=True)
        self.monitor_thread.start()
        
    def monitor_hearthstone(self):
        """监控炉石进程"""
        while True:
            try:
                # 检查炉石进程
                hearthstone_processes = []
                for proc in psutil.process_iter(['name', 'pid']):
                    try:
                        if 'hearthstone' in proc.info['name'].lower():
                            hearthstone_processes.append(proc)
                    except (psutil.NoSuchProcess, psutil.AccessDenied):
                        continue
                
                was_running = self.hearthstone_running
                self.hearthstone_running = len(hearthstone_processes) > 0
                
                if was_running != self.hearthstone_running:
                    self.root.after(0, self.update_process_indicator)
                    
            except Exception as e:
                print(f"进程监控错误: {e}")
                
            time.sleep(2)
    
    def update_process_indicator(self):
        """更新进程指示器"""
        if self.hearthstone_running:
            self.process_indicator.config(fg="green")
        else:
            self.process_indicator.config(fg="red")
            
    def get_password_from_keychain(self):
        """从keychain获取密码"""
        try:
            result = subprocess.run([
                "security", "find-generic-password",
                "-s", self.keychain_service,
                "-a", self.keychain_account,
                "-w"
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                return result.stdout.strip()
            else:
                return None
        except Exception as e:
            print(f"从keychain获取密码失败: {e}")
            return None
            
    def save_password_to_keychain(self, password):
        """保存密码到keychain"""
        try:
            # 先删除现有的
            subprocess.run([
                "security", "delete-generic-password",
                "-s", self.keychain_service,
                "-a", self.keychain_account
            ], capture_output=True)
            
            # 添加新的
            result = subprocess.run([
                "security", "add-generic-password",
                "-s", self.keychain_service,
                "-a", self.keychain_account,
                "-w", password
            ], capture_output=True, text=True)
            
            return result.returncode == 0
        except Exception as e:
            print(f"保存密码到keychain失败: {e}")
            return False
            
    def disconnect_network(self):
        """拔线操作"""
        if self.is_disconnecting:
            return
            
        if not self.hearthstone_running:
            messagebox.showwarning("警告", "炉石传说未运行")
            return
            
        self.is_disconnecting = True
        self.disconnect_btn.config(state=tk.DISABLED, text="拔线中...")
        self.status_var.set("正在拔线...")
        
        # 在新线程中执行
        threading.Thread(target=self._execute_disconnect, daemon=True).start()
        
    def _execute_disconnect(self):
        """执行拔线操作"""
        try:
            # 获取密码
            password = self.get_password_from_keychain()
            if not password:
                self.root.after(0, lambda: self.show_password_dialog())
                return
                
            # 构建命令
            command = f"""
            echo '{password}' | sudo -S littlesnitch rulegroup -e HearthStone && 
            sleep 0.5 && 
            echo '{password}' | sudo -S littlesnitch rulegroup -d HearthStone
            """
            
            # 执行命令
            result = subprocess.run(
                command, 
                shell=True, 
                capture_output=True, 
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                self.root.after(0, lambda: self.status_var.set("拔线成功"))
                print("拔线操作成功")
            else:
                self.root.after(0, lambda: self.status_var.set("拔线失败"))
                print(f"拔线失败: {result.stderr}")
                
        except subprocess.TimeoutExpired:
            self.root.after(0, lambda: self.status_var.set("操作超时"))
            print("拔线操作超时")
        except Exception as e:
            self.root.after(0, lambda: self.status_var.set("执行错误"))
            print(f"拔线操作错误: {e}")
        finally:
            # 恢复按钮状态
            time.sleep(3)
            self.root.after(0, self.reset_button_state)
            
    def reset_button_state(self):
        """重置按钮状态"""
        self.is_disconnecting = False
        self.disconnect_btn.config(state=tk.NORMAL, text="拔线")
        self.status_var.set("就绪")
        
    def show_password_dialog(self):
        """显示密码输入对话框"""
        dialog = tk.Toplevel(self.root)
        dialog.title("输入密码")
        dialog.geometry("300x150")
        dialog.resizable(False, False)
        dialog.attributes("-topmost", True)
        
        # 居中显示
        dialog.transient(self.root)
        dialog.grab_set()
        
        tk.Label(dialog, text="请输入管理员密码:", font=("Arial", 12)).pack(pady=10)
        
        password_var = tk.StringVar()
        password_entry = tk.Entry(dialog, textvariable=password_var, show="*", font=("Arial", 12))
        password_entry.pack(pady=10, padx=20, fill=tk.X)
        password_entry.focus()
        
        def save_password():
            password = password_var.get()
            if password:
                if self.save_password_to_keychain(password):
                    dialog.destroy()
                    # 重新执行拔线
                    threading.Thread(target=self._execute_disconnect, daemon=True).start()
                else:
                    messagebox.showerror("错误", "密码保存失败")
            else:
                messagebox.showwarning("警告", "请输入密码")
                
        def cancel():
            dialog.destroy()
            self.reset_button_state()
            
        button_frame = tk.Frame(dialog)
        button_frame.pack(pady=20)
        
        tk.Button(button_frame, text="保存", command=save_password, width=10).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="取消", command=cancel, width=10).pack(side=tk.LEFT, padx=5)
        
        # 绑定回车键
        password_entry.bind("<Return>", lambda e: save_password())
        
    def show_settings(self):
        """显示设置对话框"""
        settings = tk.Toplevel(self.root)
        settings.title("设置")
        settings.geometry("400x300")
        settings.resizable(False, False)
        settings.attributes("-topmost", True)
        settings.transient(self.root)
        settings.grab_set()
        
        notebook = ttk.Notebook(settings)
        notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # 基本设置
        basic_frame = ttk.Frame(notebook)
        notebook.add(basic_frame, text="基本设置")
        
        ttk.Label(basic_frame, text="规则组名称:").pack(pady=5)
        rule_group_var = tk.StringVar(value="HearthStone")
        ttk.Entry(basic_frame, textvariable=rule_group_var).pack(pady=5, fill=tk.X)
        
        ttk.Label(basic_frame, text="断线时间 (秒):").pack(pady=5)
        disconnect_time_var = tk.StringVar(value="0.5")
        ttk.Entry(basic_frame, textvariable=disconnect_time_var).pack(pady=5, fill=tk.X)
        
        # 快捷键设置
        hotkey_frame = ttk.Frame(notebook)
        notebook.add(hotkey_frame, text="快捷键")
        
        ttk.Label(hotkey_frame, text="快捷键说明:").pack(pady=10)
        ttk.Label(hotkey_frame, text="Ctrl+D: 执行拔线").pack(pady=2)
        ttk.Label(hotkey_frame, text="Ctrl+Q: 退出程序").pack(pady=2)
        ttk.Label(hotkey_frame, text="Esc: 退出程序").pack(pady=2)
        
        # 按钮
        button_frame = tk.Frame(settings)
        button_frame.pack(pady=10)
        
        def save_settings():
            config = {
                "rule_group": rule_group_var.get(),
                "disconnect_time": disconnect_time_var.get()
            }
            self.save_config(config)
            settings.destroy()
            
        tk.Button(button_frame, text="保存", command=save_settings, width=10).pack(side=tk.LEFT, padx=5)
        tk.Button(button_frame, text="取消", command=settings.destroy, width=10).pack(side=tk.LEFT, padx=5)
        
    def load_config(self):
        """加载配置"""
        try:
            if self.config_path.exists():
                with open(self.config_path, 'r') as f:
                    self.config = json.load(f)
            else:
                self.config = {
                    "rule_group": "HearthStone",
                    "disconnect_time": "0.5"
                }
        except Exception as e:
            print(f"加载配置失败: {e}")
            self.config = {
                "rule_group": "HearthStone", 
                "disconnect_time": "0.5"
            }
            
    def save_config(self, config):
        """保存配置"""
        try:
            self.config.update(config)
            with open(self.config_path, 'w') as f:
                json.dump(self.config, f, indent=2)
        except Exception as e:
            print(f"保存配置失败: {e}")
            
    def quit_app(self):
        """退出程序"""
        self.root.quit()
        
    def run(self):
        """运行程序"""
        try:
            self.root.mainloop()
        except KeyboardInterrupt:
            pass

def main():
    """主函数"""
    # 检查系统要求
    if sys.platform != "darwin":
        print("此工具仅支持macOS系统")
        sys.exit(1)
        
    # 检查Little Snitch
    if not os.path.exists("/usr/local/bin/littlesnitch"):
        print("错误: 未找到Little Snitch")
        print("请先安装Little Snitch: https://www.obdev.at/products/littlesnitch/index.html")
        sys.exit(1)
        
    # 创建并运行应用
    app = HearthstoneDisconnectTool()
    app.run()

if __name__ == "__main__":
    main()