//
//  AvatarSection.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// Child avatar display section with name and customization.
struct AvatarSection: View {
    let child: Child
    let onAvatarTap: (() -> Void)?

    init(child: Child, onAvatarTap: (() -> Void)? = nil) {
        self.child = child
        self.onAvatarTap = onAvatarTap
    }

    private var themeColor: Color {
        switch child.themeColor {
        case "pink": return Color(hex: "#FF69B4")
        case "blue": return Color(hex: "#4A90D9")
        case "green": return Color(hex: "#4CAF50")
        case "purple": return Color(hex: "#9C27B0")
        case "orange": return Color(hex: "#FF9800")
        default: return Color(hex: "#4A90D9")
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Avatar with optional tap action
            Button {
                onAvatarTap?()
            } label: {
                avatarView
            }
            .buttonStyle(.plain)
            .disabled(onAvatarTap == nil)

            // Name and age
            VStack(spacing: 4) {
                Text(child.name)
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                Text("Age \(child.age)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    private var avatarView: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [themeColor, themeColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 110, height: 110)

            // Avatar background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [themeColor.opacity(0.3), themeColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)

            // Avatar icon or image
            avatarContent
        }
    }

    @ViewBuilder
    private var avatarContent: some View {
        // Try to use the avatar ID to show appropriate icon
        switch child.avatarId {
        case "avatar_robot":
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(themeColor)

        case "avatar_cat":
            Image(systemName: "cat.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(themeColor)

        case "avatar_dog":
            Image(systemName: "dog.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(themeColor)

        case "avatar_star":
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(themeColor)

        default:
            // Default avatar with initials
            Text(String(child.name.prefix(1)).uppercased())
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(themeColor)
        }
    }
}

// MARK: - Compact Avatar

/// Smaller avatar for lists and headers.
struct CompactAvatar: View {
    let child: Child
    let size: CGFloat

    init(child: Child, size: CGFloat = 40) {
        self.child = child
        self.size = size
    }

    private var themeColor: Color {
        switch child.themeColor {
        case "pink": return Color(hex: "#FF69B4")
        case "blue": return Color(hex: "#4A90D9")
        case "green": return Color(hex: "#4CAF50")
        case "purple": return Color(hex: "#9C27B0")
        case "orange": return Color(hex: "#FF9800")
        default: return Color(hex: "#4A90D9")
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(themeColor.opacity(0.2))
                .frame(width: size, height: size)

            Text(String(child.name.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(themeColor)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        AvatarSection(
            child: Child(name: "Emma", age: 8, themeColor: "pink"),
            onAvatarTap: {}
        )

        HStack(spacing: 16) {
            CompactAvatar(child: Child(name: "Jake", age: 10, themeColor: "blue"))
            CompactAvatar(child: Child(name: "Luna", age: 7, themeColor: "purple"), size: 50)
        }
    }
    .padding()
}
