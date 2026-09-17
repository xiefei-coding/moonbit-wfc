///|
test "wide rules exceed both legacy tile and grid capacity" {
  let n = 64
  let rules : @wfc.RuleModel = {
    labels: Array::makei(n, i => i.to_string()),
    weights: Array::make(n, 1.0),
    neighbors: Array::makei(n, i => [[(i + 1) % n], [i], [(i + n - 1) % n], [i]]),
  }
  let solution = @wfc.solve_rules(rules, 128, 64, pins=[(0, 0)], periodic=true).unwrap()
  assert_eq(solution.tiles.length(), 8192)
  for i, tile in solution.tiles {
    assert_eq(tile, i % 128 % n)
  }
  assert_true(solution.validate_rules(rules, periodic=true, pins=[(0, 0)]))
  assert_eq(@wfc.solve_rules(rules, 65, 1, periodic=true), None)
}

///|
test "wide explicit relations agree with independent exhaustive oracle" {
  for east in 0..<16 {
    for south in 0..<16 {
      let neighbors = Array::makei(2, _ => Array::makei(4, _ => []))
      for a in 0..<2 {
        for b in 0..<2 {
          if (east & (1 << (2 * a + b))) != 0 {
            neighbors[a][0].push(b)
            neighbors[b][2].push(a)
          }
          if (south & (1 << (2 * a + b))) != 0 {
            neighbors[a][1].push(b)
            neighbors[b][3].push(a)
          }
        }
      }
      let rules : @wfc.RuleModel = {
        labels: ["a", "b"],
        weights: [1.0, 2.5],
        neighbors,
      }
      for periodic in [false, true] {
        let mut possible = false
        for bits in 0..<16 {
          let tiles = Array::makei(4, i => (bits >> i) & 1)
          let mut valid = tiles[0] == 0
          for i in 0..<4 {
            if i % 2 == 0 || periodic {
              let j = if i % 2 == 0 { i + 1 } else { i - 1 }
              if (east & (1 << (2 * tiles[i] + tiles[j]))) == 0 {
                valid = false
              }
            }
            if i < 2 || periodic {
              let j = (i + 2) % 4
              if (south & (1 << (2 * tiles[i] + tiles[j]))) == 0 {
                valid = false
              }
            }
          }
          if valid {
            possible = true
          }
        }
        let solved = @wfc.solve_rules(
          rules,
          2,
          2,
          pins=[(0, 0)],
          periodic~,
          seed=42U,
        )
        assert_eq(solved is Some(_), possible)
        if solved is Some(solution) {
          assert_true(solution.validate_rules(rules, periodic~, pins=[(0, 0)]))
        }
      }
    }
  }
}

///|
test "collision-free large pattern learning and independent patch membership" {
  let sample = Array::makei(64, i => i)
  let learned = @wfc.learn_patterns(sample, 8, 8, 2)
  assert_eq(learned.patterns.length(), 64)
  assert_true(learned.rules.weights.iter().all(w => w == 1.0))
  let output = learned.generate(32, 32, periodic=true).unwrap()
  for y in 0..<32 {
    for x in 0..<32 {
      let a = output[y * 32 + x]
      assert_eq(output[y * 32 + (x + 1) % 32], a / 8 * 8 + (a % 8 + 1) % 8)
      assert_eq(output[(y + 1) % 32 * 32 + x], (a / 8 + 1) % 8 * 8 + a % 8)
    }
  }
  let reflected = @wfc.learn_patterns(
    [0, 1, 2, 3],
    2,
    2,
    2,
    periodic_input=false,
    symmetry=8,
  )
  assert_eq(reflected.patterns.length(), 8)
  for i in 1..<=8 {
    assert_eq(
      @wfc.learn_patterns(
        [0, 1, 2, 3],
        2,
        2,
        2,
        periodic_input=false,
        symmetry=i,
      ).patterns.length(),
      i,
    )
  }
}

///|
test "wide restrictions reject bad models and distinguish resource exhaustion" {
  let rules : @wfc.RuleModel = {
    labels: ["a", "b"],
    weights: [1.0, 1.0],
    neighbors: [
      [[0, 1], [0, 1], [0, 1], [0, 1]],
      [[0, 1], [0, 1], [0, 1], [0, 1]],
    ],
  }
  assert_eq(@wfc.solve_rules(rules, 1, 1, restrictions=[(0, [])]), None)
  assert_eq(
    @wfc.solve_rules(rules, 1, 1, restrictions=[(0, [1])]).unwrap().tiles,
    [1],
  )
  assert_true(
    try {
      ignore(@wfc.solve_rules(rules, 32, 32, budget=1))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(@wfc.solve_rules(rules, 65536, 2))
      false
    } catch {
      _ => true
    },
  )
  let invalid : @wfc.RuleModel = {
    labels: ["a"],
    weights: [0.0],
    neighbors: [[[0], [0], [0], [0]]],
  }
  assert_true(
    try {
      ignore(@wfc.solve_rules(invalid, 1, 1))
      false
    } catch {
      _ => true
    },
  )
}
