import SwiftUI

struct TrashItemView: View {
    let item: TrashItem
    let scalingFactor: Double
    let contentOffset: Double
    let screenSize: CGSize

    private let hPadding = 50.0

    var yPosition: Double {
        item.depth * scalingFactor
    }

    var xPosition: Double {
        item.isLeftSide ? hPadding : screenSize.width - hPadding
    }

    var isVisible: Bool {
        let itemScreenY = yPosition - contentOffset + screenSize.height / 3
        return itemScreenY > -200 && itemScreenY < screenSize.height + 200
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.brown.opacity(0.25))
                    .frame(width: 44, height: 44)
                    .blur(radius: 6)
                Circle()
                    .stroke(Color.brown.opacity(0.6), lineWidth: 2)
                    .frame(width: 36, height: 36)
                Image(systemName: "trash.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .frame(width: 36, height: 36)
                    .foregroundStyle(.brown)
            }

            Text("$\(item.sandDollarValue)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.green.opacity(0.8))
        }
        .position(x: xPosition, y: yPosition)
        .offset(x: isVisible ? 0 : (item.isLeftSide ? -150 : 150))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isVisible)
    }
}

#Preview {
    GeometryReader { geo in
        ZStack {
            Color.blue.opacity(0.4)
            TrashItemView(
                item: TrashItem(depth: 20, sandDollarValue: 3, isLeftSide: true),
                scalingFactor: 10,
                contentOffset: 0,
                screenSize: geo.size
            )
        }
    }
}
