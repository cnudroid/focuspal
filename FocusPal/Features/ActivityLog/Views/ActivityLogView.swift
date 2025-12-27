//
//  ActivityLogView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View displaying the activity log with quick logging options.
struct ActivityLogView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    @StateObject private var viewModel: ActivityLogViewModel
    @State private var showingQuickLog = false
    let currentChild: Child?

    init(currentChild: Child? = nil) {
        self.currentChild = currentChild
        // Create with placeholder - will be replaced in task
        _viewModel = StateObject(wrappedValue: ActivityLogViewModel(child: currentChild))
    }

    var body: some View {
        NavigationStack {
            List {
                // Date picker section
                Section {
                    DatePicker(
                        "Date",
                        selection: $viewModel.selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }

                // Activities section
                Section("Activities") {
                    if viewModel.activities.isEmpty {
                        EmptyLogView()
                    } else {
                        ForEach(viewModel.activities) { activity in
                            ActivityLogRow(activity: activity)
                        }
                        .onDelete(perform: viewModel.deleteActivities)
                    }
                }
            }
            .navigationTitle("Activity Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingQuickLog = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingQuickLog) {
                QuickLogView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadActivities()
            }
            .onChange(of: viewModel.selectedDate) { _ in
                Task {
                    await viewModel.loadActivities()
                }
            }
        }
    }
}

struct ActivityLogRow: View {
    let activity: ActivityDisplayItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.iconName)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color(hex: activity.colorHex))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.categoryName)
                    .font(.headline)

                Text(activity.timeRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(activity.durationMinutes) min")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct EmptyLogView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No activities logged")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

#Preview {
    ActivityLogView()
}
