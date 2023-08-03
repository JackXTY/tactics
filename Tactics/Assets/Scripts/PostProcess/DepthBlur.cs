using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System;


namespace UnityEngine.Experiemntal.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("My-post-processing/DepthBlur")]
    public class DepthBlur : VolumeComponent, IPostProcessComponent
    {
        [Range(0, 20)]
        public FloatParameter focusDistance = new FloatParameter(10.0f);
        [Range(0, 20)]
        public FloatParameter focusRange = new FloatParameter(5.0f);
        [Range(0, 20)]
        public FloatParameter radiusSparse = new FloatParameter(0f);
        [Range(0, 20)]
        public FloatParameter simpleBlurRange = new FloatParameter(1.0f);
        [Range(0, 1)]
        public FloatParameter cocEdge = new FloatParameter(0.1f);
        [Range(0, 1)]
        public FloatParameter foregroundScale = new FloatParameter(1.0f);
        public bool IsActive()
        {
            return active && radiusSparse.value > 0;
        }

        public bool IsTileCompatible()
        {
            return false;
        }
    }
}
