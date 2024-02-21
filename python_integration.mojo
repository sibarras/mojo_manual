# The best thing is the evaluate
from python import Python


fn use_py_set() raises:
    let pySet = Python.evaluate("set([2, 3, 5, 7, 11])")
    let num_items = int(pySet.__len__())
    print(num_items, " items in set.")  # prints "5 items in set"
    print(pySet.__contains__(6))  # prints "False"

    let pyList: PythonObject = [1, 2, 3, 4]
    let list2 = [5, 6, 7, 8]


fn main() raises:
    use_py_set()
