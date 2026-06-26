import SwiftUI
import Combine

class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("hasCompletedSetup") var hasCompletedSetup: Bool = false
    @AppStorage("themeMode") var themeMode: String = "system"
    @AppStorage("birdCount") var birdCount: Int = 0
    @AppStorage("birdType") var birdTypeRaw: String = BirdType.chicken.rawValue
    @AppStorage("userName") var userName: String = ""
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("reminderMinutesBefore") var reminderMinutesBefore: Int = 15
    @AppStorage("autoModeEnabled") var autoModeEnabled: Bool = false
    @AppStorage("weekStartsMonday") var weekStartsMonday: Bool = true
    @AppStorage("showCostTracking") var showCostTracking: Bool = true
    @AppStorage("language") var language: String = "English"

    var birdType: BirdType {
        get { BirdType(rawValue: birdTypeRaw) ?? .chicken }
        set { birdTypeRaw = newValue.rawValue }
    }

    var colorScheme: ColorScheme? {
        switch themeMode {
        case "dark": return .dark
        case "light": return .light
        default: return .dark
        }
    }

    func resetSetup() {
        hasCompletedSetup = false
        birdCount = 0
        birdTypeRaw = BirdType.chicken.rawValue
    }
}
