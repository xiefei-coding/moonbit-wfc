///|
/// Text sample bridge: one Unicode character per symbol, newline-separated rows.
pub fn overlap(
  sample : String,
  size : Int,
  width : Int,
  height : Int,
  seed : UInt,
  periodic : Bool,
  symmetry : Bool,
) -> String {
  try {
    let rows = sample.split("\n").map(r => r.to_owned().to_array()).collect()
    if rows.is_empty() || rows[0].is_empty() {
      raise Failure("empty sample")
    }
    let sample_width = rows[0].length()
    let symbols : Array[Int] = []
    for row in rows {
      if row.length() != sample_width {
        raise Failure("sample rows must have equal widths")
      }
      for c in row {
        symbols.push(c.to_int())
      }
    }
    let model = @lib.learn_overlap(
      symbols,
      sample_width,
      rows.length(),
      size,
      symmetry~,
    )
    match model.generate(width, height, seed~, periodic~) {
      None => "UNSAT"
      Some(output) => {
        let text = StringBuilder()
        for i, symbol in output {
          if i > 0 && i % width == 0 {
            text.write_char('\n')
          }
          text.write_char(symbol.unsafe_to_char())
        }
        text.to_string()
      }
    }
  } catch {
    e => "ERROR: " + Repr(e).to_string()
  }
}
