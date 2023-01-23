import Kitura
import StableDiffusion

let router = Router()
import Foundation

import CoreGraphics
import CoreML
import UniformTypeIdentifiers

var prompt: String = "a cat"
var imageCount: Int = 1
var stepCount: Int = 10
var seed: UInt32 = 93
var outputPath: String = "./"
var saveEvery: Int = 0
var guidanceScale: Float = 7.5


router.get("/") { request, response, next in

    response.send("Hello world!")


    let config = MLModelConfiguration()

    if #available(macOS 13.1, *) {
        let computeUnits: ComputeUnits = .all
        config.computeUnits = computeUnits.asMLComputeUnits

        let resourcePath: String = "./DreamlikeDiffusion1"
        let resourceURL = URL(filePath: resourcePath)

        let pipeline = try StableDiffusionPipeline(resourcesAt: resourceURL,
                configuration: config,
                disableSafety: false,
                reduceMemory: true)

        try pipeline.loadResources()

        let scheduler: SchedulerOption = .pndm

        let sampleTimer = SampleTimer()
        sampleTimer.start()

        let images = try pipeline.generateImages(
                prompt: prompt,
                negativePrompt: "",
                imageCount: imageCount,
                stepCount: stepCount,
                seed: seed,
                guidanceScale: guidanceScale,
                scheduler: scheduler.stableDiffusionScheduler
        ) { progress in
            sampleTimer.stop()
            handleProgress(progress,sampleTimer)
            if progress.stepCount != progress.step {
                sampleTimer.start()
            }
            return true
        }

        _ = try saveImages(images, logNames: true)


    }

    response.send("Hello world!")
    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()

extension String: Error {}
let runningOnMac = ProcessInfo.processInfo.isMacCatalystApp

@available(iOS 16.2, macOS 13.1, *)
enum SchedulerOption: String {
    case pndm, dpmpp
    var stableDiffusionScheduler: StableDiffusionScheduler {
        switch self {
        case .pndm: return .pndmScheduler
        case .dpmpp: return .dpmSolverMultistepScheduler
        }
    }
}

enum RunError: Error {
    case resources(String)
    case saving(String)
}

@available(iOS 16.2, macOS 13.1, *)
enum ComputeUnits: String, CaseIterable {
    case all, cpuAndGPU, cpuOnly, cpuAndNeuralEngine
    var asMLComputeUnits: MLComputeUnits {
        switch self {
        case .all: return .all
        case .cpuAndGPU: return .cpuAndGPU
        case .cpuOnly: return .cpuOnly
        case .cpuAndNeuralEngine: return .cpuAndNeuralEngine
        }
    }
}

func saveImages(
        _ images: [CGImage?],
        step: Int? = nil,
        logNames: Bool = false
) throws -> Int {
    let url = URL(filePath: outputPath)
    var saved = 0
    for i in 0 ..< images.count {

        guard let image = images[i] else {
            if logNames {
                print("Failed to save image \(i)")
            }
            continue
        }

        let name = imageName(i, step: step)
        let fileURL = url.appending(path:name)

        guard let dest = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw RunError.saving("Failed to create destination for \(fileURL)")
        }
        CGImageDestinationAddImage(dest, image, nil)
        if !CGImageDestinationFinalize(dest) {
            throw RunError.saving("Failed to save \(fileURL)")
        }
        if logNames {
            print("Saved \(fileURL)")
        }
        saved += 1
    }
    return saved
}

@available(macOS 13.1, *)
func handleProgress(
        _ progress: StableDiffusionPipeline.Progress,
        _ sampleTimer: SampleTimer
) {
    print("\u{1B}[1A\u{1B}[K")
    print("Step \(progress.step) of \(progress.stepCount) ")
    print(" [")
    print(String(format: "mean: %.2f, ", 1.0/sampleTimer.mean))
    print(String(format: "median: %.2f, ", 1.0/sampleTimer.median))
    print(String(format: "last %.2f", 1.0/sampleTimer.allSamples.last!))
    print("] step/sec")

    if saveEvery > 0, progress.step % saveEvery == 0 {
        let saveCount = (try? saveImages(progress.currentImages, step: progress.step)) ?? 0
        print(" saved \(saveCount) image\(saveCount != 1 ? "s" : "")")
    }
    print("\n")
}

func imageName(_ sample: Int, step: Int? = nil) -> String {
    let fileCharLimit = 75
    var name = prompt.prefix(fileCharLimit).replacingOccurrences(of: " ", with: "_")
    if imageCount != 1 {
        name += ".\(sample)"
    }

    name += ".\(seed)"

    if let step = step {
        name += ".\(step)"
    } else {
        name += ".final"
    }
    name += ".png"
    return name
}