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
    @State private var showingEditSheet = false
    @State private var editingActivityId: UUID?
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
                            ActivityLogRow(
                                activity: activity,
                                onMarkComplete: activity.isComplete ? nil : {
                                    Task {
                                        await viewModel.markActivityComplete(activity.id)
                                    }
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingActivityId = activity.id
                                showingEditSheet = true
                            }
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
            .sheet(isPresented: $showingEditSheet) {
                if let activityId = editingActivityId,
                   let activity = viewModel.getActivity(activityId) {
                    ActivityEditView(
                        activity: activity,
                        categoryName: viewModel.getCategoryName(for: activityId),
                        categoryColor: viewModel.getCategoryColor(for: activityId),
                        onSave: { updatedActivity in
                            Task {
                                await viewModel.updateActivity(updatedActivity)
                            }
                            showingEditSheet = false
                        },
                        onCancel: {
                            showingEditSheet = false
                        }
                    )
                }
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
    var onMarkComplete: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Category icon with completion indicator
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: activity.iconName)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color(hex: activity.colorHex))
                    .cornerRadius(8)

                // Incomplete indicator
                if !activity.isComplete {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                        .background(Circle().fill(Color(.systemBackground)).frame(width: 12, height: 12))
                        .offset(x: 4, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(activity.categoryName)
                        .font(.headline)

                    if !activity.isComplete {
                        Text("(incomplete)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Text(activity.timeRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let onMarkComplete = onMarkComplete {
                Button {
                    onMarkComplete()
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            } else {
                Text("\(activity.durationMinutes) min")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
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
