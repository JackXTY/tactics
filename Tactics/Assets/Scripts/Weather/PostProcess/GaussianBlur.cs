using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    [Serializable]
    public sealed class GaussianFilerModeParameter : VolumeParameter<FilterMode> {
        public GaussianFilerModeParameter(FilterMode value, bool overrideState = false):
            base(value, overrideState) { } 
    }

    [Serializable, VolumeComponentMenu("My-post-processing/GaussianBlur")]
    public class GaussianBlur : VolumeComponent, IPostProcessComponent
    {
        public GaussianFilerModeParameter filterMode = new GaussianFilerModeParameter(FilterMode.Bilinear);

        [Range(0, 3.0f)]
        public FloatParameter blurSpread = new FloatParameter(0.6f);

        [Range(1, 4)]
        public IntParameter iterations = new IntParameter(0);

        [Range(1, 8)]
        public IntParameter downSample = new IntParameter(2);

        public bool IsActive()
        {
            return active && iterations.value != 0;
        }

        public bool IsTileCompatible()
        {
            return false;
        }
    }
}