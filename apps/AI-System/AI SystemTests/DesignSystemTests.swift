import Foundation
import Testing
@testable import AI_System

@Suite("UX2 presentation formatters")
struct DesignSystemTests {

    @Test("Absolute dates use French long date and short time")
    func absoluteDateIsFrench() {
        let date = ISO8601DateFormatter().date(from: "2026-08-20T19:18:00Z")!
        let formatted = AppFormatters.absoluteDate(date)

        #expect(formatted.contains("août"))
        #expect(formatted.contains("2026"))
        #expect(formatted.contains("21:18"))
    }

    @Test("Today's observation uses a concise localized label")
    func todayObservationIsConcise() {
        let now = Date()
        let formatted = AppFormatters.observationDate(
            now.addingTimeInterval(-60),
            now: now
        )

        #expect(formatted.contains("aujourd’hui"))
        #expect(formatted.contains(":"))
    }

    @Test("Relative dates use a human French expression")
    func relativeDateIsFrench() {
        let formatted = AppFormatters.relativeDate(Date(timeIntervalSinceNow: -240))

        #expect(formatted.contains("il y a"))
        #expect(formatted.contains("min"))
    }

    @Test("Durations use French decimal separators and units")
    func durationIsLocalized() {
        let short = AppFormatters.duration(1.4)
        let compound = AppFormatters.duration(237)

        #expect(short.contains("1,4"))
        #expect(short.contains("s"))
        #expect(compound.contains("3"))
        #expect(compound.contains("min"))
        #expect(compound.contains("57"))
        #expect(compound.contains("s"))
    }
}
