FROM ubuntu:22.04

# ------------------------------------------------------------------------------
# 1. CẤU HÌNH MÔI TRƯỜNG
# ------------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=trthaodev
ENV DISPLAY=:1
ENV RESOLUTION=1280x720

# ------------------------------------------------------------------------------
# 2. CÀI ĐẶT CÁC GÓI CẦN THIẾT
# ------------------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    # Giao diện Desktop nhẹ
    xfce4 \
    xfce4-goodies \
    # VNC & NoVNC để xem qua web
    tigervnc-standalone-server \
    novnc \
    websockify \
    # Các công cụ mạng & hệ thống
    openssh-server \
    curl \
    wget \
    sudo \
    python3 \
    software-properties-common \
    dbus-x11 \
    net-tools \
    # qBittorrent bản Web UI (Server)
    qbittorrent-nox \
    && mkdir /var/run/sshd

# ------------------------------------------------------------------------------
# 3. CÀI ĐẶT FIREFOX (BẢN PPA - KHÔNG DÙNG SNAP)
# ------------------------------------------------------------------------------
# Snap không chạy được trên Docker, phải dùng bản PPA
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' > /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    apt-get update && apt-get install -y firefox

# ------------------------------------------------------------------------------
# 4. CÀI ĐẶT BORE (SSH TUNNEL)
# ------------------------------------------------------------------------------
# Dùng Bore để SSH ổn định không cần cấu hình
RUN wget https://github.com/ekzhang/bore/releases/download/v0.5.1/bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz && \
    tar -xf bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz && \
    mv bore /usr/local/bin/bore && \
    rm bore-v0.5.1-x86_64-unknown-linux-musl.tar.gz && \
    chmod +x /usr/local/bin/bore

# ------------------------------------------------------------------------------
# 5. TẠO USER & CẤU HÌNH
# ------------------------------------------------------------------------------
RUN useradd -m $USER && \
    echo "$USER:thaodev@" | chpasswd && \
    adduser $USER sudo

# Cấu hình SSH
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# ------------------------------------------------------------------------------
# 6. TẠO SCRIPT KHỞI CHẠY (AUTO START)
# ------------------------------------------------------------------------------
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'echo "=== 1. KHOI DONG SSH SERVICE ==="' >> /start.sh && \
    echo 'service ssh start' >> /start.sh && \
    echo 'echo "=== 2. KHOI DONG QBITTORRENT (WEB UI PORT 8081) ==="' >> /start.sh && \
    # Chạy qBittorrent dưới background, port 8081
    echo 'nohup qbittorrent-nox --webui-port=8081 > /var/log/qbit.log 2>&1 &' >> /start.sh && \
    echo 'echo "=== 3. KHOI DONG VNC (DESKTOP) ==="' >> /start.sh && \
    echo 'mkdir -p /home/trthaodev/.vnc' >> /start.sh && \
    # Đặt mật khẩu VNC là thaodev@
    echo 'echo "thaodev@" | vncpasswd -f > /home/trthaodev/.vnc/passwd' >> /start.sh && \
    echo 'chmod 600 /home/trthaodev/.vnc/passwd' >> /start.sh && \
    echo 'chown -R trthaodev:trthaodev /home/trthaodev/.vnc' >> /start.sh && \
    # Chạy VNC Server
    echo 'su - trthaodev -c "vncserver :1 -geometry 1280x720 -depth 24"' >> /start.sh && \
    echo 'echo "=== 4. KHOI DONG NOVNC (WEB VIEW PORT 8080) ==="' >> /start.sh && \
    # Chạy Websockify để biến VNC thành Web (Port 8080 - Port chính của Railway)
    echo 'websockify --web /usr/share/novnc/ --wrap-mode=ignore 8080 localhost:5901 > /var/log/novnc.log 2>&1 &' >> /start.sh && \
    echo 'echo "=== 5. KHOI DONG BORE (SSH TUNNEL) ==="' >> /start.sh && \
    echo 'nohup bore local 22 --to bore.pub > /var/log/bore.log 2>&1 &' >> /start.sh && \
    echo 'sleep 5' >> /start.sh && \
    echo 'echo "---------------------------------------------------"' >> /start.sh && \
    echo 'echo "SERVER ONLINE!"' >> /start.sh && \
    echo 'echo "1. Truy cap Desktop: Domain Railway (Port 8080)"' >> /start.sh && \
    echo 'echo "2. Truy cap Torrent: Mo Firefox trong Desktop -> localhost:8081"' >> /start.sh && \
    echo 'echo "3. Mat khau Torrent: Xem file log bang lenh ben duoi"' >> /start.sh && \
    echo 'echo "   cat /var/log/qbit.log | grep Password"' >> /start.sh && \
    echo 'echo "---------------------------------------------------"' >> /start.sh && \
    echo 'tail -f /var/log/bore.log' >> /start.sh && \
    chmod +x /start.sh

# ------------------------------------------------------------------------------
# 7. MỞ PORT & CHẠY
# ------------------------------------------------------------------------------
EXPOSE 8080 22 8081
CMD ["/start.sh"]
