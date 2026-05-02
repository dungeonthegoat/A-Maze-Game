using Godot;
using System;
using System.Collections.Generic;

public partial class MinHeap : RefCounted
{
    /// <summary>
    /// A class that represents a vertex to be stored in a <c>MinHeap</c>.
    /// </summary>
    public class Vert
    {
        public Vector2I Position;
        public float Weight;
        public int Idx;

        public Vert(Vector2I pos, float w, int i = 0)
        {
            Position = pos;
            Weight = w;
            Idx = i;
        }
    }

    public List<Vert> Heap = new List<Vert>();
    public Dictionary<Vector2I, Vert> Map = new Dictionary<Vector2I, Vert>();

    public bool IsEmpty() => Heap.Count == 0;

    public void Insert(Vert vert)
    {
        Heap.Add(vert);
        vert.Idx = Heap.Count - 1;
        Map[vert.Position] = vert;
        ShiftUp(vert.Idx);
    }

    public Vert Pop()
    {
        if (IsEmpty()) return null;

        Vert root = Heap[0];
        Map.Remove(root.Position);

        Vert last = Heap[Heap.Count - 1];
        Heap.RemoveAt(Heap.Count - 1);
        if (!IsEmpty()) {
            Heap[0] = last;
            last.Idx = 0;
            ShiftDown(0);
        }
        return root;
    }

    /// <summary>
    /// Repeatedly shifts a <c>Vert</c> up the heap by swapping it with its parent.
    /// </summary>
    /// <param name="idx">The index in <c>Heap</c> where shifting upwards begins.</param>
    public void ShiftUp(int idx)
    {
        while (idx > 0)
        {
            int parentI = (idx - 1) / 2;
            if (Heap[idx].Weight < Heap[parentI].Weight)
            {
                Swap(idx, parentI);
                idx = parentI;
            }
            else break;
        }
    }

    /// <summary>
    /// Repeatedly shifts a <c>Vert</c> down the heap by swapping it with its children.
    /// </summary>
    /// <param name="idx">The index in <c>Heap</c> where shifting downwards begins.</param>
    public void ShiftDown(int idx)
    {
        int size = Heap.Count;

        while (true)
        {
            int smallest = idx;
            float smallestWeight = Heap[idx].Weight;

            int left = 2 * idx + 1;
            int right = 2 * idx + 2;

            if (left < size && Heap[left].Weight < smallestWeight)
            {
                smallest = left;
                smallestWeight = Heap[left].Weight;
            }
            if (right < size && Heap[right].Weight < smallestWeight)
            {
                smallest = right;
                smallestWeight = Heap[right].Weight;
            }

            if (smallest != idx)
            {
                Swap(idx, smallest);
                idx = smallest;
            }
            else break;
        }
    }

    private void Swap(int i1, int i2)
    {
        Vert temp = Heap[i1];
        Heap[i1] = Heap[i2];
        Heap[i2] = temp;

        Heap[i1].Idx = i1;
        Heap[i2].Idx = i2;
    }
}
