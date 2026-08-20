import SwiftUI
import Foundation

// MARK: - Spacing and geometry

/// Small, shared visual vocabulary for the UX2 pass. It intentionally remains
/// a namespace in this target rather than becoming a separate design system.
enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
}

/// Existing views use the shorter name. Keep that source compatibility while
/// exposing the V2 token names above.
typealias Spacing = AppSpacing

extension AppSpacing {
    static let micro = xxs
    static let related = xs
    static let grouped = sm
    static let standard = md
    static let sectionGap = lg
    static let major = xl
}

enum AppRadius {
    static let compact: CGFloat = 8
    static let interactive: CGFloat = 10
    static let section: CGFloat = 12
    static let hero: CGFloat = 16
}

// MARK: - Adaptive content

/// Constrains single-column pages to a readable measure while keeping a
/// slightly smaller inset at the existing minimum window width.
struct AdaptiveContentContainer<Content: View>: View {
    private let maxWidth: CGFloat
    private let content: Content

    init(maxWidth: CGFloat = 1040, @ViewBuilder content: () -> Content) {
        self.maxWidth = maxWidth
        self.content = content()
    }

    var body: some View {
        AdaptiveContentLayout(maxWidth: maxWidth) {
            content
        }
    }
}

private struct AdaptiveContentLayout: Layout {
    let maxWidth: CGFloat

    private let regularPadding: CGFloat = 28
    private let compactPadding: CGFloat = 20
    private let topPadding: CGFloat = 24
    private let bottomPadding: CGFloat = 32

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        guard let subview = subviews.first else { return .zero }

        let availableWidth = proposal.width ?? (maxWidth + regularPadding * 2)
        let padding = horizontalPadding(for: availableWidth)
        let contentWidth = min(maxWidth, max(0, availableWidth - padding * 2))
        let contentSize = subview.sizeThatFits(
            ProposedViewSize(width: contentWidth, height: proposal.height)
        )

        return CGSize(
            width: proposal.width ?? availableWidth,
            height: topPadding + contentSize.height + bottomPadding
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        guard let subview = subviews.first else { return }

        let padding = horizontalPadding(for: bounds.width)
        let contentWidth = min(maxWidth, max(0, bounds.width - padding * 2))
        let x = bounds.minX + max(0, (bounds.width - contentWidth) / 2)

        subview.place(
            at: CGPoint(x: x, y: bounds.minY + topPadding),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: contentWidth, height: nil)
        )
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width < 960 ? compactPadding : regularPadding
    }
}

// MARK: - Localized presentation formatters

enum AppFormatters {
    static let frenchLocale = Locale(identifier: "fr_FR")

    static func absoluteDate(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(date: .long, time: .shortened)
                .locale(frenchLocale)
        )
    }

    static func observationDate(_ date: Date, now: Date = Date()) -> String {
        if Calendar.current.isDate(date, inSameDayAs: now) {
            let time = date.formatted(
                Date.FormatStyle(date: .omitted, time: .shortened)
                    .locale(frenchLocale)
            )
            return "aujourd’hui à \(time)"
        }
        return absoluteDate(date)
    }

    static func relativeDate(_ date: Date) -> String {
        date.formatted(
            .relative(presentation: .named, unitsStyle: .abbreviated)
                .locale(frenchLocale)
        )
    }

    static func time(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(date: .omitted, time: .shortened)
                .locale(frenchLocale)
        )
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let positiveSeconds = max(0.0, seconds)
        let hasFraction = positiveSeconds
            .truncatingRemainder(dividingBy: 1) > 0.0001
        let style = Duration.UnitsFormatStyle(
            allowedUnits: [.hours, .minutes, .seconds],
            width: .abbreviated,
            maximumUnitCount: nil,
            zeroValueUnits: .hide,
            valueLength: nil,
            fractionalPart: hasFraction ? .show(length: 1) : .hide
        )
        .locale(frenchLocale)

        return Duration.seconds(positiveSeconds).formatted(style)
    }
}

// MARK: - Shared surfaces and metrics

enum SemanticSurfaceTone {
    case neutral
    case success
    case attention
    case error
    case accent

    var tint: Color {
        switch self {
        case .neutral: return .primary
        case .success: return .green
        case .attention: return .orange
        case .error: return .red
        case .accent: return .accentColor
        }
    }

    var tintOpacity: Double {
        switch self {
        case .neutral: return 0
        case .success, .attention, .error, .accent: return 0.07
        }
    }
}

struct SemanticSurface<Content: View>: View {
    let tone: SemanticSurfaceTone
    var cornerRadius: CGFloat = AppRadius.section
    let content: Content

    init(
        tone: SemanticSurfaceTone = .neutral,
        cornerRadius: CGFloat = AppRadius.section,
        @ViewBuilder content: () -> Content
    ) {
        self.tone = tone
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tone.tint.opacity(tone.tintOpacity))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    }
            }
    }
}

struct SectionSurface<Content: View>: View {
    let title: String?
    let subtitle: String?
    let tone: SemanticSurfaceTone
    let content: Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        tone: SemanticSurfaceTone = .neutral,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.tone = tone
        self.content = content()
    }

    var body: some View {
        SemanticSurface(tone: tone) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if let title {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(title)
                            .font(.headline)
                        if let subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
        }
    }
}

struct MetricItemView: View {
    let label: String
    let value: String
    var symbolName: String?
    var tint: Color?

    init(
        label: String,
        value: String,
        symbolName: String? = nil,
        tint: Color? = nil
    ) {
        self.label = label
        self.value = value
        self.symbolName = symbolName
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                if let symbolName {
                    Image(systemName: symbolName)
                        .font(.caption)
                        .foregroundStyle(tint ?? .secondary)
                        .accessibilityHidden(true)
                }
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint ?? .primary)
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("(label) : (value)")
    }
}

// MARK: - Semantic tints (spec 18.4)

/// Colours always accompany a label or a symbol; they never carry meaning
/// alone (FR-STATE-03).
extension SystemState {
    var tint: Color {
        switch self {
        case .unknown: return .secondary
        case .checking: return .accentColor
        case .healthy: return .green
        case .attention: return .orange
        case .error: return .red
        }
    }
}

extension ProjectState {
    var tint: Color {
        switch self {
        case .unknown: return .secondary
        case .healthy: return .green
        case .attention: return .orange
        case .error: return .red
        case .disabled: return .secondary
        }
    }
}

extension OperationStatus {
    var tint: Color {
        switch self {
        case .queued: return .secondary
        case .running: return .accentColor
        case .succeeded: return .green
        case .partiallySucceeded: return .orange
        case .failed: return .red
        case .cancelled: return .secondary
        }
    }
}

extension SkillStatus {
    var tint: Color {
        switch self {
        case .managedSynced:
            return .green
        case .expectedClaudeOnly, .expectedCodexOnly:
            return .secondary
        case .conflict, .manifestError:
            return .red
        default:
            return .orange
        }
    }
}

extension ActionSeverity {
    var tint: Color {
        switch self {
        case .attention: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Motion (spec 19.4)

extension View {
    /// Applies a short, functional transition unless the viewer asked for
    /// reduced motion. No animation is ever required to understand a state.
    func functionalAnimation<V: Equatable>(
        _ value: V,
        reduceMotion: Bool
    ) -> some View {
        animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: value)
    }
}
