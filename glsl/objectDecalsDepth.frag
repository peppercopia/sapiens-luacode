

layout(binding = 2) uniform sampler2D decalTexMap;

layout(location = 0) in vec4 outView;
layout(location = 1) in vec3 outNormal;
layout(location = 2) in vec3 outTexCoord;

layout(location = 0) out vec4 data;

void main(void)
{
    float viewDepth = outView.w - 0.002;

    if(viewDepth > -0.002)
    {
        discard;
    }

    vec3 V = normalize(outView.xyz);
    float alpha = clamp((abs(dot(normalize(outNormal), V))), 0.0, 1.0);
    alpha = smoothstep(0.3,0.5,alpha);
    //alpha = smoothstep(0.8,0.4,alpha);
    if(alpha < 0.1)
    {
        discard;
    }

    //vec3 normalToUse = normalize(outNormal);

   // float nDotV = dot(V, normalToUse);

    vec4 tex = texture(decalTexMap, outTexCoord.xy);
    alpha = tex.r * alpha;//clamp(((1.0 - max(nDotV, 0.0))) * 1.5, 0.0, 1.0);
    
    if(alpha < 0.1)
    {
        discard;
    }

    data = vec4(0.5,0.5,0.5, alpha);
    
}
