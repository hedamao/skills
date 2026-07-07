import sys
import subprocess
import threading
import objc
from Foundation import *
from AppKit import *
from PyObjCTools import AppHelper

class AppState(NSObject):
    def init(self):
        self = objc.super(AppState, self).init()
        if self:
            self.command = ""
            self.interval = 5.0
            self.isLooping = False
            self.isRunning = False
            self.bgOpacity = 0.8
            self.textColor = NSColor.greenColor()
            self.timer = None
            self.process = None
            self.output_callback = None
        return self

    @objc.python_method
    def start_command(self):
        if not self.command.strip(): return
        self.isRunning = True
        self.run_once()
        if self.isLooping:
            self.timer = NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_(
                self.interval, self, objc.selector(self.timerTick_, signature=b'v@:@'), None, True
            )

    def timerTick_(self, timer):
        self.run_once()

    @objc.python_method
    def stop_command(self):
        self.isRunning = False
        if self.timer: 
            self.timer.invalidate()
            self.timer = None
        if self.process:
            self.process.terminate()
            self.process = None

    @objc.python_method
    def run_once(self):
        def worker():
            try:
                proc = subprocess.Popen(['/bin/sh', '-c', self.command], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
                self.process = proc
                output, _ = proc.communicate()
            except Exception as e:
                output = f"Error: {e}\n"
            AppHelper.callAfter(self.appendOutput_, output)
        
        t = threading.Thread(target=worker)
        t.daemon = True
        t.start()

    def appendOutput_(self, text):
        if self.output_callback: 
            self.output_callback(text, self.isLooping)
        if not self.isLooping: 
            self.isRunning = False

class AppDelegate(NSObject):
    def applicationDidFinishLaunching_(self, notification):
        print("App finished launching, setting up window...")
        # Mirror FloatingClock's activation policy
        NSApp.setActivationPolicy_(1) # NSApplicationActivationPolicyAccessory
        NSApp.activateIgnoringOtherApps_(True)
        
        # Create Window - StyleMask mirrored from FloatingClock
        rect = NSMakeRect(100, 500, 500, 350)
        styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskFullSizeContentView | NSWindowStyleMaskResizable
        
        self.window = NSWindow.alloc().initWithContentRect_styleMask_backing_defer_(
            rect, styleMask, NSBackingStoreBuffered, False
        )
        self.window.center()
        self.window.setTitle_("FloatingTask")
        
        # Mirroring FloatingClock's specific level (NSMainMenuWindowLevel + 2)
        # On macOS, NSMainMenuWindowLevel is 24
        self.window.setLevel_(26)
        
        # Adding behaviors needed for Full Screen overlay
        self.window.setCollectionBehavior_(
            NSWindowCollectionBehaviorCanJoinAllSpaces | 
            NSWindowCollectionBehaviorFullScreenAuxiliary
        )
        self.window.setHidesOnDeactivate_(False)
        self.window.setCanHide_(False)
        self.window.setIsMovableByWindowBackground_(True)
        
        # Transparency
        self.window.setOpaque_(False)
        self.window.setBackgroundColor_(NSColor.blackColor().colorWithAlphaComponent_(0.8))
        self.window.setTitleVisibility_(1) # NSWindowTitleHidden
        self.window.setTitlebarAppearsTransparent_(True)

        contentView = NSView.alloc().initWithFrame_(rect)
        contentView.setAutoresizesSubviews_(True)
        self.window.setContentView_(contentView)

        self.state = AppState.alloc().init()
        self.buildUI(contentView, rect)

        self.window.makeKeyAndOrderFront_(None)
        print("Window setup complete and made front.")

    @objc.python_method
    def buildUI(self, view, rect):
        h = rect.size.height
        w = rect.size.width

        # Command Input
        self.cmdInput = NSTextField.alloc().initWithFrame_(NSMakeRect(20, h - 40, w - 120, 24))
        self.cmdInput.setPlaceholderString_("Enter bash command...")
        self.cmdInput.setAutoresizingMask_(NSViewWidthSizable | NSViewMinYMargin)
        view.addSubview_(self.cmdInput)

        # Run Button
        self.runBtn = NSButton.alloc().initWithFrame_(NSMakeRect(w - 90, h - 45, 70, 32))
        self.runBtn.setTitle_("Run")
        self.runBtn.setBezelStyle_(NSRoundedBezelStyle)
        self.runBtn.setTarget_(self)
        self.runBtn.setAction_(objc.selector(self.runStopClicked_, signature=b'v@:@'))
        self.runBtn.setAutoresizingMask_(NSViewMinXMargin | NSViewMinYMargin)
        view.addSubview_(self.runBtn)

        # Loop Checkbox
        self.loopCheck = NSButton.alloc().initWithFrame_(NSMakeRect(20, h - 75, 60, 24))
        self.loopCheck.setButtonType_(NSSwitchButton)
        self.loopCheck.setTitle_("Loop")
        self.loopCheck.setAutoresizingMask_(NSViewMinYMargin)
        view.addSubview_(self.loopCheck)

        # Interval Input
        self.intervalInput = NSTextField.alloc().initWithFrame_(NSMakeRect(85, h - 75, 40, 24))
        self.intervalInput.setStringValue_("5")
        self.intervalInput.setAutoresizingMask_(NSViewMinYMargin)
        view.addSubview_(self.intervalInput)

        # Color Well
        self.colorWell = NSColorWell.alloc().initWithFrame_(NSMakeRect(140, h - 75, 44, 24))
        self.colorWell.setColor_(NSColor.greenColor())
        self.colorWell.setTarget_(self)
        self.colorWell.setAction_(objc.selector(self.colorChanged_, signature=b'v@:@'))
        self.colorWell.setAutoresizingMask_(NSViewMinYMargin)
        view.addSubview_(self.colorWell)

        # Opacity Slider
        self.slider = NSSlider.alloc().initWithFrame_(NSMakeRect(200, h - 75, 100, 24))
        self.slider.setMinValue_(0.1)
        self.slider.setMaxValue_(1.0)
        self.slider.setFloatValue_(0.8)
        self.slider.setTarget_(self)
        self.slider.setAction_(objc.selector(self.opacityChanged_, signature=b'v@:@'))
        self.slider.setAutoresizingMask_(NSViewMinYMargin)
        view.addSubview_(self.slider)

        # Output TextView (Scrollable)
        scrollView = NSScrollView.alloc().initWithFrame_(NSMakeRect(20, 20, w - 40, h - 110))
        scrollView.setHasVerticalScroller_(True)
        scrollView.setAutoresizingMask_(NSViewWidthSizable | NSViewHeightSizable)
        
        cSize = scrollView.contentSize()
        self.textView = NSTextView.alloc().initWithFrame_(NSMakeRect(0, 0, cSize.width, cSize.height))
        self.textView.setMinSize_(NSMakeSize(0.0, cSize.height))
        self.textView.setMaxSize_(NSMakeSize(10000.0, 10000.0))
        self.textView.setVerticallyResizable_(True)
        self.textView.setHorizontallyResizable_(False)
        self.textView.setAutoresizingMask_(NSViewWidthSizable)
        self.textView.textContainer().setContainerSize_(NSMakeSize(cSize.width, 10000.0))
        self.textView.textContainer().setWidthTracksTextView_(True)
        self.textView.setEditable_(False)
        self.textView.setBackgroundColor_(NSColor.clearColor())
        self.textView.setTextColor_(NSColor.greenColor())
        self.textView.setFont_(NSFont.monospacedSystemFontOfSize_weight_(12, 0.0))

        scrollView.setDocumentView_(self.textView)
        view.addSubview_(scrollView)

        self.state.output_callback = self.handle_output

    def runStopClicked_(self, sender):
        if self.state.isRunning:
            self.state.stop_command()
            self.runBtn.setTitle_("Run")
        else:
            self.state.command = self.cmdInput.stringValue()
            self.state.isLooping = (self.loopCheck.state() == 1)
            try:
                self.state.interval = float(self.intervalInput.stringValue())
            except:
                self.state.interval = 5.0
            
            if not self.state.isLooping:
                self.textView.setString_("")
            
            self.state.start_command()
            self.runBtn.setTitle_("Stop")

    @objc.python_method
    def handle_output(self, text, isLooping):
        if isLooping:
            cur = self.textView.string()
            if len(cur) > 20000: cur = cur[-10000:]
            self.textView.setString_(cur + text)
        else:
            self.textView.setString_(text)
            self.runBtn.setTitle_("Run")
        self.textView.scrollToEndOfDocument_(None)

    def opacityChanged_(self, sender):
        val = sender.floatValue()
        self.window.setBackgroundColor_(NSColor.blackColor().colorWithAlphaComponent_(val))

    def colorChanged_(self, sender):
        self.textView.setTextColor_(sender.color())

if __name__ == '__main__':
    app = NSApplication.sharedApplication()
    delegate = AppDelegate.alloc().init()
    app.setDelegate_(delegate)
    # Set activation policy to accessory BEFORE running
    app.setActivationPolicy_(1) 
    AppHelper.runEventLoop()
