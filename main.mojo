struct Foo:
    var value: String

    fn __del__(owned self):
        print(self.value)
