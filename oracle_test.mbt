///|
test "solver agrees with exhaustive oracle for all two-tile directional models" {
  // 16 possible east relations x 16 possible south relations = 256 models.
  // Check all 16 assignments of a 2x2 grid independently of propagation/search.
  for east in 0..<16 {
    for south in 0..<16 {
      let allowed = Array::makei(2, _ => Array::make(4, 0))
      for a in 0..<2 {
        for b in 0..<2 {
          if (east & (1 << (a * 2 + b))) != 0 {
            allowed[a][0] = allowed[a][0] | (1 << b)
            allowed[b][2] = allowed[b][2] | (1 << a)
          }
          if (south & (1 << (a * 2 + b))) != 0 {
            allowed[a][1] = allowed[a][1] | (1 << b)
            allowed[b][3] = allowed[b][3] | (1 << a)
          }
        }
      }
      let model : @wfc.Model = { labels: ["0", "1"], allowed, }
      let mut possible = false
      for assignment in 0..<16 {
        let a = assignment & 1
        let b = (assignment >> 1) & 1
        let c = (assignment >> 2) & 1
        let d = (assignment >> 3) & 1
        if (east & (1 << (a * 2 + b))) != 0 &&
          (east & (1 << (c * 2 + d))) != 0 &&
          (south & (1 << (a * 2 + c))) != 0 &&
          (south & (1 << (b * 2 + d))) != 0 {
          possible = true
        }
      }
      assert_eq(@wfc.solve(model, 2, 2) is Some(_), possible)
    }
  }
}
