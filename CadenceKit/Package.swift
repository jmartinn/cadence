// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CadenceKit",
    products: [
        .library(name: "CadenceKit", targets: ["CadenceKit"]),
    ],
    targets: [
        .target(name: "CadenceKit"),
        .testTarget(name: "CadenceKitTests", dependencies: ["CadenceKit"]),
    ],
    swiftLanguageModes: [.v5]
)
