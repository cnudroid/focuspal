//
//  CreateProfileView.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Child profile creation screen in onboarding flow.
struct CreateProfileView: View {
    let onComplete: () -> Void

    @State private var name = ""
    @State private var age = 8
    @State private var selectedAvatar = "avatar_default"
    @State private var selectedColor = "blue"

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
                    Image(systemName: selectedAvatar)
                        .font(.system(size: 80))
                        .foregroundColor(Color(colorHex(for: selectedColor)))

                    // Avatar options
                    HStack(spacing: 16) {
                        ForEach(avatars, id: \.self) { avatar in
                            Button {
                                selectedAvatar = avatar
                            } label: {
                                Image(systemName: avatar)
                                    .font(.title)
                                    .foregroundColor(selectedAvatar == avatar ? .accentColor : .secondary)
                                    .frame(width: 50, height: 50)
                                    .background(selectedAvatar == avatar ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
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

                    TextField("Child's name", text: $name)
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

                    Picker("Age", selection: $age) {
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
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(colorHex(for: color)))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 40)

                // Continue button
                Button(action: {
                    // Save profile
                    onComplete()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(name.isEmpty ? Color.gray : Color.accentColor)
                        .cornerRadius(14)
                }
                .disabled(name.isEmpty)
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
    CreateProfileView { }
}
