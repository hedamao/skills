import Cocoa
import SwiftUI

class ClockAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let clockView = ClockView()
        let hostingController = NSHostingController(rootView: clockView)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 150),
            styleMask: [.titled, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.isMovableByWindowBackground = true
        
        // Make background transparent
        window.isOpaque = false
        window.backgroundColor = .clear
        
        // Extremely high window level to be higher than anything else
        // (CGWindowLevelForKey(.maximumWindow) or similar)
        let floatingLevel = Int(CGWindowLevelForKey(.mainMenuWindow)) + 2
        window.level = NSWindow.Level(rawValue: floatingLevel)
        
        // Ensure color panel can float over it
        NSColorPanel.shared.level = NSWindow.Level(rawValue: floatingLevel + 1)
        
        window.hasShadow = true
        window.contentView = hostingController.view
        window.center()
        
        window.makeKeyAndOrderFront(nil)
        
        // Ensure the app becomes active even as an accessory to receive input properly
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct ClockView: View {
    @State private var currentDate = Date()
    @State private var textColor = Color.cyan
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Invisible background to catch drag and resize events
            Color.black.opacity(0.01)
                
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                    // Allows the button to be clickable through the opaque window
                    .contentShape(Rectangle())
                }
                Spacer()
            }
            
            VStack(spacing: 5) {
                // Formatting date in Chinese as the prompt was in Chinese
                Text(currentDate, formatter: dateFormatter)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Text(currentDate, formatter: timeFormatter)
                    .font(.system(size: 48, weight: .semibold, design: .monospaced))
                    .foregroundColor(textColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .padding(.top, 10)
            
            VStack {
                Spacer()
                HStack {
                    ColorPicker("颜色", selection: $textColor)
                        .labelsHidden()
                        .padding(.leading, 8)
                        .padding(.bottom, 8)
                    Spacer()
                }
            }
        }
        // Force the frame to automatically adapt or take available space
        .frame(minWidth: 200, minHeight: 100)
        .onReceive(timer) { input in
            currentDate = input
        }
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
    
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }
}

let app = NSApplication.shared
let delegate = ClockAppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Does not show in dock
app.run()
