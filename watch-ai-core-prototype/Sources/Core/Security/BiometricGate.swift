import Foundation
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

/// Wraps `LAContext.evaluatePolicy` for sensitive operations
/// (e.g. unlocking a WristShell session, revealing a stored API key).
///
/// On non-Apple platforms, succeeds silently — prototypes that need a real
/// gate must check `Self.isAvailable` first.
public struct BiometricGate: Sendable {
    public init() {}

    public static var isAvailable: Bool {
#if canImport(LocalAuthentication)
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
#else
        return false
#endif
    }

    /// Prompts for Touch ID / Face ID with the supplied reason. Returns true
    /// on success, false if the user cancelled, throws on any other error.
    public func authenticate(reason: String) async throws -> Bool {
#if canImport(LocalAuthentication)
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw error ?? NSError(domain: "BiometricGate", code: -1)
        }
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, evalError in
                if let evalError = evalError as NSError? {
                    // userCancel / appCancel: not an error, just a "no"
                    let code = LAError.Code(rawValue: evalError.code)
                    if code == .userCancel || code == .appCancel || code == .systemCancel {
                        continuation.resume(returning: false)
                    } else {
                        continuation.resume(throwing: evalError)
                    }
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
#else
        return true
#endif
    }
}
