///|
test "budget exhaustion is typed and never a proof of unsatisfiability" {
  let model : @wfc.RuleModel = {
    labels: ["a", "b"],
    weights: [1.0, 1.0],
    neighbors: Array::makei(2, _ => Array::makei(4, _ => [0, 1])),
  }
  assert_true(
    try {
      ignore(@wfc.solve_rules(model, 8, 8, budget=1))
      false
    } catch {
      @wfc.BudgetExhausted => true
      _ => false
    },
  )
  assert_eq(
    @wfc.solve_rules(model, 1, 1, restrictions=[(0, [0]), (0, [1])]),
    None,
  )
  let result = @wfc.solve_rules(model, 1, 1, restrictions=[
    (0, [0, 1]),
    (0, [1]),
  ]).unwrap()
  assert_true(
    result.validate_rules(model, restrictions=[(0, [0, 1]), (0, [1])]),
  )
  assert_false(result.validate_rules(model, restrictions=[(0, [0])]))
  assert_false(result.validate_rules(model, restrictions=[(0, [1, 2])]))
}

///|
test "repeated restrictions are merged and bounded before wave work" {
  let n = 1024
  let neighbors = Array::makei(n, i => Array::makei(4, _ => [i]))
  let model : @wfc.RuleModel = {
    labels: Array::makei(n, i => i.to_string()),
    weights: Array::make(n, 1.0),
    neighbors,
  }
  let many = Array::make(5000, (0, [7]))
  let result = @wfc.solve_rules(model, 1, 1, restrictions=many, budget=10000).unwrap()
  assert_eq(result.tiles, [7])
  assert_true(
    try {
      ignore(
        @wfc.solve_rules(model, 1, 1, restrictions=Array::make(65537, (0, []))),
      )
      false
    } catch {
      @wfc.Invalid(_) => true
      _ => false
    },
  )
}
