struct MyPair:
    var first: Int
    var second: Int

    fn __init__(inout self, first: Int, second: Int):
        self.first = first
        self.second = second

    fn get_sum(self) -> Int:
        return self.first + self.second


struct Logger:
    fn __init__(inout self):
        pass

    @staticmethod
    fn log_info(message: String):
        print("INFO: " + message)


# Value decorator is like dataclass
@value
struct MyPet:
    var name: String
    var age: Int


struct MyPet2:
    var name: String
    var age: Int

    fn __init__(inout self, owned name: String, age: Int):
        self.name = name ^
        self.age = age

    fn __copyinit__(inout self, existing: Self):
        self.name = existing.name
        self.age = existing.age

    fn __moveinit__(inout self, owned existing: Self):
        self.name = existing.name ^
        self.age = existing.age


fn main():
    let mine = MyPair(2, 4)
    print(mine.first)
    print(mine.get_sum())

    var l = Logger()
    l.log_info("Hello, world!")
    Logger.log_info("Hello, world!")

    let dog = MyPet("Dog", 3)
    let poodle = dog
    print(poodle.name)
    print(dog.name)
