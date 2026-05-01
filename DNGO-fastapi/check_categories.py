from sqlalchemy import create_engine, text

engine = create_engine('postgresql://dtrinh:DNgodue@207.180.233.84:5432/dngo')

with engine.connect() as conn:
    # Check Category table
    result = conn.execute(text('SELECT category_id, category_name FROM "Category" ORDER BY category_name LIMIT 30'))
    rows = result.fetchall()
    print(f'=== BANG Category: {len(rows)} records ===')
    for r in rows:
        print(f'  {r[0]} | {r[1]}')
    
    # Check Ingredient count
    result2 = conn.execute(text('SELECT COUNT(*) FROM "Ingredient"'))
    count = result2.scalar()
    print(f'\n=== BANG Ingredient: {count} records ===')
