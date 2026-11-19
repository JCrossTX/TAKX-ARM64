from conans import ConanFile

class LASzipConan(ConanFile):
    name = "LASzip"
    version = "3.4.3c"
    description = "LASzip 3.4.3 (TAK-modified), built natively for ARM64; static archive assembled from the PIC objects"
    settings = "os", "compiler", "build_type", "arch"

    def package(self):
        root = "/home/kali/.cache/takx-native-pkgs/LASzip"
        self.copy("*", dst="include", src=root + "/include")
        self.copy("*", dst="lib", src=root + "/lib")

    def package_info(self):
        self.cpp_info.includedirs = ["include"]
        self.cpp_info.libdirs = ["lib"]
        self.cpp_info.libs = ["laszip"]
