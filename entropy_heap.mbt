///|
priv struct EntropyEntry {
  cell : Int
  version : Int
  priority : Double
}

///|
fn heap_push(heap : Array[EntropyEntry], entry : EntropyEntry) -> Unit {
  heap.push(entry)
  let mut i = heap.length() - 1
  while i > 0 {
    let parent = (i - 1) / 2
    if heap[parent].priority <= entry.priority {
      break
    }
    heap[i] = heap[parent]
    i = parent
  }
  heap[i] = entry
}

///|
fn heap_pop(heap : Array[EntropyEntry]) -> EntropyEntry? {
  if heap.is_empty() {
    return None
  }
  let result = heap[0]
  let last = heap.pop().unwrap()
  if !heap.is_empty() {
    let mut i = 0
    while 2 * i + 1 < heap.length() {
      let left = 2 * i + 1
      let right = left + 1
      let child = if right < heap.length() &&
        heap[right].priority < heap[left].priority {
        right
      } else {
        left
      }
      if last.priority <= heap[child].priority {
        break
      }
      heap[i] = heap[child]
      i = child
    }
    heap[i] = last
  }
  Some(result)
}
