///|
/// Validate dimensions, tile domain, all directed adjacency rules, and pins.
pub fn Solution::validate(
  self : Solution,
  model : Model,
  pins? : Array[(Int, Int)] = [],
  periodic? : Bool = false,
) -> Bool {
  let n = model.labels.length()
  if n < 1 ||
    n > 30 ||
    self.width < 1 ||
    self.height < 1 ||
    self.width > 256 ||
    self.height > 256 ||
    self.width * self.height != self.tiles.length() ||
    model.allowed.length() != n {
    return false
  }
  for row in model.allowed {
    if row.length() != 4 {
      return false
    }
  }
  for t in self.tiles {
    if t < 0 || t >= n {
      return false
    }
  }
  for (cell, tile) in pins {
    if cell < 0 || cell >= self.tiles.length() || self.tiles[cell] != tile {
      return false
    }
  }
  for i, tile in self.tiles {
    let x = i % self.width
    let y = i / self.width
    let neighbors = [
      if x + 1 < self.width {
        i + 1
      } else {
        -1
      },
      if y + 1 < self.height {
        i + self.width
      } else {
        -1
      },
      if x > 0 {
        i - 1
      } else {
        -1
      },
      if y > 0 {
        i - self.width
      } else {
        -1
      },
    ]
    for dir, j in neighbors {
      let j = if j >= 0 || !periodic {
        j
      } else {
        match dir {
          0 => y * self.width
          1 => x
          2 => y * self.width + self.width - 1
          _ => (self.height - 1) * self.width + x
        }
      }
      if j >= 0 && (model.allowed[tile][dir] & (1 << self.tiles[j])) == 0 {
        return false
      }
    }
  }
  true
}
