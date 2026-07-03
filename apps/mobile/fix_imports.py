path = "lib/features/deal/presentation/contracts_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    src = f.read()

old = """import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';"""
new = """import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';"""
assert old in src, "marker introuvable"
src = src.replace(old, new, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(src)

print("OK - import ajoute")
