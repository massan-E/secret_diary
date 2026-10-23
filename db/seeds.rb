alice = User.find_or_create_by!(email_address: "alice@example.com") { |u| u.password = "password" }
bob   = User.find_or_create_by!(email_address: "bob@example.com")   { |u| u.password = "password" }
alice.diaries.find_or_create_by!(title: "アリスの日記") { |d| d.body = "誰にも言えない秘密" }
bob.diaries.find_or_create_by!(title: "ボブの日記") { |d| d.body = "ボブだけの秘密" }
