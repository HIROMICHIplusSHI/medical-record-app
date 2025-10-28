# frozen_string_literal: true

# Rack::Attack設定
# ブルートフォース攻撃・DDoS攻撃対策

# テスト環境では無効化（既存テストへの影響を防ぐため）
return if Rails.env.test?

# Rack::Attack有効化
module Rack
  class Attack
    ### セーフリスト（IPホワイトリスト） ###

    # ローカルホストからのアクセスは常に許可
    Rack::Attack.safelist('allow-localhost') do |req|
      ['127.0.0.1', '::1'].include?(req.ip)
    end

    ### Throttleルール（レート制限） ###

    # 1. 会員登録エンドポイント
    # 招待コード総当たり攻撃を防ぐため、1分間に5回までに制限
    throttle('registrations/ip', limit: 5, period: 1.minute) do |req|
      req.ip if req.path == '/users' && req.post?
    end

    # 2. ログインエンドポイント
    # クレデンシャルスタッフィング攻撃を防ぐため、1分間に5回までに制限
    throttle('logins/ip', limit: 5, period: 1.minute) do |req|
      req.ip if req.path == '/users/sign_in' && req.post?
    end

    # 3. 一般リクエスト
    # DDoS攻撃を防ぐため、5分間に300回までに制限
    throttle('req/ip', limit: 300, period: 5.minutes, &:ip)

    ### レート制限超過時の処理 ###

    # レート制限超過時のカスタムレスポンス
    self.throttled_responder = lambda do |env|
      match_data = env['rack.attack.match_data']
      now = match_data[:epoch_time]

      headers = {
        'RateLimit-Limit' => match_data[:limit].to_s,
        'RateLimit-Remaining' => '0',
        'RateLimit-Reset' => (now + match_data[:period]).to_s,
        'Content-Type' => 'text/html; charset=utf-8',
      }

      message = <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <title>リクエスト制限</title>
            <style>
              body { font-family: sans-serif; padding: 50px; text-align: center; }
              h1 { color: #d32f2f; }
            </style>
          </head>
          <body>
            <h1>リクエスト制限</h1>
            <p>短時間に多数のリクエストが検出されました。</p>
            <p>しばらく時間をおいてから再度お試しください。</p>
          </body>
        </html>
      HTML

      [429, headers, [message]]
    end

    ### ログ出力 ###

    # レート制限適用時のログ出力
    ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _request_id, payload|
      req = payload[:request]
      Rails.logger.warn(
        "[Rack::Attack] Throttled: #{req.ip} - #{req.path} - #{req.user_agent}"
      )
    end
  end
end
