# 凭据配置 / Credential configuration

SSH 启动前生成每台设备独立的主机密钥。缺少 shadow 时生成锁定账户配置。部署镜像前请私下设置密码或 SSH authorized_keys，并提供需要的 TLS 密钥。本次未验证硬件启动。

SSH host keys are generated per device by ssh-keygen -A before ssh.service starts. If /etc/shadow is absent, accounts are locked. Before deploying an image, privately provision account passwords or SSH authorized_keys. Supply any required TLS certificate/key privately. Hardware boot has not been verified.

已公开的真实凭据仍须撤销或更换。历史重写不能清除其他人的克隆、Fork 或 GitHub 缓存。

Revoke or rotate real credentials that were exposed. Rewriting history does not remove other clones, forks, or GitHub caches.
