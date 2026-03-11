package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/lxn/walk"
	. "github.com/lxn/walk/declarative"
	"github.com/lxn/win"
	"golang.org/x/sys/windows/registry"
)

// App holds the application state
type App struct {
	mainWindow   *walk.MainWindow
	outputArea   *walk.TextEdit
	startBtn     *walk.PushButton
	stopBtn      *walk.PushButton
	restartBtn   *walk.PushButton
	gatewayCmd   *exec.Cmd
	dashboardCmd *exec.Cmd
	mu           sync.Mutex
	running      bool
	stopChan     chan struct{}
	ni           *walk.NotifyIcon
	autoStartCb  *walk.CheckBox
}

const registryRunPath = `Software\Microsoft\Windows\CurrentVersion\Run`
const registryAppName = `OpenClawController`

func main() {
	app := &App{}
	app.run()
}

func (a *App) run() {
	MainWindow{
		AssignTo: &a.mainWindow,
		Title:    "OpenClaw Controller",
		MinSize:  Size{Width: 300, Height: 200},
		Size:     Size{Width: 300, Height: 200},
		Layout:   VBox{MarginsZero: false, Margins: Margins{Left: 6, Top: 6, Right: 6, Bottom: 6}},
		Children: []Widget{
			TextEdit{
				AssignTo: &a.outputArea,
				ReadOnly: true,
				VScroll:  true,
			},
			Composite{
				MaxSize: Size{Height: 36},
				Layout:  HBox{MarginsZero: true, SpacingZero: false},
				Children: []Widget{
					CheckBox{
						AssignTo: &a.autoStartCb,
						Text:     "开机启动",
						OnCheckedChanged: func() {
							a.setAutoStart(a.autoStartCb.Checked())
						},
					},
					HSpacer{},
					PushButton{
						AssignTo:  &a.startBtn,
						Text:      "启动",
						OnClicked: a.onStart,
					},
					PushButton{
						AssignTo:  &a.stopBtn,
						Text:      "停止",
						OnClicked: a.onStop,
					},
					PushButton{
						AssignTo:  &a.restartBtn,
						Text:      "重启",
						OnClicked: a.onRestart,
					},
				},
			},
		},
	}.Create()

	// Add NotifyIcon functionality using system icon
	icon, err := walk.NewIconFromSysDLL("shell32", 3) // Typical generic folder/app icon
	if err == nil {
		a.ni, err = walk.NewNotifyIcon(a.mainWindow)
		if err == nil {
			a.ni.SetIcon(icon)
			a.ni.SetToolTip("OpenClaw Controller")

			// When icon is clicked, restore the window
			a.ni.MouseDown().Attach(func(x, y int, button walk.MouseButton) {
				if button == walk.LeftButton {
					a.restoreWindow()
				}
			})

			// Add context menu to system tray
			showAction := walk.NewAction()
			showAction.SetText("显示")
			showAction.Triggered().Attach(a.restoreWindow)
			a.ni.ContextMenu().Actions().Add(showAction)

			autoStartAction := walk.NewAction()
			autoStartAction.SetCheckable(true)
			autoStartAction.SetText("开机启动")
			autoStartAction.SetChecked(a.checkAutoStart())
			autoStartAction.Triggered().Attach(func() {
				checked := autoStartAction.Checked()
				a.setAutoStart(checked)
				a.autoStartCb.SetChecked(checked)
			})
			a.ni.ContextMenu().Actions().Add(autoStartAction)

			exitAction := walk.NewAction()
			exitAction.SetText("退出")
			exitAction.Triggered().Attach(func() {
				a.stopServices()
				walk.App().Exit(0)
			})
			a.ni.ContextMenu().Actions().Add(exitAction)
		}
	}

	// Handle window minimize
	a.mainWindow.BoundsChanged().Attach(func() {
		if win.IsIconic(a.mainWindow.Handle()) {
			a.mainWindow.SetVisible(false)
			if a.ni != nil {
				a.ni.SetVisible(true)
			}
		}
	})

	// Handle window closing down to stop background processes cleanly
	a.mainWindow.Closing().Attach(func(canceled *bool, reason walk.CloseReason) {
		a.stopServices()
		if a.ni != nil {
			a.ni.Dispose()
		}
	})

	// Check initial auto start state
	a.mainWindow.Starting().Attach(func() {
		autoStartEnabled := a.checkAutoStart()
		a.autoStartCb.SetChecked(autoStartEnabled)

		// Check if we were launched with a flag indicating we are starting from boot.
		// For now we don't have arguments, but if it's generally auto-started it probably shouldn't be visible.
		// However, it's easier to just start the services and optionally hide if started silently.
		// Let's just auto-start services if the app starts.
		a.onStart()
	})

	a.mainWindow.Run()
}

func (a *App) restoreWindow() {
	if a.ni != nil {
		a.ni.SetVisible(false)
	}
	a.mainWindow.SetVisible(true)
	win.ShowWindow(a.mainWindow.Handle(), win.SW_RESTORE)
	win.SetForegroundWindow(a.mainWindow.Handle())
}

// appendOutput safely appends text to the output area from any goroutine
func (a *App) appendOutput(text string) {
	a.mainWindow.Synchronize(func() {
		current := a.outputArea.Text()
		if current != "" {
			current += "\r\n"
		}
		current += text
		a.outputArea.SetText(current)
		// Auto-scroll to bottom
		a.outputArea.SetTextSelection(len(current), len(current))
	})
}

// pipeOutput reads from a reader and appends each line to the output area
func (a *App) pipeOutput(reader io.Reader, prefix string) {
	scanner := bufio.NewScanner(reader)
	for scanner.Scan() {
		line := scanner.Text()
		if prefix != "" {
			a.appendOutput(fmt.Sprintf("[%s] %s", prefix, line))
		} else {
			a.appendOutput(line)
		}
	}
}

// setButtonsState enables/disables buttons based on running state
func (a *App) setButtonsState(isRunning bool) {
	a.mainWindow.Synchronize(func() {
		a.startBtn.SetEnabled(!isRunning)
		a.stopBtn.SetEnabled(isRunning)
		a.restartBtn.SetEnabled(isRunning)
	})
}

// onStart handles the start button click
func (a *App) onStart() {
	a.mu.Lock()
	if a.running {
		a.mu.Unlock()
		return
	}
	a.running = true
	a.stopChan = make(chan struct{})
	a.mu.Unlock()

	a.setButtonsState(true)
	a.appendOutput("========== 启动服务 ==========")

	go a.startServices()
}

// startServices starts gateway then dashboard
func (a *App) startServices() {
	// Start gateway
	a.appendOutput("[系统] 正在启动 Gateway (port 18789)...")

	a.mu.Lock()
	a.gatewayCmd = exec.Command("cmd", "/c", "openclaw", "gateway", "--port", "18789")
	a.gatewayCmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}
	a.mu.Unlock()

	gatewayStdout, err := a.gatewayCmd.StdoutPipe()
	if err != nil {
		a.appendOutput(fmt.Sprintf("[错误] 获取 Gateway stdout 失败: %v", err))
		a.resetState()
		return
	}
	gatewayStderr, err := a.gatewayCmd.StderrPipe()
	if err != nil {
		a.appendOutput(fmt.Sprintf("[错误] 获取 Gateway stderr 失败: %v", err))
		a.resetState()
		return
	}

	if err := a.gatewayCmd.Start(); err != nil {
		a.appendOutput(fmt.Sprintf("[错误] 启动 Gateway 失败: %v", err))
		a.resetState()
		return
	}
	a.appendOutput("[系统] Gateway 进程已启动")

	// Read gateway output in background
	go a.pipeOutput(gatewayStdout, "Gateway")
	go a.pipeOutput(gatewayStderr, "Gateway")

	// Wait for gateway to be ready (3 seconds)
	select {
	case <-a.stopChan:
		a.appendOutput("[系统] 启动被中断")
		return
	case <-time.After(3 * time.Second):
	}

	// Check if gateway is still running
	a.mu.Lock()
	if !a.running {
		a.mu.Unlock()
		return
	}
	a.mu.Unlock()

	// Start dashboard
	a.appendOutput("[系统] 正在启动 Dashboard...")

	a.mu.Lock()
	a.dashboardCmd = exec.Command("cmd", "/c", "openclaw", "dashboard")
	a.dashboardCmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}
	a.mu.Unlock()

	dashStdout, err := a.dashboardCmd.StdoutPipe()
	if err != nil {
		a.appendOutput(fmt.Sprintf("[错误] 获取 Dashboard stdout 失败: %v", err))
		return
	}
	dashStderr, err := a.dashboardCmd.StderrPipe()
	if err != nil {
		a.appendOutput(fmt.Sprintf("[错误] 获取 Dashboard stderr 失败: %v", err))
		return
	}

	if err := a.dashboardCmd.Start(); err != nil {
		a.appendOutput(fmt.Sprintf("[错误] 启动 Dashboard 失败: %v", err))
		return
	}
	a.appendOutput("[系统] Dashboard 进程已启动")
	a.appendOutput("[系统] ✓ 所有服务已启动")

	// Read dashboard output in background
	go a.pipeOutput(dashStdout, "Dashboard")
	go a.pipeOutput(dashStderr, "Dashboard")

	// Monitor processes in background
	go a.monitorProcess(a.gatewayCmd, "Gateway")
	go a.monitorProcess(a.dashboardCmd, "Dashboard")
}

// monitorProcess watches a process and reports when it exits
func (a *App) monitorProcess(cmd *exec.Cmd, name string) {
	if cmd == nil {
		return
	}
	err := cmd.Wait()
	a.mu.Lock()
	isRunning := a.running
	a.mu.Unlock()

	if isRunning {
		if err != nil {
			a.appendOutput(fmt.Sprintf("[警告] %s 进程异常退出: %v", name, err))
		} else {
			a.appendOutput(fmt.Sprintf("[信息] %s 进程已退出", name))
		}
	}
}

// onStop handles the stop button click
func (a *App) onStop() {
	a.mu.Lock()
	if !a.running {
		a.mu.Unlock()
		return
	}
	a.mu.Unlock()

	a.appendOutput("========== 停止服务 ==========")
	a.stopServices()
}

// stopServices kills both processes
func (a *App) stopServices() {
	a.mu.Lock()
	if !a.running {
		a.mu.Unlock()
		return
	}

	// Signal stop
	select {
	case <-a.stopChan:
	default:
		close(a.stopChan)
	}

	// Kill dashboard first
	if a.dashboardCmd != nil && a.dashboardCmd.Process != nil {
		a.mu.Unlock()
		a.appendOutput("[系统] 正在停止 Dashboard...")
		if err := killProcess(a.dashboardCmd); err != nil {
			a.appendOutput(fmt.Sprintf("[警告] 停止 Dashboard 时出错: %v", err))
		} else {
			a.appendOutput("[系统] Dashboard 已停止")
		}
		a.mu.Lock()
		a.dashboardCmd = nil
	}

	// Kill gateway
	if a.gatewayCmd != nil && a.gatewayCmd.Process != nil {
		a.mu.Unlock()
		a.appendOutput("[系统] 正在停止 Gateway...")
		if err := killProcess(a.gatewayCmd); err != nil {
			a.appendOutput(fmt.Sprintf("[警告] 停止 Gateway 时出错: %v", err))
		} else {
			a.appendOutput("[系统] Gateway 已停止")
		}
		a.mu.Lock()
		a.gatewayCmd = nil
	}

	a.running = false
	a.mu.Unlock()

	a.appendOutput("[系统] ✓ 所有服务已停止")
	a.setButtonsState(false)
}

// resetState resets to stopped state
func (a *App) resetState() {
	a.mu.Lock()
	a.running = false
	a.mu.Unlock()
	a.setButtonsState(false)
}

// onRestart handles the restart button click
func (a *App) onRestart() {
	a.appendOutput("========== 重启服务 ==========")
	go func() {
		a.stopServices()
		time.Sleep(1 * time.Second)
		a.mainWindow.Synchronize(func() {
			a.onStart()
		})
	}()
}

// killProcess kills a process and its children on Windows
func killProcess(cmd *exec.Cmd) error {
	if cmd == nil || cmd.Process == nil {
		return nil
	}
	// Use taskkill to kill the process tree on Windows
	kill := exec.Command("taskkill", "/T", "/F", "/PID",
		fmt.Sprintf("%d", cmd.Process.Pid))
	kill.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}
	output, err := kill.CombinedOutput()
	if err != nil {
		// Fallback: direct kill
		cmd.Process.Kill()
		if strings.Contains(string(output), "not found") {
			return nil // Process already exited
		}
		return err
	}
	return nil
}

// checkAutoStart checks if the app is configured to run at startup
func (a *App) checkAutoStart() bool {
	k, err := registry.OpenKey(registry.CURRENT_USER, registryRunPath, registry.QUERY_VALUE)
	if err != nil {
		return false
	}
	defer k.Close()

	val, _, err := k.GetStringValue(registryAppName)
	if err != nil {
		return false
	}

	exePath, err := os.Executable()
	if err != nil {
		return false
	}

	return strings.EqualFold(val, "\""+exePath+"\"")
}

// setAutoStart modifies the registry to run the app at startup
func (a *App) setAutoStart(enable bool) {
	k, err := registry.OpenKey(registry.CURRENT_USER, registryRunPath, registry.SET_VALUE)
	if err != nil {
		a.appendOutput(fmt.Sprintf("[系统] 修改开机启动失败: 无法打开注册表项: %v", err))
		return
	}
	defer k.Close()

	if enable {
		exePath, err := os.Executable()
		if err != nil {
			a.appendOutput(fmt.Sprintf("[系统] 修改开机启动失败: 无法获取可执行文件路径: %v", err))
			return
		}
		err = k.SetStringValue(registryAppName, "\""+exePath+"\"")
		if err != nil {
			a.appendOutput(fmt.Sprintf("[系统] 设置开机启动失败: %v", err))
		} else {
			a.appendOutput("[系统] 开机启动已开启")
		}
	} else {
		err = k.DeleteValue(registryAppName)
		if err != nil && err != registry.ErrNotExist {
			a.appendOutput(fmt.Sprintf("[系统] 取消开机启动失败: %v", err))
		} else {
			a.appendOutput("[系统] 开机启动已关闭")
		}
	}
}
