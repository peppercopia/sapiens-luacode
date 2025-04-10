

layout(binding = 1) uniform sampler2D decalTexMap;

layout(location = 0) in vec4 outTex;

void main()
{
    vec4 tex = texture(decalTexMap, outTex.xy);
    if(tex.r < 0.7)
    {
        discard;
    }
}
