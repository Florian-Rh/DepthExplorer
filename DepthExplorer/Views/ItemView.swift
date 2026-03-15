import SwiftUI

struct ItemDescription: View {
    let text: String
    
    var body: some View {
        Text(text)
            .frame(width: 240)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
            .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
}

struct ItemView: View {
    let item: Item
    let isLeftSide: Bool
    let scalingFactor: Double
    let contentOffset: Double
    private let hPadding = 60.0
    @State private var isExpanded = false

    var yPosition: Double {
        item.depth * scalingFactor
    }
    
    var xPosition: Double {
        isLeftSide ? hPadding : UIScreen.main.bounds.width - hPadding
    }

    /// The item is visible when it's within ~300pts of the visible area
    var isVisible: Bool {
        let itemScreenY = yPosition - contentOffset + UIScreen.main.bounds.height / 3
        return itemScreenY > -300 && itemScreenY < UIScreen.main.bounds.height + 300
    }

    var body: some View {
        HStack(spacing: 8) {
            if isExpanded, let description = item.description, !isLeftSide {
                ItemDescription(text: description)
            }
            
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
            
            if isExpanded, let description = item.description, isLeftSide {
                ItemDescription(text: description)
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }
        .position(x: xPosition, y: yPosition)
        .offset(x: isVisible ? 0 : (isLeftSide ? -200 : 200))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
    }
}

#Preview {
    VStack {
        ItemView(
            item: Item(
                depth: 100,
                name: "Left Item",
                image: "star",
                description: "This"
            ),
            isLeftSide: true,
            scalingFactor: 1,
            contentOffset: 0
        )
        
        ItemView(
            item: Item(
                depth: 200,
                name: "Right Item",
                image: "moon",
                description: "eScooter, die ins Meer geworfen werden, stellen ein ernsthaftes Umweltproblem dar. Ihre Batterien enthalten Schwermetalle und Chemikalien, die ins Wasser gelangen und Meerestiere sowie das Ökosystem schädigen können. Zudem verschmutzen sie den Lebensraum und verursachen Kosten für Bergung und Entsorgung."
            ),
            isLeftSide: false,
            scalingFactor: 1,
            contentOffset: 0
        )
    }
    .background(Color.abyssBlue)
}
