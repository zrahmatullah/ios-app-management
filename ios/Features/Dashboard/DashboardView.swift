import SwiftUI

public struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Binding var selectedTab: Int
    @State private var showingQuickAdd: Bool = false
    
    public init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    headerSection
                    if viewModel.isLoading && viewModel.summary == nil {
                        // Skeleton shimmer cards while loading
                        SkeletonCardView()
                        HStack(spacing: 14) {
                            SkeletonCardView()
                            SkeletonCardView()
                        }
                        SkeletonCardView()
                    } else {
                        totalBalanceCard
                        monthIncomeExpenseRow
                        topSavingsSection
                        topGoalsSection
                        habitsSection
                        todayAgendaSection
                        recentNotesSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100) // Padding for custom floating tab bar
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.impact(.light)
                        selectedTab = 4 // Settings tab
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .refreshable {
                await viewModel.loadDashboard()
            }
            .task {
                await viewModel.loadDashboard()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(LuminaFont.subheadline())
                    .foregroundColor(.secondary)
                
                Text("Lumina Life")
                    .font(LuminaFont.largeTitle())
                    .foregroundStyle(LuminaTheme.primaryGradient)
            }
            Spacer()
        }
    }
    
    private var totalBalanceCard: some View {
        LuminaCard(cornerRadius: LuminaTheme.cornerRadiusLarge, padding: 22) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Total Saldo Keseluruhan")
                        .font(LuminaFont.subheadline())
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "wallet.pass.fill")
                        .foregroundColor(Color(hex: "6366F1"))
                }
                
                LuminaAmountText(
                    amount: viewModel.summary?.totalBalance ?? 0,
                    font: .system(size: 34, weight: .bold, design: .rounded)
                )
            }
        }
    }
    
    private var monthIncomeExpenseRow: some View {
        HStack(spacing: 14) {
            // Income Card
            LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.down.left.circle.fill")
                            .foregroundColor(Color(hex: "10B981"))
                        Text("Pemasukan")
                            .font(LuminaFont.caption())
                            .foregroundColor(.secondary)
                    }
                    LuminaAmountText(
                        amount: viewModel.summary?.monthIncome ?? 0,
                        type: "INCOME",
                        font: LuminaFont.headline()
                    )
                }
            }
            
            // Expense Card
            LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .foregroundColor(Color(hex: "F43F5E"))
                        Text("Pengeluaran")
                            .font(LuminaFont.caption())
                            .foregroundColor(.secondary)
                    }
                    LuminaAmountText(
                        amount: viewModel.summary?.monthExpense ?? 0,
                        type: "EXPENSE",
                        font: LuminaFont.headline()
                    )
                }
            }
        }
    }
    
    private var topSavingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Target Tabungan")
                    .font(LuminaFont.headline())
                Spacer()
                Button("Lihat Semua") {
                    selectedTab = 1 // Finance/Savings tab
                }
                .font(LuminaFont.subheadline())
                .foregroundColor(Color(hex: "6366F1"))
            }
            
            if let savingsList = viewModel.summary?.topSavings, !savingsList.isEmpty {
                VStack(spacing: 12) {
                    ForEach(savingsList) { item in
                        LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 14) {
                            HStack(spacing: 14) {
                                LuminaProgressRing(
                                    progress: item.progress,
                                    lineWidth: 7,
                                    gradient: LuminaTheme.savingsGradient,
                                    showLabel: true
                                )
                                .frame(width: 50, height: 50)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(LuminaFont.headline())
                                    Text("\(LuminaAmountText(amount: item.currentAmount, font: LuminaFont.caption()).body) dari \(LuminaAmountText(amount: item.targetAmount, font: LuminaFont.caption()).body)")
                                        .font(LuminaFont.caption())
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            } else {
                Text("Belum ada target tabungan aktif")
                    .font(LuminaFont.subheadline())
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var topGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Target & Milestone")
                    .font(LuminaFont.headline())
                Spacer()
                Button("Lihat Semua") {
                    selectedTab = 2 // Goals tab
                }
                .font(LuminaFont.subheadline())
                .foregroundColor(Color(hex: "6366F1"))
            }
            
            if let goals = viewModel.summary?.topGoals, !goals.isEmpty {
                ForEach(goals) { goal in
                    LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(goal.title)
                                    .font(LuminaFont.headline())
                                Spacer()
                                Text("\(Int(goal.progress * 100))%")
                                    .font(LuminaFont.subheadline().weight(.bold))
                                    .foregroundColor(Color(hex: "6366F1"))
                            }
                            
                            ProgressView(value: goal.progress)
                                .tint(Color(hex: "6366F1"))
                        }
                    }
                }
            }
        }
    }
    
    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habit Tracker Hari Ini")
                .font(LuminaFont.headline())
            
            if let habits = viewModel.summary?.habitsToday, !habits.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(habits) { habit in
                            Button(action: {
                                Task { await viewModel.toggleHabit(habitId: habit.id) }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: habit.isDoneToday ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(habit.isDoneToday ? Color(hex: "10B981") : .secondary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(habit.title)
                                            .font(LuminaFont.subheadline())
                                            .foregroundColor(.primary)
                                        Text("🔥 \(habit.streakCurrent) hari")
                                            .font(LuminaFont.caption())
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
    
    private var todayAgendaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Agenda Hari Ini")
                    .font(LuminaFont.headline())
                Spacer()
                Button("Kalender") {
                    selectedTab = 3 // Calendar tab
                }
                .font(LuminaFont.subheadline())
                .foregroundColor(Color(hex: "6366F1"))
            }
            
            if let events = viewModel.summary?.todayEvents, !events.isEmpty {
                ForEach(events) { event in
                    LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 14) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: event.color))
                                .frame(width: 10, height: 10)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(LuminaFont.headline())
                                Text(event.startTime.formatted(date: .omitted, time: .shortened))
                                    .font(LuminaFont.caption())
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            } else {
                Text("Tidak ada jadwal event hari ini")
                    .font(LuminaFont.subheadline())
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Catatan Terbaru")
                    .font(LuminaFont.headline())
                Spacer()
                Button("Semua Catatan") {
                    selectedTab = 4 // Notes tab
                }
                .font(LuminaFont.subheadline())
                .foregroundColor(Color(hex: "6366F1"))
            }
            
            if let notes = viewModel.summary?.recentNotes, !notes.isEmpty {
                ForEach(notes) { note in
                    LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                if let mood = note.mood, !mood.isEmpty {
                                    Text(mood)
                                }
                                Text(note.title)
                                    .font(LuminaFont.headline())
                                Spacer()
                                Text(note.noteDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(LuminaFont.caption())
                                    .foregroundColor(.secondary)
                            }
                            Text(note.content)
                                .font(LuminaFont.subheadline())
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }
}
