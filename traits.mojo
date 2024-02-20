# Without traits
@value
struct Duck:
    fn talk(self):
        print("Quack! Quack! Quack!")


@value
struct Cow:
    fn talk(self):
        print("Moo! Moo! Moo!")


fn make_it_talk(definetly_a_duck: Duck):
    definetly_a_duck.talk()


fn make_it_talk(not_a_duck: Cow):
    not_a_duck.talk()


trait CanTalk:
    fn talk(self):
        ...


@value
struct NewDuck(CanTalk):
    fn talk(self):
        print("Quack! Quack! Quack!")


@value
struct NewCow(CanTalk):
    fn talk(self):
        print("Moo! Moo! Moo!")


fn trait_make_it_talk[T: CanTalk](animal: T):
    animal.talk()


# Static Method traits
trait StaticMethod:
    @staticmethod
    fn do_stuff():
        ...


fn fun_with_traits[T: StaticMethod](thing: T):
    T.do_stuff()


# Trait Inheritance
trait Animal:
    fn make_sound(self):
        ...


trait Bird(Animal):
    fn fly(self):
        ...


trait Named:
    fn get_name(self) -> String:
        ...


trait NamedAnimal(Animal, Named):
    ...


@value
struct Dog(NamedAnimal):
    fn make_sound(self):
        print("Woof! Woof! Woof!")

    fn get_name(self) -> String:
        return "Dog"


trait DefaultConstructible:
    fn __init__(inout self):
        ...


trait MassProducible(DefaultConstructible, Movable):
    ...


fn factory[T: MassProducible]() -> T:
    return T()


struct Thing(MassProducible):
    var id: Int

    fn __init__(inout self):
        self.id = 0

    fn __moveinit__(inout self, owned existing: Self):
        self.id = existing.id


# Register passable and trivial


@register_passable
struct RegisterPassableType(DefaultConstructible):
    fn __init__() -> Self:
        return Self {}


fn main():
    make_it_talk(Duck())
    make_it_talk(Cow())
    trait_make_it_talk(NewDuck())
    trait_make_it_talk(NewCow())
    let dog = Dog()
    print(dog.get_name())
    let thing = factory[Thing]()
