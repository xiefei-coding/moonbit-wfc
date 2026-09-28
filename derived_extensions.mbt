///|
pub extend OverlapModel with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend PatternModel with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend PatternModel with ToJson::{to_json}

///|
pub extend RuleModel with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend RuleModel with ToJson::{to_json}

///|
pub extend SolveError with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Model with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Solution with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend Solution with Eq::{not_equal, equal}

///|
pub extend Solution with ToJson::{to_json}

///|
pub extend TileDefinition with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend TileDefinition with ToJson::{to_json}

///|
pub extend TiledModel with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub extend TiledModel with ToJson::{to_json}
