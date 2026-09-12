// swift-tools-version: 5.9

import PackageDescription
import Foundation

var dualScreenSwiftSettings: [SwiftSetting] = []

// Xcode 27 ships Swift 6.4. Keep Apple API references out of source parsing on
// older toolchains so the package retains its unsupported runtime fallback.
#if compiler(>=6.4)
dualScreenSwiftSettings.append(.define("DUAL_SCREEN_HINGE_IOS27"))

let buildEnvironment = ProcessInfo.processInfo.environment
let buildXcodeVersion = Int(buildEnvironment["XCODE_VERSION_ACTUAL"] ?? "") ?? 0
let sdkRoot = buildEnvironment["SDKROOT"] ?? ""

func selectedXcodeVersion() -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
    process.arguments = ["-version"]
    let output = Pipe()
    process.standardOutput = output
    process.standardError = Pipe()
    do {
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return "" }
        return String(
            data: output.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
    } catch {
        return ""
    }
}

let selectedXcode = selectedXcodeVersion()
let selectedVersion = selectedXcode
    .split(separator: "\n")
    .first?
    .split(separator: " ")
    .last?
    .split(separator: ".")
    .compactMap { Int($0) } ?? []
let selectedXcodeSupports271 = selectedVersion.first.map { major in
    major > 27 || (major == 27 && selectedVersion.dropFirst().first ?? 0 >= 1)
} ?? false
let enablesIOS271 = buildXcodeVersion >= 2710
    || sdkRoot.contains("iPhoneOS27.1.sdk")
    || sdkRoot.contains("iPhoneSimulator27.1.sdk")
    || selectedXcodeSupports271
    || buildEnvironment["DUAL_SCREEN_HINGE_ENABLE_IOS271"] == "1"
if enablesIOS271 {
    dualScreenSwiftSettings.append(.define("DUAL_SCREEN_HINGE_IOS271"))
}
#endif

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
            path: "Tests"
        )
    ]
)
