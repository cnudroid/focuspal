//
//  TimerView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Main timer view with visual countdown and controls.
struct TimerView: View {
    @StateObject private var viewModel: TimerViewModel
    @State private var showingParentControls = false
    @State private var showingNameEditor = false

    init(timerManager: MultiChildTimerManager? = nil, activityService: ActivityServiceProtocol? = nil, currentChild: Child? = nil) {
        _viewModel = StateObject(wrappedValue: TimerViewModel(
            timerManager: timerManager,
            activityService: activityService,
            currentChild: currentChild
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Child name greeting - tappable to edit
                Button {
                    showingNameEditor = true
                } label: {
                    HStack(spacing: 8) {
                        Text("👋")
                            .font(.title2)
                        Text("Hi, \(viewModel.childName)!")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)

                // Category selector with duration display
                // Disabled when timer is running or paused
                CategorySelector(
                    categories: viewModel.categories,
                    selected: $viewModel.selectedCategory,
                    isDisabled: viewModel.timerState == .running || viewModel.timerState == .paused
                )

                Spacer()

                // Timer display (based on visualization mode)
                // Wrap in container that completely disables animations
                TimerDisplayContainer(
                    visualizationMode: viewModel.visualizationMode,
                    progress: viewModel.progress,
                    remainingTime: viewModel.remainingTime,
                    timerState: viewModel.timerState
                )
                .frame(maxWidth: 300, maxHeight: 300)

                // Time info when running
                if viewModel.timerState == .running || viewModel.timerState == .paused {
                    TimeInfoView(viewModel: viewModel)
                }

                Spacer()

                // Add time buttons when running
                if viewModel.timerState == .running || viewModel.timerState == .paused {
                    AddTimeButtonsView(onAddTime: viewModel.addTime)
                }

                // Timer controls
                TimerControlsView(
                    state: viewModel.timerState,
                    onStart: viewModel.startTimer,
                    onPause: viewModel.pauseTimer,
                    onResume: viewModel.resumeTimer,
                    onStop: viewModel.stopTimer,
                    onCompleteEarly: viewModel.completeEarly
                )
            }
            .padding()
            .navigationTitle("Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        // Audio toggle
                        Button {
                            viewModel.toggleAudioCallouts()
                        } label: {
                            Image(systemName: viewModel.audioCalloutsEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundColor(viewModel.audioCalloutsEnabled ? .primary : .secondary)
                        }

                        // Parent Controls / Settings
                        Button {
                            showingParentControls = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(TimerVisualizationMode.allCases, id: \.self) { mode in
                            Button(mode.rawValue.capitalized) {
                                viewModel.setVisualizationMode(mode)
                            }
                        }
                    } label: {
                        Image(systemName: "paintbrush")
                    }
                }
            }
            .sheet(isPresented: $showingParentControls, onDismiss: {
                // Reload categories when returning from settings
                viewModel.reloadCategories()
            }) {
                NavigationStack {
                    CategorySettingsView()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingParentControls = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingNameEditor) {
                NameEditorView(
                    currentName: viewModel.childName,
                    onSave: { newName in
                        viewModel.setChildName(newName)
                        showingNameEditor = false
                    },
                    onCancel: {
                        showingNameEditor = false
                    }
                )
            }
            .alert("Time's Up!", isPresented: .init(
                get: { viewModel.pendingCompletionState != nil },
                set: { if !$0 { viewModel.pendingCompletionState = nil } }
            )) {
                Button("Yes, I finished!") {
                    viewModel.confirmCompletion()
                }
                Button("Not yet", role: .cancel) {
                    viewModel.markIncomplete()
                }
            } message: {
                if let state = viewModel.pendingCompletionState {
                    Text("Did you finish \(state.categoryName)?")
                } else {
                    Text("Did you finish the activity?")
                }
            }
        }
    }
}

// MARK: - Time Info View

struct TimeInfoView: View {
    @ObservedObject var viewModel: TimerViewModel

    var body: some View {
        HStack(spacing: 24) {
            // Elapsed time
            VStack(spacing: 4) {
                Text("Elapsed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.elapsedTimeFormatted)
                    .font(.headline.monospacedDigit())
            }

            // Extra time added (if any)
            if viewModel.timeAdded > 0 {
                VStack(spacing: 4) {
                    Text("Added")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.timeAddedFormatted)
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Add Time Buttons View

struct AddTimeButtonsView: View {
    let onAddTime: (Int) -> Void

    var body: some View {
        HStack(spacing: 16) {
            AddTimeButton(minutes: 1, onTap: { onAddTime(1) })
            AddTimeButton(minutes: 5, onTap: { onAddTime(5) })
            AddTimeButton(minutes: 10, onTap: { onAddTime(10) })
        }
    }
}

struct AddTimeButton: View {
    let minutes: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("+\(minutes)m")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(16)
        }
    }
}

// MARK: - Name Editor View

struct NameEditorView: View {
    let currentName: String
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Child's Name", text: $name)
                        .textContentType(.name)
                        .autocapitalization(.words)
                } header: {
                    Text("What's your name?")
                } footer: {
                    Text("This name will be shown on the timer screen.")
                }
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onSave(trimmed)
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                name = currentName
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Timer Display Container
// Wrapper that completely disables implicit animations for timer display

struct TimerDisplayContainer: View {
    let visualizationMode: TimerVisualizationMode
    let progress: Double
    let remainingTime: TimeInterval
    let timerState: TimerState

    var body: some View {
        // Use a unique ID based on the actual values to force immediate rendering
        // This prevents SwiftUI from trying to animate between states
        timerContent
            .id("\(visualizationMode.rawValue)")
            .animation(nil, value: progress)
            .animation(nil, value: remainingTime)
            .animation(nil, value: timerState)
            .transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
    }

    @ViewBuilder
    private var timerContent: some View {
        switch visualizationMode {
        case .circular:
            CircularTimerView(
                progress: progress,
                remainingTime: remainingTime,
                state: timerState
            )
        case .bar:
            BarTimerView(
                progress: progress,
                remainingTime: remainingTime,
                state: timerState
            )
        case .analog:
            AnalogTimerView(
                progress: progress,
                remainingTime: remainingTime,
                state: timerState
            )
        }
    }
}

struct CategorySelector: View {
    let categories: [Category]
    @Binding var selected: Category?
    var isDisabled: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selected?.id == category.id,
                        isDisabled: isDisabled && selected?.id != category.id
                    ) {
                        if !isDisabled {
                            selected = category
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    var isDisabled: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: category.iconName)
                    Text(category.name)
                }
                .font(.subheadline.weight(.medium))

                // Show duration
                Text("\(category.durationMinutes) min")
                    .font(.caption2)
                    .opacity(0.8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: category.colorHex) : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : (isDisabled ? .secondary : .primary))
            .cornerRadius(16)
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .disabled(isDisabled)
    }
}

#Preview {
    TimerView()
}
