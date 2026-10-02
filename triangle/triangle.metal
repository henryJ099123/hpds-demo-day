#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float4 modelPos;
};

// vertex function, returns a vertex (all float4's)
// concurrent running on the GPU
// "constant" indicates address space attribute (read-only global memory)
vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                           constant simd::float3* vertexPositions [[buffer(0)]]) {
    float4 vertexOutPositions = float4(vertexPositions[vertexID][0],
                                       vertexPositions[vertexID][1],
                                       vertexPositions[vertexID][2],
                                       1.0f);
    return {.position= vertexOutPositions, .modelPos=vertexOutPositions};
}

fragment float4 fragmentShader(VertexOut vertexOutPositions [[stage_in]]) {
    // float3 color = float3(0.5f, 0.2f, 0.4f);
    float3 color = vertexOutPositions.modelPos.xyz + 0.5;
    return float4(color.rgb, 1.0);
    // return float4(182.0f/255.0f, 240.0f/255.0f, 228.0f/255.0f, 1.0f);
}
