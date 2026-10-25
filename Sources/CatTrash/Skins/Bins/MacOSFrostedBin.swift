import SwiftUI

// MARK: - 样式 A：macOS 原生一体成型方圆角（Squircle）磨砂半透明桶

/// Apple Squircle（超椭圆 n = 4.6）方圆角透视桶口弧线
struct MacOSSquircleRimArcShape: Shape {
    let isFrontHalf: Bool

    static func squirclePoint(theta: CGFloat, cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, isFrontHalf: Bool) -> CGPoint {
        let cosT = cos(theta)
        let sinT = max(0, sin(theta))
        let signX: CGFloat = cosT >= 0 ? 1.0 : -1.0
        // 超椭圆指数 n = 4.6 -> 2/n = 0.435，使前后沿平直、四角圆润
        let x = cx - rx * signX * pow(abs(cosT), 0.435)
        let yOffset = ry * pow(sinT, 0.435)
        let y = isFrontHalf ? (cy + yOffset) : (cy - yOffset)
        return CGPoint(x: x, y: y)
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rx = rect.width * 0.5
        let ry = rect.height * 0.5
        let cx = rect.midX
        let cy = rect.midY
        let steps = 40
        for i in 0...steps {
            let theta = CGFloat(i) / CGFloat(steps) * .pi
            let pt = Self.squirclePoint(theta: theta, cx: cx, cy: cy, rx: rx, ry: ry, isFrontHalf: isFrontHalf)
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        return path
    }
}

/// macOS 原生方圆角（Squircle）半壳轮廓
struct MacOSBinShellShape: Shape {
    let isFrontHalf: Bool

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let topY: CGFloat = 3.0
        let botY: CGFloat = 65.5
        let rTop: CGFloat = 39.0
        let rBot: CGFloat = 29.5
        let ryTop: CGFloat = 5.5
        let cornerR: CGFloat = 8.5
        let steps = 40

        var path = Path()
        for i in 0...steps {
            let theta = CGFloat(i) / CGFloat(steps) * .pi
            let pt = MacOSSquircleRimArcShape.squirclePoint(
                theta: theta,
                cx: cx,
                cy: topY,
                rx: rTop,
                ry: ryTop,
                isFrontHalf: isFrontHalf
            )
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }

        // 右侧直斜壁 -> 右下紧凑圆角 -> 平直底边 -> 左下紧凑圆角 -> 左侧直斜壁
        path.addLine(to: CGPoint(x: cx + rBot, y: botY - cornerR))
        path.addQuadCurve(
            to: CGPoint(x: cx + rBot - cornerR, y: botY),
            control: CGPoint(x: cx + rBot - 0.6, y: botY - 0.4)
        )
        // 平直微弧底边（还原参考图方圆角平底）
        path.addQuadCurve(
            to: CGPoint(x: cx - rBot + cornerR, y: botY),
            control: CGPoint(x: cx, y: botY + 0.9)
        )
        path.addQuadCurve(
            to: CGPoint(x: cx - rBot, y: botY - cornerR),
            control: CGPoint(x: cx - rBot + 0.6, y: botY - 0.4)
        )
        path.closeSubpath()
        return path
    }
}

/// 样式 A：macOS 原生一体成型磨砂桶 · 后壁
struct MacOSFrostedBackWallView: View {
    var body: some View {
        ZStack {
            // 1. 桌面柔和圆角矩形接触阴影
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [.black.opacity(0.38), .black.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 42
                    )
                )
                .frame(width: 80, height: 16)
                .offset(y: 34)

            // 2. 一体成型桶后壁内腔（无外加包边圈，仅靠桶壁厚度切面与柔和冷灰白磨砂渐变呈现体积）
            MacOSBinShellShape(isFrontHalf: false)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.72, green: 0.74, blue: 0.78), location: 0.0),
                            .init(color: Color(red: 0.82, green: 0.84, blue: 0.87), location: 0.14),
                            .init(color: Color(red: 0.75, green: 0.77, blue: 0.80), location: 0.50),
                            .init(color: Color(red: 0.82, green: 0.84, blue: 0.87), location: 0.86),
                            .init(color: Color(red: 0.70, green: 0.72, blue: 0.76), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    MacOSBinShellShape(isFrontHalf: false)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.35), location: 0.0),
                                    .init(color: Color(red: 0.50, green: 0.52, blue: 0.56).opacity(0.35), location: 0.25),
                                    .init(color: Color(red: 0.38, green: 0.40, blue: 0.44).opacity(0.55), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .frame(width: 78, height: 74)

            // 3. 桶壁顶部一体平切面微高光
            MacOSSquircleRimArcShape(isFrontHalf: false)
                .stroke(
                    Color(red: 0.92, green: 0.93, blue: 0.96),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round)
                )
                .frame(width: 78, height: 11)
                .offset(y: -34)
        }
    }
}

/// 样式 A：macOS 原生一体成型磨砂桶 · 前壁
struct MacOSFrostedFrontWallView: View {
    var body: some View {
        ZStack {
            // 1. 纯粹一体成型磨砂白半透明主体
            MacOSBinShellShape(isFrontHalf: true)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.90, green: 0.92, blue: 0.94).opacity(0.92), location: 0.0),
                            .init(color: Color(red: 0.96, green: 0.97, blue: 0.99).opacity(0.86), location: 0.08),
                            .init(color: Color(red: 0.82, green: 0.84, blue: 0.88).opacity(0.75), location: 0.18),
                            .init(color: Color(red: 0.78, green: 0.80, blue: 0.84).opacity(0.70), location: 0.50),
                            .init(color: Color(red: 0.82, green: 0.84, blue: 0.88).opacity(0.75), location: 0.82),
                            .init(color: Color(red: 0.95, green: 0.96, blue: 0.98).opacity(0.86), location: 0.92),
                            .init(color: Color(red: 0.88, green: 0.90, blue: 0.93).opacity(0.92), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 78, height: 74)

            // 2. 垂直方向柔和漫射过渡
            MacOSBinShellShape(isFrontHalf: true)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.45), location: 0.0),
                            .init(color: Color.white.opacity(0.10), location: 0.16),
                            .init(color: Color.clear, location: 0.55),
                            .init(color: Color(red: 0.68, green: 0.70, blue: 0.74).opacity(0.24), location: 0.85),
                            .init(color: Color.white.opacity(0.58), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 78, height: 74)

            // 3. 桶壁顶部一体平切面微光
            MacOSSquircleRimArcShape(isFrontHalf: true)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.92, green: 0.93, blue: 0.96),
                            Color.white,
                            Color(red: 0.94, green: 0.95, blue: 0.98),
                            Color.white,
                            Color(red: 0.90, green: 0.92, blue: 0.95)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round)
                )
                .frame(width: 78, height: 11)
                .offset(y: -34)
        }
    }
}
