import Kitura
import StableDiffusion

let router = Router()
import Foundation
import StableDiffusion

router.get("/") { request, response, next in
    response.send("Hello world!")
    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()

extension String: Error {}
let runningOnMac = ProcessInfo.processInfo.isMacCatalystApp

