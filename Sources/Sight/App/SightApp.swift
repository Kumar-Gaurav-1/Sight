import SwiftUI

/// Main app entry point
/// Configured as a menu bar app using NSApplicationDelegateAdaptor
@main
struct SightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // No main window - menu bar only app
        Settings {
            SightPreferencesView()
        }
    }
}
