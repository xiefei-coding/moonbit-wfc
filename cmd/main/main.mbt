///|
fn main raise {
  let model : @lib.Model = {
    labels: ["~ ", ". ", "^ "],
    allowed: [[3, 3, 3, 3], [7, 7, 7, 7], [6, 6, 6, 6]],
  }
  let solution = @lib.solve(model, 16, 10, seed=2026U, pins=[(0, 0), (159, 2)]).unwrap()
  println(solution.render(model))
  println("decisions=\{solution.decisions}, backtracks=\{solution.backtracks}")
}
