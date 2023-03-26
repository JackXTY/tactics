/**
  * @file GetWayPoints.cs
  * @brief ��RoadArchitect���������·����ȡ·���
  * @details  
  * ��Unity�༭���������У�ѡ���Ӧ��road
  * ����inspector������Update road���ٵ������к�����
  * SaveJson()�����ݴ�Ϊjson�ļ�
  * SaveXml()�����ݴ�Ϊxml�ļ���ͬʱ����Щ��������ÿ����ʵ�ʵ�·���ű���һ��
  * ���������������Զ����ã���Ҫ���������ڰ�ť�ϻ������ð���ĳ������ִ��
  * ������Assets/StreamingAssets
  * @author ���꺽
  * @date 2023.3.26
  */


using GSD.Roads;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;
using System.Xml;
using UnityEngine;

public class GetWayPoints : MonoBehaviour
{
    public GameObject Spline;
    trackData WayPoints;
    string flie_name = "waypoints_race04";
    string path; //�ļ���·��
    // Start is called before the first frame update
    void Start()
    {
        //GSDRoad road = this.GetComponent<GSDRoad>();
        WayPoints = new trackData();
        //Path = Application.streamingAssetsPath + "/waypoints_race04.json";
    }

    public void SaveJson()
    {
        WayPoints = Spline.GetComponent<GSDSplineC>().WayPoints;
        path = Application.streamingAssetsPath + "/" + flie_name + ".json";
        if (!File.Exists(path))
        {
            File.Create(path);
        }
        string json = JsonUtility.ToJson(WayPoints, true);
        StartCoroutine(save_json_helper(json));
        
    }

    public void SaveXml()
    {
        //����
        Vector3 pos;
        Vector3 rot_euler;
        Quaternion rot;
        string scale = "(1.00,1,00,1,00)";

        WayPoints = Spline.GetComponent<GSDSplineC>().WayPoints;
        path = Application.streamingAssetsPath + "/" + flie_name + ".xml";
        //����xml�ĵ�
        XmlDocument xml = new XmlDocument();
        //�������ڵ�
        XmlElement root = xml.CreateElement("waypoints");
        int index = 0;
        int count = WayPoints.way_points_pos.Count;
        for(int i = 0; i < count; i = i+2)
        {
            //�������ڵ���ӽڵ�
            XmlElement waypoint_node = xml.CreateElement("waypoint");
            //���ø��ڵ���ӽڵ������
            waypoint_node.SetAttribute("index", index.ToString());
            index += 1;

            //��������ӽڵ㵽���ڵ���ӽڵ������
            XmlElement positon_node = xml.CreateElement("position");
            pos.x = Mathf.Round(WayPoints.way_points_pos[i].x * 100f) / 100f;
            pos.y = Mathf.Round(WayPoints.way_points_pos[i].y * 100f) / 100f;
            pos.z = Mathf.Round(WayPoints.way_points_pos[i].z * 100f) / 100f;
            positon_node.InnerText = pos.ToString();

            XmlElement rotation_node = xml.CreateElement("rotation");
            rot_euler.x = WayPoints.way_points_rot[i].x;
            rot_euler.y = WayPoints.way_points_rot[i].y;
            rot_euler.z = WayPoints.way_points_rot[i].z;
            rot = Quaternion.Euler(rot_euler);
            rot.w = Mathf.Round(rot.w * 100000f) / 100000f;
            rot.x = Mathf.Round(rot.x * 100000f) / 100000f;
            rot.y = Mathf.Round(rot.y * 100000f) / 100000f;
            rot.z = Mathf.Round(rot.z * 100000f) / 100000f;
            rotation_node.InnerText = rot.ToString();

            XmlElement scale_node = xml.CreateElement("scale");
            scale_node.InnerText = scale;

            //�ѽڵ�һ��һ��������xml�У�ע������֮����Ⱥ�˳����������XML�ļ���˳��
            waypoint_node.AppendChild(positon_node);
            waypoint_node.AppendChild(rotation_node);
            waypoint_node.AppendChild(scale_node);

            root.AppendChild(waypoint_node);
        }
        xml.AppendChild(root);
        xml.Save(path);
        Debug.Log("����ɹ�");
    }

    IEnumerator save_json_helper(string json)
    {
        yield return new WaitForSeconds(0.5f);
        
        File.WriteAllText(path, json);
        Debug.Log("����ɹ�");
    }
}