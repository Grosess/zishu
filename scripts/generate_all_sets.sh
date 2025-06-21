#!/bin/bash

# Script to generate all character sets from MakeMeAHanzi database
# Run this from the project root directory

echo "Generating character sets from MakeMeAHanzi database..."

# Create output directory
mkdir -p assets/character_sets

# Generate number set
echo "Generating numbers set..."
dart tools/generate_character_set.dart "一二三四五六七八九十" assets/character_sets/numbers.json

# Generate basic strokes set
echo "Generating basic strokes set..."
dart tools/generate_character_set.dart "一丨丿丶乙" assets/character_sets/basic_strokes.json

# Generate simple characters set
echo "Generating simple characters set..."
dart tools/generate_character_set.dart "人大小上下左右中" assets/character_sets/simple_chars.json

# Generate nature elements set
echo "Generating nature elements set..."
dart tools/generate_character_set.dart "山水火土木金日月风雨" assets/character_sets/nature.json

# Generate body parts set
echo "Generating body parts set..."
dart tools/generate_character_set.dart "口目耳手心头足身" assets/character_sets/body_parts.json

# Generate directions set
echo "Generating directions set..."
dart tools/generate_character_set.dart "东南西北上下左右前后" assets/character_sets/directions.json

# Generate time related set
echo "Generating time related set..."
dart tools/generate_character_set.dart "年月日时分早晚今明昨" assets/character_sets/time.json

# Generate family members set
echo "Generating family members set..."
dart tools/generate_character_set.dart "父母兄弟姐妹儿女爷奶" assets/character_sets/family.json

# Generate colors set
echo "Generating colors set..."
dart tools/generate_character_set.dart "红黄蓝绿黑白紫橙灰棕" assets/character_sets/colors.json

# Generate animals set
echo "Generating animals set..."
dart tools/generate_character_set.dart "马牛羊鸡狗猪猫鱼鸟虫" assets/character_sets/animals.json

# Combine all sets into a master file
echo "Creating master character database..."
dart tools/combine_character_sets.dart

echo "Done! Character sets generated in assets/character_sets/"