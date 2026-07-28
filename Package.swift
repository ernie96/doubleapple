// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "DoubleTalkApple",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DoubleTalkApp", targets: ["DoubleTalkApp"]),
        .executable(name: "DoubleTalkVoiceExtension", targets: ["DoubleTalkVoiceExtension"])
    ],
    targets: [
        .target(
            name: "CDoubleTalk",
            dependencies: [],
            path: "Sources/CDoubleTalk",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ]
        ),
        .target(
            name: "DoubleTalkKit",
            dependencies: ["CDoubleTalk"],
            path: "Sources/DoubleTalkKit"
        ),
        .executableTarget(
            name: "DoubleTalkApp",
            dependencies: ["DoubleTalkKit"],
            path: "Apps/DoubleTalkApp"
        ),
        .executableTarget(
            name: "DoubleTalkVoiceExtension",
            dependencies: ["DoubleTalkKit"],
            path: "Apps/DoubleTalkVoiceExtension"
        )
    ]
)
