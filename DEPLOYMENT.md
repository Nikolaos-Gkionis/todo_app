# 🚀 Todo-it Deployment Guide

Complete step-by-step guide to deploy Todo-it to Digital Ocean with Docker and Kamal.

## 📋 Prerequisites

### 1. **SSH Key Setup (New Laptop)**

```bash
# Generate SSH key for GitHub & Digital Ocean
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/id_ed25519

# Copy public key to clipboard
cat ~/.ssh/id_ed25519.pub

# Add to GitHub: https://github.com/settings/keys
# Add to Digital Ocean: https://cloud.digitalocean.com/account/security
```

### 2. **Accounts & Services**

- [ ] Digital Ocean account ($12 Basic droplet)
- [ ] Domain registered (Namecheap)
- [ ] GitHub repository
- [ ] Stripe account (for payments)

---

## 🏗️ **Part 1: Digital Ocean Setup**

### **1. Create Droplet**

```bash
# Login to Digital Ocean dashboard
# Create droplet with:
# - Ubuntu 22.04 LTS
# - Basic plan ($12/month, 1GB RAM, 1 vCPU, 25GB SSD)
# - Region: Closest to your users (e.g., NYC3, LON1)
# - Authentication: SSH Key (paste your public key)
# - Hostname: todo-app
```

### **2. Configure Droplet**

```bash
# SSH into your new droplet
ssh root@YOUR_DROPLET_IP

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Kamal dependencies
sudo apt install -y curl git build-essential libssl-dev libreadline-dev zlib1g-dev

# Logout and login again for Docker group
exit
ssh root@YOUR_DROPLET_IP
```

### **3. Setup Domain (Namecheap)**

```bash
# In Namecheap dashboard:
# 1. Go to Domain List → Manage
# 2. Advanced DNS → Add new record:
#    Type: A
#    Host: @
#    Value: YOUR_DROPLET_IP
#    TTL: 30 min

# Wait 30 minutes for DNS propagation
```

---

## 🐳 **Part 2: Docker Deployment**

### **1. Local Setup**

```bash
# Clone your repository
git clone https://github.com/yourusername/todo_app.git
cd todo_app

# Copy environment file and add your keys
cp .env.example .env
# Edit .env with your Stripe keys:
# STRIPE_PUBLISHABLE_KEY=pk_live_...
# STRIPE_SECRET_KEY=sk_live_...
```

### **2. Test Locally**

```bash
# Build and test locally
docker-compose up --build

# Visit http://localhost:3000
# Test signup, login, premium upgrade
```

### **3. Deploy to Digital Ocean**

```bash
# SSH into your droplet
ssh root@YOUR_DROPLET_IP

# Clone repository on server
git clone https://github.com/yourusername/todo_app.git
cd todo_app

# Copy environment file
cp .env.example .env
# Add your production Stripe keys to .env

# Build and run with Docker Compose
docker-compose up --build -d

# Check if running
docker ps
curl http://localhost
```

### **4. Setup Nginx Reverse Proxy**

```bash
# Install Nginx
sudo apt install -y nginx

# Create Nginx config
sudo nano /etc/nginx/sites-available/todo-app

# Add this configuration:
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Enable site
sudo ln -s /etc/nginx/sites-available/todo-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Test your domain
curl http://yourdomain.com
```

---

## 🚀 **Part 3: Kamal Deployment (Alternative)**

### **1. Install Kamal**

```bash
# On your local machine
gem install kamal

# Initialize Kamal
kamal init
```

### **2. Configure Kamal**

```bash
# Edit deploy.yml
nano config/deploy.yml

# Add your configuration:
service: todo-app
image: yourusername/todo-app
servers:
  web:
    hosts:
      - YOUR_DROPLET_IP
    labels:
      traefik.http.routers.todo-app.rule: Host(`yourdomain.com`)
      traefik.http.routers.todo-app.tls.certresolver: letsencrypt
env:
  clear:
    RAILS_MASTER_KEY: YOUR_MASTER_KEY
  secret:
    - STRIPE_PUBLISHABLE_KEY
    - STRIPE_SECRET_KEY
registry:
  username: yourusername
  password:
    - DOCKER_REGISTRY_PASSWORD
```

### **3. Deploy with Kamal**

```bash
# Build and deploy
kamal setup

# Deploy updates
kamal deploy

# Check status
kamal app status
kamal app logs
```

---

## 🔒 **Part 4: SSL & Security**

### **1. SSL Certificate (Let's Encrypt)**

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com

# Test renewal
sudo certbot renew --dry-run
```

### **2. Security Hardening**

```bash
# Create non-root user
sudo adduser deploy
sudo usermod -aG sudo deploy
sudo usermod -aG docker deploy

# Disable root login
sudo nano /etc/ssh/sshd_config
# Set: PermitRootLogin no
# Set: PasswordAuthentication no

sudo systemctl restart ssh

# Setup firewall
sudo ufw enable
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
```

---

## 🔧 **Part 5: Monitoring & Maintenance**

### **1. Application Monitoring**

```bash
# Check app status
docker ps
docker logs todo_app_app

# Database backup (SQLite)
cp storage/production.sqlite3 backups/$(date +%Y%m%d_%H%M%S).sqlite3
```

### **2. Updates & Maintenance**

```bash
# Update app
git pull origin main
docker-compose down
docker-compose up --build -d

# Update server
sudo apt update && sudo apt upgrade
```

---

## 🐛 **Troubleshooting**

### **Common Issues:**

**App not starting:**

```bash
docker logs todo_app_app
# Check for environment variable issues
```

**Database issues:**

```bash
# Check database file
ls -la storage/
# Reset database if needed
docker-compose exec app rails db:reset
```

**SSL issues:**

```bash
# Check certificate
sudo certbot certificates
# Renew manually
sudo certbot renew
```

**Domain not working:**

```bash
# Check DNS propagation
nslookup yourdomain.com
# Check Nginx config
sudo nginx -t
```

---

## 📊 **Post-Launch Checklist**

- [ ] Domain points to server ✅
- [ ] SSL certificate installed ✅
- [ ] App loads at https://yourdomain.com ✅
- [ ] Signup/login works ✅
- [ ] Stripe payments work ✅
- [ ] Email notifications work ✅
- [ ] All premium features accessible ✅
- [ ] Mobile responsive ✅

---

## 💰 **Business Metrics**

**Track these after launch:**

- Daily/weekly active users
- Conversion rate (free → premium)
- Revenue per user
- Support tickets
- Performance metrics

---

**🎉 Your Todo-it app is now live and ready for users!**

Need help with any step? The app is production-ready and will scale beautifully! 🚀
