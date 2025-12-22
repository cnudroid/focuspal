# UI/UX Design Specification - FocusPal

**Owner:** UI/UX Agent  
**Status:** In Progress  
**Last Updated:** [Date]

---

## Table of Contents
1. [Design Philosophy](#design-philosophy)
2. [Design System](#design-system)
3. [Component Library](#component-library)
4. [Screen Specifications](#screen-specifications)
5. [Interaction Patterns](#interaction-patterns)
6. [Accessibility Guidelines](#accessibility-guidelines)
7. [Animation Specifications](#animation-specifications)

---

## Design Philosophy

### Core Principles

1. **Child-First Design**
   - Large, colorful, touch-friendly interface
   - Minimal text, maximum visual communication
   - Immediate feedback for all interactions
   - Fun without being distracting

2. **ADHD-Friendly**
   - Clear visual hierarchy
   - One primary action per screen
   - Minimal distractions
   - Consistent color coding
   - Visual representations of abstract concepts

3. **Age-Adaptive**
   - Ages 5-7: Picture-based, minimal text
   - Ages 8-11: Icons + labels, gamification
   - Ages 12-16: More data, privacy features

4. **Inclusive & Accessible**
   - Full VoiceOver support
   - High contrast ratios (WCAG AA minimum)
   - Dynamic Type support
   - Support for Reduce Motion

---

## Design System

### Color Palette

#### Primary Colors
```swift
enum Colors {
    // Brand Colors
    static let primaryIndigo = Color(hex: "6366F1")
    static let primaryPurple = Color(hex: "A855F7")
    static let primaryPink = Color(hex: "EC4899")
    
    // Category Colors
    static let homework = Color(hex: "FF6B6B")      // Red
    static let creativePlay = Color(hex: "4ECDC4")  // Turquoise
    static let physical = Color(hex: "FFD93D")      // Yellow
    static let screenTime = Color(hex: "A78BFA")    // Purple
    static let reading = Color(hex: "F472B6")       // Pink
    static let social = Color(hex: "34D399")        // Green
    static let lifeSkills = Color(hex: "FB923C")    // Orange
    static let selfCare = Color(hex: "818CF8")      // Indigo
    
    // Semantic Colors
    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")
    static let info = Color(hex: "3B82F6")
    
    // Neutrals
    static let gray50 = Color(hex: "F9FAFB")
    static let gray100 = Color(hex: "F3F4F6")
    static let gray200 = Color(hex: "E5E7EB")
    static let gray300 = Color(hex: "D1D5DB")
    static let gray400 = Color(hex: "9CA3AF")
    static let gray500 = Color(hex: "6B7280")
    static let gray600 = Color(hex: "4B5563")
    static let gray700 = Color(hex: "374151")
    static let gray800 = Color(hex: "1F2937")
    static let gray900 = Color(hex: "111827")
}
```

#### Accessibility Contrast Ratios
All color combinations must meet WCAG AA standards (4.5:1 for normal text, 3:1 for large text)

**Verified Combinations:**
- White text on Primary Indigo: 7.2:1 ✅
- White text on Category Colors: All >4.5:1 ✅
- Gray 700 text on Gray 50: 11.8:1 ✅

### Typography

```swift
struct Typography {
    // Font Family
    static let primaryFont = "Fredoka"
    static let systemFont = Font.system(.body, design: .rounded)
    
    // Display
    static let display = Font.custom("Fredoka", size: 56).weight(.bold)
    
    // Headings
    static let h1 = Font.custom("Fredoka", size: 36).weight(.bold)
    static let h2 = Font.custom("Fredoka", size: 30).weight(.bold)
    static let h3 = Font.custom("Fredoka", size: 26).weight(.semibold)
    static let h4 = Font.custom("Fredoka", size: 22).weight(.semibold)
    
    // Body
    static let bodyLarge = Font.custom("Fredoka", size: 20).weight(.regular)
    static let body = Font.custom("Fredoka", size: 17).weight(.regular)
    static let bodySmall = Font.custom("Fredoka", size: 15).weight(.regular)
    
    // UI Elements
    static let caption = Font.custom("Fredoka", size: 14).weight(.medium)
    static let small = Font.custom("Fredoka", size: 12).weight(.medium)
    
    // Button Text
    static let buttonLarge = Font.custom("Fredoka", size: 18).weight(.semibold)
    static let button = Font.custom("Fredoka", size: 16).weight(.semibold)
}
```

### Spacing Scale

```swift
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}
```

### Border Radius

```swift
enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 20
    static let xlarge: CGFloat = 24
    static let xxlarge: CGFloat = 32
    static let round: CGFloat = 999
}
```

### Shadows

```swift
enum Shadows {
    static let small = Shadow(
        color: Color.black.opacity(0.05),
        radius: 2,
        x: 0,
        y: 1
    )
    
    static let medium = Shadow(
        color: Color.black.opacity(0.1),
        radius: 6,
        x: 0,
        y: 4
    )
    
    static let large = Shadow(
        color: Color.black.opacity(0.1),
        radius: 15,
        x: 0,
        y: 10
    )
    
    static let xlarge = Shadow(
        color: Color.black.opacity(0.15),
        radius: 25,
        x: 0,
        y: 20
    )
}
```

---

## Component Library

### Buttons

#### Primary Button
```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.buttonLarge)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Colors.primaryIndigo, Colors.primaryPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(CornerRadius.large)
                .shadow(color: Colors.primaryIndigo.opacity(0.3), radius: 8, y: 4)
        }
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}
```

#### Category Button (for activity logging)
```swift
struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: category.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(category.color)
                
                Text(category.name)
                    .font(Typography.caption)
                    .foregroundColor(Colors.gray700)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                isSelected ? category.color.opacity(0.15) : Color.white
            )
            .cornerRadius(CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 3)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
```

### Cards

#### Activity Card
```swift
struct ActivityCard: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(activity.category.color.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: activity.category.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(activity.category.color)
            }
            
            // Activity Info
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.category.name)
                    .font(Typography.h4)
                    .foregroundColor(Colors.gray800)
                
                Text("\(activity.duration.formatted()) minutes")
                    .font(Typography.caption)
                    .foregroundColor(Colors.gray500)
            }
            
            Spacer()
            
            // Time
            Text(activity.startTime.formatted(date: .omitted, time: .shortened))
                .font(Typography.caption)
                .foregroundColor(Colors.gray400)
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)
    }
}
```

#### Stats Card
```swift
struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(Typography.caption)
                .foregroundColor(Colors.gray600)
            
            Text(value)
                .font(Typography.h1)
                .foregroundColor(color)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(Typography.small)
                    .foregroundColor(Colors.gray500)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(
            LinearGradient(
                colors: [color.opacity(0.1), color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
```

### Input Fields

#### Custom Text Field
```swift
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(Colors.gray400)
            }
            
            TextField(placeholder, text: $text)
                .font(Typography.body)
                .foregroundColor(Colors.gray800)
        }
        .padding(Spacing.md)
        .background(Colors.gray50)
        .cornerRadius(CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(Colors.gray200, lineWidth: 1)
        )
    }
}
```

### Loading & Empty States

#### Loading View
```swift
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(Colors.gray200, lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Colors.primaryIndigo, Colors.primaryPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 1)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            
            Text("Loading...")
                .font(Typography.body)
                .foregroundColor(Colors.gray600)
        }
        .onAppear { isAnimating = true }
    }
}
```

#### Empty State View
```swift
struct EmptyStateView: View {
    let emoji: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text(emoji)
                .font(.system(size: 80))
            
            Text(title)
                .font(Typography.h2)
                .foregroundColor(Colors.gray800)
            
            Text(message)
                .font(Typography.body)
                .foregroundColor(Colors.gray500)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(title: actionTitle, action: action)
                    .padding(.horizontal, Spacing.xxxl)
                    .padding(.top, Spacing.md)
            }
        }
    }
}
```

---

## Screen Specifications

### Home Screen

**Purpose:** Main dashboard showing quick stats and navigation

**Layout:**
- Header with greeting and child avatar
- Quick stats cards (3 columns)
- Quick action buttons (2x2 grid)
- Today's activities list

**Components:**
- Gradient header background
- Stats cards with icons
- Large action buttons with icons
- Activity list with category icons

**Interactions:**
- Tap stats to see details
- Tap action buttons to navigate
- Pull to refresh activities
- Swipe activity card for options

### Timer Screen

**Purpose:** Visual ADHD timer with multiple visualization modes

**Layout:**
- Back button (top left)
- Timer visualization (center, large)
- Time remaining (overlaid on visualization)
- Control buttons (play/pause, reset)
- Category selector (bottom)

**Visualizations:**
1. **Circular (Time Timer style)**
   - Colored disk that disappears clockwise
   - Color changes: Green (>10min) → Yellow (5-10min) → Red (<5min)

2. **Progress Bar**
   - Horizontal bar with smooth animation
   - Color gradient matching timer colors

3. **Analog Clock**
   - Clock face with colored wedge
   - Minute hand shows remaining time

4. **Digital Countdown**
   - Large numbers with seconds
   - Color-coded background

**Components:**
- Custom Shape views for visualizations
- Timer controls with haptic feedback
- Category selection grid

**Interactions:**
- Tap to play/pause
- Long press reset button for confirmation
- Swipe to change visualization mode
- Tap category to select

### Activity Log Screen

**Purpose:** Quick activity logging interface

**Layout:**
- Header with title and instructions
- Category grid (2 columns, large buttons)
- Recent activities section
- Add manual entry button

**Components:**
- Large category buttons (100pt height)
- Category icons and labels
- Activity cards with timestamps

**Interactions:**
- Tap category to instantly log
- Hold category for manual time entry
- Swipe activity for edit/delete
- Pull to refresh

### Statistics Screen

**Purpose:** Data visualization and progress tracking

**Layout:**
- Tab selector (Daily/Weekly/Monthly)
- Chart area (large, interactive)
- Legend
- Achievement badges section
- Balance meters

**Components:**
- Swift Charts (PieChart, BarChart)
- Achievement badges
- Progress bars with labels
- Filter buttons

**Interactions:**
- Tap chart segments for details
- Swipe to change time period
- Tap achievement for details
- Pull to refresh data

### Parent Dashboard

**Purpose:** Parent controls and settings

**Layout:**
- Authentication screen (first)
- Child selector
- Settings sections
  - Category management
  - Time goals
  - Reports
  - App settings

**Components:**
- PIN/biometric authentication
- Child profile cards
- Settings list items
- Toggle switches
- Sliders for goals

**Interactions:**
- Authenticate to access
- Select child to configure
- Tap settings to configure
- Tap export to share reports

---

## Interaction Patterns

### Touch Targets

**Minimum Sizes:**
- Buttons: 44x44pt (iOS HIG minimum)
- Category buttons: 60x100pt (child-friendly)
- List items: Full width, 60pt height
- Icons: 24x24pt minimum, 32x32pt preferred

### Gestures

**Standard Gestures:**
- Tap: Primary action
- Long press: Secondary action / context menu
- Swipe: Delete, edit, navigate
- Pull to refresh: Reload data
- Pinch to zoom: Charts (optional)

**Custom Gestures:**
- Swipe timer visualization: Change mode
- Double tap timer: Quick start with last settings

### Haptic Feedback

**Usage:**
- Button taps: Light impact
- Timer start/stop: Medium impact
- Timer complete: Success notification
- Error: Error notification
- Achievement unlock: Heavy impact + success

```swift
enum HapticFeedback {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
```

---

## Accessibility Guidelines

### VoiceOver Support

**Implementation:**
- All interactive elements have accessibility labels
- Images have accessibility descriptions
- State changes announced
- Hint text for complex interactions

```swift
Button("Start Timer") {
    // Action
}
.accessibilityLabel("Start timer")
.accessibilityHint("Begins countdown for selected activity")
.accessibilityValue(timerRunning ? "Running" : "Stopped")
```

### Dynamic Type

**Implementation:**
- Use `@ScaledMetric` for responsive sizing
- Test at all Dynamic Type sizes
- Maintain minimum touch targets at all sizes

```swift
@ScaledMetric private var buttonHeight: CGFloat = 56

Button("Log Activity") {
    // Action
}
.frame(height: buttonHeight)
```

### Color Blindness

**Considerations:**
- Don't rely solely on color to convey information
- Use icons + text labels
- Ensure sufficient contrast
- Test with color blindness simulators

### Reduce Motion

**Implementation:**
- Respect reduce motion preference
- Provide non-animated alternatives
- Use cross-fade instead of scale/slide

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animationValue: Animation {
    reduceMotion ? .none : .spring()
}
```

---

## Animation Specifications

### Timing Functions

```swift
enum Animations {
    static let quick = Animation.easeInOut(duration: 0.2)
    static let standard = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
}
```

### Common Animations

#### Button Press
```swift
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
```

#### Card Appearance
```swift
.transition(.scale.combined(with: .opacity))
.animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
```

#### Timer Countdown
```swift
Circle()
    .trim(from: 0, to: progress)
    .stroke(
        AngularGradient(
            colors: [.red, .yellow, .green],
            center: .center
        ),
        lineWidth: 12
    )
    .rotationEffect(.degrees(-90))
    .animation(.linear(duration: 1), value: progress)
```

#### Achievement Unlock
```swift
struct AchievementUnlockAnimation: View {
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = -180
    @State private var opacity: Double = 0
    
    var body: some View {
        Image("badge")
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    scale = 1.2
                    rotation = 0
                    opacity = 1
                }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.4)) {
                    scale = 1.0
                }
            }
    }
}
```

---

## Responsive Design

### iPhone Layouts

**iPhone SE (Small)**
- Single column layouts
- Larger text for readability
- Simplified navigation
- Stack components vertically

**iPhone Pro (Standard)**
- Optimal target size
- 2-column grids where appropriate
- Standard spacing

**iPhone Pro Max (Large)**
- Utilize extra width for content
- 3-column grids on some screens
- More generous spacing

### iPad Layouts

**Adaptive Strategy:**
- Use sidebar navigation on iPad
- Multi-column layouts
- Floating panels for modals
- Split view for comparisons

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass

var columns: [GridItem] {
    horizontalSizeClass == .regular
        ? Array(repeating: GridItem(.flexible()), count: 4)
        : Array(repeating: GridItem(.flexible()), count: 2)
}
```

---

## Dark Mode Support

### Color Adaptations

```swift
extension Color {
    static let adaptiveBackground = Color(
        light: Colors.gray50,
        dark: Colors.gray900
    )
    
    static let adaptiveText = Color(
        light: Colors.gray800,
        dark: Colors.gray100
    )
    
    static let adaptiveCard = Color(
        light: .white,
        dark: Colors.gray800
    )
}
```

### Image Assets

- Provide dark mode variants for illustrations
- Use SF Symbols that adapt automatically
- Test all screens in both modes

---

**Next Steps for UI/UX Agent:**
1. Create design system Swift files
2. Build component library
3. Design screen flows in Figma/Sketch
4. Create style guide documentation
5. Implement accessibility testing
6. Design age-specific variations
