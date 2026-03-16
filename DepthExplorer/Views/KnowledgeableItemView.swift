import SwiftUI

struct KnowledgeableItemView: View {
    let item: KnowledgeableItem
    let isLeftSide: Bool
    let scalingFactor: Double
    let contentOffset: Double

    private let hPadding = 60.0

    var yPosition: Double {
        item.depth * scalingFactor
    }

    var xPosition: Double {
        isLeftSide ? hPadding : UIScreen.main.bounds.width - hPadding
    }

    var isVisible: Bool {
        let itemScreenY = yPosition - contentOffset + UIScreen.main.bounds.height / 3
        return itemScreenY > -300 && itemScreenY < UIScreen.main.bounds.height + 300
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .blur(radius: 8)
                Circle()
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: 50, height: 50)
                Image(systemName: item.image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .frame(width: 50, height: 50)
                    .clipShape(.circle)
            }

            Text(item.name)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                }
        }
        .position(x: xPosition, y: yPosition)
        .offset(x: isVisible ? 0 : (isLeftSide ? -200 : 200))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
    }
}

#Preview {
    VStack {
        KnowledgeableItemView(
            item: KnowledgeableItem.allItems[0],
            isLeftSide: true,
            scalingFactor: 1,
            contentOffset: 0
        )

        KnowledgeableItemView(
            item: KnowledgeableItem.allItems[3],
            isLeftSide: false,
            scalingFactor: 1,
            contentOffset: 0
        )
    }
    .background(Color.abyssBlue)
}
