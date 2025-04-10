layout(location = 0) out vec4 data;

layout(location = 0) in vec2 outAnimationAlpha;

void main()
{
    data = mix(vec4(0.02,0.02,0.02,1.0), vec4(0.07,0.07,0.07,1.0), outAnimationAlpha.y);
}
