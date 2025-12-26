//
//  CreateProfileView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Child profile creation screen in onboarding flow.
struct CreateProfileView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var isProcessing = false

    let avatars = ["person.circle.fill", "face.smiling.fill", "star.circle.fill", "heart.circle.fill"]
    let colors = ["blue", "pink", "green", "purple", "orange"]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Create Child Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                // Avatar selection
                VStack(spacing: 12) {
                    // Selected avatar preview
                    Image(systemName: viewModel.selectedAvatar)
                        .font(.system(size: 80))
                        .foregroundColor(Color(colorHex(for: viewModel.selectedTheme)))

                    // Avatar options
                    HStack(spacing: 16) {
                        ForEach(avatars, id: \.self) { avatar in
                            Button {
                                viewModel.selectedAvatar = avatar
                            } label: {
                                Image(systemName: avatar)
                                    .font(.title)
                                    .foregroundColor(viewModel.selectedAvatar == avatar ? .accentColor : .secondary)
                                    .frame(width: 50, height: 50)
                                    .background(viewModel.selectedAvatar == avatar ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                                    .cornerRadius(25)
                            }
                        }
                    }
                }

                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("Child's name", text: $viewModel.childName)
                        .font(.title3)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                // Age picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("Age", selection: $viewModel.childAge) {
                        ForEach(4...16, id: \.self) { age in
                            Text("\(age) years").tag(age)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                }
                .padding(.horizontal)

                // Color theme
                VStack(alignment: .leading, spacing: 12) {
                    Text("Theme Color")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                viewModel.selectedTheme = color
                            } label: {
                                Circle()
                                    .fill(Color(colorHex(for: color)))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(viewModel.selectedTheme == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Spacer(minLength: 40)

                // Continue button
                Button(action: {
                    isProcessing = true
                    Task {
                        let success = await viewModel.saveChildProfile()
                        isProcessing = false

                        if success {
                            onComplete()
                        }
                    }
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continue")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.childName.isEmpty || isProcessing ? Color.gray : Color.accentColor)
                    .cornerRadius(14)
                }
                .disabled(viewModel.childName.isEmpty || isProcessing)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func colorHex(for color: String) -> String {
        switch color {
        case "blue": return "#4A90D9"
        case "pink": return "#FF69B4"
        case "green": return "#4CAF50"
        case "purple": return "#9C27B0"
        case "orange": return "#FF9800"
        default: return "#888888"
        }
    }
}

#Preview {
    CreateProfileView(
        viewModel: OnboardingViewModel(childRepository: MockChildRepository()),
        onComplete: { }
    )
}
