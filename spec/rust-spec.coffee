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

currentLine = 0
currentToken = -1

expectToken = (tokens, lineN, tokenN, value, scope) ->
	currentLine = lineN
	currentToken = tokenN
	t = tokens[lineN][tokenN]
	ct = token value, scope
	expect(t.value).toEqual ct.value
	expect(t.scopes).toEqual ct.scopes

expectNext = (tokens, value, scope) ->
	expectToken(tokens, currentLine, currentToken+1, value, scope)

nextLine = ->
	currentLine += 1
	currentToken = -1
	
reset = ->
	currentLine = 0
	currentToken = -1

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
		beforeEach ->
			reset()
		
		it 'should recognize line comments', ->
			tokens = grammar.tokenizeLines('// test')
			expectNext tokens,
				'//',
				'comment.line.rust'
			expectNext tokens,
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
				['comment.block.rust', 'comment.block.rust']
			expectToken tokens, 2, 0,
				'*/',
				['comment.block.rust', 'comment.block.rust']
			expectToken tokens, 3, 0,
				'*/',
				'comment.block.rust'
	
	describe 'when tokenizing doc comments', ->
		beforeEach ->
			reset()
		
		it 'should recognize line doc comments', ->
			tokens = grammar.tokenizeLines('//! test\n/// test')
			expectNext tokens,
				'//! ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'test',
				'comment.line.documentation.rust'
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
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
		
		it 'should parse inline markdown', ->
			tokens = grammar.tokenizeLines('''
				/// *italic*
				/// **bold**
				/// _italic_
				/// __underline__
				/// ***bolditalic***
				''')
			
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'*',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'italic',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'*',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'**',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
			expectNext tokens,
				'bold',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
			expectNext tokens,
				'**',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'_',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'italic',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'_',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'__',
				['comment.line.documentation.rust', 'markup.underline.documentation.rust']
			expectNext tokens,
				'underline',
				['comment.line.documentation.rust', 'markup.underline.documentation.rust']
			expectNext tokens,
				'__',
				['comment.line.documentation.rust', 'markup.underline.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'**',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
			expectNext tokens,
				'*',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'bolditalic',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'*',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'**',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
		
		it 'should parse header markdown', ->
			tokens = grammar.tokenizeLines('''
				/// # h1
				/// ## h2
				/// ### h3
				/// #### h4
				/// ##### h5
				/// ###### h6
				/// ####### h6
				''')
			
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'#',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				' h1',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'##',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				' h2',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'###',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				' h3',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'####',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				' h4',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'#####',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				' h5',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'######',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				' h6',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'######',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				'#',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.invalid.illegal.documentation.rust']
			expectNext tokens,
				' h6',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
		
		it 'should parse link markdown', ->
			tokens = grammar.tokenizeLines('''
				/// [text]()
				/// [text](http://link.com)
				/// [text](http://link.com "title")
				/// ![text](http://link.com)
				/// [text]
				/// [text]: http://link.com
				''')
			
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'[text]',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens,
				'()',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.invalid.illegal.documentation.rust']

			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'[text](',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens,
				'http://link.com',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			expectNext tokens,
				')',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'[text](',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens,
				'http://link.com',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			expectNext tokens,
				' ',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens,
				'"title"',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			expectNext tokens,
				')',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'![text](',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens,
				'http://link.com',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			expectNext tokens,
				')',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'[text]',
				'comment.line.documentation.rust'
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'[text]: ',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens,
				'http://link.com',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			
		it 'should parse code blocks', ->
			tokens = grammar.tokenizeLines('''
				/// text `code` text
				/// ```rust
				/// impl such_code for wow {
				///     type Many = Tokens;
				/// }
				/// ```
				''')
			
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'text ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'`code`',
				['comment.line.documentation.rust', 'markup.code.raw.inline.documentation.rust']
			expectNext tokens,
				' text',
				'comment.line.documentation.rust'
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'```',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			expectNext tokens,
				'rust',
				['comment.line.documentation.rust', 'markup.bold.code.raw.block.name.documentation.rust']
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'impl such_code for wow {',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			nextLine()
			expectNext tokens,
				'///     ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'type Many = Tokens;',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'}',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'```',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
	
	describe 'when tokenizing strings', ->
		#TODO: unicode tests
		beforeEach ->
			reset()
		
		it 'should parse strings', ->
			tokens = grammar.tokenizeLines('"test"')
			expectNext tokens,
				'"',
				'string.quoted.double.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.rust'
			
			reset()
			tokens = grammar.tokenizeLines('"test\\ntset"')
			expectNext tokens,
				'"',
				'string.quoted.double.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.rust'
			expectNext tokens,
				'\\n',
				['string.quoted.double.rust', 'constant.character.escape.rust']
			expectNext tokens,
				'tset',
				'string.quoted.double.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.rust'
		
		it 'should parse byte strings', ->
			tokens = grammar.tokenizeLines('b"test"')
			expectNext tokens,
				'b"',
				'string.quoted.double.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.rust'
			
			reset()
			tokens = grammar.tokenizeLines('b"test\\ntset"')
			expectNext tokens,
				'b"',
				'string.quoted.double.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.rust'
			expectNext tokens,
				'\\n',
				['string.quoted.double.rust', 'constant.character.escape.rust']
			expectNext tokens,
				'tset',
				'string.quoted.double.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.rust'
		
		it 'should parse raw strings', ->
			tokens = grammar.tokenizeLines('r"test"')
			expectNext tokens,
				'r"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
			
			reset()
			tokens = grammar.tokenizeLines('r"test\\ntset"')
			expectNext tokens,
				'r"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test\\ntset',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
			
			reset()
			tokens = grammar.tokenizeLines('r##"test##"#tset"##')
			expectNext tokens,
				'r##"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test##"#tset',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"##',
				'string.quoted.double.raw.rust'
			
			reset()
			tokens = grammar.tokenizeLines('r"test\ntset"')
			expectNext tokens,
				'r"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.raw.rust'
			nextLine()
			expectNext tokens,
				'tset',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
			
			reset()
			tokens = grammar.tokenizeLines('r#"test#"##test"#')
			expectNext tokens,
				'r#"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test#',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"#',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'#',
				['string.quoted.double.raw.rust', 'invalid.illegal.rust']
			expectNext tokens,
				'test',
				[]
		
		it 'should parse raw byte strings', ->
			tokens = grammar.tokenizeLines('br"test"')
			expectNext tokens,
				'br"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
			
			reset()
			tokens = grammar.tokenizeLines('br"test\\ntset"')
			expectNext tokens,
				'br"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test\\ntset',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
			
			reset()
			tokens = grammar.tokenizeLines('rb"test"')
			expectNext tokens,
				'rb',
				['string.quoted.double.raw.rust', 'invalid.illegal.rust']
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
		
		it 'should parse character strings', ->
			tokens = grammar.tokenizeLines('\'a\'')
			#TODO
			
			reset()
			tokens = grammar.tokenizeLines('\'\\n\'')
			#TODO
			
			reset()
			tokens = grammar.tokenizeLines('\'abc\'')
			expectNext tokens,
				'\'',
				'string.quoted.single.rust'
			expectNext tokens,
				'a',
				'string.quoted.single.rust'
			expectNext tokens,
				'bc',
				['string.quoted.single.rust', 'invalid.illegal.rust']
			expectNext tokens,
				'\'',
				'string.quoted.single.rust'
		
		it 'should parse character byte strings', ->
			tokens = grammar.tokenizeLines('b\'a\'')
			#TODO
		
		it 'should parse escape characters', ->
			#TODO
	
	describe 'when tokenizing format strings', ->
		#TODO
