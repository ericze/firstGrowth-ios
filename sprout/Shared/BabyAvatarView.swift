import SwiftUI

struct BabyAvatarView: View {
    let avatarPath: String?
    let monogram: String
    let size: CGFloat

    @State private var loadedImage: UIImage?

    var body: some View {
        Group {
            if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(monogram)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
        }
        .frame(width: size, height: size)
        .background(AppTheme.Colors.cardBackground)
        .overlay {
            Circle()
                .stroke(AppTheme.Colors.divider, lineWidth: 1)
        }
        .clipShape(Circle())
        .onAppear { loadImage() }
        .onChange(of: avatarPath) { _, _ in loadImage() }
    }

    private func loadImage() {
        guard let path = avatarPath, !path.isEmpty else {
            loadedImage = nil
            return
        }
        loadedImage = UIImage(contentsOfFile: path)
    }
}
