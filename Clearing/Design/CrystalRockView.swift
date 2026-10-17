import SwiftUI
import RealityKit
import Metal

/// A small, non-AR RealityKit scene for Clearing's single recurring visual motif.
/// The controls around it remain native SwiftUI, so the object never owns a tap target.
struct CrystalRockView: UIViewRepresentable {
    enum Mode: Equatable {
        case onboarding
        case today
        case support

        var background: UIColor {
            switch self {
            case .onboarding, .today:
                return UIColor(red: 247 / 255, green: 245 / 255, blue: 240 / 255, alpha: 1)
            case .support:
                return UIColor(red: 20 / 255, green: 30 / 255, blue: 45 / 255, alpha: 1)
            }
        }
    }

    var progress: Double
    var mode: Mode

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(mode.background)
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        context.coordinator.install(in: view, progress: progress, mode: mode)
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        view.environment.background = .color(mode.background)
        context.coordinator.update(progress: progress, mode: mode)
    }

    static func dismantleUIView(_ view: ARView, coordinator: Coordinator) {
        coordinator.stop()
        view.scene.anchors.removeAll()
    }

    @MainActor
    final class Coordinator: NSObject {
        private weak var rock: Entity?
        private weak var shell: ModelEntity?
        private weak var core: ModelEntity?
        private var displayLink: CADisplayLink?
        private var startTime: CFTimeInterval = 0
        private var basePosition = SIMD3<Float>.zero
        private var cachedProgress: Float = -1
        private var cachedMode: Mode?

        func install(in view: ARView, progress: Double, mode: Mode) {
            let anchor = AnchorEntity(world: .zero)
            view.scene.addAnchor(anchor)

            let loaded = try? Entity.load(named: "QuietStone")
            let model = loaded ?? ModelEntity(mesh: .generateSphere(radius: 0.15))
            model.name = "ClearingCrystal"
            anchor.addChild(model)

            let bounds = model.visualBounds(recursive: true, relativeTo: model)
            let maxSize = max(bounds.extents.x, bounds.extents.y, bounds.extents.z, 0.001)
            let size: Float = 2.82 / maxSize
            let width = mode == .onboarding ? 1.0 as Float : 1.20
            let height = mode == .onboarding ? 1.0 as Float : 0.92
            model.scale = [size * width, size * height, size]
            model.position = -bounds.center * size
            basePosition = model.position
            rock = model

            shell = firstModel(in: model.findEntity(named: "QuietStoneShell"))
            core = firstModel(in: model.findEntity(named: "AmberCore"))
            if shell == nil, let fallback = model as? ModelEntity { shell = fallback }

            let camera = PerspectiveCamera()
            camera.position = [0.38, 0.11, 3.12]
            camera.look(at: .zero, from: camera.position, relativeTo: anchor)
            anchor.addChild(camera)

            let warm = DirectionalLight()
            warm.light = DirectionalLightComponent(
                color: UIColor(red: 1, green: 0.68, blue: 0.39, alpha: 1), intensity: 650)
            warm.look(at: .zero, from: [-2.4, 3.2, 2.4], relativeTo: anchor)
            anchor.addChild(warm)

            let cool = DirectionalLight()
            cool.light = DirectionalLightComponent(
                color: UIColor(red: 0.66, green: 0.84, blue: 1, alpha: 1), intensity: 330)
            cool.look(at: .zero, from: [2.5, 0.9, 1.7], relativeTo: anchor)
            anchor.addChild(cool)

            update(progress: progress, mode: mode)
            if !UIAccessibility.isReduceMotionEnabled {
                let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
                link.preferredFramesPerSecond = 30
                link.add(to: .main, forMode: .common)
                displayLink = link
            }
        }

        func update(progress: Double, mode: Mode) {
            let value = Float(min(max(progress, 0), 1))
            guard value != cachedProgress || mode != cachedMode else { return }
            cachedProgress = value
            cachedMode = mode
            if let shell { shell.model?.materials = [material(progress: value, core: false, mode: mode)] }
            if let core { core.model?.materials = [material(progress: value, core: true, mode: mode)] }
        }

        private func firstModel(in entity: Entity?) -> ModelEntity? {
            guard let entity else { return nil }
            if let model = entity as? ModelEntity { return model }
            for child in entity.children {
                if let model = firstModel(in: child) { return model }
            }
            return nil
        }

        private func material(progress: Float, core: Bool, mode: Mode) -> any RealityKit.Material {
            var base = PhysicallyBasedMaterial()
            base.baseColor = .init(tint: core ? .init(red: 0.80, green: 0.36, blue: 0.09, alpha: 1) : .init(red: 0.70, green: 0.71, blue: 0.67, alpha: 1))
            base.roughness = .init(floatLiteral: core ? 0.16 : 0.045)
            base.metallic = .init(floatLiteral: 0)
            base.blending = .transparent(opacity: .init(floatLiteral: core ? 0.67 : 0.72))

            guard let library = MTLCreateSystemDefaultDevice()?.makeDefaultLibrary(),
                  let custom = try? CustomMaterial(
                    from: base,
                    surfaceShader: .init(named: "clearingCrystalSurface", in: library)
                  ) else { return base }

            var customMaterial = custom
            customMaterial.blending = .transparent(opacity: .init(floatLiteral: core ? 0.67 : 0.72))
            customMaterial.custom.value = [progress, core ? 1 : 0, mode == .support ? 1 : 0, 0]
            return customMaterial
        }

        @objc private func tick(_ link: CADisplayLink) {
            guard let rock else { return }
            if startTime == 0 { startTime = link.timestamp }
            let elapsed = Float(link.timestamp - startTime)
            let yaw = sin(elapsed * 0.22) * 0.12
            let tilt = sin(elapsed * 0.31) * 0.035
            rock.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
                * simd_quatf(angle: tilt, axis: [0, 0, 1])
            rock.position = basePosition + [0, sin(elapsed * 0.75) * 0.025, 0]
        }

        func stop() {
            displayLink?.invalidate()
            displayLink = nil
        }
    }
}
