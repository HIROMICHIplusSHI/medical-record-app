class CreateInitialDemoUsers < ActiveRecord::Migration[7.2]
  # 【無効化済み】本番環境のデモアカウント作成は db/seeds.rb に一本化した。
  #
  # 経緯:
  #   このマイグレーションは User モデルを直接使うデータマイグレーションで、
  #   本番環境でのみ実行される（開発・テストでは早期 return）ため、
  #   ローカルでも CI でも実行されない死角になっていた。
  #   その後 Phase 7 で User に作成時バリデーション
  #   （利用規約同意・プライバシーポリシー同意・招待コード）が追加された結果、
  #   本番デプロイ時に ActiveRecord::RecordInvalid で db:migrate が失敗するようになった。
  #
  #   また seeds と重複してデモアカウントを作るため、
  #   先に走るこちらが admin@example.com を別パスワードで作ってしまい、
  #   ドキュメント記載のパスワードでログインできなくなる問題もあった。
  #
  # 対応:
  #   デモデータの投入責務は db/seeds.rb に集約し、本マイグレーションは no-op とする。
  #   （適用済みバージョンとして記録を残すためファイル自体は削除しない）
  def up
    # no-op
  end

  def down
    # no-op
  end
end
