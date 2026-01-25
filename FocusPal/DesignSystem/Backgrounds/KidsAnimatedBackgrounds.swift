//
//  KidsAnimatedBackgrounds.swift
//  FocusPal
//
//  Khan Academy Kids-inspired animated backgrounds for a playful experience.
//

import SwiftUI

// MARK: - Safe Random Helper

/// Safely generates a random CGFloat, ensuring lowerBound <= upperBound
private func safeRandom(in range: ClosedRange<CGFloat>) -> CGFloat {
    let lower = range.lowerBound
    let upper = range.upperBound
    if lower > upper {
        return lower // Return lower bound if range is invalid
    }
    return CGFloat.random(in: lower...upper)
}

// MARK: - Background Style Enum

/// Available animated background styles
enum KidsBackgroundStyle {
    case gradient(theme: BackgroundTheme)
    case floatingShapes(theme: BackgroundTheme)
    case bubbles(theme: BackgroundTheme)
    case waves(theme: BackgroundTheme)
    case sparkles
    case clouds
    case combined(theme: BackgroundTheme)
}

/// Color themes for backgrounds
enum BackgroundTheme {
    case blue
    case pink
    case green
    case purple
    case orange
    case rainbow

    var colors: [Color] {
        switch self {
        case .blue:
            return [Color(hex: "#E8F4FD"), Color(hex: "#B8E0FF"), Color(hex: "#87CEEB")]
        case .pink:
            return [Color(hex: "#FFF0F5"), Color(hex: "#FFB6D9"), Color(hex: "#FF69B4")]
        case .green:
            return [Color(hex: "#E8F5E9"), Color(hex: "#A5D6A7"), Color(hex: "#66BB6A")]
        case .purple:
            return [Color(hex: "#F3E5F5"), Color(hex: "#CE93D8"), Color(hex: "#AB47BC")]
        case .orange:
            return [Color(hex: "#FFF3E0"), Color(hex: "#FFCC80"), Color(hex: "#FFA726")]
        case .rainbow:
            return [Color(hex: "#FFE5E5"), Color(hex: "#E5F0FF"), Color(hex: "#E5FFE5"), Color(hex: "#FFF5E5")]
        }
    }

    var shapeColors: [Color] {
        switch self {
        case .blue:
            return [.blue.opacity(0.3), .cyan.opacity(0.2), .teal.opacity(0.25)]
        case .pink:
            return [.pink.opacity(0.3), .purple.opacity(0.2), .red.opacity(0.2)]
        case .green:
            return [.green.opacity(0.3), .mint.opacity(0.2), .teal.opacity(0.25)]
        case .purple:
            return [.purple.opacity(0.3), .indigo.opacity(0.2), .pink.opacity(0.2)]
        case .orange:
            return [.orange.opacity(0.3), .yellow.opacity(0.2), .red.opacity(0.2)]
        case .rainbow:
            return [.red.opacity(0.2), .orange.opacity(0.2), .yellow.opacity(0.2), .green.opacity(0.2), .blue.opacity(0.2), .purple.opacity(0.2)]
        }
    }
}

// MARK: - Animated Gradient Background

/// Smoothly animating gradient background
struct AnimatedGradientBackground: View {
    let theme: BackgroundTheme
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: theme.colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Floating Shapes Background

/// Floating shapes (stars, circles, hearts) that gently move around
struct FloatingShapesBackground: View {
    let theme: BackgroundTheme
    let shapeCount: Int

    init(theme: BackgroundTheme = .blue, shapeCount: Int = 15) {
        self.theme = theme
        self.shapeCount = shapeCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                AnimatedGradientBackground(theme: theme)

                // Floating shapes
                ForEach(0..<shapeCount, id: \.self) { index in
                    FloatingShape(
                        shape: FloatingShape.ShapeType.allCases[index % FloatingShape.ShapeType.allCases.count],
                        color: theme.shapeColors[index % theme.shapeColors.count],
                        size: CGFloat.random(in: 20...50),
                        startPosition: CGPoint(
                            x: safeRandom(in: 0...max(1, geometry.size.width)),
                            y: safeRandom(in: 0...max(1, geometry.size.height))
                        ),
                        containerSize: CGSize(width: max(1, geometry.size.width), height: max(1, geometry.size.height))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// Individual floating shape with animation
struct FloatingShape: View {
    enum ShapeType: CaseIterable {
        case star
        case circle
        case heart
        case sparkle
        case diamond
    }

    let shape: ShapeType
    let color: Color
    let size: CGFloat
    let startPosition: CGPoint
    let containerSize: CGSize

    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1

    var body: some View {
        shapeView
            .foregroundColor(color)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .position(position)
            .onAppear {
                position = startPosition
                startAnimations()
            }
    }

    @ViewBuilder
    private var shapeView: some View {
        switch shape {
        case .star:
            Image(systemName: "star.fill")
                .resizable()
        case .circle:
            Circle()
        case .heart:
            Image(systemName: "heart.fill")
                .resizable()
        case .sparkle:
            Image(systemName: "sparkle")
                .resizable()
        case .diamond:
            Image(systemName: "diamond.fill")
                .resizable()
        }
    }

    private func startAnimations() {
        // Floating movement
        withAnimation(
            .easeInOut(duration: Double.random(in: 4...8))
            .repeatForever(autoreverses: true)
            .delay(Double.random(in: 0...2))
        ) {
            position = CGPoint(
                x: max(size, min(containerSize.width - size, startPosition.x + CGFloat.random(in: -50...50))),
                y: max(size, min(containerSize.height - size, startPosition.y + CGFloat.random(in: -80...80)))
            )
        }

        // Gentle rotation
        withAnimation(
            .linear(duration: Double.random(in: 8...15))
            .repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }

        // Subtle scale breathing
        withAnimation(
            .easeInOut(duration: Double.random(in: 2...4))
            .repeatForever(autoreverses: true)
        ) {
            scale = CGFloat.random(in: 0.8...1.2)
        }
    }
}

// MARK: - Bubble Background

/// Floating bubbles that rise up
struct BubbleBackground: View {
    let theme: BackgroundTheme
    let bubbleCount: Int

    init(theme: BackgroundTheme = .blue, bubbleCount: Int = 20) {
        self.theme = theme
        self.bubbleCount = bubbleCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                AnimatedGradientBackground(theme: theme)

                // Bubbles
                ForEach(0..<bubbleCount, id: \.self) { index in
                    Bubble(
                        color: theme.shapeColors[index % theme.shapeColors.count],
                        size: CGFloat.random(in: 15...40),
                        startX: safeRandom(in: 0...max(1, geometry.size.width)),
                        containerHeight: max(1, geometry.size.height),
                        delay: Double.random(in: 0...5)
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// Individual bubble that rises and fades
struct Bubble: View {
    let color: Color
    let size: CGFloat
    let startX: CGFloat
    let containerHeight: CGFloat
    let delay: Double

    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var xWobble: CGFloat = 0

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(0.6), color.opacity(0.2)],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: size
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: size * 0.3, height: size * 0.3)
                    .offset(x: -size * 0.2, y: -size * 0.2)
            )
            .offset(x: startX + xWobble, y: containerHeight + size - yOffset)
            .opacity(opacity)
            .onAppear {
                startAnimation()
            }
    }

    private func startAnimation() {
        // Rise up animation
        withAnimation(
            .linear(duration: Double.random(in: 8...15))
            .repeatForever(autoreverses: false)
            .delay(delay)
        ) {
            yOffset = containerHeight + size * 2
        }

        // Fade in
        withAnimation(.easeIn(duration: 1).delay(delay)) {
            opacity = 1
        }

        // Side wobble
        withAnimation(
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            xWobble = CGFloat.random(in: -20...20)
        }
    }
}

// MARK: - Wave Background

/// Organic wave shapes at the bottom of the screen
struct WaveBackground: View {
    let theme: BackgroundTheme
    let waveCount: Int

    init(theme: BackgroundTheme = .blue, waveCount: Int = 3) {
        self.theme = theme
        self.waveCount = waveCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                AnimatedGradientBackground(theme: theme)

                // Waves at the bottom
                ForEach(0..<waveCount, id: \.self) { index in
                    WaveShape(
                        amplitude: 20 + Double(index) * 5,
                        frequency: 1.5 - Double(index) * 0.3,
                        phase: Double(index) * .pi / 3
                    )
                    .fill(theme.shapeColors[index % theme.shapeColors.count])
                    .frame(height: 150 + CGFloat(index) * 30)
                    .offset(y: geometry.size.height - 100 + CGFloat(index) * 20)
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// Animated wave shape
struct WaveShape: Shape {
    var amplitude: Double
    var frequency: Double
    var phase: Double

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.5

        path.move(to: CGPoint(x: 0, y: midHeight))

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * frequency * 2 * .pi + phase)
            let y = midHeight + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

/// Animated wave view that continuously animates
struct AnimatedWave: View {
    let color: Color
    let amplitude: Double
    let frequency: Double
    @State private var phase: Double = 0

    var body: some View {
        WaveShape(amplitude: amplitude, frequency: frequency, phase: phase)
            .fill(color)
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    phase = .pi * 2
                }
            }
    }
}

// MARK: - Sparkle Background

/// Twinkling sparkle/star background
struct SparkleBackground: View {
    let sparkleCount: Int

    init(sparkleCount: Int = 30) {
        self.sparkleCount = sparkleCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark blue gradient for night sky effect
                LinearGradient(
                    colors: [Color(hex: "#1a1a2e"), Color(hex: "#16213e"), Color(hex: "#0f3460")],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Sparkles
                ForEach(0..<sparkleCount, id: \.self) { index in
                    Sparkle(
                        position: CGPoint(
                            x: safeRandom(in: 0...max(1, geometry.size.width)),
                            y: safeRandom(in: 0...max(1, geometry.size.height))
                        ),
                        delay: Double.random(in: 0...3)
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// Individual twinkling sparkle
struct Sparkle: View {
    let position: CGPoint
    let delay: Double

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: CGFloat.random(in: 8...16)))
            .foregroundColor(.white)
            .opacity(opacity)
            .scaleEffect(scale)
            .position(position)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1...2))
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    opacity = Double.random(in: 0.5...1.0)
                    scale = CGFloat.random(in: 0.8...1.2)
                }
            }
    }
}

// MARK: - Cloud Background

/// Floating clouds background
struct CloudBackground: View {
    let cloudCount: Int

    init(cloudCount: Int = 8) {
        self.cloudCount = cloudCount
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sky gradient
                LinearGradient(
                    colors: [Color(hex: "#87CEEB"), Color(hex: "#B0E0E6"), Color(hex: "#E0F7FA")],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Clouds
                ForEach(0..<cloudCount, id: \.self) { index in
                    Cloud(
                        size: CGFloat.random(in: 80...150),
                        startPosition: CGPoint(
                            x: safeRandom(in: -100...max(0, geometry.size.width)),
                            y: safeRandom(in: 0...max(50, geometry.size.height * 0.6))
                        ),
                        containerWidth: max(1, geometry.size.width),
                        speed: Double.random(in: 20...40)
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// Individual floating cloud
struct Cloud: View {
    let size: CGFloat
    let startPosition: CGPoint
    let containerWidth: CGFloat
    let speed: Double

    @State private var xOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: -size * 0.3) {
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: size * 0.5, height: size * 0.5)
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: size * 0.7, height: size * 0.7)
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: size * 0.6, height: size * 0.6)
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: size * 0.4, height: size * 0.4)
        }
        .shadow(color: .white.opacity(0.5), radius: 10)
        .position(x: startPosition.x + xOffset, y: startPosition.y)
        .onAppear {
            withAnimation(
                .linear(duration: speed)
                .repeatForever(autoreverses: false)
            ) {
                xOffset = containerWidth + size * 2
            }
        }
    }
}

// MARK: - Combined Animated Background

/// Combines multiple effects for a rich animated background
struct CombinedAnimatedBackground: View {
    let theme: BackgroundTheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                AnimatedGradientBackground(theme: theme)

                // Floating shapes (fewer for performance)
                ForEach(0..<8, id: \.self) { index in
                    FloatingShape(
                        shape: FloatingShape.ShapeType.allCases[index % FloatingShape.ShapeType.allCases.count],
                        color: theme.shapeColors[index % theme.shapeColors.count],
                        size: CGFloat.random(in: 20...40),
                        startPosition: CGPoint(
                            x: safeRandom(in: 0...max(1, geometry.size.width)),
                            y: safeRandom(in: 0...max(1, geometry.size.height * 0.7))
                        ),
                        containerSize: CGSize(width: max(1, geometry.size.width), height: max(1, geometry.size.height))
                    )
                }

                // Bottom waves
                VStack {
                    Spacer()
                    AnimatedWave(
                        color: theme.shapeColors[0],
                        amplitude: 15,
                        frequency: 1.5
                    )
                    .frame(height: 100)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Background View Modifier

/// View modifier to easily apply animated backgrounds
struct AnimatedBackgroundModifier: ViewModifier {
    let style: KidsBackgroundStyle

    func body(content: Content) -> some View {
        ZStack {
            backgroundView
            content
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .gradient(let theme):
            AnimatedGradientBackground(theme: theme)
        case .floatingShapes(let theme):
            FloatingShapesBackground(theme: theme)
        case .bubbles(let theme):
            BubbleBackground(theme: theme)
        case .waves(let theme):
            WaveBackground(theme: theme)
        case .sparkles:
            SparkleBackground()
        case .clouds:
            CloudBackground()
        case .combined(let theme):
            CombinedAnimatedBackground(theme: theme)
        }
    }
}

extension View {
    /// Apply a Khan Academy Kids-style animated background
    func kidsBackground(_ style: KidsBackgroundStyle) -> some View {
        modifier(AnimatedBackgroundModifier(style: style))
    }
}

// MARK: - Previews

#Preview("Gradient Background") {
    VStack {
        Text("Hello!")
            .font(.largeTitle.bold())
            .foregroundColor(.white)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .kidsBackground(.gradient(theme: .blue))
}

#Preview("Floating Shapes") {
    VStack {
        Text("Floating Shapes")
            .font(.largeTitle.bold())
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .kidsBackground(.floatingShapes(theme: .pink))
}

#Preview("Bubbles") {
    VStack {
        Text("Bubbles!")
            .font(.largeTitle.bold())
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .kidsBackground(.bubbles(theme: .green))
}

#Preview("Waves") {
    VStack {
        Text("Waves")
            .font(.largeTitle.bold())
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .kidsBackground(.waves(theme: .purple))
}

#Preview("Sparkles") {
    VStack {
        Text("Night Sky")
            .font(.largeTitle.bold())
            .foregroundColor(.white)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .kidsBackground(.sparkles)
}

#Preview("Clouds") {
    VStack {
        Text("Clouds")
            .font(.largeTitle.bold())
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .kidsBackground(.clouds)
}

#Preview("Combined") {
    VStack {
        Text("Combined!")
            .font(.largeTitle.bold())
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .kidsBackground(.combined(theme: .orange))
}

// MARK: - Solid Background (for battery saving)

/// Simple solid color background with no animations
struct SolidBackground: View {
    let theme: BackgroundTheme

    var body: some View {
        LinearGradient(
            colors: [theme.colors.first ?? .blue, theme.colors.last ?? .cyan],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Child Preference-Based Background

/// Represents which screen is requesting a background (for automatic mode)
enum ScreenType {
    case today
    case rewards
    case me
    case timer
}

/// Creates the appropriate animated background based on child's preferences
struct ChildPreferenceBackground: View {
    let child: Child
    let screenType: ScreenType

    private var theme: BackgroundTheme {
        switch child.themeColor.lowercased() {
        case "pink": return .pink
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        default: return .blue
        }
    }

    var body: some View {
        if !child.preferences.animatedBackgroundsEnabled {
            // Animations disabled - use solid background
            SolidBackground(theme: theme)
        } else {
            backgroundForPreference
        }
    }

    @ViewBuilder
    private var backgroundForPreference: some View {
        switch child.preferences.backgroundStyle {
        case .automatic:
            automaticBackground
        case .gradient:
            AnimatedGradientBackground(theme: theme)
        case .floatingShapes:
            FloatingShapesBackground(theme: theme, shapeCount: 12)
        case .bubbles:
            BubbleBackground(theme: theme, bubbleCount: 15)
        case .waves:
            WaveBackground(theme: theme, waveCount: 3)
        case .sparkles:
            SparkleBackground(sparkleCount: 25)
        case .clouds:
            CloudBackground(cloudCount: 6)
        case .combined:
            CombinedAnimatedBackground(theme: theme)
        case .solid:
            SolidBackground(theme: theme)
        }
    }

    /// Different defaults per screen for automatic mode
    @ViewBuilder
    private var automaticBackground: some View {
        switch screenType {
        case .today:
            FloatingShapesBackground(theme: theme, shapeCount: 12)
        case .rewards:
            WaveBackground(theme: theme, waveCount: 3)
        case .me:
            BubbleBackground(theme: theme, bubbleCount: 15)
        case .timer:
            AnimatedGradientBackground(theme: theme)
        }
    }
}

// MARK: - Background Preview Card

/// A small preview card showing a background style
struct BackgroundPreviewCard: View {
    let style: ChildPreferences.BackgroundStylePreference
    let theme: BackgroundTheme
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Preview thumbnail
                ZStack {
                    previewBackground
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                        )

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                            .background(Circle().fill(.white))
                    }
                }

                // Label
                VStack(spacing: 2) {
                    Image(systemName: style.iconName)
                        .font(.caption)
                        .foregroundColor(isSelected ? .accentColor : .secondary)

                    Text(style.displayName)
                        .font(.caption2)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? .primary : .secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var previewBackground: some View {
        switch style {
        case .automatic:
            // Show a mix preview
            ZStack {
                AnimatedGradientBackground(theme: theme)
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.5))
            }
        case .gradient:
            AnimatedGradientBackground(theme: theme)
        case .floatingShapes:
            FloatingShapesBackground(theme: theme, shapeCount: 5)
        case .bubbles:
            BubbleBackground(theme: theme, bubbleCount: 8)
        case .waves:
            WaveBackground(theme: theme, waveCount: 2)
        case .sparkles:
            SparkleBackground(sparkleCount: 10)
        case .clouds:
            CloudBackground(cloudCount: 3)
        case .combined:
            CombinedAnimatedBackground(theme: theme)
        case .solid:
            SolidBackground(theme: theme)
        }
    }
}

#Preview("Background Preview Cards") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            ForEach(ChildPreferences.BackgroundStylePreference.allCases, id: \.self) { style in
                BackgroundPreviewCard(
                    style: style,
                    theme: .blue,
                    isSelected: style == .floatingShapes,
                    onTap: {}
                )
            }
        }
        .padding()
    }
    .background(Color(.systemBackground))
}
