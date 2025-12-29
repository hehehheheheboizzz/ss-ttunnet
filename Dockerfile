FROM ubuntu:22.04

# 1. Cài đặt môi trường
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    wget \
    tar \
    sudo \
    python3 \
    && mkdir /var/run/sshd

# 2. Tạo User 'trthaodev' (Pass: thaodev@)
RUN useradd -m trthaodev && \
    echo "trthaodev:thaodev@" | chpasswd && \
    adduser trthaodev sudo

# Cấu hình SSH
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# 3. Cài đặt Bore (Link GitHub chuẩn, không bao giờ chết)
RUN wget https://github.com/ekzhang/bore/releases/download/v0.5.1/bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz && \
    tar -xf bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz && \
    mv bore /usr/local/bin/bore && \
    rm bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz && \
    chmod +x /usr/local/bin/bore

# 4. Script chạy Bore TCP
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'service ssh start' >> /start.sh && \
    echo 'echo "=== DANG KHOI TAO BORE ==="' >> /start.sh && \
    echo 'echo "Doi 3 giay..."' >> /start.sh && \
    # Chạy bore kết nối tới server công cộng bore.pub
    echo 'nohup bore local 22 --to bore.pub > /var/log/bore.log 2>&1 &' >> /start.sh && \
    echo 'sleep 5' >> /start.sh && \
    echo 'echo "=== THONG TIN NHAP VAO BITVISE (Doc ky) ==="' >> /start.sh && \
    # Lọc log để lấy port
    echo 'PORT=$(grep -o "remote_port=[0-9]*" /var/log/bore.log | head -n1 | cut -d= -f2)' >> /start.sh && \
    echo 'echo "👉 Host: bore.pub"' >> /start.sh && \
    echo 'echo "👉 Port: $PORT"' >> /start.sh && \
    echo 'echo "=========================================="' >> /start.sh && \
    echo 'echo "Server dang chay..."' >> /start.sh && \
    echo 'tail -f /var/log/bore.log & python3 -m http.server 8080' >> /start.sh && \
    chmod +x /start.sh

# 5. Chạy
EXPOSE 8080 22
CMD ["/start.sh"]
