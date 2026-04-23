# DNGO - Mô hình chợ Online đa đối tác

Dự án bao gồm 4 thành phần chính:
1. **Backend API** (`DNGO-fastapi`)
2. **App Người Mua & Người Bán** (`Done-demo`)
3. **App Vận Chuyển** (`dngo_shipper_app`)
4. **Module AI Chatbot/RAG** (`LLM-master`)

Dưới đây là hướng dẫn setup chuẩn để hệ thống có thể hoạt động đồng bộ.

---

## 1. Backend API (`DNGO-fastapi`)
Backend được xây dựng bằng Python (FastAPI). Để hệ thống hoạt động, bạn cần cấu hình database và môi trường.

*   **Bước 1:** Cài đặt Python 3.12+ và khởi tạo môi trường ảo:
    ```bash
    cd DNGO-fastapi
    python -m venv venv
    venv\Scripts\activate  # (Trên Windows)
    pip install -r requirements.txt
    ```
*   **Bước 2:** Cấu hình file `.env`. Trong file `.env`, đảm bảo các biến sau đang trỏ đúng:
    *   `DATABASE_URL=postgresql://dtrinh:DNgodue@207.180.233.84:5432/dngo` (Database thật của nhóm đang host).
    *   `SECRET_KEY` và `ALGORITHM` (Dùng cho JWT Token).
    *   Các thông tin tích hợp `VNPAY` (vnp_TmnCode, vnp_HashSecret,...).
*   **Bước 3:** Cấu hình Firebase. Bỏ file chứng chỉ (Service Account key json) vào thư mục gốc của backend và cấu hình đường dẫn tới file đó trong `.env` (ví dụ: `FIREBASE_CREDENTIALS=...`). Điều này giúp server gửi được Realtime Notification.
*   **Bước 4:** Khởi chạy server:
    ```bash
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
    ```
    *API sẽ chạy tại `http://localhost:8000`. Bạn có thể truy cập `http://localhost:8000/docs` để xem Swagger UI.*

---

## 2. App Người Mua & Người Bán (`Done-demo`)
Frontend chính của hệ thống được viết bằng Flutter.

*   **Bước 1:** Trỏ Terminal vào thư mục dự án và cài đặt package:
    ```bash
    cd Done-demo
    flutter clean
    flutter pub get
    ```
*   **Bước 2:** Cấu hình địa chỉ API. Bạn cần mở file cấu hình gốc (thường là `lib/core/config/app_config.dart` hoặc `api_service.dart`) và đổi `baseUrl` về **IP mạng LAN** của máy tính đang chạy Backend (Ví dụ: `http://192.168.1.5:8000/api`). *Tuyệt đối không dùng `localhost` nếu bạn build app ra điện thoại vật lý.*
*   **Bước 3:** Build và chạy thử nghiệm.
    *   Chạy trên điện thoại giả lập / máy thật: `flutter run`
    *   Chạy trên Web (Dành cho test, bypass CORS): 
        ```bash
        flutter run -d chrome --web-browser-flag "--disable-web-security"
        ```

---

## 3. App Vận Chuyển (`dngo_shipper_app`)
App tách biệt hoàn toàn dành riêng cho Shipper đi chợ và giao hàng.

*   **Bước 1:** Cài đặt các thư viện phụ thuộc:
    ```bash
    cd dngo_shipper_app
    flutter clean
    flutter pub get
    ```
*   **Bước 2:** Tương tự App chính, đổi cấu hình API endpoint về địa chỉ máy chủ nội bộ. Bạn cũng cần đảm bảo cấu hình kết nối Firebase (file `google-services.json` trên Android) đồng bộ với Firebase Project gốc để dùng cho tính năng Location Tracking theo thời gian thực.
*   **Bước 3:** Khởi chạy:
    ```bash
    flutter run
    ```

---

## 4. Module AI / Chatbot (`LLM-master`)
Hệ thống con phục vụ Chatbot và RAG cho tính năng gợi ý món ăn/nguyên liệu.

*   **Bước 1:** Trỏ vào thư mục `LLM-master`, tạo và activate `venv`.
*   **Bước 2:** Chạy lệnh cài đặt thư viện:
    ```bash
    pip install -r requirements.txt
    ```
*   **Bước 3:** Nếu dự án yêu cầu mô hình nhúng (Embedding) hoặc Vector DB (như Chroma/Faiss), hãy đảm bảo thư mục `.vector_cache` hoặc db có sẵn (như bạn đang có).
*   **Bước 4:** Khởi chạy service:
    ```bash
    python main.py
    ```
    *Hoặc dùng file `start.bat` để tự động chạy.*

---

**Lưu ý khi báo cáo:** 
Để toàn bộ các tính năng Realtime (như Shipper cập nhật vị trí, Firebase push notification và thay đổi đơn hàng) hoạt động trơn tru trong lúc demo, bạn cần **chạy song song cả 4 service trên**.
