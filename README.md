# Odoo 20 trên Docker

Cài Odoo 20 bằng Docker chỉ với một lệnh. Một server có thể chạy nhiều instance Odoo song song, mỗi instance một thư mục và một cặp port riêng.

| Thành phần | Image | Ghi chú |
|---|---|---|
| Odoo | `odoo:20.0` | Image chính thức, Ubuntu noble, Python 3.12 |
| PostgreSQL | `pgvector/pgvector:pg17` | PostgreSQL 17 có sẵn extension `vector` cho các tính năng AI. Odoo 20 cần PostgreSQL 16 trở lên |

## Mục lục

1. [Yêu cầu](#1-yêu-cầu)
2. [Cài nhanh bằng một lệnh](#2-cài-nhanh-bằng-một-lệnh)
3. [Cài thủ công](#3-cài-thủ-công)
4. [Lần đầu sử dụng](#4-lần-đầu-sử-dụng)
5. [Cấu trúc thư mục](#5-cấu-trúc-thư-mục)
6. [Cấu hình](#6-cấu-hình)
7. [Quản lý container](#7-quản-lý-container)
8. [Addon: tự viết, Enterprise, bên thứ 3](#8-addon-tự-viết-enterprise-bên-thứ-3)
9. [AI và pgvector](#9-ai-và-pgvector)
10. [Chạy production sau Nginx](#10-chạy-production-sau-nginx)
11. [Sao lưu và khôi phục](#11-sao-lưu-và-khôi-phục)
12. [Nâng cấp từ bản cũ (Odoo 16, postgres 15)](#12-nâng-cấp-từ-bản-cũ-odoo-16-postgres-15)
13. [Xử lý sự cố](#13-xử-lý-sự-cố)

## 1. Yêu cầu

- RAM tối thiểu 4 GB cho một instance (cấu hình mặc định chạy 5 worker), ổ trống khoảng 5 GB.
- `git`, Docker và Docker Compose v2 (lệnh `docker compose`).

**Ubuntu / Debian server**

```bash
sudo apt update && sudo apt install -y git curl
curl -fsSL https://get.docker.com | sudo sh     # cài Docker + Compose plugin
docker compose version                          # kiểm tra
```

**Windows**: cài [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/), bật WSL 2 integration, rồi chạy mọi lệnh trong terminal Ubuntu (WSL). Đặt thư mục cài trong ổ của WSL (ví dụ `~/odoo-one`), không đặt trong `/mnt/c/...`, vì ở đó chậm và hay lỗi phân quyền.

**macOS**: cài [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/) hoặc OrbStack.

## 2. Cài nhanh bằng một lệnh

Linux / WSL:

```bash
curl -s https://raw.githubusercontent.com/VNEXT-CHIPT-G8/docker-odoo/20.0/run.sh | sudo bash -s odoo-one 10012 20012
```

macOS (không dùng `sudo`):

```bash
curl -s https://raw.githubusercontent.com/VNEXT-CHIPT-G8/docker-odoo/20.0/run.sh | bash -s odoo-one 10012 20012
```

Tham số:

| Vị trí | Ví dụ | Ý nghĩa |
|---|---|---|
| 1 | `odoo-one` | Thư mục cài đặt, phải chưa tồn tại |
| 2 | `10012` | Port web Odoo (mặc định `10012`) |
| 3 | `20012` | Port live chat / websocket (mặc định `20012`) |

Script sẽ clone nhánh `20.0`, cấp quyền thư mục, tăng giới hạn inotify (chỉ trên Linux), đổi port trong `docker-compose.yml` rồi chạy `docker compose up -d`.

Thêm instance thứ hai thì đổi tên thư mục và port:

```bash
curl -s https://raw.githubusercontent.com/VNEXT-CHIPT-G8/docker-odoo/20.0/run.sh | sudo bash -s odoo-two 11012 21012
```

Lần đầu phải tải khoảng 1–2 GB image nên mất vài phút.

## 3. Cài thủ công

```bash
git clone -b 20.0 https://github.com/VNEXT-CHIPT-G8/docker-odoo odoo-one
cd odoo-one
mkdir -p postgresql
sudo chmod -R 777 addons etc postgresql
# đổi port nếu cần: sửa "10012:8069" và "20012:8072" trong docker-compose.yml
docker compose up -d
```

## 4. Lần đầu sử dụng

1. Mở `http://<ip-server>:10012` (máy cá nhân thì `http://localhost:10012`).
2. Trang **tạo database** hiện ra:
   - **Master Password**: `Masterpass` (là `admin_passwd` trong `etc/odoo.conf`; [đổi ngay](#6-cấu-hình) nếu chạy thật).
   - Nhập tên database, email, mật khẩu admin, ngôn ngữ (Tiếng Việt), quốc gia.
3. Đăng nhập bằng email và mật khẩu admin vừa tạo.

Quản lý database (tạo, sao lưu, nhân bản, xoá): `http://<ip-server>:10012/web/database/manager`.

## 5. Cấu trúc thư mục

```
odoo-one/
├── docker-compose.yml     # khai báo 2 service: db, odoo
├── addons/                # addon mount vào /mnt/extra-addons
│   ├── enterprise/        #   Odoo Enterprise (không commit lên git)
│   ├── third-party/       #   app bên thứ 3
│   └── <addon tự viết>/
├── etc/                   # mount vào /etc/odoo
│   ├── odoo.conf          #   cấu hình Odoo
│   ├── odoo.log           #   log Odoo
│   ├── requirements.txt   #   thư viện Python cài thêm
│   └── files/             #   data_dir: filestore (file đính kèm), sessions
├── postgresql/            # dữ liệu PostgreSQL
├── entrypoint.sh          # entrypoint tuỳ biến (cài requirements.txt)
├── Dockerfile             # chỉ dùng khi muốn tự build image
└── run.sh                 # script cài nhanh
```

Dữ liệu cần giữ khi sao lưu hoặc chuyển server: `postgresql/`, `etc/files/`, `etc/odoo.conf`, `addons/`.

## 6. Cấu hình

Sửa `etc/odoo.conf`, sau đó chạy `docker compose restart odoo`.

| Option | Mặc định | Ghi chú |
|---|---|---|
| `admin_passwd` | `Masterpass` | Mật khẩu master để quản lý database. **Đổi khi chạy thật** |
| `workers` | `5` | Số tiến trình xử lý request. Gợi ý: (số CPU × 2) + 1. Đặt `0` khi dev |
| `max_cron_threads` | `2` | Số luồng chạy tác vụ định kỳ |
| `limit_memory_soft` / `limit_memory_hard` | 2 GB / 2.5 GB | Giới hạn RAM mỗi worker |
| `limit_time_cpu` / `limit_time_real` | 600 / 1200 giây | Thời gian tối đa mỗi request |
| `proxy_mode` | `True` | Cần khi chạy sau Nginx |
| `log_level` | `error` | Đổi sang `info` khi cần debug |
| `logfile` | `/etc/odoo/odoo.log` | Bỏ dòng này nếu muốn xem log bằng `docker compose logs` |
| `dev_mode` | tắt | Chỉ bật `dev_mode = reload` khi dev và đặt kèm `workers = 0` |

Thông tin kết nối DB (`db`, user `odoo`, mật khẩu `odoo`) nằm trong `docker-compose.yml`. Muốn đổi mật khẩu DB thì sửa cả `POSTGRES_PASSWORD` của service `db` và `PASSWORD` của service `odoo` **trước lần chạy đầu tiên**.

## 7. Quản lý container

Chạy các lệnh trong thư mục cài đặt (`cd odoo-one`):

```bash
docker compose up -d              # chạy
docker compose ps                 # trạng thái (phải là "Up")
docker compose restart odoo       # restart Odoo sau khi sửa config / addon
docker compose down               # dừng (dữ liệu vẫn giữ)
docker compose logs -f db         # log PostgreSQL
tail -f etc/odoo.log              # log Odoo
```

Cập nhật lên bản Odoo 20 mới nhất (bản build hằng ngày):

```bash
docker compose pull
docker compose up -d
```

Cài hoặc nâng cấp module bằng dòng lệnh (`exec` không đi qua entrypoint, nên phải truyền thông tin DB):

```bash
docker compose exec odoo odoo --db_host db --db_user odoo --db_password odoo \
  -d <ten_db> -u <module> --stop-after-init --no-http      # -i để cài mới, -u để nâng cấp
docker compose restart odoo
```

Tạo khung module mới:

```bash
docker compose exec odoo odoo scaffold my_module /mnt/extra-addons
```

## 8. Addon: tự viết, Enterprise, bên thứ 3

`etc/odoo.conf` đã khai báo sẵn:

```
addons_path = /mnt/extra-addons/enterprise,/mnt/extra-addons/third-party,/mnt/extra-addons/third-party/*,/mnt/extra-addons
```

Thư mục nào rỗng thì Odoo bỏ qua, nên chạy bản Community không cần làm gì thêm. Sau khi thêm addon: chạy `docker compose restart odoo`, bật chế độ developer, vào **Apps → Update Apps List** rồi cài.

### Addon tự viết

Đặt thẳng trong `addons/`, ví dụ `addons/my_module/__manifest__.py`.

### Odoo Enterprise

Cần có subscription Odoo Enterprise.

1. Lấy source Enterprise **20.0**, cùng phiên bản với image:
   - Có quyền GitHub (partner): `git clone --depth=1 -b 20.0 git@github.com:odoo/enterprise.git /tmp/enterprise`
   - Hoặc tải bản *Enterprise source (tgz)* tại https://www.odoo.com/page/download (đăng nhập bằng tài khoản subscription), rồi giải nén.
2. Copy các thư mục module vào `addons/enterprise/`. Phải có file `addons/enterprise/web_enterprise/__manifest__.py`, không lồng thêm một cấp:
   ```bash
   cp -r /tmp/enterprise/* addons/enterprise/
   sudo chmod -R 777 addons
   docker compose restart odoo
   ```
3. Database mới: cài app bất kỳ là tự dùng giao diện Enterprise. Database Community đang có: vào Apps, bỏ bộ lọc "Apps", tìm `web_enterprise` rồi cài.
4. Nhập mã subscription trong **Settings → General Settings**.

### App bên thứ 3

- File zip từ Odoo Apps Store: giải nén sao cho có `addons/third-party/<module>/__manifest__.py`.
- Repo git chứa nhiều module (OCA, ...): clone nguyên repo vào một thư mục con, Odoo tự quét nhờ `third-party/*`:
  ```bash
  git clone --depth=1 -b 20.0 https://github.com/OCA/web.git addons/third-party/oca-web
  ```
- Kiểm tra `"version": "20.0.x.y.z"` trong `__manifest__.py`, và các module mà app phụ thuộc cũng phải có.

### Thư viện Python cài thêm

Nếu addon khai báo `external_dependencies` (python):

1. Thêm tên thư viện vào `etc/requirements.txt`.
2. Bỏ comment dòng sau trong `docker-compose.yml`:
   ```yaml
   - ./entrypoint.sh:/entrypoint.sh
   ```
3. `docker compose up -d`. Thư viện được cài mỗi lần container khởi động (cần internet). `entrypoint.sh` đã dùng `pip --break-system-packages` vì image chạy Ubuntu noble (PEP 668).

## 9. AI và pgvector

Image `pgvector/pgvector:pg17` có sẵn extension `vector` mà các tính năng AI của Odoo cần. Kiểm tra:

```bash
docker compose exec db psql -U odoo -d postgres -c "SELECT name, default_version FROM pg_available_extensions WHERE name = 'vector';"
```

User `odoo` là superuser nên Odoo tự chạy `CREATE EXTENSION vector` khi cài module AI. Muốn bật tay cho một database:

```bash
docker compose exec db psql -U odoo -d <ten_db> -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

## 10. Chạy production sau Nginx

1. Trong `etc/odoo.conf`: đổi `admin_passwd`, giữ `proxy_mode = True`. Nếu một instance chạy nhiều domain thì bật `dbfilter = ^%d$`. Muốn ẩn trang quản lý database thì đặt `list_db = False`.
2. Từ Odoo 16, live chat và thông báo realtime đi qua **websocket** `/websocket` (đường dẫn `/longpolling/` cũ không còn). Request websocket phải được chuyển sang port live chat (`20012`, tức `gevent_port` 8072 trong container):

```nginx
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

upstream odoo_one      { server 127.0.0.1:10012; }
upstream odoo_one_chat { server 127.0.0.1:20012; }

server {
    listen 80;
    server_name erp.example.com;

    client_max_body_size 200m;
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;

    proxy_set_header X-Forwarded-Host  $http_host;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP         $remote_addr;

    location /websocket {
        proxy_pass http://odoo_one_chat;
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }

    location / {
        proxy_pass http://odoo_one;
        proxy_redirect off;
    }

    gzip on;
    gzip_types text/css text/plain application/json application/javascript;
}
```

Cài HTTPS: `sudo certbot --nginx -d erp.example.com`.

Khi đã đi qua Nginx thì không cần mở port 10012/20012 ra internet. Có thể đổi trong `docker-compose.yml` thành `"127.0.0.1:10012:8069"` và `"127.0.0.1:20012:8072"`.

## 11. Sao lưu và khôi phục

**Cách 1, qua giao diện web**: `/web/database/manager` → **Backup** (chọn định dạng *zip* để lấy cả file đính kèm) và **Restore**. Cách này tiện cho database nhỏ.

**Cách 2, bằng dòng lệnh** (nên dùng với database lớn):

```bash
DB=ten_db
# sao lưu: database + filestore
docker compose exec -T db pg_dump -U odoo -Fc "$DB" > "$DB.dump"
tar czf "$DB-filestore.tgz" -C etc/files/filestore "$DB"

# khôi phục
docker compose exec -T db createdb -U odoo "$DB"
docker compose exec -T db pg_restore -U odoo -d "$DB" --no-owner < "$DB.dump"
mkdir -p etc/files/filestore && tar xzf "$DB-filestore.tgz" -C etc/files/filestore
docker compose restart odoo
```

Thư mục `etc/backups/` dành cho module sao lưu tự động (ví dụ `auto_backup`, cần `pysftp` trong `etc/requirements.txt`).

## 12. Nâng cấp từ bản cũ (Odoo 16, postgres 15)

- PostgreSQL 17 **không đọc được** thư mục `postgresql/` do postgres 15 tạo. Phải dump bằng stack cũ rồi restore sang stack mới:

```bash
# ở thư mục cũ, stack cũ (postgres:15) vẫn đang chạy
docker compose exec -T db pg_dumpall -U odoo > all.sql
docker compose down
mv postgresql postgresql-pg15 && mkdir postgresql && sudo chmod 777 postgresql
# thay docker-compose.yml, entrypoint.sh, etc/odoo.conf bằng bản ở nhánh 20.0, sau đó:
docker compose up -d db
docker compose exec -T db psql -U odoo -d postgres < all.sql
docker compose up -d
```

- Database Odoo 16 **không chạy thẳng** trên Odoo 20. Phải migrate qua [Odoo Upgrade](https://upgrade.odoo.com) (Enterprise) hoặc [OpenUpgrade](https://github.com/OCA/OpenUpgrade) (Community). Addon tự viết và app bên thứ 3 cũng phải có bản cho 20.0.

## 13. Xử lý sự cố

Luôn bắt đầu bằng `docker compose ps` và `tail -100 etc/odoo.log`.

| Hiện tượng | Nguyên nhân và cách xử lý |
|---|---|
| `Running as user 'root' is a security risk.` | Chỉ là cảnh báo, vì container chạy bằng `user: root` để cài được thư viện Python. Odoo vẫn chạy bình thường |
| `This process is multi-threaded, use of fork() may lead to deadlocks` | Do `dev_mode = reload` đang bật cùng `workers > 0`. Tắt `dev_mode` (mặc định đã tắt) hoặc đặt `workers = 0` |
| `docker compose logs` không thấy log Odoo | Log được ghi vào `etc/odoo.log`. Xem bằng `tail -f etc/odoo.log`, hoặc bỏ dòng `logfile` trong `odoo.conf` |
| Container `odoo` ở trạng thái `Restarting` | Xem lỗi trong `etc/odoo.log`. Hay gặp nhất: sai cú pháp `odoo.conf`, addon lỗi, thiếu thư viện Python |
| Log db báo `database files are incompatible with server` | Thư mục `postgresql/` được tạo bởi PostgreSQL bản khác. Xem [mục 12](#12-nâng-cấp-từ-bản-cũ-odoo-16-postgres-15) |
| `Permission denied` trên `etc/` hoặc `addons/` | `sudo chmod -R 777 addons etc postgresql` |
| `port is already allocated` | Port đã có chương trình khác dùng. Đổi port trong `docker-compose.yml`, hoặc tìm chương trình đó bằng `sudo lsof -i :10012` |
| Live chat hoặc thông báo không cập nhật realtime | Nginx chưa chuyển `/websocket` sang port live chat. Xem [mục 10](#10-chạy-production-sau-nginx) |
| Lỗi inotify `max_user_watches` khi chạy nhiều instance | `echo fs.inotify.max_user_watches=524288 \| sudo tee -a /etc/sysctl.conf && sudo sysctl -p` |
| `run.sh`: `Folder 'odoo-one' already exists` | Đặt tên thư mục khác, hoặc xoá thư mục cũ nếu không còn dùng (**sẽ mất dữ liệu** trong đó) |
