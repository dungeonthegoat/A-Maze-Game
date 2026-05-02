using Godot;
using System;

public partial class Player : GridEntity
{
    [Export]
    public AudioStreamPlayer2D footstepsSounds { get; set; }

    public override void _UnhandledInput(InputEvent @event)
    {
        if (@event.IsActionPressed("left")) AttemptMove(Vector2I.Left);
        if (@event.IsActionPressed("right")) AttemptMove(Vector2I.Right);
        if (@event.IsActionPressed("down")) AttemptMove(Vector2I.Down);
        if (@event.IsActionPressed("up")) AttemptMove(Vector2I.Up);

        base._UnhandledInput(@event);
    }

    private void AttemptMove(Vector2I dir)
    {
        if (Game.Instance.IsGameOver) return;

        Vector2I nextGridPos = dir + GridPos;
        if (!Map.IsCellValid(nextGridPos)) return;

        GridPos = nextGridPos;
        Game.Instance.EmitSignal(Game.SignalName.PlayerMoved, GridPos);

        footstepsSounds.Play();
    }
}
