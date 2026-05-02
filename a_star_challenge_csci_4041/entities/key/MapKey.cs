using Godot;
using System;

public partial class MapKey : Area2D
{
    private bool _collected = false;

    [Export]
    public AnimationPlayer AnimPlayer { get; set; }
    [Export]
    public Sprite2D OuterSprite { get; set; }
    [Export]
    public PointLight2D Light { get; set; }

    public override void _Ready()
    {
        base._Ready();
        AreaEntered += OnAreaEntered;

        OuterSprite.Modulate = Color.FromHsv(GD.Randf(), 1f, 1f);
        Light.Color = OuterSprite.Modulate;
    }

    private void OnAreaEntered(Area2D _area)
    {
        if (_collected) return;

        _collected = true;
        AnimPlayer.Play("collect");
        Game.Instance.EmitSignal(Game.SignalName.KeyCollected);
    }
}
