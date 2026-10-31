"""Build an inspectable XML plugin model using only Python's standard library."""
from pathlib import Path
import xml.etree.ElementTree as ET


def build():
    root_dir = Path(__file__).resolve().parent
    root = ET.Element("roblox", {"version": "4"})
    script = ET.SubElement(root, "Item", {"class": "Script", "referent": "RBX0"})

    def properties(item, name, file):
        props = ET.SubElement(item, "Properties")
        ET.SubElement(props, "string", {"name": "Name"}).text = name
        ET.SubElement(props, "ProtectedString", {"name": "Source"}).text = (root_dir / "src" / file).read_text(encoding="utf-8")

    properties(script, "FlashInspect", "Plugin.server.luau")
    for index, name in enumerate(("Config", "Rules", "Scanner"), 1):
        module = ET.SubElement(script, "Item", {"class": "ModuleScript", "referent": f"RBX{index}"})
        properties(module, name, name + ".luau")
    ET.indent(root, space="  ")
    output = root_dir / "FlashInspect.rbxmx"
    # Writing bytes avoids Windows newline conversion in the XML serializer.
    output.write_bytes(ET.tostring(root, encoding="utf-8", xml_declaration=True))
    return output


if __name__ == "__main__":
    print(build())
