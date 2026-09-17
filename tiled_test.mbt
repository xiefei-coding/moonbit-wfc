///|
test "tiled symmetry composition and malformed input" {
  let definition : @wfc.TileDefinition = {
    name: "road",
    symmetry: "I",
    weight: 2.5,
    pixels: [[1, 2, 3, 4]],
  }
  let tiled = @wfc.expand_tiles([definition], 2, [
    ("road", "road"),
    ("road", "road 1"),
  ])
  assert_eq(tiled.rules.labels, ["road 0", "road 1"])
  assert_eq(tiled.tiles[1], [2, 4, 1, 3])
  let solution = @wfc.solve_rules(tiled.rules, 4, 4).unwrap()
  assert_eq(tiled.render(solution).length(), 64)
  assert_true(
    try {
      ignore(@wfc.expand_tiles([definition], 2, [("missing", "road")]))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@wfc.expand_tiles([definition], 2, [("road 8", "road")]))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@wfc.expand_tiles([definition], 2, [], subset=["missing"]))
      false
    } catch {
      _ => true
    },
  )
}

///|
test "pixel pins cover seams and final nonperiodic border" {
  let model = @wfc.learn_patterns([0, 1, 1, 0], 2, 2, 2)
  for periodic in [true, false] {
    let output = model
      .generate(8, 6, periodic~, pins=[(0, 1), (47, 1)])
      .unwrap()
    assert_eq(output[0], 1)
    assert_eq(output[47], 1)
    for y in 0..<6 {
      for x in 0..<8 {
        assert_eq(output[y * 8 + x], (x + y + 1) % 2)
      }
    }
    assert_eq(model.generate(8, 6, periodic~, pins=[(0, 1), (0, 0)]), None)
  }
}
