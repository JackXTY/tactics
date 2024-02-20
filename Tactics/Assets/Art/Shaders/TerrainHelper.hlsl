// return difference of depth between zBuffer & actual distance of point
float CheckDepthDiff(float3 posWS, out float2 newUV) {
    float4 posCS = TransformWorldToHClip(float4(posWS, 1));
    float4 screenPos = ComputeScreenPos(posCS) / posCS.w;
    newUV = screenPos.xy;
    return LinearEyeDepth(SampleSceneDepth(newUV), _ZBufferParams) - LinearEyeDepth(screenPos.z, _ZBufferParams);
}

float2 getWorldPosUV(float3 posWS) {
    float4 posCS = TransformWorldToHClip(float4(posWS, 1));
    return ComputeScreenPos(posCS).xy / posCS.w;
}

bool checkUV01(float2 uv) {
    return !(uv.x < 0.0f || uv.x > 1.0f || uv.y < 0.0f || uv.y > 1.0f);
}