import SwiftUI

/// Glossary content without navigation chrome — embeddable inside a parent NavigationStack (e.g. HubView).
struct GlossaryContentView: View {
    let discoveredItems: Set<String>

    private var itemsByCategory: [(KnowledgeableCategory, [KnowledgeableItem])] {
        KnowledgeableCategory.allCases.compactMap { category in
            let items = KnowledgeableItem.allItems.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    private var discoveredCount: Int {
        KnowledgeableItem.allItems.filter { discoveredItems.contains($0.name) }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                progressHeader

                ForEach(itemsByCategory, id: \.0) { category, items in
                    categorySection(category: category, items: items)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(white: 0.06))
    }

    // MARK: - Progress header

    private var progressHeader: some View {
        let total = KnowledgeableItem.allItems.count
        let fraction = total > 0 ? Double(discoveredCount) / Double(total) : 0

        return VStack(spacing: 8) {
            Text("\(discoveredCount) / \(total) Discovered")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.12))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.cyan)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Category section

    private func categorySection(category: KnowledgeableCategory, items: [KnowledgeableItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(categoryLabel(category))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)

            ForEach(items) { item in
                let isDiscovered = discoveredItems.contains(item.name)
                itemRow(item: item, isDiscovered: isDiscovered)
            }
        }
    }

    // MARK: - Item row

    private func itemRow(item: KnowledgeableItem, isDiscovered: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isDiscovered ? Color.cyan.opacity(0.2) : Color.white.opacity(0.08))
                    .frame(width: 44, height: 44)
                if isDiscovered {
                    Image(systemName: item.image)
                        .font(.system(size: 20))
                        .foregroundStyle(.cyan)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                // Name
                HStack {
                    Text(isDiscovered ? item.name : "???")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isDiscovered ? .white : .white.opacity(0.35))

                    Spacer()

                    Text("\(Int(item.depth))m")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }

                // Description
                if isDiscovered {
                    Text(item.description)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(3)
                } else {
                    Text("Dive to \(Int(item.depth))m to discover")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.25))
                        .italic()
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isDiscovered ? Color.white.opacity(0.06) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isDiscovered ? Color.cyan.opacity(0.2) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func categoryLabel(_ category: KnowledgeableCategory) -> String {
        switch category {
        case .species: "Species"
        case .oceanography: "Oceanography"
        case .humanHistory: "Human History"
        case .humanImpact: "Human Impact"
        }
    }
}

/// Standalone glossary sheet with its own NavigationStack and Done button.
/// Used when presenting the glossary outside of HubView.
struct GlossaryView: View {
    let discoveredItems: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            GlossaryContentView(discoveredItems: discoveredItems)
                .navigationTitle("Glossary")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
                .preferredColorScheme(.dark)
        }
    }
}

#Preview("Some discovered") {
    GlossaryView(discoveredItems: ["Clownfish", "Brine Pools"])
}

#Preview("None discovered") {
    GlossaryView(discoveredItems: [])
}

#Preview("All discovered") {
    GlossaryView(discoveredItems: Set(KnowledgeableItem.allItems.map(\.name)))
}
