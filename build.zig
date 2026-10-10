const std = @import("std");

/// WARNING: Keep this in sync with ./CMakeLists.txt
/// ...or come up with a way to read files inside build.zig.
/// I wasn't finding an easy way to resolve a LazyPath to an absolute
/// path.
const LibFTDIVersion: struct {
    major: u32,
    minor: u32,
    package: []const u8,
    version_string: []const u8,
} = .{
    .major = 1,
    .minor = 5,
    .package = "libftdi1",
    .version_string = "1.5",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    //const static_lib = addLibFTDI(b, target, optimize, .static);
    const libftdi_shared = addLibFTDI(b, target, optimize, .dynamic);

    {
        const libftdi_dep = b.dependency("libftdi", .{});
        const libftdi_root = libftdi_dep.path(".");

        const findall_mod = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
        });

        findall_mod.addIncludePath(libftdi_dep.path("src"));
        findall_mod.addCSourceFiles(.{
            .root = libftdi_root,
            .files = &.{ "examples/find_all.c" },
        });
        findall_mod.linkLibrary(libftdi_shared);

        const findall_exe = b.addExecutable(.{
            .name = "findall_c",
            .root_module = findall_mod,
        });
        b.installArtifact(findall_exe);

        const run_findall = b.addRunArtifact(findall_exe);
        run_findall.addPassthruArgs();
        const run_findall_step = b.step("findall_c", "Run findall (C) example");
        run_findall_step.dependOn(&run_findall.step);
    }
}

pub fn addLibFTDI(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    linkage: std.lang.LinkMode,
) *std.Build.Step.Compile {
    const libftdi_dep = b.dependency("libftdi", .{});

    const libftdi_c_files = [_][]const u8{
        "src/ftdi.c",
        "src/ftdi_stream.c",
    };

    const libusb_dep = b.dependency("libusb", .{
        .target = target,
        .optimize = optimize,
    });

    const module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = false,
    });

    module.linkLibrary(libusb_dep.artifact("usb"));
    module.addIncludePath(libusb_dep.path("libusb"));

    const lib = b.addLibrary(.{
        .name = switch (linkage) {
            .static => "libftdi-static",
            .dynamic => "libftdi-shared",
        },
        .root_module = module,
        .linkage = linkage,
    });

    //module.addIncludePath(libftdi_dep.path("src"));

    b.dependOnFileContents(libftdi_dep.path("CMakeLists.txt"));

    const ftdi_version_i_h = b.addConfigHeader(.{ .style = .{
        .autoconf_at = libftdi_dep.path("src/ftdi_version_i.h.in"),
    } }, .{
        .MAJOR_VERSION = LibFTDIVersion.major,
        .MINOR_VERSION = LibFTDIVersion.minor,
        .VERSION_STRING = LibFTDIVersion.version_string,
        // normally the `git describe` output of the repo
        .SNAPSHOT_VERSION = "unknown",
    });
    module.addConfigHeader(ftdi_version_i_h);

    module.addCSourceFiles(.{
        .root = libftdi_dep.path("."),
        .files = &libftdi_c_files,
    });

    lib.installHeader(libftdi_dep.path("src/ftdi.h"), "libftdi1/ftdi.h");
    b.installArtifact(lib);
    return lib;
}
