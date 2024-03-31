@value
struct MyValue(Stringable):
    var value: Int

    fn __str__(self) -> String:
        return str(self.value)

    fn __iadd__(inout self, other: MyValue) -> None:
        self.value += other.value


fn test_mutable_with_inmutable():
    var a: MyValue = 1
    mutable_reference_value(a)
    own_value(
        a
    )  # this creates a copy of the value, so don't affect the outside, but in the inside you can treat it as yours.
    borrow_value(a)  # this creates a reference
    print(a)
    own_value(
        a ^
    )  # this one transfers or moves the value, and will be destroyed after use.


fn mutable_reference_value(inout a: MyValue):
    a += 1
    print(a)


fn own_value(owned a: MyValue):
    a += 1
    print(a)


fn borrow_value(a: MyValue):
    print(a)


from tensor import Tensor, TensorShape


def print_shape(borrowed tensor: Tensor[DType.float32]):
    shape = tensor.shape()
    print(shape.__str__())


def run_tensor_shape():
    alias tensor = Tensor[DType.float32](256, 256)
    print_shape(tensor)


# TODO: What is @register_passable?


def example(borrowed a: Int, inout b: Int, c):
    pass


# fn example(a: Int, inout b: Int, owned c: object):
#     pass


fn main() raises:
    test_mutable_with_inmutable()
    _ = run_tensor_shape()
