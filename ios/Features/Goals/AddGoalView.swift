import SwiftUI

public struct AddGoalView: View {
    @ObservedObject var viewModel: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var category: String = "KARIER"
    @State private var priority: String = "MEDIUM"
    @State private var deadline: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    
    private let categories = ["KARIER", "KESEHATAN", "BELAJAR", "FINANSIAL", "PRIBADI"]
    private let priorities = ["LOW", "MEDIUM", "HIGH"]
    
    public init(viewModel: GoalsViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detail Target")) {
                    TextField("Judul Target (mis. Lulus Ujian AWS)", text: $title)
                    
                    Picker("Kategori", selection: $category) {
                        ForEach(categories, id: \.self) { c in
                            Text(c.capitalized).tag(c)
                        }
                    }
                    
                    Picker("Prioritas", selection: $priority) {
                        ForEach(priorities, id: \.self) { p in
                            Text(p).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Tenggat Waktu")) {
                    DatePicker("Batas Waktu", selection: $deadline, displayedComponents: .date)
                    
                    // Quick deadline chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            deadlinePresetButton(months: 1, label: "+1 Bulan")
                            deadlinePresetButton(months: 3, label: "+3 Bulan")
                            deadlinePresetButton(months: 6, label: "+6 Bulan")
                            deadlinePresetButton(months: 12, label: "+1 Tahun")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Target Baru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Simpan") {
                        saveGoal()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func deadlinePresetButton(months: Int, label: String) -> some View {
        Button(action: {
            if let newDate = Calendar.current.date(byAdding: .month, value: months, to: Date()) {
                deadline = newDate
                HapticManager.impact(.light)
            }
        }) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "6366F1"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "6366F1").opacity(0.12))
                .cornerRadius(8)
        }
    }
    
    private func saveGoal() {
        guard title.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else { return }
        Task {
            let success = await viewModel.createGoal(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category,
                priority: priority,
                deadline: deadline
            )
            if success {
                HapticManager.notification(.success)
                dismiss()
            }
        }
    }
}

public struct AddHabitView: View {
    @ObservedObject var viewModel: GoalsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var selectedIcon: String = "flame.fill"
    @State private var selectedColor: String = "#FF3B30"
    
    private let availableIcons = ["flame.fill", "drop.fill", "book.fill", "figure.run", "bed.double.fill", "brain.head.profile", "dumbbell.fill"]
    private let availableColors = ["#FF3B30", "#007AFF", "#34C759", "#AF52DE", "#FF9500", "#5856D6"]
    
    public init(viewModel: GoalsViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Kebiasaan Baru")) {
                    TextField("Nama Kebiasaan (mis. Olahraga Pagi)", text: $title)
                }
                
                Section(header: Text("Ikon & Warna")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(selectedIcon == icon ? Color(hex: selectedColor) : Color.primary.opacity(0.08))
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(availableColors, id: \.self) { color in
                                Button(action: { selectedColor = color }) {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Kebiasaan Baru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Simpan") {
                        saveHabit()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func saveHabit() {
        guard title.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { return }
        Task {
            let success = await viewModel.createHabit(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: selectedIcon,
                color: selectedColor
            )
            if success {
                HapticManager.notification(.success)
                dismiss()
            }
        }
    }
}
