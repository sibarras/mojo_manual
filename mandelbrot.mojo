import benchmark
from complex import ComplexFloat64, ComplexSIMD
from math import iota
from python import Python
from sys.info import num_physical_cores
from algorithm import parallelize, vectorize
from tensor import Tensor
from utils.index import Index

alias Float = DType.float64
alias simd_width = 2 * simdwidthof[Float]()

alias width = 960
alias height = 960
alias MAX_ITERS = 200

alias min_x = -2.0
alias max_x = 0.6
alias min_y = -1.5
alias max_y = 1.5


fn mandelbrot_kernel(c: ComplexFloat64) -> Int:
    var z = c
    for i in range(MAX_ITERS):
        z = z * z + c
        if z.squared_norm() > 4.0:
            return i
    return MAX_ITERS


fn mandelbrot_kernel_SIMD[
    simd_width: Int, T: DType
](c: ComplexSIMD[T, simd_width]) -> SIMD[T, simd_width]:
    """Vectorized representation of mandelbrot kernel."""
    let cx = c.re
    let cy = c.im
    var x: SIMD[T, simd_width] = 0
    var y: SIMD[T, simd_width] = 0
    var y2: SIMD[T, simd_width] = 0
    var iters: SIMD[T, simd_width] = 0

    var t: SIMD[DType.bool, simd_width] = True
    for i in range(MAX_ITERS):
        if not t.reduce_or():
            break
        y2 = y * y
        y = x.fma(y + y, cy)
        t = x.fma(x, y2) <= 4
        x = x.fma(x, cx - y2)
        iters = t.select(iters + 1, iters)
    return iters


fn vectorized():
    let t = Tensor[Float](height, width)

    @parameter
    fn worker(row: Int):
        alias scale_x = (max_x - min_x) / width
        alias scale_y = (max_y - min_y) / height

        @parameter
        fn compute_vector[simd_width: Int](col: Int):
            """Each time we operate on a `simd_width` vector of pixels."""
            let cx = min_x + (col + iota[Float, simd_width]()) * scale_x
            let cy = min_y + row * scale_y
            let c = ComplexSIMD[Float, simd_width](cx, cy)
            t.data().simd_store[simd_width](
                row * width + col, mandelbrot_kernel_SIMD[simd_width](c)
            )

        vectorize[simd_width, compute_vector](width)

    @parameter
    fn bench[simd_width: Int]():
        for row in range(height):
            worker(row)

    let vectorized = benchmark.run[bench[simd_width]](max_runtime_secs=0.5).mean(
        benchmark.Unit.ms
    )
    print("Vectorized: ", vectorized, "ms")

    try:
        _ = show_plot(t)
    except e:
        print("Failed to show plot: ", e)


fn parallelized():
    let t = Tensor[Float](height, width)

    @parameter
    fn worker(row: Int):
        alias scale_x = (max_x - min_x) / width
        alias scale_y = (max_y - min_y) / height

        @parameter
        fn compute_vector[simd_width: Int](col: Int):
            """Each time we operate on a `simd_width` vector of pixels."""
            let cx = min_x + (col + iota[Float, simd_width]()) * scale_x
            let cy = min_y + row * scale_y
            let c = ComplexSIMD[Float, simd_width](cx, cy)
            t.data().simd_store[simd_width](
                row * width + col, mandelbrot_kernel_SIMD[simd_width](c)
            )

        vectorize[simd_width, compute_vector](width)

    @parameter
    fn bench_parallel[simd_width: Int]():
        parallelize[worker](height, height)

    let parallelized = benchmark.run[bench_parallel[simd_width]](
        max_runtime_secs=0.5
    ).mean(benchmark.Unit.ms)
    print("Parallelized: ", parallelized, "ms")

    try:
        _ = show_plot(t)
    except e:
        print("Failed to show plot: ", e)


fn compute_mandelbrot() -> Tensor[Float]:
    var t = Tensor[Float](height, width)

    let dx = (max_x - min_x) / width
    let dy = (max_y - min_y) / height

    var y = min_y
    for row in range(height):
        var x = min_x
        for col in range(width):
            t[Index(row, col)] = mandelbrot_kernel(ComplexFloat64(x, y))
            x += dx
        y += dy
    return t


fn show_plot(tensor: Tensor[Float]) raises:
    alias scale = 10
    alias dpi = 64

    let np = Python.import_module("numpy")
    let plt = Python.import_module("matplotlib.pyplot")
    let colors = Python.import_module("matplotlib.colors")

    let numpy_array = np.zeros((height, width), np.float64)

    for row in range(height):
        for col in range(width):
            _ = numpy_array.itemset((col, row), tensor[col, row])

    let fig = plt.figure(1, [scale, scale * height // width], dpi)
    let ax = fig.add_axes([0.0, 0.0, 1.0, 1.0], False, 1)
    let light = colors.LightSource(315, 10, 0, 1, 1, 0)

    let image = light.shade(
        numpy_array, plt.cm.hot, colors.PowerNorm(0.3), "hsv", 0, 0, 1.5
    )
    _ = plt.imshow(image)
    _ = plt.axis("off")
    _ = plt.savefig("mbrot.png")


fn main():
    parallelized()
