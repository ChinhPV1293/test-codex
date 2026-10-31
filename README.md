# test-codex

Project Spring Boot 3.5.7, Java 21, Maven, Spring Web và Spring Data JPA.

## Cấu hình MySQL

Tạo database `testcodex` trên MySQL và cấp quyền cho tài khoản ứng dụng.
Thiết lập biến môi trường trước khi chạy ứng dụng hoặc kiểm thử:

```bash
export DB_URL=jdbc:mysql://localhost:3306/testcodex
export DB_USERNAME=testcodex
# Thiết lập DB_PASSWORD bằng mật khẩu của tài khoản MySQL.
```

`DB_PASSWORD` bắt buộc phải được cung cấp. Không lưu mật khẩu vào Git.
Có thể thay `DB_URL` để kết nối MySQL ở máy chủ khác.

## Chạy ứng dụng

```bash
./mvnw spring-boot:run
```

Ứng dụng chạy tại cổng 8080. Chưa có API nghiệp vụ; đường dẫn `/` trả về 404.

## Kiểm thử và build

```bash
./mvnw clean verify
```

```bash
java -jar target/test-codex-0.0.1-SNAPSHOT.jar
```

Ứng dụng dùng MySQL qua MySQL Connector/J. Các kiểm thử tích hợp yêu cầu MySQL đang chạy và các biến kết nối ở trên.
Spring Data JPA đã được cấu hình; chưa có entity hoặc repository nghiệp vụ.
Cấu hình nằm trong `src/main/resources/application.properties`.

## Môi trường cloud hiện tại

Nếu `JAVA_HOME` đang trỏ tới JDK khác, chọn JDK 21 trước khi chạy Maven.
Môi trường này yêu cầu Maven đi qua proxy; cấu hình riêng của máy nằm ngoài repository:

```bash
export JAVA_HOME=/workspace/tools/jdk-21
export MAVEN_USER_HOME=/workspace/.m2
export MAVEN_OPTS=-Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts
./mvnw -s /workspace/tools/maven-settings.xml clean verify
./mvnw -s /workspace/tools/maven-settings.xml spring-boot:run
```

## Liquibase và database local

Liquibase tự áp dụng migration khi ứng dụng khởi động. Xem
[scripts/README.md](scripts/README.md) để chạy MySQL bằng Docker, kiểm tra migration
và dừng database mà vẫn giữ dữ liệu.

## Profiles: dev, staging, prod

`application.properties` chứa cấu hình chung; mỗi môi trường có file riêng:

| Profile | File | Cấu hình database |
| --- | --- | --- |
| dev (mặc định) | `application-dev.properties` | MySQL local; cần `DB_PASSWORD` |
| staging | `application-staging.properties` | Cần `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` |
| prod | `application-prod.properties` | Cần `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` |

Chọn đúng một profile bằng biến môi trường hoặc tham số Java:

```bash
export SPRING_PROFILES_ACTIVE=staging
# Cung cấp DB_URL, DB_USERNAME, DB_PASSWORD của staging.
java -jar target/test-codex-0.0.1-SNAPSHOT.jar
# Hoặc:
java -jar target/test-codex-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod
```

Dùng database và tài khoản riêng cho từng môi trường. Với staging/prod, cấu hình
JDBC URL dùng TLS phù hợp với máy chủ, ví dụ `sslMode=VERIFY_IDENTITY` cùng CA tin cậy.
Liquibase được bật ở cả ba profile; ứng dụng cần quyền chạy migration khi khởi động.
File JAR dùng chung cho các môi trường, không chứa mật khẩu database.

## GitHub Actions

`.github/workflows/ci.yml` chạy khi push/PR vào `dev`, `UAT`, `main` hoặc chạy thủ công.
Workflow build và chạy kiểm thử với MySQL 8.4 cho cả ba profile trên database CI
riêng biệt, sau đó lưu JAR và báo cáo test thành artifacts. Các mật khẩu trong
workflow chỉ dành cho MySQL tạm thời của CI, không phải tài khoản staging/prod.

`.github/workflows/deploy-eks.yml` cung cấp CD thủ công lên AWS EKS qua ECR và
GitHub OIDC. Ánh xạ: `dev → dev`, `UAT → staging`, `main → prod`.
Xem [k8s/README.md](k8s/README.md) để cấu hình AWS, GitHub Environments và Secret database.
