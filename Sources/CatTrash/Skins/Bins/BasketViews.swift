import SwiftUI

// MARK: - 垃圾桶前后景调度视图与桶底足部组件

/// 垃圾桶后壁总调度视图（根据选中外观分发至对应独立皮肤）
struct BasketBackWallView: View {
    var binStyle: TrashBinStyle = CatPreferences.shared.selectedBinStyle

    var body: some View {
        switch binStyle {
        case .macOSFrosted:
            MacOSFrostedBackWallView()
        case .greenWheelieBin:
            GreenWheelieBinBackWallView()
        case .streetMetalBox:
            StreetMetalBoxBackWallView()
        case .metalMesh:
            MetalMeshBackWallView()
        }
    }
}

/// 垃圾桶前景总调度视图（根据选中外观分发至对应独立皮肤）
struct BasketFrontMeshView: View {
    var binStyle: TrashBinStyle = CatPreferences.shared.selectedBinStyle

    var body: some View {
        switch binStyle {
        case .macOSFrosted:
            MacOSFrostedFrontWallView()
        case .greenWheelieBin:
            GreenWheelieBinFrontWallView()
        case .streetMetalBox:
            StreetMetalBoxFrontWallView()
        case .metalMesh:
            MetalMeshFrontWallView()
        }
    }
}

/// 桶内底部一体式猫猫后脚掌
struct BucketBottomPaperAndHindFeetView: View {
    let morph: CatMorph
    let stretchRatio: CGFloat

    private var footColor: Color {
        switch morph {
        case .slime: return Color(red: 1.00, green: 0.88, blue: 0.70)
        case .bluePlush: return Color(red: 0.78, green: 0.88, blue: 0.98)
        case .calico: return Color(red: 0.97, green: 0.94, blue: 0.88)
        case .tuxedo: return Color.white
        case .siamese: return Color(red: 0.30, green: 0.18, blue: 0.12)
        case .blackShadow: return Color(red: 0.08, green: 0.08, blue: 0.12)
        }
    }

    var body: some View {
        ZStack {
            if morph != .blackShadow {
                HStack(spacing: 16) {
                    Capsule()
                        .fill(footColor)
                        .frame(width: 11, height: 16)
                        .overlay(Capsule().stroke(Color.white.opacity(0.45), lineWidth: 0.8))
                        .rotationEffect(.degrees(14))
                    Capsule()
                        .fill(footColor)
                        .frame(width: 11, height: 16)
                        .overlay(Capsule().stroke(Color.white.opacity(0.45), lineWidth: 0.8))
                        .rotationEffect(.degrees(-14))
                }
                .offset(y: 19 - min(stretchRatio * 6, 5))
            }
        }
        .frame(width: 74, height: 70)
    }
}
