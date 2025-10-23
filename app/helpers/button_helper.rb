# frozen_string_literal: true

# ButtonHelper - 統一されたボタンUIを提供するヘルパーモジュール
# InkFolioブランドデザインに準拠したボタンコンポーネントを提供します
module ButtonHelper
  # 表示ボタン（詳細ページへのリンク）
  # @param text [String] ボタンに表示するテキスト
  # @param path [String] リンク先のパス
  # @param options [Hash] 追加のオプション（class, data等）
  # @return [String] HTMLボタン要素
  def show_button(text, path, options = {})
    default_class = 'bg-accent-primary hover:bg-accent-primary/90 text-white ' \
                    'border-2 border-accent-primary font-medium py-2 px-4 rounded transition-colors'
    link_to text, path, { class: default_class }.merge(options)
  end

  # 編集ボタン（編集ページへのリンク）
  # @param text [String] ボタンに表示するテキスト
  # @param path [String] リンク先のパス
  # @param options [Hash] 追加のオプション（class, data等）
  # @return [String] HTMLボタン要素
  def edit_button(text, path, options = {})
    default_class = 'bg-white hover:bg-greige-100 text-accent-primary border-2 ' \
                    'border-accent-primary font-medium py-2 px-4 rounded transition-colors'
    link_to text, path, { class: default_class }.merge(options)
  end

  # 削除ボタン（DELETEリクエストを送信）
  # @param text [String] ボタンに表示するテキスト
  # @param path [String] リンク先のパス
  # @param options [Hash] 追加のオプション（class, data等）
  # @return [String] HTMLボタン要素
  def delete_button(text, path, options = {})
    default_class = 'bg-accent-danger hover:bg-accent-danger/90 text-white ' \
                    'font-medium py-2 px-4 rounded transition-colors'
    default_data = { turbo_confirm: '本当に削除しますか？' }

    button_to text, path, {
      method: :delete,
      class: default_class,
      data: default_data.merge(options.delete(:data) || {}),
    }.merge(options)
  end

  # 新規作成ボタン（新規作成ページへのリンク）
  # @param text [String] ボタンに表示するテキスト
  # @param path [String] リンク先のパス
  # @param options [Hash] 追加のオプション（class, data等）
  # @return [String] HTMLボタン要素
  def new_button(text, path, options = {})
    default_class = 'bg-accent-primary hover:bg-accent-primary/90 text-white ' \
                    'font-bold py-2 px-4 rounded transition-colors'
    link_to text, path, { class: default_class }.merge(options)
  end

  # 一覧戻るボタン（一覧ページへのリンク）
  # @param text [String] ボタンに表示するテキスト
  # @param path [String] リンク先のパス
  # @param options [Hash] 追加のオプション（class, data等）
  # @return [String] HTMLボタン要素
  def back_button(text, path, options = {})
    default_class = 'bg-accent-secondary hover:bg-accent-secondary/90 text-white ' \
                    'font-bold py-2 px-4 rounded transition-colors'
    link_to text, path, { class: default_class }.merge(options)
  end

  # キャンセルボタン（前のページに戻る）
  # @param text [String] ボタンに表示するテキスト
  # @param path [String] リンク先のパス
  # @param options [Hash] 追加のオプション（class, data等）
  # @return [String] HTMLボタン要素
  def cancel_button(text, path, options = {})
    default_class = 'bg-greige-300 hover:bg-greige-400 text-greige-800 font-bold py-2 px-4 rounded transition-colors'
    link_to text, path, { class: default_class }.merge(options)
  end

  # 検索ボタン（フォーム送信）
  # @param text [String] ボタンに表示するテキスト（デフォルト: "検索"）
  # @param options [Hash] 追加のオプション（class, data等）
  # @return [String] HTMLボタン要素
  def search_button(text = '検索', options = {})
    default_class = 'bg-accent-primary hover:bg-accent-primary/90 text-white ' \
                    'font-bold py-2 px-6 rounded-lg transition-colors'
    submit_tag text, { class: default_class }.merge(options)
  end

  # クリアボタン（検索条件をクリア）
  # @param text [String] ボタンに表示するテキスト
  # @param path [String] リンク先のパス
  # @param options [Hash] 追加のオプション（class, data等）
  # @return [String] HTMLボタン要素
  def clear_button(text, path, options = {})
    default_class = 'bg-accent-secondary hover:bg-accent-secondary/90 text-white ' \
                    'font-bold py-2 px-6 rounded-lg transition-colors'
    link_to text, path, { class: default_class }.merge(options)
  end
end
