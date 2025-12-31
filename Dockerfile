FROM ubuntu:22.04

# --- 1. CÀI ĐẶT MÔI TRƯỜNG CƠ BẢN ---
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    sudo \
    nano \
    ca-certificates \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# --- 2. TẠO USER 'trthaodev' (Full quyền sudo) ---
RUN useradd -m -s /bin/bash trthaodev && \
    echo "trthaodev:thaodev@" | chpasswd && \
    usermod -aG sudo trthaodev && \
    echo "trthaodev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# --- 3. CÀI ĐẶT CLOUDFLARED (Tunnel xịn) ---
RUN wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && \
    dpkg -i cloudflared-linux-amd64.deb && \
    rm cloudflared-linux-amd64.deb

# --- 4. CÀI ĐẶT FILEBROWSER (Quản lý file + Terminal trên web) ---
RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

# --- 5. SCRIPT KHỞI ĐỘNG THÔNG MINH ---
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'echo "=== KHOI TAO SERVER ==="' >> /start.sh && \
    echo '' >> /start.sh && \
    # 1. Chạy FileBrowser (Cổng 8080, Root path, Không pass)
    echo 'echo "1. Dang chay FileBrowser..."' >> /start.sh && \
    echo 'nohup filebrowser -r / -p 8080 --no-auth > /var/log/fb.log 2>&1 &' >> /start.sh && \
    echo '' >> /start.sh && \
    # 2. Chạy Cloudflare Tunnel
    echo 'echo "2. Dang ket noi Cloudflare..."' >> /start.sh && \
    echo 'nohup cloudflared tunnel --url http://localhost:8080 > /var/log/cf.log 2>&1 &' >> /start.sh && \
    echo '' >> /start.sh && \
    # 3. Vòng lặp lấy Link (Đợi đến khi có link thì in ra)
    echo 'echo "⏳ Dang lay link truy cap..."' >> /start.sh && \
    echo 'sleep 5' >> /start.sh && \
    echo 'while true; do' >> /start.sh && \
    echo '  LINK=$(grep -o "https://.*\.trycloudflare.com" /var/log/cf.log | head -n 1)' >> /start.sh && \
    echo '  if [ ! -z "$LINK" ]; then' >> /start.sh && \
    echo '    echo "=========================================================="' >> /start.sh && \
    echo '    echo "✅ SERVER SANS SANG! TRUY CAP LINK DUOI DAY (Full Quyen):"' >> /start.sh && \
    echo '    echo ""' >> /start.sh && \
    echo "    echo \"👉 \$LINK\"" >> /start.sh && \
    echo '    echo ""' >> /start.sh && \
    echo '    echo "=========================================================="' >> /start.sh && \
    echo '    break' >> /start.sh && \
    echo '  fi' >> /start.sh && \
    echo '  sleep 2' >> /start.sh && \
    echo 'done' >> /start.sh && \
    # Giữ container chạy mãi mãi
    echo 'tail -f /var/log/cf.log' >> /start.sh && \
    chmod +x /start.sh

# --- 6. CHẠY ---
EXPOSE 8080
CMD ["/start.sh"]
