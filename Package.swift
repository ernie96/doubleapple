// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "DoubleTalkApple",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CDoubleTalk",
            targets: ["CDoubleTalk"]
        ),
        .library(
            name: "DoubleTalkKit",
            targets: ["DoubleTalkKit"]
        )
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
        )
    ]
)
