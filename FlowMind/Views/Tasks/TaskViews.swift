import SwiftUI

// MARK: - Today Tasks
struct TodayTasksView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var routineStore: RoutineStore
    @State private var selectedFilter: TaskFilter = .all
    @State private var appear = false

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Done"
        case missed = "Missed"
    }

    private var filteredTasks: [DailyTask] {
        let today = taskStore.tasksForDate(Date())
        switch selectedFilter {
        case .all: return today
        case .pending: return today.filter { $0.status == .pending || $0.status == .inProgress }
        case .completed: return today.filter { $0.status == .completed }
        case .missed: return today.filter { $0.status == .missed }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                CFBackground()

                VStack(spacing: 0) {
                    CFScreenHeader(title: "Today's Tasks", subtitle: formattedDate())
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    // Filter pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TaskFilter.allCases, id: \.self) { f in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedFilter = f
                                    }
                                }) {
                                    Text(f.rawValue)
                                        .font(.cfCaption())
                                        .foregroundColor(selectedFilter == f ? .white : .cfTextSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedFilter == f ? Color.cfPrimary : Color.cfCard)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                    .padding(.bottom, 12)

                    if filteredTasks.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            Text(selectedFilter == .completed ? "🎉" : "🐔")
                                .font(.system(size: 56))
                            Text(selectedFilter == .completed ? "All tasks done!" : "No tasks here")
                                .font(.cfHeadline())
                                .foregroundColor(.cfText)
                            Text(selectedFilter == .completed ? "Great job today!" : "Try a different filter")
                                .font(.cfBody())
                                .foregroundColor(.cfTextSecondary)
                            Spacer()
                        }
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                ForEach(filteredTasks) { task in
                                    NavigationLink(destination: TaskExecutionView(task: task)) {
                                        TaskCard(task: task)
                                    }
                                    .padding(.horizontal, 18)
                                    .opacity(appear ? 1 : 0)
                                    .offset(y: appear ? 0 : 20)
                                    .animation(
                                        .spring(response: 0.4, dampingFraction: 0.7)
                                            .delay(Double(filteredTasks.firstIndex(where: { $0.id == task.id }) ?? 0) * 0.06),
                                        value: appear
                                    )
                                }
                                Spacer(minLength: 100)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                taskStore.generateTasks(for: Date(), from: routineStore.routines)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appear = true }
            }
        }
    }

    private func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }
}

struct TaskCard: View {
    var task: DailyTask
    @EnvironmentObject var taskStore: TaskStore

    var body: some View {
        CFCard(padding: 16) {
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(task.routineCategory.swiftUIColor.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Text(task.routineIcon).font(.system(size: 28))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.routineName)
                            .font(.cfHeadline())
                            .foregroundColor(.cfText)
                        HStack(spacing: 10) {
                            Label(task.scheduledTime, systemImage: "clock")
                                .font(.cfCaption())
                                .foregroundColor(.cfTextSecondary)
                            Label(task.routineCategory.rawValue, systemImage: task.routineCategory.icon)
                                .font(.cfCaption())
                                .foregroundColor(task.routineCategory.swiftUIColor)
                        }
                    }

                    Spacer()

                    // Status icon
                    Image(systemName: task.status.icon)
                        .font(.system(size: 22))
                        .foregroundColor(task.status.color)
                }

                // Quick complete row (only for pending)
                if task.status == .pending || task.status == .inProgress {
                    HStack(spacing: 12) {
                        Button(action: { taskStore.completeTask(task.id) }) {
                            Label("Complete", systemImage: "checkmark")
                                .font(.cfCaption())
                                .foregroundColor(.cfSuccess)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.cfSuccess.opacity(0.15)))
                        }

                        Button(action: { taskStore.skipTask(task.id) }) {
                            Label("Skip", systemImage: "minus")
                                .font(.cfCaption())
                                .foregroundColor(.cfTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.cfCardLight))
                        }
                    }
                }

                // Step progress
                if !task.steps.isEmpty {
                    let done = task.steps.filter { $0.isCompleted }.count
                    CFProgressBar(value: Double(done) / Double(task.steps.count), color: task.routineCategory.swiftUIColor, height: 4)
                }
            }
        }
    }
}

// MARK: - Task Execution
struct TaskExecutionView: View {
    var task: DailyTask
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var photoStore: PhotoStore
    @Environment(\.presentationMode) var presentation

    @State private var note: String = ""
    @State private var showImagePicker = false
    @State private var startTime: Date? = Date()
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?
    @State private var showComplete = false
    @State private var localTask: DailyTask

    init(task: DailyTask) {
        self.task = task
        _localTask = State(initialValue: task)
        _note = State(initialValue: task.notes)
    }

    var body: some View {
        ZStack {
            CFBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.routineName)
                                .font(.cfTitle())
                                .foregroundColor(.cfText)
                            Label(task.scheduledTime, systemImage: "clock")
                                .font(.cfBody())
                                .foregroundColor(.cfTextSecondary)
                        }
                        Spacer()
                        Text(task.routineIcon).font(.system(size: 48))
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                    // Timer
                    CFCard {
                        VStack(spacing: 8) {
                            Text("Time elapsed")
                                .font(.cfCaption())
                                .foregroundColor(.cfTextSecondary)
                            Text(timerString())
                                .font(.cfDisplay(40))
                                .foregroundColor(.cfPrimary)
                                .monospacedDigit()

                            HStack {
                                Text("Status: ")
                                    .font(.cfCaption())
                                    .foregroundColor(.cfTextSecondary)
                                Text(localTask.status.rawValue)
                                    .font(.cfCaption())
                                    .foregroundColor(localTask.status.color)
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    // Steps checklist
                    if !localTask.steps.isEmpty {
                        CFCard {
                            VStack(alignment: .leading, spacing: 14) {
                                let done = localTask.steps.filter { $0.isCompleted }.count
                                HStack {
                                    Text("Steps (\(done)/\(localTask.steps.count))")
                                        .font(.cfHeadline())
                                        .foregroundColor(.cfText)
                                    Spacer()
                                    CFProgressBar(value: Double(done) / Double(localTask.steps.count), color: .cfSuccess, height: 6)
                                        .frame(width: 80)
                                }

                                ForEach(localTask.steps.indices, id: \.self) { i in
                                    HStack(spacing: 12) {
                                        CFCheckbox(isChecked: localTask.steps[i].isCompleted, action: {
                                            taskStore.completeStep(localTask.id, stepId: localTask.steps[i].id)
                                            if let updated = taskStore.tasks.first(where: { $0.id == localTask.id }) {
                                                localTask = updated
                                            }
                                        }, color: .cfSuccess)

                                        Text(localTask.steps[i].stepTitle)
                                            .font(.cfBody())
                                            .foregroundColor(localTask.steps[i].isCompleted ? .cfTextSecondary : .cfText)
                                            .strikethrough(localTask.steps[i].isCompleted)
                                    }
                                    if i < localTask.steps.count - 1 {
                                        Divider().background(Color.cfTextTertiary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }

                    // Photos
                    CFCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Photos", systemImage: "camera.fill")
                                    .font(.cfHeadline())
                                    .foregroundColor(.cfText)
                                Spacer()
                                Button(action: { showImagePicker = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.cfPrimary)
                                        .font(.system(size: 22))
                                }
                            }

                            let taskPhotos = photoStore.photos(for: task.id)
                            if taskPhotos.isEmpty {
                                Button(action: { showImagePicker = true }) {
                                    HStack {
                                        Image(systemName: "camera")
                                        Text("Add photo evidence")
                                    }
                                    .font(.cfBody())
                                    .foregroundColor(.cfTextTertiary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                            .foregroundColor(Color.cfTextTertiary)
                                    )
                                }
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(taskPhotos) { photo in
                                            if let img = UIImage(data: photo.imageData) {
                                                Image(uiImage: img)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 80, height: 80)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        }
                                        Button(action: { showImagePicker = true }) {
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                                .foregroundColor(.cfTextTertiary)
                                                .frame(width: 80, height: 80)
                                                .overlay(Image(systemName: "plus").foregroundColor(.cfTextTertiary))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    // Notes
                    CFCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Notes", systemImage: "square.and.pencil")
                                .font(.cfHeadline())
                                .foregroundColor(.cfText)

                            ZStack(alignment: .topLeading) {
                                if note.isEmpty {
                                    Text("Add observation, issues, or details...")
                                        .font(.cfBody())
                                        .foregroundColor(.cfTextTertiary)
                                        .padding(.top, 2)
                                }
                                TextEditor(text: $note)
                                    .font(.cfBody())
                                    .foregroundColor(.cfText)
                                    .frame(minHeight: 80)
                                    .colorScheme(.dark)
                                    .onChange(of: note) { _ in
                                        taskStore.updateTaskNote(task.id, note: note)
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    // Action buttons
                    if localTask.status != .completed {
                        VStack(spacing: 12) {
                            Button(action: completeTask) {
                                Label("Mark as Complete", systemImage: "checkmark.circle.fill")
                            }
                            .buttonStyle(CFPrimaryButtonStyle(color: .cfSuccess))

                            Button(action: skipTask) {
                                Text("Skip Task")
                            }
                            .buttonStyle(CFSecondaryButtonStyle())
                        }
                        .padding(.horizontal, 24)
                    } else {
                        CFCard(padding: 16) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.cfSuccess)
                                    .font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Completed!")
                                        .font(.cfHeadline())
                                        .foregroundColor(.cfSuccess)
                                    if let minutes = localTask.actualMinutes {
                                        Text("Took \(minutes) min")
                                            .font(.cfCaption())
                                            .foregroundColor(.cfTextSecondary)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 18)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startTimer()
            taskStore.startTask(task.id)
        }
        .onDisappear {
            stopTimer()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView { image in
                guard let data = image.jpegData(compressionQuality: 0.7) else { return }
                let photo = PhotoEntry(taskId: task.id, routineName: task.routineName, imageData: data, caption: "")
                photoStore.addPhoto(photo)
                taskStore.addPhotoToTask(task.id, photoId: photo.id)
            }
        }
    }

    private func timerString() -> String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func completeTask() {
        stopTimer()
        let minutes = max(1, elapsedSeconds / 60)
        taskStore.completeTask(task.id, minutes: minutes)
        if let updated = taskStore.tasks.first(where: { $0.id == task.id }) {
            localTask = updated
        }
    }

    private func skipTask() {
        stopTimer()
        taskStore.skipTask(task.id)
        presentation.wrappedValue.dismiss()
    }
}

// MARK: - Quick Complete
struct QuickCompleteView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.presentationMode) var presentation

    var pending: [DailyTask] { taskStore.pendingToday() }

    var body: some View {
        NavigationView {
            ZStack {
                CFBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Quick Complete")
                            .font(.cfTitle())
                            .foregroundColor(.cfText)
                            .padding(.top, 20)

                        if pending.isEmpty {
                            VStack(spacing: 12) {
                                Text("🎉").font(.system(size: 56))
                                Text("All tasks done!").font(.cfHeadline()).foregroundColor(.cfText)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(pending) { task in
                                CFCard(padding: 16) {
                                    HStack {
                                        Text(task.routineIcon).font(.system(size: 28))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(task.routineName).font(.cfHeadline()).foregroundColor(.cfText)
                                            Text(task.scheduledTime).font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                        }
                                        Spacer()
                                        CFCheckbox(isChecked: false, action: {
                                            taskStore.completeTask(task.id)
                                        })
                                    }
                                }
                                .padding(.horizontal, 18)
                            }
                        }
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button(action: { presentation.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.cfTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.cfCard))
                }
                .padding(.top, 16)
                .padding(.trailing, 20)
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePickerView: UIViewControllerRepresentable {
    var onPick: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var onPick: (UIImage) -> Void
        init(onPick: @escaping (UIImage) -> Void) { self.onPick = onPick }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { onPick(img) }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}
