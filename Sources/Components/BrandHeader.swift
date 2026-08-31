import SwiftUI

struct BrandHeader: View {
    @Environment(\.colorScheme) private var scheme
    var trailingSymbol: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Image(scheme == .dark ? "WordmarkWhite" : "WordmarkBlack")
                .resizable().scaledToFit().frame(width: 150, alignment: .leading)
                .accessibilityLabel("Auto Sale Umar")
            Spacer()
            if let trailingSymbol, let trailingAction {
                Button(action: trailingAction) {
                    Image(systemName: trailingSymbol).font(.system(size: 17, weight: .semibold)).frame(width: 42, height: 42)
                        .background(.thinMaterial, in: Circle())
                        .overlay(Circle().stroke(ASUDesign.line, lineWidth: 0.75))
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, ASUDesign.pagePadding)
        .padding(.top, 8)
    }
}
