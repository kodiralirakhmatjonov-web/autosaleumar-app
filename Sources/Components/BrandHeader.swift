import SwiftUI

struct BrandHeader: View {
    @Environment(\.colorScheme) private var scheme
    var trailingSymbol: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(scheme == .dark ? "WordmarkWhite" : "WordmarkBlack")
                .resizable()
                .scaledToFit()
                .frame(width: 152, alignment: .leading)
                .accessibilityLabel("Auto Sale Umar")

            Spacer()

            if let trailingSymbol, let trailingAction {
                ASUGlassIconButton(symbol: trailingSymbol, accessibilityLabel: "Auto Sale Umar", action: trailingAction)
            }
        }
        .padding(.horizontal, ASUDesign.pagePadding)
        .padding(.top, 5)
    }
}
