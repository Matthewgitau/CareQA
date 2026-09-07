/// Returns [value] only when it is also present in [itemValues]; otherwise null.
///
/// Prevents the Flutter assertion:
///   "There should be exactly one item with [DropdownButtonFormField]'s value"
/// which fires when a dropdown is bound to an id that isn't currently in its
/// item list (stale / empty / org-filtered list, or an id arriving from a
/// different source than the items).
T? safeDropdownValue<T>(T? value, List<T?> itemValues) {
  if (value == null) return null;
  if (itemValues.contains(value)) return value;
  return null;
}