IMAGE_SIZE = 512
f = File.open('out.ppm', 'wb') # write the image out
f.write("P5\n#{IMAGE_SIZE} #{IMAGE_SIZE}\n255\n")

# Read the VM code from a file
text = File.read(File.expand_path('prospero.vm', __dir__)).chomp

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
    when "const"; [2, args[0]]
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

unless respond_to?(:____max)
    def ____max(f1, f2)
        if f1 >= f2
            f1
        else
            f2
        end
    end
    def ____min(f1, f2)
        if f1 <= f2
            f1
        else
            f2
        end
    end
end

def compile(insns, i)
    insn, args0, args1 = insns[i]
    case insn
    when 0; "x"
    when 1; "y"
    when 2; "#{args0}"
    when 3; "(#{compile(insns, args0)} + #{compile(insns, args1)})"
    when 4; "(#{compile(insns, args0)} - #{compile(insns, args1)})"
    when 5; "(#{compile(insns, args0)} * #{compile(insns, args1)})"
    when 6; "____max(#{compile(insns, args0)}, #{compile(insns, args1)})"
    when 7; "____min(#{compile(insns, args0)}, #{compile(insns, args1)})"
    when 8; "(-#{compile(insns, args0)})"
    when 9; "(#{compile(insns, args0)} * #{compile(insns, args0)})"
    when 10; "Math.sqrt(#{compile(insns, args0)})"
    else raise "unknown opcode '#{insn}'"
    end
end

code = compile(insns, -1)

code = <<EOS
def calculate(insns, x, y)
    if #{code} < 0.0
        255
    else
        0
    end
end
EOS

eval code

s = ""
for j in 0...IMAGE_SIZE
    for i in 0...IMAGE_SIZE
        x = -1.0 + 2.0 * i.to_f / (IMAGE_SIZE - 1)
        y = 1.0 - 2.0 * j.to_f / (IMAGE_SIZE - 1)
        s << calculate(insns, x, y).chr
    end
end

f.write(s)