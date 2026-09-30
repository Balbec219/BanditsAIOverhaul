"""Print selected public methods from installed Project Zomboid class files."""
import struct
import zipfile

JAR = r"C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\projectzomboid.jar"
CLASSES = (
    "zombie/characters/IsoSurvivor.class",
    "zombie/characters/IsoLivingCharacter.class",
    "zombie/characters/IsoGameCharacter.class",
    "zombie/characters/SurvivorDesc.class",
    "zombie/characters/SurvivorFactory.class",
    "zombie/iso/IsoMovingObject.class",
)


def inspect(data):
    offset = 8

    def u1():
        nonlocal offset
        value = data[offset]
        offset += 1
        return value

    def u2():
        nonlocal offset
        value = struct.unpack_from(">H", data, offset)[0]
        offset += 2
        return value

    def u4():
        nonlocal offset
        value = struct.unpack_from(">I", data, offset)[0]
        offset += 4
        return value

    pool = {}
    count = u2()
    index = 1
    while index < count:
        tag = u1()
        if tag == 1:
            length = u2()
            pool[index] = data[offset : offset + length].decode("utf-8", "replace")
            offset += length
        elif tag in (3, 4):
            offset += 4
        elif tag in (5, 6):
            offset += 8
            index += 1
        elif tag in (7, 8, 16, 19, 20):
            offset += 2
        elif tag in (9, 10, 11, 12, 17, 18):
            offset += 4
        elif tag == 15:
            offset += 3
        else:
            raise ValueError(f"Unknown constant-pool tag {tag}")
        index += 1

    offset += 6
    interface_count = u2()
    offset += 2 * interface_count

    def skip_attributes():
        nonlocal offset
        for _ in range(u2()):
            u2()
            length = u4()
            offset += length

    for _ in range(u2()):
        offset += 6
        skip_attributes()

    methods = []
    for _ in range(u2()):
        flags = u2()
        name = pool[u2()]
        descriptor = pool[u2()]
        skip_attributes()
        if flags & 1:
            methods.append((name, descriptor, flags))
    return methods


with zipfile.ZipFile(JAR) as archive:
    for class_name in CLASSES:
        print(f"\n{class_name}")
        for name, descriptor, flags in inspect(archive.read(class_name)):
            if name == "<init>" or any(part in name.lower() for part in (
                "world", "descriptor", "female", "survivor", "update", "path", "remove",
                "create", "instance", "cell", "current", "square"
            )):
                print(name, descriptor, hex(flags))
