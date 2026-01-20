//
//  ReportsViewModel.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import Foundation
import SwiftUI

/// View model for the reports dashboard
@MainActor
class ReportsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var selectedChild: Child?
    @Published var selectedDateRange: DateRange = .week
    @Published var children: [Child] = []
    @Published var weeklySummary: AnalyticsWeeklySummary?
    @Published var fullWeeklySummary: WeeklySummary?
    @Published var categoryBreakdown: [CategoryBreakdownItem] = []
    @Published var dailyBreakdown: [DailyBreakdownItem] = []
    @Published var balanceInsights: BalanceScore?
    @Published var weeklyTrend: TrendData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingExportSheet = false
    @Published var exportedPDFData: Data?

    // MARK: - Dependencies

    private let activityService: ActivityServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let categoryService: CategoryServiceProtocol
    private let childRepository: ChildRepositoryProtocol
    private let weeklySummaryService: WeeklySummaryServiceProtocol
    private let pdfGenerator: PDFReportGeneratorProtocol
    private let reportShareService: ReportShareService

    // MARK: - Initialization

    init(
        activityService: ActivityServiceProtocol,
        analyticsService: AnalyticsServiceProtocol,
        categoryService: CategoryServiceProtocol,
        childRepository: ChildRepositoryProtocol,
        weeklySummaryService: WeeklySummaryServiceProtocol,
        pdfGenerator: PDFReportGeneratorProtocol? = nil,
        reportShareService: ReportShareService? = nil
    ) {
        self.activityService = activityService
        self.analyticsService = analyticsService
        self.categoryService = categoryService
        self.childRepository = childRepository
        self.weeklySummaryService = weeklySummaryService
        self.pdfGenerator = pdfGenerator ?? PDFReportGenerator()
        self.reportShareService = reportShareService ?? ReportShareService()
    }

    // MARK: - Computed Properties

    var balanceRecommendations: String {
        guard let balance = balanceInsights else {
            return "No data available yet"
        }

        switch balance.level {
        case .excellent:
            return "Excellent balance! Keep up the great work maintaining variety in activities."
        case .good:
            return "Good balance overall. Consider adding more variety to improve further."
        case .fair:
            return "Activity balance could be improved. Try to diversify activities more."
        case .needsImprovement:
            return "Activities need more balance. Encourage a wider variety of activities throughout the day."
        }
    }

    // MARK: - Public Methods

    /// Load all children for the picker
    func loadChildren() async {
        do {
            children = try await childRepository.fetchAll()
        } catch {
            print("Failed to load children: \(error)")
            children = []
        }
    }

    func loadData(for child: Child?) async {
        isLoading = true
        errorMessage = nil
        selectedChild = child

        do {
            // Calculate date range based on selection
            let dateRange = calculateDateRange()

            // Load all data concurrently
            async let summary = loadWeeklySummary(for: child, in: dateRange)
            async let breakdown = loadCategoryBreakdown(for: child, in: dateRange)
            async let daily = loadDailyBreakdown(for: child, in: dateRange)
            async let balance = loadBalanceInsights(for: child, in: dateRange)
            async let trend = loadTrendData(for: child, in: dateRange)
            async let fullSummary = loadFullWeeklySummary(for: child)

            weeklySummary = try await summary
            categoryBreakdown = try await breakdown
            dailyBreakdown = try await daily
            balanceInsights = try await balance
            weeklyTrend = try await trend
            fullWeeklySummary = try await fullSummary

            isLoading = false
        } catch {
            errorMessage = "Failed to load report data: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Load full weekly summary with points, tier, achievements, streak
    private func loadFullWeeklySummary(for child: Child?) async throws -> WeeklySummary? {
        guard let child = child else {
            // For "All Children", aggregate summaries
            let allSummaries = try await weeklySummaryService.generateSummariesForAllChildren()
            return aggregateSummaries(allSummaries)
        }

        let dateRange = calculateDateRange()
        return try await weeklySummaryService.generateSummary(for: child.id, weekStartDate: dateRange.start)
    }

    /// Aggregate multiple child summaries into one
    private func aggregateSummaries(_ summaries: [WeeklySummary]) -> WeeklySummary? {
        guard !summaries.isEmpty else { return nil }

        let dateRange = calculateDateRange()

        let totalActivities = summaries.reduce(0) { $0 + $1.totalActivities }
        let completedActivities = summaries.reduce(0) { $0 + $1.completedActivities }
        let incompleteActivities = summaries.reduce(0) { $0 + $1.incompleteActivities }
        let totalMinutes = summaries.reduce(0) { $0 + $1.totalMinutes }
        let pointsEarned = summaries.reduce(0) { $0 + $1.pointsEarned }
        let pointsDeducted = summaries.reduce(0) { $0 + $1.pointsDeducted }
        let netPoints = summaries.reduce(0) { $0 + $1.netPoints }
        let achievementsUnlocked = summaries.reduce(0) { $0 + $1.achievementsUnlocked }

        // Merge top categories from all children
        var categoryMinutes: [String: Int] = [:]
        for summary in summaries {
            for category in summary.topCategories {
                categoryMinutes[category.categoryName, default: 0] += category.minutes
            }
        }
        let topCategories = categoryMinutes
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { (categoryName: $0.key, minutes: $0.value) }

        return WeeklySummary(
            childName: "All Children",
            weekStartDate: dateRange.start,
            weekEndDate: Calendar.current.date(byAdding: .second, value: -1, to: dateRange.end) ?? dateRange.end,
            totalActivities: totalActivities,
            completedActivities: completedActivities,
            incompleteActivities: incompleteActivities,
            totalMinutes: totalMinutes,
            pointsEarned: pointsEarned,
            pointsDeducted: pointsDeducted,
            netPoints: netPoints,
            currentTier: nil, // No single tier for all children
            topCategories: Array(topCategories),
            achievementsUnlocked: achievementsUnlocked,
            streak: 0 // No single streak for all children
        )
    }

    func exportReportAsPDF() async -> Data? {
        guard weeklySummary != nil else {
            return nil
        }

        // Generate PDF from current report data
        let pdfData = await generatePDFData()
        exportedPDFData = pdfData
        return pdfData
    }

    func shareReport() {
        guard weeklySummary != nil else {
            return
        }

        showingExportSheet = true
    }

    // MARK: - Private Methods

    private func calculateDateRange() -> DateInterval {
        let calendar = Calendar.current
        let now = Date()

        switch selectedDateRange {
        case .day:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            return DateInterval(start: startOfDay, end: endOfDay)

        case .week:
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
            return DateInterval(start: weekStart, end: weekEnd)

        case .month:
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
            return DateInterval(start: monthStart, end: monthEnd)
        }
    }

    private func loadWeeklySummary(for child: Child?, in dateRange: DateInterval) async throws -> AnalyticsWeeklySummary {
        return try await analyticsService.calculateWeeklySummary(for: child, weekOf: dateRange.start)
    }

    private func loadCategoryBreakdown(for child: Child?, in dateRange: DateInterval) async throws -> [CategoryBreakdownItem] {
        let breakdown = try await analyticsService.calculateCategoryBreakdown(for: child, in: dateRange)
        // Sort by total minutes descending
        return breakdown.sorted { $0.totalMinutes > $1.totalMinutes }
    }

    private func loadDailyBreakdown(for child: Child?, in dateRange: DateInterval) async throws -> [DailyBreakdownItem] {
        return try await analyticsService.calculateDailyBreakdown(for: child, in: dateRange)
    }

    private func loadBalanceInsights(for child: Child?, in dateRange: DateInterval) async throws -> BalanceScore {
        return try await analyticsService.calculateBalanceScore(for: child, in: dateRange)
    }

    private func loadTrendData(for child: Child?, in dateRange: DateInterval) async throws -> TrendData? {
        // Get current week summary
        let currentSummary = try await analyticsService.calculateWeeklySummary(for: child, weekOf: dateRange.start)

        // Get previous week summary
        let previousWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: dateRange.start)!
        let previousSummary = try await analyticsService.calculateWeeklySummary(for: child, weekOf: previousWeekStart)

        // Calculate trend
        guard previousSummary.totalMinutes > 0 else {
            return TrendData(percentageChange: 0, direction: .stable)
        }

        let change = Double(currentSummary.totalMinutes - previousSummary.totalMinutes)
        let percentageChange = (change / Double(previousSummary.totalMinutes)) * 100.0

        let direction: TrendDirection
        if percentageChange > 5 {
            direction = .increasing
        } else if percentageChange < -5 {
            direction = .decreasing
        } else {
            direction = .stable
        }

        return TrendData(percentageChange: percentageChange, direction: direction)
    }

    private func generatePDFData() async -> Data? {
        guard let summary = buildWeeklySummary() else {
            return nil
        }
        return pdfGenerator.generatePDF(from: summary)
    }

    // MARK: - WeeklySummary Conversion

    /// Build a WeeklySummary from the current data
    /// Used for PDF generation and sharing
    func buildWeeklySummary() -> WeeklySummary? {
        // Prefer the full weekly summary if available (has rich data)
        if let fullSummary = fullWeeklySummary {
            return fullSummary
        }

        // Fallback to basic analytics data
        guard let analyticsSummary = weeklySummary else {
            return nil
        }

        let dateRange = calculateDateRange()
        let childName = selectedChild?.name ?? "All Children"

        // Convert category breakdown to top categories format
        let topCategories: [(categoryName: String, minutes: Int)] = categoryBreakdown.prefix(3).map { item in
            (categoryName: item.categoryName, minutes: item.minutes)
        }

        let totalActivities = analyticsSummary.activityCount

        return WeeklySummary(
            childName: childName,
            weekStartDate: dateRange.start,
            weekEndDate: Calendar.current.date(byAdding: .second, value: -1, to: dateRange.end) ?? dateRange.end,
            totalActivities: totalActivities,
            completedActivities: totalActivities,
            incompleteActivities: 0,
            totalMinutes: analyticsSummary.totalMinutes,
            pointsEarned: 0,
            pointsDeducted: 0,
            netPoints: 0,
            currentTier: nil,
            topCategories: topCategories,
            achievementsUnlocked: 0,
            streak: 0
        )
    }

    /// Get the report share service for external use
    func getReportShareService() -> ReportShareService {
        reportShareService
    }
}

// MARK: - Supporting Types

/// Trend data for comparing periods
struct TrendData: Equatable {
    let percentageChange: Double
    let direction: TrendDirection
}

/// Trend direction
enum TrendDirection {
    case increasing
    case decreasing
    case stable
}

/// Date range enum
enum DateRange: CaseIterable {
    case day
    case week
    case month

    var label: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        }
    }
}
