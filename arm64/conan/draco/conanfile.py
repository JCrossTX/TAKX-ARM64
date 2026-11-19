from conans import ConanFile

class DracoConan(ConanFile):
    name = "draco"
    version = "1.5.7"
    description = "Google Draco mesh compression (static, PIC), built natively for ARM64 from the atak-civ draco tree"
    settings = "os", "compiler", "build_type", "arch"

    def package(self):
        root = "/home/kali/.cache/takx-native-pkgs/draco"
        self.copy("*", dst="include", src=root + "/include")
        self.copy("*", dst="lib", src=root + "/lib")

    def package_info(self):
        self.cpp_info.includedirs = ["include"]
        self.cpp_info.libdirs = ["lib"]
        self.cpp_info.libs = ["draco"]
