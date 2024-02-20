def python_values():
    x = 1
    y = x
    y += 1

    print(x)
    print(y)


def add_one(y: Int):
    y += 1
    return y


def update_tensor(t: Tensor[DType.uint8]):
    t[1] = 3
    print(t)


def run_tensor():
    t = Tensor[DType.uint8](2)
    t[0] = 1
    t[1] = 2
    update_tensor(t)
    print(t)


fn add_two(x: Int):
    var z = x
    z += 2
    print(z)


fn run_add_two():
    var x = 1
    add_two(x)
    print(x)


fn main() raises:
    _ = python_values()
    _ = run_tensor()
    run_add_two()
