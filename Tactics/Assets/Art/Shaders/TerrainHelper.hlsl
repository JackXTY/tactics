float CheckDepthDiff(float3 posWS, out float2 newUV) {
    float4 posCS = TransformWorldToHClip(float4(posWS, 1));
    float4 screenPos = ComputeScreenPos(posCS) / posCS.w;
    newUV = screenPos.xy;
    return LinearEyeDepth(SampleSceneDepth(newUV), _ZBufferParams) - LinearEyeDepth(screenPos.z, _ZBufferParams);
}
