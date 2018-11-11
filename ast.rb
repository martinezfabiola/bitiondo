#! /usr/bin/ruby

############################################################
# Universidad Simón Bolívar
# CI3175: Traductores e interpretadores
# 
# Bitiondo
#
# Análisis sintáctico y árbol sintáctico abstracto
# 
# David Cabeza 13-10191 <13-10191@usb.ve>
# Fabiola Martínez 13-10838 <13-10838@usb.ve>
############################################################

# The classes in this file are nodes that are instantiated by the parser file. 
# These classes contain a "print" function which is responsible for making the 
# appropriate printing for each node in the requested format of the syntax tree.

# Each class has a meaning depending on the path it is taking. Their names 
# indicate the meaning of each node.

# For more information about the meaning of each node, see the file parser.y

SemanticErrors = []

#-----------------------------------------------------------
#
#-----------------------------------------------------------
class BlockNode

	attr_accessor :statements, :instructions

	def initialize(statements, instructions)
		@statements = statements
		@instructions = instructions
		@t = nil
	end

	#-----------------------------------------------------------
	# 
	#-----------------------------------------------------------
	def printAST(indent="")

		if not SemanticErrors.empty?
			return printSemanticErrors()
		end

		puts "#{indent}BEGIN"
		if @statements
				puts "#{indent+"  "}SYMBOL TABLE"
				@t.printSymTab(indent+"    ")
		end
		if @instructions
			@instructions.printAST(indent+"  ")
		end
		puts "#{indent}END"
		return
	end

	#-----------------------------------------------------------
	# 
	#-----------------------------------------------------------
	def check(parentTable)
		@t = SymbolTable.new(parentTable)
		
		if @statements
			@statements.check(@t)
		end
		if @instructions
			@instructions.check(@t)
		end
	end

	#--------------------------------------------------------------------------#
	# 										INTERPRETADOR DEL NODO BLOQUE
	# -> Si hay declaraciones, estas son interpretadas.
	# -> Si hay instrucciones, estas son interpretadas.
	# Las declaraciones son interpretadas primero que las instrucciones.
	#--------------------------------------------------------------------------#
	def interprete(symbol_table)
		if @statements then @statements.interprete(@t) end
		if @instructions then @instructions.interprete(@t) end
	end

end

#-----------------------------------------------------------
# 
#-----------------------------------------------------------
class StatementsNode

	attr_accessor :statementsNode, :statementNode

	def initialize(statementsNode, statementNode)
		@statementsNode = statementsNode
		@statementNode = statementNode
	end

	def printAST(indent)
		@statementsNode.printAST(indent)
		@statementNode.printAST(indent)
	end

	def check(table)
		@statementsNode.check(table)
		@statementNode.check(table)
	end

	#--------------------------------------------------------------------------#
	# 						INTERPRETADOR DEL NODO LISTA DE DECLARACIONES
	# Se encarga de llamar recursivamente al interpretador de cada declaración 
	#--------------------------------------------------------------------------#
	def interprete(symbol_table)
		@statementsNode.interprete(symbol_table)
		@statementNode.interprete(symbol_table)
	end

end

class StatementNode

	def initialize(type, identifier, value, size)
		@type = type
		@identifier = identifier
		@value = value
		@size = size
	end

	def printAST(indent)
		puts "#{indent}DECLARE"
		puts "#{indent+"  "}type: #{@type.type}"
		puts "#{indent+"  "}variable: #{@identifier.value}"
		if @size
			puts "#{indent+"  "}size:"
			@size.printAST(indent+"    ")
		end
		if @value
			puts "#{indent+"  "}value:"
			@value.printAST(indent+"    ")
		end
	end

	def check(table)

		# Case: Variable has been declared before
		if table.isMember(@identifier.value)
			SemanticErrors.push("Error en línea #{@type.locationinfo[:line]}, columna #{@type.locationinfo[:column]}: La variable '#{@identifier.value}' ya ha sido declarada en este alcance")
			return
		end

		# Variable hasnt been declared before, insert in table proper way
		if not @size and not @value
			if @type.type == "int"
				return table.insert(@identifier.value, @type.type, 0, nil)
			elsif @type.type == "bool"
				return table.insert(@identifier.value, @type.type, "false", nil)
			else
				return SemanticErrors.push("Error en la línea #{@identifier.locationinfo[:line]}, column #{@identifier.locationinfo[:column]}: La declaración de tipo bits debe tener un tamaño")
			end
		end

		# Checking for variables of type bool a = false;
		if not @size
			if @type.type == @value.check(table)
				if @value.instance_of? BinExpressionNode or @value.instance_of? UnaryExpressionNode
					return table.insert(@identifier.value, @type.type, @value.value, nil)
				elsif @value.instance_of? ConstExpressionNode
					return table.insert(@identifier.value, @type.type, @value.value.value, nil)
				end 
			else
				SemanticErrors.push("Error en línea #{@type.locationinfo[:line]}, columna #{@type.locationinfo[:column]}: El tipo #{@type.type} de la declaración no coincide con el tipo de la asignación")
				return			
			end
		end

		if @size and @value

			if @value.check(table) != "bits"
				return SemanticErrors.push("Error en línea #{@type.locationinfo[:line]}, columna #{@type.locationinfo[:column]}: El tipo #{@type.type} de la declaración no coincide con el tipo de la asignación")
				
			elsif @size.check(table) != "int"
				return SemanticErrors.push("Error en línea #{@type.locationinfo[:line]}, columna #{@type.locationinfo[:column]}: El tamaño de identificador tipo bits debe ser un entero")
			else
				return table.insert(@identifier.value, @type.type, @value.value, @size.value)			
			end

		end

		if @size 
			if @type.value != "bits"
				SemanticErrors.push("Error en línea #{@type.locationinfo[:line]}, columna #{@type.locationinfo[:column]}: La variable #{@identifier.value} no puede ser declarada con el tipo #{@type.type}")
			elsif @size.check(table) != "int"
				SemanticErrors.push("Error en línea #{@type.locationinfo[:line]}, columna #{@type.locationinfo[:column]}: El tamaño de identificador tipo bits debe ser un entero")
			else
					# Inserta una declaración de tipo bits sin valor por defecto
					# ya que el valor no es interpretado.
					return table.insert(@identifier.value, @type.type, nil, @size.value)
			end
		end

	end
	
	#--------------------------------------------------------------------------#
	# 						INTERPRETADOR DEL NODO DECLARACION
	# Este interpretador tiene dos tareas principales, una es verificar si el 
	# tamaño indicado de una expresión declarada con tipo bits coincide con el
	# tamaño de la inicialización. Para esto, el tamaño de la declaracion es
	# interpretado y luego este es verificado con el de la inicialización.
	# La otra tarea de este interpretador es insertar una expresion tipo bits
	# en la tabla de símbolos una vez es interpretado el valor de su tamaño 
	#--------------------------------------------------------------------------#
	def interprete(symbol_table)

		if @value and not @size
			symbol_table.update(@identifier.value, @type.type, @value.interprete(symbol_table), nil)
		end

		if @size
			bits_decl_size = @size.interprete(symbol_table).to_i
			# si hay valor, verificar el tamaño del valor con el de la declaración
			if @value
				bits_value_size = @value.value.value.length - 2 # No contar 0b
				if bits_decl_size == bits_value_size
					symbol_table.update(@identifier.value, @type.type, @value.value.value, bits_decl_size)
				else
					raise "El tamaño de la declaración no coincide con el tamaño de la inicialización"
				end
			# si no lo hay, como fue posible interpretar el tamaño, actualizar en la
			# tabla de simbolos el valor por defecto. 
			elsif not @value
					bits_expression = "0b" + "0" * bits_decl_size
					symbol_table.update(@identifier.value, @type.type, bits_expression, bits_decl_size)
			end
		end
	end

end

class InstructionsNode

	attr_reader :indent

	def initialize(instructionsNode, instructionNode)
		@instructionsNode = instructionsNode
		@instructionNode = instructionNode
		@indent = "  "
	end

	def printAST(indent)
		@instructionsNode.printAST(indent)
		@instructionNode.printAST(indent)
	end

	def check(parentTable)
		@instructionsNode.check(parentTable)
		@instructionNode.check(parentTable)
	end

	#--------------------------------------------------------------------------#
	# 						INTERPRETADOR DEL NODO LISTA DE INSTRUCCIONES
	# Se encarga de llamar recursivamente al interpretador de cada instrucción 
	#--------------------------------------------------------------------------#
	def interprete(symbol_table)
		@instructionsNode.interprete(symbol_table)
		@instructionNode.interprete(symbol_table)
	end

end

class AssignationNode

	attr_reader :identifier, :position, :value

	def initialize(identifier, position, value)
		@identifier = identifier
		@position = position
		@value = value
	end

	def printAST(indent)
		puts "#{indent}ASSIGN"
		puts "#{indent+"  "}variable: #{@identifier.value}"
		
		if @position
			puts "#{indent+"  "}position:"
			@position.printAST(indent+"    ")
		end
	
		puts "#{indent+"  "}value:"
		@value.printAST(indent+"    ")
	end

	def check(table)

		if not table.lookup(@identifier.value)
			SemanticErrors.push("Error: La variable #{@identifier.value} no esta declarada.")
			return
		end

		if @position and @position.check(table) != "int"
			SemanticErrors.push("Error en la línea #{@identifier.locationinfo[:line]}, columna #{@identifier.locationinfo[:column]}: La posición de la declaración no es un entero")
			return
		end

		if table.find(@identifier.value).type != @value.check(table)
			SemanticErrors.push("Error en la línea #{@identifier.locationinfo[:line]}, columna #{@identifier.locationinfo[:column]}: El tipo de la declaración no coincide con el de la asignación")
			return
		end
	end

	#--------------------------------------------------------------------------#
	# 						INTERPRETADOR DEL NODO ASIGNACIÓN
	# VARIABLE
	# POSITION
	# VALUE
	#--------------------------------------------------------------------------#
	def interprete(symbol_table)
		if symbol_table.find(@identifier.value).type == "bool"
			val = @value.interprete(symbol_table)
			return symbol_table.update(@identifier.value, "bool", val,nil)
		end

		if symbol_table.find(@identifier.value).type == "int"
			val = @value.interprete(symbol_table)
			return symbol_table.update(@identifier.value, "int", val, nil)
		end

		if symbol_table.find(@identifier.value).type == "bits"
			bits_declared_expression = symbol_table.find(@identifier.value)
			if not @position
				bits_value_expression_size = @value.interprete(symbol_table).length - 2
				if bits_declared_expression.size == bits_value_expression_size
					return symbol_table.update(@identifier.value, "bits", @value.interprete(symbol_table), bits_value_expression_size)
				else
					raise "Error. Declaraste una variable de un tamaño y el tamaño que le estas intentando asignar no es el mismo."
				end

			elsif @position
				position_value = @position.interprete(symbol_table).to_i
				if (0 <= position_value) && (position_value <= bits_declared_expression.size - 1)
					if @value.interprete(symbol_table) == '0' or @value.interprete(symbol_table) == '1'
						bits_declared_expression.value[position_value+2] = @value.interprete(symbol_table)
					else
						raise "A expresiones tipo bits solo se le pueden asignar ceros o unos."
					end
				else
					raise "Estas tratando de asignar en una posicion que el bits no tiene."
				end
			end
		end

	end
end

class InputNode

	def initialize(identifier)
		@identifier = identifier
	end

	def printAST(indent)
		puts "#{indent}INPUT"
		puts "#{indent+"  "}element:"
		puts "#{indent+"    "}variable: #{@identifier.value}"
	end

	def check(table)
		if not table.lookup(@identifier.value)
			SemanticErrors.push("Error en ĺínea #{@identifier.locationinfo[:line]}, columna #{@identifier.locationinfo[:column]}: la variable #{@identifier.value} no fue declarada.")
		end
	end

	def interprete(symbol_table)
		
		while(true)

			# Read from standard input
			userInput = $stdin.gets
			# Remove newline character
			userInput = userInput.chomp
			# Remove beginning whitespaces
			userInput = userInput.lstrip
			# Remove trailing whitespaces
			userInput = userInput.rstrip

			# Se obtiene el tipo que tiene la entrada del usuario
			input_type = getInputType(userInput)

			# Se obtiene el tipo de la variable a la que va el input
			variable_info = symbol_table.find(@identifier.value)

			if(input_type != variable_info.type)
				puts "Error no coincide el tipo de variable con el tipo de la entrada"
				puts "Intentalo de nuevo"
				next
			else
				if variable_info.type == "bits" and variable_info.size != userInput.length - 2
					puts "Error. El tamano introducido para la variable tipo bits no coincide con el inicializado"
					puts "Intentalo de nuevo"
					next
				else
					if variable_info.type == "bits"
						symbol_table.update(@identifier.value, variable_info.type, userInput, variable_info.size)
					else
						symbol_table.update(@identifier.value, variable_info.type, userInput, nil)
					end

					break
				end
			end
		end
	end


	def getInputType(userInput)
		integer_regex = /\A[0-9]+/
		true_regex = /\Atrue\b/
		false_regex = /\Afalse\b/
		bitexpr_regex = /\A0b[0-1]+/

		if (userInput =~ bitexpr_regex)
			return 'bits'
		elsif (userInput =~ true_regex or userInput =~ false_regex)
			return 'bool'
		elsif (userInput =~ integer_regex)
			return 'int'
		else
			return nil
		end
	end

end

class OutputNode

	def initialize(type, expressions)
		@type = type
		@expressions = expressions
	end

	def printAST(indent)
		puts "#{indent}#{@type}"
		puts "#{indent+"  "}elements:"
		@expressions.printAST(indent+"    ")
	end

	def check(table)
		@expressions.check(table)
	end

	def interprete(symbol_table)

		if @type == "OUTPUT"
			if @expressions.class == ExpressionsNode
				@expressions.interprete(symbol_table)
			elsif @expressions.class == ConstExpressionNode
				print @expressions.interprete(symbol_table)
			end
			return
		elsif @type == "OUTPUTLN"
			if @expressions.class == ExpressionsNode
				@expressions.interprete(symbol_table)
				print "\n"
			elsif @expressions.class == ConstExpressionNode
				print @expressions.interprete(symbol_table)
			end
		end
		
	end

end

class ExpressionsNode

	attr_reader :indent

	def initialize(expressionsNode, expressionNode)
		@expressionsNode = expressionsNode
		@expressionNode = expressionNode
		@indent = "  "
	end

	def printAST(indent)
		@expressionsNode.printAST(indent)
		@expressionNode.printAST(indent)
	end

	def check(table)
		@expressionsNode.check(table)
		@expressionNode.check(table)

		if @expressionNode.check(table) == "variable"
			if !table.lookup(@expressionNode.value.value) 
				return SemanticErrors.push("Error aqui: La variable #{@expressionNode.value.value} no fue declarada")
			end
		end
	end

	def interprete(symbol_table)
		print @expressionsNode.interprete(symbol_table)
		print @expressionNode.interprete(symbol_table)
	end

end

class ConditionalNode

	def initialize(expression, ins1, ins2=nil)
		@expression = expression
		@ins1 = ins1
		@ins2 = ins2
	end

	def printAST(indent)
		puts "#{indent}CONDITIONAL"
		puts "#{indent+"  "}CONDITION:"
		@expression.printAST(indent+"    ")
		puts "#{indent+"  "}INSTRUCTION:"
		@ins1.printAST(indent+"    ")
		if @ins2
			puts "#{indent+"  "}OTHERWISE:"
			@ins2.printAST(indent+"    ")
		end
	end

	def check(table)
		if @expression.check(table) != "bool"

			if @expression.instance_of? BinExpressionNode
				SemanticErrors.push("Error en línea #{findLeftMostOperand(@expression.leftoperand).value.locationinfo[:line]}, columna #{findLeftMostOperand(@expression.leftoperand).value.locationinfo[:column]}: Instrucción 'if' espera expresion de tipo 'bool'")
			elsif @expression.instance_of? UnaryExpressionNode
				SemanticErrors.push("Error en línea #{@expression.operand.value.locationinfo[:line]}, columna #{@expression.operand.value.locationinfo[:column]}: Instrucción 'if' espera expresion de tipo 'bool'")
			elsif
				@expression.instance_of? ConstExpressionNode
				SemanticErrors.push("Error en línea #{@expression.value.locationinfo[:line]}, columna #{@expression.value.locationinfo[:column]}: Instrucción 'if' espera expresion de tipo 'bool'")
			else
				SemanticErrors.push("Error en línea #{@expression.value.locationinfo[:line]}, columna #{@expression.value.locationinfo[:column]}: Instruccion 'if' espera expresion de tipo 'bool'")
			end
		end

		@ins1.check(table)
		if @ins2 then @ins2.check(table) end
	end

	def interprete(symbol_table)
		
		if eval(@expression.interprete(symbol_table)) == false
			if @ins2
				@ins2.interprete(symbol_table)
			end
		else
			@ins1.interprete(symbol_table)
		end
	end 
end

class ForLoopNode

	def initialize(assignation, exp1, exp2, instruction)
		@assignation = assignation
		@exp1 = exp1
		@exp2 = exp2
		@instruction = instruction
		@t = nil
	end

	def printAST(indent)
		puts "#{indent}FOR LOOP"
		puts "#{indent+"  "}INITIALIZATION:"
		@assignation.printAST(indent+"    ")
		puts "#{indent+"  "}CONDITION:"
		@exp1.printAST(indent+"    ")
		puts "#{indent+"  "}VARIABLE UPDATE:"
		@exp2.printAST(indent+"    ")
		puts "#{indent+"  "}INSTRUCTION:"
		@instruction.printAST(indent+"    ")
	end

	def check(table)
		
		# The for loop has its own table with the loop variable
		@t = SymbolTable.new(table)
		
		# Get assignation needed parameters
		id = @assignation.identifier.value
		pos = @assignation.position
		val = @assignation.value

		# Case: Assignation is like b[0] = 1;
		if pos
			SemanticErrors.push("Error en línea #{@assignation.identifier.locationinfo[:line]}, columna #{@assignation.identifier.locationinfo[:column]}: Inicialización de #{id} incorrecta.")
			return
		end

		# Case: assignation is not integer
		if val.check(table) != "int"
			SemanticErrors.push("Error en línea #{@assignation.identifier.locationinfo[:line]}: La asignación de la inicialización no es un entero")
			return
		end

		# After making sure that the identifier was properly declarated 
		# in the for scope, make sure that the condition is boolean and 
		# identifier is detected as a declared variable if used in the 
		# condition.
		table.insert(id, val.check(table), val, nil)

		if @exp1.check(table) != "bool"
			SemanticErrors.push("Error en línea #{findLeftMostOperand(@exp1).value.locationinfo[:line]}, columna #{findLeftMostOperand(@exp1).value.locationinfo[:column]}: El tipo de la condición debe ser booleano")
			return 
		end

		# identifier is not itself a symbol for this scope.
		table.delete(id)

		if @exp2.check(table) != "int"
			SemanticErrors.push("Error en línea #{findLeftMostOperand(@exp2).value.locationinfo[:line]}, columna #{findLeftMostOperand(@exp2).value.locationinfo[:column]}: El tipo de la expresión que actualiza la variable (paso) debe ser entero")
		end

		if @instruction.instance_of? AssignationNode and @instruction.identifier.value == id
			return SemanticErrors.push("Error en línea #{@instruction.identifier.locationinfo[:line]}, columna #{@instruction.identifier.locationinfo[:column]}: No es posible modificar la variable de iteración '#{id}' ")
		end

		@instruction.check(table)
	end

	def interprete(symbol_table)

		# Asignamos a i el valor inicial del for para llevar conteo de la condicion
		i = @assignation.value.interprete(symbol_table).to_i
		@t.insert(@assignation.identifier.value, "int", i, nil)

		step = @exp2.interprete(@t).to_i

		# Repetimos codigo hasta que la condicion sea falsa
		while(@exp1.interprete(@t))
			# Aqui se ejecuta la instruccion
			@instruction.interprete(@t)
			i = i + step
			@t.update(@assignation.identifier.value, "int", i, nil)
		end
		
	end

end

class ForbitsLoopNode

	def initialize(bits_expression, identifier, expresion_int, direction, instruction)
		@bits_expression = bits_expression
		@identifier = identifier
		@expresion_int = expresion_int
		@direction = direction
		@instruction = instruction
	end

	def printAST(indent)
		puts "#{indent}FORBITS LOOP"
		puts "#{indent+"  "}BITS EXPRESSION:"
		@bits_expression.printAST(indent+"    ")
		puts "#{indent+"  "}IDENTIFIER:"
		puts "#{indent+"    "}value: #{@identifier.value}"
		puts "#{indent+"  "}FROM:"
		@expresion_int.printAST(indent+"    ")
		puts "#{indent+"  "}GOING:"
		puts "#{indent+"    "}value: #{@direction.value}"
		puts "#{indent+"  "}INSTRUCTION:"
		@instruction.printAST(indent+"    ")
	end

	def check(table)
		
		@identifier.value = k 

		if @bits_expression.check(table) != "bits"
			SemanticErrors.push("Error en línea #{@identifier.locationinfo[:line]}: La expresión no es de tipo bits")
		end

		@instruction.check(table)
	end

	def interprete(symbol_table)

		k = expresion_int.interprete(sym_table)

		if @direction.value == "higher"
			
			@bits_expression[2+k..-1].each_char do |c|
				puts c 
			end

		elsif @direction.value == "lower"
			
			@bits_expression.reverse[k..2].each_char do |c|
				puts c
			end

		end	
	
	end
end

class RepeatWhileLoopNode

	def initialize(instruction1, condition, instruction2=nil)
		@condition = condition
		@instruction1 = instruction1
		@instruction2 = instruction2
	end

	def printAST(indent)
		puts "#{indent}REPEAT LOOP"
		puts "#{indent+"  "}INSTRUCTION:"
		@instruction1.printAST(indent+"    ")
		puts "#{indent+"  "}WHILE:"
		@condition.printAST(indent+"    ")
		if @instruction2 then
			puts "#{indent+"  "}DO:"
			@instruction2.printAST(indent+"    ")			
		end

	end

	def check(table)
		if @condition.check(table) != "bool"

			if @condition.instance_of? BinExpressionNode
				SemanticErrors.push("Error en línea #{findLeftMostOperand(@condition.leftoperand).value.locationinfo[:line]}, columna #{findLeftMostOperand(@condition.leftoperand).value.locationinfo[:column]}: Instrucción 'while' espera expresion de tipo 'bool'")
			elsif @condition.instance_of? UnaryExpressionNode
				SemanticErrors.push("Error en línea #{@condition.operand.value.locationinfo[:line]}, columna #{@condition.operand.value.locationinfo[:column]}: Instrucción 'while' espera expresion de tipo 'bool'")
			elsif
				@condition.instance_of? ConstExpressionNode
					SemanticErrors.push("Error en línea #{@condition.value.locationinfo[:line]}, columna #{@condition.value.locationinfo[:column]}: Instrucción 'while' espera expresion de tipo 'bool'")
			else
				SemanticErrors.push("Instruccion 'while' espera expresion de tipo 'bool'")
			end
		end

		@instruction1.check(table)	

		if @instruction2
			@instruction2.check(table)
		end	
	end

	def interprete(symbol_table)
		
		if not @instruction2
			@instruction1.interprete(symbol_table)
			while(eval(@condition.interprete(symbol_table)))
				@instruction1.interprete(symbol_table)
			end
		else
			cond = @instruction1.interprete(symbol_table)
			if cond.class == TrueClass or cond.class == FalseClass then cond = @instruction1.interprete(symbol_table)
			else cond = eval(@instruction1.interprete(symbol_table))
			end
			while(cond)
				@instruction2.interprete(symbol_table)
				@instruction1.interprete(symbol_table)
				if cond.class == TrueClass or cond.class == FalseClass then cond = @instruction1.interprete(symbol_table)
				else cond = eval(@instruction1.interprete(symbol_table))
				end
			end
		end

	end 
end

class WhileLoopNode

	def initialize(condition, instruction)
		@condition = condition
		@instruction = instruction
	end

	def printAST(indent)
		puts "#{indent}WHILE LOOP"
		puts "#{indent+"  "}WHILE:"
		@condition.printAST(indent+"    ")
		puts "#{indent+"  "}DO:"
		@instruction.printAST(indent+"    ")
	end

	def check(table)
		if @condition.check(table) != "bool"
			if @condition.instance_of? BinExpressionNode
				SemanticErrors.push("Error en línea #{findLeftMostOperand(@condition.leftoperand).value.locationinfo[:line]}, columna #{findLeftMostOperand(@condition.leftoperand).value.locationinfo[:column]}: Instrucción 'while' espera expresion de tipo 'bool'")
			elsif @condition.instance_of? UnaryExpressionNode
				SemanticErrors.push("Error en línea #{@condition.operand.value.locationinfo[:line]}, columna #{@condition.operand.value.locationinfo[:column]}: Instrucción 'while' espera expresion de tipo 'bool'")
			elsif
				@condition.instance_of? ConstExpressionNode
					SemanticErrors.push("Error en línea #{@condition.value.locationinfo[:line]}, columna #{@condition.value.locationinfo[:column]}: Instrucción 'while' espera expresion de tipo 'bool'")
			else
				SemanticErrors.push("Instruccion 'while' espera expresion de tipo 'bool'")
			end
		end

		@instruction.check(table)
	end

	#--------------------------------------------------------------------------#
	# 								INTERPRETADOR DEL CICLO WHILE
	# -> Interpreta la condición (es un booleano)
	# -> Interpreta la instrucción
	# -> Interpreta la condición en cada iteración para verificar la modificación 
	#--------------------------------------------------------------------------#
	def interprete(sym_table)
		while(@condition.interprete(sym_table)) do 
			@instruction.interprete(sym_table)
		end
	end

end

class BinExpressionNode

	attr_reader :leftoperand, :rightoperand, :operator, :value

	def initialize(leftoperand, rightoperand, operator)
		@leftoperand = leftoperand
		@rightoperand = rightoperand
		@operator = operator
		@value = "#{@leftoperand.value} #{@operator} #{@rightoperand.value}"
		
		# Key is operand, array[0] is left expected operator, 
		# array[1] is right expected operator, array[2] is result
		# type
		@validOperations = {
			
			'sum'=> 	['PLUS', 'int', 'int', 'int'],
			'sub'=> 	['MINUS', 'int', 'int', 'int'],
			'mul'=> 	['MULTIPLICATION', 'int', 'int', 'int'],
			'div'=> 	['DIVISION', 'int', 'int', 'int'],
			'mod'=> 	['MODULUS', 'int', 'int', 'int'],

			'lt'=> 	['LESSTHAN', 'int', 'int', 'bool'],
			'gt'=> 	['GREATERTHAN', 'int', 'int', 'bool'],
			'lte'=> 	['LESSTHANEQUAL', 'int', 'int', 'bool'],
			'gte'=> 	['GREATERTHANEQUAL', 'int', 'int', 'bool'],

			'eqint'=> ['ISEQUAL', 'int', 'int', 'bool'],			
			'difint'=> ['ISNOTEQUAL', 'int', 'int', 'bool'],
			'eqbool'=> ['ISEQUAL', 'bool','bool', 'bool'],
			'difbool'=> ['ISNOTEQUAL', 'bool', 'bool', 'bool'],
			'eqbits'=> ['ISEQUAL', 'bits','bits', 'bool'],
			'difbits'=> ['ISNOTEQUAL', 'bits', 'bits', 'bool'],

			'andbit'=> 	['ANDBITS', 'bits', 'bits', 'bits'],
			'orbit'=> 	['ORBITS', 'bits', 'bits', 'bits'],
			'excl'=> 	['TRANSFORM', 'bits', 'bits', 'bits'],
			'rshift'=> ['LEFTSHIFT', 'bits', 'int', 'bits'],
			'lshift'=> ['RIGHTSHIFT', 'bits', 'int', 'bits'],

			'and'=> 	['ANDBOOL', 'bool', 'bool', 'bool'],
			'or'=> 	['ORBOOL', 'bool', 'bool', 'bool'],
		}
	end

	def printAST(indent)
		puts "#{indent}BIN_EXPRESSION:"
		puts "#{indent+"  "}operator: #{@operator}"
		puts "#{indent+"  "}left operand:"
		@leftoperand.printAST(indent+"    ")
		puts "#{indent+"  "}right operand:"
		@rightoperand.printAST(indent+"    ")
	end

	def check(table)

		operandoDeclarado = true

		if @leftoperand.check(table) == "variable"
			if table.lookup(@leftoperand.value.value)
				leftType = table.find(@leftoperand.value.value).type
			else
				operandoDeclarado = false
				SemanticErrors.push("Error en línea #{findLeftMostOperand(@leftoperand).value.locationinfo[:line]}, columna #{findLeftMostOperand(@leftoperand).value.locationinfo[:column]}: El operando #{@leftoperand.value.value} no fue declarado")
				return
			end
		else
			leftType = @leftoperand.check(table)
		end

		if @rightoperand.check(table) == "variable"
			if table.lookup(@rightoperand.value.value)
				rightType = table.find(@rightoperand.value.value).type
			else
				operandoDeclarado = false
				SemanticErrors.push("Error en línea #{findLeftMostOperand(@rightoperand).value.locationinfo[:line]}, columna #{findLeftMostOperand(@rightoperand).value.locationinfo[:column]}: El operando #{@rightoperand.value.value} no fue declarado")
				return
			end
		else
			rightType = @rightoperand.check(table)	
		end

		if operandoDeclarado
			@validOperations.each do |op, value|
				if leftType == value[1] and @operator == value[0] and rightType == value[2]

				return value[3]

				end
			end
		end

		if @leftoperand.instance_of? BinExpressionNode
			SemanticErrors.push("Error en línea #{findLeftMostOperand(@leftoperand).value.locationinfo[:line]}: #{@operator} no puede funcionar con estos tipos")
			return

		elsif @leftoperand.instance_of? UnaryExpressionNode
			SemanticErrors.push("Error: #{@operator} no puede funcionar con estos tipos")
			return
		else
			SemanticErrors.push("Error en línea #{findLeftMostOperand(@leftoperand).value.locationinfo[:line]}, columna #{@leftoperand.value.locationinfo[:column]}: #{@operator} no puede funcionar con estos tipos")
			return
		end
	end

	#--------------------------------------------------------------------------#
	# 						INTERPRETADOR DE LAS EXPRESIONES BINARIAS
	# '(' EXPRESSION ')'			 < Delimitador de expresiones >
	#	EXPRESION '*' EXPRESION  < Multiplicación con enteros >
	#	EXPRESION '/' EXPRESION  < División con enteros >
	#	EXPRESION '%' EXPRESION  < Módulo con enteros >
	#	EXPRESION '+' EXPRESION  < Suma con enteros >
	#	EXPRESION '-' EXPRESION  < Resta con enteros >
	#	EXPRESION '<<' EXPRESION < Shift a la izquierda de expresiones con bits >
	#	EXPRESION '>>' EXPRESION < Shift a la derecha de expresiones con bits >
	#	EXPRESION '<' EXPRESION  < Menor que  con enteros>
	#	EXPRESION '<=' EXPRESION < Menor o igual que con enteros> 
	#	EXPRESION '>' EXPRESION  < Mayor que entre con enteros >
	#	EXPRESION '>=' EXPRESION < Mayor o igual que >
	#	EXPRESION '==' EXPRESION < Equivalencia entre enteros, entre booleanos o entre bits >
	#	EXPRESION '!=' EXPRESION < Inequivalencia entre enteros, entre booleanos, o entre bits >
	#	EXPRESION '&' EXPRESION  < Conjunción entre bits >
	#	EXPRESION '|' EXPRESION  < Disyuncíón entre bits >
	#	EXPRESION '^' EXPRESION  < Exclusión entre bits >
	#	EXPRESION '&&' EXPRESION < Conjunción entre booleanos >
	#	EXPRESION '||' EXPRESION < Disyunción entre booleanos >
	#--------------------------------------------------------------------------#
	def interprete(sym_table)

		if (@operator == "MULTIPLICATION") then 
			return @leftoperand.interprete(sym_table).to_i * @rightoperand.interprete(sym_table).to_i
		elsif (@operator == "DIVISION") then
			opizq = @leftoperand.interprete(sym_table).to_i
			opdech = @rightoperand.interprete(sym_table).to_i
			if (opdech == 0)
				raise "Error. División por cero."
			end
			return  opizq / opdech 
		elsif (@operator == "MODULUS") then
			return @leftoperand.interprete(sym_table).to_i % @rightoperand.interprete(sym_table).to_i
		elsif (@operator == "PLUS") then
			return @leftoperand.interprete(sym_table).to_i + @rightoperand.interprete(sym_table).to_i
		elsif (@operator == "MINUS") then
			return @leftoperand.interprete(sym_table).to_i - @rightoperand.interprete(sym_table).to_i
		elsif (@operator == "LEFTSHIFT")
			return "0b"+((@leftoperand.interprete(sym_table).to_i(2) << @rightoperand.interprete(sym_table).to_i(2)).to_s(2))
		elsif (@operator == "RIGHTSHIFT")
			return "0b"+((@leftoperand.interprete(sym_table).to_i(2) >> @rightoperand.interprete(sym_table).to_i(2)).to_s(2))
		elsif (@operator == "LESSTHAN") then
			return @leftoperand.interprete(sym_table).to_i < @rightoperand.interprete(sym_table).to_i
		elsif (@operator == "LESSTHANEQUAL")
			return @leftoperand.interprete(sym_table).to_i <= @rightoperand.interprete(sym_table).to_i
		elsif (@operator == "GREATERTHAN")
			return @leftoperand.interprete(sym_table).to_i > @rightoperand.interprete(sym_table).to_i
		elsif (@operator == "GREATERTHANEQUAL")
			return @leftoperand.interprete(sym_table).to_i >= @rightoperand.interprete(sym_table).to_i
		elsif (@operator == "ISEQUAL")
			return @leftoperand.interprete(sym_table).to_i == @rightoperand.interprete(sym_table).to_i
		elsif (@operator == "ISNOTEQUAL")
			return @leftoperand.interprete(sym_table).to_i != @rightoperand.interprete(sym_table).to_i
		elsif (@operator == "ANDBITS")
			return "0b"+((@leftoperand.interprete(sym_table).to_i(2) & @rightoperand.interprete(sym_table).to_i(2)).to_s(2))
		elsif (@operator == "ORBITS")
			return "0b"+((@leftoperand.interprete(sym_table).to_i(2) | @rightoperand.interprete(sym_table).to_i(2)).to_s(2))
		elsif (@operator == "EXCLUSIVE")
			return "0b"+((@leftoperand.interprete(sym_table).to_i(2) ^ @rightoperand.interprete(sym_table).to_i(2)).to_s(2))
		elsif (@operator == "ANDBOOL")
			return (@leftoperand.interprete(sym_table) && @rightoperand.interprete(sym_table))
		elsif (@operator == "ORBOOL")
			return (@leftoperand.interprete(sym_table) || @rightoperand.interprete(sym_table))
		end

		raise "Hubo un error al verificar una operación binaria"
	end

end

class UnaryExpressionNode

	attr_reader :operand, :operator, :value

	def initialize(operand, operator)
		@operand = operand
		@operator = operator
		@value = "#{operator} #{operand.value}"
	
		@validUnaryOperations = {

			'-'=> ['UMINUS', 'int', 'int'],
			'@'=> ['TRANSFORM', 'int', 'bits'],
			'!'=> ['NOT', 'bool', 'bool'],
			'$'=> ['BITREPRESENTATION', 'bits', 'int'],
			'~'=> ['NOTBITS', 'bits', 'bits']
		}
	end

	def printAST(indent)
		puts "#{indent}UNARY_EXPRESSION:"
		puts "#{indent+"  "}operand:"
		@operand.printAST(indent+"    ")
		puts "#{indent+"  "}operator: #{@operator}"
	end

	def check(table)
		operandoDeclarado = true

		if @operand.check(table) == "variable"
			if table.lookup(@operand.value.value)
				type = table.find(@operand.value.value).type
			else
				operandoDeclarado = false
				SemanticErrors.push("Error: El operando #{@operand.value.value} no fue declarado")
				return
			end
		else
			type = @operand.check(table)	
		end

		if operandoDeclarado
			@validUnaryOperations.each do |op, value|
				if type == value[1] and @operator == value[0]
					return value[2]
				end
			end
		end

		SemanticErrors.push("Error en línea #{@operand.value.locationinfo[:line]}, columna #{@operand.value.locationinfo[:column]}: #{@operator} no puede funcionar con estos tipos")
		return
	end

	#--------------------------------------------------------------------------#
	# 						INTERPRETADOR DE LAS EXPRESIONES UNARIAS 
	#  '!' EXPRESION < Negación de booleanos >
	#	 '~' EXPRESION < Negación de expresión con bits >
	#	 '$' EXPRESION < Representación en entero de expresión con bits >
	#	 '@' EXPRESION < Representación en expresión con bits de un entero >
	#	 '-' EXPRESION < Menos unario para enteros>
	#--------------------------------------------------------------------------#
	def interprete(sym_table)
		if (@operator == "NOT") then return ! @operand.interprete(sym_table)
		elsif (@operator == "NOTBITS") then return @operand.interprete(sym_table)[2..-1].tr('10', '01')
		elsif @operator == "BITREPRESENTATION" then return @operand.interprete(sym_table).to_i
		elsif @operator == "TRANSFORM" then
		return "0b"+@operand.interprete(sym_table).to_s(2)
		elsif @operator == "UMINUS" then return - @operand.interprete(sym_table).to_i
		end

		raise "Error al interpretar una operación unaria"
	end

end

class ConstExpressionNode

	attr_reader :type, :value

	def initialize(value, type)
		@value = value
		@type = type
	end

	def printAST(indent)
		puts "#{indent}#{@type}: #{@value.value}"
	end

	def check(table)
		if @type != "variable"
			return @type
		end

		if table.lookup(@value.value)
			if table.find(@value.value).value
				return table.find(@value.value).type
			else
				return "variable"
			end
		else
			return "variable"
		end
	end

	#--------------------------------------------------------------------------#
	# 						INTERPRETADOR DE LAS EXPRESIONES CONSTANTES
	# Para tipos bits e int retorna el valor que contiene el Token
	# Para variables, retorna el valor obtenido desde la tabla
	#--------------------------------------------------------------------------#
	def interprete(symbol_table)
		if @type != "variable"
			return @value.value
		else
			val = symbol_table.find(@value.value)
			if val.getType() == "int" 
				return val.getValue().to_i
			elsif val.getType() == "bool"
				return eval(val.getValue())
			elsif val.getType() == "bits"
				return val.getValue()
			end
		end
	end

end

class AccessNode

	def initialize(exp1, exp2)
		@exp1 = exp1
		@exp2 = exp2
	end

	def printAST(indent)
		puts "#{indent}ACCESSOR"
		puts "#{indent+"  "}variable: #{@exp1.value.value}"
		puts "#{indent+"  "}position:"
		@exp2.printAST(indent+"    ")
	end

	def check(table)
		if @exp1.check(table) == "variable"
			if !table.lookup(@exp1.value)
				return SemanticErrors.push("Error: La variable #{@exp1.value.value} no fue declarada")
			end
		else 
			if  @exp1.check(table) != "bits" 
				return SemanticErrors.push("Error en línea #{@exp1.value.locationinfo[:line]}, columna #{@exp1.value.locationinfo[:column]}: La variable #{@exp1.value.value} no es tipo bits")
			else @exp2.check(table) != "int"
				return SemanticErrors.push("Error en línea #{@exp1.value.locationinfo[:line]}, columna #{@exp1.value.locationinfo[:column]}:: El tamaño de la variable #{@exp1.value.value} de tipo bits recibe un int")
			end
		end
	end

end

def findLeftMostOperand(leftOperand)

	if leftOperand.instance_of? ConstExpressionNode
		return leftOperand
	else
		if leftOperand.instance_of? BinExpressionNode
			return findLeftMostOperand(leftOperand.leftoperand)
		elsif leftOperand.instance_of? UnaryExpressionNode
			return findLeftMostOperand(leftOperand.operand)	
		else
			return leftOperand
		end
	end
end

def printSemanticErrors()
	SemanticErrors.each do |se|
			puts se
	end
end
