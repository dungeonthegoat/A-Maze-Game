using Godot;
using System;
using System.Collections.Generic;
using System.Data;

[GlobalClass]
public partial class Enemy : GridEntity
{
    private Line2D _pathLine;
    private int _currentStepCycle = 0; // The current cycle when using MoveInterval > 1
    private Timer _switchTimer = new();
    private Timer _moveTimer = new();

    [ExportGroup("Movement")]
    [Export]
    public bool IndependentMovement { get; set; } = false;

    [Export]
    public float MoveTickSec { get; set; } = 0.25f;

    [Export]
    public bool ShowPathLine { get; set; } = false;

    [Export]
    public int MoveInterval { get; set; } = 1;

    [Export]
    public float MoveProbability { get; set; } = 1f;

    [Export]
    public int MoveStepSize { get; set; } = 1;

    [Export]
    public bool SwitchMovement { get; set; } = false;

    [Export]
    public float MinSwitchDelaySec { get; set; } = 5f;    

    [Export]
    public float MaxSwitchDelaySec { get; set; } = 60f;

    [ExportGroup("Pathfinding")]
    [Export]
    public bool UseSmartPaths { get; set; } = false;
    [Export]
    public float HeuristicWeight { get; set; } = 1f;

    [ExportGroup("Nodes")]
    [Export]
    public AudioStreamPlayer2D FootstepsSound;

    [Export]
    public PackedScene PathLineScene { get; set; }

    public Player TargetPlayer;
    public List<Vector2I> CurrentPath = new();

    public override void _Ready()
    {
        base._Ready();

        Game.Instance.PlayerMoved += PlayerMoved;
        GridPos = Map.LocalToMap(Position);

        // Initialize the path line
        _pathLine = (Line2D)PathLineScene.Instantiate();
        _pathLine.SelfModulate = Color.FromHsv(GD.Randf(), 1f, 1f);
        _pathLine.Visible = ShowPathLine;
        GetTree().CurrentScene.AddChild(_pathLine);

        // Timer initializations
        _moveTimer.Autostart = true;
        _moveTimer.WaitTime = MoveTickSec;
        _moveTimer.OneShot = false;
        _moveTimer.Timeout += MoveTimeout;
        AddChild(_moveTimer);

        if (SwitchMovement)
        {
            _switchTimer.Autostart = true;
            _switchTimer.WaitTime = GetRandomDelayTime();
            _switchTimer.OneShot = true;
            _switchTimer.Timeout += SwitchTimeout;
            AddChild(_switchTimer);
        }
    }

    public override void _ExitTree()
    {
        if (Game.Instance != null)
        {
            Game.Instance.PlayerMoved -= PlayerMoved;
        }

        _pathLine.QueueFree();

        base._ExitTree();
    }


    private void Move()
    {
        if (GD.Randf() > MoveProbability || Game.Instance.IsGameOver) return;

        Dictionary<Vector2I, int> penaltyMap = new();
        if (UseSmartPaths) penaltyMap = Map.GetPenaltyMap(this);

        CurrentPath = PathfindingService.Pathfind(
            GridPos,
            TargetPlayer.GridPos,
            Map.NeighborMap,
            HeuristicWeight,
            penaltyMap
        );

        if (CurrentPath.Count <= MoveStepSize)
        {
            Game.Instance.EmitSignal(Game.SignalName.PlayerCaught);
            return;
        }

        GridPos = CurrentPath[MoveStepSize];
        UpdateLine();
        FootstepsSound.Play();

        if (TargetPlayer.GridPos == GridPos)
        {
            Game.Instance.EmitSignal(Game.SignalName.PlayerCaught);
            return;
        }
    }

    private void PlayerMoved(Vector2I _newPos)
    {
        if (TargetPlayer.GridPos == GridPos)
        {
            Game.Instance.EmitSignal(Game.SignalName.PlayerCaught);
            return;
        }

        if (IndependentMovement) return;

        _currentStepCycle = (_currentStepCycle + 1) % MoveInterval;
        if (_currentStepCycle > 0) return;
        Move();
    }

    private void SwitchTimeout()
    {
        IndependentMovement = !IndependentMovement;
        _switchTimer.Start(GetRandomDelayTime());
    }

    private void MoveTimeout()
    {
        if (!IndependentMovement) return;
        Move();
    }

    private void UpdateLine()
    {
        _pathLine.ClearPoints();
        for (int i = 0; i < CurrentPath.Count; i++)
        {
            _pathLine.AddPoint(Map.MapToLocal(CurrentPath[i]));
        }
    }

    private float GetRandomDelayTime()
    {
        return (float)GD.RandRange(MinSwitchDelaySec, MaxSwitchDelaySec);
    }
}
