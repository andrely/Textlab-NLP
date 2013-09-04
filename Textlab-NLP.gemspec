Gem::Specification.new do |s|
  s.name = 'Textlab-NLP'
  s.version = '0.0.1'
  s.date = '2013-09-03'
  s.summary = 'Textlaboratory shared library.'
  s.description = 'Textlaboratory shared library.'
  s.authors = ['Andre Lynum']
  s.email = 'andrely@idi.ntnu.no'
  s.files = ['lib/globals.rb',
             'lib/logger_mixin.rb',
             'lib/oslo_bergen_tagger.rb',
             'lib/obt_format_reader.rb']
  s.homepage = ''
  s.license = ''
  s.add_dependency('deep_merge', ">=1.0")
end
