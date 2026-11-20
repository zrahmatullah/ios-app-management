import Foundation

// MARK: - Financial Account
public struct Account: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var type: String // CASH, BANK, EWALLET
    public var balance: Int64
    public var currency: String
    public var color: String
    public var icon: String
    public var isArchived: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, balance, currency, color, icon
        case isArchived = "is_archived"
    }
}

// MARK: - Category
public struct Category: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var type: String // INCOME, EXPENSE
    public var icon: String
    public var color: String
    public var isDefault: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, icon, color
        case isDefault = "is_default"
    }
}

// MARK: - Transaction
public struct Transaction: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var accountId: String
    public var accountName: String?
    public var toAccountId: String?
    public var toAccountName: String?
    public var categoryId: String?
    public var categoryName: String?
    public var categoryIcon: String?
    public var categoryColor: String?
    public var amount: Int64
    public var type: String // INCOME, EXPENSE, TRANSFER
    public var note: String
    public var transactionDate: Date
    public var receiptPath: String?
    
    enum CodingKeys: String, CodingKey {
        case id, amount, type, note
        case accountId = "account_id"
        case accountName = "account_name"
        case toAccountId = "to_account_id"
        case toAccountName = "to_account_name"
        case categoryId = "category_id"
        case categoryName = "category_name"
        case categoryIcon = "category_icon"
        case categoryColor = "category_color"
        case transactionDate = "transaction_date"
        case receiptPath = "receipt_path"
    }
}

// MARK: - Budget
public struct Budget: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var categoryId: String
    public var categoryName: String?
    public var categoryIcon: String?
    public var categoryColor: String?
    public var amount: Int64
    public var spent: Int64
    public var period: String
    public var alertThreshold: Double
    
    enum CodingKeys: String, CodingKey {
        case id, amount, spent, period
        case categoryId = "category_id"
        case categoryName = "category_name"
        case categoryIcon = "category_icon"
        case categoryColor = "category_color"
        case alertThreshold = "alert_threshold"
    }
    
    public var percentage: Double {
        guard amount > 0 else { return 0 }
        return min(Double(spent) / Double(amount), 1.0)
    }
    
    public var isOverBudget: Bool {
        spent > amount
    }
}

// MARK: - Savings
public struct Savings: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var targetAmount: Int64
    public var currentAmount: Int64
    public var deadline: Date
    public var icon: String
    public var color: String
    public var status: String // ACTIVE, COMPLETED
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, color, status, deadline
        case targetAmount = "target_amount"
        case currentAmount = "current_amount"
    }
    
    public var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(Double(currentAmount) / Double(targetAmount), 1.0)
    }
}

// MARK: - Savings Entry
public struct SavingsEntry: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var savingsId: String
    public var accountId: String?
    public var amount: Int64
    public var type: String // DEPOSIT, WITHDRAW
    public var note: String
    public var entryDate: Date
    
    enum CodingKeys: String, CodingKey {
        case id, amount, type, note
        case savingsId = "savings_id"
        case accountId = "account_id"
        case entryDate = "entry_date"
    }
}

// MARK: - Savings Projection
public struct SavingsProjection: Codable, Sendable {
    public let savingsId: String
    public let targetAmount: Int64
    public let currentAmount: Int64
    public let remainingAmount: Int64
    public let progressPercentage: Double
    public let daysRemaining: Int
    public let recommendedDailyDeposit: Int64
    public let recommendedWeeklyDeposit: Int64
    public let recommendedMonthlyDeposit: Int64
    public let estimatedCompletionDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case savingsId = "savings_id"
        case targetAmount = "target_amount"
        case currentAmount = "current_amount"
        case remainingAmount = "remaining_amount"
        case progressPercentage = "progress_percentage"
        case daysRemaining = "days_remaining"
        case recommendedDailyDeposit = "recommended_daily_deposit"
        case recommendedWeeklyDeposit = "recommended_weekly_deposit"
        case recommendedMonthlyDeposit = "recommended_monthly_deposit"
        case estimatedCompletionDate = "estimated_completion_date"
    }
}

// MARK: - Goal
public struct Goal: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var title: String
    public var category: String // CAREER, HEALTH, LEARNING, FINANCE, PERSONAL
    public var deadline: Date
    public var priority: String // LOW, MEDIUM, HIGH
    public var status: String // ACTIVE, COMPLETED, POSTPONED
    public var progress: Double
    public var tasks: [GoalTask]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, category, deadline, priority, status, progress, tasks
    }
}

// MARK: - Goal Task
public struct GoalTask: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var goalId: String
    public var title: String
    public var isCompleted: Bool
    public var orderIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title
        case goalId = "goal_id"
        case isCompleted = "is_completed"
        case orderIndex = "order_index"
    }
}

// MARK: - Habit
public struct Habit: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var title: String
    public var frequency: String
    public var streakCurrent: Int
    public var streakLongest: Int
    public var icon: String
    public var color: String
    public var isDoneToday: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, frequency, icon, color
        case streakCurrent = "streak_current"
        case streakLongest = "streak_longest"
        case isDoneToday = "is_done_today"
    }
}

// MARK: - Calendar Event
public struct CalendarEvent: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var title: String
    public var startTime: Date
    public var endTime: Date
    public var location: String
    public var color: String
    public var recurrence: String
    public var reminderMinutes: Int
    public var isCompleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, location, color, recurrence
        case startTime = "start_time"
        case endTime = "end_time"
        case reminderMinutes = "reminder_minutes"
        case isCompleted = "is_completed"
    }
}

// MARK: - Note
public struct Note: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var title: String
    public var content: String
    public var mood: String?
    public var isPinned: Bool
    public var isArchived: Bool
    public var noteDate: Date
    public var tags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, mood, tags
        case isPinned = "is_pinned"
        case isArchived = "is_archived"
        case noteDate = "note_date"
    }
}

// MARK: - Dashboard Summary
public struct DashboardSummary: Codable, Sendable {
    public let totalBalance: Int64
    public let monthIncome: Int64
    public let monthExpense: Int64
    public let topSavings: [Savings]
    public let topGoals: [Goal]
    public let todayEvents: [CalendarEvent]
    public let recentNotes: [Note]
    public let recentTransactions: [Transaction]
    public let habitsToday: [Habit]
    
    enum CodingKeys: String, CodingKey {
        case totalBalance = "total_balance"
        case monthIncome = "month_income"
        case monthExpense = "month_expense"
        case topSavings = "top_savings"
        case topGoals = "top_goals"
        case todayEvents = "today_events"
        case recentNotes = "recent_notes"
        case recentTransactions = "recent_transactions"
        case habitsToday = "habits_today"
    }
}

// MARK: - Finance Report
public struct FinanceReport: Codable, Sendable {
    public let totalIncome: Int64
    public let totalExpense: Int64
    public let netSavings: Int64
    public let categoryExpense: [String: Int64]
    public let dailyTrend: [DailyTrendPoint]
    
    enum CodingKeys: String, CodingKey {
        case totalIncome = "total_income"
        case totalExpense = "total_expense"
        case netSavings = "net_savings"
        case categoryExpense = "category_expense"
        case dailyTrend = "daily_trend"
    }
}

public struct DailyTrendPoint: Codable, Hashable, Sendable {
    public let date: String
    public let income: Int64
    public let expense: Int64
}
