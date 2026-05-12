
int durationToMinutes(String duration) {
  final parts = duration.split(':');
  if (parts.length != 2) return 10;

  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;

  return (hours * 60) + minutes;
}
