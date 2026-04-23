"""
Script giả lập Shipper đang giao hàng.
Đẩy tọa độ GPS lên Firebase Realtime Database mỗi 3 giây.
Chạy: python test_firebase_tracking.py
"""
import sys, os, time, math

# Đảm bảo tìm được các module trong dự án
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from dotenv import load_dotenv
load_dotenv()

from app.firebase_client import init_firebase, get_db_ref

# ========================================================
# CẤU HÌNH - Nhập mã đơn hàng khi chạy script
# ========================================================
if len(sys.argv) > 1:
    ORDER_ID = sys.argv[1]           # Trường hợp: python test_firebase_tracking.py DH20250416xyz
else:
    ORDER_ID = input("Nhập mã đơn hàng cần giả lập (Enter để dùng TEST_ORDER_001): ").strip()
    if not ORDER_ID:
        ORDER_ID = "TEST_ORDER_001"

STEPS    = 20     # Số bước di chuyển
INTERVAL = 3      # Giây giữa mỗi lần update


def simulate_shipper():
    print("🔥 Đang kết nối Firebase...")
    init_firebase()
    print("✅ Kết nối thành công!\n")

    # Tọa độ bắt đầu (Khu vực Đà Nẵng - gần Chợ Bắc Mỹ An)
    start_lat = 16.0450
    start_lng = 108.2200

    # Tọa độ kết thúc (giả lập đi đến địa chỉ giao hàng)
    end_lat   = 16.0544
    end_lng   = 108.2022

    ref = get_db_ref(f"tracking/{ORDER_ID}")

    print(f"🚗 Bắt đầu giả lập shipper giao đơn: [{ORDER_ID}]")
    print(f"   Từ: ({start_lat}, {start_lng})")
    print(f"   Đến: ({end_lat}, {end_lng})")
    print(f"   Tổng {STEPS} bước, mỗi {INTERVAL}s\n")
    print("👉 Mở Firebase Console → Realtime Database để xem tọa độ nhảy!\n")
    print("-" * 50)

    for i in range(STEPS + 1):
        progress = i / STEPS
        # Nội suy tuyến tính giữa điểm đầu và điểm cuối
        lat = start_lat + (end_lat - start_lat) * progress
        lng = start_lng + (end_lng - start_lng) * progress

        # Thêm chút nhiễu nhỏ cho tự nhiên hơn
        lat += math.sin(i * 0.5) * 0.0002
        lng += math.cos(i * 0.5) * 0.0002

        try:
            ref.set({
                "lat": round(lat, 6),
                "lng": round(lng, 6),
                "heading": 315,
                "speed": 8.5,
                "updated_at": int(time.time() * 1000),
            })
            print(f"  ✅ Bước {i+1:02d}/{STEPS}: lat={lat:.6f}, lng={lng:.6f}")
        except Exception as e:
            print(f"  ❌ Lỗi bước {i+1}: {e}")

        if i < STEPS:
            time.sleep(INTERVAL)

    # Dọn dẹp sau khi xong
    ref.delete()
    print("\n")
    print("=" * 50)
    print("🏁 Giả lập xong! Node tracking đã được xóa.")
    print("✅ Firebase Realtime Database hoạt động tốt!")


if __name__ == "__main__":
    simulate_shipper()
