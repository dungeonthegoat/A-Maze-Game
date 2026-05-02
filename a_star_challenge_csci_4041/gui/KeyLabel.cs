using Godot;
using System;

[GlobalClass]
public partial class KeyLabel : Label
{
    private int _keyCount = 0;

    [Export]
    public AnimationPlayer KeyAnim { get; set; }

    public override void _Ready()
    {
        Game.Instance.KeysUpdated += OnKeysUpdated;
    }

    public override void _ExitTree()
    {
        if (Game.Instance != null)
        {
            Game.Instance.KeysUpdated -= OnKeysUpdated;
        }

        base._ExitTree();
    }


    private void OnKeysUpdated(int keys, int maxKeys)
    {
        Text = $"{keys}/{maxKeys}";

        if (keys > _keyCount) KeyAnim.Play("collect");

        _keyCount = keys;
    } 
}
