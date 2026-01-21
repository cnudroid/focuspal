//
//  ReportsView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI
import Charts

/// Parent reports view with detailed analytics.
struct ReportsView: View {
    @EnvironmentObject private var serviceContainer: ServiceContainer
    @StateObject private var viewModel: ReportsViewModel
    @State private var selectedChild: Child?
    @State private var hasInitializedWithRealServices = false

    init() {
        // Initialize with placeholder - will be replaced via environment on appear
        _viewModel = StateObject(wrappedValue: ReportsViewModel(
            activityService: MockActivityService(),
            analyticsService: MockAnalyticsService(),
            categoryService: MockCategoryService(),
            childRepository: MockChildRepository(),
            weeklySummaryService: MockWeeklySummaryService()
        ))
    }

    /// Initializer with real services (for use with ServiceContainer)
    init(serviceContainer: ServiceContainer, initialChild: Child? = nil) {
        _viewModel = StateObject(wrappedValue: ReportsViewModel(
            activityService: serviceContainer.activityService,
            analyticsService: serviceContainer.analyticsService,
            categoryService: serviceContainer.categoryService,
            childRepository: serviceContainer.childRepository,
            weeklySummaryService: serviceContainer.weeklySummaryService,
            pdfGenerator: serviceContainer.pdfReportGenerator,
            reportShareService: serviceContainer.reportShareService
        ))
        _selectedChild = State(initialValue: initialChild)
    }

    var body: some View {
        contentView
            .navigationTitle("Reports")
            .toolbar { toolbarContent }
            .task {
                await viewModel.loadChildren()
                await viewModel.loadData(for: selectedChild)
            }
            .onChange(of: selectedChild) { newValue in
                Task { await viewModel.loadData(for: newValue) }
            }
            .onChange(of: viewModel.selectedDateRange) { _ in
                Task { await viewModel.loadData(for: selectedChild) }
            }
    }

    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            filtersSection
            mainContent
        }
    }

    private var filtersSection: some View {
        VStack(spacing: 12) {
            Picker("Child", selection: $selectedChild) {
                Text("All Children").tag(nil as Child?)
                ForEach(viewModel.children) { child in
                    Text(child.name).tag(child as Child?)
                }
            }
            .pickerStyle(.segmented)

            Picker("Period", selection: $viewModel.selectedDateRange) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Text(range.label).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading {
            loadingView
        } else if let error = viewModel.errorMessage {
            errorView(error)
        } else {
            reportScrollView
        }
    }

    private var loadingView: some View {
        ProgressView("Loading report...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(error)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.loadData(for: selectedChild) }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var reportScrollView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Child header with name and tier
                if let fullSummary = viewModel.fullWeeklySummary {
                    ChildReportHeader(summary: fullSummary)
                }

                SummaryStatsSection(summary: viewModel.weeklySummary)

                // Highlights section (achievements & streak)
                if let fullSummary = viewModel.fullWeeklySummary,
                   fullSummary.achievementsUnlocked > 0 || fullSummary.streak > 0 || fullSummary.netPoints > 0 {
                    HighlightsSection(summary: fullSummary)
                }

                if let trend = viewModel.weeklyTrend {
                    ReportsTrendIndicator(trend: trend)
                }

                CategoryBreakdownSection(breakdown: viewModel.categoryBreakdown)

                // Show daily breakdown only for Today tab
                if viewModel.selectedDateRange == .day {
                    DailyBreakdownSection(
                        breakdown: viewModel.dailyBreakdown,
                        dateRange: viewModel.selectedDateRange
                    )
                }

                BalanceInsightsSection(
                    balance: viewModel.balanceInsights,
                    recommendations: viewModel.balanceRecommendations
                )
            }
            .padding()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    Task { await shareReportWithPDF() }
                } label: {
                    Label("Share Report (with PDF)", systemImage: "square.and.arrow.up")
                }

                Button {
                    Task { await sharePDFOnly() }
                } label: {
                    Label("Export PDF Only", systemImage: "arrow.down.doc")
                }

                Divider()

                Button {
                    shareViaEmail()
                } label: {
                    Label("Email Report", systemImage: "envelope")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private func shareReportWithPDF() async {
        guard let summary = viewModel.buildWeeklySummary() else { return }
        guard let viewController = ReportShareService.getRootViewController() else { return }

        viewModel.getReportShareService().shareReport(
            summaries: [summary],
            includePDF: true,
            from: viewController
        )
    }

    private func sharePDFOnly() async {
        guard let summary = viewModel.buildWeeklySummary() else { return }
        guard let viewController = ReportShareService.getRootViewController() else { return }

        viewModel.getReportShareService().sharePDFReport(
            summaries: [summary],
            from: viewController
        )
    }

    private func shareViaEmail() {
        guard let summary = viewModel.buildWeeklySummary() else { return }
        viewModel.getReportShareService().shareViaEmail(summaries: [summary])
    }
}

// MARK: - Summary Stats Section

struct SummaryStatsSection: View {
    let summary: AnalyticsWeeklySummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)

            if let summary = summary {
                summaryStats(summary)
            } else {
                noDataView
            }
        }
    }

    private func summaryStats(_ summary: AnalyticsWeeklySummary) -> some View {
        HStack(spacing: 16) {
            StatBox(
                value: String(summary.totalMinutes / 60),
                unit: "hrs",
                label: "Total Time",
                detail: "\(summary.totalMinutes % 60) min"
            )
            StatBox(
                value: String(summary.averageMinutesPerDay),
                unit: "min",
                label: "Daily Avg",
                detail: "\(summary.activeDays) days"
            )
            StatBox(
                value: String(summary.activityCount),
                unit: "",
                label: "Activities",
                detail: ""
            )
        }
    }

    private var noDataView: some View {
        Text("No data available")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
}

struct StatBox: View {
    let value: String
    let unit: String
    let label: String
    let detail: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            if !detail.isEmpty {
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Trend Indicator

struct ReportsTrendIndicator: View {
    let trend: TrendData

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
            Text(trendText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(12)
    }

    private var iconName: String {
        switch trend.direction {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    private var iconColor: Color {
        switch trend.direction {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .blue
        }
    }

    private var trendText: String {
        let percentageText = String(format: "%.1f%%", abs(trend.percentageChange))
        switch trend.direction {
        case .increasing: return "Up \(percentageText) from last period"
        case .decreasing: return "Down \(percentageText) from last period"
        case .stable: return "Stable activity"
        }
    }

    private var backgroundColor: Color {
        switch trend.direction {
        case .increasing: return Color.green.opacity(0.1)
        case .decreasing: return Color.red.opacity(0.1)
        case .stable: return Color.blue.opacity(0.1)
        }
    }
}

// MARK: - Category Breakdown Section

struct CategoryBreakdownSection: View {
    let breakdown: [CategoryBreakdownItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)

            if breakdown.isEmpty {
                noDataView
            } else {
                chartView
                legendView
            }
        }
    }

    private var noDataView: some View {
        Text("No category data available")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }

    private var chartView: some View {
        Chart(breakdown) { item in
            BarMark(
                x: .value("Minutes", item.minutes),
                y: .value("Category", item.categoryName)
            )
            .foregroundStyle(Color(hex: item.colorHex))
            .cornerRadius(4)
        }
        .frame(height: CGFloat(breakdown.count * 40 + 20))
    }

    private var legendView: some View {
        VStack(spacing: 8) {
            ForEach(breakdown) { item in
                HStack {
                    Circle()
                        .fill(Color(hex: item.colorHex))
                        .frame(width: 12, height: 12)
                    Text(item.categoryName)
                        .font(.subheadline)
                    Spacer()
                    Text("\(item.minutes) min (\(item.percentage)%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Daily Breakdown Section

struct DailyBreakdownSection: View {
    let breakdown: [DailyBreakdownItem]
    let dateRange: DateRange

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Activity")
                .font(.headline)

            if breakdown.isEmpty {
                noDataView
            } else {
                dailyChart
            }
        }
    }

    private var noDataView: some View {
        Text("No daily data available")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }

    private var dailyChart: some View {
        Chart(breakdown) { item in
            BarMark(
                x: .value("Date", item.date, unit: .day),
                y: .value("Minutes", item.totalMinutes)
            )
            .foregroundStyle(Color.blue.gradient)
            .cornerRadius(4)
        }
        .frame(height: 200)
    }
}

// MARK: - Balance Insights Section

struct BalanceInsightsSection: View {
    let balance: BalanceScore?
    let recommendations: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Balance Score")
                .font(.headline)

            if let balance = balance {
                balanceCard(balance)
            } else {
                noDataView
            }
        }
    }

    private var noDataView: some View {
        Text("No balance data available")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }

    private func balanceCard(_ balance: BalanceScore) -> some View {
        HStack {
            scoreCircle(balance)
            scoreDetails(balance)
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func scoreCircle(_ balance: BalanceScore) -> some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)
                .frame(width: 100, height: 100)
            Circle()
                .trim(from: 0, to: CGFloat(balance.score) / 100.0)
                .stroke(balanceColor(for: balance.level), lineWidth: 8)
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(balance.score)")
                    .font(.title)
                    .fontWeight(.bold)
                Text("/ 100")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func scoreDetails(_ balance: BalanceScore) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(balance.level.rawValue)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(balanceColor(for: balance.level))
            Text(recommendations)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.leading)
    }

    private func balanceColor(for level: BalanceLevel) -> Color {
        switch level {
        case .excellent: return .green
        case .good: return Color(hex: "#8BC34A")
        case .fair: return .orange
        case .needsImprovement: return .red
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReportsView()
    }
}

// MARK: - Child Report Header

struct ChildReportHeader: View {
    let summary: WeeklySummary

    var body: some View {
        HStack(spacing: 16) {
            // Child avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)

                Text(String(summary.childName.prefix(1)).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(summary.childName)
                    .font(.title2)
                    .fontWeight(.bold)

                if let tier = summary.currentTier {
                    TierBadge(tier: tier)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Highlights Section

struct HighlightsSection: View {
    let summary: WeeklySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline)

            HStack(spacing: 12) {
                if summary.netPoints > 0 {
                    HighlightCard(
                        icon: "star.fill",
                        value: "\(summary.netPoints)",
                        label: "Points",
                        color: Color(hex: "#FFD700")
                    )
                }

                if summary.achievementsUnlocked > 0 {
                    HighlightCard(
                        icon: "trophy.fill",
                        value: "\(summary.achievementsUnlocked)",
                        label: summary.achievementsUnlocked == 1 ? "Achievement" : "Achievements",
                        color: .orange
                    )
                }

                if summary.streak > 0 {
                    HighlightCard(
                        icon: "flame.fill",
                        value: "\(summary.streak)",
                        label: summary.streak == 1 ? "Week Streak" : "Weeks Streak",
                        color: .red
                    )
                }
            }
        }
    }
}

struct HighlightCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Mock Analytics Service

class MockAnalyticsService: AnalyticsServiceProtocol {
    func calculateWeeklySummary(for child: Child?, weekOf date: Date) async throws -> AnalyticsWeeklySummary {
        AnalyticsWeeklySummary(weekStart: date, totalMinutes: 420, activityCount: 14, activeDays: 5, averageMinutesPerDay: 84)
    }

    func calculateBalanceScore(for child: Child?, in dateRange: DateInterval) async throws -> BalanceScore {
        BalanceScore(score: 75, level: .good, breakdown: [:])
    }

    func calculateCategoryBreakdown(for child: Child?, in dateRange: DateInterval) async throws -> [CategoryBreakdownItem] {
        []
    }

    func calculateDailyBreakdown(for child: Child?, in dateRange: DateInterval) async throws -> [DailyBreakdownItem] {
        []
    }
}

// MARK: - Mock Weekly Summary Service

class MockWeeklySummaryService: WeeklySummaryServiceProtocol {
    func generateSummary(for childId: UUID, weekStartDate: Date) async throws -> WeeklySummary {
        WeeklySummary(
            childName: "Sample Child",
            weekStartDate: weekStartDate,
            weekEndDate: Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate)!,
            totalActivities: 10,
            completedActivities: 8,
            incompleteActivities: 2,
            totalMinutes: 300,
            pointsEarned: 200,
            pointsDeducted: 20,
            netPoints: 180,
            currentTier: .silver,
            topCategories: [
                (categoryName: "Reading", minutes: 120),
                (categoryName: "Homework", minutes: 100),
                (categoryName: "Sports", minutes: 80)
            ],
            achievementsUnlocked: 1,
            streak: 2
        )
    }

    func generateSummariesForAllChildren() async throws -> [WeeklySummary] {
        [try await generateSummary(for: UUID(), weekStartDate: Date())]
    }
}
