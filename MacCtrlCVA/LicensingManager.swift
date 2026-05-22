import CryptoKit
import Foundation
import IOKit
import Security

struct ActivationLicense: Codable {
    let product: String
    let licenseVersion: Int
    let machineCodes: [String]
    let maxMachines: Int
    let issuedAt: Date
}

enum ActivationError: LocalizedError {
    case invalidFormat
    case invalidSignature
    case machineNotAuthorized
    case invalidProduct
    case invalidPublicKey
    case machineIdentityUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "The activation code format is invalid."
        case .invalidSignature:
            return "The activation code signature is invalid."
        case .machineNotAuthorized:
            return "This activation code does not match the current machine code."
        case .invalidProduct:
            return "This activation code was not issued for MacCtrlCVA."
        case .invalidPublicKey:
            return "The embedded activation public key is invalid."
        case .machineIdentityUnavailable:
            return "Unable to generate a stable machine code on this Mac."
        }
    }
}

final class LicensingManager {
    static let productName = "MacCtrlCVA"

    private let keychainService = "com.magamale.MacCtrlCVA.licensing"
    private let keychainAccount = "activationCode"
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func currentMachineCode() throws -> String {
        guard let platformUUID = platformUUID() else {
            throw ActivationError.machineIdentityUnavailable
        }

        let digest = SHA256.hash(data: Data("\(Self.productName):\(platformUUID)".utf8))
        let prefix = digest.prefix(10).map { String(format: "%02X", $0) }.joined()
        let groups = stride(from: 0, to: prefix.count, by: 4).map { index in
            let start = prefix.index(prefix.startIndex, offsetBy: index)
            let end = prefix.index(start, offsetBy: min(4, prefix.distance(from: start, to: prefix.endIndex)), limitedBy: prefix.endIndex) ?? prefix.endIndex
            return String(prefix[start..<end])
        }

        return "MCVA-" + groups.joined(separator: "-")
    }

    var isActivated: Bool {
        (try? validatedStoredLicense()) != nil
    }

    func currentLicense() -> ActivationLicense? {
        try? validatedStoredLicense()
    }

    func activate(with activationCode: String) throws {
        _ = try validate(activationCode: activationCode)
        try storeActivationCode(activationCode)
    }

    func deactivate() {
        SecItemDelete(keychainQuery as CFDictionary)
    }

    func activationCode() -> String? {
        try? storedActivationCode()
    }

    @discardableResult
    func validate(activationCode: String) throws -> ActivationLicense {
        let normalizedCode = activationCode
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let segments = normalizedCode.split(separator: ".")
        guard segments.count == 2 else {
            throw ActivationError.invalidFormat
        }

        guard
            let payloadData = Data(base64URLEncoded: String(segments[0])),
            let signatureData = Data(base64URLEncoded: String(segments[1]))
        else {
            throw ActivationError.invalidFormat
        }

        guard let publicKeyData = Data(base64Encoded: ActivationKeys.publicKeyBase64) else {
            throw ActivationError.invalidPublicKey
        }

        let publicKey = try P256.Signing.PublicKey(rawRepresentation: publicKeyData)
        let signature = try P256.Signing.ECDSASignature(derRepresentation: signatureData)

        guard publicKey.isValidSignature(signature, for: payloadData) else {
            throw ActivationError.invalidSignature
        }

        let license = try decoder.decode(ActivationLicense.self, from: payloadData)

        guard license.product == Self.productName else {
            throw ActivationError.invalidProduct
        }

        let machineCode = try currentMachineCode()
        guard license.machineCodes.contains(machineCode) else {
            throw ActivationError.machineNotAuthorized
        }

        return license
    }

    private func validatedStoredLicense() throws -> ActivationLicense {
        let activationCode = try storedActivationCode()
        return try validate(activationCode: activationCode)
    }

    private func storedActivationCode() throws -> String {
        var query = keychainQuery
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data, let code = String(data: data, encoding: .utf8) else {
            throw ActivationError.invalidFormat
        }

        return code
    }

    private func storeActivationCode(_ activationCode: String) throws {
        let data = Data(activationCode.utf8)
        SecItemDelete(keychainQuery as CFDictionary)

        var query = keychainQuery
        query[kSecValueData as String] = data

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    private var keychainQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
    }

    private func platformUUID() -> String? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        guard service != 0 else {
            return nil
        }
        defer { IOObjectRelease(service) }

        let key = kIOPlatformUUIDKey as CFString
        return IORegistryEntryCreateCFProperty(service, key, kCFAllocatorDefault, 0)?.takeRetainedValue() as? String
    }
}

private extension Data {
    init?(base64URLEncoded value: String) {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let padding = 4 - base64.count % 4
        if padding < 4 {
            base64.append(String(repeating: "=", count: padding))
        }

        self.init(base64Encoded: base64)
    }

    var base64URLEncodedString: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
