using UnityEngine;
using System.Collections;
using System;
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.ProjectWindowCallback;
#endif
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    [Serializable]
    public class AdditionalPostProcessData : ScriptableObject
    {

#if UNITY_EDITOR
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Performance", "CA1812")]

        [MenuItem("Assets/Create/Rendering/Universal Render Pipeline/Additional Post-process Data", priority = CoreUtils.Priorities.assetsCreateShaderMenuPriority + 1)]
        static void CreateAdditionalPostProcessData()
        {
            //ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0, CreateInstance<CreatePostProcessDataAsset>(), "CustomPostProcessData.asset", null, null);
            var instance = CreateInstance<AdditionalPostProcessData>();
            AssetDatabase.CreateAsset(instance, string.Format("Assets/Settings/{0}.asset", typeof(AdditionalPostProcessData).Name));
            Selection.activeObject = instance;
        }
#endif
        [Serializable]
        public sealed class Shaders
        {
            public Shader postFog;
            public Shader depthBlur;
            public Shader postRainDrop;
            public Shader gaussianBlur;
        }
        public Shaders shaders;
    }
}