using Godot;
using System;
using System.Threading.Tasks;

public partial class GameManager : Node2D
{
    private int _keysCollected = 0;

    [Export]
    public int KeysRequired { get; set; } = 5;

    [Export]
    public int EnemyCount { get; set; } = 2;

    [Export]
    public int LampCount { get; set; } = 10;

    [Export]
    public Maze MazeParameters { get; set; }

    [Export]
    public int EnemySpawnsOnKeys { get; set; } = 0;

    [Export]
    public GameMap Map { get; set; }

    [Export]
    public AnimationPlayer GameEndAnimationPlayer { get; set; }


    public override void _Ready()
    {
        EmitSignal(Game.SignalName.KeysUpdated, _keysCollected, KeysRequired);
        Game.Instance.KeyCollected += KeyCollected;
        Game.Instance.PlayerCaught += GameLost;

        StartGame();
    }

    private void StartGame()
    {
        MazeParameters.GenerateMaze();
        Map.Resolution = MazeParameters.Size;
        Map.GenerateMaze(KeysRequired, LampCount, EnemyCount, MazeParameters.MazeEdges);

        EmitSignal(Game.SignalName.GameStarted);
    }

    private void KeyCollected()
    {
        _keysCollected++;
        if (_keysCollected >= KeysRequired) GameWon();

        if (EnemySpawnsOnKeys > 0 && _keysCollected < KeysRequired)
        {
            Map.SpawnEnemies(EnemySpawnsOnKeys, MazeParameters.MazeEdges);
        }

        Game.Instance.EmitSignal(Game.SignalName.KeysUpdated, _keysCollected, KeysRequired);
    }

    private void GameLost()
    {
        Game.Instance.EmitSignal(Game.SignalName.GameEnded, 0);
        GameEndAnimationPlayer.Play("jumpscare");
        QueueRestartGame();
    }

    private void GameWon()
    {
        Game.Instance.EmitSignal(Game.SignalName.GameEnded, 1);
        GameEndAnimationPlayer.Play("victory");
        QueueRestartGame();
    }

    private async Task QueueRestartGame()
    {
        await ToSignal(GetTree().CreateTimer(1f), SceneTreeTimer.SignalName.Timeout);
        GetTree().ReloadCurrentScene();
    }
}
