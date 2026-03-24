import tkinter as tk
from tkinter import colorchooser
import time
import json
import os

CONFIG_FILE = "clock_config.json"

class FloatingClock:
    def __init__(self, root):
        self.root = root
        self.root.title("Floating Clock")
        
        # Determine background behavior (Windows specific)
        self.bg_color = '#000001'  # Almost black, used as transparent key on Windows
        
        self.root.configure(bg=self.bg_color)
        
        # Load config
        self.config = self.load_config()
        self.text_color = self.config.get('text_color', '#00FFFF')
        self.bg_alpha = self.config.get('bg_alpha', 0.0)
        self.geom = self.config.get('geometry', '350x150+100+100')
        
        self.root.geometry(self.geom)
        self.root.attributes("-topmost", True)
        self.root.overrideredirect(True)
        
        # Make the dark background transparent on Windows
        # (This makes it fully click-through and invisible)
        self.root.attributes("-transparentcolor", self.bg_color)
        
        # Variables for dragging
        self._offsetx = 0
        self._offsety = 0
        self.is_resizing = False
        
        # Frame to hold everything
        self.main_frame = tk.Frame(root, bg=self.bg_color)
        self.main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Labels
        self.time_label = tk.Label(self.main_frame, text="", bg=self.bg_color, fg=self.text_color)
        self.time_label.pack(expand=True, fill=tk.BOTH)
        
        self.date_label = tk.Label(self.main_frame, text="", bg=self.bg_color, fg=self.text_color)
        self.date_label.pack(expand=True, fill=tk.BOTH)
        
        # Controls Frame (Hidden by default)
        self.controls_frame = tk.Frame(self.main_frame, bg='#333333')
        
        # Close Button
        self.close_btn = tk.Button(self.main_frame, text="✕", command=self.close_app, 
                                   bg='#222222', fg='white', bd=0, highlightthickness=0,
                                   activebackground='#444444', activeforeground='white')
        
        # Color Picker Button
        self.color_btn = tk.Button(self.main_frame, text="🎨", command=self.choose_color, 
                                   bg='#222222', fg='white', bd=0, highlightthickness=0,
                                   activebackground='#444444', activeforeground='white')
                                   
        # Resize Handle
        self.resize_label = tk.Label(self.main_frame, text="↘", bg='#222222', fg='white', cursor="bottom_right_corner")
        
        # Bindings for hover
        self.main_frame.bind("<Enter>", self.on_hover)
        self.main_frame.bind("<Leave>", self.on_leave)
        self.time_label.bind("<Enter>", self.on_hover)
        self.date_label.bind("<Enter>", self.on_hover)
        
        # Bindings for drag
        for widget in (self.main_frame, self.time_label, self.date_label):
            widget.bind("<Button-1>", self.click_window)
            widget.bind("<B1-Motion>", self.drag_window)
            widget.bind("<ButtonRelease-1>", self.save_position)
            
        # Bindings for resize
        self.resize_label.bind("<Button-1>", self.resize_start)
        self.resize_label.bind("<B1-Motion>", self.resize_motion)
        self.resize_label.bind("<ButtonRelease-1>", self.save_position)

        self.update_time()
        self.update_fonts(None)  # Initial font sizing
        self.root.bind("<Configure>", self.update_fonts)

    def load_config(self):
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception:
                return {}
        return {}

    def save_config(self):
        self.config['text_color'] = self.text_color
        self.config['geometry'] = self.root.geometry()
        try:
            with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
                json.dump(self.config, f)
        except Exception as e:
            print("Failed to save config:", e)

    def click_window(self, event):
        self._offsetx = event.x
        self._offsety = event.y

    def drag_window(self, event):
        if self.is_resizing: return
        x = self.root.winfo_x() - self._offsetx + event.x
        y = self.root.winfo_y() - self._offsety + event.y
        self.root.geometry(f"+{x}+{y}")

    def resize_start(self, event):
        self.is_resizing = True

    def resize_motion(self, event):
        x = self.root.winfo_pointerx() - self.root.winfo_rootx()
        y = self.root.winfo_pointery() - self.root.winfo_rooty()
        # Enforce minimum size
        x = max(150, x)
        y = max(80, y)
        self.root.geometry(f"{x}x{y}")

    def save_position(self, event):
        self.is_resizing = False
        self.save_config()

    def update_time(self):
        current_time = time.strftime('%H:%M:%S')
        current_date = time.strftime('%Y年%m月%d日')
        
        self.time_label.config(text=current_time)
        self.date_label.config(text=current_date)
        
        self.root.after(1000, self.update_time)

    def update_fonts(self, event):
        # Calculate size depending on window height
        h = self.root.winfo_height()
        time_size = max(12, int(h * 0.35))
        date_size = max(8, int(h * 0.15))
        
        self.time_label.config(font=("Consolas", time_size, "bold"))
        self.date_label.config(font=("Microsoft YaHei UI", date_size, "bold"))

    def on_hover(self, event):
        # Change background color slightly to make window visible
        self.main_frame.config(bg="#222222")
        self.time_label.config(bg="#222222")
        self.date_label.config(bg="#222222")
        self.root.attributes("-transparentcolor", "none") # Clear transparency color so background shows
        
        # Show controls
        h, w = self.root.winfo_height(), self.root.winfo_width()
        self.close_btn.place(x=w-25, y=5, width=20, height=20)
        self.color_btn.place(x=5, y=5, width=25, height=25)
        self.resize_label.place(x=w-16, y=h-16, width=16, height=16)

    def on_leave(self, event):
        # Only hide if mouse actually left the app window
        if event.widget == self.main_frame or event.widget == self.time_label or event.widget == self.date_label:
            # Check root pointer coordinates
            px, py = self.root.winfo_pointerxy()
            rx, ry = self.root.winfo_rootx(), self.root.winfo_rooty()
            rw, rh = self.root.winfo_width(), self.root.winfo_height()
            
            # If pointer outside of widget coords bounds
            if not (rx <= px <= rx + rw and ry <= py <= ry + rh):
                # Hide controls back
                self.main_frame.config(bg=self.bg_color)
                self.time_label.config(bg=self.bg_color)
                self.date_label.config(bg=self.bg_color)
                self.root.attributes("-transparentcolor", self.bg_color) # Reapply transparent color
                
                self.close_btn.place_forget()
                self.color_btn.place_forget()
                self.resize_label.place_forget()

    def choose_color(self):
        color_code = colorchooser.askcolor(title="选择文字颜色", initialcolor=self.text_color)
        if color_code[1]:
            self.text_color = color_code[1]
            self.time_label.config(fg=self.text_color)
            self.date_label.config(fg=self.text_color)
            self.save_config()

    def close_app(self):
        self.save_config()
        self.root.destroy()

if __name__ == "__main__":
    root = tk.Tk()
    app = FloatingClock(root)
    root.mainloop()
