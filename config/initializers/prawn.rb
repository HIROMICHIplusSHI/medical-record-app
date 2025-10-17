# Prawn PDF設定
require 'prawn'

# IPAフォントのダウンロードURL（Noto Sans JP代替）
# 本番環境ではフォントファイルを配置してください
PRAWN_FONT_PATH = Rails.root.join('lib', 'fonts')

# フォントディレクトリが存在しない場合は作成
FileUtils.mkdir_p(PRAWN_FONT_PATH) unless File.directory?(PRAWN_FONT_PATH)

# デフォルト設定
Prawn::Document.generate('/dev/null') do
  # 初期化時にフォントパスを設定
  font_families.update(
    'NotoSansJP' => {
      normal: Rails.root.join('lib', 'fonts', 'NotoSansJP-Regular.ttf').to_s,
      bold: Rails.root.join('lib', 'fonts', 'NotoSansJP-Bold.ttf').to_s
    }
  ) if File.exist?(Rails.root.join('lib', 'fonts', 'NotoSansJP-Regular.ttf'))
end
