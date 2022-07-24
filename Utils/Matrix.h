#ifndef Matrix_h
#define Matrix_h

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

#endif /* Matrix_h */
