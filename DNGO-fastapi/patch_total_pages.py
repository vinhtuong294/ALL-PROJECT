#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Patch total_pages bug in market_management.py repository"""
with open('app/repositories/market_management.py', 'r', encoding='utf-8') as f:
    content = f.read()

# The list_tieu_thuong has: "total_pages": (total + limit - 1) // limit
old = '"total_pages": (total + limit - 1) // limit'
new = '"total_pages": max(1, (total + limit - 1) // limit)'

count = content.count(old)
print(f'Found {count} occurrences')
content = content.replace(old, new)  # Replace all (list_stall_fees already has max(1,...))

with open('app/repositories/market_management.py', 'w', encoding='utf-8') as f:
    f.write(content)

print('Patch applied OK')

# Verify
with open('app/repositories/market_management.py', 'r', encoding='utf-8') as f:
    content2 = f.read()
    remaining = content2.count('"total_pages": (total + limit - 1)')
    print(f'Remaining unpatched: {remaining}')
    patched = content2.count('"total_pages": max(1,')
    print(f'Patched occurrences: {patched}')
