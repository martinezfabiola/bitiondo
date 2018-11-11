#! /usr/bin/ruby

############################################################
# Universidad Simón Bolívar
# CI3175: Traductores e interpretadores
# 
# Bitiondo
# Lexer del lenguaje Bitiondo
#
# Analizador lexicográfico para el intepretador del lenguaje 
#
#
# David Cabeza 13-10191 <13-10191@usb.ve>
# Fabiola Martínez 13-10838 <13-10838@usb.ve>
############################################################

class Token

	attr_accessor :value, :type, :locationinfo, :is_correct
	attr_reader :tokenswithvalue

	# Initialize method: initializes tokens atributtes.
	# Parameters:
	# - type: token name, it refers to key dictionary.
	# - value: it refers to some tokens (string, interger, identifier, bitsexpression) take.
	# - line: where the token is.
	# - column: where the token is.
	def initialize(type, value=nil, line=0, column=0)
		@type = type
		@value = value
		@locationinfo = {
			line: line,
			column: column
		}
		@tokenswithvalue = ["string", "integer", "identifier", "bitsexpression"]
		@is_correct = true
	end

	# to_s method: for each token generates its string for be printed.
	def to_s
  	
  	if @is_correct
	  
	  	str = "#{@type} at line #{@locationinfo[:line]}, column #{@locationinfo[:column]}"
	  	if (@tokenswithvalue.include?@type)
	  		str = str + " with value `#{@value}`"
	  	end
  	
  	else
  		str = "Error: Se encontró un caracter inesperado \"#{@value}\" en la Línea #{@locationinfo[:line]}, Columna #{@locationinfo[:column]}."
  	end

  	return str

  end

end

class Lexer

	attr_accessor :filename, :tokens
	attr_reader :data, :tokensdict, :ignore 

	# Initialize method: initializes elements like:
	# - tokens: stores corrects tokens.
	# - wrongTokens: stores incorrects tokens.
	# - line: counter for lines.
	# - column: counter for columns.
	# - ignore: regular expression, it will used to ignore tokens.
	# Parameters:
	# - filename: name file that will be opened.
	def initialize(filename)
		@filename = filename
		@tokens = []
		@wrongTokens = []
		@lineno = 0
		@column = 0
		@hasLexicographicErrors = false
		@ignore = /\A#.*|\A\s+/
		@cur_token = 0;

		@tokensdict = {

			'bitexpr'=> /\A0b[0-1]+/,

			# Numbers=>
			'integer'=> /\A[0-9]+/,

			# Reserved words:
			'begin'=> /\Abegin\b/,
			'end'=> /\Aend\b/,
			'if'=> /\Aif\b/,
			'else'=> /\Aelse\b/,
			'for'=> /\Afor\b/,
			'forbits'=> /\Aforbits\b/,
			'as'=> /\Aas\b/,
			'from'=> /\Afrom\b/,
			'going'=> /\Agoing\b/,
			'higher'=> /\Ahigher\b/,
			'lower'=> /\Alower\b/,
			'while'=> /\Awhile\b/,
			'do'=> /\Ado\b/,
			'repeat'=> /\Arepeat\b/,
			'input'=> /\Ainput\b/,
			'output'=> /\Aoutput\b/,
			'outputln'=> /\Aoutputln\b/,
			'true'=> /\Atrue\b/,
			'false'=> /\Afalse\b/,
			
			# Strings
			'string'=> /\A"(\\.|[^\\"\n])*"/,
			
			# Symbols:

			# Unary
			'['=> /\A\[/,
			']'=> /\A\]/,
			'~'=> /\A\~/,
			'$'=> /\A\$/,
			'@'=> /\A\@/,
			'-'=> /\A\-/, 

			# Binary
			'*'=> /\A\*/, 
			'/'=> /\A\//,
			'%'=> /\A\%/,
			'+'=> /\A\+/, 
			'<<'=> /\A<</,
			'>>'=> /\A>>/,

			'<='=> /\A\<\=/,
			'>='=> /\A\>\=/,
			'<'=> /\A\</,
			'>'=> /\A\>/,
			'=='=> /\A\=\=/,

			'!='=> /\A\!\=/,
			'!'=> /\A\!/,

			'&&'=> /\A\&\&/,
			'&'=> /\A\&/,

			'^'=> /\A\^/,

			'||'=> /\A\|\|/,
			'|'=> /\A\|/,	

			'='=> /\A\=/,
			'('=> /\A\(/,
			')'=> /\A\)/,
			','=> /\A,/,
			';'=> /\A\;/,
			
			# Data Type:
			'int'=> /\Aint\b/,
			'bool'=> /\Abool\b/,
			'bits'=> /\Abits\b/,

			# Identifiers:
			'identifier'=> /\A[A-Za-z][A-Za-z0-9\_]*/
		}

		# Try to read file and save his data.
		begin
			readFile
		rescue
			puts "File #{@filename} could not be read."
			return
		end

	end

	# Read File method: reads text file.
	def readFile
		file = File.open(@filename,"r")
		@data = file.read
 		
		file.close
		
		return true
	end

	# Tokenizer method: principal method that does lexer method.
	def tokenizer

		# irates through file lines
		data.each_line do |line|

			@lineno = @lineno + 1
			@column = 1

			while line.length > 0
				
				matches = false

				# compares if the token read has to be ignored
				if (line =~ @ignore)
					matches = true
					@column = @column + $&.length
					line = line[$&.length..line.length]
					next

				else
					# iterates through the token dictionary 
					# value has regular expressions
					tokensdict.each do |key, value|

						# compares for which regular expression will do match
						if (line =~ value)
							matches = true
							tk = Token.new(key.to_s, $&, @lineno, @column)
							# adds to correct token list
							@tokens.push(tk)
							@column = @column + $&.length
							line = line[$&.length..line.length]
							break

						end

					end
					
					# if the token didn't match with any regular expression is an error	
					if !(matches)
						@hasLexicographicErrors = true
						tk = Token.new(nil, line[0], @lineno, @column)
						tk.is_correct = false
						# adds to incorrect token list
						@wrongTokens.push(tk)
						@column = @column + 1
						line = line[1..line.length]
					end
				
				end
		
			end
				
		end

	end

	# Prints tokens found after doing lexical analysis
	def printTokenList
		tokens.each do |tk|
			puts tk
		end
	end

	# Prints lexicographic errors after doing lexical analysis
	def printLexicographicErrors
		@wrongTokens.each do |tk|
			puts tk.to_s
		end
	end

	# Returns true if there are lexicographic errors
	def hasLexicographicErrors
		return @hasLexicographicErrors
	end

	# Checks whether there are any tokens left
	def has_next_token
		return @cur_token < @tokens.length;
	end

	# Returns next token
	def next_token
		token = @tokens[@cur_token];
		@cur_token = @cur_token + 1;
		return token;
	end

end

