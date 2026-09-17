///|
pub struct PatternModel {
  size : Int
  patterns : Array[Array[Int]]
  rules : RuleModel
} derive(Debug, ToJson)

///|
fn pattern_key(pattern : Array[Int]) -> String {
  pattern.map(value => value.to_string()).join(",")
}

///|
fn overlap_key(pattern : Array[Int], size : Int, direction : Int) -> String {
  let values = []
  for y in 0..<size {
    for x in 0..<size {
      if (direction == 0 && x > 0) ||
        (direction == 1 && y > 0) ||
        (direction == 2 && x + 1 < size) ||
        (direction == 3 && y + 1 < size) {
        values.push(pattern[y * size + x])
      }
    }
  }
  pattern_key(values)
}

///|
/// Learn collision-free integer patterns with 1..8 dihedral transforms. Transform
/// order is identity, reflection, quarter-turn, reflection, half-turn, ... .
pub fn learn_patterns(
  sample : Array[Int],
  width : Int,
  height : Int,
  size : Int,
  periodic_input? : Bool = true,
  symmetry? : Int = 1,
) -> PatternModel raise SolveError {
  if width < 1 ||
    height < 1 ||
    width > 1024 ||
    height > 1024 ||
    width * height > 262144 ||
    sample.length() != width * height ||
    size < 1 ||
    size > 8 ||
    symmetry < 1 ||
    symmetry > 8 ||
    (!periodic_input && (width < size || height < size)) {
    raise Invalid("invalid pattern learning dimensions or symmetry")
  }
  let patterns : Array[Array[Int]] = []
  let counts : Array[Double] = []
  let indices : Map[String, Int] = Map([])
  let nx = if periodic_input { width } else { width - size + 1 }
  let ny = if periodic_input { height } else { height - size + 1 }
  if nx.to_int64() *
    ny.to_int64() *
    symmetry.to_int64() *
    size.to_int64() *
    size.to_int64() >
    32000000L {
    raise Invalid("pattern learning work limit")
  }
  for y in 0..<ny {
    for x in 0..<nx {
      let mut rotated = Array::makei(size * size, i => {
        sample[(y + i / size) % height * width + (x + i % size) % width]
      })
      for transform in 0..<symmetry {
        if transform > 0 && transform % 2 == 0 {
          rotated = Array::makei(size * size, i => {
            rotated[i % size * size + size - 1 - i / size]
          })
        }
        let pattern = if transform % 2 == 0 {
          rotated
        } else {
          Array::makei(size * size, i => {
            rotated[i / size * size + size - 1 - i % size]
          })
        }
        let key = pattern_key(pattern)
        if indices.get(key) is Some(index) {
          counts[index] += 1.0
        } else {
          if patterns.length() == 4096 {
            raise Invalid("pattern count limit")
          }
          indices[key] = patterns.length()
          patterns.push(pattern)
          counts.push(1.0)
        }
      }
    }
  }
  let neighbors = Array::makei(patterns.length(), _ => Array::makei(4, _ => []))
  let mut edges = 0
  for direction in 0..<4 {
    let incoming : Map[String, Array[Int]] = Map([])
    for index, pattern in patterns {
      let key = overlap_key(pattern, size, (direction + 2) % 4)
      let entries = incoming.get(key).unwrap_or([])
      entries.push(index)
      incoming[key] = entries
    }
    for index, pattern in patterns {
      let row = incoming
        .get(overlap_key(pattern, size, direction))
        .unwrap_or([])
      edges += row.length()
      if edges > 4000000 {
        raise Invalid("pattern adjacency limit")
      }
      neighbors[index][direction] = row.copy()
    }
  }
  {
    size,
    patterns,
    rules: {
      labels: Array::makei(patterns.length(), i => i.to_string()),
      neighbors,
      weights: counts,
    },
  }
}

///|
pub fn PatternModel::generate(
  self : PatternModel,
  width : Int,
  height : Int,
  seed? : UInt = 1U,
  periodic? : Bool = false,
  ground? : Bool = false,
  pins? : Array[(Int, Int)] = [],
  budget? : Int = 10000000,
) -> Array[Int]? raise SolveError {
  if self.size < 1 ||
    self.size > 8 ||
    self.patterns.is_empty() ||
    self.patterns.length() != self.rules.labels.length() ||
    self.patterns.iter().any(p => p.length() != self.size * self.size) {
    raise Invalid("invalid pattern model")
  }
  if width < self.size ||
    height < self.size ||
    width > 65536 ||
    height > 65536 ||
    width.to_int64() * height.to_int64() > 65536L {
    raise Invalid("invalid output dimensions")
  }
  let wave_width = if periodic { width } else { width - self.size + 1 }
  let wave_height = if periodic { height } else { height - self.size + 1 }
  if wave_width.to_int64() *
    wave_height.to_int64() *
    self.patterns.length().to_int64() >
    2000000L {
    raise Invalid("pattern wave state limit")
  }
  let restrictions : Array[(Int, Array[Int])] = []
  if ground {
    let last = self.patterns.length() - 1
    for cell in 0..<(wave_width * wave_height) {
      restrictions.push(
        (
          cell,
          if cell / wave_width == wave_height - 1 {
            [last]
          } else {
            Array::makei(last, i => i)
          },
        ),
      )
    }
  }
  if pins.length() > 4096 {
    raise Invalid("pixel constraint count limit")
  }
  let mut constraint_work = 0
  for (pixel, color) in pins {
    if pixel < 0 || pixel >= width * height {
      raise Invalid("invalid pixel pin")
    }
    let px = pixel % width
    let py = pixel / width
    for dy in 0..<self.size {
      for dx in 0..<self.size {
        let ax = if periodic { (px - dx + width) % width } else { px - dx }
        let ay = if periodic { (py - dy + height) % height } else { py - dy }
        if ax >= 0 && ax < wave_width && ay >= 0 && ay < wave_height {
          constraint_work += self.patterns.length()
          if constraint_work > 10000000 {
            raise Invalid("pixel constraint work limit")
          }
          let allowed = Array::makei(self.patterns.length(), i => i).filter(i => {
            self.patterns[i][dy * self.size + dx] == color
          })
          restrictions.push((ay * wave_width + ax, allowed))
        }
      }
    }
  }
  let result = solve_rules(
    self.rules,
    wave_width,
    wave_height,
    seed~,
    periodic~,
    budget~,
    restrictions~,
  )
  result.map(solution => {
    Array::makei(width * height, i => {
      let x = i % width
      let y = i / width
      let ax = if x < wave_width { x } else { wave_width - 1 }
      let ay = if y < wave_height { y } else { wave_height - 1 }
      self.patterns[solution.tiles[ay * wave_width + ax]][(y - ay) * self.size +
      x -
      ax]
    })
  })
}
