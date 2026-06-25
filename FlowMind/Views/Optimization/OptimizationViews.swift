import SwiftUI

// MARK: - Suggestions View
struct SuggestionsView: View {
    @EnvironmentObject var routineStore: RoutineStore
    @EnvironmentObject var taskStore: TaskStore
    @State private var suggestions: [Suggestion] = []
    @State private var autoMode: Bool = false
    @AppStorage("autoModeEnabled") private var savedAutoMode: Bool = false

    var body: some View {
        ZStack {
            CFBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Auto mode toggle
                    CFCard(padding: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Automation Mode", systemImage: "bolt.fill")
                                    .font(.cfHeadline())
                                    .foregroundColor(.cfAccent)
                                Text("Auto-schedule tasks based on history")
                                    .font(.cfCaption())
                                    .foregroundColor(.cfTextSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $autoMode)
                                .tint(.cfAccent)
                                .onChange(of: autoMode) { val in
                                    savedAutoMode = val
                                }
                        }
                    }
                    .padding(.horizontal, 18)

                    // Suggestions list
                    Text("Suggestions").font(.cfHeadline()).foregroundColor(.cfText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)

                    if suggestions.isEmpty {
                        CFCard(padding: 20) {
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles").font(.system(size: 36)).foregroundColor(.cfAccent)
                                Text("Great job!").font(.cfHeadline()).foregroundColor(.cfText)
                                Text("No optimization suggestions at this time. Keep up the good work!")
                                    .font(.cfBody()).foregroundColor(.cfTextSecondary).multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 18)
                    } else {
                        ForEach(suggestions) { s in
                            SuggestionCard(suggestion: s) {
                                applySuggestion(s)
                            }
                            .padding(.horizontal, 18)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
        }
        .navigationTitle("Suggestions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            autoMode = savedAutoMode
            generateSuggestions()
        }
    }

    private func generateSuggestions() {
        var list: [Suggestion] = []

        // Check for closely-timed routines
        let byTime = Dictionary(grouping: routineStore.routines.filter { $0.isActive }, by: { $0.schedule.times.first ?? "" })
        for (time, routines) in byTime where routines.count >= 2 {
            list.append(Suggestion(
                title: "Merge tasks at \(time)",
                description: "You have \(routines.count) routines scheduled at \(time). Consider combining them to save setup time.",
                type: .merge,
                icon: "arrow.triangle.merge"
            ))
        }

        // Miss rate suggestion
        let rate = taskStore.completionRate(last: 7)
        if rate < 0.7 {
            list.append(Suggestion(
                title: "Reschedule missed tasks",
                description: "Your completion rate is \(Int(rate * 100))%. Consider rescheduling tasks to better fit your day.",
                type: .reschedule,
                icon: "calendar.badge.clock"
            ))
        }

        // Long routine suggestion
        if let long = routineStore.routines.filter({ $0.estimatedMinutes > 30 }).first {
            list.append(Suggestion(
                title: "Break down '\(long.name)'",
                description: "This routine takes \(long.estimatedMinutes) min. Consider splitting it into smaller tasks.",
                type: .reduce,
                icon: "scissors"
            ))
        }

        suggestions = list
    }

    private func applySuggestion(_ s: Suggestion) {
        if let idx = suggestions.firstIndex(where: { $0.id == s.id }) {
            suggestions[idx].isApplied = true
        }
    }
}

struct SuggestionCard: View {
    var suggestion: Suggestion
    var onApply: () -> Void

    var body: some View {
        CFCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: suggestion.icon)
                        .font(.system(size: 22))
                        .foregroundColor(.cfAccent)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.cfAccent.opacity(0.15)))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.title).font(.cfHeadline()).foregroundColor(.cfText)
                        Text(suggestion.type.rawValue)
                            .font(.cfCaption())
                            .foregroundColor(.cfAccent)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.cfAccent.opacity(0.15)))
                    }
                }

                Text(suggestion.description)
                    .font(.cfBody())
                    .foregroundColor(.cfTextSecondary)

                Button(action: onApply) {
                    Text(suggestion.isApplied ? "✓ Applied" : "Apply Suggestion")
                        .font(.cfCaption())
                        .foregroundColor(suggestion.isApplied ? .cfSuccess : .cfPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(suggestion.isApplied ? Color.cfSuccess.opacity(0.15) : Color.cfPrimary.opacity(0.15))
                        )
                }
                .disabled(suggestion.isApplied)
            }
        }
    }
}

// MARK: - Photo Log
struct PhotoLogView: View {
    @EnvironmentObject var photoStore: PhotoStore
    @State private var showAdd = false
    @State private var selectedPhoto: PhotoEntry?

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            CFBackground()
            ScrollView {
                VStack(spacing: 16) {
                    CFScreenHeader(title: "Photo Log", subtitle: "\(photoStore.photos.count) photos", action: { showAdd = true })
                        .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(photoStore.photos) { photo in
                            if let img = UIImage(data: photo.imageData) {
                                Button(action: { selectedPhoto = photo }) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 0))
                                }
                            }
                        }
                    }

                    if photoStore.photos.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle").font(.system(size: 44)).foregroundColor(.cfTextTertiary)
                            Text("No photos yet").font(.cfHeadline()).foregroundColor(.cfText)
                            Text("Add photos while completing tasks").font(.cfBody()).foregroundColor(.cfTextSecondary)
                        }
                        .padding(.top, 60)
                    }

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) {
            ImagePickerView { image in
                guard let data = image.jpegData(compressionQuality: 0.7) else { return }
                photoStore.addPhoto(PhotoEntry(routineName: "Manual", imageData: data, caption: ""))
            }
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
        }
    }
}

struct PhotoDetailView: View {
    var photo: PhotoEntry
    @EnvironmentObject var photoStore: PhotoStore
    @Environment(\.presentationMode) var presentation
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack {
                    if let img = UIImage(data: photo.imageData) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                    }
                    VStack(spacing: 8) {
                        Text(photo.routineName).font(.cfHeadline()).foregroundColor(.cfText)
                        Text(photo.createdAt, style: .date).font(.cfCaption()).foregroundColor(.cfTextSecondary)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { presentation.wrappedValue.dismiss() }.foregroundColor(.cfText)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash").foregroundColor(.cfAlert)
                    }
                }
            }
            .alert("Delete Photo?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    photoStore.delete(photo.id)
                    presentation.wrappedValue.dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

// MARK: - Notes
struct NotesView: View {
    @EnvironmentObject var noteStore: NoteStore
    @State private var showAdd = false
    @State private var editNote: NoteEntry?

    var body: some View {
        ZStack {
            CFBackground()
            ScrollView {
                VStack(spacing: 16) {
                    CFScreenHeader(title: "Notes", subtitle: "\(noteStore.notes.count) notes", action: { showAdd = true })
                        .padding(.top, 8)

                    if noteStore.notes.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "note.text").font(.system(size: 44)).foregroundColor(.cfTextTertiary)
                            Text("No notes yet").font(.cfHeadline()).foregroundColor(.cfText)
                            Text("Add notes while completing tasks").font(.cfBody()).foregroundColor(.cfTextSecondary)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(noteStore.notes) { note in
                            Button(action: { editNote = note }) {
                                CFCard(padding: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(note.title).font(.cfHeadline()).foregroundColor(.cfText)
                                            Spacer()
                                            Text(note.updatedAt, style: .date).font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                        }
                                        Text(note.content)
                                            .font(.cfBody()).foregroundColor(.cfTextSecondary)
                                            .lineLimit(3)
                                        if !note.tags.isEmpty {
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 6) {
                                                    ForEach(note.tags, id: \.self) { tag in
                                                        Text("#\(tag)")
                                                            .font(.cfCaption(10))
                                                            .foregroundColor(.cfPrimary)
                                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.cfPrimary.opacity(0.15)))
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                        }
                    }
                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAdd) { AddNoteView() }
        .sheet(item: $editNote) { note in AddNoteView(editing: note) }
    }
}

struct AddNoteView: View {
    var editing: NoteEntry? = nil
    @EnvironmentObject var noteStore: NoteStore
    @Environment(\.presentationMode) var presentation
    @State private var title = ""
    @State private var content = ""
    @State private var tagInput = ""
    @State private var tags: [String] = []

    var body: some View {
        NavigationView {
            ZStack {
                CFBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        CFCard {
                            VStack(alignment: .leading, spacing: 10) {
                                TextField("Title", text: $title).font(.cfTitle(22)).foregroundColor(.cfText)
                                Divider().background(Color.cfTextTertiary)
                                ZStack(alignment: .topLeading) {
                                    if content.isEmpty {
                                        Text("Write your note...").font(.cfBody()).foregroundColor(.cfTextTertiary).padding(.top, 2)
                                    }
                                    TextEditor(text: $content)
                                        .font(.cfBody()).foregroundColor(.cfText)
                                        .frame(minHeight: 120).colorScheme(.dark)
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        CFCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Tags").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                HStack {
                                    TextField("Add tag", text: $tagInput)
                                        .font(.cfBody()).foregroundColor(.cfText)
                                    Button(action: {
                                        if !tagInput.trimmingCharacters(in: .whitespaces).isEmpty {
                                            tags.append(tagInput.trimmingCharacters(in: .whitespaces))
                                            tagInput = ""
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill").foregroundColor(.cfPrimary)
                                    }
                                }
                                if !tags.isEmpty {
                                    FlowLayout(spacing: 6) {
                                        ForEach(tags, id: \.self) { tag in
                                            HStack(spacing: 4) {
                                                Text("#\(tag)").font(.cfCaption()).foregroundColor(.cfPrimary)
                                                Button(action: { tags.removeAll { $0 == tag } }) {
                                                    Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundColor(.cfTextSecondary)
                                                }
                                            }
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.cfPrimary.opacity(0.15)))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        Button(action: save) {
                            Text(editing == nil ? "Save Note" : "Update Note")
                        }
                        .buttonStyle(CFPrimaryButtonStyle())
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(editing == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentation.wrappedValue.dismiss() }.foregroundColor(.cfTextSecondary)
                }
                if editing != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Delete") {
                            if let e = editing { noteStore.delete(e.id) }
                            presentation.wrappedValue.dismiss()
                        }
                        .foregroundColor(.cfAlert)
                    }
                }
            }
        }
        .onAppear {
            if let e = editing { title = e.title; content = e.content; tags = e.tags }
        }
    }

    private func save() {
        guard !title.isEmpty else { return }
        if let e = editing {
            var updated = e
            updated.title = title; updated.content = content; updated.tags = tags
            noteStore.update(updated)
        } else {
            noteStore.add(NoteEntry(title: title, content: content, tags: tags))
        }
        presentation.wrappedValue.dismiss()
    }
}

// MARK: - Alerts / Reminders
struct AlertsView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var notificationManager: NotificationManager

    var missed: [DailyTask] { taskStore.missedToday() }
    var pending: [DailyTask] { taskStore.pendingToday() }

    var body: some View {
        ZStack {
            CFBackground()
            ScrollView {
                VStack(spacing: 16) {
                    CFScreenHeader(title: "Alerts", subtitle: "\(missed.count) missed today")
                        .padding(.top, 8)

                    if !missed.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Missed Tasks").font(.cfHeadline()).foregroundColor(.cfAlert)
                                .padding(.horizontal, 18)

                            ForEach(missed) { task in
                                CFCard(padding: 14) {
                                    HStack {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(.cfAlert)
                                            .font(.system(size: 22))
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(task.routineName).font(.cfHeadline()).foregroundColor(.cfText)
                                            Text("Scheduled at \(task.scheduledTime)").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                        }
                                        Spacer()
                                        Button(action: { taskStore.completeTask(task.id) }) {
                                            Text("Done")
                                                .font(.cfCaption())
                                                .foregroundColor(.cfSuccess)
                                                .padding(.horizontal, 12).padding(.vertical, 6)
                                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.cfSuccess.opacity(0.15)))
                                        }
                                    }
                                }
                                .padding(.horizontal, 18)
                            }
                        }
                    }

                    if !pending.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Upcoming").font(.cfHeadline()).foregroundColor(.cfAccent)
                                .padding(.horizontal, 18)

                            ForEach(pending) { task in
                                CFCard(padding: 14) {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.cfAccent).font(.system(size: 20))
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(task.routineName).font(.cfHeadline()).foregroundColor(.cfText)
                                            Text("Due at \(task.scheduledTime)").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                        }
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal, 18)
                            }
                        }
                    }

                    if missed.isEmpty && pending.isEmpty {
                        VStack(spacing: 12) {
                            Text("🎉").font(.system(size: 56))
                            Text("All clear!").font(.cfHeadline()).foregroundColor(.cfText)
                            Text("No alerts at this time").font(.cfBody()).foregroundColor(.cfTextSecondary)
                        }
                        .padding(.top, 60)
                    }

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var selectedDate = Date()
    @State private var displayMonth = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        ZStack {
            CFBackground()
            VStack(spacing: 0) {
                CFScreenHeader(title: "Calendar")
                    .padding(.top, 8)

                // Quick nav to weekly/monthly plan
                HStack(spacing: 10) {
                    NavigationLink(destination: WeeklyPlanView()) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.checkmark").font(.caption)
                            Text("Weekly").font(.system(.caption, design: .rounded)).fontWeight(.semibold)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Color(hex: "#4A90E2").opacity(0.2))
                        .foregroundColor(Color(hex: "#4A90E2"))
                        .cornerRadius(20)
                    }
                    NavigationLink(destination: MonthlyPlanView()) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar").font(.caption)
                            Text("Monthly").font(.system(.caption, design: .rounded)).fontWeight(.semibold)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(Color(hex: "#FFC933").opacity(0.2))
                        .foregroundColor(Color(hex: "#FFC933"))
                        .cornerRadius(20)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)

                // Month navigation
                HStack {
                    Button(action: { changeMonth(-1) }) {
                        Image(systemName: "chevron.left").foregroundColor(.cfText)
                    }
                    Spacer()
                    Text(monthYearString(displayMonth))
                        .font(.cfHeadline())
                        .foregroundColor(.cfText)
                    Spacer()
                    Button(action: { changeMonth(1) }) {
                        Image(systemName: "chevron.right").foregroundColor(.cfText)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                // Day headers
                HStack {
                    ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                        Text(d).font(.cfCaption()).foregroundColor(.cfTextSecondary).frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 18)

                // Calendar grid
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(calendarDays(), id: \.self) { date in
                        if let date = date {
                            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                            let isToday = calendar.isDateInToday(date)
                            let stats = taskStore.statsForDate(date)
                            let hasTasks = stats.totalTasks > 0

                            Button(action: { withAnimation { selectedDate = date } }) {
                                VStack(spacing: 4) {
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.cfBody())
                                        .foregroundColor(isSelected ? .cfBg : isToday ? .cfAccent : .cfText)
                                        .frame(width: 34, height: 34)
                                        .background(
                                            Circle()
                                                .fill(isSelected ? Color.cfPrimary : isToday ? Color.cfAccent.opacity(0.2) : Color.clear)
                                        )
                                    if hasTasks {
                                        HStack(spacing: 2) {
                                            if stats.completedTasks > 0 { dot(color: .cfSuccess) }
                                            if stats.missedTasks > 0 { dot(color: .cfAlert) }
                                            if stats.totalTasks > stats.completedTasks + stats.missedTasks { dot(color: .cfAccent) }
                                        }
                                    } else {
                                        Color.clear.frame(height: 6)
                                    }
                                }
                            }
                        } else {
                            Color.clear.frame(height: 42)
                        }
                    }
                }
                .padding(.horizontal, 12)

                Divider().background(Color.cfTextTertiary).padding(.top, 8)

                // Selected date tasks
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selectedDate, style: .date)
                            .font(.cfHeadline())
                            .foregroundColor(.cfText)
                            .padding(.horizontal, 18)
                            .padding(.top, 12)

                        let dayTasks = taskStore.tasksForDate(selectedDate)
                        if dayTasks.isEmpty {
                            Text("No tasks scheduled")
                                .font(.cfBody()).foregroundColor(.cfTextSecondary)
                                .padding(.horizontal, 18)
                        } else {
                            ForEach(dayTasks) { task in
                                HStack(spacing: 12) {
                                    Text(task.routineIcon).font(.system(size: 20))
                                    Text(task.routineName).font(.cfBody()).foregroundColor(.cfText)
                                    Spacer()
                                    Text(task.scheduledTime).font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                    Image(systemName: task.status.icon)
                                        .foregroundColor(task.status.color)
                                }
                                .padding(.horizontal, 18)
                            }
                        }
                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dot(color: Color) -> some View {
        Circle().fill(color).frame(width: 5, height: 5)
    }

    private func changeMonth(_ delta: Int) {
        if let newDate = calendar.date(byAdding: .month, value: delta, to: displayMonth) {
            withAnimation { displayMonth = newDate }
        }
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private func calendarDays() -> [Date?] {
        var comps = calendar.dateComponents([.year, .month], from: displayMonth)
        comps.day = 1
        guard let firstDay = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else { return [] }

        let startWeekday = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: startWeekday)
        for d in range {
            comps.day = d
            days.append(calendar.date(from: comps))
        }
        return days
    }
}
