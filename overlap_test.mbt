///|
test "overlap learns frequencies and complete output patches" {
  let learned = @wfc.learn_overlap(
    [0, 1, 0, 1, 0, 1],
    3,
    2,
    2,
    periodic_input=false,
  )
  assert_eq(learned.patterns.length(), 2)
  assert_eq(learned.weights, [1, 1])
  for seed in 1..<12 {
    let out = learned.generate(8, 7, seed=seed.reinterpret_as_uint()).unwrap()
    assert_eq(out.length(), 56)
    for y in 0..<6 {
      for x in 0..<7 {
        let patch = [
          out[y * 8 + x],
          out[y * 8 + x + 1],
          out[(y + 1) * 8 + x],
          out[(y + 1) * 8 + x + 1],
        ]
        assert_true(learned.patterns.iter().any(p => p == patch))
      }
    }
  }
  let frequency = @wfc.learn_overlap([0, 0, 0, 1], 4, 1, 1)
  assert_eq(frequency.weights, [3, 1])
}

///|
test "overlap symmetry and toroidal constraints" {
  let asymmetric = @wfc.learn_overlap(
    [0, 1, 2, 3],
    2,
    2,
    2,
    periodic_input=false,
    symmetry=true,
  )
  assert_eq(asymmetric.patterns.length(), 8)
  let checker = @wfc.learn_overlap([0, 1, 1, 0], 2, 2, 2)
  assert_eq(checker.patterns.length(), 2)
  let out = checker.generate(4, 4, periodic=true).unwrap()
  for y in 0..<4 {
    for x in 0..<4 {
      assert_true(out[y * 4 + x] != out[y * 4 + (x + 1) % 4])
      assert_true(out[y * 4 + x] != out[(y + 1) % 4 * 4 + x])
    }
  }
  assert_eq(checker.generate(3, 3, periodic=true), None)
  assert_eq(@wfc.solve(checker.model, 1, 1, periodic=true), None)
  let solution = @wfc.solve(checker.model, 4, 4, periodic=true).unwrap()
  assert_true(solution.validate(checker.model, periodic=true))
}

///|
test "overlap weighted collapse and resource rejection" {
  let model : @wfc.Model = {
    labels: ["a", "b"],
    allowed: [[3, 3, 3, 3], [3, 3, 3, 3]],
  }
  let mut common = 0
  for seed in 1..<101 {
    if @wfc.solve(model, 1, 1, seed=seed.reinterpret_as_uint(), weights=[100, 1]).unwrap().tiles[0] ==
      0 {
      common += 1
    }
  }
  assert_true(common > 85)
  assert_true(
    try {
      ignore(@wfc.solve(model, 1, 1, weights=[0, 1]))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@wfc.learn_overlap(Array::makei(31, i => i), 31, 1, 1))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@wfc.learn_overlap([0], 1, 1, 2, periodic_input=false))
      false
    } catch {
      _ => true
    },
  )
}
