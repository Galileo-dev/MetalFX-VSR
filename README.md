# MetalFX-VSR
## TL;DR
This is a MetalFX implementation of Nvidia's Video Super Resolution (VSR) using Metal 3.0's spatial upscaling.

## Description
For some reason, Apple created a spatial upscaler in Metal 3.0, but macOS does not support many games. not because Apple hardware is bad, but because Apple won't write drivers for other graphics APIs * ahem * Vulkan. so there is very limited game support. 

Recently Nvidia came out with their [Video Super Resolution](https://blogs.nvidia.com/blog/2023/02/28/rtx-video-super-resolution/) (VSR) which allowed people with supported Nvidia GPUS to upscale video content.

## How it works
Swift is being used to create the upscale and upscale while Rust will handle the intermediary steps. 
Swift is a nice language but I am not familiar with it, so I will be using Rust to handle the intermediary steps.

## How to use
1. Install Rust
2. install Swift
3. Have a macOS device with Metal 3.0 support
4. in the root directory run `Cargo build --release`
5. cry because it doesn't work yet