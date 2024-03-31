struct Foo:
    var value: String

    fn __del__(owned self):
        print(self.value)

fn main() raises:
    print("Hello World", "samuel", sep=", ", end="\n")
