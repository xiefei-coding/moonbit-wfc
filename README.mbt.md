# 可执行 API 示例

增加解的尺寸、tile、pin 和四方向邻接约束验证。这些例子调用公开 API，并随 `moon test` 执行。

```mbt check
///|
test "validate solver result and externally altered tiles" {
  let m = @wfc.Model::{
    labels: ["a", "b"],
    allowed: [[3, 3, 3, 3], [3, 3, 3, 3]],
  }
  match @wfc.solve(m, 3, 3, pins=[(0, 1)]) {
    Some(s) => {
      assert_true(s.validate(m, pins=[(0, 1)]))
      assert_true(!s.validate(m, pins=[(0, 0)]))
      s.tiles[0] = 99
      assert_true(!s.validate(m))
    }
    None => fail("expected solution")
  }
}
```

限制：非完整 overlapping model；没有交互式素材导入与大图性能证明。
