-- the script was written several years ago, now darktable has a native batch mode

function getOsName()
  local file = io.open("C:/Windows/System32/winver.exe", "r")

  if file then
    file:close()

    return "windows"
  end

  file = io.open("/usr/bin/sw_vers", "r")

  if file then
    file:close()

    return "macos"
  end

  file = io.open("/etc/freebsd-version", "r")

  if file then
    file:close()

    return "freebsd"
  end

  file = io.open("/system/build.prop", "r")

  if file then
    file:close()

    return "android"
  end

  return "unix"
end

function getDynLibExt()
  local osName = getOsName()
  local ext = "so"

  if osName == "windows" then
    ext = "dll"
  elseif osName == "macos" then
    ext = "dylib"
  end

  return ext
end

local dynLibExt = getDynLibExt()

package.path = package.path .. ";libs/?.lua"
package.cpath = package.cpath .. ";libs/?." .. dynLibExt

local lfs = require("lfs")

-- paths should not contain spaces
-- paths should be absolute
local darktableCliBinPath = "C:/Users/zar-s/darktable-cli"
local inDirPath = "C:/Users/zar-s/projects2/darktableCliBatch/photos/"
local outDirPath =
  "C:/Users/zar-s/projects2/darktableCliBatch/photos/photosEdited/"
local inFileExts = { "png", "jpg", "jpeg" }
local xmpFilePath =
  "C:/Users/zar-s/projects2/darktableCliBatch/photos/effects.xmp"

function tableContains(t, needle)
  for _, v in ipairs(t) do
    if v == needle then
      return true
    end
  end

  return false
end

function normalizePath(path)
  local normPath = string.gsub(path, "/+", "/")
  normPath = string.gsub(normPath, "\\+", "/")
  normPath = string.gsub(normPath, "/$", "")

  return normPath
end

function getFileExt(path)
  local ext = string.match(path, "^.+%.(.+)$")
  ext = string.lower(ext)

  return ext
end

darktableCliBinPath = normalizePath(darktableCliBinPath)
inDirPath = normalizePath(inDirPath)
outDirPath = normalizePath(outDirPath)
xmpFilePath = normalizePath(xmpFilePath)

if inDirPath == outDirPath then
  print("error: input and output directories should not match")
  os.exit(1)
end

function processFile(dirPath)
  do
    for filePath in lfs.dir(dirPath) do
      if filePath ~= "." and filePath ~= ".." then
        local absFilePath = dirPath .. "/" .. filePath
        local fileAttrs = lfs.attributes(absFilePath)

        if fileAttrs.mode == "directory" then
          if absFilePath ~= outDirPath then
            processFile(absFilePath)
          end
        else
          local fileExt = getFileExt(absFilePath)

          if tableContains(inFileExts, fileExt) then
            local outFilePath = outDirPath .. "/" .. filePath
            local cmd = string.format(
              '%s "%s" "%s" "%s"',
              darktableCliBinPath,
              absFilePath,
              xmpFilePath,
              outFilePath
            )

            os.execute(cmd)
          end
        end
      end
    end
  end
end

processFile(inDirPath)
