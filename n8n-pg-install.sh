#!/bin/bash
set -e

echo "🚀 n8n + PostgreSQL + Traefik kurulumu başlatılıyor..."

# Sistem güncelleme
sudo apt update && sudo apt upgrade -y

# Temel araçlar
sudo apt install -y curl wget git

# Docker kurulumu (resmi kaynak)
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

# Docker Compose kurulumu (v2 plugin)
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/download/v2.30.1/docker-compose-linux-$(uname -m) -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Proje klasörü
mkdir -p ~/n8n-traefik
cd ~/n8n-traefik

# docker-compose.yaml dosyasını indir
echo "📦 docker-compose.yaml dosyası indiriliyor..."
wget https://raw.githubusercontent.com/Rarebox/n8n-scripts/master/docker-compose-pg.yaml -O docker-compose.yaml || echo "🚨 Lütfen docker-compose-pg.yaml'ı elle buraya ekleyin."

echo ""
echo "🔐 PostgreSQL ayarlarını yapılandırın:"
read -p "PostgreSQL Kullanıcı Adı: " pg_user
read -p "PostgreSQL Veritabanı Adı: " pg_db
read -s -p "PostgreSQL Şifresi: " pg_pass
echo ""

# .env dosyasını oluştur
echo "🗑️ .env dosyası oluşturuluyor..."
cat > .env << EOL
# Domain info
DOMAIN_NAME=example.com
SUBDOMAIN=n8n
SSL_EMAIL=admin@example.com

POSTGRES_USER=$pg_user
POSTGRES_PASSWORD=$pg_pass
POSTGRES_DB=$pg_db

# Timezone
GENERIC_TIMEZONE=Europe/Istanbul
EOL

# Docker volume oluştur
docker volume create traefik_data
docker volume create n8n_data
docker volume create postgres_data

# UFW kurulumu ve güvenli şekilde aktif edilmesi
if ! command -v ufw >/dev/null 2>&1; then
  echo "🛡️ UFW kurulumu yapılıyor..."
  sudo apt install -y ufw
fi

# SSH bağlantısını kaybetmemek için önce port 22'yi açıyoruz
echo "🔐 UFW yapılandırılıyor..."
sudo ufw allow OpenSSH

# Web trafiği için 80 ve 443 portlarını açıyoruz
sudo ufw allow 80
sudo ufw allow 443

# UFW aktif değilse aktif ediyoruz
ufw_status=$(sudo ufw status | grep "Status:" | awk '{print $2}')
if [[ "$ufw_status" != "active" ]]; then
  echo "⚠️ UFW aktif değil, şimdi etkinleştiriliyor..."
  echo "y" | sudo ufw enable
else
  echo "✅ UFW zaten aktif."
fi

echo ""
echo "✅ Kurulum tamamlandı."

# Kullanıcıya .env dosyasını düzenlemek isteyip istemediğini sor
echo ""
echo "🛠️ Şimdi .env dosyasını düzenlemek ister misiniz? (evet/hayır)"
read -r editenv
if [[ "$editenv" == "evet" ]]; then
  nano .env
fi

# Kullanıcıya servisi başlatmak isteyip istemediğini sor
echo ""
echo "🚀 n8n servisini şimdi başlatmak ister misiniz? (evet/hayır)"
read -r runn8n
if [[ "$runn8n" == "evet" ]]; then
  docker compose up -d
  echo ""
  echo "🎉 n8n başlatıldı! Domaininize giderek kontrol edebilirsiniz:"
  echo "🔗 https://n8n.$(grep DOMAIN_NAME .env | cut -d '=' -f2)"
else
  echo ""
  echo "ℹ️ n8n'i daha sonra başlatmak için şu komutu kullanabilirsiniz:"
  echo "   cd ~/n8n-traefik && docker compose up -d"
fi
