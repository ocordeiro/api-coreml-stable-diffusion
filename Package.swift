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
        ],
        targets: [
            .target(
                    name: "Diffusion",
                    dependencies: [
                        "Kitura",
                        "StableDiffusion",
                    ]),

        ]
)
