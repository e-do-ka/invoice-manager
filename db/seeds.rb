# デモ用のサンプルデータ。何度実行しても重複しないようにしている。

company = CompanySetting.current
if company.name.include?("未設定") || company.name.include?("設定画面")
  company.update!(
    name: "フリーランス 山田 太郎",
    postal_code: "150-0002",
    address: "東京都渋谷区渋谷1-2-3 サンプルビル 401",
    tel: "03-1234-5678",
    email: "yamada@example.com",
    registration_number: "T1234567890123",
    bank_info: "サンプル銀行 渋谷支店\n普通 1234567\nヤマダ タロウ"
  )
end

if Client.none?
  clients = Client.create!([
    { name: "株式会社サンプル商事", contact_name: "佐藤 一郎", email: "sato@sample-shoji.example.com",
      postal_code: "100-0001", address: "東京都千代田区千代田1-1-1", notes: "毎月末締め・翌月末払い" },
    { name: "有限会社テックラボ", contact_name: "鈴木 花子", email: "suzuki@techlab.example.com",
      postal_code: "220-0011", address: "神奈川県横浜市西区高島2-2-2" },
    { name: "合同会社クリエイトデザイン", contact_name: "高橋 健", email: "takahashi@create-design.example.com",
      postal_code: "530-0001", address: "大阪府大阪市北区梅田3-3-3" },
    { name: "株式会社グリーンフーズ", contact_name: "田中 美咲", email: "tanaka@green-foods.example.com",
      postal_code: "460-0008", address: "愛知県名古屋市中区栄4-4-4", notes: "請求書はPDFでメール送付" }
  ])

  today = Date.current

  # 過去5ヶ月分の入金済み請求書
  (1..5).each do |months_ago|
    issue = (today << months_ago).beginning_of_month + 24
    clients.first(2 + months_ago % 2).each_with_index do |client, i|
      invoice = Invoice.new(
        client: client,
        issue_date: issue + i,
        due_date: ((issue + i) >> 1).end_of_month,
        status: :paid,
        paid_on: ((issue + i) >> 1).end_of_month - 3,
        invoice_items_attributes: [
          { description: "Webサイト保守費用（#{issue.strftime('%-m月')}分）", quantity: 1, unit_price: 50_000 + i * 10_000 },
          { description: "機能追加・改修対応", quantity: 8 + i * 2, unit_price: 8_000 }
        ]
      )
      invoice.save!
    end
  end

  # 送付済（未入金）… うち1件は期限超過
  Invoice.create!(
    client: clients[1],
    issue_date: today << 2,
    due_date: ((today << 2) >> 1).end_of_month,
    status: :sent,
    notes: "お振込の際は請求書番号をご記載ください。",
    invoice_items_attributes: [
      { description: "業務システム開発（フェーズ2）", quantity: 1, unit_price: 480_000 }
    ]
  )
  Invoice.create!(
    client: clients[2],
    issue_date: today.beginning_of_month + 1,
    due_date: (today >> 1).end_of_month,
    status: :sent,
    invoice_items_attributes: [
      { description: "LPデザイン制作", quantity: 1, unit_price: 120_000 },
      { description: "バナー制作", quantity: 5, unit_price: 15_000 }
    ]
  )

  # 下書き
  Invoice.create!(
    client: clients[3],
    issue_date: today,
    due_date: (today >> 1).end_of_month,
    status: :draft,
    invoice_items_attributes: [
      { description: "ECサイト構築（着手金）", quantity: 1, unit_price: 300_000 }
    ]
  )

  puts "Seeded: #{Client.count} clients, #{Invoice.count} invoices"
end
