using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System;


namespace UnityEngine.Experiemntal.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("My-post-processing/PostRainDrop")]
    public class PostRainDrop : VolumeComponent, IPostProcessComponent
    {
        public FloatParameter gridNum = new FloatParameter(16.0f);
        [Range(0, 1)]
        public FloatParameter distortion = new FloatParameter(0.5f);
        public FloatParameter blur = new FloatParameter(1.0f);

        [Range(1, 7)]
        public IntParameter rainAmount = new IntParameter(0);
        [Range(0, 3)]
        public FloatParameter rainSpeed = new FloatParameter(0.25f);
        [Range(1, 8)]
        public IntParameter downSample = new IntParameter(2);
        public Vector3Parameter windForce = new Vector3Parameter(Vector3.zero);
        public BoolParameter fogScreen = new BoolParameter(true);
        public bool IsActive()
        {
            return active && rainAmount.value > 0;
        }

        public bool IsTileCompatible()
        {
            return false;
        }
    }
}
