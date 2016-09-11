describe 'atom-language-rust', ->
  grammar = null
	
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage 'language-rust'
    runs ->
      grammar = atom.grammars.grammarForScopeName('source.rust')
	
  it 'should be ready to parse', ->
    expect(grammar).toBeDefined()
    expect(grammar.scopeName).toBe 'source.rust'
  
  describe 'when tokenizing comments', ->
    it 'should recognize line comments', ->
      tokens = grammar.tokenizeLines('//test')
      expect(tokens[0][0]).toEqual
        scopes: [
          'comment.line.double-slash.rust'
        ]
        value: '//'
			expect(tokens[0][1]).toEqual
				scopes: [
					'comment.line.double-slash.rust'
				]
				value: 'test'
