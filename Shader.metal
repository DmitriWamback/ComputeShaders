#include <metal_stdlib>
using namespace metal;

float fade(float t) {
    return t * t * t * (t * (t * 6 - 15) + 10);
}

float lerp(float t, float a, float b) {
    return a + t * (b - a);
}

float gradient(int hash, float x, float y, float z) {
    int h = hash & 15;
    float u = h < 8 ? x : y;
    float v = h < 4 ? y : h == 12 || h == 14 ? x : z;

    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
}

float noise(float x, float y, float z) {
    
    int p[512] = {
        151,160,137,91,90,105,
        131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,203,
        190,126,148,247,120,234,75,0,6,197,62,94,252,219,203,117,35,11,32,57,177,133,
        88,237,149,56,87,174,20,125,136,171,168,68,175,74,15,71,134,139,48,27,166,177,
        146,158,21,83,111,229,12,60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,
        54,65,25,63,161,111,216,80,73,209,76,132,187,208,89,18,169,200,196,135,130,116,
        188,159,86,164,100,109,198,173,186,223,64,52,217,226,250,124,123,5,202,38,147,
        118,126,255,182,185,212,207,206,59,227,147,16,58,17,182,189,28,142,223,183,170,
        213,119,248,152,222,4,154,163,70,221,153,101,155,167,43,172,119,129,222,39,253,
        19,98,108,110,189,113,224,232,178,185,112,104,218,246,97,228,
        251,134,242,193,238,210,144,12,191,179,162,241,181,151,145,25,249,14,29,107,
        49,192,214,131,181,199,106,57,184,84,204,176,115,121,150,145,127,24,150,254,
        138,236,205,93,222,114,167,229,224,172,243,141,128,195,178,166,215,161,156,180,
        151,160,137,91,90,105,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,
        8,99,37,240,21,10,203,190,126,148,247,120,234,75,0,6,197,62,94,252,219,203,
        117,35,11,32,57,177,133,88,237,149,56,87,174,20,125,136,171,168,68,175,74,15,
        71,134,139,48,27,166,177,146,158,21,83,111,229,12,60,211,133,230,220,105,92,41,
        55,46,245,40,244,102,143,54,65,25,63,161,111,216,80,73,209,76,132,187,208,
        89,18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,223,64,52,217,
        226,250,124,123,5,202,38,147,118,126,255,182,185,212,207,206,59,227,147,16,
        58,17,182,189,28,142,223,183,170,213,119,248,152,222,4,154,163,170,221,153,101,
        155,167,43,172,119,129,222,39,253,19,98,108,110,189,113,224,232,178,185,
        112,104,218,246,97,228,251,134,242,193,238,210,144,12,191,179,162,241,181,151,
        145,25,249,14,29,107,49,192,214,131,181,199,106,57,184,84,204,176,115,121,
        150,145,127,24,150,254,138,236,205,93,222,114,167,229,224,172,243,141,128,195,
        178,166,215,161,156,180
    };

    int x1 = (int)floor(x) & 255,
        y1 = (int)floor(y) & 255,
        z1 = (int)floor(z) & 255;

    x -= floor(x);
    y -= floor(y);
    z -= floor(z);

    float x2 = fade(x),
            y2 = fade(y),
            z2 = fade(z);

    int A = p[x1] + y1, AA = p[A] + z1, AB = p[A + 1] + z1,      // HASH COORDINATES OF
        B = p[x1 + 1] + y1, BA = p[B] + z1, BB = p[B + 1] + z1;      // THE 8 CUBE CORNERS,

    return lerp(z2, lerp(y2, lerp(x2, gradient(p[AA],     x,     y,     z),
                                        gradient(p[BA],     x - 1, y,     z)),
                                lerp(x2, gradient(p[AB],     x,     y - 1, z),
                                        gradient(p[BB],     x - 1, y - 1, z))),
                    lerp(y2, lerp(x2, gradient(p[AA + 1], x,     y,     z - 1),
                                        gradient(p[BA + 1], x - 1, y,     z - 1)),
                                lerp(x2, gradient(p[AB + 1], x,     y - 1, z - 1),
                                        gradient(p[BB + 1], x - 1, y - 1, z - 1))));
}

float noise_layer(float3 coordinate, int octaves, float freq, float ampl, float t) {
    
    float frequency = 1.0;
    float amplitude = 1.0;
    float result = 0;
    
    for (int i = 0; i < octaves; i++) {
        result += ((noise(coordinate.x * frequency + t, coordinate.y * frequency + t, coordinate.z * frequency + t) + 1) / 2) * amplitude;
        frequency *= freq;
        amplitude *= ampl;
    }
    
    return result > 1.1 ? result * 2 : 0.6 * result;
}


float4x4 eulerRotation(float3 rotation) {
    
    float xrad = rotation.x * 3.14159265 / 180;
    float yrad = rotation.y * 3.14159265 / 180;
    float zrad = rotation.z * 3.14159265 / 180;
    
    float4x4 xrot = float4x4(
                    float4(cos(xrad), -sin(xrad), 0, 0),
                    float4(sin(xrad),  cos(xrad), 0, 0),
                    float4(0,          0,         1, 0),
                    float4(0,          0,         0, 1));
    
    float4x4 yrot = float4x4(
                    float4( cos(yrad),  0, sin(yrad), 0),
                    float4( 0,          1, 0,         0),
                    float4(-sin(yrad),  0, cos(yrad), 0),
                    float4(0,           0,         0, 1));
    
    float4x4 zrot = float4x4(
                    float4(1,  0,          0,         0),
                    float4(0,  cos(zrad), -sin(zrad), 0),
                    float4(0,  sin(zrad),  cos(zrad), 0),
                    float4(0,          0,         0,  1));
    
    return xrot * yrot * zrot;
}



struct Uniforms {
    float3 col;
    float2 window_size;
    float time;
    float rotation;
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
        
        float noiseValue = noise_layer(surface_position_hit2, 40, 2, 0.6, 355 + uniforms.time);
        
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
