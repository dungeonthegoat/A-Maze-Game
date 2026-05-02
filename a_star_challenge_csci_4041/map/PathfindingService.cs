using Godot;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Transactions;

[GlobalClass]
public partial class PathfindingService : Node
{
    private const int PenaltyWeight = 5;
    private const int MaxDepth = 1000000;

    public static List<Vector2I> Pathfind(Vector2I start, Vector2I goal, Dictionary<Vector2I, List<Vector2I>> neighborMap, float greediness, Dictionary<Vector2I, int> penaltyMap)
    {
        // Create a priority queue with the first cell in it
        var openSet = new PriorityQueue<Vector2I, float>();
        openSet.Enqueue(start, 0);

        // A dictionary of every node's g score
        var gScores = new Dictionary<Vector2I, float>();
        gScores[start] = 0;

        // A dictionary representing where each node came from
        var cameFrom = new Dictionary<Vector2I, Vector2I>();

        // Keep track of the closest node for depth limiting
        Vector2I closestNode = start;
        float closestDist = Distance(start, goal);

        int iterations = 0;

        while (openSet.Count > 0)
        {
            Vector2I current = openSet.Dequeue();
            iterations++;

            // Update the closest node/dist
            int currentDist = Distance(current, goal);
            if (currentDist < closestDist)
            {
                closestDist = currentDist;
                closestNode = current;
            }

            // If we reached the goal, return the path
            if (current == goal) return ReconstructPath(cameFrom, current);

            // If depth limit was exceeded, return the closest path
            if (iterations > MaxDepth) return ReconstructPath(cameFrom, closestNode);

            if (!neighborMap.ContainsKey(current)) continue;

            foreach (Vector2I neighbor in neighborMap[current])
            {
                int penalty = penaltyMap.ContainsKey(neighbor) ? penaltyMap[neighbor] : 0;
                float g = gScores[current] + 1f + (penalty * PenaltyWeight);

                if (!gScores.ContainsKey(neighbor) || g < gScores[neighbor])
                {
                    cameFrom[neighbor] = current;
                    gScores[neighbor] = g;

                    float f = g + Distance(neighbor, goal) * greediness;

                    openSet.Enqueue(neighbor, f);
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
    private static List<Vector2I> ReconstructPath(Dictionary<Vector2I, Vector2I> cameFrom, Vector2I node)
    {
        var path = new List<Vector2I> { node };

        while (cameFrom.ContainsKey(node))
        {
            node = cameFrom[node];
            path.Add(node);
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
