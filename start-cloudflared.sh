#!/bin/bash

echo "=== Bắt đầu dịch vụ SSH ==="
service ssh start

# Kiểm tra biến môi trường CLOUDFLARE_TOKEN
if [ -z "$CLOUDFLARE_TOKEN" ]; then
  echo "⚠️  Lỗi: Không tìm thấy CLOUDFLARE_TOKEN!"
  echo "➡️  Vui lòng thêm token từ Cloudflare Zero Trust vào Environment Variables."
  exit 1
fi

echo "=== Khởi động Cloudflare Tunnel ==="
# Chạy cloudflared dưới nền, dùng token để kết nối
nohup cloudflared tunnel run --token "$CLOUDFLARE_TOKEN" > /var/log/cloudflared.log 2>&1 &

echo "=== Dịch vụ đang chạy ==="
echo "Bây giờ bạn có thể SSH vào server thông qua domain bạn đã cấu hình trên Cloudflare."
echo "Ví dụ: ssh trthaodev@ssh-server.domaincuaban.com"
echo "(Lưu ý: Client cần cài cloudflared hoặc setup Browser Rendering)"

# Giữ container sống (Quan trọng cho Railway/Render)
echo "=== Giữ container hoạt động (port 8080) ==="
python3 -m http.server 8080
