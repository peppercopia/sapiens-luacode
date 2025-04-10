layout(location = 0) out vec4 data;

layout(location = 0) in vec3 outPositionWeight;
layout(location = 1) in vec3 outClearMarker;
layout(location = 2) in vec3 outHeightFlatAnimation;

void main()
{
    float inside = 0.0;
    float value = 0.0;

    if(outClearMarker.x > 0.5)
    {
        if(outPositionWeight.x > outPositionWeight.y && outPositionWeight.x > outPositionWeight.z)
        {
            value = 1.0 - abs(outPositionWeight.x - outPositionWeight.y);
            value = max(value, 1.0 - abs(outPositionWeight.x - outPositionWeight.z));
            inside = 1.0;
        }
    }
    if(outClearMarker.y > 0.5)
    {
        if(outPositionWeight.y > outPositionWeight.z && outPositionWeight.y > outPositionWeight.x)
        {
            value = 1.0 - abs(outPositionWeight.y - outPositionWeight.z);
            value = max(value, 1.0 - abs(outPositionWeight.y - outPositionWeight.x));
            inside = 1.0;
        }
    }
    if(outClearMarker.z > 0.5)
    {
        if(outPositionWeight.z > outPositionWeight.x && outPositionWeight.z > outPositionWeight.y)
        {
            value = 1.0 - abs(outPositionWeight.z - outPositionWeight.y);
            value = max(value, 1.0 - abs(outPositionWeight.z - outPositionWeight.x));
            inside = 1.0;
        }
    }

    /*float yellowA = smoothstep(0.3,0.35, fract(outPositionWeight.x * 4.0)) * (1.0 - smoothstep(0.65,0.7, fract(outPositionWeight.x * 4.0)));
    float yellowB = smoothstep(0.3,0.35, fract(outPositionWeight.y * 4.0)) * (1.0 - smoothstep(0.65,0.7, fract(outPositionWeight.y * 4.0)));
    float yellowC = smoothstep(0.3,0.35, fract(outPositionWeight.z * 4.0)) * (1.0 - smoothstep(0.65,0.7, fract(outPositionWeight.z * 4.0)));*/

    //float yellowGradient = inside * smoothstep(0.3,0.35, fract(value * 2.0)) * (1.0 - smoothstep(0.65,0.7, fract(value * 2.0)));;//max(max(yellowA, yellowB), yellowC);

    float linesValue = 1.0 - min(min(outPositionWeight.x, outPositionWeight.y), outPositionWeight.z);
    float line = smoothstep(0.995, 1.0, linesValue);

    float fraction = 0.0;
    if(fract(outHeightFlatAnimation.x + 100.0) > 0.001)
    {
        fraction =  fract(abs(outHeightFlatAnimation.x + 100.0) * 2.0);
    }

    vec4 gradientColor = mix(vec4(0.0), vec4(0.2,0.2,0.2,0.2), smoothstep(0.323,0.343, fraction) * (1.0 - smoothstep(0.657, 0.677, fraction)));
    vec4 lineColor = vec4(1.0,1.0,1.0,1.0) * line * 0.3;
    vec4 yellowColor = vec4(0.2,0.2,0.4,0.2) * inside;

    vec4 combined = yellowColor * (1.0 - gradientColor.a) + gradientColor;
    combined = combined * (1.0 - lineColor.a) + lineColor;
    data = combined;
}
