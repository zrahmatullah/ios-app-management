import SwiftUI

public struct SavingsListView: View {
    @StateObject private var viewModel = SavingsViewModel()
    @State private var showingAddSavings: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if !viewModel.savingsList.isEmpty {
                        ForEach(viewModel.savingsList) { item in
                            NavigationLink(destination: SavingsDetailView(savings: item, viewModel: viewModel)) {
                                LuminaCard(cornerRadius: LuminaTheme.cornerRadiusLarge, padding: 18) {
                                    HStack(spacing: 16) {
                                        LuminaProgressRing(
                                            progress: item.progress,
                                            lineWidth: 8,
                                            gradient: LuminaTheme.savingsGradient,
                                            showLabel: true
                                        )
                                        .frame(width: 62, height: 62)
                                        
                                        VStack(alignment: .leading, spacing: 5) {
                                            HStack {
                                                Image(systemName: item.icon)
                                                    .foregroundColor(Color(hex: item.color))
                                                Text(item.name)
                                                    .font(LuminaFont.headline())
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            HStack(spacing: 4) {
                                                LuminaAmountText(amount: item.currentAmount, font: LuminaFont.subheadline().weight(.bold))
                                                Text("dari")
                                                    .font(LuminaFont.caption())
                                                    .foregroundColor(.secondary)
                                                LuminaAmountText(amount: item.targetAmount, font: LuminaFont.caption())
                                            }
                                            
                                            Text("Batas: \(item.deadline.formatted(date: .abbreviated, time: .omitted))")
                                                .font(LuminaFont.caption())
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } else {
                        LuminaEmptyStateView(
                            icon: "gift",
                            title: "Belum Ada Celengan",
                            message: "Buat celengan baru untuk mencapai impian finansial Anda.",
                            actionTitle: "Buat Celengan"
                        ) {
                            showingAddSavings = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Tabungan")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.impact(.light)
                        showingAddSavings = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(LuminaTheme.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showingAddSavings) {
                AddSavingsView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadSavings()
            }
            .refreshable {
                await viewModel.loadSavings()
            }
        }
    }
}
