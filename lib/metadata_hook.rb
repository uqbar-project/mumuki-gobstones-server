class MetadataHook < Mumukit::Hook
  def metadata
    {language: {
        name: 'gobstones',
        icon: {type: 'devicon', name: 'gobstones'},
        version: '1.4.1',
        extension: 'gbs',
        ace_mode: 'gobstones'
    },
     test_framework: {
         name: 'stones-spec',
         test_extension: 'yml'
     }}
  end
end