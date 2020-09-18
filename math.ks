
function clamp {
  parameter x_min.
  parameter x.
  parameter x_max.
  return min(x_max, max(x, x_min)).
}
