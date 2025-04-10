
#extension GL_EXT_multiview : enable

layout(binding = 0) uniform UniformBufferObject {
    mat4 mv_matrix[6];
    mat4 p_matrix;
    mat4 normal_matrix;
    mat4 shadow_matrices[4];
    mat4 waterDepthOrthoMatrix;
    vec4 camPos;
    vec4 sunPos;
    vec4 origin;
    vec4 translation;
    vec4 extraData;
} ubo;


layout(location = 0) in vec3 pos;
layout(location = 1) in vec2 uv;
layout(location = 2) in vec4 normal;
layout(location = 3) in vec4 tangent;
layout(location = 4) in uvec4 material;
layout(location = 5) in uvec4 materialB;

layout(location = 0) out vec3 outPos;
layout(location = 1) out vec4 outWorldPos;
layout(location = 2) out vec3 outWorldCamPos;
layout(location = 3) out vec3 outColor;
layout(location = 4) out vec4 outMaterialUV;
layout(location = 5) out vec3 outView;
layout(location = 6) out vec3 outNormal;
layout(location = 7) out vec3 outWorldViewVec;
layout(location = 8) out vec4 outShadowCoords[4];
layout(location = 12) out vec4 outInstanceExtraData;
layout(location = 13) out vec3 outColorB;
layout(location = 14) out vec2 outMaterialB;
layout(location = 15) out vec3 outTangent;

out gl_PerVertex {
    vec4 gl_Position;
};

void main(void)
{
    vec4 V = ubo.mv_matrix[gl_ViewIndex] * vec4(pos.xyz, 1.0);
    gl_Position = ubo.p_matrix * V;

    outInstanceExtraData = vec4(0.0,0.0,0.0,0.0);
    
    vec3 rotatedPosition = (ubo.normal_matrix * vec4(pos, 1.0)).xyz;
    
    outColor = material.xyz / 255.0;
    outColorB = materialB.xyz / 255.0;
    //outColor = outColor * outColor;
    //outColorB = outColorB * outColorB;
    if(material.w > 127)
    {
      outMaterialUV.xy = vec2((material.w - 128.0) / 127.0, 1.0);
    }
    else
    {
      outMaterialUV.xy = vec2(material.w / 127.0, 0.0);
    }
    if(materialB.w > 127)
    {
      outMaterialB = vec2((materialB.w - 128.0) / 127.0, 1.0);
    }
    else
    {
      outMaterialB = vec2(materialB.w / 127.0, 0.0);
    }

    outMaterialUV.zw = uv;

    outNormal = (ubo.normal_matrix * vec4(normal.xyz, 1.0)).xyz;
    outTangent = (ubo.normal_matrix * vec4(tangent.xyz, 1.0)).xyz;

    outView = ubo.camPos.xyz - ubo.translation.xyz - rotatedPosition;

    float baseNDotL = dot( outNormal, ubo.sunPos.xyz );

    outPos = rotatedPosition.xyz + ubo.translation.xyz;
    
    outWorldPos.xyz = (rotatedPosition.xyz + ubo.translation.xyz + ubo.origin.xyz) * 8.388608;
    outWorldCamPos = (ubo.camPos.xyz + ubo.origin.xyz) * 8.388608;
    outWorldViewVec = (outWorldPos.xyz - outWorldCamPos);

    vec4 waterDepth = ubo.waterDepthOrthoMatrix * vec4((rotatedPosition.xyz + ubo.translation.xyz), 1.0);
    outWorldPos.w = -waterDepth.z + ubo.origin.w;
    
    /*outShadowCoords[0] = shadow_matrices[0] * vec4(rotatedPosition + translation, 1.0);
    outShadowCoords[1] = shadow_matrices[1] * vec4(rotatedPosition + translation, 1.0);
    outShadowCoords[2] = shadow_matrices[2] * vec4(rotatedPosition + translation, 1.0);
    outShadowCoords[3] = shadow_matrices[3] * vec4(rotatedPosition + translation, 1.0);*/
    
}
