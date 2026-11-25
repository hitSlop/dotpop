import CryptoKit
import Foundation
import Security

/// Zero-dependency Ed25519 (`Curve25519`) device identity built into `PopKit`.
///
/// Generates a persistent Ed25519 signing key in Apple Keychain (with `kSecAttrSynchronizable`
/// enabled so a user's iPhone, iPad, and Mac share the same identity automatically via iCloud
/// Keychain, falling back to device-local Keychain when iCloud Keychain is unavailable).
///
/// Mints standard RFC 8037 `EdDSA` JWTs (`sub = "pk:<base64url-32-byte-pubkey>"`) accepted
/// directly by `share.dotpop.click` with zero hardcoded app allowlists, zero login wall, and
/// zero third-party auth SDKs.
public final class PopDeviceIdentity: @unchecked Sendable {
    public static let shared = PopDeviceIdentity(service: "click.dotpop.popkit.identity")

    private let lock = NSLock()
    private let service: String?
    private var cachedKey: Curve25519.Signing.PrivateKey?

    public init(service: String = "click.dotpop.popkit.identity") {
        self.service = service
    }

    private init(ephemeralKey: Curve25519.Signing.PrivateKey) {
        self.service = nil
        self.cachedKey = ephemeralKey
    }

    /// Ephemeral in-memory identity for deterministic unit tests (never touches Keychain).
    public static func ephemeral() -> PopDeviceIdentity {
        PopDeviceIdentity(ephemeralKey: Curve25519.Signing.PrivateKey())
    }

    /// Stable public identity string (`"pk:<base64url-ed25519-pubkey>"`), safe to use as an
    /// account ID with `PopCloudSession` and `share.dotpop.click`.
    public var accountID: String {
        let pub = signingKey().publicKey.rawRepresentation
        return "pk:\(Self.base64URLEncode(pub))"
    }

    /// Mints a short-lived standard RFC 8037 `EdDSA` JWT proving possession of `accountID`.
    public func mintBearerToken(ttlSeconds: Int = 600, now: Date = Date()) throws -> String {
        let clampedTTL = max(30, min(900, ttlSeconds))
        let key = signingKey()
        let sub = "pk:\(Self.base64URLEncode(key.publicKey.rawRepresentation))"
        let iat = Int(now.timeIntervalSince1970)
        let exp = iat + clampedTTL

        let headerJSON = #"{"alg":"EdDSA","typ":"JWT"}"#
        let payloadJSON = #"{"sub":"\#(sub)","iat":\#(iat),"exp":\#(exp)}"#

        let signingInput = "\(Self.base64URLEncode(Data(headerJSON.utf8))).\(Self.base64URLEncode(Data(payloadJSON.utf8)))"
        let signature = try key.signature(for: Data(signingInput.utf8))
        return "\(signingInput).\(Self.base64URLEncode(signature))"
    }

    // MARK: - Keychain persistence

    private func signingKey() -> Curve25519.Signing.PrivateKey {
        lock.lock()
        defer { lock.unlock() }
        if let cachedKey { return cachedKey }
        if let service, let loaded = Self.loadFromKeychain(service: service) {
            cachedKey = loaded
            return loaded
        }
        let fresh = Curve25519.Signing.PrivateKey()
        if let service {
            Self.saveToKeychain(fresh, service: service)
        }
        cachedKey = fresh
        return fresh
    }

    private static func loadFromKeychain(service: String) -> Curve25519.Signing.PrivateKey? {
        for sync in [true, false] {
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: "ed25519-v1",
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]
            if sync {
                query[kSecAttrSynchronizable as String] = kCFBooleanTrue
            }
            var item: CFTypeRef?
            if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
               let data = item as? Data,
               let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: data) {
                return key
            }
        }
        return nil
    }

    private static func saveToKeychain(_ key: Curve25519.Signing.PrivateKey, service: String) {
        let data = key.rawRepresentation
        for sync in [true, false] {
            var item: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: "ed25519-v1",
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            ]
            if sync {
                item[kSecAttrSynchronizable as String] = kCFBooleanTrue
            }
            let status = SecItemAdd(item as CFDictionary, nil)
            if status == errSecSuccess || status == errSecDuplicateItem {
                return
            }
        }
    }

    static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
