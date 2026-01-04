//
//  ClockMascot.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import SwiftUI

/// A friendly clock mascot character with arms, legs, and a face inside the clock.
struct ClockMascot: View {
    var size: CGFloat = 120
    var message: String? = nil
    var mood: MascotMood = .happy
    var isAnimated: Bool = true

    @State private var isWaving = false
    @State private var isBouncing = false
    @State private var eyesBlink = false

    enum MascotMood {
        case happy
        case excited
        case encouraging
        case celebrating

        var eyeStyle: String {
            switch self {
            case .happy: return "normal"
            case .excited: return "wide"
            case .encouraging: return "wink"
            case .celebrating: return "stars"
            }
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Main clock body with arms and legs
                clockCharacter
                    .offset(y: isBouncing ? -5 : 0)
            }

            // Optional speech bubble
            if let message = message {
                speechBubble(text: message)
                    .offset(y: -8)
            }
        }
        .onAppear {
            if isAnimated {
                startAnimations()
            }
        }
    }

    private var clockCharacter: some View {
        ZStack {
            // Legs
            HStack(spacing: size * 0.25) {
                // Left leg
                legShape
                    .offset(x: -2)

                // Right leg
                legShape
                    .offset(x: 2)
            }
            .offset(y: size * 0.45)

            // Left arm
            armShape(isLeft: true)
                .rotationEffect(.degrees(isWaving ? -20 : -45), anchor: .topTrailing)
                .offset(x: -size * 0.45, y: size * 0.05)

            // Right arm (waving)
            armShape(isLeft: false)
                .rotationEffect(.degrees(isWaving ? 30 : 0), anchor: .topLeading)
                .offset(x: size * 0.45, y: size * 0.05)

            // Clock body
            clockBody

            // Face inside clock
            clockFace
        }
    }

    private var clockBody: some View {
        ZStack {
            // Shadow
            Circle()
                .fill(Color.black.opacity(0.1))
                .frame(width: size, height: size)
                .offset(x: 3, y: 3)

            // Main clock circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.9), Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            // Inner circle (clock face background)
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.8, height: size * 0.8)

            // Clock rim
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.blue],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: size * 0.08
                )
                .frame(width: size * 0.92, height: size * 0.92)

            // Hour markers
            ForEach(0..<12) { i in
                Rectangle()
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 2, height: i % 3 == 0 ? 8 : 4)
                    .offset(y: -size * 0.35)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
        }
    }

    private var clockFace: some View {
        VStack(spacing: size * 0.02) {
            // Eyes
            HStack(spacing: size * 0.15) {
                eyeView(isLeft: true)
                eyeView(isLeft: false)
            }
            .offset(y: -size * 0.05)

            // Smile
            smileView
                .offset(y: size * 0.02)
        }
    }

    private func eyeView(isLeft: Bool) -> some View {
        ZStack {
            // Eye white
            Ellipse()
                .fill(Color.white)
                .frame(width: size * 0.18, height: eyesBlink ? size * 0.02 : size * 0.22)
                .overlay(
                    Ellipse()
                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                )

            // Pupil
            if !eyesBlink {
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.1, height: size * 0.1)
                    .offset(x: mood == .encouraging && !isLeft ? size * 0.02 : 0, y: size * 0.02)

                // Eye shine
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.03, height: size * 0.03)
                    .offset(x: -size * 0.02, y: -size * 0.02)
            }
        }
    }

    private var smileView: some View {
        Group {
            switch mood {
            case .happy, .encouraging:
                // Simple smile arc
                Path { path in
                    path.addArc(
                        center: CGPoint(x: size * 0.15, y: 0),
                        radius: size * 0.15,
                        startAngle: .degrees(20),
                        endAngle: .degrees(160),
                        clockwise: true
                    )
                }
                .stroke(Color.black, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: size * 0.3, height: size * 0.15)

            case .excited, .celebrating:
                // Big open smile
                ZStack {
                    Ellipse()
                        .fill(Color.black)
                        .frame(width: size * 0.25, height: size * 0.15)

                    // Tongue
                    Ellipse()
                        .fill(Color.pink)
                        .frame(width: size * 0.1, height: size * 0.08)
                        .offset(y: size * 0.04)
                }
            }
        }
    }

    private func armShape(isLeft: Bool) -> some View {
        ZStack {
            // Arm
            RoundedRectangle(cornerRadius: size * 0.05)
                .fill(Color.blue)
                .frame(width: size * 0.12, height: size * 0.35)

            // Hand
            Circle()
                .fill(Color.blue.opacity(0.9))
                .frame(width: size * 0.15, height: size * 0.15)
                .offset(y: size * 0.12)
        }
    }

    private var legShape: some View {
        VStack(spacing: 0) {
            // Leg
            RoundedRectangle(cornerRadius: size * 0.03)
                .fill(Color.blue)
                .frame(width: size * 0.1, height: size * 0.2)

            // Foot
            Ellipse()
                .fill(Color.blue.opacity(0.9))
                .frame(width: size * 0.15, height: size * 0.08)
                .offset(y: -size * 0.02)
        }
    }

    private func speechBubble(text: String) -> some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.system(size: size * 0.12, weight: .medium))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )

            // Triangle pointer
            Triangle()
                .fill(Color(.systemBackground))
                .frame(width: 12, height: 8)
                .rotationEffect(.degrees(180))
                .offset(y: -1)
        }
    }

    private func startAnimations() {
        // Waving animation
        withAnimation(
            Animation.easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
        ) {
            isWaving = true
        }

        // Bouncing animation
        withAnimation(
            Animation.easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
                .delay(0.2)
        ) {
            isBouncing = true
        }

        // Blinking animation
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                eyesBlink = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    eyesBlink = false
                }
            }
        }
    }
}

// MARK: - Triangle Shape for Speech Bubble

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Previews

#Preview("Happy") {
    VStack {
        ClockMascot(size: 150, message: "Let's focus!", mood: .happy)
        Spacer().frame(height: 40)
        ClockMascot(size: 100, mood: .excited)
    }
    .padding()
}

#Preview("Celebrating") {
    ClockMascot(size: 150, message: "Great job!", mood: .celebrating)
        .padding()
}
