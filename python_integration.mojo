# The best thing is the evaluate
from python import Python
from collections import Set


fn use_py_set() raises:
    var pySet = Python.evaluate("set([2, 3, 5, 7, 11, 11])")
    var num_items = int(pySet.__len__())
    var set = Set(2, 3, 5, 7, 11, 11)
    print("Python has ", num_items, " items in set.")  # prints "5 items in set"
    print(
        "Check if the python set contains 6?: ", pySet.__contains__(6)
    )  # prints "False"

    print("mojo set len is:", len(set))
    print("the mojo set contains 6?:", 6 in set)

    var pyList: PythonObject = [1, 2, 3, 4]
    var list2 = [5, 6, 7, 8]


fn main() raises:
    use_py_set()
