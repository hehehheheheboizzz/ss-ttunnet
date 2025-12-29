#!/bin/bash

echo "=== BẮT ĐẦU DỊCH VỤ SSH ==="
service ssh start

# -----------------------------
# Kiểm tra Secret Key
# -----------------------------
if [ -z "$PLAYIT_SECRET" ]; then
  echo "❌ LỖI NGHIÊM TRỌNG: Không tìm thấy biến môi trường PLAYIT_SECRET"
  echo "👉 Hãy vào Railway/Render -> Variables -> Thêm PLAYIT_SECRET lấy từ web Playit.gg"
  # Không exit để tránh container bị crash liên tục, nhưng sẽ không chạy playit
  echo "Container sẽ chạy ở chế độ chờ (không có Tunnel)..."
else
  echo "=== KHỞI ĐỘNG PLAYIT AGENT ==="
  echo "Đang kết nối với tài khoản Playit..."
  # Chạy playit ngầm và ghi log
  nohup playit --secret "$PLAYIT_SECRET" > /var/log/playit.log 2>&1 &
  sleep 5
  echo "✅ Playit đã chạy. Vui lòng kiểm tra Dashboard trên web Playit.gg để lấy địa chỉ SSH."
fi

# -----------------------------
# Giữ container sống (Quan trọng cho Railway)
# -----------------------------
echo "=== CONTAINER ĐANG HOẠT ĐỘNG (Port 8080) ==="
python3 -m http.server 8080
