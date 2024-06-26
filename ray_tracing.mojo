from image import Image, Vec3f, render
from math import tan, acos, sqrt, max, pow
from algorithm import parallelize
from math.limit import inf
from collections.list import List


@register_passable("trivial")
struct Material:
    var color: Vec3f
    var albedo: Vec3f
    var specular_component: Float32

    fn __init__(color: Vec3f) -> Material:
        return Material {color: color, albedo: Vec3f(0, 0, 0), specular_component: 0}

    fn __init__(color: Vec3f, albedo: Vec3f, specular_component: Float32) -> Material:
        return Material {
            color: color, albedo: albedo, specular_component: specular_component
        }


alias W = 1024
alias H = 768
alias bg_color = Vec3f(0.02, 0.02, 0.02)
var shiny_yellow = Material(Vec3f(0.95, 0.95, 0.4), Vec3f(0.7, 0.6, 0), 30.0)
var green_rubber = Material(Vec3f(0.3, 0.7, 0.3), Vec3f(0.9, 0.1, 0), 1.0)


@register_passable("trivial")
struct Sphere(CollectionElement):
    var center: Vec3f
    var radius: Float32
    var material: Material

    fn __init__(c: Vec3f, r: Float32, material: Material) -> Self:
        return Sphere {center: c, radius: r, material: material}

    @always_inline
    fn intersects(self, orig: Vec3f, dir: Vec3f, inout dist: Float32) -> Bool:
        """This method returns True if a given ray intersects this sphere.
        And if it does, it writes in the `dist` parameter the distance to the
        origin of the ray.
        """
        var L = orig - self.center
        var a = dir @ dir
        var b = 2 * (dir @ L)
        var c = L @ L - self.radius * self.radius
        var discriminant = b * b - 4 * a * c
        if discriminant < 0:
            return False
        if discriminant == 0:
            dist = -b / 2 * a
            return True
        var q = -0.5 * (b + sqrt(discriminant)) if b > 0 else -0.5 * (
            b - sqrt(discriminant)
        )
        var t0 = q / a
        var t1 = c / q
        if t0 > t1:
            t0 = t1
        if t0 < 0:
            t0 = t1
            if t0 < 0:
                return False

        dist = t0
        return True


fn cast_ray(orig: Vec3f, dir: Vec3f, sphere: Sphere) -> Vec3f:
    var dist: Float32 = 0
    if not sphere.intersects(orig, dir, dist):
        return bg_color

    return sphere.material.color


fn create_image_with_sphere(sphere: Sphere, height: Int, width: Int) -> Image:
    var image = Image(height, width)

    @parameter
    fn _process_row(row: Int):
        var y = -((2.0 * row + 1) / height - 1)
        for col in range(width):
            var x = ((2.0 * col + 1) / width - 1) * width / height
            var dir = Vec3f(x, y, -1).normalize()
            image.set(row, col, cast_ray(Vec3f.zero(), dir, sphere))

    parallelize[_process_row](height)

    return image


fn scene_intersect(
    orig: Vec3f,
    dir: Vec3f,
    spheres: List[Sphere],
    background: Material,
) -> Material:
    var spheres_dist = inf[DType.float32]()
    var material = background

    for i in range(spheres.size):
        var dist = inf[DType.float32]()
        if spheres[i].intersects(orig, dir, dist) and dist < spheres_dist:
            spheres_dist = dist
            material = spheres[i].material

    return material


fn cast_ray(orig: Vec3f, dir: Vec3f, spheres: List[Sphere]) -> Material:
    alias background = Material(Vec3f(0.02, 0.02, 0.02))
    return scene_intersect(orig, dir, spheres, background)


fn create_image_with_spheres(spheres: List[Sphere], height: Int, width: Int) -> Image:
    var image = Image(height, width)

    @parameter
    fn _process_row(row: Int):
        var y = -((2.0 * row + 1) / height - 1)
        for col in range(width):
            var x = ((2.0 * col + 1) / width - 1) * width / height
            var dir = Vec3f(x, y, -1).normalize()
            image.set(row, col, cast_ray(Vec3f.zero(), dir, spheres).color)

    parallelize[_process_row](height)

    return image


@register_passable("trivial")
struct Light(CollectionElement):
    var position: Vec3f
    var intensity: Float32

    fn __init__(p: Vec3f, i: Float32) -> Self:
        return Light {position: p, intensity: i}


fn scene_intersect(
    orig: Vec3f,
    dir: Vec3f,
    spheres: List[Sphere],
    inout material: Material,
    inout hit: Vec3f,
    inout N: Vec3f,
) -> Bool:
    var spheres_dist = inf[DType.float32]()

    for i in range(0, spheres.size):
        var dist: Float32 = 0
        if spheres[i].intersects(orig, dir, dist) and dist < spheres_dist:
            spheres_dist = dist
            hit = orig + dir * dist
            N = (hit - spheres[i].center).normalize()
            material = spheres[i].material

    return (spheres_dist != inf[DType.float32]()).__bool__()


# fn cast_ray(
#     orig: Vec3f,
#     dir: Vec3f,
#     spheres: List[Sphere],
#     lights: List[Light],
# ) -> Material:
#     var point = Vec3f.zero()
#     var material = Material(Vec3f.zero())
#     var N = Vec3f.zero()
#     if not scene_intersect(orig, dir, spheres, material, point, N):
#         return bg_color

#     var diffuse_light_intensity: Float32 = 0
#     for i in range(lights.size):
#         alias light_dir = (lights[i].position - point).normalize()
#         diffuse_light_intensity += lights[i].intensity * max(0, light_dir @ N)

#     return material.color * diffuse_light_intensity


fn create_image_with_spheres_and_lights(
    spheres: List[Sphere],
    lights: List[Light],
    height: Int,
    width: Int,
) -> Image:
    var image = Image(height, width)

    @parameter
    fn _process_row(row: Int):
        var y = -((2.0 * row + 1) / height - 1)
        for col in range(width):
            var x = ((2.0 * col + 1) / width - 1) * width / height
            var dir = Vec3f(x, y, -1).normalize()
            image.set(row, col, cast_ray(Vec3f.zero(), dir, spheres, lights).color)

    parallelize[_process_row](height)

    return image


fn reflect(I: Vec3f, N: Vec3f) -> Vec3f:
    return I - N * (I @ N) * 2.0


fn cast_ray(
    orig: Vec3f,
    dir: Vec3f,
    spheres: List[Sphere],
    lights: List[Light],
) -> Material:
    var point = Vec3f.zero()
    var material = Material(Vec3f.zero())
    var N = Vec3f.zero()
    if not scene_intersect(orig, dir, spheres, material, point, N):
        return bg_color

    var diffuse_light_intensity: Float32 = 0
    var specular_light_intensity: Float32 = 0
    for i in range(lights.size):
        var light_dir = (lights[i].position - point).normalize()
        diffuse_light_intensity += lights[i].intensity * max(0, light_dir @ N)
        specular_light_intensity += (
            pow(
                max(0.0, -reflect(-light_dir, N) @ dir),
                material.specular_component,
            )
            * lights[i].intensity
        )

    var result = material.color * diffuse_light_intensity * material.albedo.data[
        0
    ] + Vec3f(1.0, 1.0, 1.0) * specular_light_intensity * material.albedo.data[1]
    var result_max = max(result[0], max(result[1], result[2]))
    # Cap the resulting vector
    if result_max > 1:
        return result * (1.0 / result_max)
    return result


fn create_image_with_spheres_and_specular_lights(
    spheres: List[Sphere],
    lights: List[Light],
    height: Int,
    width: Int,
) -> Image:
    var image = Image(height, width)

    @parameter
    fn _process_row(row: Int):
        var y = -((2.0 * row + 1) / height - 1)
        for col in range(width):
            var x = ((2.0 * col + 1) / width - 1) * width / height
            var dir = Vec3f(x, y, -1).normalize()
            image.set(row, col, cast_ray(Vec3f.zero(), dir, spheres, lights).color)

    parallelize[_process_row](height)

    return image


fn main() raises:
    render(create_image_with_sphere(Sphere(Vec3f(-3, 0, -16), 2, shiny_yellow), H, W))

    # var spheres = List[Sphere]()
    # spheres.push_back(Sphere(Vec3f(-3, 0, -16), 2, shiny_yellow))
    # spheres.push_back(Sphere(Vec3f(-1.0, -1.5, -12), 1.8, green_rubber))
    # spheres.push_back(Sphere(Vec3f(1.5, -0.5, -18), 3, green_rubber))
    # spheres.push_back(Sphere(Vec3f(7, 5, -18), 4, shiny_yellow))

    # # _ = render(create_image_with_spheres(spheres, H, W))

    # var lights = List[Light]()
    # lights.push_back(Light(Vec3f(-20, 20, 20), 1.0))
    # lights.push_back(Light(Vec3f(20, -20, 20), 0.5))

    # # _ = render(create_image_with_spheres_and_lights(spheres, lights, H, W))

    # _ = render(create_image_with_spheres_and_specular_lights(spheres, lights, H, W))
