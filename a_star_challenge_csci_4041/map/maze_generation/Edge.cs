using Godot;
using System;

[GlobalClass]
public partial class Edge : RefCounted
{
    public Vector2I From;
    public Vector2I To;
    public float Weight;

    public Edge(Vector2I v1, Vector2I v2, float w)
    {
        From = v1;
        To = v2;
        Weight = w;
    }
}
