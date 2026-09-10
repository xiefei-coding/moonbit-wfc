///|
/// Learned square patterns and their observed frequencies. Symbols may be colors or tiles.
pub struct OverlapModel {
  size : Int
  patterns : Array[Array[Int]]
  weights : Array[Int]
  model : Model
} derive(Debug)

///|
/// Learn patterns, optionally with all eight rotations/reflections.
/// Current bit-mask solver supports at most 30 unique patterns; excess raises.
pub fn learn_overlap(
  sample : Array[Int],
  width : Int,
  height : Int,
  size : Int,
  periodic_input? : Bool = true,
  symmetry? : Bool = false,
) -> OverlapModel raise SolveError {
  if width < 1 ||
    height < 1 ||
    width > 256 ||
    height > 256 ||
    sample.length() != width * height ||
    size < 1 ||
    size > 8 ||
    (!periodic_input && (width < size || height < size)) {
    raise Invalid("invalid sample dimensions or pattern size")
  }
  let patterns : Array[Array[Int]] = []
  let weights : Array[Int] = []
  let nx = if periodic_input { width } else { width - size + 1 }
  let ny = if periodic_input { height } else { height - size + 1 }
  for y in 0..<ny {
    for x in 0..<nx {
      let original = Array::makei(size * size, i => {
        sample[(y + i / size) % height * width + (x + i % size) % width]
      })
      let mut rotated = original
      for turn in 0..<(if symmetry { 4 } else { 1 }) {
        for mirror in 0..<(if symmetry { 2 } else { 1 }) {
          let pattern = if mirror == 0 {
            rotated
          } else {
            Array::makei(size * size, i => {
              rotated[i / size * size + size - 1 - i % size]
            })
          }
          let mut found = -1
          for i, existing in patterns {
            if existing == pattern {
              found = i
              break
            }
          }
          if found >= 0 {
            weights[found] += 1
          } else {
            if patterns.length() == 30 {
              raise Invalid("more than 30 unique overlapping patterns")
            }
            patterns.push(pattern)
            weights.push(1)
          }
        }
        if turn < 3 {
          rotated = Array::makei(size * size, i => {
            rotated[(size - 1 - i % size) * size + i / size]
          })
        }
      }
    }
  }
  let allowed = Array::makei(patterns.length(), _ => Array::make(4, 0))
  for a, first in patterns {
    for b, second in patterns {
      for dir in 0..<4 {
        let dx = if dir == 0 { 1 } else if dir == 2 { -1 } else { 0 }
        let dy = if dir == 1 { 1 } else if dir == 3 { -1 } else { 0 }
        let mut compatible = true
        for y in 0..<size {
          for x in 0..<size {
            let bx = x - dx
            let by = y - dy
            if bx >= 0 &&
              bx < size &&
              by >= 0 &&
              by < size &&
              first[y * size + x] != second[by * size + bx] {
              compatible = false
            }
          }
        }
        if compatible {
          allowed[a][dir] = allowed[a][dir] | (1 << b)
        }
      }
    }
  }
  {
    size,
    patterns,
    weights,
    model: {
      labels: Array::makei(patterns.length(), i => i.to_string()),
      allowed,
    },
  }
}

///|
/// Return exactly width*height symbols. Nonperiodic output includes the full edge patches.
pub fn OverlapModel::generate(
  self : OverlapModel,
  width : Int,
  height : Int,
  seed? : UInt = 1U,
  periodic? : Bool = false,
  budget? : Int = 1000000,
) -> Array[Int]? raise SolveError {
  if width < self.size || height < self.size || width > 256 || height > 256 {
    raise Invalid("output dimensions must accommodate the pattern")
  }
  let wave_width = if periodic { width } else { width - self.size + 1 }
  let wave_height = if periodic { height } else { height - self.size + 1 }
  let result = solve(
    self.model,
    wave_width,
    wave_height,
    seed~,
    periodic~,
    budget~,
    weights=self.weights,
  )
  match result {
    None => None
    Some(solution) =>
      Some(
        Array::makei(width * height, i => {
          let x = i % width
          let y = i / width
          let anchor_x = if x < wave_width { x } else { wave_width - 1 }
          let anchor_y = if y < wave_height { y } else { wave_height - 1 }
          let pattern = self.patterns[solution.tiles[anchor_y * wave_width +
            anchor_x]]
          pattern[(y - anchor_y) * self.size + x - anchor_x]
        }),
      )
  }
}
