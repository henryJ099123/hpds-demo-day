# High Performance Distributed Systems Demo Day

Henry Jochaniewicz
October 2, 2026

# Metal Introduction

This repo and presentation covers [Metal](https://developer.apple.com/documentation/metal), which is Apple's graphics and compute API for programmatically interacting with its GPUs. While CUDA's focus is on weaponizing GPUs for computation, Metal covers both rendering and compute; it is a true [graphics API](https://gist.github.com/MangaD/b24f4e3052ff7854c6fa5074f22bc9b2#1-what-is-a-graphics-api) that interfaces into the rendering pipeline.

> This demo will not cover the rendering pipeline. If you are curious, the `triangle` subdirectory has code for getting a triangle on the screen.

Metal can be used for graphics programming, like Vulkan or OpenGL, or for general compute, like CUDA or OpenCL. For any kind of machine learning on Apple hardware (or for video games), using Metal is imperative.

Because Metal is Apple's own creation, they have the luxury of tailoring the API and what it offers to their hardware. We will see how this comes into play later.

## Computation Model

The *computation model* of Metal has its similarities and differences from CUDA.

[CUDA's programming model](https://docs.nvidia.com/cuda/cuda-programming-guide/01-introduction/programming-model.html) expects a *heterogenous system*, one in which the CPU and GPU are separated with separate memories. For its has the idea of *streams* into which are submitted *kernels* and *events*, which are executed across grids of thread blocks which have *warps* of 16 or 32 threads. You have to manually allocate buffers on the GPU and copy data back and forth from the CPU.

Furthermore, you can write the kernels in an extended C++ superset with some fancy notation (e.g., triple chevrons).

There is still a "client-server" relationship between the GPU and the CPU. In order to send commands to the GPU, you allocate a *command queue* (which is similar to a stream), and you wrap your kernel in a *command buffer* to send into the queue to the GPU. To actually transform kernel source code into GPU instructions, you need a *command encoder*. You also need a *pipeline object* to encapsulate the kernel before passing it into the encoder on the CPU side. Most of these are taken care of for you by CUDA.

> See [Apple's official explanation](https://developer.apple.com/documentation/metal/setting-up-a-command-structure). There is a really good picture that shows this in [this Metal tutorial](https://metaltutorial.com/Lesson%201%3A%20Hello%20Metal/2.%20Hello%20Triangle/) (its focus is graphics but the image also works for compute), at the section "The Metal Flow". There's also a good explanation from Apple's old documentation about [Command Organization and Execution](https://developer.apple.com/library/archive/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Cmd-Submiss/Cmd-Submiss.html#//apple_ref/doc/uid/TP40014221-CH3-SW1).

A lot of this boilerplate is because the same model of interaction is used for graphics rendering. A command buffer makes more sense when you are doing draw calls (i.e., you have multiple commands), and a pipeline object is more sensible with multiple kernels (i.e., vertex and fragment shaders).

The kernel itself can be split into a grid of thread blocks, like CUDA; but these can be of nonuniform size. Thread blocks are instead split into "SIMD groups" of threads, instead of warps, but they are quite similar; you can query the position of a thread in a SIMD group, though, unlike in a warp. However, [you can also decide to organize the data as just blocks of threads](https://medium.com/@ashwinalra/getting-started-with-metal-cpp-5f21423ed72a), which is similar to OpenCL (or so I'm told); it is interesting that Metal provides this option.

## Memory Model

The last major difference at a high level is the memory model. In CUDA, you have global memory (the "RAM" of the GPU), constant memory (read-only global memory), shared memory (part of the L1 cache of a streaming multiprocessor visible within a block), and register/local memory (per thread). There are others but we won't get into that.

Metal's memory model is different. Since the GPU and the CPU in an Apple Silicon chip are on the [same SOC die](https://medium.com/@ashwinalra/getting-started-with-metal-cpp-5f21423ed72a), they *share RAM efficiently*. There is still a sense of "global memory", but it aligns more with CUDA's unified memory approach.
- So, the cost to sharing buffers between the GPU and CPU is greatly reduced.
- Furthermore, buffers can be made *shared* or *private* to the GPU; but private GPU buffers must have their data copied from a shared one.

There is still an equivalent of shared memory; it's called "thread group memory" here, and each warp has its own local memory called "SIMD group memory," which is a local register cache.

## Setup

Since Metal is Apple's own creation, they really, *really* want you to stay in their environment to use their tools. I did not, but that's their intention.

The Metal API was originally for Swift and Objective-C, which no one uses outside of for Apple products. The kernels have to be written in [Metal Shading Language](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf), which is a C++-like language similar to GLSL meant to interface with the GPU. Kernel programs are called *shaders*, which are just programs that run on the GPU; the name makes more sense when you actually render things on the screen.

Luckily Apple released [Metal-cpp](https://developer.apple.com/metal/cpp/?source=post_page-----5f21423ed72a-----------------------------------------), a C++ interface that hooks into Objective-C Metal code for you. It is rather ugly and quite "C++" but it works, and is doubly great because we do not need to learn Objective-C.

You will need to install this at [its official open-source repo](http://github.com/apple/metal-cpp). Make sure you know where it is so you can include it in compilation; I placed it immediately outside of this repository's directory.

You need to install MacOS's SDK to be able to compile Metal code. This should be rather doable as long as you have XCode Developer Tools installed, which you should if you have ever tried to run `clang` on your laptop. If not:

```
clang
```

in a terminal should prompt the download of the tools. Then follow this [Metal Tutorial](https://metaltutorial.com/Setup/) as best you can. You may need to run the following too (I did) to get the Makefile to work:

```
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

It requires using the `xcrun` utility to get Metal's compiler and library tool to actually be able to load the kernel code into the main file.

Then hopefully running `make` should work. I've tried to comment up the code as much as possible to make it rather readable.

## Process

I followed Apple's introduction to [running code on the GPU](https://developer.apple.com/documentation/metal/performing-calculations-on-a-gpu) and changed the code to fit C++ rather than Objective-C to run the array compilation. I used [this repo](https://github.com/n-yoda/metal-without-xcode) and [this stack overflow post](https://stackoverflow.com/questions/70632495/how-to-build-apples-metal-cpp-example-using-cmake) to figure out how to get the Makefile to work correctly too.
