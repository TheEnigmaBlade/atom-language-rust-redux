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

expectNoScope = (tokens, lineN, tokenN, scope) ->
	currentLine = lineN
	currentToken = tokenN
	t = tokens[lineN][tokenN]
	expect(t.scopes).not.toContain scope

expectNext = (tokens, value, scope) ->
	expectToken(tokens, currentLine, currentToken+1, value, scope)

expectSpace = (tokens) ->
	currentToken += 1
	t = tokens[currentLine][currentToken]
	expect(t.value).not.toMatch /\S+/

skip = (n) ->
	if not n?
		n = 1
	currentToken += n

nextLine = ->
	currentLine += 1
	currentToken = -1

reset = ->
	currentLine = 0
	currentToken = -1

tokenize = (grammar, value) ->
	reset()
	grammar.tokenizeLines value

# Main
describe 'atom-language-rust-redux', ->
	grammar = null
	
	# Setup
	
	beforeEach ->
		waitsForPromise ->
			atom.packages.activatePackage 'language-rust-redux'
		runs ->
			grammar = atom.grammars.grammarForScopeName('source.rust')
			
	it 'should be ready to parse', ->
		expect(grammar).toBeDefined()
		expect(grammar.scopeName).toBe 'source.rust'
		
	# Tests
	
	describe 'when tokenizing comments', ->
		it 'should recognize line comments', ->
			tokens = tokenize grammar, '// test'
			expectNext tokens, '//',
				'comment.line.rust'
			expectNext tokens, ' test',
				'comment.line.rust'

		it 'should recognize multiline comments', ->
			tokens = tokenize grammar, '/*\ntest\n*/'
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
			tokens = tokenize grammar, '/*\n/*\n*/\n*/'
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
		it 'should recognize line doc comments', ->
			tokens = tokenize grammar, '//! test\n/// test'
			expectNext tokens, '//!',
				'comment.line.documentation.rust'
			expectNext tokens, ' test',
				'comment.line.documentation.rust'
			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectNext tokens, ' test',
				'comment.line.documentation.rust'
		
		it 'should recognize block doc comments', ->
			tokens = tokenize grammar, '/**\ntest\n*/'
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
			tokens = tokenize grammar, '''
				/// *italic*
				/// **bold**
				/// _italic_
				/// __underline__
				/// ***bolditalic***
				'''

			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '*',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens, 'italic',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens, '*',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']

			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '**',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
			expectNext tokens, 'bold',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
			expectNext tokens, '**',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']

			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '_',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens, 'italic',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens, '_',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']

			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '__',
				['comment.line.documentation.rust', 'markup.underline.documentation.rust']
			expectNext tokens, 'underline',
				['comment.line.documentation.rust', 'markup.underline.documentation.rust']
			expectNext tokens, '__',
				['comment.line.documentation.rust', 'markup.underline.documentation.rust']

			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '**',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
			expectNext tokens, '*',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens, 'bolditalic',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens, '*',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens, '**',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
		
		it 'should parse header markdown', ->
			tokens = tokenize grammar, '''
				/// # h1
				/// ## h2
				/// ### h3
				/// #### h4
				/// ##### h5
				/// ###### h6
				/// ####### h6
				'''

			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '#',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens, ' h1',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']

			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '##',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens, ' h2',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']

			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '###',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens, ' h3',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']

			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '####',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens, ' h4',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']

			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '#####',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens, ' h5',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']

			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '######',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens, ' h6',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']

			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '######',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens, '#',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.invalid.illegal.documentation.rust']
			expectNext tokens, ' h6',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
		
		it 'should parse link markdown', ->
			tokens = tokenize grammar, '''
				/// [text]()
				/// [text](http://link.com)
				/// [text](http://link.com "title")
				/// ![text](http://link.com)
				/// [text]
				/// [text]: http://link.com
				'''
				
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '[',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens, 'text',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.text.documentation.rust']
			expectNext tokens, ']',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens, '()',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.invalid.illegal.documentation.rust']
				
			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '[',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens, 'text',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.text.documentation.rust']
			expectNext tokens, '](',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens, 'http://link.com',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			expectNext tokens, ')',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
				
			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '[',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens, 'text',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.text.documentation.rust']
			expectNext tokens, '](',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens, 'http://link.com',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			expectNext tokens, ' ',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens, '"title"',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			expectNext tokens, ')',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
				
			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '![',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens, 'text',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.text.documentation.rust']
			expectNext tokens, '](',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens, 'http://link.com',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			expectNext tokens, ')',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
				
			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectNext tokens, ' [text]',
				'comment.line.documentation.rust'
				
			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '[',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens, 'text',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.text.documentation.rust']
			expectNext tokens, ']: ',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens, 'http://link.com',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
		
		it 'should parse code blocks', ->
			tokens = tokenize grammar, '''
				/// text `code` text
				/// ```rust
				/// impl such_code for wow {
				///     type Many = Tokens;
				/// }
				/// ```
				'''

			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectNext tokens, ' text ',
				'comment.line.documentation.rust'
			expectNext tokens, '`code`',
				['comment.line.documentation.rust', 'markup.code.raw.inline.documentation.rust']
			expectNext tokens, ' text',
				'comment.line.documentation.rust'

			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectSpace tokens
			expectNext tokens, '```',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			expectNext tokens, 'rust',
				['comment.line.documentation.rust', 'markup.code.raw.block.name.bold.documentation.rust']
			nextLine()
			expectNext tokens, '/// ',
				'comment.line.documentation.rust'
			expectNext tokens, 'impl such_code for wow {',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			nextLine()
			expectNext tokens, '///     ',
				'comment.line.documentation.rust'
			expectNext tokens, 'type Many = Tokens;',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			nextLine()
			expectNext tokens, '/// ',
				'comment.line.documentation.rust'
			expectNext tokens, '}',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			nextLine()
			expectNext tokens, '/// ',
				'comment.line.documentation.rust'
			expectNext tokens, '```',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
		
		it 'should always terminate code blocks under valid conditions (issues 1, 2)', ->
			# Code block in quote
			tokens = tokenize grammar, '''
				/// before text
				/// > ```
				/// > I'm a quoted block of code!
				/// > ```
				/// after text
				'''
			
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectNext tokens, ' before text',
				'comment.line.documentation.rust'
			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectNext tokens, ' > ',
				'comment.line.documentation.rust'
			expectNext tokens, '```',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			nextLine()
			expectNext tokens, '/// > ',
				'comment.line.documentation.rust'
			expectNext tokens, 'I\'m a quoted block of code!',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			nextLine()
			expectNext tokens, '/// > ',
				'comment.line.documentation.rust'
			expectNext tokens, '```',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			nextLine()
			expectNext tokens, '///',
				'comment.line.documentation.rust'
			expectNext tokens, ' after text',
				'comment.line.documentation.rust'
		
	describe 'when tokenizing strings', ->
		#TODO: unicode tests
		it 'should parse strings', ->
			tokens = tokenize grammar, '"test"'
			expectNext tokens, '"',
				'string.quoted.double.rust'
			expectNext tokens, 'test',
				'string.quoted.double.rust'
			expectNext tokens, '"',
				'string.quoted.double.rust'

			tokens = tokenize grammar, '"test\\ntset"'
			expectNext tokens, '"',
				'string.quoted.double.rust'
			expectNext tokens, 'test',
				'string.quoted.double.rust'
			expectNext tokens, '\\n',
				['string.quoted.double.rust', 'constant.character.escape.rust']
			expectNext tokens, 'tset',
				'string.quoted.double.rust'
			expectNext tokens, '"',
				'string.quoted.double.rust'

		it 'should parse byte strings', ->
			tokens = tokenize grammar, 'b"test"'
			expectNext tokens, 'b"',
				'string.quoted.double.rust'
			expectNext tokens, 'test',
				'string.quoted.double.rust'
			expectNext tokens, '"',
				'string.quoted.double.rust'

			tokens = tokenize grammar, 'b"test\\ntset"'
			expectNext tokens, 'b"',
				'string.quoted.double.rust'
			expectNext tokens, 'test',
				'string.quoted.double.rust'
			expectNext tokens, '\\n',
				['string.quoted.double.rust', 'constant.character.escape.rust']
			expectNext tokens, 'tset',
				'string.quoted.double.rust'
			expectNext tokens, '"',
				'string.quoted.double.rust'

		it 'should parse raw strings', ->
			tokens = tokenize grammar, 'r"test"'
			expectNext tokens, 'r"',
				'string.quoted.double.raw.rust'
			expectNext tokens, 'test',
				'string.quoted.double.raw.rust'
			expectNext tokens, '"',
				'string.quoted.double.raw.rust'

			tokens = tokenize grammar, 'r"test\\ntset"'
			expectNext tokens, 'r"',
				'string.quoted.double.raw.rust'
			expectNext tokens, 'test\\ntset',
				'string.quoted.double.raw.rust'
			expectNext tokens, '"',
				'string.quoted.double.raw.rust'

			tokens = tokenize grammar, 'r##"test##"#tset"##'
			expectNext tokens, 'r##"',
				'string.quoted.double.raw.rust'
			expectNext tokens, 'test##"#tset',
				'string.quoted.double.raw.rust'
			expectNext tokens, '"##',
				'string.quoted.double.raw.rust'

			tokens = tokenize grammar, 'r"test\ntset"'
			expectNext tokens, 'r"',
				'string.quoted.double.raw.rust'
			expectNext tokens, 'test',
				'string.quoted.double.raw.rust'
			nextLine()
			expectNext tokens, 'tset',
				'string.quoted.double.raw.rust'
			expectNext tokens, '"',
				'string.quoted.double.raw.rust'

			tokens = tokenize grammar, 'r#"test#"##test"#'
			expectNext tokens, 'r#"',
				'string.quoted.double.raw.rust'
			expectNext tokens, 'test#',
				'string.quoted.double.raw.rust'
			expectNext tokens, '"#',
				'string.quoted.double.raw.rust'
			expectNext tokens, '#',
				['string.quoted.double.raw.rust', 'invalid.illegal.rust']
			expectNext tokens, 'test',
				[]

		it 'should parse raw byte strings', ->
			tokens = tokenize grammar, 'br"test"'
			expectNext tokens, 'br"',
				'string.quoted.double.raw.rust'
			expectNext tokens, 'test',
				'string.quoted.double.raw.rust'
			expectNext tokens, '"',
				'string.quoted.double.raw.rust'

			tokens = tokenize grammar, 'br"test\\ntset"'
			expectNext tokens, 'br"',
				'string.quoted.double.raw.rust'
			expectNext tokens, 'test\\ntset',
				'string.quoted.double.raw.rust'
			expectNext tokens, '"',
				'string.quoted.double.raw.rust'

			tokens = tokenize grammar, 'rb"test"'
			expectNext tokens, 'rb',
				['string.quoted.double.raw.rust', 'invalid.illegal.rust']
			expectNext tokens, '"',
				'string.quoted.double.raw.rust'
			expectNext tokens, 'test',
				'string.quoted.double.raw.rust'
			expectNext tokens, '"',
				'string.quoted.double.raw.rust'

		it 'should parse character strings', ->
			tokens = tokenize grammar, '\'a\''
			#TODO

			tokens = tokenize grammar, '\'\\n\''
			#TODO

			tokens = tokenize grammar, '\'abc\''
			expectNext tokens, '\'',
				'string.quoted.single.rust'
			expectNext tokens, 'a',
				'string.quoted.single.rust'
			expectNext tokens, 'bc',
				['string.quoted.single.rust', 'invalid.illegal.rust']
			expectNext tokens, '\'',
				'string.quoted.single.rust'

		it 'should parse character byte strings', ->
			tokens = tokenize grammar, 'b\'a\''
			#TODO

		it 'should parse escape characters', ->
			#TODO

	describe 'when tokenizing format strings', ->
		#TODO

	describe 'when tokenizing floating-point literals', ->
		it 'should parse without type', ->
			tokens = tokenize grammar, '4.2'
			expectNext tokens, '4.2',
				'constant.numeric.float.rust'

			tokens = tokenize grammar, '4_2.0'
			expectNext tokens, '4_2.0',
				'constant.numeric.float.rust'

			tokens = tokenize grammar, '0_________0.6'
			expectNext tokens, '0_________0.6',
				'constant.numeric.float.rust'

		it 'should parse with type', ->
			tokens = tokenize grammar, '4f32'
			expectNext tokens, '4f32',
				'constant.numeric.float.rust'

			tokens = tokenize grammar, '4f64'
			expectNext tokens, '4f64',
				'constant.numeric.float.rust'

			tokens = tokenize grammar, '4.2f32'
			expectNext tokens, '4.2f32',
				'constant.numeric.float.rust'

			tokens = tokenize grammar, '3_________3f32'
			expectNext tokens, '3_________3f32',
				'constant.numeric.float.rust'

		it 'should parse with exponents', ->
			tokens = tokenize grammar, '3e8'
			expectNext tokens, '3e8',
				'constant.numeric.float.rust'

			tokens = tokenize grammar, '3E8'
			expectNext tokens, '3E8',
				'constant.numeric.float.rust'

			tokens = tokenize grammar, '3e+8'
			expectNext tokens, '3e+8',
				'constant.numeric.float.rust'

			tokens = tokenize grammar, '3e-8'
			expectNext tokens, '3e-8',
				'constant.numeric.float.rust'

			tokens = tokenize grammar, '2.99e8'
			expectNext tokens, '2.99e8',
				'constant.numeric.float.rust'

			tokens = tokenize grammar, '6.626e-34'
			expectNext tokens, '6.626e-34',
				'constant.numeric.float.rust'

			tokens = tokenize grammar, '3e8f64'
			expectNext tokens, '3e8f64',
				'constant.numeric.float.rust'

	describe 'when tokenizing integer literals', ->
		it 'should parse decimal', ->
			tokens = tokenize grammar, '13'
			expectNext tokens, '13',
				'constant.numeric.integer.decimal.rust'

			tokens = tokenize grammar, '1_013'
			expectNext tokens, '1_013',
				'constant.numeric.integer.decimal.rust'

			tokens = tokenize grammar, '_031'
			expectNoScope tokens, 0, 0,
				'constant.numeric.integer.decimal.rust'

		it 'should parse type suffixes', ->
			val = 2
			for type in ['u8', 'u16', 'u32', 'u64', 'u128', 'usize', 'i8', 'i16', 'i32', 'i64', 'i128', 'isize']
				tokens = tokenize grammar, "#{val}#{type}"
				expectNext tokens, "#{val}#{type}",
					'constant.numeric.integer.decimal.rust'
				val *= 2

		it 'should parse invalid type suffixes', ->
			val = 2
			for type in ['int', 'uint', 'is', 'us']
				tokens = tokenize grammar, "#{val}#{type}"
				expectNext tokens, "#{val}",
					'constant.numeric.integer.decimal.rust'
				expectNext tokens, "#{type}",
					['constant.numeric.integer.decimal.rust', 'invalid.illegal.rust']
				val *= 2

		it 'should parse hexadecimal', ->
			tokens = tokenize grammar, '0x123'
			expectNext tokens, '0x123',
				'constant.numeric.integer.hexadecimal.rust'

			tokens = tokenize grammar, '0xbeeF'
			expectNext tokens, '0xbeeF',
				'constant.numeric.integer.hexadecimal.rust'

			tokens = tokenize grammar, '0x1_2_3'
			expectNext tokens, '0x1_2_3',
				'constant.numeric.integer.hexadecimal.rust'

			tokens = tokenize grammar, '0x123u8'
			expectNext tokens, '0x123u8',
				'constant.numeric.integer.hexadecimal.rust'

			tokens = tokenize grammar, '0x123us'
			expectNext tokens, '0x123',
				'constant.numeric.integer.hexadecimal.rust'
			expectNext tokens, 'us',
				['constant.numeric.integer.hexadecimal.rust', 'invalid.illegal.rust']

		it 'should parse octal', ->
			tokens = tokenize grammar, '0o123'
			expectNext tokens, '0o123',
				'constant.numeric.integer.octal.rust'

			tokens = tokenize grammar, '0o1_2_3'
			expectNext tokens, '0o1_2_3',
				'constant.numeric.integer.octal.rust'

			tokens = tokenize grammar, '0o123u8'
			expectNext tokens, '0o123u8',
				'constant.numeric.integer.octal.rust'

			tokens = tokenize grammar, '0o123us'
			expectNext tokens, '0o123',
				'constant.numeric.integer.octal.rust'
			expectNext tokens, 'us',
				['constant.numeric.integer.octal.rust', 'invalid.illegal.rust']

		it 'should parse binary', ->
			tokens = tokenize grammar, '0b1111011'
			expectNext tokens, '0b1111011',
				'constant.numeric.integer.binary.rust'

			tokens = tokenize grammar, '0b1_11_10_11'
			expectNext tokens, '0b1_11_10_11',
				'constant.numeric.integer.binary.rust'

			tokens = tokenize grammar, '0b1111011u8'
			expectNext tokens, '0b1111011u8',
				'constant.numeric.integer.binary.rust'

			tokens = tokenize grammar, '0b1111011us'
			expectNext tokens, '0b1111011',
				'constant.numeric.integer.binary.rust'
			expectNext tokens, 'us',
				['constant.numeric.integer.binary.rust', 'invalid.illegal.rust']

	describe 'when tokenizing boolean literals', ->
		it 'should parse them', ->
			tokens = tokenize grammar, 'true'
			expectNext tokens, 'true',
				'constant.language.boolean.rust'

			tokens = tokenize grammar, 'false'
			expectNext tokens, 'false',
				'constant.language.boolean.rust'

	describe 'when tokenizing variable type declarations', ->
		it 'should parse integer variations', ->
			for type in ['u8', 'u16', 'u32', 'u64', 'u128', 'usize', 'i8', 'i16', 'i32', 'i64', 'i128', 'isize']
				tokens = tokenize grammar, "let x: #{type};"
				skip 4
				expectNext tokens, type,
					'storage.type.core.rust'

		it 'should parse float variations', ->
			for type in ['f32', 'f64']
				tokens = tokenize grammar, "let x: #{type};"
				skip 4
				expectNext tokens, type,
					'storage.type.core.rust'

		it 'should parse other core types', ->
			for type in ['bool', 'char', 'str', 'String', 'Self', 'Option', 'Result']
				tokens = tokenize grammar, "let x: #{type};"
				skip 4
				expectNext tokens, type,
					'storage.type.core.rust'

		it 'should parse std types', ->
			for type in ['Path', 'PathBuf', 'Arc', 'Weak', 'Box', 'Rc', 'Vec', 'VecDeque', 'LinkedList', 'HashMap', 'BTreeMap', 'HashSet', 'BTreeSet', 'BinaryHeap']
				tokens = tokenize grammar, "let x: #{type};"
				skip 4
				expectNext tokens, type,
					'storage.class.std.rust'

	# Incomplete

	describe 'when tokenizing impl', ->
		it 'should parse basic', ->
			tokens = tokenize grammar, 'impl Cookie {}'
			expectNext tokens, 'impl',
				'storage.type.impl.rust'
			expectSpace tokens
			expectNext tokens, 'Cookie',
				'entity.name.type.rust'
			expectSpace tokens
			expectNext tokens, '{',
				'punctuation.brace.rust'

		it 'should parse for', ->
			tokens = tokenize grammar, 'impl Eat for Cookie {}'
			expectNext tokens, 'impl',
				'storage.type.impl.rust'
			expectSpace tokens
			expectNext tokens, 'Eat',
				'entity.name.type.rust'
			expectSpace tokens
			expectNext tokens, 'for',
				'keyword.other.for.rust'
			expectSpace tokens
			expectNext tokens, 'Cookie',
				[]
			expectSpace tokens
			expectNext tokens, '{',
				'punctuation.brace.rust'

		it 'should parse where', ->
			tokens = tokenize grammar, 'impl Eat where Cookie: Delicious {}'
			expectNext tokens, 'impl',
				'storage.type.impl.rust'
			expectSpace tokens
			expectNext tokens, 'Eat',
				'entity.name.type.rust'
			expectSpace tokens
			expectNext tokens, 'where',
				'keyword.other.where.rust'
			expectNext tokens, ' Cookie',
				[]
			expectNext tokens, ':',
				'keyword.operator.misc.rust'
			expectNext tokens, ' Delicious ',
				[]
			expectNext tokens, '{',
				'punctuation.brace.rust'

		it 'should parse for and where', ->
			tokens = tokenize grammar, 'impl Eat for Cookie where Cookie: Delicious {}'
			expectNext tokens, 'impl',
				'storage.type.impl.rust'
			expectSpace tokens
			expectNext tokens, 'Eat',
				'entity.name.type.rust'
			expectSpace tokens
			expectNext tokens, 'for',
				'keyword.other.for.rust'
			expectSpace tokens
			expectNext tokens, 'Cookie',
				[]
			expectSpace tokens
			expectNext tokens, 'where',
				'keyword.other.where.rust'
			expectNext tokens, ' Cookie',
				[]
			expectNext tokens, ':',
				'keyword.operator.misc.rust'
			expectNext tokens, ' Delicious ',
				[]
			expectNext tokens, '{',
				'punctuation.brace.rust'

		describe 'with type args', ->
			it 'should parse where', ->
				tokens = tokenize grammar, 'impl<Flavor> Eat where Cookie<Flavor>: Oatmeal {}'
				expectNext tokens, 'impl',
					'storage.type.impl.rust'
				expectNext tokens, '<',
					'meta.type_params.rust'
				expectNext tokens, 'Flavor',
					'meta.type_params.rust'
				expectNext tokens, '>',
					'meta.type_params.rust'
				expectSpace tokens
				expectNext tokens, 'Eat',
					'entity.name.type.rust'
				expectSpace tokens
				expectNext tokens, 'where',
					'keyword.other.where.rust'
				expectNext tokens, ' Cookie',
					[]
				expectNext tokens, '<',
					'meta.type_params.rust'
				expectNext tokens, 'Flavor',
					'meta.type_params.rust'
				expectNext tokens, '>',
					'meta.type_params.rust'
				expectNext tokens, ':',
					'keyword.operator.misc.rust'
				expectNext tokens, ' Oatmeal ',
					[]
				expectNext tokens, '{',
					'punctuation.brace.rust'

			it 'should parse for and where', ->
				tokens = tokenize grammar, 'impl<Flavor> Eat for Cookie<Flavor> where Flavor: Oatmeal {}'
				expectNext tokens, 'impl',
					'storage.type.impl.rust'
				expectNext tokens, '<',
					'meta.type_params.rust'
				expectNext tokens, 'Flavor',
					'meta.type_params.rust'
				expectNext tokens, '>',
					'meta.type_params.rust'
				expectSpace tokens
				expectNext tokens, 'Eat',
					'entity.name.type.rust'
				expectSpace tokens
				expectNext tokens, 'for',
					'keyword.other.for.rust'
				expectSpace tokens
				expectNext tokens, 'Cookie',
					[]
				expectNext tokens, '<',
					'meta.type_params.rust'
				expectNext tokens, 'Flavor',
					'meta.type_params.rust'
				expectNext tokens, '>',
					'meta.type_params.rust'
				expectSpace tokens
				expectNext tokens, 'where',
					'keyword.other.where.rust'
				expectNext tokens, ' Flavor',
					[]
				expectNext tokens, ':',
					'keyword.operator.misc.rust'
				expectNext tokens, ' Oatmeal ',
					[]
				expectNext tokens, '{',
					'punctuation.brace.rust'

		describe 'with lifetimes', ->
			it 'should parse where', ->
				tokens = tokenize grammar, 'impl<\'F> Eat where Cookie<\'F>: Oatmeal {}'
				expectNext tokens, 'impl',
					'storage.type.impl.rust'
				expectNext tokens, '<',
					'meta.type_params.rust'
				expectNext tokens, '\'',
					['meta.type_params.rust', 'storage.modifier.lifetime.rust']
				expectNext tokens, 'F',
					['meta.type_params.rust', 'storage.modifier.lifetime.rust', 'entity.name.lifetime.rust']
				expectNext tokens, '>',
					'meta.type_params.rust'
				expectSpace tokens
				expectNext tokens, 'Eat',
					'entity.name.type.rust'
				expectSpace tokens
				expectNext tokens, 'where',
					'keyword.other.where.rust'
				expectNext tokens, ' Cookie',
					[]
				expectNext tokens, '<',
					'meta.type_params.rust'
				expectNext tokens, '\'',
					['meta.type_params.rust', 'storage.modifier.lifetime.rust']
				expectNext tokens, 'F',
					['meta.type_params.rust', 'storage.modifier.lifetime.rust', 'entity.name.lifetime.rust']
				expectNext tokens, '>',
					'meta.type_params.rust'
				expectNext tokens, ':',
					'keyword.operator.misc.rust'
				expectNext tokens, ' Oatmeal ',
					[]
				expectNext tokens, '{',
					'punctuation.brace.rust'

			it 'should parse for and where', ->
				tokens = tokenize grammar, 'impl<Flavor> Eat for Cookie<Flavor> where Flavor: Oatmeal {}'
				expectNext tokens, 'impl',
					'storage.type.impl.rust'
				expectNext tokens, '<',
					'meta.type_params.rust'
				expectNext tokens, 'Flavor',
					'meta.type_params.rust'
				expectNext tokens, '>',
					'meta.type_params.rust'
				expectSpace tokens
				expectNext tokens, 'Eat',
					'entity.name.type.rust'
				expectSpace tokens
				expectNext tokens, 'for',
					'keyword.other.for.rust'
				expectSpace tokens
				expectNext tokens, 'Cookie',
					[]
				expectNext tokens, '<',
					'meta.type_params.rust'
				expectNext tokens, 'Flavor',
					'meta.type_params.rust'
				expectNext tokens, '>',
					'meta.type_params.rust'
				expectSpace tokens
				expectNext tokens, 'where',
					'keyword.other.where.rust'
				expectNext tokens, ' Flavor',
					[]
				expectNext tokens, ':',
					'keyword.operator.misc.rust'
				expectNext tokens, ' Oatmeal ',
					[]
				expectNext tokens, '{',
					'punctuation.brace.rust'

	describe 'when tokenizing the question mark operator thing', ->
		it 'should parse', ->
			tokens = tokenize grammar, 'File::create("foo.txt")?'
			expectNext tokens, 'File',
				[]
			expectNext tokens, '::',
				'keyword.operator.misc.rust'
			expectNext tokens, 'create',
				'entity.name.function.rust'
			expectNext tokens, '(',
				'punctuation.parenthesis.rust'
			expectNext tokens, '"',
				'string.quoted.double.rust'
			expectNext tokens, 'foo.txt',
				'string.quoted.double.rust'
			expectNext tokens, '"',
				'string.quoted.double.rust'
			expectNext tokens, ')',
				'punctuation.parenthesis.rust'
			expectNext tokens, '?',
				'keyword.operator.misc.question-mark.rust'

			tokens = tokenize grammar, 'File::create("foo.txt")?.write_all("test")?'
			expectNext tokens, 'File',
				[]
			expectNext tokens, '::',
				'keyword.operator.misc.rust'
			expectNext tokens, 'create',
				'entity.name.function.rust'
			expectNext tokens, '(',
				'punctuation.parenthesis.rust'
			expectNext tokens, '"',
				'string.quoted.double.rust'
			expectNext tokens, 'foo.txt',
				'string.quoted.double.rust'
			expectNext tokens, '"',
				'string.quoted.double.rust'
			expectNext tokens, ')',
				'punctuation.parenthesis.rust'
			expectNext tokens, '?',
				'keyword.operator.misc.question-mark.rust'
			expectNext tokens, '.',
				[]
			expectNext tokens, 'write_all',
				'entity.name.function.rust'
			expectNext tokens, '(',
				'punctuation.parenthesis.rust'
			expectNext tokens, '"',
				'string.quoted.double.rust'
			expectNext tokens, 'test',
				'string.quoted.double.rust'
			expectNext tokens, '"',
				'string.quoted.double.rust'
			expectNext tokens, ')',
				'punctuation.parenthesis.rust'
			expectNext tokens, '?',
				'keyword.operator.misc.question-mark.rust'

			tokens = tokenize grammar, 'if test()? {}'
			expectNext tokens, 'if',
				'keyword.control.rust'
			expectSpace tokens
			expectNext tokens, 'test',
				'entity.name.function.rust'
			expectNext tokens, '(',
				'punctuation.parenthesis.rust'
			expectNext tokens, ')',
				'punctuation.parenthesis.rust'
			expectNext tokens, '?',
				'keyword.operator.misc.question-mark.rust'
			expectSpace tokens
			expectNext tokens, '{',
				'punctuation.brace.rust'
			expectNext tokens, '}',
				'punctuation.brace.rust'
				
	describe 'when tokenizing function definitions', ->
		it 'should parse basic', ->
			tokens = tokenize grammar, 'fn foo() {}'
			expectNext tokens, 'fn',
				'keyword.other.fn.rust'
			expectSpace tokens
			expectNext tokens, 'foo',
				'entity.name.function.rust'
			expectNext tokens, '() ',
				[]
			expectNext tokens, '{',
				'punctuation.brace.rust'
			expectNext tokens, '}',
				'punctuation.brace.rust'
			
		it 'should parse arguments', ->
			tokens = tokenize grammar, 'fn foo(bar: str) {}'
			expectNext tokens, 'fn',
				'keyword.other.fn.rust'
			expectSpace tokens
			expectNext tokens, 'foo',
				'entity.name.function.rust'
			expectNext tokens, '(bar',
				[]
			expectNext tokens, ':',
				'keyword.operator.misc.rust'
			expectSpace tokens
			expectNext tokens, 'str',
				'storage.type.core.rust'
			expectNext tokens, ') ',
				[]
			expectNext tokens, '{',
				'punctuation.brace.rust'
			expectNext tokens, '}',
				'punctuation.brace.rust'
		
		it 'should parse borrow arguments', ->
			tokens = tokenize grammar, 'fn foo(bar: &str) {}'
			expectNext tokens, 'fn',
				'keyword.other.fn.rust'
			expectSpace tokens
			expectNext tokens, 'foo',
				'entity.name.function.rust'
			expectNext tokens, '(bar',
				[]
			expectNext tokens, ':',
				'keyword.operator.misc.rust'
			expectSpace tokens
			expectNext tokens, '&',
				'keyword.operator.sigil.rust'
			expectNext tokens, 'str',
				'storage.type.core.rust'
			expectNext tokens, ') ',
				[]
			expectNext tokens, '{',
				'punctuation.brace.rust'
			expectNext tokens, '}',
				'punctuation.brace.rust'
		
		it 'should parse lifetime arguments', ->
			tokens = tokenize grammar, 'fn foo(bar: &\'a str) {}'
			expectNext tokens, 'fn',
				'keyword.other.fn.rust'
			expectSpace tokens
			expectNext tokens, 'foo',
				'entity.name.function.rust'
			expectNext tokens, '(bar',
				[]
			expectNext tokens, ':',
				'keyword.operator.misc.rust'
			expectSpace tokens
			expectNext tokens, '&',
				'keyword.operator.sigil.rust'
			expectNext tokens, '\'',
				'storage.modifier.lifetime.rust'
			expectNext tokens, 'a',
				['storage.modifier.lifetime.rust', 'entity.name.lifetime.rust']
			expectSpace tokens
			expectNext tokens, 'str',
				'storage.type.core.rust'
			expectNext tokens, ') ',
				[]
			expectNext tokens, '{',
				'punctuation.brace.rust'
			expectNext tokens, '}',
				'punctuation.brace.rust'
