# Linux Server Configuration

This is the sixth project of Full Stack Web Develper Nanodegree by Udacity.

## Server information summary

### Public IP address and port

35.165.178.76:2200

### URL to web application

http://ec2-35-165-178-76.us-west-2.compute.amazonaws.com/

### Installed third party softwares

    - Apache2 and modules
    - PostgreSQL and modules
    - Git
    - Pip and virtualenv

## How to setup server

### Basic security configuration

Connect to ssh as a root.

    ssh -i ~/.ssh/udacity_key.rsa root@35.165.178.76

Set up locale.

    echo 'LC_ALL="en_US.UTF-8"' >> /etc/environment
    source /etc/environment
    export LC_ALL

Download and run [setup script][].

    wget https://raw.githubusercontent.com/earlbread/linux-server-configuration/master/config_server.sh
    chmod +x ./config_server.sh
    ./config_server.sh
    exit

[setup script]: https://github.com/earlbread/linux-server-configuration/blob/master/config_server.sh

### Set password and upgrade softwares

After basic security configuration, connect to server as `grader`.

    ssh -i ~/.ssh/udacity_key.rsa grader@35.165.178.76 -p 2200

At first login, you need to set new password for grader.

    passwd

Before install other softwares, upgrade softwares currently installed.

    sudo apt -qy update && sudo apt -qy upgrade

### Web server configuration

#### Install and configure third party softwares

Install Apache and mod wsgi.

    sudo apt -qy install apache2 libapache2-mod-wsgi python-dev

Install PostgreSQL and python module.

    sudo apt -qy install postgresql python-psycopg2 libpq-dev

Change user to postgres.

    sudo su - postgres

Run psql, create user and database.

    psql
    create user catalog with password 'catalog';
    create database catalog owner catalog encoding 'utf-8';
    \q

    exit

Return to grader, add user catalog.

    sudo adduser --disabled-password --gecos "" catalog

Install git, pip and virtualenv to serve catalog app.

    sudo apt -qy install git python-pip && sudo pip install virtualenv

Change user to catalog.

    sudo su - catalog

Clone app and install modules needed as catalog user.

    git clone https://github.com/earlbread/item-catalog catalog

    cd catalog
    ./setup

To use google and facebook login, update client keys in `catalog/config.py`

    GOOGLE_CLIENT_ID='YOUR_GOOGLE_CLIENT_ID'
    GOOGLE_CLIENT_SECRET='YOUR_GOOGLE_CLIENT_SECRET'
    FB_CLIENT_ID='YOUR_FACEBOOK_CLIENT_ID'
    FB_CLIENT_SECRET='YOUR_FACEBOOK_CLIENT_SECRET'

Return to grader, add apache configuration to `/etc/apache2/sites-available/catalog.conf`

    # /etc/apache2/sites-available/catalog.conf

    <VirtualHost *:80>
        ServerName localhost
        WSGIScriptAlias / /home/catalog/catalog/catalog.wsgi
        <Directory /home/catalog/catalog/>
                Require all granted
        </Directory>
        ErrorLog ${APACHE_LOG_DIR}/error.log
        LogLevel warn
        CustomLog ${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>

Disable default page and enable catalog application.

    sudo a2dissite 000-default
    sudo a2ensite catalog

Suppress apache warning.

    echo "ServerName localhost" | sudo tee /etc/apache2/conf-available/fqdn.conf
    sudo a2enconf fqdn

Restart apache server.

    sudo service apache2 restart
