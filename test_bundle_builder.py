#!/usr/bin/env python3
"""Unit tests for bundle_builder module (.apks and .xapk creation)."""

import io
import json
import unittest
import zipfile

from bundle_builder import create_apks_bundle, create_xapk_bundle, create_splits_zip


class TestBundleBuilder(unittest.TestCase):

    def setUp(self):
        self.base_bytes = b"MOCK_BASE_APK_BYTES"
        self.splits = [
            ("config.arm64_v8a", b"MOCK_SPLIT_ARM64"),
            ("config.xxhdpi", b"MOCK_SPLIT_XXHDPI"),
            ("config.en", b"MOCK_SPLIT_EN"),
        ]
        self.pkg = "com.example.mockapp"
        self.version_code = 12345
        self.version_name = "2.1.0"
        self.title = "Mock App"

    def test_create_apks_bundle(self):
        apks_bytes = create_apks_bundle(
            self.base_bytes, self.splits, self.pkg, self.version_code
        )
        self.assertIsInstance(apks_bytes, bytes)
        with zipfile.ZipFile(io.BytesIO(apks_bytes)) as zf:
            names = zf.namelist()
            self.assertIn("splits/base-master.apk", names)
            self.assertIn("splits/base-config.arm64_v8a.apk", names)
            self.assertIn("toc.json", names)

            # Validate toc.json
            toc_content = json.loads(zf.read("toc.json").decode("utf-8"))
            self.assertIn("variant", toc_content)
            apk_set = toc_content["variant"][0]["apkSet"][0]
            descriptions = apk_set["apkDescription"]
            self.assertEqual(len(descriptions), 4)

    def test_create_xapk_bundle(self):
        xapk_bytes = create_xapk_bundle(
            self.base_bytes,
            self.splits,
            self.pkg,
            self.version_code,
            version_name=self.version_name,
            title=self.title,
            icon_data=b"PNG_DATA",
        )
        self.assertIsInstance(xapk_bytes, bytes)
        with zipfile.ZipFile(io.BytesIO(xapk_bytes)) as zf:
            names = zf.namelist()
            self.assertIn(f"{self.pkg}.apk", names)
            self.assertIn("config.arm64_v8a.apk", names)
            self.assertIn("manifest.json", names)
            self.assertIn("icon.png", names)

            # Validate manifest.json
            manifest = json.loads(zf.read("manifest.json").decode("utf-8"))
            self.assertEqual(manifest["package_name"], self.pkg)
            self.assertEqual(manifest["name"], self.title)
            self.assertEqual(manifest["version_code"], str(self.version_code))
            self.assertEqual(manifest["version_name"], self.version_name)
            self.assertEqual(len(manifest["split_apks"]), 4)

    def test_create_splits_zip(self):
        zip_bytes = create_splits_zip(
            self.base_bytes, self.splits, self.pkg, self.version_code
        )
        self.assertIsInstance(zip_bytes, bytes)
        with zipfile.ZipFile(io.BytesIO(zip_bytes)) as zf:
            names = zf.namelist()
            self.assertIn(f"{self.pkg}-{self.version_code}-base.apk", names)
            self.assertIn(f"{self.pkg}-{self.version_code}-config.arm64_v8a.apk", names)


if __name__ == "__main__":
    unittest.main()
