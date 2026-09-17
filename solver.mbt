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
} derive(Debug, Eq, ToJson)

///|
/// Legacy integer-mask model adapter; use RuleModel for more than 30 tiles.
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
  solve_rules(
    model.to_rules(weights~),
    width,
    height,
    seed~,
    pins~,
    budget~,
    periodic~,
  )
}

///|
pub fn Solution::render(
  self : Solution,
  model : Model,
) -> String raise SolveError {
  if self.width < 1 ||
    self.height < 1 ||
    self.width > 65536 ||
    self.height > 65536 ||
    self.width.to_int64() * self.height.to_int64() > 65536L ||
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
