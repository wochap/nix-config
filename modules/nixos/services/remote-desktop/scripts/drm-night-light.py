# drm-night-light
#
# Sets a color temperature on every CRTC through the DRM CTM property, with
# hyprsunset's Kelvin-to-RGB formula. Meant for a bare TTY right before a
# KMS client (Moonlight on eglfs) takes the display: with no compositor holding
# DRM master, opening the card makes this process master. The CTM stays on the
# CRTC after exit, until the next client changes it.
#
#   drm-night-light <kelvin>    6500 or more clears the CTM

import ctypes
import glob
import math
import os
import sys

libdrm = ctypes.CDLL(os.environ["DRM_NIGHT_LIGHT_LIBDRM"])


class DrmModeRes(ctypes.Structure):
    _fields_ = [
        ("count_fbs", ctypes.c_int),
        ("fbs", ctypes.POINTER(ctypes.c_uint32)),
        ("count_crtcs", ctypes.c_int),
        ("crtcs", ctypes.POINTER(ctypes.c_uint32)),
        ("count_connectors", ctypes.c_int),
        ("connectors", ctypes.POINTER(ctypes.c_uint32)),
        ("count_encoders", ctypes.c_int),
        ("encoders", ctypes.POINTER(ctypes.c_uint32)),
        ("min_width", ctypes.c_uint32),
        ("max_width", ctypes.c_uint32),
        ("min_height", ctypes.c_uint32),
        ("max_height", ctypes.c_uint32),
    ]


class DrmModeObjectProperties(ctypes.Structure):
    _fields_ = [
        ("count_props", ctypes.c_uint32),
        ("props", ctypes.POINTER(ctypes.c_uint32)),
        ("prop_values", ctypes.POINTER(ctypes.c_uint64)),
    ]


class DrmModePropertyRes(ctypes.Structure):
    _fields_ = [
        ("prop_id", ctypes.c_uint32),
        ("flags", ctypes.c_uint32),
        ("name", ctypes.c_char * 32),
        ("count_values", ctypes.c_int),
        ("values", ctypes.POINTER(ctypes.c_uint64)),
        ("count_enums", ctypes.c_int),
        ("enums", ctypes.c_void_p),
        ("count_blobs", ctypes.c_int),
        ("blob_ids", ctypes.POINTER(ctypes.c_uint32)),
    ]


DRM_MODE_OBJECT_CRTC = 0xCCCCCCCC

libdrm.drmModeGetResources.restype = ctypes.POINTER(DrmModeRes)
libdrm.drmModeObjectGetProperties.restype = ctypes.POINTER(DrmModeObjectProperties)
libdrm.drmModeObjectGetProperties.argtypes = [ctypes.c_int, ctypes.c_uint32, ctypes.c_uint32]
libdrm.drmModeGetProperty.restype = ctypes.POINTER(DrmModePropertyRes)
libdrm.drmModeGetProperty.argtypes = [ctypes.c_int, ctypes.c_uint32]
libdrm.drmModeCreatePropertyBlob.argtypes = [
    ctypes.c_int,
    ctypes.c_void_p,
    ctypes.c_size_t,
    ctypes.POINTER(ctypes.c_uint32),
]
libdrm.drmModeObjectSetProperty.argtypes = [
    ctypes.c_int,
    ctypes.c_uint32,
    ctypes.c_uint32,
    ctypes.c_uint32,
    ctypes.c_uint64,
]


def kelvin_to_rgb(kelvin):
    # same approximation as hyprsunset's matrixForKelvin
    temp = kelvin / 100
    if temp <= 66:
        r = 255.0
        g = min(max(99.4708025861 * math.log(temp) - 161.1195681661, 0.0), 255.0)
        if temp <= 19:
            b = 0.0
        else:
            b = min(max(math.log(temp - 10) * 138.5177312231 - 305.0447927307, 0.0), 255.0)
    else:
        r = min(max(329.698727446 * math.pow(temp - 60, -0.1332047592), 0.0), 255.0)
        g = min(max(288.1221695283 * math.pow(temp - 60, -0.0755148492), 0.0), 255.0)
        b = 255.0
    return r / 255, g / 255, b / 255


def s31_32(value):
    # DRM CTM entries are sign-magnitude S31.32 fixed point
    magnitude = int(round(abs(value) * (1 << 32)))
    return magnitude | (1 << 63) if value < 0 else magnitude


def crtc_ctm_property(fd, crtc):
    props = libdrm.drmModeObjectGetProperties(fd, crtc, DRM_MODE_OBJECT_CRTC)
    if not props:
        return None
    try:
        for i in range(props.contents.count_props):
            prop = libdrm.drmModeGetProperty(fd, props.contents.props[i])
            if not prop:
                continue
            name = prop.contents.name
            prop_id = prop.contents.prop_id
            libdrm.drmModeFreeProperty(prop)
            if name == b"CTM":
                return prop_id
    finally:
        libdrm.drmModeFreeObjectProperties(props)
    return None


def main():
    if len(sys.argv) != 2 or not sys.argv[1].isdigit():
        sys.exit("usage: drm-night-light <kelvin>")
    kelvin = int(sys.argv[1])

    blob_data = None
    if kelvin < 6500:
        r, g, b = kelvin_to_rgb(kelvin)
        matrix = [r, 0, 0, 0, g, 0, 0, 0, b]
        blob_data = (ctypes.c_uint64 * 9)(*[s31_32(v) for v in matrix])

    applied = 0
    for card in sorted(glob.glob("/dev/dri/card[0-9]*")):
        try:
            fd = os.open(card, os.O_RDWR | os.O_CLOEXEC)
        except OSError:
            continue
        try:
            res = libdrm.drmModeGetResources(fd)
            if not res:
                continue
            crtcs = [res.contents.crtcs[i] for i in range(res.contents.count_crtcs)]
            libdrm.drmModeFreeResources(res)

            blob_id = ctypes.c_uint32(0)
            if blob_data is not None:
                if libdrm.drmModeCreatePropertyBlob(fd, blob_data, ctypes.sizeof(blob_data), ctypes.byref(blob_id)):
                    print(f"drm-night-light: {card}: cannot create CTM blob (DRM master held elsewhere?)", file=sys.stderr)
                    continue

            for crtc in crtcs:
                prop_id = crtc_ctm_property(fd, crtc)
                if prop_id is None:
                    continue
                if libdrm.drmModeObjectSetProperty(fd, crtc, DRM_MODE_OBJECT_CRTC, prop_id, blob_id.value) == 0:
                    applied += 1
                else:
                    print(f"drm-night-light: {card}: cannot set CTM on CRTC {crtc}", file=sys.stderr)
        finally:
            os.close(fd)

    if applied == 0:
        sys.exit(1)


main()
