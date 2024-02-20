# @value
# struct MyPet:
#     var name: String
#     var age: Int


fn pets():
    var a = MyPet("Loki", 4)
    let b = MyPet("Sylvie", 2)
    print(a.name)
    # a.__del__() runs here for "Loki"

    a = MyPet("Charlie", 8)
    # a.__del__() runs immediately because "Charlie" is never used

    print(b.name)
    # b.__del__() runs here


struct HeapArray[T: Sized]:
    var data: Pointer[Int]
    var size: Int

    fn __init__(inout self, size: Int, val: Int):
        self.size = size
        self.data = Pointer[Int].alloc(self.size)
        for i in range(self.size):
            self.data.store(i, val)

    fn __del__(owned self):
        self.data.free()


struct MyPet:
    var name: String
    var age: Int

    fn __init__(inout self, name: String, age: Int):
        self.name = name
        self.age = age

    fn __del__(owned self):
        pass


# Field lifetimes
@value
struct MyNewPet:
    var name: StringLiteral
    var age: Int

    fn __init__(inout self, data: Tuple[StringLiteral, Int]):
        self.name, self.age = data


fn use_two_strings_first():
    var pet: MyNewPet = "Po", 9
    print(pet.name)
    #  pet.__del__() runs here for "Po"

    pet.name = "Lola"
    print(pet.name)
    #  pet.__del__() runs here for "Lola"


# fn consume(owned arg: String):
#     pass


fn use(arg: MyPet):
    print(arg.name)


fn consume_and_use():
    var pet = MyPet("Selma", 5)
    consume(pet.name ^)

    # use(pet) will fail because name is unitialized
    print(pet.age)  # this works because it's not dropped.
    # print(pet.name)

    pet.name = "Lola"  # if I dont do it, I'm unable to print the obj.
    use(pet)

    # If I dont initialize again the name, the compiler will not be able to drop.

    # consume(pet.name ^) #  This creates a compiler error


# field lifetimes during destruct and move


# struct TwoStrings:
#     fn __moveinit__(inout self, owned existing: Self):
#         """Initializes a new `self` by consuming the contents of `existing`."""
#         ...

#     fn __del__(owned self):
#         """Destroys all resources in `self`."""
#         ...

# We can have a problem here because moveinit needs to know how to delete and delete needs to know how to move.

# For these two, the drop happens in the return position


fn consume(owned string: String):
    print("Consumed:", string)


struct TwoStrings:
    var str1: String
    var str2: String

    fn __init__(inout self, one: String):
        self.str1 = one
        self.str2 = String("bar")

    fn __moveinit__(inout self, owned existing: Self):
        self.str1 = existing.str1
        self.str2 = existing.str2

    fn __del__(owned self):
        self.dump()  # Self is still whole here
        # Mojo calls self.str2.__del__() since str2 isn't used anymore
        consume(self.str1 ^)
        # self.str1 has been transferred so it is also destroyed now;
        # `self.__del__()` is not called (avoiding an infinite loop).

    fn dump(inout self):
        print("str1:", self.str1)
        print("str2:", self.str2)


fn use_two_strings():
    let two_strings = TwoStrings("foo")


fn foo():
    ...


fn bar():
    ...


fn explicit_lifetimes() raises:
    with open("my_file.txt", "r") as file:
        print(file.read())

        # Other stuff happens here (whether using `file` or not)...
        foo()
        # `file` is alive up to the end of the `with` statement.

    # `file` is destroyed when the statement ends.
    bar()


fn main():
    consume_and_use()
    use_two_strings_first()
    use_two_strings()
