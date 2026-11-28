import AVFoundation
import Observation
import os
import SwiftUI
import UIKit
import NomNomDesignSystem

// MARK: - Camera Capture Controller

/// Hardware-aware camera capture controller wrapping `AVCaptureSession` and `AVCapturePhotoOutput`
/// on physical devices, with a deterministic sample-plate fallback in the iOS Simulator or when
/// no rear camera is available.
@Observable
@MainActor
public final class CameraCaptureController {
    public private(set) var isSimulatorFallback: Bool
    public private(set) var authorizationStatus: AVAuthorizationStatus
    public private(set) var isSessionRunning: Bool = false
    public var isFlashEnabled: Bool = false

    public let simulatorSampleJPEG: Data

    private let engine: CameraSessionEngine

    public var previewSession: AVCaptureSession {
        engine.session
    }

    public init() {
        self.simulatorSampleJPEG = AppPhotoStorage.makeSimulatorSamplePlateJPEG()
        self.engine = CameraSessionEngine()

        #if targetEnvironment(simulator)
        self.isSimulatorFallback = true
        self.authorizationStatus = .authorized
        #else
        let hasBackCamera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) != nil
        self.isSimulatorFallback = !hasBackCamera
        self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        #endif
    }

    public func toggleFlash() {
        guard !isSimulatorFallback else { return }
        isFlashEnabled.toggle()
    }

    public func start() async {
        guard !isSimulatorFallback else {
            isSessionRunning = true
            return
        }

        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        authorizationStatus = currentStatus

        switch currentStatus {
        case .authorized:
            let started = await engine.startSession()
            isSessionRunning = started
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationStatus = granted ? .authorized : .denied
            if granted {
                let started = await engine.startSession()
                isSessionRunning = started
            }
        case .denied, .restricted:
            isSessionRunning = false
        @unknown default:
            isSessionRunning = false
        }
    }

    public func stop() {
        isSessionRunning = false
        guard !isSimulatorFallback else { return }
        engine.stopSession()
    }

    /// Captures a JPEG photo from `AVCapturePhotoOutput` on real hardware,
    /// or returns the bundled sample plate JPEG in the Simulator / no-camera fallback.
    public func capturePhoto() async -> Data {
        if isSimulatorFallback || authorizationStatus != .authorized {
            return simulatorSampleJPEG
        }

        if let data = await engine.capturePhoto(flashEnabled: isFlashEnabled), !data.isEmpty {
            return data
        }

        return simulatorSampleJPEG
    }
}

// MARK: - Thread-Safe AVFoundation Session Engine

private final class CameraSessionEngine: @unchecked Sendable {
    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(
        label: "dev.brianphan.nomnom.camera.session",
        qos: .userInitiated
    )
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false
    private let activeDelegates = OSAllocatedUnfairLock<[UUID: PhotoCaptureDelegateBox]>(initialState: [:])

    func startSession() async -> Bool {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: false)
                    return
                }
                if !self.isConfigured {
                    self.configureSessionLocked()
                }
                guard self.isConfigured else {
                    continuation.resume(returning: false)
                    return
                }
                if !self.session.isRunning {
                    self.session.startRunning()
                }
                continuation.resume(returning: self.session.isRunning)
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func capturePhoto(flashEnabled: Bool) async -> Data? {
        await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: nil)
                    return
                }
                if !self.isConfigured {
                    self.configureSessionLocked()
                }
                guard self.isConfigured else {
                    continuation.resume(returning: nil)
                    return
                }
                if !self.session.isRunning {
                    self.session.startRunning()
                }

                let settings = AVCapturePhotoSettings(format: [
                    AVVideoCodecKey: AVVideoCodecType.jpeg,
                ])
                let supportedFlash = self.photoOutput.supportedFlashModes
                if flashEnabled && supportedFlash.contains(.on) {
                    settings.flashMode = .on
                } else if supportedFlash.contains(.off) {
                    settings.flashMode = .off
                }

                let delegateId = UUID()
                let box = PhotoCaptureDelegateBox { [weak self] data in
                    self?.activeDelegates.withLock { store in
                        _ = store.removeValue(forKey: delegateId)
                    }
                    continuation.resume(returning: data)
                }

                self.activeDelegates.withLock { store in
                    store[delegateId] = box
                }

                self.photoOutput.capturePhoto(with: settings, delegate: box)
            }
        }
    }

    private func configureSessionLocked() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            return
        }

        session.addInput(input)

        guard session.canAddOutput(photoOutput) else {
            return
        }
        session.addOutput(photoOutput)
        isConfigured = true
    }
}

private final class PhotoCaptureDelegateBox: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private let completionLock: OSAllocatedUnfairLock<(@Sendable (Data?) -> Void)?>

    init(completion: @escaping @Sendable (Data?) -> Void) {
        self.completionLock = OSAllocatedUnfairLock(initialState: completion)
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        let data: Data? = error == nil ? photo.fileDataRepresentation() : nil
        let callback = completionLock.withLock { stored -> (@Sendable (Data?) -> Void)? in
            let current = stored
            stored = nil
            return current
        }
        callback?(data)
    }
}

// MARK: - Camera Preview View

/// Full-bleed camera viewfinder with graceful Simulator and denied-permission fallbacks.
public struct CameraPreviewView: View {
    public let controller: CameraCaptureController

    @Environment(\.openURL) private var openURL

    public init(controller: CameraCaptureController) {
        self.controller = controller
    }

    public var body: some View {
        ZStack {
            NNColor.viewfinder
                .ignoresSafeArea()

            if controller.isSimulatorFallback {
                simulatorFallbackView
            } else if controller.authorizationStatus == .denied || controller.authorizationStatus == .restricted {
                cameraPermissionDeniedView
            } else {
                AVCameraPreviewRepresentable(session: controller.previewSession)
                    .ignoresSafeArea()
                cornerReticleOverlay
            }
        }
        .task {
            await controller.start()
        }
        .onDisappear {
            controller.stop()
        }
    }

    private var simulatorFallbackView: some View {
        ZStack {
            if let uiImage = UIImage(data: controller.simulatorSampleJPEG) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.24).ignoresSafeArea())
            }

            cornerReticleOverlay

            VStack {
                Spacer()
                    .frame(height: 140)
                Text("Simulator preview")
                    .nnTextStyle(.caption)
                    .foregroundStyle(NNColor.onPhoto)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().fill(Color.black.opacity(0.35)))
                    .environment(\.colorScheme, .dark)
                Spacer()
            }
        }
    }

    private var cornerReticleOverlay: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width - 64, proxy.size.height * 0.44, 300)
            CornerReticleView(size: max(180, side))
                .position(x: proxy.size.width / 2, y: proxy.size.height * 0.46)
        }
        .allowsHitTesting(false)
    }

    private var cameraPermissionDeniedView: some View {
        VStack(spacing: NNSpacing.s3) {
            NNIconView(.camera, size: 32, weight: .regular, color: NNColor.onPhoto.opacity(0.7))

            Text("Camera access is turned off")
                .nnTextStyle(.title2)
                .foregroundStyle(NNColor.onPhoto)
                .multilineTextAlignment(.center)

            Text("Enable camera access in Settings, or choose a photo from your library below.")
                .nnTextStyle(.subhead)
                .foregroundStyle(NNColor.onPhoto.opacity(0.75))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            NNButton("Open Settings", variant: .secondary, size: .md) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .environment(\.colorScheme, .dark)
            .padding(.top, NNSpacing.s2)
        }
        .padding(.horizontal, NNSpacing.screenMargin)
    }
}

// MARK: - Corner Reticle Guides

private struct CornerReticleView: View {
    let size: CGFloat

    var body: some View {
        let arm: CGFloat = 24
        let stroke = NNColor.onPhoto.opacity(0.65)
        ZStack {
            CornerBracket()
                .stroke(stroke, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .frame(width: arm, height: arm)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            CornerBracket()
                .rotation(.degrees(90))
                .stroke(stroke, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .frame(width: arm, height: arm)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            CornerBracket()
                .rotation(.degrees(180))
                .stroke(stroke, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .frame(width: arm, height: arm)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            CornerBracket()
                .rotation(.degrees(270))
                .stroke(stroke, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .frame(width: arm, height: arm)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(width: size, height: size)
    }
}

private struct CornerBracket: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 10
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

// MARK: - UIKit AVCaptureVideoPreviewLayer Wrapper

private struct AVCameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewContainerView {
        let view = VideoPreviewContainerView()
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: VideoPreviewContainerView, context: Context) {
        if uiView.videoPreviewLayer.session !== session {
            uiView.videoPreviewLayer.session = session
        }
    }
}

private final class VideoPreviewContainerView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
