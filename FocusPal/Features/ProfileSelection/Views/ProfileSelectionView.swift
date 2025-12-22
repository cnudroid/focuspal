//
//  ProfileSelectionView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// View for selecting between child profiles.
struct ProfileSelectionView: View {
    @StateObject private var viewModel = ProfileSelectionViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Who's using FocusPal?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                // Profile grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(viewModel.children) { child in
                        ProfileCard(child: child) {
                            viewModel.selectChild(child)
                            dismiss()
                        }
                    }

                    // Add profile button (parent only)
                    AddProfileCard {
                        viewModel.showAddProfile = true
                    }
                }
                .padding()

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showAddProfile) {
                // Add profile flow
                Text("Add Child Profile")
            }
        }
    }
}

struct ProfileCard: View {
    let child: Child
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: colorHex(for: child.themeColor)))

                Text(child.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Age \(child.age)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }

    private func colorHex(for theme: String) -> String {
        switch theme {
        case "pink": return "#FF69B4"
        case "blue": return "#4A90D9"
        case "green": return "#4CAF50"
        case "purple": return "#9C27B0"
        default: return "#888888"
        }
    }
}

struct AddProfileCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)

                Text("Add Child")
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
    }
}

#Preview {
    ProfileSelectionView()
}
