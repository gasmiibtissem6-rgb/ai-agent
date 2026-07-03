path = "lib/features/deal/presentation/contracts_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

old = """  @override
  Widget build(BuildContext context) {
    final filtered = _contracts.where((c) {"""
new = """  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
    final filtered = _contracts.where((c) {"""
assert old in src, "marker introuvable"
src = src.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("OK - Consumer ouvert")
