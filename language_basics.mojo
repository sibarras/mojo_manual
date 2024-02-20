def greet(name):
    return "Hello, " + name + "!"


fn greet2(name: String) -> String:
    return "Hello, " + name + "!"


struct MyPair:
    var first: Int
    var second: Int

    fn __init__(inout self, first: Int, second: Int):
        self.first = first
        self.second = second

    fn dump(self):
        print(self.first, self.second)


# Traits
trait SomeTrait:
    fn some_method(self, x: Int) -> Int:
        ...


struct SomeStruct(SomeTrait):
    fn __init__(inout self):
        ...

    fn some_method(self, x: Int) -> Int:
        return x * 2


fn fun_with_traits[T: SomeTrait](x: T, y: Int) -> Int:
    return x.some_method(y)


fn use_trait_function():
    var thing = SomeStruct()
    _ = fun_with_traits(thing, 42)


# Parametrization
fn repeat[count: Int](msg: String):
    for i in range(count):
        print(msg)


fn call_repeat():
    repeat[3]("Hello")


# Blocks and statements
fn loop():
    for x in range(5):
        if x % 2 == 0:
            print(x)


fn print_line():
    let long_text = "This is a long text that should be printed With a lot of space that needs "
                    "to be covered accross the screen but may be too long to fit in a single line"

    print(long_text)

fn print_hello():
    let text =
        String(",")
        .join("Hello", " World!")

    print(text)


from python import Python

fn use_polars() raises:
    let pl = Python.import_module("polars")
    let df = pl.DataFrame([1,2,3,4,5,6]).select(pl.col("column_0").`alias`("foo"))
    print(df)

fn main() raises:
    print(greet("World"))
    print(greet2("World"))
    let mine = MyPair(1, 2)
    mine.dump()
    call_repeat()
    print_line()
    print_hello()
    # use_numpy()
    use_polars()
