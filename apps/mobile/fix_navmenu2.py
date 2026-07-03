path = "lib/shared/ideal_ui.dart"
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

old_imports = """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/router/app_router.dart';"""
new_imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/router/app_router.dart';
import '../core/locale/app_strings.dart';
import '../core/locale/locale_provider.dart';"""
assert old_imports in src, "imports marker introuvable"
src = src.replace(old_imports, new_imports, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("OK - imports ajoutes")
