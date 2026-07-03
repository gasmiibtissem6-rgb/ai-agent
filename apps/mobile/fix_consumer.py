path = "lib/features/deal/presentation/contracts_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

old = """      ),
    );
  }
}

class _ContractCard"""
new = """      ),
    );
    });
  }
}

class _ContractCard"""
assert old in src, "marker introuvable"
src = src.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("OK - Consumer ferme")
