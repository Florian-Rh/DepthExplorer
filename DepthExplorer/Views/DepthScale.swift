import SwiftUI

struct DepthScale: View {
    let maximumDepth: Double
    let factor: Double

    var depths: [Int] {
        // Start with 50m and double until 1000m
        var markers = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90]

        // Add 1000m increments up to maximumDepth
        var current = 100
        while current <= Int(maximumDepth) {
            markers.append(current)
            current += 100
        }
        
        return markers
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            ForEach(depths, id: \.self) { depth in
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(.white.opacity(0.5))
                        .frame(width: 50, height: 2)

                    Text("\(depth)m")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Rectangle()
                        .fill(.white.opacity(0.5))
                        .frame(width: 50, height: 2)
                }
                .position(x: UIScreen.main.bounds.width / 2, y: Double(depth) * factor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    DepthScale(maximumDepth: 5000, factor: 10)
        .background(.black)
}
