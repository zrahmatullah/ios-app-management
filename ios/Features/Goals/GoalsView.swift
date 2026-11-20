import SwiftUI

public struct GoalsView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @State private var selectedSegment: Int = 0 // 0: Goals, 1: Habits
    @State private var showingAddSheet: Bool = false
    @State private var newSubtaskText: [String: String] = [:]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment Control
                Picker("", selection: $selectedSegment) {
                    Text("Target Hidup").tag(0)
                    Text("Kebiasaan (Habits)").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if selectedSegment == 0 {
                            goalsListSection
                        } else {
                            habitsListSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Target & Kebiasaan")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.impact(.light)
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(LuminaTheme.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                if selectedSegment == 0 {
                    AddGoalView(viewModel: viewModel)
                } else {
                    AddHabitView(viewModel: viewModel)
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Goals Section
    private var goalsListSection: some View {
        VStack(spacing: 14) {
            if !viewModel.goals.isEmpty {
                ForEach(viewModel.goals) { goal in
                    LuminaCard(cornerRadius: LuminaTheme.cornerRadiusLarge, padding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goal.title)
                                        .font(LuminaFont.headline())
                                    Text("\(goal.category) • Deadline: \(goal.deadline.formatted(date: .abbreviated, time: .omitted))")
                                        .font(LuminaFont.caption())
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(Int(goal.progress * 100))%")
                                    .font(LuminaFont.headline())
                                    .foregroundColor(Color(hex: "6366F1"))
                            }
                            
                            ProgressView(value: goal.progress)
                                .tint(Color(hex: "6366F1"))
                            
                            // Subtasks list
                            if let tasks = goal.tasks, !tasks.isEmpty {
                                Divider()
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(tasks) { task in
                                        Button(action: {
                                            Task { await viewModel.toggleTask(taskId: task.id) }
                                        }) {
                                            HStack(spacing: 10) {
                                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(task.isCompleted ? Color(hex: "10B981") : .secondary)
                                                Text(task.title)
                                                    .font(LuminaFont.subheadline())
                                                    .strikethrough(task.isCompleted)
                                                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                                                Spacer()
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            
                            // Add subtask input
                            HStack {
                                TextField("Tambah sub-tugas...", text: Binding(
                                    get: { newSubtaskText[goal.id] ?? "" },
                                    set: { newSubtaskText[goal.id] = $0 }
                                ))
                                .font(LuminaFont.subheadline())
                                
                                Button(action: {
                                    if let text = newSubtaskText[goal.id], !text.isEmpty {
                                        Task {
                                            await viewModel.addTask(goalId: goal.id, title: text)
                                            newSubtaskText[goal.id] = ""
                                        }
                                    }
                                }) {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(Color(hex: "6366F1"))
                                }
                                .disabled((newSubtaskText[goal.id] ?? "").isEmpty)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            } else {
                LuminaEmptyStateView(
                    icon: "target",
                    title: "Belum Ada Target",
                    message: "Tentukan impian dan langkah-langkah nyata untuk mencapainya.",
                    actionTitle: "Buat Target Baru"
                ) {
                    showingAddSheet = true
                }
            }
        }
    }
    
    // MARK: - Habits Section
    private var habitsListSection: some View {
        VStack(spacing: 12) {
            if !viewModel.habits.isEmpty {
                ForEach(viewModel.habits) { habit in
                    LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 16) {
                        HStack(spacing: 14) {
                            Button(action: {
                                Task { await viewModel.toggleHabit(habitId: habit.id) }
                            }) {
                                Image(systemName: habit.isDoneToday ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 26))
                                    .foregroundColor(habit.isDoneToday ? Color(hex: "10B981") : .secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Circle()
                                .fill(Color(hex: habit.color).opacity(0.15))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: habit.icon)
                                        .foregroundColor(Color(hex: habit.color))
                                )
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(habit.title)
                                    .font(LuminaFont.headline())
                                Text("Streak: \(habit.streakCurrent) hari • Terbaik: \(habit.streakLongest) hari")
                                    .font(LuminaFont.caption())
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("🔥 \(habit.streakCurrent)")
                                .font(LuminaFont.headline())
                                .foregroundColor(Color(hex: "FF3B30"))
                        }
                    }
                }
            } else {
                LuminaEmptyStateView(
                    icon: "flame",
                    title: "Belum Ada Kebiasaan",
                    message: "Bentuk kebiasaan positif setiap hari dengan streak pelacak.",
                    actionTitle: "Tambah Kebiasaan"
                ) {
                    showingAddSheet = true
                }
            }
        }
    }
}
