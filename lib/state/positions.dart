const kPositionGap = 16384.0;

double positionBetween(double? before, double? after) {
  if (before == null && after == null) return kPositionGap;
  if (after == null) return before! + kPositionGap;
  if (before == null) return after / 2;
  return (before + after) / 2;
}
