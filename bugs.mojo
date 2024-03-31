from collections import Set


struct MyStruct:
    var name: StringLiteral

    fn __init__(inout self, name: StringLiteral) -> None:
        self.name = name

    fn __str__(self) -> String:
        return self.name


fn main():
    alias const_empty_set = Set[Int]()  # ok
    # alias const_set = Set[Int](1)  # fails

    alias strct: MyStruct = "Sam"
    print(strct)
