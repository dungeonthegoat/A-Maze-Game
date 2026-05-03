using Godot;
using System;
using System.Collections.Generic;


public static class PathfindingService
{
    private const int PenaltyWeight = 5;
    private const int MaxDepth = 1000000;

    private const int MaxArraySize = 400000; // 300 x 300
    private static readonly PriorityQueue<Vector2I, float> _openSet = new();
    private static readonly float[] _gScores = new float[MaxArraySize];
    private static readonly int[] _cameFrom = new int[MaxArraySize];

    public static List<Vector2I> Pathfind(
        Vector2I start, 
        Vector2I goal, 
        Dictionary<Vector2I, List<Vector2I>> neighborMap, 
        float greediness, 
        Dictionary<Vector2I, int> penaltyMap,
        Vector2I resolution)
    {
        Array.Fill(_gScores, float.MaxValue);
        Array.Fill(_cameFrom, -1);
        _openSet.Clear();

        int totalWidth = resolution.X * 2;
        int offsetX = resolution.X;
        int offsetY = resolution.Y;

        int GetIndex(Vector2I pos) => (pos.Y + offsetY) * totalWidth + (pos.X + offsetX);

        int startIdx = GetIndex(start);
        _gScores[startIdx] = 0;
        _openSet.Enqueue(start, 0);

        // Keep track of the closest node for depth limiting
        Vector2I closestNode = start;
        float closestDist = Distance(start, goal);
        int iterations = 0;

        while (_openSet.Count > 0)
        {
            Vector2I current = _openSet.Dequeue();
            int currentIdx = GetIndex(current);
            iterations++;

            // Update the closest node/dist
            int currentDist = Distance(current, goal);
            if (currentDist < closestDist)
            {
                closestDist = currentDist;
                closestNode = current;
            }

            // If we reached the goal, return the path
            if (current == goal || iterations >= MaxDepth)
            {
                return ReconstructPath(current, totalWidth, offsetX, offsetY);
            }

            if (!neighborMap.TryGetValue(current, out List<Vector2I> neighbors)) continue;

            foreach (Vector2I neighbor in neighbors)
            {
                int neighborIdx = GetIndex(neighbor);

                penaltyMap.TryGetValue(neighbor, out int penalty);

                float g = _gScores[currentIdx] + 1f + (penalty * PenaltyWeight);

                if (g < _gScores[neighborIdx])
                {
                    _cameFrom[neighborIdx] = currentIdx;
                    _gScores[neighborIdx] = g;

                    float h = Distance(neighbor, goal) * greediness;
                    float f = g + h * 1.01f;

                    _openSet.Enqueue(neighbor, f);
                }
            }
        }

        return [];
    }

    /// <summary>
    /// Walks backwards from some node to try to reach the start again
    /// </summary>
    /// <param name="cell"></param>
    /// <returns></returns>
    private static List<Vector2I> ReconstructPath(Vector2I current, int totalWidth, int offsetX, int offsetY)
    {
        var path = new List<Vector2I> { current };

        int currentIdx = (current.Y + offsetY) * totalWidth + (current.X + offsetX);

        while (_cameFrom[currentIdx] != -1)
        {
            int parentIdx = _cameFrom[currentIdx];

            int parentY = (parentIdx / totalWidth) - offsetY;
            int parentX = (parentIdx % totalWidth) - offsetX;

            Vector2I parentPos = new(parentX, parentY);
            path.Add(parentPos);

            currentIdx = parentIdx;
        }

        path.Reverse();
        return path;
    }

    /// <summary>
    /// Calculates the taxicab distance between two points
    /// </summary>
    /// <param name="p1"></param>
    /// <param name="p2"></param>
    /// <returns></returns>
    private static int Distance(Vector2I p1, Vector2I p2)
    {
        return System.Math.Abs(p1.X - p2.X) + System.Math.Abs(p1.Y - p2.Y);
    }
}
