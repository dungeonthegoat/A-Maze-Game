using Godot;
using System;

public readonly struct Edge
{
    public readonly Vector2I From;
    public readonly Vector2I To;
    public readonly float Weight;

    public Edge(Vector2I from, Vector2I to, float weight)
    {
        From = from;
        To = to;
        Weight = weight;
    }
}
