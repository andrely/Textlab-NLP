Gem::Specification.new do |s|
  s.name = 'Textlab-NLP'
  s.version = '0.0.1'
  s.date = '2013-09-03'
  s.summary = 'Textlaboratory shared library.'
  s.description = 'Textlaboratory shared library.'
  s.authors = ['Andre Lynum']
  s.email = 'andrely@idi.ntnu.no'
  s.files = Dir['textlabnlp/lib/*.rb'] + ['lib/config_default.json']
  s.homepage = ''
  s.license = ''
  s.add_dependency('deep_merge', ">=1.0")
end
