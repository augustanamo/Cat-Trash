import SwiftUI

// MARK: - 样式 C：3D 圆柱透视高光金属网格桶

/// 桶口后半圈上弧 Shape（0 -> pi，向上拱起）
struct BackRimArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rx = rect.width * 0.5
        let ry = rect.height * 0.5
        let cx = rect.midX
        let cy = rect.midY
        for i in 0...30 {
            let theta = CGFloat(i) / 30.0 * .pi
            let x = cx - rx * cos(theta)
            let y = cy - ry * sin(theta)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

/// 桶口前半圈下弧 Shape（0 -> pi，向下弯垂，与后半圈在左右两端点精确闭合）
struct FrontRimArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rx = rect.width * 0.5
        let ry = rect.height * 0.5
        let cx = rect.midX
        let cy = rect.midY
        for i in 0...30 {
            let theta = CGFloat(i) / 30.0 * .pi
            let x = cx - rx * cos(theta)
            let y = cy + ry * sin(theta)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

/// 3D 圆台前后半壳裁剪轮廓
struct CylindricalFrustumShellShape: Shape {
    let isFrontHalf: Bool

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let topY: CGFloat = 3.0
        let botY: CGFloat = 57.8
        let rTop: CGFloat = 39.0
        let rBot: CGFloat = 30.8
        let ryTop: CGFloat = 7.5
        let ryBot: CGFloat = 5.4
        let steps = 32

        var path = Path()
        for i in 0...steps {
            let theta = CGFloat(i) / CGFloat(steps) * .pi
            let x = cx - rTop * cos(theta)
            let y = isFrontHalf ? (topY + ryTop * sin(theta)) : (topY - ryTop * sin(theta))
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        for i in stride(from: steps, through: 0, by: -1) {
            let theta = CGFloat(i) / CGFloat(steps) * .pi
            let x = cx - rBot * cos(theta)
            let y = botY + ryBot * sin(theta)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.closeSubpath()
        return path
    }
}

/// 真实 3D 圆柱螺旋金属编织网 Shape
struct CylindricalWireMeshShape: Shape {
    let isFrontHalf: Bool
    let strandCount: Int
    let twistRadians: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let topY: CGFloat = 3.0
        let botY: CGFloat = 58.2
        let rTop: CGFloat = 39.0
        let rBot: CGFloat = 30.8
        let ryTop: CGFloat = 7.5
        let ryBot: CGFloat = 5.4

        let dTheta = .pi / CGFloat(strandCount)
        let vSteps = 22
        let signY: CGFloat = isFrontHalf ? 1.0 : -1.0

        for dir in [-1.0, 1.0] as [CGFloat] {
            for k in -strandCount...(strandCount * 2) {
                let thetaStart = CGFloat(k) * dTheta
                var isPenDown = false

                for step in 0...vSteps {
                    let v = CGFloat(step) / CGFloat(vSteps)
                    let theta = thetaStart + dir * twistRadians * v

                    if theta >= -0.02 && theta <= .pi + 0.02 {
                        let clampedTheta = min(max(theta, 0.0), .pi)
                        let r = rTop + (rBot - rTop) * v
                        let ry = ryTop + (ryBot - ryTop) * v
                        let yAxis = topY + (botY - topY) * v

                        let x = cx - r * cos(clampedTheta)
                        let y = yAxis + signY * ry * sin(clampedTheta)
                        let pt = CGPoint(x: x, y: y)

                        if !isPenDown {
                            path.move(to: pt)
                            isPenDown = true
                        } else {
                            path.addLine(to: pt)
                        }
                    } else {
                        isPenDown = false
                    }
                }
            }
        }

        let ringV: CGFloat = 0.46
        let ringR = rTop + (rBot - rTop) * ringV
        let ringRy = ryTop + (ryBot - ryTop) * ringV
        let ringYAxis = topY + (botY - topY) * ringV
        for i in 0...28 {
            let theta = CGFloat(i) / 28.0 * .pi
            let x = cx - ringR * cos(theta)
            let y = ringYAxis + signY * ringRy * sin(theta)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

/// 桶身左右两侧立体金属边线
struct CylindricalSideEdgesShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        path.move(to: CGPoint(x: cx - 39.0, y: 3.0))
        path.addLine(to: CGPoint(x: cx - 29.5, y: 66.0))
        path.move(to: CGPoint(x: cx + 39.0, y: 3.0))
        path.addLine(to: CGPoint(x: cx + 29.5, y: 66.0))
        return path
    }
}

/// 真实 3D 旋压金属底座环视图
struct SpunMetalBaseCollarView: View {
    var body: some View {
        Canvas { context, size in
            let cx = size.width * 0.5
            let topY: CGFloat = 57.5
            let botY: CGFloat = 66.2
            let rTop: CGFloat = 30.8
            let rBot: CGFloat = 29.5
            let ryTop: CGFloat = 5.4
            let ryBot: CGFloat = 6.2

            var collar = Path()
            let steps = 36
            for i in 0...steps {
                let theta = CGFloat(i) / CGFloat(steps) * .pi
                let x = cx - rTop * cos(theta)
                let y = topY + ryTop * sin(theta)
                if i == 0 {
                    collar.move(to: CGPoint(x: x, y: y))
                } else {
                    collar.addLine(to: CGPoint(x: x, y: y))
                }
            }
            for i in stride(from: steps, through: 0, by: -1) {
                let theta = CGFloat(i) / CGFloat(steps) * .pi
                let x = cx - rBot * cos(theta)
                let y = botY + ryBot * sin(theta)
                collar.addLine(to: CGPoint(x: x, y: y))
            }
            collar.closeSubpath()

            context.fill(
                collar,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color(red: 0.22, green: 0.24, blue: 0.27), location: 0.0),
                        .init(color: Color(red: 0.62, green: 0.65, blue: 0.70), location: 0.15),
                        .init(color: Color(red: 0.95, green: 0.97, blue: 1.00), location: 0.29),
                        .init(color: Color(red: 0.46, green: 0.49, blue: 0.54), location: 0.55),
                        .init(color: Color(red: 0.80, green: 0.83, blue: 0.88), location: 0.79),
                        .init(color: Color(red: 0.20, green: 0.22, blue: 0.25), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: cx - rTop, y: topY),
                    endPoint: CGPoint(x: cx + rTop, y: topY)
                )
            )

            context.fill(
                collar,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color.white.opacity(0.12), location: 0.0),
                        .init(color: Color.clear, location: 0.45),
                        .init(color: Color.black.opacity(0.38), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: cx, y: topY),
                    endPoint: CGPoint(x: cx, y: botY + ryBot)
                )
            )

            var topLip = Path()
            var topShadow = Path()
            for i in 0...steps {
                let theta = CGFloat(i) / CGFloat(steps) * .pi
                let x = cx - rTop * cos(theta)
                let y = topY + ryTop * sin(theta)
                if i == 0 {
                    topLip.move(to: CGPoint(x: x, y: y))
                    topShadow.move(to: CGPoint(x: x, y: y - 0.9))
                } else {
                    topLip.addLine(to: CGPoint(x: x, y: y))
                    topShadow.addLine(to: CGPoint(x: x, y: y - 0.9))
                }
            }
            context.stroke(topShadow, with: .color(.black.opacity(0.45)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            context.stroke(
                topLip,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: .white.opacity(0.25), location: 0.0),
                        .init(color: .white.opacity(0.95), location: 0.29),
                        .init(color: .white.opacity(0.40), location: 0.58),
                        .init(color: .white.opacity(0.85), location: 0.80),
                        .init(color: .white.opacity(0.20), location: 1.0)
                    ]),
                    startPoint: CGPoint(x: cx - rTop, y: topY),
                    endPoint: CGPoint(x: cx + rTop, y: topY)
                ),
                style: StrokeStyle(lineWidth: 1.1, lineCap: .round)
            )

            var botLip = Path()
            for i in 0...steps {
                let theta = CGFloat(i) / CGFloat(steps) * .pi
                let x = cx - rBot * cos(theta)
                let y = botY + ryBot * sin(theta)
                if i == 0 {
                    botLip.move(to: CGPoint(x: x, y: y))
                } else {
                    botLip.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(
                botLip,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(white: 0.35),
                        Color(white: 0.88),
                        Color(white: 0.45),
                        Color(white: 0.75),
                        Color(white: 0.30)
                    ]),
                    startPoint: CGPoint(x: cx - rBot, y: botY),
                    endPoint: CGPoint(x: cx + rBot, y: botY)
                ),
                style: StrokeStyle(lineWidth: 1.0, lineCap: .round)
            )
        }
    }
}

/// 样式 C：3D 圆柱透视高光金属网格桶 · 后壁
struct MetalMeshBackWallView: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.black.opacity(0.55), .black.opacity(0.24), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 45
                    )
                )
                .frame(width: 90, height: 22)
                .offset(y: 35)

            Ellipse()
                .fill(Color.black.opacity(0.45))
                .frame(width: 58, height: 11)
                .blur(radius: 2.2)
                .offset(y: 34)

            CylindricalFrustumShellShape(isFrontHalf: false)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.16, green: 0.18, blue: 0.21).opacity(0.84), location: 0.0),
                            .init(color: Color(red: 0.28, green: 0.30, blue: 0.35).opacity(0.76), location: 0.32),
                            .init(color: Color(red: 0.13, green: 0.15, blue: 0.18).opacity(0.90), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 78, height: 74)

            CylindricalWireMeshShape(isFrontHalf: false, strandCount: 15, twistRadians: .pi * 0.56)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(white: 0.32).opacity(0.42),
                            Color(white: 0.62).opacity(0.48),
                            Color(white: 0.28).opacity(0.40)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 0.65, lineCap: .round)
                )
                .frame(width: 78, height: 74)
                .clipShape(CylindricalFrustumShellShape(isFrontHalf: false))

            ZStack {
                Ellipse()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.20, green: 0.22, blue: 0.25), location: 0.0),
                                .init(color: Color(red: 0.56, green: 0.59, blue: 0.64), location: 0.30),
                                .init(color: Color(red: 0.30, green: 0.32, blue: 0.36), location: 0.68),
                                .init(color: Color(red: 0.16, green: 0.18, blue: 0.20), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 56, height: 12.5)

                Ellipse()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.65),
                                Color.white.opacity(0.45),
                                Color.black.opacity(0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.2
                    )
                    .frame(width: 52, height: 10.5)

                Ellipse()
                    .stroke(Color.white.opacity(0.28), lineWidth: 0.6)
                    .frame(width: 34, height: 6.5)
            }
            .offset(y: 26.5)

            ZStack {
                BackRimArcShape()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color(white: 0.18), location: 0.0),
                                .init(color: Color(white: 0.48), location: 0.32),
                                .init(color: Color(white: 0.22), location: 0.72),
                                .init(color: Color(white: 0.35), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 6.2, lineCap: .round)
                    )
                    .offset(y: 1.2)

                BackRimArcShape()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.38, green: 0.40, blue: 0.44), location: 0.0),
                                .init(color: Color(red: 0.90, green: 0.93, blue: 0.97), location: 0.28),
                                .init(color: Color(red: 0.52, green: 0.55, blue: 0.60), location: 0.62),
                                .init(color: Color(red: 0.78, green: 0.81, blue: 0.86), location: 0.84),
                                .init(color: Color(red: 0.36, green: 0.38, blue: 0.42), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4.4, lineCap: .round)
                    )

                BackRimArcShape()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .white.opacity(0.92), .white.opacity(0.40)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 0.9, lineCap: .round)
                    )
                    .offset(y: -1.1)
            }
            .frame(width: 78, height: 15)
            .offset(y: -34)
        }
    }
}

/// 样式 C：3D 圆柱透视高光金属网格桶 · 前景
struct MetalMeshFrontWallView: View {
    var body: some View {
        ZStack {
            CylindricalFrustumShellShape(isFrontHalf: true)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.black.opacity(0.32), location: 0.0),
                            .init(color: Color.white.opacity(0.22), location: 0.25),
                            .init(color: Color(white: 0.75).opacity(0.06), location: 0.56),
                            .init(color: Color.white.opacity(0.14), location: 0.80),
                            .init(color: Color.black.opacity(0.38), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 78, height: 74)

            ZStack {
                CylindricalWireMeshShape(isFrontHalf: true, strandCount: 16, twistRadians: .pi * 0.58)
                    .stroke(
                        Color.black.opacity(0.48),
                        style: StrokeStyle(lineWidth: 1.05, lineCap: .round, lineJoin: .round)
                    )
                    .offset(y: 0.45)

                CylindricalWireMeshShape(isFrontHalf: true, strandCount: 16, twistRadians: .pi * 0.58)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.38, green: 0.41, blue: 0.45).opacity(0.85), location: 0.0),
                                .init(color: Color(red: 0.96, green: 0.98, blue: 1.00).opacity(0.95), location: 0.26),
                                .init(color: Color(red: 0.56, green: 0.60, blue: 0.65).opacity(0.82), location: 0.58),
                                .init(color: Color(red: 0.86, green: 0.89, blue: 0.94).opacity(0.90), location: 0.82),
                                .init(color: Color(red: 0.34, green: 0.37, blue: 0.41).opacity(0.85), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 0.78, lineCap: .round, lineJoin: .round)
                    )
            }
            .frame(width: 78, height: 74)
            .clipShape(CylindricalFrustumShellShape(isFrontHalf: true))

            CylindricalSideEdgesShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(white: 0.88).opacity(0.85),
                            Color(white: 0.50).opacity(0.75)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.15
                )
                .frame(width: 78, height: 74)

            SpunMetalBaseCollarView()
                .frame(width: 78, height: 74)

            ZStack {
                FrontRimArcShape()
                    .stroke(
                        Color.black.opacity(0.45),
                        style: StrokeStyle(lineWidth: 5.2, lineCap: .round)
                    )
                    .offset(y: 1.1)

                FrontRimArcShape()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.34, green: 0.36, blue: 0.40), location: 0.0),
                                .init(color: Color(red: 0.72, green: 0.75, blue: 0.80), location: 0.14),
                                .init(color: Color(red: 0.98, green: 0.99, blue: 1.00), location: 0.28),
                                .init(color: Color(red: 0.54, green: 0.57, blue: 0.62), location: 0.56),
                                .init(color: Color(red: 0.88, green: 0.91, blue: 0.95), location: 0.80),
                                .init(color: Color(red: 0.32, green: 0.34, blue: 0.38), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4.8, lineCap: .round)
                    )

                FrontRimArcShape()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.25), location: 0.0),
                                .init(color: .white.opacity(0.98), location: 0.28),
                                .init(color: .white.opacity(0.45), location: 0.58),
                                .init(color: .white.opacity(0.88), location: 0.82),
                                .init(color: .white.opacity(0.20), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 1.15, lineCap: .round)
                    )
                    .offset(y: -1.15)
            }
            .frame(width: 78, height: 15)
            .offset(y: -34)
        }
    }
}
