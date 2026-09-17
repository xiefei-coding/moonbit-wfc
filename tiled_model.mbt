///|
/// D4 symmetry names and orientations follow mxgmn/WaveFunctionCollapse (MIT).
/// Neighbor expansion below applies group actions to a directed spatial edge.
pub(all) struct TileDefinition {
  name : String
  symmetry : String
  weight : Double
  pixels : Array[Array[Int]]
} derive(Debug, ToJson)

///|
pub struct TiledModel {
  rules : RuleModel
  tiles : Array[Array[Int]]
  tile_size : Int
} derive(Debug, ToJson)

///|
fn symmetry_count(symmetry : String) -> Int raise SolveError {
  match symmetry {
    "X" => 1
    "I" | "\\" => 2
    "L" | "T" => 4
    "F" => 8
    _ => raise Invalid("unknown tile symmetry")
  }
}

///|
fn rotate_orientation(symmetry : String, orientation : Int) -> Int {
  match symmetry {
    "X" => 0
    "I" | "\\" => 1 - orientation
    "F" =>
      if orientation < 4 {
        (orientation + 1) % 4
      } else {
        4 + (orientation + 3) % 4
      }
    _ => (orientation + 1) % 4
  }
}

///|
fn reflect_orientation(symmetry : String, orientation : Int) -> Int {
  match symmetry {
    "X" | "I" => orientation
    "\\" => 1 - orientation
    "L" => if orientation % 2 == 0 { orientation + 1 } else { orientation - 1 }
    "T" => if orientation % 2 == 0 { orientation } else { 4 - orientation }
    _ => if orientation < 4 { orientation + 4 } else { orientation - 4 }
  }
}

///|
pub fn expand_tiles(
  definitions : Array[TileDefinition],
  tile_size : Int,
  neighbors : Array[(String, String)],
  subset? : Array[String] = [],
) -> TiledModel raise SolveError {
  if tile_size < 1 ||
    tile_size > 256 ||
    definitions.is_empty() ||
    definitions.length() > 4096 ||
    neighbors.length() > 100000 {
    raise Invalid("invalid tileset dimensions")
  }
  let names : Map[String, Int] = Map([])
  let starts : Map[String, Int] = Map([])
  let actions : Array[Array[Int]] = []
  let labels = []
  let weights = []
  let tiles : Array[Array[Int]] = []
  for definition in definitions {
    if definition.name.is_empty() ||
      definition.name
      .iter()
      .any(c => c == ' ' || c == '\n' || c == '\t' || c == '\r') ||
      names.contains(definition.name) {
      raise Invalid("empty, duplicate or whitespace tile name")
    }
    names[definition.name] = 1
    let cardinality = symmetry_count(definition.symmetry)
    if !subset.is_empty() && !subset.contains(definition.name) {
      continue
    }
    if definition.pixels.length() != 1 &&
      definition.pixels.length() != cardinality {
      raise Invalid("tile needs one base bitmap or all orientation bitmaps")
    }
    if definition.pixels.iter().any(p => p.length() != tile_size * tile_size) {
      raise Invalid("tile bitmap dimensions differ")
    }
    let start = labels.length()
    if start + cardinality > 4096 ||
      (start + cardinality).to_int64() *
      tile_size.to_int64() *
      tile_size.to_int64() >
      4000000L {
      raise Invalid("expanded tile data limit")
    }
    starts[definition.name] = start
    for orientation in 0..<cardinality {
      let row = []
      let mut turned = orientation
      for _ in 0..<4 {
        row.push(start + turned)
        turned = rotate_orientation(definition.symmetry, turned)
      }
      turned = orientation
      for _ in 0..<4 {
        row.push(start + reflect_orientation(definition.symmetry, turned))
        turned = rotate_orientation(definition.symmetry, turned)
      }
      actions.push(row)
      let pixel = if definition.pixels.length() == cardinality {
        definition.pixels[orientation].copy()
      } else if orientation == 0 {
        definition.pixels[0].copy()
      } else if orientation < 4 {
        Array::makei(tile_size * tile_size, i => {
          tiles[start + orientation - 1][i % tile_size * tile_size +
          tile_size -
          1 -
          i / tile_size]
        })
      } else {
        Array::makei(tile_size * tile_size, i => {
          tiles[start + orientation - 4][i / tile_size * tile_size +
          tile_size -
          1 -
          i % tile_size]
        })
      }
      tiles.push(pixel)
      labels.push(definition.name + " " + orientation.to_string())
      weights.push(definition.weight)
    }
  }
  for name in subset {
    if !names.contains(name) {
      raise Invalid("unknown subset tile")
    }
  }
  let edges : Array[Map[Int, Bool]] = Array::makei(labels.length() * 4, _ => {
    Map([])
  })
  fn reference(text : String) -> (String, Int) raise SolveError {
    let parts = text.split(" ").filter(p => !p.is_empty()).collect()
    if parts.is_empty() || parts.length() > 2 {
      raise Invalid("invalid neighbor reference")
    }
    let name = parts[0].to_owned()
    if !names.contains(name) {
      raise Invalid("unknown neighbor tile")
    }
    let orientation = if parts.length() == 1 {
      0
    } else if parts[1].length() == 1 && parts[1][0] >= '0' && parts[1][0] <= '7' {
      parts[1][0].to_int() - 48
    } else {
      raise Invalid("neighbor orientation must be 0..7")
    }
    (name, orientation)
  }
  for (left, right) in neighbors {
    let l = reference(left)
    let r = reference(right)
    if starts.get(l.0) is Some(ls) && starts.get(r.0) is Some(rs) {
      let left_id = actions[ls][l.1]
      let right_id = actions[rs][r.1]
      for mirror in 0..<2 {
        for turn in 0..<4 {
          let a = actions[left_id][turn + 4 * mirror]
          let b = actions[right_id][turn + 4 * mirror]
          let rotated = (4 - turn) % 4
          let direction = if mirror == 1 && rotated % 2 == 0 {
            (rotated + 2) % 4
          } else {
            rotated
          }
          edges[a * 4 + direction][b] = true
          edges[b * 4 + (direction + 2) % 4][a] = true
        }
      }
    }
  }
  let neighbors = Array::makei(labels.length(), tile => {
    Array::makei(4, direction => {
      let row = edges[tile * 4 + direction].keys().collect()
      row.sort()
      row
    })
  })
  let rules : RuleModel = { labels, weights, neighbors, }
  rules.checked()
  { rules, tiles, tile_size, }
}

///|
pub fn TiledModel::render(
  self : TiledModel,
  solution : Solution,
) -> Array[Int] raise SolveError {
  if self.tile_size < 1 ||
    self.tile_size > 256 ||
    self.tiles.length() != self.rules.labels.length() ||
    self.tiles.iter().any(t => t.length() != self.tile_size * self.tile_size) ||
    !solution.validate_rules(self.rules) ||
    solution.tiles.length().to_int64() *
    self.tile_size.to_int64() *
    self.tile_size.to_int64() >
    4000000L {
    raise Invalid("invalid tiled rendering dimensions or solution")
  }
  let width = solution.width * self.tile_size
  Array::makei(solution.tiles.length() * self.tile_size * self.tile_size, i => {
    let x = i % width
    let y = i / width
    self.tiles[solution.tiles[y / self.tile_size * solution.width +
    x / self.tile_size]][y % self.tile_size * self.tile_size +
    x % self.tile_size]
  })
}
