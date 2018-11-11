#! /usr/bin/ruby
#<Encoding:UTF-8>
############################################################
# Universidad Simón Bolívar
# CI3175: Traductores e interpretadores
# 
# Bitiondo
#
# Gramática libre de contexto para Bitiondo
# 
# David Cabeza 13-10191 <13-10191@usb.ve>
# Fabiola Martínez 13-10838 <13-10838@usb.ve>
############################################################

class Parser

	# Precedence for tokens in Bitiondo
  prechigh
    right '['
    left ']'
    right '$' '@' '!' '~' UMINUS
    left '*' '/' '%'
    left '+' '-'
    left '<<' '>>'
    nonassoc '<' '<=' '>' '>='
    left '==' '!='
    left '&'
    left '^'
    left '|'
    left '&&'
    left '||'
  preclow

	# Valid token list in Bitiondo
	token '[' ']' '!' '~' '$' '@' UMINUS '*' '/' '%' '+' '-' '<<' '>>' '<' 
		  	'<=' '>' '>=' '==' '!=' '&' '^' '|' '&&' '||' '=' '(' ')' ',' 'bitexpr' 
		  	'integer' 'begin' 'end' 'if' 'else' 'for' 'forbits' 'as' 'from' 'going' 
		  	'higher' 'lower' 'while' 'do' 'repeat' 'input' 'output' 'outputln' 'true' 
		  	'false' 'string' ';' 'identifier' 'bool' 'int' 'bits'

	start S

	# Definition of context-free grammar admitted by Bitiondo
	rule

		# Initial rule. General structure of bitiondo
		S
		: BLOCK {result = val[0]}
		;

		# Blocks in bitiondo are defined by begin and end keywords
		BLOCK
		: 'begin' STATEMENTS INSTRUCTIONS 'end' {result = BlockNode.new(val[1], val[2])}
		| 'begin' STATEMENTS 'end' 							{result = BlockNode.new(val[1], nil)}
		| 'begin' INSTRUCTIONS 'end' 						{result = BlockNode.new(nil, val[1])}
		| 'begin' 'end' 												{result = BlockNode.new(nil, nil)}
		;

		# Statements rule. Bitiondo can have several statements or one
		STATEMENTS
		: STATEMENTS STATEMENT 	{result = StatementsNode.new(val[0], val[1])}
		| STATEMENT 						{result = val[0]}
		;

		# Statement rule. There are 4 types of statements in bitiondo
		STATEMENT
		: TYPE 'identifier' ';' 																	{result = StatementNode.new(val[0], val[1], nil, nil)}
		| TYPE 'identifier' '=' EXPRESSION ';'  									{result = StatementNode.new(val[0], val[1], val[3], nil)}
		| TYPE 'identifier' '[' EXPRESSION ']' ';' 								{result = StatementNode.new(val[0], val[1], nil, val[3])} 
		| TYPE 'identifier' '[' EXPRESSION ']' '=' EXPRESSION ';' {result = StatementNode.new(val[0], val[1], val[6], val[3])}
		;

		# Type rule. Types admitted for statements
		TYPE
		: 'int' {result = val[0]}
		| 'bool' {result = val[0]}
		| 'bits' {result = val[0]}
		;

		# Instructions rules. It helps to generate several instructions
		INSTRUCTIONS
		: INSTRUCTIONS INSTRUCTION {result = InstructionsNode.new(val[0], val[1])}
		| INSTRUCTION {result = val[0]}
		;

		# Instruction rule. There are 8 types of instructions in bitiondo
		INSTRUCTION
		: BLOCK {result = val[0]}
		| ASSIGNATION {result = val[0]}
		| INPUT {result = val[0]}
		| OUT {result = val[0]}
		| CONDITIONAL {result = val[0]}
		| FOR {result = val[0]}
		| FORBITS {result = val[0]}
		| WHILE {result = val[0]}
		;

		# Assignation rule. Two ways to assign varibles in bitiondo
		ASSIGNATION
		: 'identifier' '=' EXPRESSION ';' {result = AssignationNode.new(val[0], nil, val[2])}
		| 'identifier' '[' EXPRESSION ']' '=' EXPRESSION ';' {result = AssignationNode.new(val[0], val[2], val[5])}
		;

		# Input rule. Defines the way of inputs in bitiondo
		INPUT
		: 'input' 'identifier' ';' {result = InputNode.new(val[1])}
		;	

		# Out rule. Defines the way of outputs in bitiondo
		OUT
		: 'output' EXPRESSIONS ';' {result = OutputNode.new('OUTPUT', val[1])}
		| 'outputln' EXPRESSIONS ';' {result = OutputNode.new('OUTPUTLN', val[1])}
		;

		# Expressions rule. Its like the group of expressions in outputs
		EXPRESSIONS
		: EXPRESSIONS ',' EXPRESSION {result = ExpressionsNode.new(val[0], val[2])}
		| EXPRESSION {result = val[0]}
		;

		# Conditional rule. Two types of conditionals in bitiondo
		# This rule has shift/reduce problem
		CONDITIONAL
		: 'if' '(' EXPRESSION ')' INSTRUCTION {result = ConditionalNode.new(val[2], val[4])}
		| 'if' '(' EXPRESSION ')' INSTRUCTION 'else' INSTRUCTION {result = ConditionalNode.new(val[2], val[4], val[6])}
		;

		# For rule. Normal for loop
		FOR
		: 'for' '(' ASSIGNATION EXPRESSION ';' EXPRESSION ')' INSTRUCTION {result = ForLoopNode.new(val[2], val[3], val[5], val[7])}
		;

		# Forbits rule. Way to iterate through bits
		FORBITS
		: 'forbits' EXPRESSION 'as' 'identifier' 'from' EXPRESSION 'going' DIRECTION INSTRUCTION {result = ForbitsLoopNode.new(val[1], val[3], val[5], val[7], val[8])}
		;

		# Direction rule. Two ways to iterate through bits: higher or lower
		DIRECTION
		: 'higher' {result = val[0]}
		| 'lower' {result = val[0]}
		;

		# While rule. Three ways to do whiles in bitiondo. Already known
		WHILE
		: 'repeat' INSTRUCTION 'while' '(' EXPRESSION ')' 'do' INSTRUCTION {result = RepeatWhileLoopNode.new(val[1], val[4], val[7])}
		| 'while' '(' EXPRESSION ')' 'do' INSTRUCTION {result = WhileLoopNode.new(val[2], val[5])}
		| 'repeat' INSTRUCTION 'while' '(' EXPRESSION ')' ';' {result = RepeatWhileLoopNode.new(val[1], val[4])} 
		;

		# Expression rule. Defines all allowed expressions in bitiondo
		# Binary, Unary and Constant expressions. One especial named "ACCESSOR"
		EXPRESSION
		: '(' EXPRESSION ')'					{result = val[1]}
		| EXPRESSION '*' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'MULTIPLICATION')}
		| EXPRESSION '/' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'DIVISION')}
		| EXPRESSION '%' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'MODULUS')}
		| EXPRESSION '+' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'PLUS')}
		| EXPRESSION '-' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'MINUS')}
		| EXPRESSION '<<' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'LEFTSHIFT')}
		| EXPRESSION '>>' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'RIGHTSHIFT')}
		| EXPRESSION '<' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'LESSTHAN')}
		| EXPRESSION '<=' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'LESSTHANEQUAL')}
		| EXPRESSION '>' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'GREATERTHAN')}
		| EXPRESSION '>=' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'GREATERTHANEQUAL')}
		| EXPRESSION '==' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'ISEQUAL')}
		| EXPRESSION '!=' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'ISNOTEQUAL')}
		| EXPRESSION '&' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'ANDBITS')}
		| EXPRESSION '^' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'EXCLUSIVE')}
		| EXPRESSION '|' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'ORBITS')}
		| EXPRESSION '&&' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'ANDBOOL')}
		| EXPRESSION '||' EXPRESSION 	{result = BinExpressionNode.new(val[0], val[2], 'ORBOOL')}
		| '!' EXPRESSION 							{result = UnaryExpressionNode.new(val[1], 'NOT')}
		| '~' EXPRESSION 							{result = UnaryExpressionNode.new(val[1], 'NOTBITS')}
		| '$' EXPRESSION 							{result = UnaryExpressionNode.new(val[1], 'BITREPRESENTATION')}
		| '@' EXPRESSION 							{result = UnaryExpressionNode.new(val[1], 'TRANSFORM')}
		| '-' EXPRESSION =UMINUS 			{result = UnaryExpressionNode.new(val[1], 'UMINUS')}
		| 'identifier' 								{result = ConstExpressionNode.new(val[0], "variable")}
		| 'integer' 									{result = ConstExpressionNode.new(val[0], "int")}
		| 'bitexpr' 									{result = ConstExpressionNode.new(val[0], "bits")}
		| 'true' 											{result = ConstExpressionNode.new(val[0], "bool")}
		| 'false' 										{result = ConstExpressionNode.new(val[0], "bool")}
		| 'string' 										{result = ConstExpressionNode.new(val[0], "string")}
		| EXPRESSION '[' EXPRESSION ']' {result = AccessNode.new(val[0], val[2])}
		;

end

---- header

require_relative "ast.rb"

class SyntacticError < RuntimeError

	def initialize(token)
		@token = token
	end

	def to_s
		"ERROR: unexpected token '#{@token.type}' at line #{@token.locationinfo[:line]}, column #{@token.locationinfo[:column]}"
	end

end

---- inner

def initialize(lexer)
    @lexer = lexer
end

def on_error(id, token, stack)
    raise SyntacticError::new(token)
end

def next_token
    if @lexer.has_next_token then
        token = @lexer.next_token;
        return [token.type,token]
    else
        return nil
    end
end

def parse
    do_parse
end
