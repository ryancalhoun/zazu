[![Gem Version](https://badge.fury.io/rb/zazu.svg)](http://badge.fury.io/rb/zazu)

# zazu
Fetch tools and run them

Example:
```ruby
zazu = Zazu.new 'my-script'
zazu.fetch url: 'https://example.com/my_script.sh'
zazu.run ['--environment', 'prod']
```

To fetch os-dependent tools:
```ruby
zazu = Zazu.new 'my-script'
zazu.fetch do |os, arch|
  # os will be :linux, :mac, :windows
  # arch will be 32 or 64
  "https://example.com/my_script-#{os}_#{arch}-bit"
end
```

