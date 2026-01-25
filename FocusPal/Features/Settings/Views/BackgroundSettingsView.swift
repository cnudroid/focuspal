//
//  BackgroundSettingsView.swift
//  FocusPal
//
//  Settings view for customizing animated backgrounds.
//

import SwiftUI

/// Settings view for choosing animated background styles
struct BackgroundSettingsView: View {
    @Binding var preferences: ChildPreferences
    let themeColor: String

    @State private var showingFullPreview = false
    @State private var previewStyle: ChildPreferences.BackgroundStylePreference = .automatic

    private var theme: BackgroundTheme {
        switch themeColor.lowercased() {
        case "pink": return .pink
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        default: return .blue
        }
    }

    var body: some View {
        List {
            // Enable/Disable toggle section
            Section {
                Toggle(isOn: $preferences.animatedBackgroundsEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.purple)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Animated Backgrounds")
                                .font(.body)
                            Text("Turn off to save battery")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Animation")
            }

            // Style picker section (only shown when enabled)
            if preferences.animatedBackgroundsEnabled {
                Section {
                    // Horizontal scroll of preview cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ChildPreferences.BackgroundStylePreference.allCases, id: \.self) { style in
                                BackgroundPreviewCard(
                                    style: style,
                                    theme: theme,
                                    isSelected: preferences.backgroundStyle == style,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3)) {
                                            preferences.backgroundStyle = style
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                    // Description of selected style
                    HStack {
                        Image(systemName: preferences.backgroundStyle.iconName)
                            .foregroundColor(.accentColor)
                        Text(preferences.backgroundStyle.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                } header: {
                    Text("Background Style")
                } footer: {
                    Text("Tap a style to preview. Your choice is saved automatically.")
                }

                // Full-screen preview button
                Section {
                    Button {
                        previewStyle = preferences.backgroundStyle
                        showingFullPreview = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.expand.vertical")
                                .foregroundColor(.accentColor)
                            Text("Full Screen Preview")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Battery info section
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "battery.100")
                        .font(.title2)
                        .foregroundColor(.green)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Battery Tips")
                            .font(.subheadline.weight(.medium))

                        Text("\"Simple\" and \"Gradient\" use less battery. \"Floating Shapes\" and \"Bubbles\" use more.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Backgrounds")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingFullPreview) {
            BackgroundFullPreview(
                style: previewStyle,
                theme: theme,
                onDismiss: { showingFullPreview = false }
            )
        }
    }
}

// MARK: - Full Screen Preview

struct BackgroundFullPreview: View {
    let style: ChildPreferences.BackgroundStylePreference
    let theme: BackgroundTheme
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // The background
            backgroundForStyle
                .ignoresSafeArea()

            // Content overlay
            VStack {
                // Close button
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(radius: 4)
                    }
                    .padding()
                }

                Spacer()

                // Style name
                VStack(spacing: 8) {
                    Image(systemName: style.iconName)
                        .font(.system(size: 40))
                        .foregroundColor(.white)

                    Text(style.displayName)
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text(style.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )

                Spacer()

                // Tap to dismiss hint
                Text("Tap X to close")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 40)
            }
        }
    }

    @ViewBuilder
    private var backgroundForStyle: some View {
        switch style {
        case .automatic:
            // Show combined for automatic preview
            CombinedAnimatedBackground(theme: theme)
        case .gradient:
            AnimatedGradientBackground(theme: theme)
        case .floatingShapes:
            FloatingShapesBackground(theme: theme, shapeCount: 15)
        case .bubbles:
            BubbleBackground(theme: theme, bubbleCount: 20)
        case .waves:
            WaveBackground(theme: theme, waveCount: 4)
        case .sparkles:
            SparkleBackground(sparkleCount: 40)
        case .clouds:
            CloudBackground(cloudCount: 10)
        case .combined:
            CombinedAnimatedBackground(theme: theme)
        case .solid:
            SolidBackground(theme: theme)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BackgroundSettingsView(
            preferences: .constant(ChildPreferences()),
            themeColor: "blue"
        )
    }
}
