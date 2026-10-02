#include <iostream>
#include "mtl_engine.hpp"

void MTLEngine::init() {
    initDevice();
    initWindow();

    createTriangle();
    createDefaultLibrary();
    createCommandQueue();
    createRenderPipeline();
}

void MTLEngine::run() {
    while(!glfwWindowShouldClose(glfwWindow)) {
        // This is essentially a memory arena.
        // Do not need to explicitly release() objects in an autoreleasePool,
        // which implicitly manages lifetimes and prevents memory leaks.
        // Scope of lifetime is roughly one frame.
        @autoreleasepool {
            metalDrawable = (__bridge CA::MetalDrawable*)[metalLayer nextDrawable];
            draw();
        }
        glfwPollEvents();
    }
}

void MTLEngine::cleanup() {
    glfwTerminate();
    // free memory
    metalDevice->release();
}

void MTLEngine::initDevice() {
    // this allows access to the GPU.
    metalDevice = MTL::CreateSystemDefaultDevice();
}

void MTLEngine::initWindow() {
    glfwInit();
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    glfwWindow = glfwCreateWindow(800, 800, "Metal Engine", NULL, NULL);
    if(!glfwWindow) {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }

    // metalWindow is a reference to underyling native macOS Cocoa window
    metalWindow = glfwGetCocoaWindow(glfwWindow);

    // disgusting. This is objective-C declaration for a frame buffer
    metalLayer = [CAMetalLayer layer];
    // this converts C++ pointer to objectiveC MTLDevice
    metalLayer.device = (__bridge id<MTLDevice>) metalDevice;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalWindow.contentView.layer = metalLayer;
    metalWindow.contentView.wantsLayer = YES;
}

void MTLEngine::createTriangle() {
    simd::float3 triangleVertices[] = {
        {-0.5f, -0.5f, 0.0f},
        { 0.5f, -0.5f, 0.0f},
        { 0.0f,  0.5f, 0.0f},
    };

    // This is essentially unified memory with the last argument
    triangleVertexBuffer = metalDevice->newBuffer(&triangleVertices,
           sizeof(triangleVertices), MTL::ResourceStorageModeShared);
}

void MTLEngine::createDefaultLibrary() {
    // XCode is supposed to automatically compile metal source files into
    // a single default library at compilation.
    // This object gives the ability to reference metal source code.
    /*
    metalDefaultLibrary = metalDevice->newDefaultLibrary();
    */

    NS::String* filePath = NS::String::string("triangle.metallib", NS::UTF8StringEncoding);
    NS::Error* error;
    metalDefaultLibrary = metalDevice->newLibrary(filePath, &error);
    if(error) {
        std::cerr << "Failed to load default library.\n";
        std::exit(-1);
    }
}

void MTLEngine::createCommandQueue() {
    metalCommandQueue = metalDevice->newCommandQueue();
}

void MTLEngine::createRenderPipeline() {
    // access Metal functions from the library
    MTL::Function* vertexShader = metalDefaultLibrary->newFunction(NS::String::string("vertexShader", NS::ASCIIStringEncoding));
    assert(vertexShader);
    MTL::Function* fragmentShader = metalDefaultLibrary->newFunction(NS::String::string("fragmentShader", NS::ASCIIStringEncoding));
    assert(fragmentShader);

    MTL::RenderPipelineDescriptor* renderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    renderPipelineDescriptor->setLabel(NS::String::string("Triangle Rendering Pipeline", NS::ASCIIStringEncoding));
    renderPipelineDescriptor->setVertexFunction(vertexShader);
    renderPipelineDescriptor->setFragmentFunction(fragmentShader);
    assert(renderPipelineDescriptor);

    // make pixel format match output render target
    MTL::PixelFormat pixelFormat = (MTL::PixelFormat)metalLayer.pixelFormat;
    // colorAttachments() is where final color info of each pixel stored
    renderPipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(pixelFormat);

    NS::Error* error;
    // state object can be used to render objects by encoding render commands into the
    // command buffer
    // created only once for each render pipeline
    metalRenderPSO = metalDevice->newRenderPipelineState(renderPipelineDescriptor, &error);
    renderPipelineDescriptor->release();
    vertexShader->release();
    fragmentShader->release();
}

// render pass: rendering commands that take input resources and processes them through
// graphics pipeline
// groups related rendering operations for optimization purposes
// create a command encoder to encode commands and provide resources to graphics pipeline
void MTLEngine::draw() {
    sendRenderCommand();
}

void MTLEngine::sendRenderCommand() {
    // create a command buffer
    metalCommandBuffer = metalCommandQueue->commandBuffer();

    MTL::RenderPassDescriptor* renderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
    // indicates what will store the data: metalDrawable
    MTL::RenderPassColorAttachmentDescriptor* cd = renderPassDescriptor->colorAttachments()->object(0);
    cd->setTexture(metalDrawable->texture());
    cd->setLoadAction(MTL::LoadActionClear);
    // cd->setClearColor(MTL::ClearColor(41.0f/255.0f, 42.0f/255.0f, 48.0f/255.0f, 1.0f));
    cd->setClearColor(MTL::ClearColor(0.0f,0.0f,0.0f,1.0f));
    // tell it to store the data into metalDrawable
    cd->setStoreAction(MTL::StoreActionStore);

    MTL::RenderCommandEncoder* renderCommandEncoder = metalCommandBuffer->renderCommandEncoder(renderPassDescriptor);
    encodeRenderCommand(renderCommandEncoder);
    renderCommandEncoder->endEncoding();

    metalCommandBuffer->presentDrawable(metalDrawable);
    metalCommandBuffer->commit();
    metalCommandBuffer->waitUntilCompleted();

    renderPassDescriptor->release();
}

// tell command encoder to draw the triangle
void MTLEngine::encodeRenderCommand(MTL::RenderCommandEncoder* renderCommandEncoder) {
    renderCommandEncoder->setRenderPipelineState(metalRenderPSO);
    renderCommandEncoder->setVertexBuffer(triangleVertexBuffer, 0, 0);
    MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
    
    NS::UInteger vertexStart = 0;
    NS::UInteger vertexCount = 3;

    renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);
}
