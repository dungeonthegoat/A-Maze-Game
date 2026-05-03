using Godot;
using System;

public partial class FpsLabel : Label
{
    public override void _Process(double delta)
    {
        base._Process(delta);

        Text = $"{Engine.GetFramesPerSecond()} FPS";
    }

}
