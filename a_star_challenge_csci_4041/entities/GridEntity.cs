using Godot;
using System;
using System.Data;

[GlobalClass]
public partial class GridEntity : Node2D
{
    private Vector2I _gridPos; 
    private Vector2 _targetPos;

    [Export]
    public float Smoothing { get; set; } = 20f;

    public GameMap Map;
    public Vector2I GridPos
    {
        get => _gridPos;
        set
        {
            _gridPos = value;
            _targetPos = Map.MapToLocal(_gridPos);
        }
    }

    public override void _Ready()
    {
        GridPos = Map.LocalToMap(Position);
        base._Ready();
    }

    public override void _Process(double delta)
    {
        Position = Position.Lerp(_targetPos, 1f - (float)Mathf.Exp(-delta * Smoothing));
        base._Process(delta);
    }
}
