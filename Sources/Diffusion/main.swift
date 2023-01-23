import Kitura
import StableDiffusion

let router = Router()
import Foundation

import CoreGraphics
import CoreML
import UniformTypeIdentifiers

var imageCount: Int = 1
var stepCount: Int = 20
var seed: UInt32 = 93
var outputPath: String = "./"
var saveEvery: Int = 0
var guidanceScale: Float = 14
var prompt: String = ""
var negativePrompt: String = ""
var resourcePath: String = "./models/DreamlikeDiffusion1"

router.get("/") { request, response, next in

    if request.queryParameters["prompt"] != nil {
        prompt = request.queryParameters["prompt"]!
    }else{
        response.send("No prompt provided")
        return next()
    }

    if request.queryParameters["negativePrompt"] != nil {
        negativePrompt = request.queryParameters["negativePrompt"]!
    }

    response.headers["Content-Type"] = "image/png"

    let config = MLModelConfiguration()

    if #available(macOS 13.1, *) {
        let computeUnits: ComputeUnits = .all
        config.computeUnits = computeUnits.asMLComputeUnits

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
                negativePrompt: negativePrompt,
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

        for i in 0 ..< images.count {
            let image = images[i]

            let imageData = CFDataCreateMutable(nil, 0)
            let destination = CGImageDestinationCreateWithData(imageData!, UTType.png.identifier as CFString, 1, nil)

            CGImageDestinationAddImage(destination!, image!, nil)
            CGImageDestinationFinalize(destination!)

            let data = imageData! as Data
            response.send(data:data)

        }
    }

    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
print("Open http://localhost:8080?prompt=cat&negativePrompt=dog")

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
    print("\n")
}