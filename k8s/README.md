# Triển khai AWS EKS bằng GitHub Actions

Workflow `.github/workflows/deploy-eks.yml` chạy thủ công từ Actions → Deploy to AWS EKS.
Chọn đúng nhánh và môi trường:

| Nhánh | GitHub Environment / Spring profile |
| --- | --- |
| dev | dev |
| UAT | staging |
| main | prod |

Workflow kiểm thử với database CI tạm thời, build JAR, sau đó build và push image lên
ECR với tag duy nhất theo commit/run và triển khai EKS. Không chạy migration trực tiếp
vào database thật từ GitHub runner; Liquibase chạy khi pod ứng dụng khởi động.

## Cấu hình một lần trên AWS và GitHub

1. Tạo ECR repository, EKS cluster và namespace riêng cho mỗi môi trường.
2. Tạo GitHub Environments `dev`, `staging`, `prod`. Thiết lập biến cho từng Environment:

   | Variable | Giá trị |
   | --- | --- |
   | `AWS_ROLE_ARN` | IAM role để GitHub OIDC assume |
   | `AWS_REGION` | Region chứa ECR và EKS |
   | `ECR_REPOSITORY` | Tên repository ECR, không phải URL |
   | `EKS_CLUSTER_NAME` | Tên cluster |
   | `K8S_NAMESPACE` | Namespace đã tạo |
   | `KUBECTL_VERSION` | Phiên bản kubectl tương thích cluster, ví dụ `v1.34.1` |

3. Cấu hình IAM OIDC provider `https://token.actions.githubusercontent.com`, audience
   `sts.amazonaws.com`. Trust policy của từng role giới hạn `sub` vào
   `repo:ChinhPV1293/test-codex:environment:dev` (hoặc `staging`/`prod`).
   Không cần lưu AWS access key dài hạn vào GitHub.
4. Role cần quyền push vào ECR repository (`ecr:GetAuthorizationToken` và các quyền
   upload layer/put image), `eks:DescribeCluster`. Thêm EKS access entry và quyền
   Kubernetes phù hợp để đọc namespace/secret metadata, apply Deployment/Service
   và theo dõi rollout trong namespace đích. Không cấp cluster-admin chỉ để deploy.
5. Tạo Kubernetes Secret `test-codex-db` trong mỗi namespace bằng công cụ quản lý
   secret của bạn, với ba key `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`.
   Dùng MySQL/RDS và tài khoản riêng cho từng môi trường. Với staging/prod,
   cấu hình TLS xác minh máy chủ trong JDBC URL và CA tin cậy. Nếu CA cần bổ sung,
   mount trust store bằng cấu hình hạ tầng trước khi deploy.
6. Đảm bảo pod kết nối được MySQL/RDS qua network/security group; tài khoản DB cần
   quyền DDL cho Liquibase. GitHub runner phải truy cập được EKS API. Nếu cluster
   chỉ có private endpoint, đổi `runs-on` của job deploy sang self-hosted runner
   có đường mạng vào VPC.
7. Cấu hình deployment branch rules cho GitHub Environments theo bảng trên; có thể
   bật required reviewers cho prod. Workflow cũng kiểm tra nhánh trước khi build.

Workflow không tạo cluster, IAM, database, namespace hay Secret. Service là ClusterIP,
chưa công khai ra Internet; thêm Ingress/ALB theo domain và TLS của hạ tầng thực tế.
Probe TCP chỉ kiểm tra cổng server; hiện ứng dụng chưa có health endpoint nghiệp vụ.

## Rollout và rollback

Workflow chờ rollout tối đa 5 phút và báo lỗi nếu không thành công. Nó không tự rollback
migration hoặc ứng dụng. Xem log pod để chẩn đoán. Với migration tương thích ngược,
có thể rollback Deployment bằng `kubectl rollout undo deployment/test-codex -n <namespace>`.
Rollback schema phải được đánh giá riêng; không tự chạy Liquibase rollback trên prod.
