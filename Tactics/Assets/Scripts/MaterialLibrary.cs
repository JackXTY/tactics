using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class MaterialLibrary
    {
        public readonly Material gaussianBlur;
        public readonly Material depthBlur;
        public readonly Material postFog;
        public readonly Material postRainDrop;

        public MaterialLibrary(AdditionalPostProcessData data)
        {
            gaussianBlur = Load(data.shaders.gaussianBlur);
            depthBlur = Load(data.shaders.depthBlur);
            postFog = Load(data.shaders.postFog);
            postRainDrop = Load(data.shaders.postRainDrop);
        }

        Material Load(Shader shader)
        {
            if (shader == null)
            {
                Debug.LogErrorFormat($"Missing shader. {GetType().DeclaringType.Name} render pass will not execute. Check for missing reference in the renderer resources.");
                return null;
            }
            else if (!shader.isSupported)
            {
                return null;
            }

            return CoreUtils.CreateEngineMaterial(shader);

        }
        internal void Cleanup()
        {
            CoreUtils.Destroy(gaussianBlur);
        }
    }
}