import Foundation
#if canImport(CoreML)
import CoreML

public struct OnDeviceModelDescriptor: Identifiable, Sendable {
    public let id: String               // stem of the filename, e.g. "NanoGPT-CodeAssist-v1"
    public let displayName: String
    public let sizeBytes: Int
    public let modelURL: URL
    public let vocabURL: URL
    public let mergesURL: URL
}

public struct ModelBundleLoader: Sendable {
    // Scan for all .mlpackage bundles in the CoreMLModels resource directory
    public static func availableModels() -> [OnDeviceModelDescriptor] {
        guard let resourceURL = Bundle.main.url(forResource: "CoreMLModels", withExtension: nil) else {
            return []
        }
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return []
        }
        return contents
            .filter { $0.pathExtension == "mlpackage" }
            .compactMap { url -> OnDeviceModelDescriptor? in
                let stem = url.deletingPathExtension().lastPathComponent
                let vocabURL = resourceURL.appendingPathComponent("\(stem).vocab.json")
                let mergesURL = resourceURL.appendingPathComponent("\(stem).merges.txt")
                guard fm.fileExists(atPath: vocabURL.path),
                      fm.fileExists(atPath: mergesURL.path) else { return nil }
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return OnDeviceModelDescriptor(
                    id: stem,
                    displayName: stem.replacingOccurrences(of: "-", with: " "),
                    sizeBytes: size,
                    modelURL: url,
                    vocabURL: vocabURL,
                    mergesURL: mergesURL
                )
            }
    }

    // Compile (if needed) and load the model. Compilation result cached to Caches.
    public static func load(descriptor: OnDeviceModelDescriptor) async throws -> MLModel {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let compiledURL = cachesDir.appendingPathComponent("\(descriptor.id).mlmodelc")

        if !FileManager.default.fileExists(atPath: compiledURL.path) {
            let tempURL = try await MLModel.compileModel(at: descriptor.modelURL)
            try FileManager.default.moveItem(at: tempURL, to: compiledURL)
        }

        let config = MLModelConfiguration()
        config.computeUnits = .all
        return try MLModel(contentsOf: compiledURL, configuration: config)
    }
}
#endif
