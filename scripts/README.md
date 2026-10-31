# MySQL thử nghiệm và Liquibase

Yêu cầu: Docker Engine, Docker Compose v2 có hỗ trợ `--wait`, Java 21.
Các script tự xác định đường dẫn nên có thể gọi từ thư mục bất kỳ.

## 1. Khởi động MySQL thật bằng Docker

Từ thư mục gốc project:

```bash
cp scripts/.env.example scripts/.env
# Chỉnh scripts/.env nếu cần, trước lần khởi động đầu tiên.
./scripts/db-up.sh
./scripts/db-check.sh
```

Không ghi đè `.env` đã có. File `.env` được Git bỏ qua. Mật khẩu mẫu chỉ dùng
cho database local. MySQL 8.4 được bind vào `127.0.0.1`, mặc định cổng 3306.
Nếu cổng bận, đổi `DB_PORT` trong `.env`.

## 2. Chạy ứng dụng và migration

File `.env` mẫu cũng tương thích với Bash. Chỉ source file do bạn kiểm soát:

```bash
set -a
source scripts/.env
set +a
export DB_URL="jdbc:mysql://127.0.0.1:${DB_PORT}/${DB_NAME}?allowPublicKeyRetrieval=true&sslMode=DISABLED"
./mvnw spring-boot:run
```

Các tùy chọn TLS trên chỉ dành cho MySQL local ở loopback. Với máy chủ thật,
dùng JDBC URL và cấu hình TLS của máy chủ đó.

Spring Boot tự chạy Liquibase trước khi khởi tạo JPA. Không cần chạy SQL bằng tay.
Changelog gốc: `src/main/resources/db/changelog/db.changelog-master.yaml`.
Migration đầu tiên tạo bảng ví dụ `database_probe`; chưa có dữ liệu nghiệp vụ.
Liquibase ghi lịch sử vào `DATABASECHANGELOG` và dùng `DATABASECHANGELOGLOCK`
để đồng bộ. Khởi động lại không chạy lại changeset đã áp dụng.

Trong terminal khác, kiểm tra migration và thử INSERT/SELECT, rồi ROLLBACK dữ liệu thử:

```bash
./scripts/db-verify-migrations.sh
```

Với cùng các biến môi trường, chạy `./mvnw clean verify` để chạy kiểm thử tích hợp.
Trong môi trường cloud hiện tại, dùng JDK và tham số Maven proxy trong README gốc.

## 3. Dừng database

```bash
./scripts/db-down.sh
```

Script giữ nguyên volume và dữ liệu. Mật khẩu trong `.env` chỉ được MySQL dùng
để khởi tạo volume trống; thay file này không đổi mật khẩu trong volume đã có.

## Thêm migration

Tạo file SQL mới trong `src/main/resources/db/changelog/changes/`, đặt changeset ID
mới và thêm `include` vào changelog gốc. Không sửa changeset đã áp dụng.
`ddl-auto=none` để Liquibase quản lý schema. Dòng `--rollback` trong SQL là chỉ dẫn
cho Liquibase khi rollback có chủ đích; script dừng database không rollback schema.
