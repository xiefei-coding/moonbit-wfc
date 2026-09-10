///|
pub suberror SolveError {
  Invalid(String)
} derive(Debug)

///|
/// allowed[tile][direction], directions east, south, west, north.
pub(all) struct Model {
  labels : Array[String]
  allowed : Array[Array[Int]]
} derive(Debug)

///|
pub struct Solution {
  width : Int
  height : Int
  tiles : Array[Int]
  decisions : Int
  backtracks : Int
} derive(Debug, Eq)

///|
priv struct Search {
  model : Model
  weights : Array[Int]
  periodic : Bool
  width : Int
  height : Int
  mut seed : UInt
  mut budget : Int
  mut decisions : Int
  mut backtracks : Int
}

///|
fn Search::random(self : Search, n : Int) -> Int {
  let mut x = self.seed
  x = x ^ (x << 13)
  x = x ^ (x >> 17)
  x = x ^ (x << 5)
  self.seed = x
  (x % n.reinterpret_as_uint()).reinterpret_as_int()
}

///|
fn bits(mask : Int) -> Array[Int] {
  let out = []
  for i in 0..<30 {
    if (mask & (1 << i)) != 0 {
      out.push(i)
    }
  }
  out
}

///|
fn Search::neighbor(self : Search, cell : Int, dir : Int) -> Int? {
  let x = cell % self.width
  let y = cell / self.width
  if self.periodic {
    return Some(
      match dir {
        0 => y * self.width + (x + 1) % self.width
        1 => (y + 1) % self.height * self.width + x
        2 => y * self.width + (x + self.width - 1) % self.width
        _ => (y + self.height - 1) % self.height * self.width + x
      },
    )
  }
  match dir {
    0 => if x + 1 < self.width { Some(cell + 1) } else { None }
    1 => if y + 1 < self.height { Some(cell + self.width) } else { None }
    2 => if x > 0 { Some(cell - 1) } else { None }
    _ => if y > 0 { Some(cell - self.width) } else { None }
  }
}

///|
fn Search::propagate(
  self : Search,
  domains : Array[Int],
) -> Bool raise SolveError {
  let queue = Array::makei(domains.length(), i => i)
  let mut head = 0
  while head < queue.length() {
    self.budget -= 1
    if self.budget < 0 {
      raise Invalid("search budget exhausted")
    }
    let cell = queue[head]
    head += 1
    if domains[cell] == 0 {
      return false
    }
    for dir in 0..<4 {
      if self.neighbor(cell, dir) is Some(other) {
        let mut support = 0
        for tile in bits(domains[cell]) {
          support = support | self.model.allowed[tile][dir]
        }
        let next = domains[other] & support
        if next == 0 {
          return false
        }
        if next != domains[other] {
          domains[other] = next
          queue.push(other)
        }
      }
    }
  }
  true
}

///|
fn Search::search(
  self : Search,
  domains : Array[Int],
) -> Array[Int]? raise SolveError {
  if !self.propagate(domains) {
    return None
  }
  let mut selected = -1
  let mut minimum = 1.0e100
  let mut ties = 0
  for i in 0..<domains.length() {
    let count = bits(domains[i]).length()
    let mut sum = 0.0
    let mut weighted_log = 0.0
    for tile in bits(domains[i]) {
      let weight = self.weights[tile].to_double()
      sum += weight
      weighted_log += weight * @math.ln(weight)
    }
    let entropy = @math.ln(sum) - weighted_log / sum
    if count > 1 && entropy < minimum {
      selected = i
      minimum = entropy
      ties = 1
    } else if count > 1 && entropy == minimum {
      ties += 1
      if self.random(ties) == 0 {
        selected = i
      }
    }
  }
  if selected < 0 {
    return Some(domains.map(d => bits(d)[0]))
  }
  self.decisions += 1
  let choices = bits(domains[selected])
  for i in 0..<choices.length() {
    let mut total = 0
    for k in i..<choices.length() {
      total += self.weights[choices[k]]
    }
    let mut draw = self.random(total)
    let mut j = i
    while j + 1 < choices.length() && draw >= self.weights[choices[j]] {
      draw -= self.weights[choices[j]]
      j += 1
    }
    let temp = choices[i]
    choices[i] = choices[j]
    choices[j] = temp
    let branch = domains.copy()
    branch[selected] = 1 << choices[i]
    if self.search(branch) is Some(solution) {
      return Some(solution)
    }
    self.backtracks += 1
  }
  None
}

///|
/// Exact tiled WFC with backtracking. Invalid models and budget exhaustion raise;
/// a fully explored unsatisfiable model returns None. Maximum 256 cells, 30 tiles.
pub fn solve(
  model : Model,
  width : Int,
  height : Int,
  seed? : UInt = 1U,
  pins? : Array[(Int, Int)] = [],
  budget? : Int = 1000000,
  weights? : Array[Int] = [],
  periodic? : Bool = false,
) -> Solution? raise SolveError {
  let count = model.labels.length()
  if width < 1 ||
    height < 1 ||
    width > 256 ||
    height > 256 ||
    width * height > 256 ||
    count < 1 ||
    count > 30 ||
    model.allowed.length() != count ||
    budget < 1 {
    raise Invalid("invalid model dimensions or budget")
  }
  let weights = if weights.is_empty() {
    Array::make(count, 1)
  } else {
    weights.copy()
  }
  if weights.length() != count || weights.iter().any(w => w < 1 || w > 1000000) {
    raise Invalid("one positive weight per tile, maximum 1000000")
  }
  let full = (1 << count) - 1
  for row in model.allowed {
    if row.length() != 4 {
      raise Invalid("each tile requires four directions")
    }
    for mask in row {
      if mask < 0 || (mask & full) != mask {
        raise Invalid("invalid tile mask")
      }
    }
  }
  // Mutual adjacency is required so that every collapsed edge satisfies both tiles.
  for t in 0..<count {
    for dir in 0..<4 {
      for other in 0..<count {
        if ((model.allowed[t][dir] >> other) & 1) !=
          ((model.allowed[other][(dir + 2) % 4] >> t) & 1) {
          raise Invalid("asymmetric adjacency")
        }
      }
    }
  }
  let domains = Array::make(width * height, full)
  for pin in pins {
    if pin.0 < 0 || pin.0 >= domains.length() || pin.1 < 0 || pin.1 >= count {
      raise Invalid("invalid pin")
    }
    domains[pin.0] = domains[pin.0] & (1 << pin.1)
  }
  let state : Search = {
    model,
    weights,
    periodic,
    width,
    height,
    seed: if seed == 0U {
      1U
    } else {
      seed
    },
    budget,
    decisions: 0,
    backtracks: 0,
  }
  match state.search(domains) {
    None => None
    Some(tiles) =>
      Some({
        width,
        height,
        tiles,
        decisions: state.decisions,
        backtracks: state.backtracks,
      })
  }
}

///|
pub fn Solution::render(
  self : Solution,
  model : Model,
) -> String raise SolveError {
  if self.width < 1 ||
    self.height < 1 ||
    self.width > 256 ||
    self.height > 256 ||
    self.tiles.length() != self.width * self.height {
    raise Invalid("invalid solution dimensions")
  }
  let rows = []
  for y in 0..<self.height {
    let mut row = ""
    for x in 0..<self.width {
      let tile = self.tiles[y * self.width + x]
      if tile < 0 || tile >= model.labels.length() {
        raise Invalid("invalid solution tile")
      }
      row += model.labels[tile]
    }
    rows.push(row)
  }
  rows.join("\n")
}
