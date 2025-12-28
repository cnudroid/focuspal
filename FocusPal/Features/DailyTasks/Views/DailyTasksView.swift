//
//  DailyTasksView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View displaying today's completed activities and points earned
struct DailyTasksView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: DailyTasksViewModel
    @Environment(\.dismiss) private var dismiss
    let currentChild: Child?

    init(currentChild: Child? = nil) {
        self.currentChild = currentChild
        _viewModel = StateObject(wrappedValue: DailyTasksViewModel(child: currentChild))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date header
                    dateHeader

                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.isEmpty {
                        emptyStateView
                    } else {
                        // Points summary card
                        DailySummaryCard(
                            totalEarned: viewModel.totalEarned,
                            totalBonus: viewModel.totalBonus,
                            totalDeducted: viewModel.totalDeducted,
                            streakDays: viewModel.streakDays,
                            completedCount: viewModel.completedCount,
                            incompleteCount: viewModel.incompleteCount
                        )
                        .padding(.horizontal)

                        // Tasks list
                        tasksSection
                    }
                }
                .padding(.vertical)
            }
            .background(Color.fpGroupedBackground)
            .navigationTitle("Today's Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    // MARK: - Subviews

    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.fpTextSecondary)
                    .textCase(.uppercase)

                Text(viewModel.formattedDate)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.fpTextPrimary)
            }

            Spacer()

            // Decorative calendar icon
            Image(systemName: "calendar")
                .font(.title)
                .foregroundColor(.fpAccent)
        }
        .padding(.horizontal)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading today's activities...")
                .font(.subheadline)
                .foregroundColor(.fpTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            // Illustration
            ZStack {
                Circle()
                    .fill(Color.fpAccent.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(.fpAccent)
            }

            VStack(spacing: 8) {
                Text("No Activities Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.fpTextPrimary)

                Text("Start a focus session to earn points!")
                    .font(.subheadline)
                    .foregroundColor(.fpTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Encouraging message
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("Tip")
                        .fontWeight(.medium)
                }
                .font(.caption)

                Text("Complete activities to earn +10 points each!")
                    .font(.caption)
                    .foregroundColor(.fpTextTertiary)
            }
            .padding()
            .background(Color.fpSecondaryBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 40)
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text("Activities")
                    .font(.headline)
                    .foregroundColor(.fpTextPrimary)

                Spacer()

                Text("\(viewModel.tasks.count) total")
                    .font(.caption)
                    .foregroundColor(.fpTextSecondary)
            }
            .padding(.horizontal)

            // Task rows
            LazyVStack(spacing: 10) {
                ForEach(viewModel.tasks) { task in
                    DailyTaskRow(task: task)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal)

            // Points legend
            pointsLegend
        }
    }

    private var pointsLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How Points Work")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.fpTextSecondary)

            HStack(spacing: 16) {
                legendItem(icon: "checkmark.circle.fill", color: .fpSuccess, text: "+10 pts complete")
                legendItem(icon: "star.fill", color: .yellow, text: "+5 pts early bonus")
            }

            HStack(spacing: 16) {
                legendItem(icon: "exclamationmark.circle.fill", color: .fpWarning, text: "-5 pts incomplete")
            }
        }
        .padding()
        .background(Color.fpSecondaryBackground.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func legendItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(text)
                .font(.caption2)
                .foregroundColor(.fpTextTertiary)
        }
    }
}

// MARK: - Preview

#Preview("With Tasks") {
    DailyTasksView()
}

#Preview("Empty State") {
    DailyTasksView()
}
