Gem::Specification.new do |s|
  s.name = 'qnd_html2page'
  s.version = '0.2.1'
  s.summary = 'Splits HTML into pages suitable for reading like a book.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/qnd_html2page.rb']
  s.add_runtime_dependency('rxfhelper', '~> 0.9', '>=0.9.4')
  s.add_runtime_dependency('ferrum', '~> 0.6', '>=0.6.2')
  s.signing_key = '../privatekeys/qnd_html2page.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/qnd_html2page'
end
