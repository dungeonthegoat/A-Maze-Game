using Godot;
using System;

[GlobalClass]
public partial class PlayerCamera : Camera2D
{
    [Export]
    public bool FollowPlayer { get; set; } = false;

    [Export]
    public float Smoothing { get; set; } = 3f;

    public Player TargetPlayer;


    public override void _Process(double delta)
    {
        if (!FollowPlayer || TargetPlayer == null) return;

        Position = Position.Lerp(TargetPlayer.Position, 1f - MathF.Exp(-(float)delta * Smoothing));
    }
}
