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
    float2 window_size;
    float time;
};

struct vertex_in {
    packed_float3 _vertex;
};

struct vertex_out {
    float4 fragp [[position]];
    float4 col;
    float2 uv;
    float time;
};

vertex vertex_out vertexMain(const device vertex_in* vArray [[buffer(0)]],
                             constant Uniforms &uniforms [[buffer(1)]],
                             unsigned int vertexid [[vertex_id]]) {
    
    vertex_in i = vArray[vertexid];
    
    vertex_out o;
    o.fragp = float4(i._vertex, 1.0);
    o.col = float4(uniforms.col * (sin(uniforms.time) + 1)/2, 1.0);
    o.uv = float2(i._vertex.xy + float2(1)) / float2(2);
    o.time = uniforms.time;
    return o;
}

kernel void compute(texture2d<half, access::read_write> texture [[texture(0)]],
                    constant Uniforms &uniforms [[buffer(1)]],
                    uint index [[thread_position_in_grid]]) {
    
    for (int x = 0; x < uniforms.window_size.x; x++) {
        for (int y = 0; y < uniforms.window_size.y; x++) {
            texture.write(half4(1.0, 0.0, 0.0, 1.0), ushort2(x, y));
        }
    }
    
}

fragment float4 fragmentMain(vertex_out i [[stage_in]], texture2d<float> texture [[texture(0)]]) {
    
    constexpr sampler sample(coord::normalized, address::clamp_to_zero, filter::nearest);
    //return texture.sample(sample, i.uv);
    return float4(1.0 * (sin(i.time) + 1) / 2, 0.0, 0.0, 1.0);
}
