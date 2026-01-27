-- the script was written several years ago, now darktable has a native batch mode

function fileExists(path)
  local file = io.open(path)

  if file then
    file:close()

    return true
  end

  return false
end

function getOsName()
  local osName = "unix"
  local filePath = "C:/Windows/System32/winver.exe"

  if fileExists(filePath) then
    osName = "windows"

    return osName
  end

  filePath = "/usr/bin/sw_vers"

  if fileExists(filePath) then
    osName = "macos"

    return osName
  end

  filePath = "/etc/freebsd-version"

  if fileExists(filePath) then
    osName = "freebsd"

    return osName
  end

  filePath = "/system/build.prop"

  if fileExists(filePath) then
    osName = "android"

    return osName
  end

  return osName
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

function tableContains(tbl, needle)
  for _, v in ipairs(tbl) do
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
  for filePath in lfs.dir(dirPath) do
    if filePath ~= "." and filePath ~= ".." then
      local absFilePath = dirPath .. "/" .. filePath

      if lfs.attributes(absFilePath, "mode") == "directory" then
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

processFile(inDirPath)
