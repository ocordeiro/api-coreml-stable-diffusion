// swift-tools-version:5.0
import PackageDescription

let package = Package(
        name: "Diffusion",
        platforms: [
            .macOS("13.1")
        ],
        dependencies: [
            .package(url: "https://github.com/Kitura/Kitura", from: "2.9.0"),
            .package(url: "https://github.com/apple/ml-stable-diffusion.git", .branch("main")),
            .package(url: "https://github.com/mxcl/Path.swift.git", from: "1.4.0"),
            .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.16"),
        ],
        targets: [
            .target(
                    name: "Diffusion",
                    dependencies: [
                        "Kitura",
                        "StableDiffusion",
                        "Path",
                        "ZIPFoundation",
                    ]),

        ]
)
