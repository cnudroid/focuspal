//
//  LandingView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Landing page showing child profiles and parent access.
/// Kids tap their avatar to enter, parents tap the lock icon.
struct LandingView: View {
    @StateObject private var viewModel: LandingViewModel
    var onChildSelected: (Child) -> Void

    init(childRepository: ChildRepositoryProtocol? = nil, onChildSelected: @escaping (Child) -> Void) {
        _viewModel = StateObject(wrappedValue: LandingViewModel(childRepository: childRepository))
        self.onChildSelected = onChildSelected
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("FocusPal")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Who's ready to focus?")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
            .padding(.bottom, 40)

            Spacer()

            // Child profiles grid
            if viewModel.children.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("No profiles yet")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Ask a parent to add your profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 24) {
                    ForEach(viewModel.children) { child in
                        ChildProfileButton(child: child) {
                            Task {
                                await viewModel.selectChild(child)
                                onChildSelected(child)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            // Parent access button
            Button {
                viewModel.showParentAuth = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.title3)
                    Text("Parent Access")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.8))
                .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .task {
            await viewModel.loadChildren()
        }
        .sheet(isPresented: $viewModel.showParentAuth, onDismiss: {
            // Present parent controls after auth sheet dismisses
            if viewModel.parentAuthSucceeded {
                viewModel.parentAuthSucceeded = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.showParentControls = true
                }
            }
        }) {
            ParentAuthView(
                onAuthenticated: {
                    viewModel.parentAuthSucceeded = true
                    viewModel.showParentAuth = false
                },
                onCancel: {
                    viewModel.showParentAuth = false
                }
            )
        }
        .sheet(isPresented: $viewModel.showParentControls) {
            ParentControlsView(
                onAddChild: {
                    Task {
                        await viewModel.loadChildren()
                    }
                }
            )
        }
    }
}

/// Button displaying a child's profile that can be tapped to enter
struct ChildProfileButton: View {
    let child: Child
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(themeColor.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: child.avatarId.isEmpty ? "person.circle.fill" : child.avatarId)
                        .font(.system(size: 50))
                        .foregroundColor(themeColor)
                }

                // Name
                Text(child.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                // Age badge
                Text("Age \(child.age)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(themeColor)
                    .cornerRadius(12)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: themeColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var themeColor: Color {
        switch child.themeColor.lowercased() {
        case "pink": return .pink
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "teal": return .teal
        case "yellow": return .yellow
        default: return .blue
        }
    }
}

#Preview {
    LandingView(onChildSelected: { _ in })
}
