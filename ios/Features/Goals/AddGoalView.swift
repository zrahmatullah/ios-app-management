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
                    
                    DatePicker("Batas Waktu", selection: $deadline, displayedComponents: .date)
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
                    .disabled(title.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func saveGoal() {
        Task {
            let success = await viewModel.createGoal(
                title: title,
                category: category,
                priority: priority,
                deadline: deadline
            )
            if success {
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
                    .disabled(title.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func saveHabit() {
        Task {
            let success = await viewModel.createHabit(
                title: title,
                icon: selectedIcon,
                color: selectedColor
            )
            if success {
                dismiss()
            }
        }
    }
}
