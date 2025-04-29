import math

with open('prospero.vm') as f:
    text = f.read().strip()

image_size = 512
v = ""

for line in text.split('\n'):
    if line.startswith('#'):
        continue
    [out, op, *args] = line.split()
    v += f"\t{out} = "
    match op:
        case "var-x": v += "x"
        case "var-y": v += "y"
        case "const": v += args[0]
        case "add": v += f"{args[0]} + {args[1]}"
        case "sub": v += f"{args[0]} - {args[1]}"
        case "mul": v += f"{args[0]} * {args[1]}"
        case "max": v += f"max({args[0]}, {args[1]})"
        case "min": v += f"min({args[0]}, {args[1]})"
        case "neg": v += f"-{args[0]}"
        case "square": v += f"{args[0]} * {args[0]}"
        case "sqrt": v += f"math.sqrt({args[0]})"
        case _: raise Exception(f"unknown opcode '{op}'")
    v += "\n"

code = f"""
def calculate(x, y):
{v}
\treturn 255 if {out} < 0.0 else 0
"""

exec(code, globals())


with open('out.ppm', 'wb') as f: # write the image out
    f.write(f'P5\n{image_size} {image_size}\n255\n'.encode())
    s = b""
    for j in range(0, image_size):
        for i in range(0, image_size):
            x = -1.0 + 2.0 * i / (image_size - 1)
            y = 1.0 - 2.0 * j / (image_size - 1)
            s += calculate(x, y).to_bytes(1, byteorder='big')
    f.write(s)
