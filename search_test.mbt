///|
test "arc-consistent unsatisfiable tile system requires search" {
  let model : @wfc.Model = {
    labels: ["0", "1", "2"],
    allowed: [[2, 2, 4, 2], [4, 1, 1, 1], [1, 4, 2, 4]],
  }
  // Every tile has support in every direction, but horizontal and vertical
  // permutations do not commute, so the 2x2 cycle cannot close.
  assert_eq(@wfc.solve(model, 2, 2), None)
}

///|
test "single cell no neighbors and dimension limits" {
  let isolated : @wfc.Model = { labels: ["x"], allowed: [[0, 0, 0, 0]], }
  assert_eq(@wfc.solve(isolated, 1, 1).unwrap().tiles, [0])
  assert_eq(@wfc.solve(isolated, 2, 1), None)
  assert_true(
    try {
      ignore(@wfc.solve(isolated, 257, 1))
      false
    } catch {
      _ => true
    },
  )
}
