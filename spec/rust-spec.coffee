# Utilities
token = (value, scope) ->
	scopes: [
		'source.rust'
		(if Array.isArray scope
     	scope
     else
       [scope])...
	]
	value: value


expectToken = (tokens, lineN, tokenN, value, scope) ->
	expect(tokens[lineN][tokenN]).toEqual token value, scope

# Main
describe 'atom-language-rust', ->
	grammar = null
	
	# Setup
	beforeEach ->
		waitsForPromise ->
			atom.packages.activatePackage 'language-rust'
		runs ->
			grammar = atom.grammars.grammarForScopeName('source.rust')
	
	it 'should be ready to parse', ->
		expect(grammar).toBeDefined()
		expect(grammar.scopeName).toBe 'source.rust'
	
	# Tests
	describe 'when tokenizing comments', ->
		it 'should recognize line comments', ->
			tokens = grammar.tokenizeLines('// test')
			expectToken tokens, 0, 0,
				'//',
				'comment.line.rust'
			expectToken tokens, 0, 1,
				' test',
				'comment.line.rust'
				
		it 'should recognize multiline comments', ->
			tokens = grammar.tokenizeLines '/*\ntest\n*/'
			expectToken tokens, 0, 0,
				'/*',
				'comment.block.rust'
			expectToken tokens, 1, 0,
				'test',
				'comment.block.rust'
			expectToken tokens, 2, 0,
				'*/',
				'comment.block.rust'
		
		it 'should nest multiline comments', ->
			tokens = grammar.tokenizeLines '/*\n/*\n*/\n*/'
			expectToken tokens, 0, 0,
				'/*',
				'comment.block.rust'
			expectToken tokens, 1, 0,
				'/*',
				'comment.block.rust'
			expectToken tokens, 2, 0,
				'*/',
				'comment.block.rust'
			expectToken tokens, 3, 0,
				'*/',
				'comment.block.rust'
	
	describe 'when tokenizing doc comments', ->
		it 'should recognize line doc comments', ->
			tokens = grammar.tokenizeLines('//! test\n/// test')
			expectToken tokens, 0, 0,
				'//! ',
				'comment.line.documentation.rust'
			expectToken tokens, 0, 1,
				'test',
				'comment.line.documentation.rust'
			expectToken tokens, 1, 0,
				'/// ',
				'comment.line.documentation.rust'
			expectToken tokens, 1, 1,
				'test',
				'comment.line.documentation.rust'
		
		it 'should recognize block doc comments', ->
			tokens = grammar.tokenizeLines('/**\ntest\n*/')
			expectToken tokens, 0, 0,
				'/**',
				['comment.block.documentation.rust', 'invalid.deprecated.rust']
			expectToken tokens, 1, 0,
				'test',
				'comment.block.documentation.rust'
			expectToken tokens, 2, 0,
				'*/',
				['comment.block.documentation.rust', 'invalid.deprecated.rust']
