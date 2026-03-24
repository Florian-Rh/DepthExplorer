import SwiftUI

/// Displays the highest-severity active warning as a single-line banner.
/// Hidden when no warnings are active.
struct WarningBannerView: View {
    let warnings: [DiveWarning]

    /// The most severe active warning, if any.
    private var topWarning: DiveWarning? {
        warnings.max(by: { $0.severity < $1.severity })
    }

    private func severityColor(_ severity: DiveWarningSeverity) -> Color {
        switch severity {
        case .caution: .yellow
        case .critical: .orange
        case .fatal: .red
        }
    }

    var body: some View {
        let warning = topWarning
        let color = warning.map { severityColor($0.severity) } ?? .clear

        HStack(spacing: 5) {
            Image(systemName: warning?.severity == .fatal ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                .font(.system(size: 10, weight: .bold))
            Text(warning?.message ?? " ")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(warning != nil ? 0.15 : 0), in: RoundedRectangle(cornerRadius: 6))
        .opacity(warning != nil ? 1 : 0)
    }
}

#Preview {
    ZStack {
        Color(white: 0.08)
        VStack(spacing: 12) {
            WarningBannerView(warnings: [])
            WarningBannerView(warnings: [
                DiveWarning(kind: .airSupply, severity: .caution, message: "50 bar remaining")
            ])
            WarningBannerView(warnings: [
                DiveWarning(kind: .decompression, severity: .critical, message: "Ascending too fast! (22.3 m/s)")
            ])
            WarningBannerView(warnings: [
                DiveWarning(kind: .thermal, severity: .fatal, message: "Severe hypothermia! (34.0°C)")
            ])
        }
        .padding()
    }
}
