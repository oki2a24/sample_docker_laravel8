# sample_docker_php
Laravel 8 に関して、開発環境と Docker 化したサーバ環境のサンプル Docker Compose です。

## 開発環境のセットアップ
`composer create-project` は対象ディレクトリが空以外の場合は失敗するため、一度適当なディレクトリにインストール後、移動しています。

```bash
cp .env.docker-compose_example
docker-compose up -d
docker-compose exec app bash
composer create-project --prefer-dist laravel/laravel:8 tmp
mv tmp/* tmp/.[^\.]* .
rm -rf tmp
```
