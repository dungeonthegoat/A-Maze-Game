using Godot;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;

[GlobalClass]
public partial class PathfindingService : Node
{
    public class Cell
    {
        public Cell Prev;
        public Vector2I Position;
        public int Idx;

        public float FCost;
        public float HCost;
        public float GCost;

        public Cell(Vector2I newPos, float g, float h, Cell prevCell)
        {
            Position = newPos;
            Prev = prevCell;

            GCost = g;
            HCost = h;
            FCost = h + g;
        }
    }

    public class CellHeap
    {
        public List<Cell> Heap = new();
        public Dictionary<Vector2I, Cell> Map = new();

        public bool IsEmpty()
        {
            return Heap.Count == 0;
        }

        public void Insert(Cell cell)
        {
            Heap.Add(cell);
            cell.Idx = Heap.Count - 1;
            Map[cell.Position] = cell;
            ShiftUp(cell.Idx);
        }

        public Cell Pop()
        {
            if (IsEmpty()) return null;
            
            Cell root = Heap[0];
            Map.Remove(root.Position);
            
            Cell last = Heap[Heap.Count - 1];
            Heap.RemoveAt(Heap.Count - 1);
            if (Heap.Count > 0)
            {
                Heap[0] = last;
                last.Idx = 0;
                ShiftDown(0);
            }

            return root;
        }

        public void ShiftUp(int Idx)
        {
            while (Idx > 0)
            {
                int parI = (Idx - 1) / 2;

                float currF = Heap[Idx].FCost;
                float currH = Heap[Idx].HCost;
                float parF = Heap[parI].FCost;
                float parH = Heap[parI].HCost;

                if (currF < parF || (currF == parH && currH < parH))
                {
                    Swap(Idx, parI);
                    Idx = parI;
                }
                else break;
            }
        }

        public void ShiftDown(int Idx)
        {
            while (true)
            {
                int smallest = Idx;
                int left = 2 * Idx + 1;
                int right = left + 1;

                float smallF = Heap[smallest].FCost;
                float smallH = Heap[smallest].HCost;

                if (left < Heap.Count)
                {
                    float leftF = Heap[left].FCost;
                    if (leftF < smallF || (leftF == smallF && Heap[left].HCost < smallH))
                    {
                        smallest = left;
                        smallF = leftF;
                        smallH = Heap[left].HCost;
                    }
                }

                if (right < Heap.Count)
                {
                    float rightF = Heap[right].FCost;
                    if (rightF < smallF || (rightF == smallF && Heap[right].HCost < smallH))
                    {
                        smallest = right;
                        smallF = rightF;
                        smallH = Heap[right].HCost;
                    }
                }

                if (smallest != Idx)
                {
                    Swap(smallest, Idx);
                    Idx = smallest;
                }
                else break;
            }
        }

        private void Swap(int i1, int i2)
        {
            Cell temp = Heap[i1];
            Heap[i1] = Heap[i2];
            Heap[i2] = temp;
            Heap[i1].Idx = i1;
            Heap[i2].Idx = i2;
        }
    }

    private const int PenaltyWeight = 5;
    private const int MaxDepth = 1000000;

    public static List<Vector2I> Pathfind(Vector2I start, Vector2I goal, Dictionary<Vector2I, List<Vector2I>> neighborMap, float greediness, Dictionary<Vector2I, int> penaltyMap)
    {
        Cell startCell = new Cell(start, 0, Distance(start, goal), null);
        CellHeap openCells = new();
        openCells.Insert(startCell);
        HashSet<Vector2I> closedPositions = new();
        Cell current;

        // The closest cell is tracked to prevent the algorithm from searching too far
        Cell closestCell = startCell;
        int iterations = 0;

        while (!openCells.IsEmpty())
        {
            current = openCells.Pop();
            iterations++;

            if (current.HCost < closestCell.HCost) closestCell = current;

            if (current.Position == goal || iterations >= MaxDepth)
            {
                return ReconstructPath(current);
            }

            closedPositions.Add(current.Position);

            foreach (Vector2I neighborPos in neighborMap[current.Position])
            {
                if (closedPositions.Contains(neighborPos)) continue;

                int penalty = 0;
                if (penaltyMap.ContainsKey(neighborPos)) penalty = penaltyMap[neighborPos];

                float g = current.GCost + 1f + (penalty * PenaltyWeight);
                float h = (float)Distance(neighborPos, goal) * greediness;

                if (openCells.Map.ContainsKey(neighborPos))
                {
                    Cell existingCell = openCells.Map[neighborPos];
                    if (g < existingCell.GCost)
                    {
                        existingCell.GCost = g;
                        existingCell.FCost = g + h;
                        existingCell.Prev = current;
                        openCells.ShiftUp(existingCell.Idx);
                    }
                } else
                {
                    openCells.Insert(new Cell(neighborPos, g, h, current));
                }
            }
        }

        return [];
    }

    private static List<Vector2I> ReconstructPath(Cell cell)
    {
        List<Vector2I> path = new();
        Cell current = cell;

        while (current != null)
        {
            path.Add(current.Position);
            current = current.Prev;
        }

        path.Reverse();
        return path;
    }

    private static int Distance(Vector2I p1, Vector2I p2)
    {
        return System.Math.Abs(p1.X - p2.X) + System.Math.Abs(p1.Y - p2.Y);
    }
}
