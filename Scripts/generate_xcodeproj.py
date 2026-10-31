#!/usr/bin/env python3
import os
import hashlib

def uid(name):
    # Deterministic 24-char hex string from name
    return hashlib.md5(name.encode('utf-8')).hexdigest()[:24].upper()

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(base_dir)

    sources = []
    for root, dirs, files in os.walk("Sources"):
        for f in files:
            if f.endswith(".swift") and "TestRunner" not in root:
                rel = os.path.relpath(os.path.join(root, f), base_dir)
                sources.append(rel)

    resources = ["Resources/AppIcon.icns", "Resources/Info.plist"]

    # IDs
    proj_id = uid("HardcoreAlarm_Project")
    target_id = uid("HardcoreAlarm_Target")
    main_group_id = uid("HardcoreAlarm_MainGroup")
    sources_group_id = uid("HardcoreAlarm_SourcesGroup")
    resources_group_id = uid("HardcoreAlarm_ResourcesGroup")
    products_group_id = uid("HardcoreAlarm_ProductsGroup")
    product_ref_id = uid("HardcoreAlarm_ProductRef")

    sources_build_phase_id = uid("HardcoreAlarm_SourcesBuildPhase")
    resources_build_phase_id = uid("HardcoreAlarm_ResourcesBuildPhase")
    frameworks_build_phase_id = uid("HardcoreAlarm_FrameworksBuildPhase")

    proj_cfg_list_id = uid("HardcoreAlarm_ProjCfgList")
    proj_debug_cfg_id = uid("HardcoreAlarm_ProjDebugCfg")
    proj_release_cfg_id = uid("HardcoreAlarm_ProjReleaseCfg")

    target_cfg_list_id = uid("HardcoreAlarm_TargetCfgList")
    target_debug_cfg_id = uid("HardcoreAlarm_TargetDebugCfg")
    target_release_cfg_id = uid("HardcoreAlarm_TargetReleaseCfg")

    file_refs = {}
    build_files = {}

    for src in sources:
        f_id = uid("FILEREF_" + src)
        b_id = uid("BUILDFILE_" + src)
        file_refs[src] = (f_id, os.path.basename(src), src)
        build_files[src] = (b_id, f_id, os.path.basename(src))

    for res in resources:
        f_id = uid("FILEREF_" + res)
        b_id = uid("BUILDFILE_" + res)
        file_refs[res] = (f_id, os.path.basename(res), res)
        build_files[res] = (b_id, f_id, os.path.basename(res))

    lines = [
        "// !$*UTF8*$!",
        "{",
        "\tarchiveVersion = 1;",
        "\tclasses = {",
        "\t};",
        "\tobjectVersion = 56;",
        "\tobjects = {",
        "",
        "/* Begin PBXBuildFile section */"
    ]

    for src in sources:
        b_id, f_id, name = build_files[src]
        lines.append(f"\t\t{b_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {f_id} /* {name} */; }};")

    for res in resources:
        b_id, f_id, name = build_files[res]
        if name.endswith(".icns"):
            lines.append(f"\t\t{b_id} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {f_id} /* {name} */; }};")

    lines.extend([
        "/* End PBXBuildFile section */",
        "",
        "/* Begin PBXFileReference section */",
        f"\t\t{product_ref_id} /* HardcoreAlarm.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = HardcoreAlarm.app; sourceTree = BUILT_PRODUCTS_DIR; }};"
    ])

    for path, (f_id, name, rel) in file_refs.items():
        ext = os.path.splitext(name)[1]
        file_type = "sourcecode.swift" if ext == ".swift" else ("image.icns" if ext == ".icns" else "text.plist.xml")
        lines.append(f"\t\t{f_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = \"{rel}\"; sourceTree = SOURCE_ROOT; }};")

    lines.extend([
        "/* End PBXFileReference section */",
        "",
        "/* Begin PBXFrameworksBuildPhase section */",
        f"\t\t{frameworks_build_phase_id} /* Frameworks */ = {{",
        "\t\t\tisa = PBXFrameworksBuildPhase;",
        "\t\t\tbuildActionMask = 2147483647;",
        "\t\t\tfiles = (",
        "\t\t\t);",
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
        "\t\t};",
        "/* End PBXFrameworksBuildPhase section */",
        "",
        "/* Begin PBXGroup section */",
        f"\t\t{main_group_id} = {{",
        "\t\t\tisa = PBXGroup;",
        "\t\t\tchildren = (",
        f"\t\t\t\t{sources_group_id} /* Sources */,",
        f"\t\t\t\t{resources_group_id} /* Resources */,",
        f"\t\t\t\t{products_group_id} /* Products */,",
        "\t\t\t);",
        "\t\t\tsourceTree = \"<group>\";",
        "\t\t};",
        f"\t\t{products_group_id} /* Products */ = {{",
        "\t\t\tisa = PBXGroup;",
        "\t\t\tchildren = (",
        f"\t\t\t\t{product_ref_id} /* HardcoreAlarm.app */,",
        "\t\t\t);",
        "\t\t\tname = Products;",
        "\t\t\tsourceTree = \"<group>\";",
        "\t\t};",
        f"\t\t{sources_group_id} /* Sources */ = {{",
        "\t\t\tisa = PBXGroup;",
        "\t\t\tchildren = ("
    ])

    for src in sorted(sources):
        f_id = file_refs[src][0]
        name = file_refs[src][1]
        lines.append(f"\t\t\t\t{f_id} /* {name} */,")

    lines.extend([
        "\t\t\t);",
        "\t\t\tname = Sources;",
        "\t\t\tsourceTree = \"<group>\";",
        "\t\t};",
        f"\t\t{resources_group_id} /* Resources */ = {{",
        "\t\t\tisa = PBXGroup;",
        "\t\t\tchildren = ("
    ])

    for res in sorted(resources):
        f_id = file_refs[res][0]
        name = file_refs[res][1]
        lines.append(f"\t\t\t\t{f_id} /* {name} */,")

    lines.extend([
        "\t\t\t);",
        "\t\t\tname = Resources;",
        "\t\t\tsourceTree = \"<group>\";",
        "\t\t};",
        "/* End PBXGroup section */",
        "",
        "/* Begin PBXNativeTarget section */",
        f"\t\t{target_id} /* HardcoreAlarm */ = {{",
        "\t\t\tisa = PBXNativeTarget;",
        f"\t\t\tbuildConfigurationList = {target_cfg_list_id} /* Build configuration list for PBXNativeTarget \"HardcoreAlarm\" */;",
        "\t\t\tbuildPhases = (",
        f"\t\t\t\t{sources_build_phase_id} /* Sources */,",
        f"\t\t\t\t{frameworks_build_phase_id} /* Frameworks */,",
        f"\t\t\t\t{resources_build_phase_id} /* Resources */,",
        "\t\t\t);",
        "\t\t\tbuildRules = (",
        "\t\t\t);",
        "\t\t\tdependencies = (",
        "\t\t\t);",
        "\t\t\tname = HardcoreAlarm;",
        "\t\t\tproductName = HardcoreAlarm;",
        f"\t\t\tproductReference = {product_ref_id} /* HardcoreAlarm.app */;",
        "\t\t\tproductType = \"com.apple.product-type.application\";",
        "\t\t};",
        "/* End PBXNativeTarget section */",
        "",
        "/* Begin PBXProject section */",
        f"\t\t{proj_id} /* Project object */ = {{",
        "\t\t\tisa = PBXProject;",
        "\t\t\tattributes = {",
        "\t\t\t\tBuildIndependentTargetsInParallel = 1;",
        "\t\t\t\tLastUpgradeCheck = 1500;",
        "\t\t\t};",
        f"\t\t\tbuildConfigurationList = {proj_cfg_list_id} /* Build configuration list for PBXProject \"HardcoreAlarm\" */;",
        "\t\t\tcompatibilityVersion = \"Xcode 14.0\";",
        "\t\t\tdevelopmentRegion = en;",
        "\t\t\thasScannedForEncodings = 0;",
        "\t\t\tknownRegions = (",
        "\t\t\t\ten,",
        "\t\t\t\tBase,",
        "\t\t\t);",
        f"\t\t\tmainGroup = {main_group_id};",
        f"\t\t\tproductRefGroup = {products_group_id} /* Products */;",
        "\t\t\tprojectDirPath = \"\";",
        "\t\t\tprojectRoot = \"\";",
        "\t\t\ttargets = (",
        f"\t\t\t\t{target_id} /* HardcoreAlarm */,",
        "\t\t\t);",
        "\t\t};",
        "/* End PBXProject section */",
        "",
        "/* Begin PBXResourcesBuildPhase section */",
        f"\t\t{resources_build_phase_id} /* Resources */ = {{",
        "\t\t\tisa = PBXResourcesBuildPhase;",
        "\t\t\tbuildActionMask = 2147483647;",
        "\t\t\tfiles = ("
    ])

    for res in sorted(resources):
        if res.endswith(".icns"):
            b_id = build_files[res][0]
            name = build_files[res][2]
            lines.append(f"\t\t\t\t{b_id} /* {name} in Resources */,")

    lines.extend([
        "\t\t\t);",
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
        "\t\t};",
        "/* End PBXResourcesBuildPhase section */",
        "",
        "/* Begin PBXSourcesBuildPhase section */",
        f"\t\t{sources_build_phase_id} /* Sources */ = {{",
        "\t\t\tisa = PBXSourcesBuildPhase;",
        "\t\t\tbuildActionMask = 2147483647;",
        "\t\t\tfiles = ("
    ])

    for src in sorted(sources):
        b_id = build_files[src][0]
        name = build_files[src][2]
        lines.append(f"\t\t\t\t{b_id} /* {name} in Sources */,")

    lines.extend([
        "\t\t\t);",
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
        "\t\t};",
        "/* End PBXSourcesBuildPhase section */",
        "",
        "/* Begin XCBuildConfiguration section */",
        f"\t\t{proj_debug_cfg_id} /* Debug */ = {{",
        "\t\t\tisa = XCBuildConfiguration;",
        "\t\t\tbuildSettings = {",
        "\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;",
        "\t\t\t\tCLANG_ANALYZER_NONNULL = YES;",
        "\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";",
        "\t\t\t\tCLANG_ENABLE_MODULES = YES;",
        "\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;",
        "\t\t\t\tCOPY_PHASE_STRIP = NO;",
        "\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;",
        "\t\t\t\tENABLE_TESTABILITY = YES;",
        "\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;",
        "\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;",
        "\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (",
        "\t\t\t\t\t\"DEBUG=1\",",
        "\t\t\t\t\t\"$(inherited)\",",
        "\t\t\t\t);",
        "\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;",
        "\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;",
        "\t\t\t\tONLY_ACTIVE_ARCH = YES;",
        "\t\t\t\tSDKROOT = macosx;",
        "\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;",
        "\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";",
        "\t\t\t\tSWIFT_VERSION = 6.0;",
        "\t\t\t};",
        "\t\t\tname = Debug;",
        "\t\t};",
        f"\t\t{proj_release_cfg_id} /* Release */ = {{",
        "\t\t\tisa = XCBuildConfiguration;",
        "\t\t\tbuildSettings = {",
        "\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;",
        "\t\t\t\tCLANG_ANALYZER_NONNULL = YES;",
        "\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";",
        "\t\t\t\tCLANG_ENABLE_MODULES = YES;",
        "\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;",
        "\t\t\t\tCOPY_PHASE_STRIP = NO;",
        "\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";",
        "\t\t\t\tENABLE_NS_ASSERTIONS = NO;",
        "\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;",
        "\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;",
        "\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;",
        "\t\t\t\tSDKROOT = macosx;",
        "\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;",
        "\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";",
        "\t\t\t\tSWIFT_VERSION = 6.0;",
        "\t\t\t};",
        "\t\t\tname = Release;",
        "\t\t};",
        f"\t\t{target_debug_cfg_id} /* Debug */ = {{",
        "\t\t\tisa = XCBuildConfiguration;",
        "\t\t\tbuildSettings = {",
        "\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;",
        "\t\t\t\tCODE_SIGN_IDENTITY = \"-\";",
        "\t\t\t\tCODE_SIGN_STYLE = Automatic;",
        "\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;",
        "\t\t\t\tGENERATE_INFOPLIST_FILE = NO;",
        "\t\t\t\tINFOPLIST_FILE = Resources/Info.plist;",
        "\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (",
        "\t\t\t\t\t\"$(inherited)\",",
        "\t\t\t\t\t\"@executable_path/../Frameworks\",",
        "\t\t\t\t);",
        "\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.hardcore.HardcoreAlarm;",
        "\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";",
        "\t\t\t\tSWIFT_VERSION = 6.0;",
        "\t\t\t};",
        "\t\t\tname = Debug;",
        "\t\t};",
        f"\t\t{target_release_cfg_id} /* Release */ = {{",
        "\t\t\tisa = XCBuildConfiguration;",
        "\t\t\tbuildSettings = {",
        "\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;",
        "\t\t\t\tCODE_SIGN_IDENTITY = \"-\";",
        "\t\t\t\tCODE_SIGN_STYLE = Automatic;",
        "\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;",
        "\t\t\t\tGENERATE_INFOPLIST_FILE = NO;",
        "\t\t\t\tINFOPLIST_FILE = Resources/Info.plist;",
        "\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (",
        "\t\t\t\t\t\"$(inherited)\",",
        "\t\t\t\t\t\"@executable_path/../Frameworks\",",
        "\t\t\t\t);",
        "\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.hardcore.HardcoreAlarm;",
        "\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";",
        "\t\t\t\tSWIFT_VERSION = 6.0;",
        "\t\t\t};",
        "\t\t\tname = Release;",
        "\t\t};",
        "/* End XCBuildConfiguration section */",
        "",
        "/* Begin XCConfigurationList section */",
        f"\t\t{proj_cfg_list_id} /* Build configuration list for PBXProject \"HardcoreAlarm\" */ = {{",
        "\t\t\tisa = XCConfigurationList;",
        "\t\t\tbuildConfigurations = (",
        f"\t\t\t\t{proj_debug_cfg_id} /* Debug */,",
        f"\t\t\t\t{proj_release_cfg_id} /* Release */,",
        "\t\t\t);",
        "\t\t\tdefaultConfigurationIsVisible = 0;",
        "\t\t\tdefaultConfigurationName = Release;",
        "\t\t};",
        f"\t\t{target_cfg_list_id} /* Build configuration list for PBXNativeTarget \"HardcoreAlarm\" */ = {{",
        "\t\t\tisa = XCConfigurationList;",
        "\t\t\tbuildConfigurations = (",
        f"\t\t\t\t{target_debug_cfg_id} /* Debug */,",
        f"\t\t\t\t{target_release_cfg_id} /* Release */,",
        "\t\t\t);",
        "\t\t\tdefaultConfigurationIsVisible = 0;",
        "\t\t\tdefaultConfigurationName = Release;",
        "\t\t};",
        "/* End XCConfigurationList section */",
        "\t};",
        f"\trootObject = {proj_id} /* Project object */;",
        "}"
    ])

    proj_dir = "HardcoreAlarm.xcodeproj"
    os.makedirs(proj_dir, exist_ok=True)
    pbx_path = os.path.join(proj_dir, "project.pbxproj")
    with open(pbx_path, "w") as f:
        f.write("\n".join(lines) + "\n")

    print(f"✅ Generated {pbx_path} with {len(sources)} source files!")

if __name__ == "__main__":
    main()
