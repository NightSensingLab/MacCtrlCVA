#!/usr/bin/env swift

import CryptoKit
import Foundation

struct ActivationLicense: Codable {
    let product: String
    let licenseVersion: Int
    let machineCodes: [String]
    let maxMachines: Int
    let issuedAt: Date
}

struct ActivationRecord: Codable {
    let id: UUID
    let createdAt: Date
    let machineCodes: [String]
    let activationCode: String
    let label: String?
}

private enum ScriptError: LocalizedError {
    case missingPrivateKey
    case tooManyMachineCodes
    case invalidPrivateKey
    case invalidArguments

    var errorDescription: String? {
        switch self {
        case .missingPrivateKey:
            return "Missing Keys/activation-private-key.txt"
        case .tooManyMachineCodes:
            return "Provide one or two machine codes."
        case .invalidPrivateKey:
            return "The private key in Keys/activation-private-key.txt is invalid."
        case .invalidArguments:
            return "Invalid arguments."
        }
    }
}

private extension Data {
    var base64URLEncodedString: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

var positionalArguments: [String] = []
var label: String?
var outputMode = "plain"

var index = 1
while index < CommandLine.arguments.count {
    let argument = CommandLine.arguments[index]

    switch argument {
    case "--label":
        let nextIndex = index + 1
        guard nextIndex < CommandLine.arguments.count else {
            fputs("error: --label requires a value\n", stderr)
            exit(1)
        }
        label = CommandLine.arguments[nextIndex]
        index += 2
    case "--output":
        let nextIndex = index + 1
        guard nextIndex < CommandLine.arguments.count else {
            fputs("error: --output requires a value\n", stderr)
            exit(1)
        }
        outputMode = CommandLine.arguments[nextIndex]
        index += 2
    default:
        positionalArguments.append(argument)
        index += 1
    }
}

guard !positionalArguments.isEmpty, positionalArguments.count <= 2 else {
    print("Usage: ./scripts/generate-activation-code.swift [--label NOTE] [--output plain|kv] MACHINE_CODE [MACHINE_CODE_2]")
    exit(1)
}

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let root = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let privateKeyURL = root.appendingPathComponent("Keys/activation-private-key.txt")
let recordsURL = root.appendingPathComponent("Keys/activation-records.json")
do {
    guard let privateKeyBase64 = try? String(contentsOf: privateKeyURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines), !privateKeyBase64.isEmpty else {
        throw ScriptError.missingPrivateKey
    }

    guard let privateKeyData = Data(base64Encoded: privateKeyBase64) else {
        throw ScriptError.invalidPrivateKey
    }

    let privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    encoder.dateEncodingStrategy = .iso8601

    let license = ActivationLicense(
        product: "MacCtrlCVA",
        licenseVersion: 1,
        machineCodes: positionalArguments,
        maxMachines: 2,
        issuedAt: Date()
    )

    let payload = try encoder.encode(license)
    let signature = try privateKey.signature(for: payload).derRepresentation
    let activationCode = payload.base64URLEncodedString + "." + signature.base64URLEncodedString
    let records = try loadRecords(from: recordsURL)
    let record = ActivationRecord(
        id: UUID(),
        createdAt: Date(),
        machineCodes: positionalArguments,
        activationCode: activationCode,
        label: label?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    )
    try saveRecords(records + [record], to: recordsURL)

    switch outputMode {
    case "plain":
        print(activationCode)
    case "kv":
        print("ACTIVATION_CODE=\(activationCode)")
        print("RECORD_ID=\(record.id.uuidString)")
        print("RECORDS_PATH=\(recordsURL.path)")
        print("MACHINE_CODES=\(record.machineCodes.joined(separator: ","))")
        print("LABEL=\(record.label ?? "")")
    default:
        throw ScriptError.invalidArguments
    }
} catch {
    fputs("error: \(error.localizedDescription)\n", stderr)
    exit(1)
}

private func loadRecords(from url: URL) throws -> [ActivationRecord] {
    guard FileManager.default.fileExists(atPath: url.path) else {
        return []
    }

    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode([ActivationRecord].self, from: data)
}

private func saveRecords(_ records: [ActivationRecord], to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(records)
    try data.write(to: url, options: .atomic)
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
