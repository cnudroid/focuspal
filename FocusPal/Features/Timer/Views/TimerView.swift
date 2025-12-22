//
//  TimerView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Main timer view with visual countdown and controls.
struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Category selector
                CategorySelector(
                    categories: viewModel.categories,
                    selected: $viewModel.selectedCategory
                )

                Spacer()

                // Timer display (based on visualization mode)
                Group {
                    switch viewModel.visualizationMode {
                    case .circular:
                        CircularTimerView(
                            progress: viewModel.progress,
                            remainingTime: viewModel.remainingTime,
                            state: viewModel.timerState
                        )
                    case .bar:
                        BarTimerView(
                            progress: viewModel.progress,
                            remainingTime: viewModel.remainingTime,
                            state: viewModel.timerState
                        )
                    case .analog:
                        AnalogTimerView(
                            progress: viewModel.progress,
                            remainingTime: viewModel.remainingTime,
                            state: viewModel.timerState
                        )
                    }
                }
                .frame(maxWidth: 300, maxHeight: 300)

                Spacer()

                // Timer controls
                TimerControlsView(
                    state: viewModel.timerState,
                    onStart: viewModel.startTimer,
                    onPause: viewModel.pauseTimer,
                    onResume: viewModel.resumeTimer,
                    onStop: viewModel.stopTimer
                )
            }
            .padding()
            .navigationTitle("Timer")
            .toolbar {
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
        }
    }
}

struct CategorySelector: View {
    let categories: [Category]
    @Binding var selected: Category?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selected?.id == category.id
                    ) {
                        selected = category
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
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                Text(category.name)
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: category.colorHex) : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

#Preview {
    TimerView()
}
