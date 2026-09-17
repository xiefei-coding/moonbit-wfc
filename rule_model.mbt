///|
/// Explicit neighbor lists, indexed [tile][east,south,west,north]. Unlike Model,
/// tile IDs are not packed into a signed machine integer.
pub(all) struct RuleModel {
  labels : Array[String]
  neighbors : Array[Array[Array[Int]]]
  weights : Array[Double]
} derive(Debug, ToJson)

///|
fn RuleModel::checked(self : RuleModel) -> Unit raise SolveError {
  let n = self.labels.length()
  if n < 1 ||
    n > 4096 ||
    self.neighbors.length() != n ||
    self.weights.length() != n {
    raise Invalid("invalid rule model dimensions")
  }
  let mut edges = 0
  let sets : Array[Map[Int, Bool]] = []
  for t in 0..<n {
    if self.weights[t] <= 0.0 ||
      self.weights[t] > 1000000.0 ||
      self.weights[t] != self.weights[t] {
      raise Invalid("weights must be finite, positive and at most 1000000")
    }
    if self.neighbors[t].length() != 4 {
      raise Invalid("four neighbor lists required")
    }
    for row in self.neighbors[t] {
      let seen : Map[Int, Bool] = Map([])
      for other in row {
        if other < 0 || other >= n || seen.contains(other) {
          raise Invalid("invalid or duplicate neighbor")
        }
        seen[other] = true
      }
      edges += row.length()
      if edges > 4000000 {
        raise Invalid("adjacency size limit")
      }
      sets.push(seen)
    }
  }
  for t in 0..<n {
    for dir in 0..<4 {
      for other in self.neighbors[t][dir] {
        if !sets[other * 4 + (dir + 2) % 4].contains(t) {
          raise Invalid("asymmetric adjacency")
        }
      }
    }
  }
}

///|
pub fn Model::to_rules(
  self : Model,
  weights? : Array[Int] = [],
) -> RuleModel raise SolveError {
  let n = self.labels.length()
  if n < 1 || n > 30 || self.allowed.length() != n {
    raise Invalid("invalid legacy model dimensions")
  }
  let full = (1 << n) - 1
  let neighbors = []
  for row in self.allowed {
    if row.length() != 4 {
      raise Invalid("four directions required")
    }
    let lists = []
    for mask in row {
      if mask < 0 || (mask & full) != mask {
        raise Invalid("invalid tile mask")
      }
      lists.push(Array::makei(n, i => i).filter(i => (mask & (1 << i)) != 0))
    }
    neighbors.push(lists)
  }
  let values = if weights.is_empty() {
    Array::make(n, 1.0)
  } else {
    weights.map(w => w.to_double())
  }
  let result : RuleModel = {
    labels: self.labels.copy(),
    neighbors,
    weights: values,
  }
  result.checked()
  result
}

///|
fn grid_neighbor(
  cell : Int,
  direction : Int,
  width : Int,
  height : Int,
  periodic : Bool,
) -> Int? {
  let x = cell % width
  let y = cell / width
  match direction {
    0 =>
      if x + 1 < width {
        Some(cell + 1)
      } else if periodic {
        Some(cell + 1 - width)
      } else {
        None
      }
    1 =>
      if y + 1 < height {
        Some(cell + width)
      } else if periodic {
        Some(x)
      } else {
        None
      }
    2 =>
      if x > 0 {
        Some(cell - 1)
      } else if periodic {
        Some(cell + width - 1)
      } else {
        None
      }
    _ =>
      if y > 0 {
        Some(cell - width)
      } else if periodic {
        Some((height - 1) * width + x)
      } else {
        None
      }
  }
}

///|
pub fn Solution::validate_rules(
  self : Solution,
  model : RuleModel,
  pins? : Array[(Int, Int)] = [],
  periodic? : Bool = false,
) -> Bool {
  if self.width < 1 ||
    self.width > 65536 ||
    self.height < 1 ||
    self.height > 65536 ||
    self.width.to_int64() * self.height.to_int64() > 65536L ||
    self.tiles.length() != self.width * self.height {
    return false
  }
  model.checked() catch {
    _ => return false
  }
  if self.tiles.iter().any(t => t < 0 || t >= model.labels.length()) {
    return false
  }
  for (cell, tile) in pins {
    if cell < 0 || cell >= self.tiles.length() || self.tiles[cell] != tile {
      return false
    }
  }
  for cell, tile in self.tiles {
    for direction in 0..<4 {
      if grid_neighbor(cell, direction, self.width, self.height, periodic)
        is Some(other) {
        if !model.neighbors[tile][direction].contains(self.tiles[other]) {
          return false
        }
      }
    }
  }
  true
}
