using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;


[CustomEditor(typeof(WeatherManager))]
public class WeatherManagerEditor : Editor
{
    private WeatherManager instance;
    private void OnEnable()
    {
        instance = target as WeatherManager;
    }

    // Update is called once per frame
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        GUILayout.Space(30);
        if (GUILayout.Button("UpdateMaterial", GUILayout.Height(30)))
        {
            instance.InitMat();
        }
    }
}
