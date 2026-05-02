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
        DisplayEdges(edges);
        InitNeighbors(edges);
        SpawnPlayer(edges);
        SpawnEnemies(enemyCount, edges);
        SpawnKeys(keyCount, edges);
        SpawnLamps(lightCount, edges);
        GD.Print("Spawned everything");
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

    public void SpawnEnemies(int count, List<Edge> edges)
    {
        if (count == 0) return;

        int minDistFromPlayer = Math.Max(1, (int)(Resolution.Length() * 0.2));

        for (int _i = 0; _i < count; _i++)
        {
            Vector2I spawnPoint = Vector2I.Zero;
            int dist = 0;

            while (dist <= minDistFromPlayer)
            {
                spawnPoint = edges[GD.RandRange(1, edges.Count - 1)].From * 2 - GetTileOffset();
                dist = Distance(spawnPoint, _currentPlayer.GridPos);
            }

            Enemy enemy = (Enemy)EnemyScene.Instantiate();
            enemy.Map = this;
            GetTree().CurrentScene.AddChild(enemy);

            enemy.GridPos = spawnPoint;
            enemy.Position = MapToLocal(spawnPoint);
            enemy.TargetPlayer = _currentPlayer;

            _enemies.Add(enemy);
        }
    }

    private void SpawnPlayer(List<Edge> edges)
    {
        Player newPlayer = (Player)PlayerScene.Instantiate();
        newPlayer.Map = this;
        GetTree().CurrentScene.AddChild(newPlayer);

        newPlayer.GridPos = edges[0].From * 2 - GetTileOffset();
        newPlayer.Position = MapToLocal(newPlayer.GridPos);
        Camera.TargetPlayer = newPlayer;
        if (Camera.FollowPlayer)
        {
            Camera.Position = newPlayer.Position;
        }
    }

    private void SpawnKeys(int count, List<Edge> edges)
    {
        if (count == 0) return;

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

        for (int _i = 0; _i < count; _i++)
        {
            if (spawnPoints.Count == 0) return;

            int randIdx = GD.RandRange(0, spawnPoints.Count - 1);
            MapKey key = (MapKey)KeyScene.Instantiate();
            key.Position = MapToLocal(spawnPoints[randIdx] * 2 - GetTileOffset());
            GetTree().CurrentScene.AddChild(key);
        }
    }

    private void SpawnLamps(int count, List<Edge> edges)
    {
        if (count == 0) return;

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
                SetCell(new Vector2I(x, y), 0, Vector2I.Left);
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
}
