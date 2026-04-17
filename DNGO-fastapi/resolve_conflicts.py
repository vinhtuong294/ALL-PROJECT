import re
import os

def resolve_file(filepath, strategy):
    # strategy: 'head', 'branch', 'both', 'custom'
    if not os.path.exists(filepath): return
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    out = []
    state = 0 # 0=normal, 1=head, 2=branch
    for line in lines:
        if line.startswith('<<<<<<< HEAD'):
            state = 1
            continue
        elif line.startswith('======='):
            state = 2
            continue
        elif line.startswith('>>>>>>>'):
            state = 0
            continue
            
        if state == 0:
            out.append(line)
        elif state == 1:
            if strategy in ('head', 'both'):
                out.append(line)
        elif state == 2:
            if strategy in ('branch', 'both'):
                out.append(line)
                
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(out)

def fix_cart():
    # Similar to order, but we want HEAD for most, except total_amount=int(total_amount)
    with open('app/repositories/cart.py', 'r', encoding='utf-8') as f:
        text = f.read()
    text = re.sub(r'<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>>', r'\1', text, flags=re.DOTALL)
    text = text.replace('total_amount=total_amount,', 'total_amount=int(total_amount),')
    text = text.replace('order.total_amount = total_amount', 'order.total_amount = int(total_amount)')
    text = text.replace('db.rollback()', '')
    with open('app/repositories/cart.py', 'w', encoding='utf-8') as f:
        f.write(text)

def fix_wallet_repo():
    with open('app/repositories/wallet.py', 'r', encoding='utf-8') as f:
        lines = f.readlines()
    out = []
    state = 0
    conflict_idx = 0
    for line in lines:
        if line.startswith('<<<<<<< HEAD'):
            state = 1
            conflict_idx += 1
            continue
        elif line.startswith('======='):
            state = 2
            continue
        elif line.startswith('>>>>>>>'):
            state = 0
            continue
            
        if state == 0:
            out.append(line)
        else:
            # Which conflicts?
            # 1: func.coalesce, tien_dang_cho_rut -> want branch (state=2)
            # 2: _seller_balance order status -> want branch (state=2)
            # 3: _seller_balance gross/net -> want HEAD (state=1)
            # 4: _shipper_balance order status -> want branch (state=2)
            # 5: _shipper_balance gross/net -> want HEAD (state=1)
            # 6: request_withdraw -> want branch (state=2)
            if conflict_idx == 1:
                if state == 2: out.append(line)
            elif conflict_idx == 2:
                if state == 2: out.append(line)
            elif conflict_idx == 3:
                if state == 1: out.append(line)
            elif conflict_idx == 4:
                if state == 2: out.append(line)
            elif conflict_idx == 5:
                if state == 1: out.append(line)
            elif conflict_idx == 6:
                if state == 2: out.append(line)
                
    with open('app/repositories/wallet.py', 'w', encoding='utf-8') as f:
        f.writelines(out)

def fix_market_repo():
    with open('app/repositories/market_management.py', 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Due to copy-paste conflict style:
    with open('app/repositories/market_management.py', 'w', encoding='utf-8') as f:
        state = 0
        head_funcs = []
        for line in lines:
            if line.startswith('<<<<<<< HEAD'):
                state = 1
                continue
            elif line.startswith('======='):
                state = 2
                continue
            elif line.startswith('>>>>>>>'):
                state = 0
                continue
                
            if state == 0:
                pass # usually empty
            elif state == 1:
                # gather head functions
                head_funcs.append(line)
            elif state == 2:
                # this is the main branch file content
                f.write(line)
        f.write("\n")
        
        # head_funcs contains the entire HEAD file. We only want list_pending_sellers and approve_seller
        head_text = "".join(head_funcs)
        match = re.search(r'(def list_pending_sellers.*)', head_text, re.DOTALL)
        if match:
            f.write(match.group(1))

def fix_shipper_router():
    with open('app/routers/shipper.py', 'r', encoding='utf-8') as f:
        lines = f.readlines()
    out = []
    state = 0
    conflict_idx = 0
    for line in lines:
        if line.startswith('<<<<<<< HEAD'):
            state = 1
            conflict_idx += 1
            continue
        elif line.startswith('======='):
            state = 2
            continue
        elif line.startswith('>>>>>>>'):
            state = 0
            continue
            
        if state == 0:
            out.append(line)
        else:
            if conflict_idx == 6: # the big one with optimize_route (head) and dashboard/etc (branch)
                out.append(line) # keep both
            elif conflict_idx == 4: # optimize_route_body definitions - keep both
                out.append(line)
            else:
                if state == 2: out.append(line)
                
    with open('app/routers/shipper.py', 'w', encoding='utf-8') as f:
        f.writelines(out)

resolve_file('README.md', 'head')
resolve_file('app/database.py', 'head')
resolve_file('app/utils/notification.py', 'head')
resolve_file('app/utils/scheduler.py', 'branch')
resolve_file('app/schemas/merchant.py', 'both')
resolve_file('app/schemas/wallet.py', 'both')
resolve_file('app/models/models.py', 'both')
resolve_file('app/repositories/order.py', 'head')
resolve_file('app/repositories/seller.py', 'branch')
resolve_file('app/repositories/shipper.py', 'head')
resolve_file('app/utils/distance.py', 'head')

fix_cart()
fix_wallet_repo()
fix_market_repo()
fix_shipper_router()

# Simple ones left
resolve_file('app/routers/market_management.py', 'both')
resolve_file('app/routers/wallet.py', 'both')
