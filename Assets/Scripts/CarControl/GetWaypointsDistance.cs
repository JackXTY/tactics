/**
  * @file GetWaypointsDistance.cs
  * @brief Ѳ�߿�ʼʱ����������·����ľ��룬���ں�������
  * @details  
  * ���ظýű��Ķ���RaceArea �� dataProcessing \n
  * @author ���꺽
  * @date 2023-04-15
  */

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GetWaypointsDistance : MonoBehaviour
{
    /// ·��������ļ� <summary>
    /// </summary>
    public TextAsset waypointsData = null;
    /// ·���ר��XML���� <summary>
    /// </summary>
    private WaypointsXML _WaypointsXML = new WaypointsXML();
    /// ����·��� <summary>
    /// </summary>
    public List<WaypointsModel> WaypointsModelAll = new List<WaypointsModel>();
    public static float[] Waypoints_distance;
    void Start()
    {
        float dist_square;
        Vector3 WP1;
        Vector3 WP2;
        //��ȡ·�������
        _WaypointsXML.GetXmlData(WaypointsModelAll, null, waypointsData.text);
        int numWP = WaypointsModelAll.Count;
        Waypoints_distance = new float[numWP];
        for(int i = 0;i < numWP; i++)
        {
            WP1 = WaypointsModelAll[i].Position;
            if(i + 1 >= numWP)
                WP2 = WaypointsModelAll[0].Position;
            else
                WP2 = WaypointsModelAll[i+1].Position;
            dist_square = Mathf.Pow(WP1.x - WP2.x, 2) + Mathf.Pow(WP1.y - WP2.y, 2) + Mathf.Pow(WP1.z - WP2.z, 2);
            Waypoints_distance[i] = Mathf.Sqrt(dist_square);
        }
    }

}
