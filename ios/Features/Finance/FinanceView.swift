import SwiftUI
import Charts

public struct FinanceView: View {
    @StateObject private var viewModel = FinanceViewModel()
    @State private var showingAddTransaction: Bool = false
    @State private var showingBudgetManager: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    accountsCarousel
                    SafeToSpendCard(
                        dailySafeAmount: 85000,
                        daysRemaining: 12,
                        status: "SAFE"
                    )
                    budgetOverviewSection
                    spendingChartSection
                    transactionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Keuangan")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.impact(.light)
                        showingAddTransaction = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(LuminaTheme.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingBudgetManager) {
                BudgetManageView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Accounts Carousel
    private var accountsCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dompet & Rekening")
                .font(LuminaFont.headline())
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.accounts) { acc in
                        LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 16) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: acc.icon)
                                        .foregroundColor(Color(hex: acc.color))
                                    Text(acc.name)
                                        .font(LuminaFont.subheadline().weight(.medium))
                                        .lineLimit(1)
                                }
                                
                                LuminaAmountText(
                                    amount: acc.balance,
                                    font: LuminaFont.title3()
                                )
                            }
                            .frame(width: 160)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Budget Section
    private var budgetOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Anggaran Bulanan")
                    .font(LuminaFont.headline())
                Spacer()
                Button("Kelola") {
                    showingBudgetManager = true
                }
                .font(LuminaFont.subheadline())
                .foregroundColor(Color(hex: "6366F1"))
            }
            
            if !viewModel.budgets.isEmpty {
                VStack(spacing: 10) {
                    ForEach(viewModel.budgets) { budget in
                        LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 14) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    if let icon = budget.categoryIcon {
                                        Image(systemName: icon)
                                            .foregroundColor(Color(hex: budget.categoryColor ?? "6366F1"))
                                    }
                                    Text(budget.categoryName ?? "Kategori")
                                        .font(LuminaFont.subheadline().weight(.semibold))
                                    Spacer()
                                    Text("\(Int(budget.percentage * 100))%")
                                        .font(LuminaFont.caption().weight(.bold))
                                        .foregroundColor(budget.isOverBudget ? Color(hex: "F43F5E") : .secondary)
                                }
                                
                                ProgressView(value: budget.percentage)
                                    .tint(budget.isOverBudget ? Color(hex: "F43F5E") : Color(hex: "6366F1"))
                                
                                HStack {
                                    HStack(spacing: 2) {
                                        Text("Terpakai: ")
                                            .foregroundColor(.secondary)
                                            .font(LuminaFont.caption())
                                        LuminaAmountText(amount: budget.spent, font: LuminaFont.caption())
                                    }
                                    Spacer()
                                    HStack(spacing: 2) {
                                        Text("Batas: ")
                                            .foregroundColor(.secondary)
                                            .font(LuminaFont.caption())
                                        LuminaAmountText(amount: budget.amount, font: LuminaFont.caption())
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                Text("Belum ada anggaran per kategori")
                    .font(LuminaFont.subheadline())
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Swift Charts Spending
    private var spendingChartSection: some View {
        LuminaCard(cornerRadius: LuminaTheme.cornerRadiusLarge, padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Aktivitas Transaksi")
                    .font(LuminaFont.headline())
                
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(viewModel.transactions.prefix(7)) { tx in
                            BarMark(
                                x: .value("Tanggal", tx.transactionDate.formatted(.dateTime.day().month())),
                                y: .value("Nominal", tx.amount)
                            )
                            .foregroundStyle(tx.type == "INCOME" ? Color(hex: "10B981") : Color(hex: "F43F5E"))
                            .cornerRadius(4)
                        }
                    }
                    .frame(height: 160)
                }
            }
        }
    }
    
    // MARK: - Transactions History List
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Riwayat Transaksi")
                .font(LuminaFont.headline())
            
            if !viewModel.transactions.isEmpty {
                VStack(spacing: 10) {
                    ForEach(viewModel.transactions) { tx in
                        LuminaCard(cornerRadius: LuminaTheme.cornerRadiusMedium, padding: 14) {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(Color(hex: tx.categoryColor ?? "6366F1").opacity(0.15))
                                    .frame(width: 42, height: 42)
                                    .overlay(
                                        Image(systemName: tx.categoryIcon ?? "dollarsign")
                                            .foregroundColor(Color(hex: tx.categoryColor ?? "6366F1"))
                                    )
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(tx.categoryName ?? (tx.type == "TRANSFER" ? "Transfer" : "Lainnya"))
                                        .font(LuminaFont.headline())
                                    Text(tx.note.isEmpty ? (tx.accountName ?? "") : "\(tx.accountName ?? "") • \(tx.note)")
                                        .font(LuminaFont.caption())
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 3) {
                                    LuminaAmountText(
                                        amount: tx.amount,
                                        type: tx.type,
                                        font: LuminaFont.headline()
                                    )
                                    Text(tx.transactionDate.formatted(date: .numeric, time: .omitted))
                                        .font(LuminaFont.caption())
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteTransaction(id: tx.id) }
                            } label: {
                                Label("Hapus Transaksi", systemImage: "trash")
                            }
                        }
                    }
                }
            } else {
                LuminaEmptyStateView(
                    icon: "tray",
                    title: "Belum Ada Transaksi",
                    message: "Mulai catat pemasukan atau pengeluaran harian Anda.",
                    actionTitle: "Tambah Sekarang"
                ) {
                    showingAddTransaction = true
                }
            }
        }
    }
}
