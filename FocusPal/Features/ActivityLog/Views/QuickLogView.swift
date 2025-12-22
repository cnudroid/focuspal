//
//  QuickLogView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Quick activity logging sheet with category grid.
struct QuickLogView: View {
    @ObservedObject var viewModel: ActivityLogViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: Category?
    @State private var duration: Int = 30
    @State private var showingManualEntry = false

    let durationOptions = [5, 10, 15, 20, 30, 45, 60]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Category grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Category")
                            .font(.headline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(viewModel.categories) { category in
                                CategoryTile(
                                    category: category,
                                    isSelected: selectedCategory?.id == category.id
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Duration picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Duration")
                            .font(.headline)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(durationOptions, id: \.self) { minutes in
                                    DurationChip(
                                        minutes: minutes,
                                        isSelected: duration == minutes
                                    ) {
                                        duration = minutes
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Manual entry option
                    Button {
                        showingManualEntry = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil.circle")
                            Text("Manual Entry")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle("Quick Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        if let category = selectedCategory {
                            Task {
                                await viewModel.logActivity(
                                    category: category,
                                    duration: TimeInterval(duration * 60)
                                )
                                dismiss()
                            }
                        }
                    }
                    .disabled(selectedCategory == nil)
                }
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualEntryView(viewModel: viewModel)
            }
        }
    }
}

struct CategoryTile: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.title2)

                Text(category.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color(hex: category.colorHex) : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: category.colorHex) : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text("\(minutes) min")
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

#Preview {
    QuickLogView(viewModel: ActivityLogViewModel())
}
