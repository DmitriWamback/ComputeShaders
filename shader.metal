//
//  Shader.metal
//  MetalComputeShader
//
//  Created by NewTest on 2022-07-22.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float3 col;
    float time;
};

struct vertex_in {
    packed_float3 _vertex;
};

struct vertex_out {
    float4 fragp [[position]];
    float4 col;
};

vertex vertex_out vertexMain(const device vertex_in* vArray [[buffer(0)]],
                             constant Uniforms &uniforms [[buffer(1)]],
                             unsigned int vertexid [[vertex_id]]) {
    
    vertex_out o;
    o.fragp = float4(vArray[vertexid]._vertex, 1.0);
    o.col = float4(uniforms.col * (sin(uniforms.time) + 1)/2, 1.0);
    return o;
}

kernel void compute(texture2d<half, access::read_write> texture [[texture(0)]]) {
    
}

fragment half4 fragmentMain(vertex_out i [[stage_in]]) {
    return half4(i.col);
}
