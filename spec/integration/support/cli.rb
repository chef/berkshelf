module Berkshelf
  module RSpec
    module Integration
      # Replaces the Cucumber step definitions. Each of these was a sentence
      # matched by a regular expression; here they are just methods.
      module CLI
        # -- Berksfile fixtures ------------------------------------------------

        def write_berksfile(content = "", path: ".")
          create_directory(path)
          write_file(File.join(path, "Berksfile"), <<~BERKSFILE)
            source 'http://127.0.0.1:#{BERKS_API_PORT}'

            #{content}
          BERKSFILE
        end

        def write_community_berksfile(content = "")
          write_file("Berksfile", <<~BERKSFILE)
            source '#{Berkshelf::Berksfile::DEFAULT_API_URL}'

            #{content}
          BERKSFILE
        end

        def write_lockfile(content, path: "Berksfile.lock")
          write_file(path, content)
        end

        # -- Cookbook fixtures -------------------------------------------------

        def create_cookbook(name)
          create_directory(name)
          write_file(File.join(name, "metadata.rb"), "name '#{name}'")
        end

        # Each entry is [name, version] or [name, version, license].
        def store_cookbooks(*cookbooks)
          cookbooks.each do |name, version, license|
            generate_cookbook(cookbook_store.storage_path, name, version, license: license)
          end
        end

        def store_cookbook_with_dependencies(name, version, dependencies)
          generate_cookbook(cookbook_store.storage_path, name, version, dependencies: dependencies)
        end

        # Each entry is [name, version, sha].
        def store_git_cookbooks(*cookbooks)
          cookbooks.each do |name, version, sha|
            folder = "#{name}-#{sha}"
            create_directory(folder)
            write_file(File.join(folder, "metadata.rb"), "name '#{name}'\nversion '#{version}'")
          end
        end

        def empty_cookbook_store
          Berkshelf::CookbookStore.instance.clean!
        end

        def compile_stored_metadata(name, version, keep_metadata_rb: false)
          cookbook_path = File.join(cookbook_store.storage_path, "#{name}-#{version}")
          Berkshelf::CachedCookbook.from_path(cookbook_path).compile_metadata
          metadata_file = File.join(cookbook_path, "metadata.rb")

          if keep_metadata_rb
            raise "internal error, fixture cookbook should have a metadata.rb" unless File.file?(metadata_file)
          elsif File.file?(metadata_file)
            File.unlink(metadata_file)
          end
        end

        # -- Running berks -----------------------------------------------------

        def berks(args, fail_on_error: false)
          reset_process_directory
          run_command_and_stop("berks #{args}", fail_on_error: fail_on_error)
        end

        def berks!(args)
          reset_process_directory
          run_command_and_stop("berks #{args}", fail_on_error: true)
        end

        # Aruba tracks its working directory logically and the in-process
        # launcher performs the real chdir itself, so between commands the
        # process is free to sit somewhere guaranteed to exist. Without this a
        # command that leaves the process on a directory Aruba later removes
        # makes the *next* command fail on getcwd, which reads as an unrelated
        # example failing at random.
        def reset_process_directory
          Dir.chdir(Berkshelf.root)
        end

        def berks_output
          last_command_started.output
        end

        def berks_stdout
          last_command_started.stdout
        end

        # -- Expectations ------------------------------------------------------

        def expect_output(*fragments)
          fragments.each { |fragment| expect(berks_output).to include(fragment) }
        end

        def expect_output_matching(*patterns)
          patterns.each { |pattern| expect(berks_output).to match(pattern) }
        end

        def expect_no_output(*fragments)
          fragments.each { |fragment| expect(berks_output).not_to include(fragment) }
        end

        # The Gherkin form was `the exit status should be "LockfileNotFound"`,
        # which resolved the constant by splitting the string on "::".
        def expect_exit_status(error_class)
          status = error_class.is_a?(Integer) ? error_class : error_class.status_code
          expect(last_command_started).to have_exit_status(status)
        end

        def expect_success
          expect(last_command_started).to be_successfully_executed
        end

        # Each entry is [name, version].
        def expect_stored_cookbooks(*cookbooks)
          cookbooks.each do |name, version|
            expect(cookbook_store.storage_path).to have_structure {
              directory "#{name}-#{version}" do
                file "metadata.{rb,json}" do
                  contains version
                end
              end
            }
          end
        end

        # Each entry is [name, version, sha].
        def expect_stored_git_cookbooks(*cookbooks)
          cookbooks.each do |name, version, sha|
            expect(cookbook_store.storage_path).to have_structure {
              directory "#{name}-#{sha}" do
                file "metadata.{rb,json}" do
                  contains version
                end
              end
            }
          end
        end

        def expect_no_stored_cookbooks(*cookbooks)
          cookbooks.each do |name, version|
            expect(cookbook_store.storage_path).not_to have_structure {
              directory "#{name}-#{version}"
            }
          end
        end

        def expect_file_contains(path, content)
          expect(read(path).join("\n")).to include(content)
        end

        def expect_file_does_not_contain(path, content)
          expect(read(path).join("\n")).not_to include(content)
        end

        def expect_files_in(directory, *files)
          check_file_presence(files.map { |file| File.join(directory, file) }, true)
        end

        def expect_no_files_in(directory, *files)
          check_file_presence(files.map { |file| File.join(directory, file) }, false)
        end

        def expect_vendored_cookbook(path, name, version)
          cookbook = Berkshelf::CachedCookbook.from_path(expand_path(path))
          expect(cookbook.version).to eq(version)
          expect(cookbook.cookbook_name).to eq(name)
        end

        def expect_archive_contents(path, expected)
          actual = Zlib::GzipReader.open(expand_path(path)) do |gz|
            Minitar::Input.each_entry(gz).map(&:full_name).join("\n")
          end
          expect(actual).to eql(expected)
        end

        # -- Chef server fixtures ----------------------------------------------

        # Each entry is [name, version] or [name, version, "dep >= 1.0, other ~> 2.0"].
        def chef_server_has_cookbooks(*cookbooks)
          cookbooks.each do |name, version, dependencies|
            metadata = ["name '#{name}'", "version '#{version}'"]
            dependencies.to_s.split(",").map { |d| d.strip.split(" ", 2) }.each do |dep_name, constraint|
              metadata << "depends '#{dep_name}', '#{constraint}'"
            end
            chef_cookbook(name, { "metadata.rb" => metadata.join("\n") })
          end
        end

        def chef_server_has_frozen_cookbooks(*cookbooks)
          cookbooks.each do |name, version|
            chef_cookbook(name, { "metadata.rb" => "version '#{version}'", frozen: true })
          end
        end

        def chef_server_has_environment(name)
          chef_environment(name, { "description" => "This is an environment" })
        end

        def chef_server_has_no_environment(name)
          key = ["organizations", "chef", "environments", name]
          chef_server.data_store.delete(key) if chef_server.data_store.exists?(key)
        end

        def expect_chef_server_cookbooks(*cookbooks)
          list = chef_cookbooks
          cookbooks.each do |name, version|
            expect(list.keys).to include(name)
            expect(list[name]).to include(version) unless version.nil?
          end
        end

        def expect_no_chef_server_cookbooks(*cookbooks)
          list = chef_cookbooks
          cookbooks.each do |name, version|
            if version.nil?
              expect(list.keys).not_to include(name)
            else
              expect(list[name] || []).not_to include(version)
            end
          end
        end

        def expect_environment_locks(environment, locks)
          actual = chef_environment_locks(environment)
          locks.each { |cookbook, version| expect(actual[cookbook]).to eq(version) }
        end

        # -- Berkshelf config --------------------------------------------------

        def existing_berkshelf_config
          path = Tempfile.new("berkshelf").path
          config = Berkshelf::Config.new(path)
          config.save
          Berkshelf.config = config
          ENV["BERKSHELF_CONFIG"] = path
          set_environment_variable "BERKSHELF_CONFIG", path
          path
        end

        def write_berkshelf_config(contents)
          path = Berkshelf.config.path
          FileUtils.mkdir_p(Pathname.new(path).dirname.to_s)
          File.write(path, contents)
          Berkshelf.config = Berkshelf::Config.from_file(path)
        end

        def remove_berkshelf_config
          FileUtils.rm_f(ENV["BERKSHELF_CONFIG"])
        end

        def expect_berkshelf_config(values)
          Berkshelf.config.reload
          check_file_presence([Berkshelf.config.path], true)
          values.each { |key, value| expect(Berkshelf.config[key]).to eq(value) }
        end

        def expect_berkshelf_config_at(path, values)
          check_file_presence([path], true)
          config = Berkshelf::Config.from_file(expand_path(path))
          values.each { |key, value| expect(config[key]).to eq(value) }
        end

        # -- JSON output -------------------------------------------------------

        # The formatter emits one JSON document per command, so comparison is on
        # parsed data with keys deeply sorted rather than on the raw string.
        def expect_output_json(expected)
          actual = JSON.parse(all_commands.map(&:output).join("\n"))
          expect(deep_sort_keys(actual)).to eq(deep_sort_keys(JSON.parse(expected)))
        end

        def deep_sort_keys(value)
          case value
          when Hash then value.keys.sort.to_h { |key| [key, deep_sort_keys(value[key])] }
          when Array then value.map { |element| deep_sort_keys(element) }
          else value
          end
        end

        # -- Environment -------------------------------------------------------

        # Artifactory has no local stand-in, so those examples only run when a
        # real server is configured.
        def artifactory_or_skip
          url = ENV["TEST_BERKSHELF_ARTIFACTORY"]
          skip("TEST_BERKSHELF_ARTIFACTORY is not set") unless url
          url
        end

        def dep_selector_or_skip
          Gem::Specification.find_by_name("dep_selector")
        rescue Gem::MissingSpecError
          skip("dep_selector gem is not installed (optional dependency)")
        end
      end
    end
  end
end
