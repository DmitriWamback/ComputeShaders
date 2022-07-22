import Cocoa
import Metal
import MetalKit
import simd

class ViewController: NSViewController {
    
    var metal_device:     MTLDevice!
    var metal_layer:      CAMetalLayer!
    var pipeline:         MTLRenderPipelineState!
    var queue:            MTLCommandQueue!
    var metalView:        MTKView!
    var compute_pipeline: MTLComputePipelineState!
    
    var test:         Renderable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        metalView = MTKView(frame: NSRect(x: 0, y: 0, width: 1200, height: 800))
        
        metal_device = MTLCreateSystemDefaultDevice()
        queue = metal_device.makeCommandQueue()
        metalView.delegate = self
        metalView.device = metal_device
        self.view.addSubview(metalView)
        self.view.frame.size = metalView.frame.size
        
        test = Renderable()
        test.sendData(vertices: [-0.5, -0.5, 0.0,
                                  0.5, -0.5, 0.0,
                                  0.0,  0.5, 0.0])
    }
}

extension ViewController: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        
        guard let drawable = view.currentDrawable else {
            return
        }
        
        let library  = metal_device.makeDefaultLibrary()
        let vertex   = library?.makeFunction(name: "vertexMain")
        let fragment = library?.makeFunction(name: "fragmentMain")
        let kernel   = library?.makeFunction(name: "compute")
        
        let stateDescriptor = MTLRenderPipelineDescriptor()
        stateDescriptor.vertexFunction = vertex
        stateDescriptor.fragmentFunction = fragment
        stateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipeline = try! metal_device.makeRenderPipelineState(descriptor: stateDescriptor)
        compute_pipeline = try! metal_device.makeComputePipelineState(function: kernel!)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        guard let commandBuffer = queue.makeCommandBuffer() else {
            return
        }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipeline)
        
        test.render(renderEncoder: renderEncoder, device: metal_device)
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}


// Other definitions here

struct Uniforms {
    var color: SIMD3<Float>
    var time: Float
}

class Renderable {
    
    var vertices: [Float]!
    var uniforms: Uniforms!
    
    func sendData(vertices: [Float]) {
        self.vertices = vertices
        uniforms = Uniforms(color: SIMD3<Float>(1.0, 0.0, 1.0), time: 1.0)
    }
    
    func makeVertexBuffer(device: MTLDevice) -> MTLBuffer? {
        let size = vertices.count * MemoryLayout.size(ofValue: vertices[0])
        return device.makeBuffer(bytes: vertices, length: size, options: [])
    }
    
    func render(renderEncoder: MTLRenderCommandEncoder, device: MTLDevice) {
        
        renderEncoder.setVertexBuffer(self.makeVertexBuffer(device: device), offset: 0, index: 0)
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        
        uniforms.time += 0.1
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    }
    
    func render(computeEncoder: MTLComputeCommandEncoder, device: MTLDevice) {
        
    }
}
