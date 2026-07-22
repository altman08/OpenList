set -e
appName="openlist"
builtAt="$(date +'%F %T %z')"
gitAuthor="The OpenList Projects Contributors <noreply@openlist.team>"
gitCommit=$(git log --pretty=format:"%h" -1)

# Set frontend repository, default to OpenListTeam/OpenList-Frontend
frontendRepo="${FRONTEND_REPO:-OpenListTeam/OpenList-Frontend}"

githubAuthArgs=""
if [ -n "$GITHUB_TOKEN" ]; then
  githubAuthArgs="--header \"Authorization: Bearer $GITHUB_TOKEN\""
fi

# Check for lite parameter
useLite=false
if [[ "$*" == *"lite"* ]]; then
  useLite=true
fi

if [ "$1" = "dev" ]; then
  version="dev"
  webVersion="rolling"
elif [ "$1" = "beta" ]; then
  version="beta"
  webVersion="rolling"
else
  git tag -d beta || true
  # Always true if there's no tag
  version=$(git describe --abbrev=0 --tags 2>/dev/null || echo "v0.0.0")
  webVersion=$(eval "curl -fsSL --max-time 2 $githubAuthArgs \"https://api.github.com/repos/$frontendRepo/releases/latest\"" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
fi

echo "backend version: $version"
echo "frontend version: $webVersion"
if [ "$useLite" = true ]; then
  echo "using lite frontend"
else
  echo "using standard frontend"
fi

ldflags="\
-w -s \
-X 'github.com/OpenListTeam/OpenList/v4/internal/conf.BuiltAt=$builtAt' \
-X 'github.com/OpenListTeam/OpenList/v4/internal/conf.GitAuthor=$gitAuthor' \
-X 'github.com/OpenListTeam/OpenList/v4/internal/conf.GitCommit=$gitCommit' \
-X 'github.com/OpenListTeam/OpenList/v4/internal/conf.Version=$version' \
-X 'github.com/OpenListTeam/OpenList/v4/internal/conf.WebVersion=$webVersion' \
"

FetchWebRolling() {
  pre_release_json=$(eval "curl -fsSL --max-time 2 $githubAuthArgs -H \"Accept: application/vnd.github.v3+json\" \"https://api.github.com/repos/$frontendRepo/releases/tags/rolling\"")
  pre_release_assets=$(echo "$pre_release_json" | jq -r '.assets[].browser_download_url')
  
  # There is no lite for rolling
  pre_release_tar_url=$(echo "$pre_release_assets" | grep "openlist-frontend-dist" | grep -v "lite" | grep "\.tar\.gz$")

  curl -fsSL "$pre_release_tar_url" -o dist.tar.gz
  rm -rf public/dist && mkdir -p public/dist
  tar -zxvf dist.tar.gz -C public/dist
  rm -rf dist.tar.gz
}

FetchWebRelease() {
  release_json=$(eval "curl -fsSL --max-time 2 $githubAuthArgs -H \"Accept: application/vnd.github.v3+json\" \"https://api.github.com/repos/$frontendRepo/releases/latest\"")
  release_assets=$(echo "$release_json" | jq -r '.assets[].browser_download_url')
  
  if [ "$useLite" = true ]; then
    release_tar_url=$(echo "$release_assets" | grep "openlist-frontend-dist-lite" | grep "\.tar\.gz$")
  else
    release_tar_url=$(echo "$release_assets" | grep "openlist-frontend-dist" | grep -v "lite" | grep "\.tar\.gz$")
  fi
  
  curl -fsSL "$release_tar_url" -o dist.tar.gz
  rm -rf public/dist && mkdir -p public/dist
  tar -zxvf dist.tar.gz -C public/dist
  rm -rf dist.tar.gz
}

BuildDev() {
  mkdir -p "dist"
  xgo -targets=linux/arm64,linux/arm-7 -out "$appName" -ldflags="$ldflags" -tags=jsoniter .
  mv "$appName"-* dist
  cd dist
  find . -type f -print0 | xargs -0 md5sum >md5.txt
  cat md5.txt
}

BuildRelease() {
  mkdir -p "build"
  xgo -targets=linux/arm64,linux/arm-7 -out "$appName" -ldflags="$ldflags" -tags=jsoniter .
  mv "$appName"-* build
}

MakeRelease() {
  cd build
  if [ -d compress ]; then
    rm -rv compress
  fi
  mkdir compress
  
  # Add -lite suffix if useLite is true
  liteSuffix=""
  if [ "$useLite" = true ]; then
    liteSuffix="-lite"
  fi
  
  for i in $(find . -type f -name "$appName-linux-*"); do
    cp "$i" "$appName"
    tar -czvf compress/"$i$liteSuffix".tar.gz "$appName"
    rm -f "$appName"
  done
  cd compress
  
  # Handle MD5 filename - add -lite suffix only if not already present
  md5FileName="$1"
  if [ "$useLite" = true ] && [[ "$1" != *"-lite.txt" ]]; then
    md5FileName=$(echo "$1" | sed 's/\.txt$/-lite.txt/')
  fi
  
  find . -type f -print0 | xargs -0 md5sum >"$md5FileName"
  cat "$md5FileName"
  cd ../..
}

# Parse parameters to handle lite parameter position flexibility
buildType=""
otherParam=""

for arg in "$@"; do
  case $arg in
    dev|beta|release|zip)
      if [ -z "$buildType" ]; then
        buildType="$arg"
      fi
      ;;
    web)
      dockerType="web"
      ;;
    lite)
      # lite parameter is already handled above
      ;;
    *)
      if [ -z "$otherParam" ]; then
        otherParam="$arg"
      fi
      ;;
  esac
done

if [ "$buildType" = "dev" ]; then
  FetchWebRolling
  if [ "$dockerType" = "web" ]; then
    echo "web only"
  else
    BuildDev
  fi
elif [ "$buildType" = "release" -o "$buildType" = "beta" ]; then
  if [ "$buildType" = "beta" ]; then
    FetchWebRolling
  else
    FetchWebRelease
  fi
  if [ "$dockerType" = "web" ]; then
    echo "web only"
  else
    BuildRelease
    if [ "$useLite" = true ]; then
      MakeRelease "md5-lite.txt"
    else
      MakeRelease "md5.txt"
    fi
  fi
elif [ "$buildType" = "zip" ]; then
  if [ -n "$otherParam" ]; then
    if [ "$useLite" = true ]; then
      MakeRelease "$otherParam-lite.txt"
    else
      MakeRelease "$otherParam.txt"
    fi
  else
    if [ "$useLite" = true ]; then
      MakeRelease "md5-lite.txt"
    else
      MakeRelease "md5.txt"
    fi
  fi
else
  echo -e "Parameter error"
  echo -e "Usage: $0 {dev|beta|release|zip} [web] [lite] [other_params]"
  echo -e "Only linux/arm64 and linux/arm-7 targets are built."
  echo -e "Examples:"
  echo -e "  $0 dev"
  echo -e "  $0 dev lite"
  echo -e "  $0 dev web"
  echo -e "  $0 release"
  echo -e "  $0 release lite"
fi
