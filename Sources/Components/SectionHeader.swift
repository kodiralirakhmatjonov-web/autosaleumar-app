import SwiftUI

struct SectionHeader: View {
    let eyebrow: String?
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                if let eyebrow { Text(eyebrow.uppercased()).font(.system(size: 10.5, weight: .bold, design: .rounded)).tracking(1.0).foregroundStyle(.secondary) }
                Text(title).font(.system(size: 24, weight: .bold, design: .rounded)).tracking(-0.5)
            }
            Spacer()
            if let actionTitle, let action { Button(actionTitle, action: action).font(.system(size: 12.5, weight: .semibold)).buttonStyle(.plain).foregroundStyle(.secondary) }
        }
    }
}
