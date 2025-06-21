#!/usr/bin/env python3
"""
Preprocesses large Hanzi databases into a compact SQLite database for the app.
Run this script once to prepare your data files.

Usage: python preprocess_data.py --mmah /path/to/makemeahanzi --cedict /path/to/cedict --unihan /path/to/unihan
"""

import json
import sqlite3
import argparse
import os
import re
from collections import defaultdict

def create_database(db_path):
    """Create SQLite database with tables"""
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    
    # Characters table
    c.execute('''CREATE TABLE IF NOT EXISTS characters (
        id INTEGER PRIMARY KEY,
        character TEXT UNIQUE NOT NULL,
        pinyin TEXT,
        meanings TEXT,
        stroke_count INTEGER,
        stroke_order TEXT,
        svg_path TEXT,
        radical TEXT,
        frequency INTEGER DEFAULT 0
    )''')
    
    # Character sets table
    c.execute('''CREATE TABLE IF NOT EXISTS character_sets (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        level TEXT,
        characters TEXT
    )''')
    
    # Create indices
    c.execute('CREATE INDEX IF NOT EXISTS idx_character ON characters(character)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_frequency ON characters(frequency DESC)')
    
    conn.commit()
    return conn

def process_makemeahanzi(mmah_path, conn):
    """Process MakeMeAHanzi dictionary.txt"""
    print("Processing MakeMeAHanzi...")
    c = conn.cursor()
    
    dict_path = os.path.join(mmah_path, 'dictionary.txt')
    if not os.path.exists(dict_path):
        print(f"Warning: {dict_path} not found")
        return
    
    with open(dict_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                data = json.loads(line.strip())
                character = data.get('character', '')
                
                # Extract stroke order from strokes data
                strokes = data.get('strokes', [])
                stroke_order = json.dumps(strokes)
                
                # Check if SVG exists
                svg_path = f"svgs/{ord(character):05d}.svg" if character else None
                
                c.execute('''INSERT OR IGNORE INTO characters 
                    (character, stroke_count, stroke_order, svg_path) 
                    VALUES (?, ?, ?, ?)''',
                    (character, len(strokes), stroke_order, svg_path))
            except Exception as e:
                print(f"Error processing line: {e}")
    
    conn.commit()
    print(f"Processed MakeMeAHanzi")

def process_cedict(cedict_path, conn):
    """Process CEDICT file"""
    print("Processing CEDICT...")
    c = conn.cursor()
    
    if not os.path.exists(cedict_path):
        print(f"Warning: {cedict_path} not found")
        return
    
    with open(cedict_path, 'r', encoding='utf-8') as f:
        for line in f:
            if line.startswith('#'):
                continue
                
            match = re.match(r'^(\S+)\s+(\S+)\s+\[([^\]]+)\]\s+/(.+)/$', line.strip())
            if match:
                trad, simp, pinyin, meanings = match.groups()
                
                # Process both traditional and simplified
                for char in simp:
                    if len(char) == 1 and '\u4e00' <= char <= '\u9fff':
                        meanings_list = [m.strip() for m in meanings.split('/')]
                        meanings_json = json.dumps(meanings_list[:5])  # Limit to 5 meanings
                        
                        c.execute('''UPDATE characters 
                            SET pinyin = ?, meanings = ? 
                            WHERE character = ?''',
                            (pinyin.lower(), meanings_json, char))
    
    conn.commit()
    print("Processed CEDICT")

def process_unihan_readings(unihan_path, conn):
    """Process Unihan readings file"""
    print("Processing Unihan readings...")
    c = conn.cursor()
    
    readings_path = os.path.join(unihan_path, 'Unihan_Readings.txt')
    if not os.path.exists(readings_path):
        print(f"Warning: {readings_path} not found")
        return
    
    with open(readings_path, 'r', encoding='utf-8') as f:
        for line in f:
            if line.startswith('#') or not line.strip():
                continue
                
            parts = line.strip().split('\t')
            if len(parts) >= 3:
                codepoint = parts[0]
                field = parts[1]
                value = parts[2]
                
                if field == 'kMandarin':
                    try:
                        char = chr(int(codepoint[2:], 16))
                        c.execute('''UPDATE characters 
                            SET pinyin = COALESCE(pinyin, ?) 
                            WHERE character = ?''',
                            (value.lower(), char))
                    except:
                        pass
    
    conn.commit()
    print("Processed Unihan readings")

def create_hsk_sets(conn):
    """Create HSK character sets"""
    print("Creating HSK character sets...")
    c = conn.cursor()
    
    # Sample HSK1 characters (you can expand this)
    hsk_sets = [
        {
            'name': 'HSK 1',
            'description': 'Basic 150 characters for beginners',
            'level': 'HSK1',
            'characters': ['我', '你', '他', '她', '们', '的', '了', '是', '不', '在', '有', '这', '个', '上', '大', '中', '小', '来', '去', '说']
        },
        {
            'name': 'Numbers',
            'description': 'Chinese numbers 0-10',
            'level': 'Beginner',
            'characters': ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十']
        },
        {
            'name': 'Basic Radicals',
            'description': 'Common radicals',
            'level': 'Beginner',
            'characters': ['人', '口', '手', '心', '水', '火', '木', '金', '土', '日', '月']
        }
    ]
    
    for hsk_set in hsk_sets:
        c.execute('''INSERT INTO character_sets (name, description, level, characters)
            VALUES (?, ?, ?, ?)''',
            (hsk_set['name'], hsk_set['description'], hsk_set['level'], 
             json.dumps(hsk_set['characters'])))
    
    conn.commit()
    print("Created character sets")

def main():
    parser = argparse.ArgumentParser(description='Preprocess Hanzi databases')
    parser.add_argument('--mmah', help='Path to MakeMeAHanzi directory')
    parser.add_argument('--cedict', help='Path to CEDICT file')
    parser.add_argument('--unihan', help='Path to Unihan directory')
    parser.add_argument('--output', default='hanzi.db', help='Output database file')
    
    args = parser.parse_args()
    
    # Create database
    conn = create_database(args.output)
    
    # Process each data source
    if args.mmah:
        process_makemeahanzi(args.mmah, conn)
    
    if args.cedict:
        process_cedict(args.cedict, conn)
    
    if args.unihan:
        process_unihan_readings(args.unihan, conn)
    
    # Create character sets
    create_hsk_sets(conn)
    
    # Update character frequencies (you can add actual frequency data later)
    c = conn.cursor()
    c.execute('UPDATE characters SET frequency = RANDOM() % 1000')
    
    conn.commit()
    conn.close()
    
    print(f"\nDatabase created: {args.output}")
    print("Copy this file to your Flutter app's assets folder")

if __name__ == '__main__':
    main()