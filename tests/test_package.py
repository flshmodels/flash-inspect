from pathlib import Path
import unittest
import xml.etree.ElementTree as ET


class PackageTests(unittest.TestCase):
    def test_model_contains_exact_current_sources(self):
        root = Path(__file__).resolve().parents[1]
        document = ET.parse(root / "FlashInspect.rbxmx").getroot()
        self.assertEqual(document.tag, "roblox")
        items = document.findall(".//Item")
        self.assertEqual(len(items), 4)
        expected = {"FlashInspect": "Plugin.server.luau", "Config": "Config.luau", "Rules": "Rules.luau", "Scanner": "Scanner.luau"}
        for item in items:
            props = item.find("Properties")
            name = props.find("string[@name='Name']").text
            source = props.find("ProtectedString[@name='Source']").text
            self.assertEqual(source, (root / "src" / expected.pop(name)).read_text(encoding="utf-8"))
        self.assertFalse(expected)


if __name__ == "__main__":
    unittest.main()
