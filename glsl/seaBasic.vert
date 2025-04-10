
layout(binding = 0) uniform UniformBufferObject {
    mat4 mv_matrix;
    mat4 shadow_matrices[4];
    mat4 waveMatrix;
    vec4 camPos;
    vec4 sunPosAnimationTimer;
    vec4 origin;
} ubo;

layout(binding = 1) uniform cameraUniformBufferObject {
  mat4 proj;
  mat4 view;
  mat4 worldView;
  mat4 worldRotation;
	vec4 camOffsetPos;
	vec4 camOffsetPosWorld;
} camera;

layout(location = 0) in vec4 pos;

layout(location = 0) out vec4 outPos;
layout(location = 1) out vec3 outWorldPos;
layout(location = 2) out vec3 outWorldCamPos;
layout(location = 3) out vec3 outColor;
layout(location = 4) out vec2 outMaterial;
layout(location = 5) out vec3 outView;
layout(location = 6) out vec3 outNormal;
layout(location = 7) out vec3 outWorldViewVec;
layout(location = 8) out vec4 outShadowCoords[4];

layout(location = 12) out vec3 fLocalPos;
layout(location = 13) out vec3 outCamPos;

out gl_PerVertex {
    vec4 gl_Position;
};


#define WAVE_SCALE 0.03

float addWave(vec2 wavePosition2D, vec2 originOffset, float viewDistanceToUse, float waveLengthScale, float waveHeightScale, float animationTimerToUse, float inWave)
{
    float mixValueA = max(1.0 - clamp(viewDistanceToUse, 0.0, 1.0), 0.0);
    vec2 directionA = originOffset - wavePosition2D;
    float lengthA = length(directionA);
    float waveHeight = (cos(lengthA * waveLengthScale + animationTimerToUse) - 1.0) * waveHeightScale * mixValueA * WAVE_SCALE;
    return inWave + waveHeight;
}


void main()
{
    float animationTimer = ubo.sunPosAnimationTimer.w;
    vec2 wavePosition2D = (ubo.waveMatrix * vec4(pos.xyz, 1.0)).xz;

outCamPos = (camera.camOffsetPosWorld.xyz + ubo.camPos.xyz);
    outView = (camera.camOffsetPosWorld.xyz + ubo.camPos.xyz) - pos.xyz;

    float viewDistance = length(outView);
    
    float waveHeight = addWave(wavePosition2D, vec2(136.0, 13.7), viewDistance * 1.5, 75.0, 0.01, animationTimer * 2.0, 0.0);
    waveHeight = addWave(wavePosition2D, vec2(96.0, 53.7), viewDistance * 2.5, 35.0, 0.01, animationTimer * 1.5, waveHeight);

    vec3 offsetPos = pos.xyz + normalize(pos.xyz + ubo.origin.xyz) * waveHeight;
    gl_Position = camera.proj * camera.worldView * ubo.mv_matrix * vec4(offsetPos, 1.0);
 
    fLocalPos = pos.xyz;
    

    outPos = pos;


    outWorldPos = (pos.xyz + ubo.origin.xyz) * 8.388608;
    vec3 outViewNormal = outView / viewDistance;
    float viewAngle = dot(outViewNormal, normalize(outWorldPos));
    outPos.w = outPos.w / max(viewAngle, 0.001);
    if(outPos.w > 0.0)
    {
        outPos.w = pow(outPos.w, 0.5) * 2.0 - 0.5;
    }

    outColor = vec3(0.0, 0.02, 0.03);
    outMaterial = vec2(0.02, 0.0);
    //outMaterial = vec2(0.0, 0.0);
    outNormal = normalize(pos.xyz + ubo.origin.xyz);
    
    outWorldCamPos = (ubo.camPos.xyz + ubo.origin.xyz) * 8.388608;
    outWorldViewVec = (pos.xyz - ubo.camPos.xyz) * 8.388608;
    
    outShadowCoords[0] = ubo.shadow_matrices[0] * vec4(pos.xyz, 1.0);
    outShadowCoords[1] = ubo.shadow_matrices[1] * vec4(pos.xyz, 1.0);
    outShadowCoords[2] = ubo.shadow_matrices[2] * vec4(pos.xyz, 1.0);
    outShadowCoords[3] = ubo.shadow_matrices[3] * vec4(pos.xyz, 1.0);
}
