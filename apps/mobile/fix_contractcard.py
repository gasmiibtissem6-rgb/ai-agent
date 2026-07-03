import re

path = "lib/features/deal/presentation/contracts_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

# 1. Remplacer le bricolage staticTr par une vraie méthode _tr locale à la classe
old_labels = """    final labels = {'DRAFT': _ContractsScreenState().staticTr(ref, 'myContracts_status_draft'), 'SENT': _ContractsScreenState().staticTr(ref, 'myContracts_status_sent'), 'SIGNED': _ContractsScreenState().staticTr(ref, 'myContracts_status_signed'), 'CANCELLED': _ContractsScreenState().staticTr(ref, 'myContracts_status_cancelled')};"""
new_labels = """    final labels = {'DRAFT': _tr('myContracts_status_draft'), 'SENT': _tr('myContracts_status_sent'), 'SIGNED': _tr('myContracts_status_signed'), 'CANCELLED': _tr('myContracts_status_cancelled')};"""
assert old_labels in src, "labels marker introuvable"
src = src.replace(old_labels, new_labels, 1)

# 2. Ajouter la méthode _tr juste après le constructeur de _ContractCard
old_ctor = """  const _ContractCard({required this.ref, required this.contract, required this.onTap});"""
new_ctor = """  const _ContractCard({required this.ref, required this.contract, required this.onTap});

  String _tr(String key) => AppStrings.get(ref.watch(localeProvider).languageCode, key);"""
assert old_ctor in src, "constructeur marker introuvable"
src = src.replace(old_ctor, new_ctor, 1)

# 3. Corriger l'appel _ContractCard(...) pour lui passer ref: ref si ce n'est pas déjà fait
def fix_call(match):
    block = match.group(0)
    if "ref:" in block:
        return block
    return block.replace("_ContractCard(", "_ContractCard(\n                    ref: ref,", 1)

src_new = re.sub(r"_ContractCard\(\s*\n(?:.*\n)*?\s*\),", fix_call, src, count=1)
if src_new == src:
    print("ATTENTION: aucun appel _ContractCard(...) modifié automatiquement, verification manuelle necessaire")
else:
    src = src_new

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("OK - ContractCard traduit")
