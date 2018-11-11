#! /usr/bin/ruby

############################################################
# Universidad Simón Bolívar
# CI3175: Traductores e interpretadores
# 
# Bitiondo
#
# Tabla de símbolos para Bitiondo
#
# 
# David Cabeza 13-10191 <13-10191@usb.ve>
# Fabiola Martínez 13-10838 <13-10838@usb.ve>
############################################################

#-----------------------------------------------------------
# Simbolos para la tabla de símbolos
#-----------------------------------------------------------
class Sym

	attr_reader	:name, :type, :value, :size

	def initialize(name, type, value, size)
		@name = name
		@type = type
		@value = value
		@size = size
	end

	def getName()
		return @name
	end

	def getType()
		return @type
	end

	def getValue()
		return @value
	end

	def getSize()
		if @size
			return @size
		end
		return
	end

	def to_s
		s = "Name: #{@name}, Type: #{@type}"
		return s
	end

end

#-----------------------------------------------------------
# Tabla de Símbolos
#-----------------------------------------------------------
class SymbolTable

	def initialize(parentTable)
		@symTable = Hash.new
		@parentTable = parentTable
	end

	def insert(name, type, value, size)

		if value
			
			if size
				s = Sym.new(name, type, value, size)
				@symTable[name] = s
				return true
			end
			
			s = Sym.new(name, type, value, nil)
			@symTable[name] = s
			return true

		elsif not value
			
			if size
				s = Sym.new(name, type, nil, size)
				@symTable[name] = s
				return true
			end

			s = Sym.new(name, type, nil, nil)
			@symTable[name] = s
			return true
		end

		return false
	
	end

	def delete(name)
		return @symTable.delete(name)
	end

	def update(name, type, value, size)
		return insert(name, type, value, size)
	end

	def isMember(name)
		return @symTable.has_key?(name)
	end

	# Returns element
	def find(name)
		if @symTable.has_key?(name)
			return @symTable[name]
		end
		
		if @parentTable
			return @parentTable.find(name)
		end

		# Raise exception and finaliza el programa!
		return nil 
	end

	# Returns true or false if element exists
	def lookup(name)
		if isMember(name)
			return isMember(name)
		end

		if @parentTable
			return @parentTable.lookup(name)
		end

		return false
	end

	def printSymTab(indent)

		@symTable.each do |key, value|
			puts "#{indent} #{value.to_s}"
		end 
		
	end

end
