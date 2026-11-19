from conans import ConanFile

class KhronosConan(ConanFile):
    name = "khronos"
    version = "1.0"
    description = "Khronos OpenGL ES / EGL / KHR registry headers (from the atak-civ khronos tree)"
    settings = None

    def package(self):
        root = "/home/kali/.cache/atak-civ-src/khronos"
        self.copy("*.h", dst="include/GL", src=root + "/OpenGL/api/GL")
        self.copy("*.h", dst="include/GLES", src=root + "/OpenGL/api/GLES")
        self.copy("*.h", dst="include/GLES2", src=root + "/OpenGL/api/GLES2")
        self.copy("*.h", dst="include/GLES3", src=root + "/OpenGL/api/GLES3")
        self.copy("*.h", dst="include/EGL", src=root + "/EGL/api/EGL")
        self.copy("*.h", dst="include/KHR", src=root + "/EGL/api/KHR")

    def package_info(self):
        self.cpp_info.includedirs = ["include"]
