using Godot;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Runtime.Versioning;


[GlobalClass]
public partial class Maze : Resource
{
    private const int MinSize = 5;

    // // The maze's preview image to be displayed in the editor
    // [Export] public ImageTexture Preview { get; set; }
    // The dimensions of the maze
    [Export] public Vector2I Size { get; set; } = new(16, 16);
    // A perfect maze is a maze that contains no loops
    [Export] public bool MakePerfect { get; set; } = false;
    [Export] public int MinLoopSize = 10;
    [Export] public float LoopCountScale = 0.1f;

    private List<Vector2I> _vertices = new();
    private List<Edge> _edges = new();
    public List<Edge> MazeEdges = new();

    public List<Edge> GenerateMaze()
    {
        if (Size.X < MinSize || Size.Y < MinSize)
        {
            GD.PushWarning($"Cannot generate maze; both size dimensions must be at least {MinSize}");
            return [];
        }

        var stopwatch = new Stopwatch();
        stopwatch.Start();

        MazeEdges.Clear();
        GenerateWeightedLattice();
        FindMinimumSpanningEdges();

        stopwatch.Stop();
        GD.Print($"Generated maze in {stopwatch.ElapsedMilliseconds} milliseconds");

        return [..MazeEdges];
    }

    /// <summary>
    /// Uses Prim's algorithm to find the minimum spanning tree on the lattice graph.
    /// </summary>
    private List<Edge> FindMinimumSpanningEdges()
    {
        var openSet = new PriorityQueue<Vector2I, float>();
        var cheapestEdge = new Dictionary<Vector2I, Edge>();

        // A hash set containing every vertex that has been explored
        var explored = new HashSet<Vector2I>();

        // The dictionary containing every vertex's connected edges
        var adjEdges = new Dictionary<Vector2I, List<Edge>>();

        // Each vertex should be initialized as:
            // 1. A cost of ∞
            // 2. No adjacent edges
        foreach (Vector2I vertex in _vertices)
        {
            adjEdges[vertex] = new List<Edge>();
        }

        // Set up the adjacent edges for each edge
        foreach (Edge edge in _edges)
        {
            adjEdges[edge.From].Add(edge);
            adjEdges[edge.To].Add(edge);
        }

        // Starting vertex can be arbitrary
        Vector2I startVertex = _vertices[GD.RandRange(0, _vertices.Count - 1)];
        openSet.Enqueue(startVertex, 0f);

        while (openSet.Count > 0)
        {
            Vector2I currentVert = openSet.Dequeue();

            if (explored.Contains(currentVert)) continue;
            explored.Add(currentVert);

            foreach (Edge edge in adjEdges[currentVert])
            {
                Vector2I neighbor = (edge.From == currentVert) ? edge.To : edge.From;
                
                if (explored.Contains(neighbor)) continue;

                // If the current edge is cheaper than the old one, replace it
                if (!cheapestEdge.ContainsKey(neighbor) || edge.Weight < cheapestEdge[neighbor].Weight)
                {
                    cheapestEdge[neighbor] = edge;
                    openSet.Enqueue(neighbor, edge.Weight);
                }
            }
        }

        MazeEdges = new List<Edge>();
        HashSet<Edge> usedEdges = new HashSet<Edge>();

        foreach (Edge edge in cheapestEdge.Values)
        {
            MazeEdges.Add(edge);
            usedEdges.Add(edge);
        }

        if (!MakePerfect)
        {
            AddLoops(usedEdges);
        }

        return MazeEdges;
    }

    /// <summary>
    /// Adds loops of some minimum size to a perfect maze using a breadth-first search.
    /// </summary>
    /// <param name="usedEdges">The edges which have been used to construct the maze.</param>
    private void AddLoops(HashSet<Edge> usedEdges)
    {
        Dictionary<Vector2I, List<Vector2I>> adjacentVertices = new Dictionary<Vector2I, List<Vector2I>>();
        foreach (Vector2I vertex in _vertices) adjacentVertices[vertex] = new List<Vector2I>();
        
        foreach (Edge edge in MazeEdges)
        {
            adjacentVertices[edge.From].Add(edge.To);
            adjacentVertices[edge.To].Add(edge.From);
        }

        List<Edge> unusedEdges = new List<Edge>();
        foreach (Edge edge in _edges)
        {
            if (!usedEdges.Contains(edge))
            {
                unusedEdges.Add(edge);
            }
        }
        // unusedEdges.Sort((a, b) => GD.Randf().CompareTo(0.5f));

        int targetLoopCount = System.Math.Max(1, (int)(_edges.Count * LoopCountScale));
        int loopCounter = 0;

        var searchQueue = new Queue<Vector2I>();
        var visited = new HashSet<Vector2I>();

        // Loop through each unused edge and perform a breadth-first search
        while (loopCounter < targetLoopCount && unusedEdges.Count > 0)
        {
            Edge currentEdge = unusedEdges[unusedEdges.Count - 1];
            unusedEdges.RemoveAt(unusedEdges.Count - 1);

            bool belowMinDist = false;
            int dist = 0;
            
            searchQueue.Clear();
            searchQueue.Enqueue(currentEdge.From);
            visited.Clear();

            while (searchQueue.Count > 0 && dist < MinLoopSize)
            {
                int levelSize = searchQueue.Count;
                for (int i = 0; i < levelSize; i++)
                {
                    Vector2I vertex = searchQueue.Dequeue();

                    if (vertex == currentEdge.To)
                    {
                        belowMinDist = true;
                        break;
                    }

                    foreach (Vector2I neighbor in adjacentVertices[vertex])
                    {
                        if (!visited.Contains(neighbor))
                        {
                            visited.Add(neighbor);
                            searchQueue.Enqueue(neighbor);
                        }
                    }
                }

                if (belowMinDist) break;
                dist++;
            }

            if (!belowMinDist)
            {
                loopCounter++;
                MazeEdges.Add(currentEdge);
                adjacentVertices[currentEdge.From].Add(currentEdge.To);
                adjacentVertices[currentEdge.To].Add(currentEdge.From);
            }
        }
    }

    /// <summary>
    /// Generates a weighted lattice graph with its size defined by <c>Size</c>.
    /// </summary>
    private void GenerateWeightedLattice()
    {
        // Clear everything before generating
        _vertices.Clear();
        _edges.Clear();

        // Scale the grid to account for the spacing of vertices
        Vector2I scaledResolution = (Size - Vector2I.One) / 2;
        Dictionary<Vector2I, bool> tempVerts = new Dictionary<Vector2I, bool>();

        for (int x = 0; x < scaledResolution.X; x++)
        {
            for (int y = 0; y < scaledResolution.Y; y++)
            {
                Vector2I currentPos = new Vector2I(x, y);
                tempVerts[currentPos] = true;
                _vertices.Add(currentPos);

                // Add the edges
                if (tempVerts.ContainsKey(currentPos + Vector2I.Left))
                {
                    _edges.Add(new Edge(currentPos, currentPos + Vector2I.Left, GD.Randf()));
                }
                if (tempVerts.ContainsKey(currentPos + Vector2I.Up))
                {
                    _edges.Add(new Edge(currentPos, currentPos + Vector2I.Up, GD.Randf()));
                }
            }
        }
    }
}