from conans import ConanFile

class GlesStubConan(ConanFile):
    name = "GLES-stub"
    version = "2.0.0"
    description = "GLESv2-over-desktop-GL shim for the Java render context (ARM64 binary from gles-jogl-c-1.0.3.jar) plus Khronos headers"
    settings = "os", "arch"

    def package(self):
        root = "/home/kali/.cache/atak-civ-src/khronos"
        self.copy("*.h", dst="include/GLES2", src=root + "/OpenGL/api/GLES2")
        self.copy("*.h", dst="include/GLES3", src=root + "/OpenGL/api/GLES3")
        self.copy("*.h", dst="include/KHR", src=root + "/EGL/api/KHR")
        self.copy("libGLESv2.so", dst="lib", src="/home/kali/.cache/takx-conan-pkgs/gles-stub/lib")

    def package_info(self):
        self.cpp_info.includedirs = ["include"]
        self.cpp_info.libdirs = ["lib"]
        self.cpp_info.libs = ["GLESv2"]
