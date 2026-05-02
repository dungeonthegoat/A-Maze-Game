using Godot;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;

[GlobalClass]
public partial class GameMap : TileMapLayer
{
    private List<Enemy> _enemies = new();
    private Player _currentPlayer;

    [Export]
    public PackedScene PlayerScene { get; set; }
    [Export]
    public PackedScene EnemyScene { get; set; }
    [Export]
    public PackedScene KeyScene { get; set; }
    [Export]
    public PackedScene LampScene { get; set; }
    [Export]
    public PlayerCamera Camera { get; set; }

    /// <summary>
    /// When enabled, you can reload the map by pressing space.
    /// </summary>
    [Export]
    public bool DebugMode = false;

    public Vector2I Resolution;

    public Dictionary<Vector2I, List<Vector2I>> NeighborMap = new();

    public override void _UnhandledInput(InputEvent @event)
    {
        if (!DebugMode) return;

        if (@event.IsActionPressed("debug_map"))
        {
            GetTree().ReloadCurrentScene();
        }

        base._UnhandledInput(@event);
    }

    public bool IsCellValid(Vector2I coords)
    {
        return GetCellAtlasCoords(coords) == Vector2I.Zero;
    }

    /// <summary>
    /// Generates a procedural maze, fills it with entities, and displays it.
    /// </summary>
    /// <param name="numKeys">The number of keys to generate.</param>
    /// <param name="lightCount">The number of lights to generate.</param>
    /// <param name="enemyCount">The number of enemies to spawn.</param>
    /// <param name="maze">The maze to display and generate things in.</param>
    public void GenerateMaze(int keyCount, int lightCount, int enemyCount, List<Edge> edges)
    {
        List<Vector2I> spawnPoints = GetSpawnPoints(edges);

        DisplayEdges(edges);
        InitNeighbors(edges);

        SpawnPlayer(spawnPoints);
        SpawnEnemies(enemyCount, spawnPoints);
        SpawnKeys(keyCount, spawnPoints);
        SpawnLamps(lightCount, spawnPoints);
    }

    public Dictionary<Vector2I, int> GetPenaltyMap(Enemy enemy)
    {
        Dictionary<Vector2I, int> penaltyMap = new();

        foreach (Enemy other in _enemies)
        {
            if (other == enemy) continue;

            foreach (Vector2I vertex in other.CurrentPath)
            {
                if (!penaltyMap.ContainsKey(vertex))
                {
                    penaltyMap[vertex] = 1;
                } else
                {
                    penaltyMap[vertex] += 1;
                }
            }
        }

        return penaltyMap;
    }

    public void SpawnEnemies(int count, List<Vector2I> spawnPoints)
    {
        if (count == 0) return;

        int minDistFromPlayer = Math.Max(1, (int)(Resolution.Length() * 0.2));

        for (int _i = 0; _i < count; _i++)
        {
            if (spawnPoints.Count == 0) return;

            int idx = 0;
            Vector2I spawnPoint = Vector2I.Zero;
            int dist = 0;

            while (dist <= minDistFromPlayer)
            {
                idx = GD.RandRange(1, spawnPoints.Count - 1);
                spawnPoint = spawnPoints[idx] * 2 - GetTileOffset();
                dist = Distance(spawnPoint, _currentPlayer.GridPos);
            }

            Enemy enemy = EnemyScene.Instantiate<Enemy>();
            enemy.Map = this;
            GetTree().CurrentScene.AddChild(enemy);

            enemy.GridPos = spawnPoint;
            enemy.Position = MapToLocal(spawnPoint);
            enemy.TargetPlayer = _currentPlayer;

            _enemies.Add(enemy);

            spawnPoints.RemoveAt(idx);
        }
    }

    private void SpawnPlayer(List<Vector2I> spawnPoints)
    {
        _currentPlayer = PlayerScene.Instantiate<Player>();
        _currentPlayer.Map = this;
        GetTree().CurrentScene.AddChild(_currentPlayer);

        _currentPlayer.GridPos = spawnPoints[0] * 2 - GetTileOffset();
        _currentPlayer.Position = MapToLocal(_currentPlayer.GridPos);
        Camera.TargetPlayer = _currentPlayer;
        if (Camera.FollowPlayer)
        {
            Camera.Position = _currentPlayer.Position;
        }

        spawnPoints.RemoveAt(0);
    }

    private void SpawnKeys(int count, List<Vector2I> spawnPoints)
    {
        if (count == 0) return;

        for (int _i = 0; _i < count; _i++)
        {
            if (spawnPoints.Count == 0) return;

            int randIdx = GD.RandRange(0, spawnPoints.Count - 1);

            MapKey key = KeyScene.Instantiate<MapKey>();
            key.Position = MapToLocal(spawnPoints[randIdx] * 2 - GetTileOffset());
            GetTree().CurrentScene.AddChild(key);

            spawnPoints.RemoveAt(randIdx);
        }
    }

    private void SpawnLamps(int count, List<Vector2I> spawnPoints)
    {
        if (count == 0) return;

        for (int _i = 0; _i < count; _i++)
        {
            if (spawnPoints.Count == 0) return;

            int randIdx = GD.RandRange(0, spawnPoints.Count - 1);
            Node2D lamp = (Node2D)LampScene.Instantiate();
            lamp.Position = MapToLocal(spawnPoints[randIdx] * 2 - GetTileOffset());
            GetTree().CurrentScene.AddChild(lamp);
        }
    }

    private void InitNeighbors(List<Edge> edges)
    {
        NeighborMap.Clear();

        foreach (Edge edge in edges)
        {
            Vector2I from = edge.From * 2 - GetTileOffset();
            Vector2I to = edge.To * 2 - GetTileOffset();
            Vector2I mid = (edge.To + edge.From) - GetTileOffset();

            if (!NeighborMap.ContainsKey(from)) NeighborMap[from] = [];
            NeighborMap[from].Add(mid);

            if (!NeighborMap.ContainsKey(to)) NeighborMap[to] = [];
            NeighborMap[to].Add(mid);

            if (!NeighborMap.ContainsKey(mid)) NeighborMap[mid] = [];
            NeighborMap[mid].Add(from);
            NeighborMap[mid].Add(to);
        }
    }

    /// <summary>
    /// Updates the tile map to display the current maze
    /// </summary>
    /// <param name="edges">The edges of the maze to display</param>
    private void DisplayEdges(List<Edge> edges)
    {
        Clear();

        // Fill the area with walls
        for (int x = -Resolution.X; x < Resolution.X; x++)
        {
            for (int y = -Resolution.Y; y < Resolution.Y; y++)
            {
                SetCell(new Vector2I(x, y), 0, Vector2I.Right);
            }
        }

        Vector2I offset = Resolution / 2 - Vector2I.One;

        // Display the edges as tiles
        foreach (Edge edge in edges)
        {
            SetCell(edge.From * 2 - offset, 0, Vector2I.Zero);
            SetCell(edge.To * 2 - offset, 0, Vector2I.Zero);
            SetCell((edge.From + edge.To) - offset, 0, Vector2I.Zero);
        }
    }

    private Vector2I GetTileOffset()
    {
        return Resolution / 2 - Vector2I.One;
    }

    private int Distance(Vector2I p1, Vector2I p2)
    {
        return Math.Abs(p1.X - p2.X) + Math.Abs(p1.Y - p2.Y);
    }

    public static List<Vector2I> GetSpawnPoints(List<Edge> edges)
    {
        List<Vector2I> spawnPoints = new();
        HashSet<Vector2I> usedSpawnPoints = new();
        foreach (Edge edge in edges)
        {
            if (!usedSpawnPoints.Contains(edge.From))
            {
                usedSpawnPoints.Add(edge.From);
                spawnPoints.Add(edge.From);
            }
            if (!usedSpawnPoints.Contains(edge.To))
            {
                usedSpawnPoints.Add(edge.To);
                spawnPoints.Add(edge.To);
            }
        }

        return spawnPoints;
    }
}
