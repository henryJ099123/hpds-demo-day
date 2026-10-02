/*
 * Demo Day: Henry Jochaniewicz
 * Metal Introduction
 *
 * This is a minimal program that uses metal-cpp
 * to add up two arrays on the GPU
 */

// These three macros must only be defined once!
#define MTL_PRIVATE_IMPLEMENTATION
#define NS_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION
#include <Foundation/Foundation.hpp>
#include <Metal/Metal.hpp>
#include <QuartzCore/QuartzCore.hpp>

#include <simd/simd.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>

#define SIZE (1<<10)

void randomize(float *a);
double addup(const float *a);
void add_arrays(const float *a, const float* b, float* c);

int main(int argc, const char* argv[]) {
    srand(7);
    float *a = (float*) malloc(SIZE * sizeof(float));
    float *b = (float*) malloc(SIZE * sizeof(float));
    float *c = (float*) malloc(SIZE * sizeof(float));

    randomize(a);
    randomize(b);

    // Device is an abstraction for GPU. This constructor just gets one of them.
    MTL::Device* device = MTL::CreateSystemDefaultDevice();

    // Equivalent of a CUDA stream.
    MTL::CommandQueue* commandQueue = device->newCommandQueue();
    assert(commandQueue);
    // Needed to write commands into the queue.
    MTL::CommandBuffer* commandBuffer = commandQueue->commandBuffer();
    // Needed to write commands into the buffer.
    MTL::ComputeCommandEncoder* encoder = commandBuffer->computeCommandEncoder();

    // Load the shader (kernel) into memory as a library.
    NS::Error* error;
    NS::String* filepath = NS::String::string("add.metallib", NS::UTF8StringEncoding);
    MTL::Library* lib = device->newLibrary(filepath, &error);
    if(error) {
        fprintf(stderr, "Failure to load library\n"); 
        exit(1);
    }

    // Reference the kernel from the shader.
    MTL::Function* kernel = lib->newFunction(NS::String::string("add_arrays", NS::ASCIIStringEncoding));
    assert(kernel);

    // Get a "pipeline state object", which just tells the GPU which kernel to run.
    // This exists to match the graphics rendering API.
    MTL::ComputePipelineState* kernelPSO = device->newComputePipelineState(kernel, &error);
    if(error) {
        fprintf(stderr, "Failure to create pipeline state object\n");
        exit(1);
    }

    // Associate the command we will submit with the kernel.
    encoder->setComputePipelineState(kernelPSO);

    // Allocate buffers.
    // Notice these are in "global memory" akin to CUDA. This pays less of a performance cost
    // since the GPU and CPU are on the same die.
    MTL::Buffer* buffer_a = device->newBuffer(a, SIZE * sizeof(float), MTL::ResourceStorageModeShared);
    MTL::Buffer* buffer_b = device->newBuffer(b, SIZE * sizeof(float), MTL::ResourceStorageModeShared);
    MTL::Buffer* buffer_c = device->newBuffer(SIZE * sizeof(float), MTL::ResourceStorageModeShared);

    // Indicate the placement of each buffer in the GPU via index.
    encoder->setBuffer(buffer_a, 0, 0); 
    encoder->setBuffer(buffer_b, 0, 1); 
    encoder->setBuffer(buffer_c, 0, 2); 

    // This is just like declaring block and grid sizes in CUDA.
    MTL::Size grid = MTL::Size(SIZE, 1, 1);
    NS::UInteger threadGroupSize = kernelPSO->maxTotalThreadsPerThreadgroup();
    if(threadGroupSize > SIZE) threadGroupSize = SIZE;
    MTL::Size threadGroup = MTL::Size(threadGroupSize, 1, 1);
    encoder->dispatchThreadgroups(grid, threadGroup);

    encoder->endEncoding();

    struct timeval start;
    gettimeofday(&start, 0);

    // Actually execute kernel on the GPU.
    commandBuffer->commit();
    commandBuffer->waitUntilCompleted();

    struct timeval end;
    gettimeofday(&end, 0);

    struct timeval elapsed;
    timersub(&end, &start, &elapsed);

    printf("elapsed - GPU: %ld.%0.6u\n", elapsed.tv_sec, elapsed.tv_usec);
    // We can read directly from the buffer because it is in RAM.
    printf("GPU result: %lf\n", addup((const float*) buffer_c->contents()));

    add_arrays(a, b, c);
    printf("CPU result: %lf\n", addup(c));

    // free our memory
    buffer_c->release();
    buffer_b->release();
    buffer_a->release();
    kernelPSO->release();
    kernel->release();
    lib->release();
    commandQueue->release();
    device->release();

    free(a);
    free(b);
    return 0;
}

void randomize(float *a) {
    for(int i = 0; i < SIZE; i++) {
        a[i] = rand();
    }
}

double addup(const float *a) {
    double total = 0;
    for(int i = 0; i < SIZE; i++) {
        total += a[i];
    }
    return total;
}

void add_arrays(const float *a, const float* b, float* c) {
    for(int i = 0; i < SIZE; i++) {
        c[i] = a[i] + b[i];
    }
}

