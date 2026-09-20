// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIInterpreterIOS",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "AIInterpreterIOS", targets: ["AIInterpreterIOS"])
    ],
    targets: [
        .target(name: "AIInterpreterIOS")
    ]
)
