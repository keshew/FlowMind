import SwiftUI

// MARK: - Routine List
struct RoutineListView: View {
    @EnvironmentObject var routineStore: RoutineStore
    @State private var showCreate = false
    @State private var appear = false

    var body: some View {
        NavigationView {
            ZStack {
                CFBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        CFScreenHeader(
                            title: "Routines",
                            subtitle: "\(routineStore.routines.count) total",
                            action: { showCreate = true }
                        )
                        .padding(.top, 8)

                        if routineStore.routines.isEmpty {
                            VStack(spacing: 16) {
                                Text("🐔").font(.system(size: 60))
                                Text("No routines yet")
                                    .font(.cfHeadline())
                                    .foregroundColor(.cfText)
                                Text("Create your first routine to get started")
                                    .font(.cfBody())
                                    .foregroundColor(.cfTextSecondary)
                                Button("Create Routine") { showCreate = true }
                                    .buttonStyle(CFPrimaryButtonStyle())
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(routineStore.routines) { routine in
                                NavigationLink(destination: RoutineDetailView(routine: routine)) {
                                    RoutineRow(routine: routine)
                                }
                                .padding(.horizontal, 18)
                                .opacity(appear ? 1 : 0)
                                .offset(y: appear ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)
                                        .delay(Double(routineStore.routines.firstIndex(where: { $0.id == routine.id }) ?? 0) * 0.07),
                                    value: appear
                                )
                            }
                        }

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreate) {
                CreateRoutineView()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appear = true }
            }
        }
    }
}

struct RoutineRow: View {
    var routine: Routine
    @EnvironmentObject var routineStore: RoutineStore

    var body: some View {
        CFCard(padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: routine.color).opacity(0.2))
                        .frame(width: 52, height: 52)
                    Text(routine.icon)
                        .font(.system(size: 28))
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(routine.name)
                            .font(.cfHeadline())
                            .foregroundColor(.cfText)
                        Spacer()
                        Circle()
                            .fill(routine.isActive ? Color.cfSuccess : Color.cfTextTertiary)
                            .frame(width: 8, height: 8)
                    }
                    HStack(spacing: 10) {
                        Label(routine.category.rawValue, systemImage: routine.category.icon)
                            .font(.cfCaption())
                            .foregroundColor(routine.category.swiftUIColor)
                        Label("\(routine.estimatedMinutes)min", systemImage: "clock")
                            .font(.cfCaption())
                            .foregroundColor(.cfTextSecondary)
                    }
                    HStack(spacing: 6) {
                        ForEach(routine.schedule.times, id: \.self) { t in
                            Text(t)
                                .font(.cfCaption(11))
                                .foregroundColor(.cfAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.cfAccent.opacity(0.15))
                                )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Routine Detail
struct RoutineDetailView: View {
    var routine: Routine
    @EnvironmentObject var routineStore: RoutineStore
    @EnvironmentObject var taskStore: TaskStore
    @State private var showEdit = false
    @State private var showDeleteAlert = false
    @Environment(\.presentationMode) var presentation

    var body: some View {
        ZStack {
            CFBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Hero
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: routine.color).opacity(0.2))
                            .frame(height: 200)
                        VStack(spacing: 12) {
                            Text(routine.icon).font(.system(size: 64))
                            Text(routine.name)
                                .font(.cfDisplay(28))
                                .foregroundColor(.cfText)
                            Label(routine.category.rawValue, systemImage: routine.category.icon)
                                .font(.cfBody())
                                .foregroundColor(routine.category.swiftUIColor)
                        }
                    }
                    .padding(.horizontal, 18)

                    // Stats row
                    HStack(spacing: 12) {
                        CFStatChip(label: "Duration", value: "\(routine.estimatedMinutes)m", color: .cfPrimary)
                        CFStatChip(label: "Cost", value: "€\(String(format: "%.2f", routine.costPerSession))", color: .cfAccent)
                        if routine.feedAmount > 0 {
                            CFStatChip(label: "Feed", value: "\(Int(routine.feedAmount))g", color: .cfSecondary)
                        }
                        if routine.waterAmount > 0 {
                            CFStatChip(label: "Water", value: "\(String(format: "%.1f", routine.waterAmount))L", color: .cfPrimaryLight)
                        }
                    }
                    .padding(.horizontal, 18)

                    // Schedule
                    CFCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Schedule", systemImage: "calendar")
                                .font(.cfHeadline())
                                .foregroundColor(.cfText)

                            HStack {
                                Text(routine.schedule.frequency.rawValue)
                                    .font(.cfBody())
                                    .foregroundColor(.cfPrimary)
                                Spacer()
                            }

                            HStack(spacing: 8) {
                                ForEach(routine.schedule.times, id: \.self) { t in
                                    Label(t, systemImage: "clock.fill")
                                        .font(.cfCaption())
                                        .foregroundColor(.cfAccent)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.cfAccent.opacity(0.15))
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    // Steps
                    CFCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Steps (\(routine.steps.count))", systemImage: "list.bullet")
                                .font(.cfHeadline())
                                .foregroundColor(.cfText)

                            ForEach(routine.steps.indices, id: \.self) { i in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(i + 1)")
                                        .font(.cfCaption())
                                        .foregroundColor(.cfBg)
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(Color.cfPrimary))

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(routine.steps[i].title)
                                            .font(.cfHeadline())
                                            .foregroundColor(.cfText)
                                        Text(routine.steps[i].description)
                                            .font(.cfCaption())
                                            .foregroundColor(.cfTextSecondary)
                                        Text("\(routine.steps[i].estimatedMinutes) min")
                                            .font(.cfCaption())
                                            .foregroundColor(.cfAccent)
                                    }
                                    Spacer()
                                }
                                if i < routine.steps.count - 1 {
                                    Divider().background(Color.cfTextTertiary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)

                    // Active toggle
                    CFCard(padding: 14) {
                        HStack {
                            Label("Active", systemImage: "power")
                                .font(.cfHeadline())
                                .foregroundColor(.cfText)
                            Spacer()
                            Toggle("", isOn: .constant(routine.isActive))
                                .labelsHidden()
                                .tint(.cfSuccess)
                                .onTapGesture {
                                    routineStore.toggleActive(routine.id)
                                }
                        }
                    }
                    .padding(.horizontal, 18)

                    // Actions
                    HStack(spacing: 12) {
                        Button("Edit Routine") { showEdit = true }
                            .buttonStyle(CFSecondaryButtonStyle())

                        Button("Delete") { showDeleteAlert = true }
                            .buttonStyle(CFPrimaryButtonStyle(color: .cfAlert))
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentation.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.cfText)
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            CreateRoutineView(editingRoutine: routine)
        }
        .alert("Delete Routine", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                routineStore.delete(routine.id)
                presentation.wrappedValue.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(routine.name)'?")
        }
    }
}

// MARK: - Create Routine
struct CreateRoutineView: View {
    var editingRoutine: Routine? = nil
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var routineStore: RoutineStore

    @State private var name: String = ""
    @State private var icon: String = "🐔"
    @State private var category: RoutineCategory = .feeding
    @State private var steps: [RoutineStep] = []
    @State private var frequency: ScheduleFrequency = .daily
    @State private var times: [String] = ["08:00"]
    @State private var estimatedMinutes: Double = 10
    @State private var costPerSession: String = "0.0"
    @State private var feedAmount: String = "0"
    @State private var waterAmount: String = "0"
    @State private var selectedColor: String = "#4A90E2"
    @State private var newStepTitle: String = ""
    @State private var newStepDesc: String = ""
    @State private var newStepMin: Double = 5
    @State private var showStepAdder = false
    @State private var showTimePicker = false
    @State private var newTime = "08:00"
    @State private var saveConfirm = false

    let icons = ["🐔", "🦆", "🥚", "💧", "🌾", "🧹", "🌅", "🌙", "❤️", "⭐"]
    let colors = ["#4A90E2", "#FF9F5A", "#4CAF50", "#FFC933", "#FF6B6B", "#5BA3F5"]

    var body: some View {
        NavigationView {
            ZStack {
                CFBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Icon picker
                        CFCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Icon").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(icons, id: \.self) { ic in
                                            Button(action: { icon = ic }) {
                                                Text(ic).font(.system(size: 32))
                                                    .frame(width: 52, height: 52)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(icon == ic ? Color.cfPrimary.opacity(0.2) : Color.cfCardLight)
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 12)
                                                                    .stroke(icon == ic ? Color.cfPrimary : Color.clear, lineWidth: 2)
                                                            )
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        // Name
                        CFCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Routine Name").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                TextField("e.g. Morning Feeding", text: $name)
                                    .font(.cfHeadline())
                                    .foregroundColor(.cfText)
                            }
                        }
                        .padding(.horizontal, 18)

                        // Category
                        CFCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Category").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                HStack(spacing: 8) {
                                    ForEach(RoutineCategory.allCases, id: \.self) { cat in
                                        Button(action: { category = cat }) {
                                            VStack(spacing: 4) {
                                                Image(systemName: cat.icon)
                                                    .font(.system(size: 18))
                                                Text(cat.rawValue)
                                                    .font(.cfCaption(10))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .foregroundColor(category == cat ? .cfText : .cfTextSecondary)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(category == cat ? Color(hex: cat.color).opacity(0.3) : Color.cfCardLight)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        // Schedule
                        CFCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Schedule").font(.cfCaption()).foregroundColor(.cfTextSecondary)

                                Picker("Frequency", selection: $frequency) {
                                    ForEach(ScheduleFrequency.allCases, id: \.self) { f in
                                        Text(f.rawValue).tag(f)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .background(Color.cfCardLight)
                                .cornerRadius(8)

                                HStack {
                                    Text("Times").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                    Spacer()
                                    Button(action: { showTimePicker = true }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.cfPrimary)
                                    }
                                }
                                FlowLayout(spacing: 8) {
                                    ForEach(times, id: \.self) { t in
                                        HStack(spacing: 4) {
                                            Text(t)
                                                .font(.cfCaption())
                                                .foregroundColor(.cfAccent)
                                            Button(action: { times.removeAll { $0 == t } }) {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.cfTextSecondary)
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.cfAccent.opacity(0.15))
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        // Duration & costs
                        CFCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Duration & Resources").font(.cfCaption()).foregroundColor(.cfTextSecondary)

                                HStack {
                                    Text("Est. Duration: \(Int(estimatedMinutes)) min")
                                        .font(.cfBody())
                                        .foregroundColor(.cfText)
                                    Spacer()
                                }
                                Slider(value: $estimatedMinutes, in: 1...120, step: 1)
                                    .accentColor(.cfPrimary)

                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Cost (€)").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                        TextField("0.0", text: $costPerSession)
                                            .font(.cfHeadline())
                                            .foregroundColor(.cfText)
                                            .keyboardType(.decimalPad)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Feed (g)").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                        TextField("0", text: $feedAmount)
                                            .font(.cfHeadline())
                                            .foregroundColor(.cfText)
                                            .keyboardType(.numberPad)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Water (L)").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                        TextField("0", text: $waterAmount)
                                            .font(.cfHeadline())
                                            .foregroundColor(.cfText)
                                            .keyboardType(.decimalPad)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        // Steps
                        CFCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Steps").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                    Spacer()
                                    Button(action: { showStepAdder = true }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.cfPrimary)
                                    }
                                }

                                if steps.isEmpty {
                                    Text("No steps added yet. Tap + to add.")
                                        .font(.cfCaption())
                                        .foregroundColor(.cfTextTertiary)
                                } else {
                                    ForEach(steps.indices, id: \.self) { i in
                                        HStack(alignment: .top, spacing: 10) {
                                            Text("\(i+1)")
                                                .font(.cfCaption())
                                                .foregroundColor(.cfBg)
                                                .frame(width: 22, height: 22)
                                                .background(Circle().fill(Color.cfPrimary))

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(steps[i].title)
                                                    .font(.cfHeadline())
                                                    .foregroundColor(.cfText)
                                                Text("\(steps[i].estimatedMinutes) min")
                                                    .font(.cfCaption())
                                                    .foregroundColor(.cfAccent)
                                            }
                                            Spacer()
                                            Button(action: { steps.remove(at: i) }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.cfAlert)
                                                    .font(.system(size: 14))
                                            }
                                        }
                                        if i < steps.count - 1 {
                                            Divider().background(Color.cfTextTertiary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        // Color
                        CFCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Color").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                                HStack(spacing: 12) {
                                    ForEach(colors, id: \.self) { c in
                                        Button(action: { selectedColor = c }) {
                                            Circle()
                                                .fill(Color(hex: c))
                                                .frame(width: 36, height: 36)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: selectedColor == c ? 3 : 0)
                                                )
                                                .shadow(color: Color(hex: c).opacity(0.4), radius: selectedColor == c ? 6 : 0)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        if saveConfirm {
                            Text("✓ Routine saved!")
                                .font(.cfHeadline())
                                .foregroundColor(.cfSuccess)
                        }

                        Button(action: save) {
                            Text(editingRoutine == nil ? "Create Routine" : "Save Changes")
                        }
                        .buttonStyle(CFPrimaryButtonStyle(color: .cfSuccess))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(editingRoutine == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentation.wrappedValue.dismiss() }
                        .foregroundColor(.cfTextSecondary)
                }
            }
        }
        .onAppear { loadIfEditing() }
        .sheet(isPresented: $showStepAdder) {
            AddStepSheet(title: $newStepTitle, desc: $newStepDesc, minutes: $newStepMin) {
                let step = RoutineStep(title: newStepTitle, description: newStepDesc, estimatedMinutes: Int(newStepMin))
                steps.append(step)
                newStepTitle = ""
                newStepDesc = ""
                newStepMin = 5
            }
        }
        .sheet(isPresented: $showTimePicker) {
            TimePickerSheet(time: $newTime) {
                if !times.contains(newTime) {
                    times.append(newTime)
                    times.sort()
                }
            }
        }
    }

    private func loadIfEditing() {
        guard let r = editingRoutine else { return }
        name = r.name; icon = r.icon; category = r.category
        steps = r.steps; frequency = r.schedule.frequency; times = r.schedule.times
        estimatedMinutes = Double(r.estimatedMinutes)
        costPerSession = String(r.costPerSession)
        feedAmount = String(Int(r.feedAmount))
        waterAmount = String(r.waterAmount)
        selectedColor = r.color
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let schedule = RoutineSchedule(frequency: frequency, times: times, daysOfWeek: [0,1,2,3,4,5,6])
        var routine = Routine(
            name: name, icon: icon, category: category, steps: steps,
            schedule: schedule,
            estimatedMinutes: Int(estimatedMinutes),
            costPerSession: Double(costPerSession) ?? 0,
            feedAmount: Double(feedAmount) ?? 0,
            waterAmount: Double(waterAmount) ?? 0,
            color: selectedColor
        )
        if let editing = editingRoutine {
            routine.id = editing.id
            routineStore.update(routine)
        } else {
            routineStore.add(routine)
        }
        withAnimation { saveConfirm = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            presentation.wrappedValue.dismiss()
        }
    }
}

// MARK: - Add Step Sheet
struct AddStepSheet: View {
    @Binding var title: String
    @Binding var desc: String
    @Binding var minutes: Double
    var onAdd: () -> Void
    @Environment(\.presentationMode) var presentation

    var body: some View {
        NavigationView {
            ZStack {
                CFBackground()
                VStack(spacing: 20) {
                    CFCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Step Title").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                            TextField("e.g. Fill feeders", text: $title)
                                .font(.cfHeadline()).foregroundColor(.cfText)
                            Divider().background(Color.cfTextTertiary)
                            Text("Description").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                            TextField("Optional details...", text: $desc)
                                .font(.cfBody()).foregroundColor(.cfText)
                            Divider().background(Color.cfTextTertiary)
                            Text("Duration: \(Int(minutes)) min").font(.cfCaption()).foregroundColor(.cfTextSecondary)
                            Slider(value: $minutes, in: 1...60, step: 1).accentColor(.cfPrimary)
                        }
                    }
                    .padding(.horizontal, 18)

                    Button("Add Step") {
                        guard !title.isEmpty else { return }
                        onAdd()
                        presentation.wrappedValue.dismiss()
                    }
                    .buttonStyle(CFPrimaryButtonStyle(color: .cfPrimary))
                    .padding(.horizontal, 24)
                }
                .padding(.top, 20)
            }
            .navigationTitle("Add Step").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentation.wrappedValue.dismiss() }.foregroundColor(.cfTextSecondary)
                }
            }
        }
    }
}

// MARK: - Time Picker Sheet
struct TimePickerSheet: View {
    @Binding var time: String
    var onAdd: () -> Void
    @Environment(\.presentationMode) var presentation
    @State private var selectedDate = Date()

    var body: some View {
        NavigationView {
            ZStack {
                CFBackground()
                VStack {
                    DatePicker("Select Time", selection: $selectedDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .onChange(of: selectedDate) { d in
                            let f = DateFormatter(); f.dateFormat = "HH:mm"
                            time = f.string(from: d)
                        }

                    Button("Add Time") {
                        onAdd()
                        presentation.wrappedValue.dismiss()
                    }
                    .buttonStyle(CFPrimaryButtonStyle(color: .cfPrimary))
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Pick Time").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentation.wrappedValue.dismiss() }.foregroundColor(.cfTextSecondary)
                }
            }
        }
    }
}

// MARK: - FlowLayout helper
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 300
        var x: CGFloat = 0; var y: CGFloat = 0; var rowH: CGFloat = 0; var totalH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > w && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            rowH = max(rowH, sz.height); x += sz.width + spacing
        }
        totalH = y + rowH
        return CGSize(width: w, height: totalH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX && x > bounds.minX { y += rowH + spacing; x = bounds.minX; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            rowH = max(rowH, sz.height); x += sz.width + spacing
        }
    }
}
