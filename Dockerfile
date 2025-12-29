FROM ubuntu:22.04

# -----------------------------
# 1. Cài đặt các gói cần thiết
# -----------------------------
# Lưu ý: Thêm 'gnupg' để cài key cho Playit
RUN apt update && apt install -y \
    openssh-server \
    curl \
    wget \
    sudo \
    python3 \
    gnupg \
    && mkdir /var/run/sshd

# -----------------------------
# 2. Tạo user 'trthaodev'
# -----------------------------
# User: trthaodev / Pass: thaodev@
RUN useradd -m trthaodev && echo "trthaodev:thaodev@" | chpasswd && adduser trthaodev sudo

# -----------------------------
# 3. Cấu hình SSH
# -----------------------------
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'ClientAliveInterval 60' >> /etc/ssh/sshd_config

# -----------------------------
# 4. Cài đặt Playit.gg (Bản mới nhất)
# -----------------------------
RUN curl -SsL https://playit-cloud.github.io/ppa/key.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/playit.gpg >/dev/null && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/playit.gpg] https://playit-cloud.github.io/ppa/data ./" | tee /etc/apt/sources.list.d/playit-cloud.list && \
    apt update && apt install -y playit

# -----------------------------
# 5. Copy script khởi chạy
# -----------------------------
# Bạn nhớ tạo file start-playit.sh cùng thư mục với Dockerfile trước khi deploy
COPY start-playit.sh /usr/local/bin/start-playit.sh
RUN chmod +x /usr/local/bin/start-playit.sh

# -----------------------------
# 6. Mở port (Web để giữ container, SSH để kết nối nội bộ)
# -----------------------------
EXPOSE 8080 22

# -----------------------------
# 7. Chạy script
# -----------------------------
CMD ["/usr/local/bin/start-playit.sh"]
