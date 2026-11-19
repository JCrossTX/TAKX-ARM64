from conans import ConanFile

class LibLASConan(ConanFile):
    name = "libLAS"
    version = "1.8.2f"
    description = "libLAS 1.8.2 (TAK-modified) with static LASzip, built natively for ARM64"
    settings = "os", "compiler", "build_type", "arch"

    def package(self):
        root = "/home/kali/.cache/takx-native-pkgs/libLAS"
        self.copy("*", dst="include", src=root + "/include")
        self.copy("*", dst="lib", src=root + "/lib")
        self.copy("*", dst="include", src="/home/kali/.cache/takx-native-pkgs/LASzip/include")

    def package_info(self):
        self.cpp_info.includedirs = ["include"]
        self.cpp_info.libdirs = ["lib"]
        self.cpp_info.libs = ["las", "las_c"]
