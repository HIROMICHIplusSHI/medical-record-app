#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean
bundle exec rake db:migrate

# デモデータ投入（冪等: find_or_create_by! なので再デプロイで重複しない）
# レビュアーが demo@example.com / admin@example.com でログインできるようにする
bundle exec rake db:seed
