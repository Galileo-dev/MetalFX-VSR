import AppKit
import Cocoa
import Metal
import MetalFX
import MetalKit
import MetalPerformanceShaders

@available(macOS 13.0, *)
public struct ImageUpscaler {
  public init() {}

  public func upscaleImage(path: String, scaleFactor: Float) -> NSImage? {

    let nsImage = NSImage(contentsOfFile: path)!
    let device = MTLCreateSystemDefaultDevice()!
    let outputImage = upscaleImageWithMetalFX(
      nsImage: nsImage, device: device, scaleFactor: scaleFactor)!
    return outputImage
  }
}

@available(macOS 13.0, *)
func upscaleImageWithMetalFX(nsImage: NSImage, device: MTLDevice, scaleFactor: Float) -> NSImage? {
  guard let inputTexture = nsImageToMetalTexture(nsImage: nsImage, device: device) else {
    return nil
  }

  let width = Int(Float(inputTexture.width) * scaleFactor)
  let height = Int(Float(inputTexture.height) * scaleFactor)

  let outputDescriptor = MTLTextureDescriptor.texture2DDescriptor(
    pixelFormat: .rgba8Unorm,
    width: width,
    height: height,
    mipmapped: false)

  guard let outputTexture = device.makeTexture(descriptor: outputDescriptor) else {
    return nil
  }

  let commandQueue = device.makeCommandQueue()
  let commandBuffer = commandQueue?.makeCommandBuffer()

  let spatialScalerDescriptor = MTLFXSpatialScalerDescriptor()

  let supported = MTLFXSpatialScalerDescriptor.supportsDevice(device)
  print("Supported?: \(supported)")

  //input
  spatialScalerDescriptor.inputHeight = inputTexture.height
  spatialScalerDescriptor.inputWidth = inputTexture.width
  spatialScalerDescriptor.colorTextureFormat = .rgba8Unorm
  spatialScalerDescriptor.colorProcessingMode = .perceptual

  //output
  spatialScalerDescriptor.outputHeight = outputTexture.height
  spatialScalerDescriptor.outputWidth = outputTexture.width
  spatialScalerDescriptor.outputTextureFormat = .rgba8Unorm

  let spatialScaler = spatialScalerDescriptor.makeSpatialScaler(device: device)
  print("spatialScaler: \(spatialScaler)")

  spatialScaler?.colorTexture = inputTexture
  spatialScaler?.inputContentWidth = inputTexture.width
  spatialScaler?.inputContentHeight = inputTexture.height
  spatialScaler?.outputTexture = outputTexture

  spatialScaler?.encode(commandBuffer: commandBuffer!)

  commandBuffer?.commit()

  commandBuffer?.waitUntilCompleted()
  // make sure to flip the image
  let ciImage = CIImage(mtlTexture: outputTexture, options: nil)?.oriented(.downMirrored)

  let nsImage = NSImage(size: NSSize(width: width, height: height))
  nsImage.addRepresentation(NSCIImageRep(ciImage: ciImage!))

  return nsImage
}

func nsImageToMetalTexture(nsImage: NSImage, device: MTLDevice) -> MTLTexture? {
  // Convert NSImage to CGImage
  guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    return nil
  }

  // Create MTLTextureDescriptor
  let width = cgImage.width
  print("width: \(width)")
  let height = cgImage.height
  print("height: \(height)")
  let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
    pixelFormat: .rgba8Unorm,
    width: width,
    height: height,
    mipmapped: false)

  // Create MTLTexture
  guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
    return nil
  }

  // Copy image data to MTLTexture
  let bytesPerPixel = 4
  let bytesPerRow = bytesPerPixel * width
  let region = MTLRegionMake2D(0, 0, width, height)

  if let dataProvider = cgImage.dataProvider,
    let data = dataProvider.data,
    let bytes = CFDataGetBytePtr(data)
  {
    texture.replace(
      region: region,
      mipmapLevel: 0,
      withBytes: bytes,
      bytesPerRow: bytesPerRow)
  } else {
    return nil
  }

  return texture
}
