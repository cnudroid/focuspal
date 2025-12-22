//
//  ReportsView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Parent reports view with detailed analytics.
struct ReportsView: View {
    @State private var selectedChild: Child?
    @State private var selectedDateRange: DateRange = .week
    @State private var children: [Child] = [
        Child(name: "Emma", age: 8),
        Child(name: "Lucas", age: 10)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Filters
            VStack(spacing: 12) {
                // Child picker
                Picker("Child", selection: $selectedChild) {
                    Text("All Children").tag(nil as Child?)
                    ForEach(children) { child in
                        Text(child.name).tag(child as Child?)
                    }
                }
                .pickerStyle(.segmented)

                // Date range picker
                Picker("Period", selection: $selectedDateRange) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            .background(Color(.systemBackground))

            // Report content
            ScrollView {
                VStack(spacing: 24) {
                    // Summary stats
                    SummaryStatsSection()

                    // Category breakdown
                    CategoryBreakdownSection()

                    // Goal compliance
                    GoalComplianceSection()

                    // Activity timeline
                    ActivityTimelineSection()
                }
                .padding()
            }
        }
        .navigationTitle("Reports")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        // Export report
                    } label: {
                        Label("Export PDF", systemImage: "arrow.down.doc")
                    }

                    Button {
                        // Share report
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

struct SummaryStatsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)

            HStack(spacing: 16) {
                StatBox(value: "14.5", unit: "hrs", label: "Total Time")
                StatBox(value: "2.1", unit: "hrs", label: "Daily Avg")
                StatBox(value: "82", unit: "%", label: "Balance")
            }
        }
    }
}

struct StatBox: View {
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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

struct CategoryBreakdownSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category")
                .font(.headline)

            // Placeholder chart
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("Category Chart")
                        .foregroundColor(.secondary)
                )
        }
    }
}

struct GoalComplianceSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Compliance")
                .font(.headline)

            VStack(spacing: 8) {
                GoalComplianceRow(category: "Homework", compliance: 95)
                GoalComplianceRow(category: "Screen Time", compliance: 78)
                GoalComplianceRow(category: "Reading", compliance: 60)
            }
        }
    }
}

struct GoalComplianceRow: View {
    let category: String
    let compliance: Int

    var body: some View {
        HStack {
            Text(category)
                .font(.subheadline)

            Spacer()

            Text("\(compliance)%")
                .font(.subheadline)
                .foregroundColor(compliance >= 80 ? .green : (compliance >= 60 ? .orange : .red))

            ProgressView(value: Double(compliance), total: 100)
                .frame(width: 60)
        }
    }
}

struct ActivityTimelineSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Timeline")
                .font(.headline)

            // Placeholder timeline
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 150)
                .overlay(
                    Text("Timeline View")
                        .foregroundColor(.secondary)
                )
        }
    }
}

enum DateRange: CaseIterable {
    case day, week, month

    var label: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        }
    }
}

#Preview {
    NavigationStack {
        ReportsView()
    }
}
