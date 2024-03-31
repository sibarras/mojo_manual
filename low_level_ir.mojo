@register_passable("trivial")
struct MyBool:
    var value: __mlir_type.i1

    fn __init__() -> Self:
        return Self {value: __mlir_attr.false}

    fn __init__(value: __mlir_type.i1) -> Self:
        return Self {value: value}

    fn __mlir_i1__(self) -> __mlir_type.i1:
        return self.value

    fn __eq__(self, rhs: Self) -> Self:
        var lhs_index = __mlir_op.`index.casts`[_type = __mlir_type.index](self.value)
        var rhs_index = __mlir_op.`index.casts`[_type = __mlir_type.index](rhs.value)
        return Self(
            __mlir_op.`index.cmp`[pred = __mlir_attr.`#index<cmp_predicate eq>`](
                lhs_index, rhs_index
            )
        )

    fn __invert__(self) -> Self:
        return MyFalse if self == MyTrue else MyTrue


alias MyTrue: MyBool = __mlir_attr.true
alias MyFalse: MyBool = __mlir_attr.false


# TODO: Study how to build a simpler tuple type.
fn main():
    alias my_bool = MyBool()
