path = "lib/core/locale/app_strings.dart"
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

old1 = "'myContracts_title': 'Mes Contrats', 'myContracts_status_cancelled': 'Annulé',"
new1 = "'myContracts_status_cancelled': 'Annulé',"
assert old1 in src, "marker FR introuvable"
src = src.replace(old1, new1, 1)

old2 = "'myContracts_title': 'My Contracts', 'myContracts_status_cancelled': 'Cancelled',"
new2 = "'myContracts_status_cancelled': 'Cancelled',"
assert old2 in src, "marker EN introuvable"
src = src.replace(old2, new2, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("OK - doublons supprimes")
