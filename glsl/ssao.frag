

layout(binding = 0) uniform UniformBufferObject {
	mat4 p_matrix;
	mat4 p_matrixInv;
	vec4 screenSize;
} ubo;

layout(binding = 1) uniform sampler2D depthMap;
layout(binding = 2) uniform sampler2D noiseMap;

layout(location = 0) out vec4 outColor;

layout(location = 0) in vec2 outPos;

const uint sampleCount = 5;
const uint noiseTexSize = 2048;
const uint screenPixelsPerRow = noiseTexSize / sampleCount;
const float xOffsetPerSample = 1.0 / sampleCount;

vec3 getViewPos(vec2 texCoord, float depth) {
    float z = depth;

    vec4 clipSpacePosition = vec4(texCoord.x * 2.0 - 1.0, texCoord.y * 2.0 - 1.0, z, 1.0);
    vec4 viewSpacePosition = ubo.p_matrixInv * clipSpacePosition;

    viewSpacePosition /= viewSpacePosition.w;

    //vec4 worldSpacePosition = viewMatrixInv * viewSpacePosition;

    return viewSpacePosition.xyz;
}

vec2 getDepthPos(vec3 viewPos) {
    vec4 clipSpacePosition = ubo.p_matrix * vec4(viewPos, 1.0);
    clipSpacePosition.xyz = clipSpacePosition.xyz / clipSpacePosition.w;
    return vec2((clipSpacePosition.x + 1.0) * 0.5, (clipSpacePosition.y + 1.0) * 0.5);
}

vec2 getOffsetFragPos(vec2 pixelOffset)
{
    return outPos + pixelOffset / vec2(ubo.screenSize.x, ubo.screenSize.y);
}

float getOcclusion(vec2 sampleStartTexCoord, int sampleIndex, vec3 viewPos, vec3 normal, float baseDepth)
{
    vec2 noiseTexPos = sampleStartTexCoord + vec2(xOffsetPerSample * sampleIndex, 0.0);
    vec3 noiseValue = texture(noiseMap, noiseTexPos).rgb * 2.0 - vec3(1.0);
    if(dot(noiseValue, normal) > 0.0)
    {
        noiseValue = -noiseValue;
    }

    noiseValue = (-normal * 0.1 + noiseValue);

    vec3 offsetPos = viewPos + noiseValue * (0.01 + 0.01 * -viewPos.z) * 0.5;

    vec2 depthLookup = getDepthPos(offsetPos);
    float depth = texture(depthMap, depthLookup).r;

    vec3 lookUpViewPos = getViewPos(depthLookup, depth);


    float rangeCheck = smoothstep(0.0, 1.0, (0.001 + 0.01 * -viewPos.z) / abs(viewPos.z - lookUpViewPos.z));
   // float rangeCheck = smoothstep(0.0, 1.0, 0.002 / abs(viewPos.z - lookUpViewPos.z));

    //float maxDepth = max(depth, baseDepth);
    //rangeCheck = rangeCheck * smoothstep(0.0,1.0,maxDepth * 10000.0);

    return xOffsetPerSample * rangeCheck * clamp((lookUpViewPos.z - offsetPos.z - 0.00001) * 10000000.0, 0.0, 1.0);// * min(1.0 + 0.1 * -viewPos.z, 2.0);
}


void main() {

    float depth = texture(depthMap, outPos).r;
    vec3 viewPos = getViewPos(outPos, depth);

    vec2 offsetRight = getOffsetFragPos(vec2(1.0,0.0));
    vec2 offsetLeft = getOffsetFragPos(vec2(-1.0,0.0));
    vec2 offsetUp = getOffsetFragPos(vec2(0.0,1.0));
    vec2 offsetDown = getOffsetFragPos(vec2(0.0,-1.0));

    float depthRight = texture(depthMap, offsetRight).r;
    float depthLeft = texture(depthMap, offsetLeft).r;
    float depthUp = texture(depthMap, offsetUp).r;
    float depthDown = texture(depthMap, offsetDown).r;

    vec3 xCross;
    vec3 yCross;

    if(abs(depthRight - depth) > abs(depthLeft - depth))
    {
        vec3 posLeft = getViewPos(offsetLeft, depthLeft);
        xCross = viewPos - posLeft;
    }
    else
    {
        vec3 posRight = getViewPos(offsetRight, depthRight);
        xCross = posRight - viewPos;
    }
    
    if(abs(depthUp - depth) > abs(depthDown - depth))
    {
        vec3 posDown = getViewPos(offsetDown, depthDown);
        yCross = viewPos - posDown;
    }
    else
    {
        vec3 posUp = getViewPos(offsetUp, depthUp);
        yCross = posUp - viewPos;
    }

    vec3 normal = normalize(cross(xCross, yCross));// + vec3(depthRight - depth, depthUp - depth, 0.0);

    ivec2 outputScreenPixel = ivec2(outPos * ubo.screenSize.xy);
    int screenPixelIndex = outputScreenPixel.y * int(ubo.screenSize.x) + outputScreenPixel.x;

    ivec2 sampleStartTexIndex = ivec2((screenPixelIndex % screenPixelsPerRow), (screenPixelIndex / screenPixelsPerRow));
    vec2 sampleStartTexCoord = vec2(sampleStartTexIndex) / noiseTexSize;

    float occlusion = 0.0;
    for(int sampleIndex = 0; sampleIndex < sampleCount; sampleIndex++)
    {
        occlusion += getOcclusion(sampleStartTexCoord, sampleIndex, viewPos, normal, depth);
    }


    //outColor = vec4(normal.x * 0.5 + 0.5, normal.y * 0.5 + 0.5, -normal.z * 0.5 + 0.5, 1.0);

    //outColor = vec4(vec3(1.0 - pow(occlusion, 1.5) * 2.5), 1.0);
    //float strength = 2.9;//original
    //float strength = 20.0; //max
    outColor = vec4(vec3(max(1.0 - occlusion, 0.0)), 1.0);
}