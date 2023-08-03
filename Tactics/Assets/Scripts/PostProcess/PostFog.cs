using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System;


namespace UnityEngine.Experiemntal.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("My-post-processing/PostFog")]
    public class PostFog : VolumeComponent, IPostProcessComponent
    {
		[Range(0.1f, 3.0f)]
		public FloatParameter fogDensity = new FloatParameter(0);

		public ColorParameter fogColor = new ColorParameter(Color.white);

		public FloatParameter fogHeightStart = new FloatParameter(0.0f);
		public FloatParameter fogHeightEnd = new FloatParameter(10.0f);
		public FloatParameter fogDepthNear = new FloatParameter(0.0f);
		public FloatParameter fogDepthFar = new FloatParameter(100.0f);

		public TextureParameter noiseTexture = new TextureParameter(null);

		[Range(-0.5f, 0.5f)]
		public FloatParameter fogXSpeed = new FloatParameter(0.1f);

		[Range(-0.5f, 0.5f)]
		public FloatParameter fogYSpeed = new FloatParameter(0.1f);

		[Range(0.0f, 3.0f)]
		public FloatParameter noiseAmount = new FloatParameter(1.0f);

		// public Transform fogBoxTrans;
		public Vector3Parameter minCorner = new Vector3Parameter(new Vector3(-100.0f, -50.0f, -100.0f));
		public Vector3Parameter maxCorner = new Vector3Parameter(new Vector3(100.0f, 50.0f, 100.0f));

		public BoolParameter expFog = new BoolParameter(false);
		public bool IsActive()
        {
            return active && fogDensity.value > 0;
        }

        public bool IsTileCompatible()
        {
            return false;
        }
    }
}
