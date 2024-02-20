# Def functions


def greet(name):
    greeting = "Hello, " + name + "!"
    return greeting


#  With types
def greet2(name: String) -> String:
    let greeting = "Hello, " + name + "!"
    return greeting


# Fn function
def greet3(name: String) -> String:
    let greeting = "Hello, " + name + "!"
    return greeting


fn pow(base: Int, exp: Int = 2) -> Int:
    return base**exp


fn use_defaults():
    let z = pow(3)
    print(z)


# With keywords
fn use_keywords():
    let z = pow(exp=3, base=2)
    print(z)


# Overloading functions
fn add(x: Int, y: Int) -> Int:
    return x + y


fn add(x: String, y: String) -> String:
    return x + y


@value
struct MyString:
    fn __init__(inout self, string: StringLiteral):
        pass


fn foo(name: String):
    print("String")


fn foo(name: MyString):
    print("MyString")


fn call_foo():
    let string = "Hello!"
    foo(String(string))
    foo(MyString(string))


fn main():
    let x = add(1, 2)
    print(x)

    let y = add("Hello, ", "World!")
    print(y)
    call_foo()


# Fixing implicit conversion with ambiguity
