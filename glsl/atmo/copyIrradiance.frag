
layout(location = 0) out vec4 data;

layout(binding = 1) uniform AtmoCommonUniformBufferObjectFrag {
    float Rg;
    float Rt;
    float RL;
    float AVERAGE_GROUND_REFLECTANCE;

    vec4 betaRAndHR;
    vec4 betaMScaAndHM;
    vec4 betaMExAndmieG;

    int TRANSMITTANCE_W;
    int TRANSMITTANCE_H;
    int SKY_W;
    int SKY_H;
    int RES_R;
    int RES_MU;
    int RES_MU_S;
    int RES_NU;
} ubo;

layout(binding = 2) uniform sampler2D deltaESampler;
layout(binding = 3) uniform sampler2D otherIrradianceSampler;

void main() {
    vec2 uv = gl_FragCoord.xy / vec2(ubo.SKY_W, ubo.SKY_H);
    data = vec4(texture(deltaESampler, uv).xyz + texture(otherIrradianceSampler, uv).xyz, 1.0);
}