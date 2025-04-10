layout(location = 0) out vec4 data;

layout(location = 0) in vec3 outPositionWeight;
layout(location = 1) in vec3 outSelection;
layout(location = 2) in vec3 outHeightFlatAnimation;

void main()
{
    float value = 0.0;
    float inside = 0.0;

    if(outSelection.x > 0.5)
    {
        if(outPositionWeight.x > outPositionWeight.y && outPositionWeight.x > outPositionWeight.z)
        {
            value = 1.0 - abs(outPositionWeight.x - outPositionWeight.y);
            value = max(value, 1.0 - abs(outPositionWeight.x - outPositionWeight.z));
            inside = 1.0;
        }
    }

    if(outSelection.y > 0.5)
    {
        if(outPositionWeight.y > outPositionWeight.z && outPositionWeight.y > outPositionWeight.x)
        {
            value = max(value, 1.0 - abs(outPositionWeight.y - outPositionWeight.z));
            value = max(value, 1.0 - abs(outPositionWeight.y - outPositionWeight.x));
            inside = 1.0;
        }
    }

    if(outSelection.z > 0.5)
    {
        if(outPositionWeight.z > outPositionWeight.x && outPositionWeight.z > outPositionWeight.y)
        {
            value = max(value, 1.0 - abs(outPositionWeight.z - outPositionWeight.y));
            value = max(value, 1.0 - abs(outPositionWeight.z - outPositionWeight.x));
            inside = 1.0;
        }
    }

    
    float line = smoothstep(0.98, 0.99, value) * smoothstep(1.0, 0.99, value);

    /*float linesValue = 1.0 - min(min(outPositionWeight.x, outPositionWeight.y), outPositionWeight.z);
    float linesLine = smoothstep(0.99, 1.0, linesValue);
    line = max(line, linesLine);*/

    vec4 gradientColor = vec4(0.0,0.0,0.0,0.1);

    data = mix(gradientColor, vec4(1.0), line);
    data = mix(data,  vec4(0.5,0.5,0.5, 1.0), inside * 0.2) * inside;
}
