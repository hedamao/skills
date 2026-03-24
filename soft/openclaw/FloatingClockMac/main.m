#import <Cocoa/Cocoa.h>

@interface HoverView : NSView
@property (copy) void (^mouseExitedBlock)(void);
@property (copy) void (^mouseEnteredBlock)(void);
@end

@implementation HoverView

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    for (NSTrackingArea *area in self.trackingAreas) {
        [self removeTrackingArea:area];
    }
    NSTrackingAreaOptions options = NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited | NSTrackingInVisibleRect;
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:self.bounds options:options owner:self userInfo:nil];
    [self addTrackingArea:area];
}

- (void)mouseEntered:(NSEvent *)event {
    if (self.mouseEnteredBlock) self.mouseEnteredBlock();
}

- (void)mouseExited:(NSEvent *)event {
    if (self.mouseExitedBlock) self.mouseExitedBlock();
}

// Intercept clicks to allow completely transparent areas to drag the window
- (NSView *)hitTest:(NSPoint)point {
    NSView *hit = [super hitTest:point];
    if (hit) return hit;
    if (NSPointInRect(point, self.bounds)) return self;
    return nil;
}

- (BOOL)mouseDownCanMoveWindow {
    return YES;
}

@end


@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property (strong) NSWindow *window;
@property (strong) NSTextField *timeLabel;
@property (strong) NSTextField *dateLabel;
@property (strong) NSColorWell *colorWell;
@property (strong) NSTimer *timer;
@property (strong) NSButton *closeButton;
@property (strong) NSTextField *resizeHint;
@property (strong) NSSlider *alphaSlider;
@property (assign) CGFloat bgAlpha;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSRect frame = NSMakeRect(0, 0, 350, 150);
    NSString *savedFrame = [[NSUserDefaults standardUserDefaults] stringForKey:@"WindowFrame"];
    if (savedFrame) {
        frame = NSRectFromString(savedFrame);
    }
    
    NSUInteger styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskFullSizeContentView | NSWindowStyleMaskResizable;
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:styleMask
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    self.window.delegate = self;
    self.window.titlebarAppearsTransparent = YES;
    self.window.titleVisibility = NSWindowTitleHidden;
    [[self.window standardWindowButton:NSWindowCloseButton] setHidden:YES];
    [[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    
    self.window.movableByWindowBackground = YES;
    self.window.opaque = NO;
    
    self.bgAlpha = 0.0;
    NSNumber *alphaNum = [[NSUserDefaults standardUserDefaults] objectForKey:@"BackgroundAlpha"];
    if (alphaNum) {
        self.bgAlpha = [alphaNum doubleValue];
    }
    self.window.backgroundColor = [NSColor colorWithWhite:0.0 alpha:self.bgAlpha];
    self.window.hasShadow = NO;
    
    // 固定在所有屏幕空间，不随桌面切换而移动
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorTransient;
    
    self.window.level = NSMainMenuWindowLevel + 2;
    [NSColorPanel sharedColorPanel].level = NSMainMenuWindowLevel + 3;
    
    HoverView *contentView = [[HoverView alloc] initWithFrame:frame];
    contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.window.contentView = contentView;
    
    // Close Button (Top Right)
    self.closeButton = [[NSButton alloc] initWithFrame:NSMakeRect(frame.size.width - 25, frame.size.height - 25, 20, 20)];
    self.closeButton.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin;
    [self.closeButton setTitle:@"✕"];
    [self.closeButton setBezelStyle:NSBezelStyleCircular];
    [self.closeButton setTarget:self];
    [self.closeButton setAction:@selector(closeApp)];
    self.closeButton.alphaValue = 0.0;
    [contentView addSubview:self.closeButton];
    
    // Color Well (Bottom Left)
    self.colorWell = [[NSColorWell alloc] initWithFrame:NSMakeRect(10, 10, 30, 30)];
    self.colorWell.autoresizingMask = NSViewMaxXMargin | NSViewMaxYMargin;
    self.colorWell.alphaValue = 0.0;
    [self.colorWell setAction:@selector(colorChanged:)];
    [self.colorWell setTarget:self];
    [contentView addSubview:self.colorWell];
    
    // Alpha Slider (Bottom Left, next to Color Well)
    self.alphaSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(50, 15, 80, 20)];
    self.alphaSlider.autoresizingMask = NSViewMaxXMargin | NSViewMaxYMargin;
    self.alphaSlider.minValue = 0.0;
    self.alphaSlider.maxValue = 1.0;
    self.alphaSlider.doubleValue = self.bgAlpha;
    self.alphaSlider.alphaValue = 0.0;
    [self.alphaSlider setTarget:self];
    [self.alphaSlider setAction:@selector(alphaChanged:)];
    [contentView addSubview:self.alphaSlider];
    
    // Resize Hint Indicator (Bottom Right)
    self.resizeHint = [[NSTextField alloc] initWithFrame:NSMakeRect(frame.size.width - 20, 0, 20, 20)];
    self.resizeHint.autoresizingMask = NSViewMinXMargin | NSViewMaxYMargin; // Sticks to bottom right
    self.resizeHint.editable = NO;
    self.resizeHint.selectable = NO;
    self.resizeHint.bezeled = NO;
    self.resizeHint.drawsBackground = NO;
    self.resizeHint.stringValue = @"↘";
    self.resizeHint.textColor = [NSColor whiteColor];
    self.resizeHint.font = [NSFont systemFontOfSize:14];
    self.resizeHint.alphaValue = 0.0;
    [contentView addSubview:self.resizeHint];
    
    // Restore Color
    NSColor *textColor = [NSColor cyanColor];
    NSData *colorData = [[NSUserDefaults standardUserDefaults] dataForKey:@"TextColor"];
    if (colorData) {
        NSColor *unarchivedColor = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:colorData error:nil];
        if (unarchivedColor) {
            textColor = unarchivedColor;
        }
    }
    self.colorWell.color = textColor;
    
    // Time Label
    self.timeLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
    self.timeLabel.editable = NO;
    self.timeLabel.selectable = NO;
    self.timeLabel.bezeled = NO;
    self.timeLabel.drawsBackground = NO;
    self.timeLabel.alignment = NSTextAlignmentCenter;
    self.timeLabel.textColor = textColor;
    [contentView addSubview:self.timeLabel];
    
    // Date Label
    self.dateLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
    self.dateLabel.editable = NO;
    self.dateLabel.selectable = NO;
    self.dateLabel.bezeled = NO;
    self.dateLabel.drawsBackground = NO;
    self.dateLabel.alignment = NSTextAlignmentCenter;
    self.dateLabel.textColor = textColor;
    [contentView addSubview:self.dateLabel];
    
    // Setup Hover actions
    __weak typeof(self) weakSelf = self;
    contentView.mouseEnteredBlock = ^{
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.2;
            weakSelf.window.animator.backgroundColor = [NSColor colorWithWhite:0.2 alpha:MAX(0.4, weakSelf.bgAlpha + 0.1)];
            weakSelf.window.hasShadow = YES;
            weakSelf.closeButton.animator.alphaValue = 1.0;
            weakSelf.colorWell.animator.alphaValue = 1.0;
            weakSelf.resizeHint.animator.alphaValue = 1.0;
            weakSelf.alphaSlider.animator.alphaValue = 1.0;
        }];
    };
    
    contentView.mouseExitedBlock = ^{
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.3;
            weakSelf.window.animator.backgroundColor = [NSColor colorWithWhite:0.0 alpha:weakSelf.bgAlpha];
            weakSelf.window.hasShadow = NO;
            weakSelf.closeButton.animator.alphaValue = 0.0;
            if (![weakSelf.colorWell isActive]) {
                weakSelf.colorWell.animator.alphaValue = 0.0;
            }
            weakSelf.resizeHint.animator.alphaValue = 0.0;
            weakSelf.alphaSlider.animator.alphaValue = 0.0;
        }];
    };
    
    [self updateFonts];
    [self updateLayout];
    [self updateTime];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    
    if (!savedFrame) {
        [self.window center];
    }
    
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)updateTime {
    NSDate *date = [NSDate date];
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    [timeFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [timeFormatter setDateStyle:NSDateFormatterNoStyle];
    self.timeLabel.stringValue = [timeFormatter stringFromDate:date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"]];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    self.dateLabel.stringValue = [dateFormatter stringFromDate:date];
}

- (void)updateFonts {
    NSRect bounds = self.window.contentView.bounds;
    CGFloat timeFontSize = bounds.size.height * 0.35;
    CGFloat dateFontSize = bounds.size.height * 0.15;
    timeFontSize = MAX(timeFontSize, 12.0);
    dateFontSize = MAX(dateFontSize, 8.0);
    
    self.timeLabel.font = [NSFont monospacedDigitSystemFontOfSize:timeFontSize weight:NSFontWeightSemibold];
    self.dateLabel.font = [NSFont systemFontOfSize:dateFontSize weight:NSFontWeightBold];
}

- (void)updateLayout {
    NSRect bounds = self.window.contentView.bounds;
    self.timeLabel.frame = NSMakeRect(0, bounds.size.height * 0.15, bounds.size.width, bounds.size.height * 0.5);
    self.dateLabel.frame = NSMakeRect(0, bounds.size.height * 0.65, bounds.size.width, bounds.size.height * 0.25);
}

- (void)colorChanged:(id)sender {
    NSColor *newColor = self.colorWell.color;
    self.timeLabel.textColor = newColor;
    self.dateLabel.textColor = newColor;
    
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:newColor requiringSecureCoding:NO error:nil];
    if (colorData) {
        [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:@"TextColor"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)alphaChanged:(id)sender {
    self.bgAlpha = self.alphaSlider.doubleValue;
    self.window.backgroundColor = [NSColor colorWithWhite:0.2 alpha:MAX(0.4, self.bgAlpha + 0.1)];
    
    [[NSUserDefaults standardUserDefaults] setObject:@(self.bgAlpha) forKey:@"BackgroundAlpha"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)windowDidResize:(NSNotification *)notification {
    [self updateFonts];
    [self updateLayout];
}

- (void)windowDidMove:(NSNotification *)notification {
    NSString *frameString = NSStringFromRect(self.window.frame);
    [[NSUserDefaults standardUserDefaults] setObject:frameString forKey:@"WindowFrame"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)windowDidEndLiveResize:(NSNotification *)notification {
    NSString *frameString = NSStringFromRect(self.window.frame);
    [[NSUserDefaults standardUserDefaults] setObject:frameString forKey:@"WindowFrame"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)closeApp {
    [NSApp terminate:nil];
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [app run];
    }
    return 0;
}
