import UIKit
import MetalKit
import simd

var context : CGContext?

class Flam3View: UIImageView
{
    var blankImage:UIImage! = nil
    let queue = DispatchQueue(label: "Q")
    var gDevice:MTLDevice! = nil
    var commandQueue:MTLCommandQueue! = nil
    var cBuffer:MTLBuffer! = nil
    var texture1: MTLTexture!
    var pipeLine1:MTLComputePipelineState! = nil
    var tGroups = MTLSize()
    var tCount = MTLSize()

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        gDevice = MTLCreateSystemDefaultDevice()

        blankImage = UIColor.black.image(CGSize(width: 1024/2, height: 1024/2))
        texture1 = texture(from: blankImage)
        clearImage()
        
        commandQueue = gDevice.makeCommandQueue()!
        cBuffer = gDevice?.makeBuffer(length:MemoryLayout<Control>.stride, options:.storageModeShared)
    }

    func clearImage() {
        texture1 = texture(from: blankImage)
        image = image(from: texture1)
    }
    
    //MARK: -
    
    func updateImage() {
        queue.async {
            self.calcImage()
            DispatchQueue.main.async { self.image = self.image(from: self.texture1) }
        }
    }
    
    func calcImage() {
        if pipeLine1 == nil {
            func buildPipeline(_ shaderFunction:String) -> MTLComputePipelineState {
                var result:MTLComputePipelineState!
                
                do {
                    let defaultLibrary = gDevice?.makeDefaultLibrary()
                    let prg = defaultLibrary?.makeFunction(name:shaderFunction)
                    result = try gDevice?.makeComputePipelineState(function: prg!)
                } catch { fatalError("Failed to setup " + shaderFunction) }
                
                return result
            }
            
            pipeLine1 = buildPipeline("Flam3Shader")
        }
        
        cBuffer?.contents().copyMemory(from:&control, byteCount:MemoryLayout<Control>.stride)

        let tWidth = pipeLine1.threadExecutionWidth
        tGroups = MTLSize(width:tWidth, height:1, depth:1)
        tCount = MTLSize(width:tWidth, height:1, depth:1)
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        commandEncoder.setComputePipelineState(pipeLine1)
        commandEncoder.setTexture(texture1, index: 0)
        commandEncoder.setBuffer(cBuffer, offset: 0, index: 0)
        commandEncoder.dispatchThreadgroups(tGroups, threadsPerThreadgroup:tCount)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    //MARK: -
    
    override func draw(_ rect: CGRect) {
        UIColor.blue.setFill()
        UIBezierPath(rect:rect).fill()
    }

    //MARK: -

    var pt = CGPoint()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            pt = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            var npt = touch.location(in: self)
            npt.x -= pt.x
            npt.y -= pt.y
            vc.focusMovement(npt)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        pt.x = 0
        pt.y = 0
        vc.focusMovement(pt)
    }
    
    //MARK: -
    // edit Scheme, Options, Metal API Validation : Disabled
    //the fix is to turn off Metal API validation under Product -> Scheme -> Options
    
    func texture(from image: UIImage) -> MTLTexture {
        guard let cgImage = image.cgImage else { fatalError("Can't open image \(image)") }
        
        let textureLoader = MTKTextureLoader(device: self.gDevice)
        do {
            let textureOut = try textureLoader.newTexture(cgImage:cgImage)
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: textureOut.pixelFormat,
                width: textureOut.width,
                height: textureOut.height,
                mipmapped: false)
            texture1 = self.gDevice.makeTexture(descriptor: textureDescriptor)
            return textureOut
        }
        catch {
            fatalError("Can't load texture")
        }
    }
    
    func image(from texture: MTLTexture) -> UIImage {
        let bytesPerPixel: Int = 4
        let imageByteCount = texture.width * texture.height * bytesPerPixel
        let bytesPerRow = texture.width * bytesPerPixel
        var src = [UInt8](repeating: 0, count: Int(imageByteCount))
        
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        texture.getBytes(&src, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent = 8
        let context = CGContext(data: &src,
                                width: texture.width,
                                height: texture.height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        
        let dstImageFilter = context?.makeImage()
        
        return UIImage(cgImage: dstImageFilter!, scale: 0.0, orientation: UIImageOrientation.up)
    }
}

extension UIColor {
    func image(_ size:CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
    }
}
