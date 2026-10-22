// swift-tools-version: 5.9

import PackageDescription
import Foundation

// Detect public API declarations rather than inferring them from the Xcode or
// Swift version. SDKs with no declarations must compile the safe fallback.
func selectedSDKPath() -> String? {
    let sdkRoot = ProcessInfo.processInfo.environment["SDKROOT"] ?? ""
    if sdkRoot.hasPrefix("/") { return sdkRoot }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["--sdk", sdkRoot.isEmpty ? "iphoneos" : sdkRoot, "--show-sdk-path"]
    let output = Pipe()
    process.standardOutput = output
    process.standardError = FileHandle.nullDevice
    do {
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        return nil
    }
}

func uiKitDeclarations() -> String {
    guard let sdkPath = selectedSDKPath() else { return "" }
    let framework = URL(fileURLWithPath: sdkPath)
        .appendingPathComponent("System/Library/Frameworks/UIKit.framework")
    var declarations: [String] = []
    for directory in ["Headers", "Modules"] {
        guard let files = FileManager.default.enumerator(
            at: framework.appendingPathComponent(directory),
            includingPropertiesForKeys: nil
        ) else { continue }
        for case let file as URL in files {
            guard ["h", "swiftinterface"].contains(file.pathExtension),
                  let contents = try? String(contentsOf: file, encoding: .utf8)
            else { continue }
            declarations.append(contents)
        }
    }
    return declarations.joined(separator: "\n")
}

let declarations = uiKitDeclarations()
var dualScreenSwiftSettings: [SwiftSetting] = []
if declarations.range(
    of: #"(?:@interface|\bclass)\s+UIHingeInteraction\b"#,
    options: .regularExpression
) != nil {
    dualScreenSwiftSettings.append(.define("DUAL_SCREEN_HINGE_IOS27"))
}
if declarations.range(
    of: #"\bfunc\s+reservedRegions\s*\(|\breservedRegions(?:With\w*)?\s*:"#,
    options: .regularExpression
) != nil {
    dualScreenSwiftSettings.append(.define("DUAL_SCREEN_HINGE_IOS271"))
}
if declarations.range(
    of: #"\bUIVerticalBarEdge\s+verticalBarEdge\b|\bvar\s+verticalBarEdge\s*:"#,
    options: .regularExpression
) != nil {
    dualScreenSwiftSettings.append(.define("DUAL_SCREEN_HINGE_VERTICAL_BAR"))
}

let package = Package(
    name: "dual_screen_hinge",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "dual-screen-hinge", targets: ["dual_screen_hinge"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "dual_screen_hinge",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            swiftSettings: dualScreenSwiftSettings
        ),
        .testTarget(
            name: "dual_screen_hingeTests",
            dependencies: ["dual_screen_hinge"],
            path: "Tests",
            swiftSettings: dualScreenSwiftSettings
        )
    ]
)
