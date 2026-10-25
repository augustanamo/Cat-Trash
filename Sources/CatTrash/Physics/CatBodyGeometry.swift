import SwiftUI

// MARK: - 猫咪拉伸身体参数化贝塞尔几何与宽度剖面 Shape

struct StretchedCatBodyShape: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var baseHalfWidth: CGFloat
    var headHalfWidth: CGFloat
    var waistScale: CGFloat
    var isFrontCompartmentExit: Bool = false

    func path(in rect: CGRect) -> Path {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let dist = hypot(dx, dy)

        let c1Center: CGPoint
        let c2Center: CGPoint
        if isFrontCompartmentExit {
            let forwardDip = min(max(dy * 0.22 + 14.0, -2.0), 34.0)
            c1Center = CGPoint(
                x: startPoint.x + dx * 0.26,
                y: startPoint.y + forwardDip
            )
            c2Center = CGPoint(
                x: startPoint.x + dx * 0.70,
                y: endPoint.y + min(max(-dy * 0.14, -16.0), 24.0)
            )
        } else {
            let archLift = max(18, min(dist * 0.48, 115))
            c1Center = CGPoint(
                x: startPoint.x + dx * 0.10,
                y: startPoint.y - archLift
            )
            c2Center = CGPoint(
                x: startPoint.x + dx * 0.68,
                y: endPoint.y + min(dist * 0.18, 32)
            )
        }

        let w1 = max(16, baseHalfWidth * waistScale)
        let w2 = max(16, ((baseHalfWidth + headHalfWidth) * 0.5) * waistScale)

        let leftStart = CGPoint(x: startPoint.x - baseHalfWidth, y: startPoint.y)
        let rightStart = CGPoint(x: startPoint.x + baseHalfWidth, y: startPoint.y)

        let leftEnd = CGPoint(x: endPoint.x - headHalfWidth, y: endPoint.y)
        let rightEnd = CGPoint(x: endPoint.x + headHalfWidth, y: endPoint.y)

        let leftC1 = CGPoint(x: c1Center.x - w1, y: c1Center.y)
        let leftC2 = CGPoint(x: c2Center.x - w2, y: c2Center.y)

        let rightC1 = CGPoint(x: c1Center.x + w1, y: c1Center.y)
        let rightC2 = CGPoint(x: c2Center.x + w2, y: c2Center.y)

        var path = Path()
        path.move(to: leftStart)
        path.addCurve(to: leftEnd, control1: leftC1, control2: leftC2)
        path.addQuadCurve(
            to: rightEnd,
            control: CGPoint(x: endPoint.x, y: endPoint.y - 10)
        )
        path.addCurve(to: rightStart, control1: rightC2, control2: rightC1)
        path.addQuadCurve(
            to: leftStart,
            control: CGPoint(x: startPoint.x, y: startPoint.y + 18)
        )
        path.closeSubpath()
        return path
    }
}



/// 三次贝塞尔曲线坐标计算函数
func cubicBezierPoint(t: CGFloat, p0: CGPoint, c1: CGPoint, c2: CGPoint, p3: CGPoint) -> CGPoint {
    let u = 1.0 - t
    let tt = t * t
    let uu = u * u
    let uuu = uu * u
    let ttt = tt * t

    let x = uuu * p0.x + 3 * uu * t * c1.x + 3 * u * tt * c2.x + ttt * p3.x
    let y = uuu * p0.y + 3 * uu * t * c1.y + 3 * u * tt * c2.y + ttt * p3.y
    return CGPoint(x: x, y: y)
}

/// 按品种「宽度剖面」沿贝塞尔脊柱逐段采样的身体轮廓
struct ProfiledCatBodyShape: Shape {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var c1: CGPoint
    var c2: CGPoint
    var baseHalfWidth: CGFloat = 25
    var headHalfWidth: CGFloat = 23
    var stretchRatio: CGFloat
    var pinch: CGFloat = 0.3
    var pinchExponent: CGFloat = 1.3
    var minHalfWidth: CGFloat = 10
    var endBulge: CGFloat = 0
    var basePoolFlare: CGFloat = 0
    var wobblePhase: CGFloat = 0
    var wobbleAmp: CGFloat = 0

    static let samples = 56

    func halfWidth(at t: CGFloat) -> CGFloat {
        let linear = baseHalfWidth * (1 - t) + headHalfWidth * t
        let bell = pow(max(sin(.pi * t), 0), pinchExponent)
        var w = linear * (1 - pinch * stretchRatio * bell)
        let g1 = exp(-pow((t - 0.16) / 0.09, 2))
        let g2 = exp(-pow((t - 0.84) / 0.09, 2))
        w += endBulge * stretchRatio * (g1 + g2)
        if t < 0.30 {
            let f = 1 - t / 0.30
            w += basePoolFlare * stretchRatio * f * f
        }
        w += sin(t * 9 + wobblePhase * 3.2) * wobbleAmp * sin(.pi * t)
        return max(minHalfWidth, w)
    }

    func frame(at t: CGFloat) -> (center: CGPoint, tangent: CGVector, normal: CGVector) {
        let u = 1 - t
        let x = u * u * u * startPoint.x + 3 * u * u * t * c1.x + 3 * u * t * t * c2.x + t * t * t * endPoint.x
        let y = u * u * u * startPoint.y + 3 * u * u * t * c1.y + 3 * u * t * t * c2.y + t * t * t * endPoint.y
        var dx = 3 * u * u * (c1.x - startPoint.x) + 6 * u * t * (c2.x - c1.x) + 3 * t * t * (endPoint.x - c2.x)
        var dy = 3 * u * u * (c1.y - startPoint.y) + 6 * u * t * (c2.y - c1.y) + 3 * t * t * (endPoint.y - c2.y)
        let len = hypot(dx, dy)
        if len < 0.001 {
            dx = endPoint.x - startPoint.x
            dy = endPoint.y - startPoint.y
        }
        let l2 = max(hypot(dx, dy), 0.001)
        let tx = dx / l2
        let ty = dy / l2
        return (CGPoint(x: x, y: y), CGVector(dx: tx, dy: ty), CGVector(dx: -ty, dy: tx))
    }

    func edges() -> (left: [CGPoint], right: [CGPoint]) {
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        let n = Self.samples
        left.reserveCapacity(n + 1)
        right.reserveCapacity(n + 1)
        for i in 0...n {
            let t = CGFloat(i) / CGFloat(n)
            let f = frame(at: t)
            let w = halfWidth(at: t)
            left.append(CGPoint(x: f.center.x + f.normal.dx * w, y: f.center.y + f.normal.dy * w))
            right.append(CGPoint(x: f.center.x - f.normal.dx * w, y: f.center.y - f.normal.dy * w))
        }
        return (left, right)
    }

    func path(in rect: CGRect) -> Path {
        let e = edges()
        guard let l0 = e.left.first, let rN = e.right.last else {
            return Path()
        }
        let endF = frame(at: 1)
        let startF = frame(at: 0)
        var path = Path()
        path.move(to: l0)
        for p in e.left.dropFirst() { path.addLine(to: p) }
        path.addQuadCurve(
            to: rN,
            control: CGPoint(x: endF.center.x + endF.tangent.dx * 12, y: endF.center.y + endF.tangent.dy * 12)
        )
        for p in e.right.reversed().dropFirst() { path.addLine(to: p) }
        path.addQuadCurve(
            to: l0,
            control: CGPoint(x: startF.center.x - startF.tangent.dx * 18, y: startF.center.y - startF.tangent.dy * 18)
        )
        path.closeSubpath()
        return path
    }
}


