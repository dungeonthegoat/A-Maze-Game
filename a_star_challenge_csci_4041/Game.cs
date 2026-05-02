using Godot;
using System;

[GlobalClass]
public partial class Game : Node
{
    public static Game Instance { get; private set; }

    [Signal]
    public delegate void KeyCollectedEventHandler();

    [Signal]
    public delegate void KeysUpdatedEventHandler(int keys, int maxKeys);

    [Signal]
    public delegate void PlayerMovedEventHandler(Vector2I newGridPos);

    [Signal]
    public delegate void PlayerCaughtEventHandler();

    /// <summary>
    /// The signal when the game ends
    /// </summary>
    /// <param name="state">The state representing the condition of the game ending; 0 = loss, 1 = win</param>
    [Signal]
    public delegate void GameEndedEventHandler(int state);

    [Signal]
    public delegate void GameStartedEventHandler();

    public bool IsGameOver = false;

    public override void _EnterTree()
    {
        Instance = this;

    }

    public override void _Ready()
    {
        GameEnded += OnGameEnded;
        GameStarted += OnGameStarted;
    }

    private void OnGameEnded(int _state) => IsGameOver = true;
    private void OnGameStarted() => IsGameOver = false;

}
