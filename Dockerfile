FROM ubuntu:22.04

# Gunakan noninteractive agar tidak berhenti saat minta timezone
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update -y && \
    apt install -y apache2 \
    php \
    npm \
    php-xml \
    php-mbstring \
    php-curl \
    php-mysql \
    php-gd \
    unzip \
    nano  \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sS https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer

RUN mkdir -p /var/www/sosmed
WORKDIR /var/www/sosmed

# Copy semua file ke dalam container
COPY . /var/www/sosmed
COPY sosmed.conf /etc/apache2/sites-available/

# Pastikan file .env tersedia agar php artisan tidak error
RUN cp .env.example .env || true

RUN a2dissite 000-default.conf && a2ensite sosmed.conf

# Setup folder Laravel dan permissions awal
RUN mkdir -p bootstrap/cache \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views && \
    chown -R www-data:www-data /var/www/sosmed && \
    chmod -R 775 /var/www/sosmed

# Jalankan composer install saat build (tidak butuh database)
RUN composer install --no-interaction --optimize-autoloader

# Pastikan script install.sh bisa dieksekusi
RUN chmod +x install.sh

EXPOSE 8000

# Perintah CMD di bawah ini akan menjalankan migrasi & seeder 
# SAAT container dijalankan (ketika database biasanya sudah siap)
CMD bash -c "./install.sh && php artisan serve --host=0.0.0.0 --port=8000"
