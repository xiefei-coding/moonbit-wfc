///|
fn object(value : Json) -> Map[String, Json] raise SolveError {
  match value {
    Object(items) => items
    _ => raise Invalid("expected object")
  }
}

///|
fn array(value : Json) -> Array[Json] raise SolveError {
  match value {
    Array(items) => items
    _ => raise Invalid("expected array")
  }
}

///|
fn number(value : Json) -> Double raise SolveError {
  match value {
    Number(n, ..) =>
      if n == n && n >= -1.0e300 && n <= 1.0e300 {
        n
      } else {
        raise Invalid("nonfinite number")
      }
    _ => raise Invalid("expected number")
  }
}

///|
fn integer(value : Json) -> Int raise SolveError {
  let n = number(value)
  if n < -2147483648.0 || n > 2147483647.0 || n != n.to_int().to_double() {
    raise Invalid("expected signed 32-bit integer")
  }
  n.to_int()
}

///|
fn string(value : Json) -> String raise SolveError {
  match value {
    String(s) => s
    _ => raise Invalid("expected string")
  }
}

///|
fn boolean(value : Json) -> Bool raise SolveError {
  match value {
    True => true
    False => false
    _ => raise Invalid("expected boolean")
  }
}

///|
fn required(items : Map[String, Json], key : String) -> Json raise SolveError {
  match items.get(key) {
    Some(value) => value
    None => raise Invalid("missing field: " + key)
  }
}

///|
fn read_rules(value : Json) -> RuleModel raise SolveError {
  let items = object(value)
  let labels = array(required(items, "labels")).map(string)
  let weights = if items.get("weights") is Some(values) {
    array(values).map(number)
  } else {
    Array::make(labels.length(), 1.0)
  }
  let neighbors = array(required(items, "neighbors")).map(row => {
    array(row).map(list => array(list).map(integer))
  })
  { labels, neighbors, weights, }
}

///|
fn run_request(input : String) -> Json raise {
  if input.length() > 16000000 {
    raise Invalid("JSON request limit")
  }
  let job = object(@json.parse(input))
  let mode = string(job.get("mode").unwrap_or("overlap"))
  let width = integer(job.get("width").unwrap_or(32))
  let height = integer(job.get("height").unwrap_or(32))
  let seed_value = number(job.get("seed").unwrap_or(1))
  if seed_value < 0.0 ||
    seed_value > 4294967295.0 ||
    seed_value != seed_value.to_int64().to_double() {
    raise Invalid("seed must be UInt32")
  }
  let seed = seed_value.to_int64().to_int().reinterpret_as_uint()
  let periodic = boolean(job.get("periodic").unwrap_or(false.to_json()))
  let budget = integer(job.get("budget").unwrap_or(10000000))
  let pins = array(job.get("pins").unwrap_or([])).map(pair => {
    let values = array(pair)
    if values.length() != 2 {
      raise Invalid("pin must be [cell,tile]")
    }
    (integer(values[0]), integer(values[1]))
  })
  if mode == "learn" || mode == "overlap" {
    let sample = array(required(job, "sample")).map(integer)
    let sample_width = integer(required(job, "sampleWidth"))
    let sample_height = integer(required(job, "sampleHeight"))
    let size = integer(job.get("size").unwrap_or(3))
    let symmetry = integer(job.get("symmetry").unwrap_or(1))
    let periodic_input = boolean(
      job.get("periodicInput").unwrap_or(true.to_json()),
    )
    let model = learn_patterns(
      sample,
      sample_width,
      sample_height,
      size,
      symmetry~,
      periodic_input~,
    )
    if mode == "learn" {
      return { "ok": true.to_json(), "model": ToJson::to_json(model) }
    }
    let pixels = model.generate(
      width,
      height,
      seed~,
      periodic~,
      pins~,
      ground=boolean(job.get("ground").unwrap_or(false.to_json())),
      budget~,
    )
    return match pixels {
      None => { "ok": true.to_json(), "status": "unsat" }
      Some(pixels) =>
        {
          "ok": true.to_json(),
          "status": "solved",
          "width": width.to_json(),
          "height": height.to_json(),
          "pixels": pixels.to_json(),
          "patternCount": model.patterns.length().to_json(),
        }
    }
  }
  let tiled : TiledModel? = if mode == "expand" || mode == "tiled" {
    let definitions = array(required(job, "tiles")).map(value => {
      let items = object(value)
      let pixels = array(required(items, "pixels")).map(values => {
        array(values).map(integer)
      })
      TileDefinition::{
        name: string(required(items, "name")),
        symmetry: string(items.get("symmetry").unwrap_or("X")),
        weight: number(items.get("weight").unwrap_or(1)),
        pixels,
      }
    })
    let neighbors = array(required(job, "neighbors")).map(pair => {
      let pair = array(pair)
      if pair.length() != 2 {
        raise Invalid("neighbor must be [left,right]")
      }
      (string(pair[0]), string(pair[1]))
    })
    let subset = array(job.get("subset").unwrap_or([])).map(string)
    Some(
      expand_tiles(
        definitions,
        integer(required(job, "tileSize")),
        neighbors,
        subset~,
      ),
    )
  } else {
    None
  }
  if mode == "expand" {
    return { "ok": true.to_json(), "model": ToJson::to_json(tiled.unwrap()) }
  }
  let model = if tiled is Some(tiled) {
    tiled.rules
  } else if mode == "rules" || mode == "validate" {
    read_rules(required(job, "model"))
  } else {
    raise Invalid("unknown request mode")
  }
  if mode == "validate" {
    let solution : Solution = {
      width,
      height,
      tiles: array(required(job, "tiles")).map(integer),
      decisions: 0,
      backtracks: 0,
    }
    return {
      "ok": true.to_json(),
      "valid": solution.validate_rules(model, pins~, periodic~).to_json(),
    }
  }
  let solution = solve_rules(
    model,
    width,
    height,
    seed~,
    periodic~,
    budget~,
    pins~,
  )
  match solution {
    None => { "ok": true.to_json(), "status": "unsat" }
    Some(solution) => {
      let result : Map[String, Json] = {
        "ok": true.to_json(),
        "status": "solved",
        "solution": ToJson::to_json(solution),
      }
      if tiled is Some(tiled) {
        result["pixels"] = tiled.render(solution).to_json()
        result["width"] = (width * tiled.tile_size).to_json()
        result["height"] = (height * tiled.tile_size).to_json()
      }
      result.to_json()
    }
  }
}

///|
/// Numeric-pixel/file-independent request interface shared by the Node worker and
/// browser worker. File decoding belongs to the host; solving remains MoonBit.
pub fn evaluate_json(input : String) -> String {
  (run_request(input) catch {
    e => { "ok": false.to_json(), "error": Repr(e).to_string().to_json() }
  }).stringify()
}
