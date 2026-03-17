import SwiftUI

struct KnowledgeableItemView: View {
    let item: KnowledgeableItem
    let isLeftSide: Bool
    let scalingFactor: Double
    let contentOffset: Double
    let screenSize: CGSize
    let isDiscovered: Bool

    private let hPadding = 60.0

    var yPosition: Double {
        item.depth * scalingFactor
    }

    var xPosition: Double {
        isLeftSide ? hPadding : screenSize.width - hPadding
    }

    var isVisible: Bool {
        let itemScreenY = yPosition - contentOffset + screenSize.height / 3
        return itemScreenY > -300 && itemScreenY < screenSize.height + 300
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((isDiscovered ? Color.yellow : Color.blue).opacity(0.3))
                    .frame(width: 60, height: 60)
                    .blur(radius: 8)
                Circle()
                    .stroke(isDiscovered ? Color.yellow : Color.blue, lineWidth: 3)
                    .frame(width: 50, height: 50)
                Image(systemName: item.image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .frame(width: 50, height: 50)
                    .clipShape(.circle)
            }
            .scaleEffect(isDiscovered ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isDiscovered)

            Text(item.name)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                }

            if isDiscovered {
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 180)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                    }
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .position(x: xPosition, y: yPosition)
        .offset(x: isVisible ? 0 : (isLeftSide ? -200 : 200))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
        .animation(.easeInOut(duration: 0.3), value: isDiscovered)
    }
}

#Preview {
    GeometryReader { geo in
        VStack {
            KnowledgeableItemView(
                item: KnowledgeableItem.allItems[0],
                isLeftSide: true,
                scalingFactor: 1,
                contentOffset: 0,
                screenSize: geo.size,
                isDiscovered: false
            )

            KnowledgeableItemView(
                item: KnowledgeableItem.allItems[0],
                isLeftSide: false,
                scalingFactor: 1,
                contentOffset: 0,
                screenSize: geo.size,
                isDiscovered: true
            )
        }
    }
    .background(Color.blue.opacity(0.3))
}
