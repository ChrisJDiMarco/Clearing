import SwiftUI

/// A carefully framed still of the crystal. The edge fade lets its photographed
/// floor light disappear into the native screen background without a hard tile.
struct CrystalArtView: View {
    let name: String

    var body: some View {
        GeometryReader { geometry in
            Image(name)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .mask {
                    Rectangle()
                        .fill(LinearGradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.075),
                            .init(color: .black, location: 0.925),
                            .init(color: .clear, location: 1)
                        ], startPoint: .leading, endPoint: .trailing))
                        .mask {
                            Rectangle()
                                .fill(LinearGradient(stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 0.09),
                                    .init(color: .black, location: 0.88),
                                    .init(color: .clear, location: 1)
                                ], startPoint: .top, endPoint: .bottom))
                        }
                }
        }
        .accessibilityHidden(true)
    }
}
