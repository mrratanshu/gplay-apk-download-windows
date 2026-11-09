"""
Android APK Bundle Builder (.apks and .xapk).

Packages split APKs (App Bundles) and asset packs into standard container
formats with 100% original Google Play signatures preserved:

  - .apks: Bundletool / SAI (Split APKs Installer) / Shizuku format with toc.json
  - .xapk: Standard APKPure / XAPK installer format with manifest.json
  - .zip:  Raw archive of base + split APKs
"""

import io
import json
import zipfile
from pathlib import Path


def create_apks_bundle(base_apk_data, splits_data, pkg_name, version_code, output_path=None):
    """
    Create a standard .apks archive from base and split APKs.
    Preserves original Google signatures.

    base_apk_data: bytes or file path
    splits_data: list of (split_name, bytes_or_path)
    pkg_name: package name string
    version_code: int or str
    output_path: optional str or Path. If None, returns bytes.
    """
    buf = io.BytesIO() if output_path is None else None
    target = output_path if output_path is not None else buf

    base_bytes = _to_bytes(base_apk_data)

    with zipfile.ZipFile(target, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
        # 1. Base APK
        zf.writestr('splits/base-master.apk', base_bytes)

        # 2. Split APKs
        apk_descriptions = [
            {'path': 'splits/base-master.apk', 'targeting': {}}
        ]

        for name, split_data in splits_data:
            s_bytes = _to_bytes(split_data)
            split_filename = f"splits/base-{name}.apk" if not name.endswith('.apk') else f"splits/{name}"
            zf.writestr(split_filename, s_bytes)

            targeting = {}
            if 'arm64' in name or 'arm64_v8a' in name:
                targeting = {'abi': {'value': [{'alias': 'ARM64_V8A'}]}}
            elif 'armeabi' in name or 'armv7' in name:
                targeting = {'abi': {'value': [{'alias': 'ARMEABI_V7A'}]}}
            elif 'x86_64' in name:
                targeting = {'abi': {'value': [{'alias': 'X86_64'}]}}
            elif 'x86' in name:
                targeting = {'abi': {'value': [{'alias': 'X86'}]}}

            apk_descriptions.append({
                'path': split_filename,
                'targeting': targeting
            })

        # 3. Bundletool toc.json
        toc = {
            'variant': [
                {
                    'targeting': {},
                    'apkSet': [
                        {
                            'moduleMetadata': {
                                'name': 'base',
                                'targeting': {},
                                'isInstant': False
                            },
                            'apkDescription': apk_descriptions
                        }
                    ]
                }
            ]
        }
        zf.writestr('toc.json', json.dumps(toc, indent=2))

    if output_path is None:
        return buf.getvalue()
    return str(output_path)


def create_xapk_bundle(base_apk_data, splits_data, pkg_name, version_code,
                       version_name="1.0", title="", icon_data=None, output_path=None):
    """
    Create a standard .xapk archive with manifest.json.
    Preserves original Google signatures.
    """
    buf = io.BytesIO() if output_path is None else None
    target = output_path if output_path is not None else buf

    base_bytes = _to_bytes(base_apk_data)
    base_filename = f"{pkg_name}.apk"

    with zipfile.ZipFile(target, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr(base_filename, base_bytes)

        split_apks_meta = [
            {'file': base_filename, 'id': 'base'}
        ]

        for name, split_data in splits_data:
            s_bytes = _to_bytes(split_data)
            split_filename = name if name.endswith('.apk') else f"{name}.apk"
            zf.writestr(split_filename, s_bytes)
            split_apks_meta.append({
                'file': split_filename,
                'id': name.replace('.apk', '')
            })

        if icon_data:
            zf.writestr('icon.png', _to_bytes(icon_data))

        manifest = {
            'xapk_version': 1,
            'package_name': pkg_name,
            'name': title or pkg_name,
            'version_code': str(version_code),
            'version_name': str(version_name),
            'min_sdk_version': '21',
            'target_sdk_version': '34',
            'permissions': [],
            'split_apks': split_apks_meta
        }
        zf.writestr('manifest.json', json.dumps(manifest, indent=2))

    if output_path is None:
        return buf.getvalue()
    return str(output_path)


def create_splits_zip(base_apk_data, splits_data, pkg_name, version_code, output_path=None):
    """
    Create a simple ZIP archive containing base and split APKs.
    """
    buf = io.BytesIO() if output_path is None else None
    target = output_path if output_path is not None else buf

    base_bytes = _to_bytes(base_apk_data)

    with zipfile.ZipFile(target, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr(f"{pkg_name}-{version_code}-base.apk", base_bytes)
        for name, split_data in splits_data:
            s_bytes = _to_bytes(split_data)
            split_filename = name if name.endswith('.apk') else f"{pkg_name}-{version_code}-{name}.apk"
            zf.writestr(split_filename, s_bytes)

    if output_path is None:
        return buf.getvalue()
    return str(output_path)


def _to_bytes(data):
    if isinstance(data, (bytes, bytearray)):
        return bytes(data)
    elif isinstance(data, (str, Path)):
        with open(data, 'rb') as f:
            return f.read()
    elif hasattr(data, 'read'):
        return data.read()
    raise TypeError(f"Unsupported data type for APK content: {type(data)}")
