///|
priv struct WaveSearch {
  model : RuleModel
  width : Int
  height : Int
  periodic : Bool
  count : Int
  domains : FixedArray[Bool]
  supports : FixedArray[Int]
  sizes : FixedArray[Int]
  sums : FixedArray[Double]
  logs : FixedArray[Double]
  weight_logs : Array[Double]
  versions : FixedArray[Int]
  trail : Array[Int]
  processed : Array[Int]
  queue : Array[Int]
  heap : Array[EntropyEntry]
  mut budget : Int
  mut seed : UInt
  mut decisions : Int
  mut backtracks : Int
}

///|
priv struct Decision {
  cell : Int
  trail_mark : Int
  processed_mark : Int
  choices : Array[Int]
}

///|
fn WaveSearch::tick(self : WaveSearch) -> Unit raise SolveError {
  self.budget -= 1
  if self.budget < 0 {
    raise Invalid("search budget exhausted")
  }
}

///|
fn WaveSearch::random(self : WaveSearch) -> Double {
  let mut x = self.seed
  x = x ^ (x << 13)
  x = x ^ (x >> 17)
  x = x ^ (x << 5)
  self.seed = x
  x.to_double() / 4294967296.0
}

///|
fn WaveSearch::enqueue_entropy(self : WaveSearch, cell : Int) -> Unit {
  self.versions[cell] += 1
  if self.sizes[cell] > 1 {
    let sum = self.sums[cell]
    let entropy = @math.ln(sum) - self.logs[cell] / sum
    heap_push(self.heap, {
      cell,
      version: self.versions[cell],
      priority: entropy + self.random() * 1.0e-9,
    })
  }
}

///|
fn WaveSearch::ban(
  self : WaveSearch,
  cell : Int,
  tile : Int,
) -> Unit raise SolveError {
  let index = cell * self.count + tile
  if !self.domains[index] {
    return
  }
  self.tick()
  self.domains[index] = false
  self.sizes[cell] -= 1
  self.sums[cell] -= self.model.weights[tile]
  self.logs[cell] -= self.weight_logs[tile]
  // Removing a dominant weight can erase tiny remaining weights by rounding.
  // Rebuild the two sums before computing entropy in that case.
  if self.sizes[cell] > 1 &&
    self.sums[cell] <= self.model.weights[tile] * 1.0e-8 {
    self.sums[cell] = 0.0
    self.logs[cell] = 0.0
    for other in 0..<self.count {
      self.tick()
      if self.domains[cell * self.count + other] {
        self.sums[cell] += self.model.weights[other]
        self.logs[cell] += self.weight_logs[other]
      }
    }
  }
  self.trail.push(index)
  self.queue.push(index)
  self.enqueue_entropy(cell)
  if self.heap.length() > self.sizes.length() * 8 + 1024 {
    self.heap.clear()
    for cell in 0..<self.sizes.length() {
      self.enqueue_entropy(cell)
    }
  }
}

///|
fn WaveSearch::propagate(self : WaveSearch) -> Bool raise SolveError {
  let mut valid = true
  while self.queue.pop() is Some(index) {
    self.tick()
    let cell = index / self.count
    let tile = index % self.count
    if self.sizes[cell] == 0 {
      valid = false
    }
    // Finish the event before returning a contradiction so rollback can restore
    // exactly the counters changed by each processed removal.
    for direction in 0..<4 {
      if grid_neighbor(cell, direction, self.width, self.height, self.periodic)
        is Some(other) {
        for target in self.model.neighbors[tile][direction] {
          self.tick()
          let counter = (other * self.count + target) * 4 + (direction + 2) % 4
          self.supports[counter] -= 1
          if self.supports[counter] == 0 {
            self.ban(other, target)
          }
        }
      }
    }
    self.processed.push(index)
  }
  valid
}

///|
fn WaveSearch::rollback(
  self : WaveSearch,
  decision : Decision,
) -> Unit raise SolveError {
  self.queue.clear()
  while self.processed.length() > decision.processed_mark {
    let index = self.processed.pop().unwrap()
    let cell = index / self.count
    let tile = index % self.count
    for direction in 0..<4 {
      if grid_neighbor(cell, direction, self.width, self.height, self.periodic)
        is Some(other) {
        for target in self.model.neighbors[tile][direction] {
          self.tick()
          self.supports[(other * self.count + target) * 4 + (direction + 2) % 4] += 1
        }
      }
    }
  }
  let touched : Map[Int, Bool] = Map([])
  while self.trail.length() > decision.trail_mark {
    let index = self.trail.pop().unwrap()
    let cell = index / self.count
    let tile = index % self.count
    self.domains[index] = true
    self.sizes[cell] += 1
    self.sums[cell] += self.model.weights[tile]
    self.logs[cell] += self.weight_logs[tile]
    touched[cell] = true
  }
  for cell, _ in touched {
    self.enqueue_entropy(cell)
  }
}

///|
fn WaveSearch::collapse(
  self : WaveSearch,
  decision : Decision,
) -> Unit raise SolveError {
  let mut total = 0.0
  for tile in decision.choices {
    total += self.model.weights[tile]
  }
  let mut draw = self.random() * total
  let mut picked = decision.choices.length() - 1
  for i, tile in decision.choices {
    draw -= self.model.weights[tile]
    if draw < 0.0 {
      picked = i
      break
    }
  }
  let tile = decision.choices[picked]
  decision.choices[picked] = decision.choices[decision.choices.length() - 1]
  ignore(decision.choices.pop())
  for other in 0..<self.count {
    if other != tile {
      self.ban(decision.cell, other)
    }
  }
}

///|
/// Iterative, reversible constraint propagation with weighted entropy. Limits are
/// 4096 tiles, 65536 cells and two million cell/tile states; budget counts actual
/// removal/counter work. None means complete exhaustion, not a timeout.
pub fn solve_rules(
  model : RuleModel,
  width : Int,
  height : Int,
  seed? : UInt = 1U,
  pins? : Array[(Int, Int)] = [],
  restrictions? : Array[(Int, Array[Int])] = [],
  periodic? : Bool = false,
  budget? : Int = 10000000,
) -> Solution? raise SolveError {
  model.checked()
  let count = model.labels.length()
  if width < 1 ||
    height < 1 ||
    width > 65536 ||
    height > 65536 ||
    width.to_int64() * height.to_int64() > 65536L ||
    width.to_int64() * height.to_int64() * count.to_int64() > 2000000L ||
    budget < 1 {
    raise Invalid("grid/state dimensions or budget exceed limits")
  }
  let cells = width * height
  let states = cells * count
  let mut total = 0.0
  let weight_logs = model.weights.map(w => w * @math.ln(w))
  let mut total_log = 0.0
  for i, weight in model.weights {
    total += weight
    total_log += weight_logs[i]
  }
  let self : WaveSearch = {
    model,
    width,
    height,
    periodic,
    count,
    domains: FixedArray::make(states, true),
    supports: FixedArray::make(states * 4, 0),
    sizes: FixedArray::make(cells, count),
    sums: FixedArray::make(cells, total),
    logs: FixedArray::make(cells, total_log),
    weight_logs,
    versions: FixedArray::make(cells, 0),
    trail: [],
    processed: [],
    queue: [],
    heap: [],
    budget,
    seed: if seed == 0U {
      1U
    } else {
      seed
    },
    decisions: 0,
    backtracks: 0,
  }
  for cell in 0..<cells {
    for tile in 0..<count {
      for direction in 0..<4 {
        let supports = model.neighbors[tile][direction].length()
        self.supports[(cell * count + tile) * 4 + direction] = supports
        if supports == 0 &&
          grid_neighbor(cell, direction, width, height, periodic) != None {
          self.ban(cell, tile)
        }
      }
    }
    self.enqueue_entropy(cell)
  }
  for (cell, tile) in pins {
    if cell < 0 || cell >= cells || tile < 0 || tile >= count {
      raise Invalid("invalid pin")
    }
    for other in 0..<count {
      if other != tile {
        self.ban(cell, other)
      }
    }
  }
  for (cell, allowed) in restrictions {
    if cell < 0 || cell >= cells || allowed.iter().any(t => t < 0 || t >= count) {
      raise Invalid("invalid cell restriction")
    }
    let keep : Map[Int, Bool] = Map([])
    for tile in allowed {
      keep[tile] = true
    }
    for tile in 0..<count {
      if !keep.contains(tile) {
        self.ban(cell, tile)
      }
    }
  }
  if !self.propagate() {
    return None
  }
  let stack : Array[Decision] = []
  while true {
    let mut selected = -1
    while heap_pop(self.heap) is Some(entry) {
      self.tick()
      if self.versions[entry.cell] == entry.version &&
        self.sizes[entry.cell] > 1 {
        selected = entry.cell
        break
      }
    }
    if selected < 0 {
      let tiles = Array::makei(cells, cell => {
        let mut tile = 0
        while tile < count && !self.domains[cell * count + tile] {
          tile += 1
        }
        tile
      })
      return Some({
        width,
        height,
        tiles,
        decisions: self.decisions,
        backtracks: self.backtracks,
      })
    }
    let decision : Decision = {
      cell: selected,
      trail_mark: self.trail.length(),
      processed_mark: self.processed.length(),
      choices: Array::makei(count, i => i).filter(t => {
        self.domains[selected * count + t]
      }),
    }
    stack.push(decision)
    self.decisions += 1
    self.collapse(decision)
    while !self.propagate() {
      let mut resumed = false
      while stack.pop() is Some(previous) {
        self.rollback(previous)
        self.backtracks += 1
        if !previous.choices.is_empty() {
          stack.push(previous)
          self.collapse(previous)
          resumed = true
          break
        }
      }
      if !resumed {
        return None
      }
    }
  }
  None
}
