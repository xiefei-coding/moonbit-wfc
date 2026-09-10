///|
test "checkerboard and pins" {
  let model : @wfc.Model = {
    labels: [".", "#"],
    allowed: [[2, 2, 2, 2], [1, 1, 1, 1]],
  }
  let solution = @wfc.solve(model, 4, 3, pins=[(0, 0)]).unwrap()
  assert_eq(solution.render(model), ".#.#\n#.#.\n.#.#")
  assert_eq(@wfc.solve(model, 2, 1, pins=[(0, 0), (1, 0)]), None)
}

///|
test "all generated edges valid across seeds" {
  let model : @wfc.Model = {
    labels: ["~", ".", "^"],
    allowed: [[3, 3, 3, 3], [7, 7, 7, 7], [6, 6, 6, 6]],
  }
  for seed in 1..<40 {
    let result = @wfc.solve(model, 8, 8, seed=seed.reinterpret_as_uint()).unwrap()
    for y in 0..<8 {
      for x in 0..<8 {
        let t = result.tiles[y * 8 + x]
        if x < 7 {
          assert_true(
            (model.allowed[t][0] & (1 << result.tiles[y * 8 + x + 1])) != 0,
          )
        }
        if y < 7 {
          assert_true(
            (model.allowed[t][1] & (1 << result.tiles[(y + 1) * 8 + x])) != 0,
          )
        }
      }
    }
    assert_eq(
      result,
      @wfc.solve(model, 8, 8, seed=seed.reinterpret_as_uint()).unwrap(),
    )
  }
}

///|
test "invalid model and exhausted budget are distinct from contradiction" {
  let bad : @wfc.Model = { labels: ["a"], allowed: [[2, 2, 2, 2]], }
  assert_true(
    try {
      ignore(@wfc.solve(bad, 2, 2))
      false
    } catch {
      _ => true
    },
  )
  let good : @wfc.Model = {
    labels: ["a", "b"],
    allowed: [[3, 3, 3, 3], [3, 3, 3, 3]],
  }
  assert_true(
    try {
      ignore(@wfc.solve(good, 4, 4, budget=1))
      false
    } catch {
      _ => true
    },
  )
  assert_eq(@wfc.solve(good, 1, 1, pins=[(0, 0), (0, 1)]), None)
}
