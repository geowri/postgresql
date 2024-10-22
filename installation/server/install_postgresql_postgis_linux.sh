
sudo apt update
sudo apt upgrade

> Change port for ssh conections in /etc/ssh/sshd_config
systemctl disable --now ssh.socket
systemctl enable --now ssh.service
systemctl restart sshd

> Installing necessary packages
sudo apt install postgresql postgresql-contrib
sudo apt install postgis postgresql-16-postgis-3
sudo apt install libgmp3-dev libpq-dev build-essential python3-dev python3-venv
sudo apt install nginx python3-certbot-nginx vim-gtk3

> Creating directories
sudo mkdir -p /var/lib/pgadmin4/sessions
sudo mkdir /var/lib/pgadmin4/storage
sudo mkdir /var/log/pgadmin4
sudo mkdir /opt/pgadmin

> Creating virtual environment
python3 -m venv /opt/pgadmin/venv
source /opt/pgadmin/venv/bin/activate

> Installing pip packages
pip install pgadmin4
pip install gunicorn

vim /opt/pgadmin/venv/lib/python3.12/site-packages/pgadmin4/config_local.py

LOG_FILE = '/var/log/pgadmin4/pgadmin4.log'
SQLITE_PATH = '/var/lib/pgadmin4/pgadmin4.db'
SESSION_DB_PATH = '/var/lib/pgadmin4/sessions'
STORAGE_DIR = '/var/lib/pgadmin4/storage'
AZURE_CREDENTIAL_CACHE_DIR = '/var/lib/pgadmin4/azurecredentialcache'
KERBEROS_CCACHE_DIR = '/var/lib/pgadmin4/kerberoscache'
DEFAULT_USER = 'your_email@example.com'
DEFAULT_PASSWORD = 'your_secure_password'
SERVER_MODE = True

python3 /opt/pgadmin/venv/lib/python3.12/site-packages/pgadmin4/setup.py setup-db

vim /etc/systemd/system/pgadmin4.service
[Unit]
Description=Gunicorn instance to serve pgAdmin 4
Requires=pgadmin4.socket
After=network.target
[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/pgadmin/venv/lib/python3.12/site-packages/pgadmin4
ExecStart=/opt/pgadmin/venv/bin/gunicorn --bind unix:/run/pgadmin4.sock --workers=1 --threads=25 pgAdmin4:app
[Install]
WantedBy=multi-user.target

vim /etc/systemd/system/pgadmin4.socket
[Unit]
Description=pgadmin4 socket
[Socket]
ListenStream=/run/pgadmin4.sock
[Install]
WantedBy=sockets.target

sudo chown -R www-data:www-data /var/lib/pgadmin4
sudo chown -R www-data:www-data /var/log/pgadmin4

systemctl enable --now pgadmin4.service
systemctl status pgadmin4.service

vim /etc/nginx/sites-available/pgadmin4
server {
    listen 80;
    listen [::]:80;
    server_name database.dsview.org www.database.dsview.org;
    location / {
        proxy_pass http://unix:/run/pgadmin4.sock;
        include proxy_params;
    }
}

sudo ln -s /etc/nginx/sites-available/pgadmin4 /etc/nginx/sites-enabled/
systemctl restart nginx
systemctl status nginx
