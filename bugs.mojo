from collections import Set


struct MyStruct:
    var name: StringLiteral  # ok with StringLiteral, parser crashes with String

    fn __del__(owned self) -> None:
        print("Deleting the struct with name:", self.name)


struct CanBeAliased:
    var name: String

    fn __init__(inout self, name: String):
        self.name = name


struct CannotBeAliased:
    var name: String

    fn __init__(inout self, *names: String):
        self.name = String()
        for nm in names:
            print(String(nm))


fn main():
    alias const_empty_set = Set[Int]()  # ok
    # alias const_set = Set[Int](1)  # fails

    alias new_var: CanBeAliased = String("Hello!")
