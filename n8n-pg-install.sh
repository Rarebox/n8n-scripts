#!/bin/bash
set -e

echo "🚀 n8n + PostgreSQL + Traefik kurulumu başlatılıyor..."

# Sistem güncelleme
sudo apt update && sudo apt upgrade -y

# Temel araçlar
sudo apt install -y curl wget git

# Docker kurulumu
# Docker için resmi repo kurulumu
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

# Docker CE kur
sudo apt install -y docker-ce docker-ce-cli containerd.io

sudo systemctl start docker
sudo systemctl enable docker

# Docker Compose kurulumu
sudo curl -SL https://github.com/docker/compose/releases/download/v2.30.1/docker-compose-linux-$(uname -m) -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Proje klasörü
mkdir -p ~/n8n-traefik
cd ~/n8n-traefik

# Dosyaları oluştur
echo "📦 docker-compose.yaml oluşturuluyor..."
wget https://raw.githubusercontent.com/Rarebox/n8n-scripts/master/docker-compose-pg.yaml -O docker-compose.yaml || echo "🚨 Lütfen docker-compose-pg.yaml'ı elle buraya ekleyin."

echo "📝 .env dosyası oluşturuluyor..."
cat > .env << 'EOL'
# Domain info
DOMAIN_NAME=example.com
SUBDOMAIN=n8n
SSL_EMAIL=admin@example.com

# Timezone
GENERIC_TIMEZONE=Europe/Istanbul
EOL

# Volume oluştur
docker volume create traefik_data
docker volume create n8n_data
docker volume create postgres_data

echo "✅ Kurulum tamamlandı. Başlatmak için:"
echo "cd ~/n8n-traefik && docker compose up -d"
