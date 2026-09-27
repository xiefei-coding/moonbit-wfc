///|
test "accepted learning dimensions produce a model the solver can consume" {
  // Exact occurrence counts: 512*512 sample positions and eight transforms.
  let sample = Array::make(512 * 512, 7)
  let uniform = @wfc.learn_patterns(sample, 512, 512, 1, symmetry=8)
  assert_eq(uniform.rules.weights, [2097152.0])
  assert_eq(uniform.generate(2, 2), Some([7, 7, 7, 7]))
  sample[sample.length() - 1] = 9
  let mixed = @wfc.learn_patterns(sample, 512, 512, 1, symmetry=8)
  assert_eq(mixed.rules.weights, [2097144.0, 8.0])
  let output = mixed.generate(2, 2, pins=[(0, 9)]).unwrap()
  assert_eq(output[0], 9)
  assert_true(output.all(value => value == 7 || value == 9))
}

///|
test "legacy positive Int weights retain a finite solver model" {
  let model : @wfc.Model = { labels: ["one"], allowed: [[1, 1, 1, 1]], }
  assert_eq(@wfc.solve(model, 2, 1, weights=[2147483647]).unwrap().tiles, [0, 0])
  let too_large : @wfc.RuleModel = {
    labels: ["one"],
    neighbors: [[[0], [0], [0], [0]]],
    weights: [2147483648.0],
  }
  assert_true(
    try {
      ignore(@wfc.solve_rules(too_large, 1, 1))
      false
    } catch {
      @wfc.Invalid(_) => true
      _ => false
    },
  )
}

///|
test "repeated pins preserve identity conflicts and cell restrictions" {
  let n = 4096
  let model : @wfc.RuleModel = {
    labels: Array::makei(n, i => i.to_string()),
    weights: Array::make(n, 1.0),
    neighbors: Array::makei(n, i => Array::makei(4, _ => [i])),
  }
  let many = Array::make(65536, (0, 7))
  assert_eq(
    @wfc.solve_rules(model, 1, 1, pins=many, budget=20000).unwrap().tiles,
    [7],
  )
  assert_eq(
    @wfc.solve_rules(
      model,
      1,
      1,
      pins=many,
      restrictions=[(0, [8])],
      budget=20000,
    ),
    None,
  )
  many[1] = (0, 8)
  assert_eq(@wfc.solve_rules(model, 1, 1, pins=many, budget=20000), None)
  many[many.length() - 1] = (1, 7)
  assert_true(
    try {
      ignore(@wfc.solve_rules(model, 1, 1, pins=many, budget=20000))
      false
    } catch {
      @wfc.Invalid(_) => true
      _ => false
    },
  )
}
