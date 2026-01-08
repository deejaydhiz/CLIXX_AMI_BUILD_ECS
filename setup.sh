##Install the needed packages and enable the services(MariaDb, Apache)
sudo dnf upgrade -y
sudo dnf install mariadb105-server php-mysqlnd php-fpm php-mysqli php-json php php-devel -y
sudo dnf install -y nfs-utils wget git cronie httpd docker

echo "Starting Services"
sudo systemctl start mariadb crond docker 
sudo systemctl enable mariadb crond docker
echo "======================================================================"

##Add ec2-user to Apache group and grant permissions to /var/www
echo "Setting Permissions"
sudo usermod -a -G apache ec2-user   
sudo chown -R ec2-user:apache /var/www     
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;   
find /var/www -type f -exec sudo chmod 0664 {} \;    
cd /var/www/html

##Grant file ownership of /var/www & its contents to apache user
sudo chown -R apache /var/www

##Grant group ownership of /var/www & contents to apache group
sudo chgrp -R apache /var/www

##Change directory permissions of /var/www & its subdir to add group write 
sudo chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} \;

##Recursively change file permission of /var/www & subdir to add group write perm
sudo find /var/www -type f -exec sudo chmod 0664 {} \;
