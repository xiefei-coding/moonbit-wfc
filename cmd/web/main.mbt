///|
pub fn run(input : String) -> String {
  try {
    let mut seed = 0L
    let text = input.trim().to_owned()
    if text == "" || text.length() > 10 {
      raise Failure("seed must be an unsigned 32-bit integer")
    }
    for c in text.iter() {
      if c < '0' || c > '9' {
        raise Failure("seed must contain decimal digits")
      }
      seed = seed * 10L + (c.to_int() - 48).to_int64()
    }
    if seed > 4294967295L {
      raise Failure("seed overflow")
    }
    let model : @lib.Model = {
      labels: ["~", ".", "^"],
      allowed: [[3, 3, 3, 3], [7, 7, 7, 7], [6, 6, 6, 6]],
    }
    let result = @lib.solve(
      model,
      16,
      12,
      seed=seed.to_int().reinterpret_as_uint(),
      pins=[(0, 0), (191, 2)],
    ).unwrap()
    result.render(model) +
    "\n\nDecisions: \{result.decisions}; backtracks: \{result.backtracks}"
  } catch {
    e => "ERROR: " + Repr(e).to_string()
  }
}

///|
fn main {

}
