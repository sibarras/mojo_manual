import benchmark
from sys.intrinsics import strided_load
from math import div_ceil, min
from memory import memset_zero
from memory.unsafe import DTypePointer
from random import rand, random_float64
from sys.info import simdwidthof
from runtime.llcl import Runtime

alias type = DType.float32


struct Matrix:
    var data: DTypePointer[type]
    var rows: Int
    var cols: Int

    fn __init__(inout self, rows: Int, cols: Int):
        self.data = DTypePointer[type].alloc(rows * cols)
        memset_zero(self.data, rows * cols)
        self.rows = rows
        self.cols = cols

    fn __init__(inout self, rows: Int, cols: Int, data: DTypePointer[type]):
        self.data = data
        self.rows = rows
        self.cols = cols

    @staticmethod
    fn rand(rows: Int, cols: Int) -> Self:
        var data = DTypePointer[type].alloc(rows * cols)
        rand(data, rows * cols)
        return Self(rows, cols, data)

    fn __getitem__(self, y: Int, x: Int) -> Float32:
        return self.load[1](y, x)

    fn __setitem__(self, y: Int, x: Int, value: Float32):
        self.store[1](y, x, value)

    fn load[nelts: Int](self, y: Int, x: Int) -> SIMD[type, nelts]:
        return self.data.load[width=nelts](y * self.cols + x)

    fn store[nelts: Int](self, y: Int, x: Int, value: SIMD[type, nelts]):
        self.data.store[width=nelts](y * self.cols + x, value)


fn matmul_naive(c: Matrix, a: Matrix, b: Matrix):
    for m in range(c.rows):
        for k in range(a.cols):
            for n in range(c.cols):
                c[m, n] += a[m, k] * b[k, n]


alias nelts = simdwidthof[type]()


fn matmul_vectorized_0(c: Matrix, a: Matrix, b: Matrix):
    for m in range(c.rows):
        for k in range(a.cols):
            for nv in range(0, c.cols, nelts):
                c.store[nelts](
                    m, nv, c.load[nelts](m, nv) + a[m, k] * b.load[nelts](k, nv)
                )

            for n in range(nelts * (c.cols // nelts), c.cols):
                c[m, n] += a[m, k] * b[k, n]


from algorithm import vectorize


fn matmul_vectorized_1(c: Matrix, a: Matrix, b: Matrix):
    for m in range(c.rows):
        for k in range(a.rows):

            @parameter
            fn dot[nelts: Int](n: Int):
                c.store[nelts](
                    m, n, c.load[nelts](m, n) + a[m, k] * b.load[nelts](k, n)
                )

            vectorize[dot, nelts](c.cols)


from algorithm import parallelize


fn matmul_parallelized(c: Matrix, a: Matrix, b: Matrix):
    @parameter
    fn calc_row(m: Int):
        for k in range(a.cols):

            @parameter
            fn dot[nelts: Int](n: Int):
                c.store[nelts](
                    m, n, c.load[nelts](m, n) + a[m, k] * b.load[nelts](k, n)
                )

            vectorize[dot, nelts](c.cols)

    parallelize[calc_row](c.rows, c.rows)


from algorithm import Static2DTileUnitFunc as Tile2DFunc


fn tile[tiled_fn: Tile2DFunc, tile_x: Int, tile_y: Int](end_x: Int, end_y: Int):
    for y in range(0, end_y, tile_y):
        for x in range(0, end_x, tile_x):
            tiled_fn[tile_x, tile_y](x, y)


fn matmul_tiled_parallelized(c: Matrix, a: Matrix, b: Matrix):
    @parameter
    fn calc_row(m: Int):
        @parameter
        fn calc_tile[tile_x: Int, tile_y: Int](x: Int, y: Int):
            for k in range(y, y + tile_y):

                @parameter
                fn dot[
                    nelts: Int,
                ](n: Int):
                    c.store[nelts](
                        m,
                        n + x,
                        c.load[nelts](m, n + x) + a[m, k] * b.load[nelts](k, n + x),
                    )

                vectorize[dot, nelts](tile_x)

        alias tile_size = 4
        tile[calc_tile, nelts * tile_size, tile_size](a.cols, b.cols)

    parallelize[calc_row](c.rows, c.rows)


fn matmul_tiled_unrolled_parallelized(C: Matrix, A: Matrix, B: Matrix):
    @parameter
    fn calc_row(m: Int):
        @parameter
        fn calc_tile[tile_x: Int, tile_y: Int](x: Int, y: Int):
            for k in range(y, y + tile_y):

                @parameter
                fn dot[
                    nelts: Int,
                ](n: Int):
                    C.store[nelts](
                        m,
                        n + x,
                        C.load[nelts](m, n + x) + A[m, k] * B.load[nelts](k, n + x),
                    )

                # Vectorize by nelts and unroll by tile_x/nelts
                # Here unroll factor is 4
                vectorize[dot, nelts, unroll_factor = tile_x // nelts](tile_x)

        alias tile_size = 4
        tile[calc_tile, nelts * tile_size, tile_size](A.cols, C.cols)

    parallelize[calc_row](C.rows, C.rows)


# Perform 2D tiling on the iteration space defined by end_x and end_y, parallelizing over y.


fn tile_parallel[
    tiled_fn: Tile2DFunc, tile_x: Int, tile_y: Int
](end_x: Int, end_y: Int):
    # Note: this assumes that ends are multiples of the tiles.
    @parameter
    fn row(yo: Int):
        var y = tile_y * yo
        for x in range(0, end_x, tile_x):
            tiled_fn[tile_x, tile_y](x, y)

    parallelize[row](end_y // tile_y, M)


from memory import stack_allocation


fn accumulate_registers(c: Matrix, a: Matrix, b: Matrix):
    alias tile_k = 8
    alias tile_k_unroll = 8
    alias tile_i = 32
    alias tile_j = nelts * 4

    @parameter
    fn calc_tile[tile_j: Int, tile_i: Int](jo: Int, io: Int):
        var accumulators = Matrix(
            tile_i, tile_j, stack_allocation[tile_i * tile_j, type]()
        )
        for ko in range(0, a.cols, tile_k * tile_k_unroll):
            for _ in range(tile_i):
                for i in range(tile_k):

                    @unroll
                    for k in range(tile_k_unroll):

                        @parameter
                        fn calc_tile_cols[nelts: Int](j: Int):
                            accumulators.store[nelts](
                                i,
                                j,
                                accumulators.load[nelts](i, j)
                                + a[io + i, ko + k] * a.load[nelts](ko + k, jo + j),
                            )

                        vectorize[
                            calc_tile_cols, nelts, unroll_factor = tile_j // nelts
                        ](tile_j)

        for i in range(tile_i):
            for j in range(tile_j):
                c[io + i, jo + j] = accumulators[i, j]

    tile_parallel[calc_tile, tile_j, tile_i](c.cols, c.rows)


alias M = 1024
alias N = M
alias K = M


@always_inline
fn bench[func: fn (Matrix, Matrix, Matrix) -> None](base_gflops: Float64):
    var c = Matrix(M, N)
    var a = Matrix.rand(M, K)
    var b = Matrix.rand(K, N)

    @always_inline
    @parameter
    fn test_fn():
        func(c, a, b)

    alias secs = benchmark.run[test_fn](max_runtime_secs=1).mean()

    a.data.free()
    b.data.free()
    c.data.free()
    alias gflops = ((2 * M * N * K) / secs) / 1e9
    var speedup: Float64 = gflops / base_gflops
    print("GFLOPS: ", gflops, " Speedup: ", speedup)


alias python = 0.002827808410133812


fn main():
    # bench[matmul_naive](python)
    # bench[matmul_vectorized_0](python)
    # bench[matmul_vectorized_1](python)
    # bench[matmul_parallelized](python)
    # bench[matmul_tiled_parallelized](python)
    # bench[matmul_tiled_unrolled_parallelized](python)
    bench[accumulate_registers](python)
