#  Late initialization
fn my_function(x: Int):
    let z: Float32
    if x != 0:
        z = 1.0
    else:
        z = foo()
    print(z)


fn foo() -> Float32:
    return 3.14


# Implicit Type Conversion
fn tp():
    # Those 2 are the same
    var number: String = 1
    var number2 = String(1)


# Sam test
# What if the initializator needs multiple inputs:


struct MyStruct:
    var value_1: Int
    var value_2: Int

    fn __init__(inout self, x: Int):
        self.value_1 = x
        self.value_2 = x + 1

    fn __init__(inout self, tp: Tuple[Int, Int]):
        self.value_1 = tp.get[0, Int]()
        self.value_2 = tp.get[1, Int]()


fn cohersion():
    var a: MyStruct = 1
    print(a.value_1)
    print(a.value_2)

    var b: MyStruct = 1, 2
    print(b.value_1)
    print(b.value_2)


fn main():
    var name = "sam"
    let user_id = 1

    name = "Sammy"
