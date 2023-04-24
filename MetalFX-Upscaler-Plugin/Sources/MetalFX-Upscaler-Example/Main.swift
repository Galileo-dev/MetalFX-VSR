import AppKit
import MetalFX_Upscaler_Plugin

@main
@available(macOS 13.0, *)
class MyApp {

  static func main() {
    let upscaler = ImageUpscaler()
    let image = upscaler.upscaleImage(path: "./input.png", scaleFactor: 4.0)
    saveImage(nsImage: image!, path: "./output.png")

  }
}

func saveImage(nsImage: NSImage, path: String) -> Bool {
  guard let tiffData = nsImage.tiffRepresentation else {
    return false
  }

  guard let bitmapImage = NSBitmapImageRep(data: tiffData) else {
    return false
  }

  guard let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
    return false
  }

  do {
    try pngData.write(to: URL(fileURLWithPath: path))
  } catch {
    return false
  }

  return true
}
