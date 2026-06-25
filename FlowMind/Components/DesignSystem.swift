import SwiftUI

// MARK: - Color Palette
extension Color {
    static let cfPrimary = Color(hex: "#4A90E2")
    static let cfPrimaryLight = Color(hex: "#5BA3F5")
    static let cfPrimaryBright = Color(hex: "#7CB8FF")

    static let cfSuccess = Color(hex: "#4CAF50")
    static let cfSuccessLight = Color(hex: "#6BCB77")

    static let cfAccent = Color(hex: "#FFC933")
    static let cfAccentLight = Color(hex: "#FFD95A")

    static let cfSecondary = Color(hex: "#FF9F5A")
    static let cfSecondaryLight = Color(hex: "#FFB074")

    static let cfAlert = Color(hex: "#FF6B6B")
    static let cfAlertLight = Color(hex: "#FF8787")

    static let cfBg = Color(hex: "#1E1F2B")
    static let cfBgMid = Color(hex: "#26273A")
    static let cfBgLight = Color(hex: "#2F3045")

    static let cfCard = Color(hex: "#2F3147")
    static let cfCardLight = Color(hex: "#3A3D5C")

    static let cfText = Color.white
    static let cfTextSecondary = Color.white.opacity(0.6)
    static let cfTextTertiary = Color.white.opacity(0.35)

    init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if h.count == 6 { h += "FF" }
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        let r = Double((val >> 24) & 0xFF) / 255
        let g = Double((val >> 16) & 0xFF) / 255
        let b = Double((val >> 8) & 0xFF) / 255
        let a = Double(val & 0xFF) / 255
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let cfPrimaryGradient = LinearGradient(
        colors: [.cfPrimary, .cfPrimaryLight],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cfAccentGradient = LinearGradient(
        colors: [.cfAccent, .cfSecondary],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cfSuccessGradient = LinearGradient(
        colors: [.cfSuccess, .cfSuccessLight],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cfBgGradient = LinearGradient(
        colors: [.cfBg, .cfBgMid],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Fonts
extension Font {
    static func cfTitle(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func cfHeadline(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func cfBody(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func cfCaption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func cfDisplay(_ size: CGFloat = 36) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
}

// MARK: - Custom Button Style
struct CFPrimaryButtonStyle: ButtonStyle {
    var color: Color = .cfPrimary
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cfHeadline())
            .foregroundColor(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, fullWidth ? 0 : 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
                    .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 6)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct CFSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cfHeadline())
            .foregroundColor(.cfPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cfPrimary, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Card View
struct CFCard<Content: View>: View {
    var content: () -> Content
    var padding: CGFloat = 16

    init(padding: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cfCard)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
    }
}

// MARK: - Animated Checkbox
struct CFCheckbox: View {
    var isChecked: Bool
    var action: () -> Void
    var color: Color = .cfSuccess

    @State private var scale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                scale = 1.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = 1.0
                }
            }
            action()
        }) {
            ZStack {
                Circle()
                    .fill(isChecked ? color : Color.cfCardLight)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(isChecked ? color : Color.cfTextTertiary, lineWidth: 1.5)
                    )
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress Bar
struct CFProgressBar: View {
    var value: Double
    var color: Color = .cfPrimary
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.cfCardLight)
                    .frame(height: height)
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geo.size.width * min(max(value, 0), 1), height: height)
                    .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 2)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Background
struct CFBackground: View {
    var body: some View {
        LinearGradient.cfBgGradient
            .ignoresSafeArea()
    }
}

// MARK: - Stat Chip
struct CFStatChip: View {
    var label: String
    var value: String
    var color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.cfHeadline(22))
                .foregroundColor(color)
            Text(label)
                .font(.cfCaption())
                .foregroundColor(.cfTextSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.12))
        )
    }
}

// MARK: - Screen Header
struct CFScreenHeader: View {
    var title: String
    var subtitle: String?
    var action: (() -> Void)? = nil
    var actionIcon: String = "plus"

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.cfTitle())
                    .foregroundColor(.cfText)
                if let sub = subtitle {
                    Text(sub)
                        .font(.cfBody())
                        .foregroundColor(.cfTextSecondary)
                }
            }
            Spacer()
            if let action = action {
                Button(action: action) {
                    Image(systemName: actionIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.cfText)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.cfCardLight))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }
}

// MARK: - Color for category
extension RoutineCategory {
    var swiftUIColor: Color {
        Color(hex: self.color)
    }
}

extension TaskStatus {
    var color: Color {
        switch self {
        case .pending: return .cfAccent
        case .inProgress: return .cfPrimary
        case .completed: return .cfSuccess
        case .missed: return .cfAlert
        case .skipped: return .cfTextSecondary
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .missed: return "exclamationmark.circle.fill"
        case .skipped: return "minus.circle.fill"
        }
    }
}
