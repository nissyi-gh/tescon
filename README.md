# Tescon

RSpec と FactoryBot から、Rails の **minitest-spec** と **fixtures** への移行を支援する CLI ツールです。

変換は **レビュー前提の下書き** です。すべての spec を完全自動で置き換えることは目指していません。対応パターンだけを安全に書き換え、未対応部分はそのまま残します。

## インストール

Gemfile に追加:

```bash
bundle add tescon
```

または:

```bash
gem install tescon
```

開発版:

```bash
gem "tescon", github: "nissyi-gh/tescon"
```

## 使い方

### spec の変換（デフォルト: dry-run）

変換結果は **標準出力** に出し、入力ファイルは変更しません。

```bash
tescon spec/models/user_spec.rb
```

変更ファイル数とルールごとの適用回数は **標準エラー出力** に表示されます。

```
Changed 1 file
  example_dsl     7
  expect_eq       4
  rspec_describe  1
  subject         3
```

上書きする場合:

```bash
tescon --write spec/models/user_spec.rb
```

別ファイルに書き出す場合:

```bash
tescon -o test/models/user_spec.rb spec/models/user_spec.rb
```

複数ファイル:

```bash
tescon spec/models/user_spec.rb spec/models/post_spec.rb
```

### FactoryBot の fixture ヒント

`create` / `build` などの呼び出しを解析し、fixtures 用の YAML 案を出力します（ソースは変更しません）。

```bash
tescon --fixtures-hints spec/models/user_spec.rb
```

リテラルで書かれた属性は YAML に展開し、動的な値は `# TODO` コメントとして残します。

### オプション

| オプション | 説明 |
|-----------|------|
| `-w`, `--write` | 入力ファイルを上書き |
| `-o`, `--output PATH` | 出力先ファイル（`--write` と併用不可） |
| `--fixtures-hints` | fixture YAML ヒントを出力（変換は行わない） |
| `-h`, `--help` | ヘルプ |
| `-v`, `--version` | バージョン |

## 対応している変換（0.1.0）

| ルール | RSpec | minitest-spec |
|--------|-------|---------------|
| `rspec_describe` | `RSpec.describe` | `describe` |
| `example_dsl` | `context` / `specify` | `describe` / `it` |
| `subject` | `subject` / `subject(:name)` | `let(:subject)` / `let` |
| `expect_eq` | `expect(x).to eq(y)` | `expect(x).must_equal y` |
| `expect_eq` | `expect(x).not_to eq(y)` | `expect(x).wont_equal y` |
| `is_expected_eq` | `is_expected.to eq(y)` | `subject.must_equal y`（名前付き subject に対応） |
| `expect_be_nil` | `expect(x).to be_nil` | `expect(x).must_be_nil` |
| `expect_be_nil` | `expect(x).not_to be_nil` | `expect(x).wont_be_nil` |

## 意図的に変換しないもの

- 文字列リテラル内の RSpec 風テキスト
- `type: :model` などの RSpec メタデータ
- `shared_examples` / `shared_context`
- `receive` / `have_received` などのモック
- `let` / `before` / `after`（今後のバージョンで追加予定）
- 上記以外のマッチャー（`be_truthy`, `include`, `raise_error` など）

## 移行後のテスト構成

**デフォルトのゴール** はトップレベルの minitest-spec です。

```ruby
describe User do
  let(:user) { users(:alice) }

  it "has a name" do
    expect(user.name).must_equal "Alice"
  end
end
```

fixtures や `ActiveSupport::TestCase` のヘルパーが必要な場合は、クラス内で `extend Minitest::Spec::DSL` する構成も想定しています（`--style=hybrid` は今後対応予定）。

## 開発

```bash
bin/setup
bundle exec rake test
```

## Contributing

Issue と Pull Request を歓迎します。[Code of Conduct](CODE_OF_CONDUCT.md) に従ってください。

## License

MIT — 詳細は [LICENSE.txt](LICENSE.txt)
