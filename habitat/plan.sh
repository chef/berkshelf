export HAB_BLDR_CHANNEL="base-2025"
export HAB_REFRESH_CHANNEL="base-2025"

# Resolve the repo root from this file's own location (BASH_SOURCE) rather
# than PLAN_CONTEXT. PLAN_CONTEXT is set by Habitat to the directory it
# started the build from, which is NOT necessarily the directory this file
# lives in -- e.g. when habitat/aarch64-linux/plan.sh sources this file,
# PLAN_CONTEXT is "habitat/aarch64-linux", not "habitat", which breaks any
# "${PLAN_CONTEXT}/.." reference used here. BASH_SOURCE[0] always points at
# this file, so it resolves correctly regardless of which plan sourced it.
BERKSHELF_PLAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BERKSHELF_REPO_ROOT="$(cd "${BERKSHELF_PLAN_DIR}/.." && pwd)"

pkg_name="berkshelf"
pkg_origin="chef"
ruby_pkg="core/ruby3_4"
pkg_maintainer="The Chef Maintainers <humans@chef.io>"
pkg_description="Manage Chef Infra cookbooks and cookbook dependencies."
pkg_license=('Apache-2.0')
pkg_deps=(${ruby_pkg} core/coreutils)
pkg_bin_dirs=(bin)
pkg_build_deps=(
  core/make
  core/gcc
)

do_setup_environment() {
  push_runtime_env GEM_PATH "${pkg_prefix}/vendor"

  set_runtime_env APPBUNDLER_ALLOW_RVM "true" # prevent appbundler from clearing out the carefully constructed runtime GEM_PATH
  set_runtime_env LANG "en_US.UTF-8"
  set_runtime_env LC_CTYPE "en_US.UTF-8"
}

do_prepare() {
  if [[ ! -f /usr/bin/env ]]; then
    ln -s "$(pkg_interpreter_for core/coreutils bin/env)" /usr/bin/env
  fi
}

pkg_version() {
  cat "$SRC_PATH/VERSION"
}

do_before() {
  update_pkg_version
}

do_unpack() {
  mkdir -pv "$HAB_CACHE_SRC_PATH/$pkg_dirname"
  cp -RT "$BERKSHELF_REPO_ROOT" "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
}

do_build() {
  export GEM_HOME="$pkg_prefix/vendor"

  build_line "Setting GEM_PATH=$GEM_HOME"
  export GEM_PATH="$GEM_HOME"
  bundle config --local without integration deploy maintenance test development profile
  bundle config --local jobs 4
  bundle config --local retry 5
  bundle config --local silence_root_warning 1
  bundle install
  gem build berkshelf.gemspec
}

do_install() {

  # Copy NOTICE to the package directory
  if [[ -f "${BERKSHELF_REPO_ROOT}/NOTICE" ]]; then
    build_line "Copying NOTICE to package directory"
    cp "${BERKSHELF_REPO_ROOT}/NOTICE" "$pkg_prefix/"
  else
    build_line "Warning: NOTICE not found at ${BERKSHELF_REPO_ROOT}/NOTICE"
  fi

  export GEM_HOME="$pkg_prefix/vendor"

  build_line "Setting GEM_PATH=$GEM_HOME"
  export GEM_PATH="$GEM_HOME"
  gem install berkshelf-*.gem --no-document

  build_line "** generating binstubs for berkshelf with precise version pins"
  "${pkg_prefix}/vendor/bin/appbundler" . "$pkg_prefix/bin" berkshelf

  build_line "** patching binstubs to allow running directly"
  for binstub in "${pkg_prefix}"/bin/*; do
    sed -i "/require \"rubygems\"/r ${BERKSHELF_REPO_ROOT}/binstub_patch.rb" "$binstub"
  done

  fix_interpreter "${pkg_prefix}/bin/*" "$ruby_pkg" bin/ruby

  rm -rf "${GEM_PATH:?}/cache/"
  rm -rf "${GEM_PATH:?}/bundler"
  rm -rf "${GEM_PATH:?}/doc"
}

do_after() {
  build_line "Removing .github directories from vendored gems..."
  find "$pkg_prefix/vendor/gems" -type d -name ".github" \
      | while read github_dir; do rm -rf "$github_dir"; done
}

do_strip() {
  return 0
}

do_end() {
  if [[ "$(readlink /usr/bin/env)" = "$(pkg_interpreter_for core/coreutils bin/env)" ]]; then
    build_line "Removing the symlink we created for '/usr/bin/env'"
    rm /usr/bin/env
  fi
}
