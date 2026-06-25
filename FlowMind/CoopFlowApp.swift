import SwiftUI

@main
struct CoopFlowApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var routineStore = RoutineStore()
    @StateObject private var taskStore = TaskStore()
    @StateObject private var photoStore = PhotoStore()
    @StateObject private var noteStore = NoteStore()
    @StateObject private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(routineStore)
                .environmentObject(taskStore)
                .environmentObject(photoStore)
                .environmentObject(noteStore)
                .environmentObject(notificationManager)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}
