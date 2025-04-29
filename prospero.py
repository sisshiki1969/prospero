import numpy as np
import sys

with open('prospero.vm') as f:
    text = f.read().strip()

image_size = 512
space = np.linspace(-1, 1, image_size)
(x, y) = np.meshgrid(space, -space)
v = []

for line in text.split('\n'):
    if line.startswith('#'):
        continue
    [out, op, *args] = line.split()
    match op:
        case "var-x": v.append(x)
        case "var-y": v.append(y)
        case "const":
            arg0 = float(args[0])
            v.append(arg0)
        case "add":
            arg0 = int(args[0][1:], 16) if args[0].startswith('_') else None
            arg1 = int(args[1][1:], 16) if args[1].startswith('_') else None
            v.append(v[arg0] + v[arg1])
        case "sub":
            arg0 = int(args[0][1:], 16) if args[0].startswith('_') else None
            arg1 = int(args[1][1:], 16) if args[1].startswith('_') else None
            v.append(v[arg0] - v[arg1])
        case "mul":
            arg0 = int(args[0][1:], 16) if args[0].startswith('_') else None
            arg1 = int(args[1][1:], 16) if args[1].startswith('_') else None
            v.append(v[arg0] * v[arg1])
        case "max":
            arg0 = int(args[0][1:], 16) if args[0].startswith('_') else None
            arg1 = int(args[1][1:], 16) if args[1].startswith('_') else None
            v.append(np.maximum(v[arg0], v[arg1]))
        case "min":
            arg0 = int(args[0][1:], 16) if args[0].startswith('_') else None
            arg1 = int(args[1][1:], 16) if args[1].startswith('_') else None
            v.append(np.minimum(v[arg0], v[arg1]))
        case "neg":
            arg0 = int(args[0][1:], 16) if args[0].startswith('_') else None
            v.append(-v[arg0])
        case "square":
            arg0 = int(args[0][1:], 16) if args[0].startswith('_') else None
            v.append(v[arg0] * v[arg0])
        case "sqrt":
            arg0 = int(args[0][1:], 16) if args[0].startswith('_') else None
            v.append(np.sqrt(v[arg0]))
        case _: raise Exception(f"unknown opcode '{op}'")
out = v[-1]

with open('out.ppm', 'wb') as f: # write the image out
    f.write(f'P5\n{image_size} {image_size}\n255\n'.encode())
    f.write(((out < 0) * 255).astype(np.uint8).tobytes())
