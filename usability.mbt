///|
/// Legacy model validation adapter.
pub fn Solution::validate(
  self : Solution,
  model : Model,
  pins? : Array[(Int, Int)] = [],
  periodic? : Bool = false,
) -> Bool {
  self.validate_rules(model.to_rules(), pins~, periodic~) catch {
    _ => false
  }
}
