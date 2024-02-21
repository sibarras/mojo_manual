# Parameters are for metaprogramming

# Parameter is a compile time variable that becomes a runtime constant
# In Mojo, Parameter is a compile time value and argument a runtime value.


fn repeat[count: Int](msg: String):
    @unroll
    for i in range(count):
        print(msg)


fn repeat_with_factor[count: Int, factor: Int](msg: String):
    @unroll(factor)
    for i in range(count):
        print(msg)


# Parametrized Structs
struct GenericArray[T: AnyRegType]:
    var data: Pointer[T]
    var size: Int
    var current: Int

    fn __init__(inout self, *elements: T):
        self.current = 0
        self.size = len(elements)
        self.data = Pointer[T].alloc(self.size)
        for i in range(self.size):
            self.data[i] = elements[i]

    fn __del__(owned self):
        self.data.free()

    fn __getitem__(self, index: Int) raises -> T:
        return self.data[index]


fn test_generic_array() raises:
    var arr = GenericArray(1, 2, 3, 4, 5)
    for i in range(arr.size):
        print(arr[i])


# TODO: What is register passable type?. AnyRegType is for that... but what is it?

# Fully Bound, Partially Bound, Unbound types


struct MyType[s: String, i: Int]:
    pass


fn call_my_type():
    let v0 = MyType
    let v = MyType["Hello"]
    let v2 = MyType["Hello", 10]


# # SIMD Case of Study
# struct SIMD[type: DType, size: Int]:
#     # var value: ...

#     fn __init__(inout self, *elems: SIMD[type, 1]):
#         ...

#     # Fill a SIMD with duplicated scalar values
#     @staticmethod
#     fn splat(x: SIMD[type, 1]) -> SIMD[type, size]:
#         ...

#     # Cast the elements of the SIMD to a different elt type.
#     fn cast[target: DType](self) -> SIMD[target, size]:
#         ...

#     fn __add__(self, rhs: Self) -> Self:
#         ...


fn use_simd():
    var vector = SIMD[DType.int16, 4](1, 2, 3, 4)
    vector = vector * vector
    for i in range(4):
        print_no_newline(vector[i], " ")
    else:
        print()


# Overloading using parameters
@register_passable("trivial")
struct MyInt:
    var value: Int

    @always_inline("nodebug")
    fn __init__(_a: Int) -> Self:
        return Self {value: _a}


fn foo[x: MyInt, a: Int]():
    print("foo[x: MyInt, a: Int]()")


fn foo[x: MyInt, y: MyInt]():
    print("foo[x: MyInt, y: MyInt]()")


fn bar[a: Int](b: Int):
    print("bar[a: Int](b: Int)")


fn bar[a: Int](*b: Int):
    print("bar[a: Int](*b: Int)")


fn bar[*a: Int](b: Int):
    print("bar[*a: Int](b: Int)")


fn parameter_overloads[a: Int, b: Int, x: MyInt]():
    # `foo[x: MyInt, a: Int]()` is called because it requires no implicit
    # conversions, whereas `foo[x: MyInt, y: MyInt]()` requires one.
    foo[x, a]()
    # `bar[a: Int](b: Int)` is called because it does not have variadic
    # arguments or parameters.
    bar[a](b)
    # `bar[*a: Int](b: Int)` is called because it has variadic parameters.
    bar[a, a, a](b)


struct MyStruct:
    fn __init__(inout self):
        pass

    fn foo(inout self):
        print("Calling instance method")

    @staticmethod
    fn foo():
        print("Calling static method")


fn test_static_overloads():
    var a = MyStruct()
    # `foo(inout self)` takes precedence over a static method.
    a.foo()


# Using parametrized types and functions
fn parametrized_types():
    let small_vec = SIMD[DType.float32, 4](1.0, 2.0, 3.0, 4.0)
    # Make a big vector containing 1.0 in float16 format.
    let big_vec = SIMD[DType.float16, 32].splat(1.0)
    # Do some math and convert the elements to float32.
    let bigger_vec = (big_vec + big_vec).cast[DType.float32]()
    # You can write types out explicitly if you want of course.
    let bigger_vec2: SIMD[DType.float32, 32] = bigger_vec
    print("small_vec type:", small_vec.element_type, "length:", len(small_vec))
    print("bigger_vec2 type:", bigger_vec2.element_type, "length:", len(bigger_vec2))


# power of defiing parametric alogirthms and types
from math import sqrt


fn rsqrt[dt: DType, width: Int](x: SIMD[dt, width]) -> SIMD[dt, width]:
    return 1 / sqrt(x)


# Optional Parameters
fn speak[a: Int = 3, msg: StringLiteral = "woof"]():
    print(msg, a)


fn use_defaults() raises:
    speak()
    speak[5]()
    speak[7, "meow"]()
    speak[msg="pio"]()


# Get the parameter from the argument inferred.
@value
struct Bar[v: Int]:
    pass


fn foo[a: Int = 3, msg: StringLiteral = "woof"](bar: Bar[a]):
    print(msg, a)


fn use_inferred():
    foo(Bar[9]())


struct KwParamStruct[greeting: StringLiteral = "Hello", name: StringLiteral = "World"]:
    fn __init__(inout self):
        print(greeting, name)


fn use_kw_params():
    let a = KwParamStruct[]()
    let b = KwParamStruct[name="Mojo"]()
    let c = KwParamStruct[greeting="Hola"]()


# Parameter expressions are just Mojo Code.
fn concat[
    ty: DType, len1: Int, len2: Int
](lhs: SIMD[ty, len1], rhs: SIMD[ty, len2]) -> SIMD[ty, len1 + len2]:
    var result = SIMD[ty, len1 + len2]()
    for i in range(len1):
        result[i] = SIMD[ty, 1](lhs[i])
    for j in range(len2):
        result[len1 + j] = SIMD[ty, 1](rhs[j])
    return result


fn concat_values():
    let a = SIMD[DType.float32, 2](1, 2)
    let x = concat(a, a)
    print("result type: ", x.element_type, "length: ", len(x))


# Powerfull compile time programming
# While simple expressions are useful, sometimes you want to write imperative compile-time logic with control flow.
# You can even do compile-time recursion.
# For instance, here is an example “tree reduction” algorithm that sums all elements of a vector recursively into a sclr


fn slice[
    ty: DType, new_size: Int, size: Int
](x: SIMD[ty, size], offset: Int) -> SIMD[ty, new_size]:
    var result = SIMD[ty, new_size]()
    for i in range(new_size):
        result[i] = SIMD[ty, 1](x[i + offset])
    return result


fn reduce_add[ty: DType, size: Int](x: SIMD[ty, size]) -> Int:
    # This makes use of the @parameter decorator to create a parametric if condition, which is an if statement that runs at compile-time.
    @parameter
    if size == 1:
        return x[0].to_int()
    elif size == 2:
        return x[0].to_int() + x[1].to_int()
    else:
        alias half_size = size // 2
        let lhs = slice[ty, half_size, size](x, 0)
        let rhs = slice[ty, half_size, size](x, half_size)
        return reduce_add[ty, half_size](lhs + rhs)


# Mojo Types are just parameter expressions


# Main part
fn main() raises:
    repeat[5]("Hello")
    repeat_with_factor[10, 2]("Factored hello!")
    test_generic_array()
    call_my_type()
    use_simd()
    parameter_overloads[1, 2, MyInt(3)]()
    test_static_overloads()
    parametrized_types()

    let v = SIMD[DType.float16, 4](42)
    let r = rsqrt(v)
    print(r)
    use_kw_params()
    concat_values()
    let a = reduce_add(SIMD[DType.index, 4](1, 2, 3, 4))
    print(a)
