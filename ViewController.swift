import Cocoa
import Metal
import MetalKit
import simd

class ViewController: NSViewController {
    
    var metal_device:     MTLDevice!
    var pipeline:         MTLRenderPipelineState!
    var queue:            MTLCommandQueue!
    var metalView:        MTKView!
    var compute_pipeline: MTLComputePipelineState!
    var monitor: Any?
    var mousePosition:    SIMD2<Double>!
    var cameraRotation:   SIMD2<Double>!
    
    var test:             Renderable!
    static var uniforms:  Uniforms!
    var kernel:           ComputeKernel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mousePosition = SIMD2<Double>(0, 0)
        cameraRotation = SIMD2<Double>(0, 0)
        
        metalView = MTKView(frame: NSRect(x: 0, y: 0, width: 1300, height: 1300))
        preferredContentSize = metalView.frame.size
        
        metal_device = MTLCreateSystemDefaultDevice()
        queue = metal_device.makeCommandQueue()
        
        let library  = metal_device.makeDefaultLibrary()
        let vertex   = library?.makeFunction(name: "vertexMain")
        let fragment = library?.makeFunction(name: "fragmentMain")
        
        let stateDescriptor = MTLRenderPipelineDescriptor()
        stateDescriptor.vertexFunction = vertex
        stateDescriptor.fragmentFunction = fragment
        stateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipeline = try! metal_device.makeRenderPipelineState(descriptor: stateDescriptor)
        
        metalView.delegate = self
        metalView.device = metal_device
        self.view.addSubview(metalView)
        self.view.frame.size = metalView.frame.size
        
        ViewController.uniforms = Uniforms(color: SIMD3<Float>(1.0, 0.0, 0.5),
                                           window_size: SIMD2<Float>(Float(self.view.frame.width), Float(self.view.frame.height)),
                                           camera_rotation: SIMD3<Float>(0.0, 0.0, -1.0),
                                           time: 0,
                                           rotation: 0,
                                           noise_time: 0)
        
        self.monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            if self.keyDownEvent(with: $0) {
                return nil
            }
            else {
                return $0
            }
        }
        self.monitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) {
            
            self.mouseMoveEvent(with: $0)
            
            return nil
        }
        
        kernel = ComputeKernel()
        kernel.createComputeKernel(library: library, device: metal_device, commandQueue: queue)
        
        test = Renderable()
        test.sendData(vertices: [-1.0, -1.0, 0.0,
                                  1.0, -1.0, 0.0,
                                  1.0,  1.0, 0.0,
                                  1.0,  1.0, 0.0,
                                 -1.0,  1.0, 0.0,
                                 -1.0, -1.0, 0.0], uniforms: ViewController.uniforms)
    }
}

extension ViewController: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
                
        guard let drawable = view.currentDrawable else {
            return
        }
        
        ViewController.uniforms.time += 0.001
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        guard let commandBuffer = queue.makeCommandBuffer() else { return }
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setFragmentTexture(kernel.texture, index: 0)
        
        test.render(renderEncoder: renderEncoder, device: metal_device)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        kernel.use(drawable: drawable)
    }
    
    func keyDownEvent(with event: NSEvent) -> Bool {
        
        print(event.keyCode)
        if event.keyCode == 0 {
            ViewController.uniforms.rotation -= 4
            print(ViewController.uniforms.rotation)
        }
        if event.keyCode == 2 {
            ViewController.uniforms.rotation += 4
        }
        
        // q
        if event.keyCode == 12 {
            ViewController.uniforms.noise_time -= 0.001
        }
        // e
        if event.keyCode == 14 {
            ViewController.uniforms.noise_time += 0.001
        }
        
        return true
    }
    
    func mouseMoveEvent(with event: NSEvent) {
        
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        let x = (Double(event.locationInWindow.x) - mousePosition.x)
        let y = (Double(event.locationInWindow.y) - mousePosition.y)
        
        cameraRotation.x -= x * 0.25
        cameraRotation.y += y * 0.25
        
        ViewController.uniforms.camera_rotation = SIMD3<Float>(
            Float(cos(cameraRotation.y * 3.14159265 / 180) * cos(cameraRotation.x * 3.14159265 / 180)),
            Float(sin(cameraRotation.y * 3.14159265 / 180)),
            Float(cos(cameraRotation.y * 3.14159265 / 180) * sin(cameraRotation.x * 3.14159265 / 180))
        )
        
        mousePosition = SIMD2<Double>(x, y)
    }
}


// Other definitions here

struct Uniforms {
    var color: SIMD3<Float>
    var window_size: SIMD2<Float>
    var camera_rotation: SIMD3<Float>
    var time: Float
    var rotation: Float
    var noise_time: Float
}

class Renderable {
    
    var vertices: [Float]!
    var uniforms: Uniforms!
    
    func sendData(vertices: [Float], uniforms: Uniforms) {
        self.vertices = vertices
        self.uniforms = uniforms
    }
    
    func makeVertexBuffer(device: MTLDevice) -> MTLBuffer? {
        let size = vertices.count * MemoryLayout.size(ofValue: vertices[0])
        return device.makeBuffer(bytes: vertices, length: size, options: [])
    }
    
    func render(renderEncoder: MTLRenderCommandEncoder, device: MTLDevice) {
        
        renderEncoder.setVertexBuffer(self.makeVertexBuffer(device: device), offset: 0, index: 0)
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        
        uniforms.time += 0.1
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

class ComputeKernel {
    
    var computePipeline: MTLComputePipelineState!
    var commandBuffer:   MTLCommandBuffer!
    
    var metal_device:    MTLDevice!
    var library:         MTLLibrary!
    var commandQueue:    MTLCommandQueue!
    var texture:         MTLTexture!
    
    func createComputeKernel(library: MTLLibrary?, device: MTLDevice?, commandQueue: MTLCommandQueue) {
        
        metal_device = device
        self.library = library
        self.commandQueue = commandQueue
        
        let computeKernel = library?.makeFunction(name: "compute")
        do {
            computePipeline = try device?.makeComputePipelineState(function: computeKernel!)
        }
        catch {
            print(error)
        }
        
        self.commandBuffer = self.commandQueue.makeCommandBuffer()
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.storageMode = .private
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        textureDescriptor.pixelFormat = .rgba32Float
        textureDescriptor.width = Int(ViewController.uniforms.window_size.x)
        textureDescriptor.height = Int(ViewController.uniforms.window_size.y)
        textureDescriptor.depth = 1
        texture = device!.makeTexture(descriptor: textureDescriptor)!
    }
    
    func use(drawable: CAMetalDrawable?) {
        
        self.commandBuffer = self.commandQueue.makeCommandBuffer()
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {return}
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setBytes(&ViewController.uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        computeEncoder.dispatchThreads(MTLSize(width: Int(ViewController.uniforms.window_size.x),
                                               height: Int(ViewController.uniforms.window_size.y), depth: 1),
                                               threadsPerThreadgroup: MTLSize(width: 10, height: 10, depth: 1))
        computeEncoder.endEncoding()
        
        commandBuffer.present(drawable!)
        commandBuffer.commit()
    }
}
