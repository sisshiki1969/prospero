IMAGE_SIZE = 512

class SIMDFloat
    attr_accessor :value

    def initialize(value)
        @value = value
    end

    def inspect
        @value.inspect
    end

    def +(other)
        if other.is_a?(SIMDFloat)
            SIMDFloat.new(@value.value + other.value)
        elsif other.is_a?(SIMDArray)
            SIMDArray.new(other.size) do |i|
                if other[i].is_a?(SIMDArray)
                    SIMDArray.new(other.size, @value) + other[i]
                else
                    @value + other[i]
                end
            end
        end
    end
    
    def -(other)
        if other.is_a?(SIMDFloat)
            SIMDFloat.new(@value.value - other.value)
        elsif other.is_a?(SIMDArray)
            SIMDArray.new(other.size) do |i|
                if other[i].is_a?(SIMDArray)
                    SIMDArray.new(other.size, @value) - other[i]
                else
                    @value - other[i]
                end
            end
        end
    end
end

class SIMDArray < Array

    def +(other)
        if other.is_a?(SIMDFloat)
            SIMDArray.new(size) do |i|
                if self[i].is_a?(SIMDArray)
                    self[i] + other
                elsif self[i].is_a?(Float)
                    self[i] + other.value
                else
                    raise "unknown type '#{self[i].class}'"
                end
            end
        elsif other.is_a?(SIMDArray)
            raise "size mismatch" unless size == other.size
            SIMDArray.new(size) do |i|
                self[i] + other[i]
            end
        else
            SIMDArray.new(size) do |i|
                self[i] + other
            end
        end
    end

    def -(other)
        if other.is_a?(SIMDFloat)
            SIMDArray.new(size) do |i|
                if self[i].is_a?(SIMDArray)
                    self[i] - other
                elsif self[i].is_a?(Float)
                    self[i] - other.value
                else
                    raise "unknown type '#{self[i].class}'"
                end
            end
        elsif other.is_a?(SIMDArray)
            raise "size mismatch" unless size == other.size
            SIMDArray.new(size) do |i|
                self[i] - other[i]
            end
        else
            SIMDArray.new(size) do |i|
                self[i] - other
            end
        end
    end

    def *(other)
        if other.is_a?(SIMDArray)
            raise "size mismatch" unless size == other.size
            SIMDArray.new(size) do |i|
                self[i] * other[i]
            end
        elsif other.is_a?(SIMDFloat)
            SIMDArray.new(size) do |i|
                if self[i].is_a?(SIMDArray)
                    self[i] * other
                elsif self[i].is_a?(Float)
                    self[i] * other.value
                else
                    raise "unknown type '#{self[i].class}'"
                end
            end
        else
            SIMDArray.new(size) do |i|
                self[i] * other
            end
        end
    end

    def -@
        SIMDArray.new(size) do |i|
            -self[i]
        end
    end

    def max(other)
        if other.is_a?(SIMDFloat)
            SIMDArray.new(size) do |i|
                if self[i].is_a?(SIMDArray)
                    self[i].max(other)
                else
                    [self[i], other.value].max
                end
            end
        elsif other.is_a?(SIMDArray)
            raise "size mismatch" unless size == other.size
            SIMDArray.new(size) do |i|
                if self[i].is_a?(SIMDArray)
                    self[i].max(other[i])
                else
                    [self[i], other[i]].max
                end
            end
        else
            raise "unknown type '#{other.class}'"
        end
    end

    def min(other)
        if other.is_a?(SIMDFloat)
            SIMDArray.new(size) do |i|
                if self[i].is_a?(SIMDArray)
                    self[i].min(other)
                else
                    [self[i], other.value].min
                end
            end
        elsif other.is_a?(SIMDArray)
            raise "size mismatch" unless size == other.size
            SIMDArray.new(size) do |i|
                if self[i].is_a?(SIMDArray)
                    self[i].min(other[i])
                else
                    [self[i], other[i]].min
                end
            end
        else
            raise "unknown type '#{other.class}'"
        end
    end

    def sqrt
        SIMDArray.new(size) do |i|
            if self[i].is_a?(SIMDArray)
                self[i].sqrt
            else
                Math.sqrt(self[i])
            end
        end
    end

    def <(other)
        SIMDArray.new(size) do |i|
            if self[i].is_a?(SIMDArray)
                self[i] < other
            else
                if self[i] < other
                    1
                else
                    0
                end
            end
        end
    end

    def chr
        res = ""
        self.each do |elem|
            res += elem.chr
        end
        res
    end
end

# Read the VM code from a file
text = File.read('prospero.vm').chomp

x = SIMDArray.new(IMAGE_SIZE) do
    SIMDArray.new(IMAGE_SIZE) do |i|
        -1.0 + 2.0 * i.to_f / (IMAGE_SIZE - 1)
    end
end
y = SIMDArray.new(IMAGE_SIZE) do |i|
    SIMDArray.new(IMAGE_SIZE, 1.0 - 2.0 * i.to_f / (IMAGE_SIZE - 1))
end

insns = []

for line in text.split("\n")
    if line.start_with?("#")
        next
    end
    out, op, *args = line.split(" ")
    if out.delete_prefix("_").to_i(16) != insns.size
        raise "instruction #{out} does not match the position #{insns.size}"
    end
    args.map!{ |arg| if arg.start_with?("_") then arg.delete_prefix("_").to_i(16) else arg.to_f end }
    insns << case op
    when "var-x"; [0]
    when "var-y"; [1]
    when "const"; [2, SIMDFloat.new(args[0])]
    when "add"; [3, args[0], args[1]]
    when "sub"; [4, args[0], args[1]]
    when "mul"; [5, args[0], args[1]]
    when "max"; [6, args[0], args[1]]
    when "min"; [7, args[0], args[1]]
    when "neg"; [8, args[0]]
    when "square"; [9, args[0]]
    when "sqrt"; [10, args[0]]
    else raise "unknown opcode '#{op}'"
    end
end

v = []

insn_size = insns.size
for i in 0..insn_size - 1
    insn, args0, args1 = insns[i]
    case insn
    when 0; v[i] = x
    when 1; v[i] = y
    when 2; v[i] = args0
    when 3; v[i] = v[args0] + v[args1]
    when 4; v[i] = v[args0] - v[args1]
    when 5; v[i] = v[args0] * v[args1]
    when 6; v[i] = v[args0].max(v[args1])
    when 7; v[i] = v[args0].min(v[args1])
    when 8; v[i] = -v[args0]
    when 9; v[i] = v[args0] * v[args0]
    when 10;v[i] = v[args0].sqrt
    else raise "unknown opcode '#{insn}'"
    end
end

out = v[-1]

f = File.open('out_ruby.ppm', 'wb') # write the image out
f.write("P5\n#{IMAGE_SIZE} #{IMAGE_SIZE}\n255\n")
f.write(((out < 0) * 255).chr)
