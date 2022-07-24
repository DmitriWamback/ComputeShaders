#include <metal_stdlib>
using namespace metal;

#include "Utils/Noise.metal"
#include "Utils/Structures.metal"
#include "Utils/Matrix.metal"

vertex vertex_out vertexMain(const device vertex_in* vArray [[buffer(0)]],
                             constant Uniforms &uniforms [[buffer(1)]],
                             unsigned int vertexid [[vertex_id]]) {
    
    vertex_in i = vArray[vertexid];
    
    vertex_out o;
    o.fragp = float4(i._vertex, 1.0);
    o.col = float4(uniforms.col * (sin(uniforms.time) + 1)/2, 1.0);
    o.uv = (i._vertex.xy + float2(1)) / float2(2);
    o.time = uniforms.time;
    return o;
}

kernel void compute(texture2d<half, access::read_write> texture [[texture(0)]],
                    constant Uniforms &uniforms [[buffer(1)]],
                    uint2 index [[thread_position_in_grid]]) {
    
    float2 uv = float2((index.x / uniforms.window_size.x) - 0.5, index.y / uniforms.window_size.y - 0.5);
    float3 position = float3(0.0, 0.0, 0.0);
    float3 rayOrigin = float3(0.0, 0.0, -2.0) + position;
    float3 rayDirection = float3(uv.x, uv.y, -1.0);
    float radius = 0.5;
    float a = dot(rayDirection, rayDirection);
    float b = 2 * dot(rayOrigin, rayDirection);
    float c = dot(rayOrigin, rayOrigin) - pow(radius, 2);
    float discriminant = pow(b, 2) - (4 * a * c);
    
    if (discriminant >= 0) {
        
        float t1 = (-b + sqrt(discriminant)) / (2 * a);
        float t2 = (-b - sqrt(discriminant)) / (2 * a);
        
        float3 hit1 = rayOrigin + rayDirection * t1;
        float3 hit2 = rayOrigin + rayDirection * t2;
        float3 normal2 = normalize(hit2 - position);
        
        float3 surface_position_hit2 = (eulerRotation(float3(12, uniforms.rotation, 0)) * float4(hit2, 1.0)).xyz;
        
        float3 lightPosition = float3(0, 3, 10);
        float3 direction = normalize(lightPosition - normal2);
        float diff = max(dot(hit2, direction), 0.0);
        float3 color = float3(0.5, 0.7, 0.8);
        float3 ambient = color * 0.05;
        
        float3 viewDirection = normalize(float3(0) - normal2);
        float3 reflection = reflect(-direction, hit2);
        float spec = pow(max(dot(viewDirection, reflection), 0.0), 32);
        
        float noiseValue = noise_layer(surface_position_hit2, 40, 2, 0.6, 0 + uniforms.noise_time);
        
        // albedo
        color = (color * (diff + float3(spec)) + (diff + float3(spec)) * float3(0.7, 0.9, 0.6) * 2 + ambient) * noiseValue;
        
        // hdr + gamma correction
        float exposure = 1.0;
        float3 mapped = float3(1.0) - exp(-color * exposure);
        mapped = pow(mapped, float3(1.0 / 1.1));
        
        texture.write(half4(half3(mapped), 1.0), index);
    }
    else texture.write(half4(0.0, 0.0, 0.0, 1.0), index);
}

fragment float4 fragmentMain(vertex_out i [[stage_in]], texture2d<float> texture [[texture(0)]]) {
    
    constexpr sampler sample(coord::normalized, address::clamp_to_zero, filter::nearest);
    float4 fragc = texture.sample(sample, float2(i.uv.x, 1 - i.uv.y));
    
    return fragc;
    //return float4(1.0 * (((sin(i.time) + 1) / 2) + 1) / 2, 0.0, 0.0, 1.0);
}
