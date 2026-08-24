require "spec_helper"

module Berkshelf
  describe Downloader do
    let(:berksfile) do
      double(Berksfile,
        lockfile: lockfile,
        dependencies: [])
    end

    let(:lockfile) do
      double(Lockfile,
        graph: graph)
    end

    let(:graph) { double(Lockfile::Graph, locks: {}) }
    let(:self_signed_crt_path) { File.join(BERKS_SPEC_DATA, "trusted_certs") }
    let(:self_signed_crt) { OpenSSL::X509::Certificate.new(File.read("#{self_signed_crt_path}/example.crt")) }
    let(:cert_store) { OpenSSL::X509::Store.new.add_cert(self_signed_crt) }
    let(:ssl_policy) { double(SSLPolicy, store: cert_store) }

    subject { described_class.new(berksfile) }

    describe "#download" do
      skip
    end

    describe "#try_download" do
      let(:remote_cookbook) { double("remote-cookbook") }
      let(:source) do
        source = double("source")
        allow(source).to receive(:cookbook) { remote_cookbook }
        source
      end
      let(:name) { "fake" }
      let(:version) { "1.0.0" }

      it "supports the 'opscode' location type" do
        allow(source).to receive(:type) { :supermarket }
        allow(source).to receive(:options) { { ssl: {} } }
        allow(remote_cookbook).to receive(:location_type) { :opscode }
        allow(remote_cookbook).to receive(:location_path) { "http://api.opscode.com" }
        rest = double("community-rest")
        expect(CommunityREST).to receive(:new).with("http://api.opscode.com", { ssl: {} }) { rest }
        expect(rest).to receive(:download).with(name, version)
        subject.try_download(source, name, version)
      end

      it "supports the 'supermarket' location type" do
        allow(source).to receive(:type) { :supermarket }
        allow(source).to receive(:options) { { ssl: {} } }
        allow(remote_cookbook).to receive(:location_type) { :supermarket }
        allow(remote_cookbook).to receive(:location_path) { "http://api.supermarket.com" }
        rest = double("community-rest")
        expect(CommunityREST).to receive(:new).with("http://api.supermarket.com", { ssl: {} }) { rest }
        expect(rest).to receive(:download).with(name, version)
        subject.try_download(source, name, version)
      end

      context "supports location paths" do
        before(:each) do
          allow(source).to receive(:type) { :supermarket }
          allow(source).to receive(:options) { { ssl: {} } }
          allow(source).to receive(:uri_string).and_return("http://localhost:8081/repository/chef-proxy")
          allow(remote_cookbook).to receive(:location_type) { :opscode }
        end

        let(:rest) { double("community-rest") }

        it "that are relative and prepends the source URI for the download" do
          allow(remote_cookbook).to receive(:location_path) { "/api/v1" }
          expect(CommunityREST).to receive(:new).with("http://localhost:8081/repository/chef-proxy/api/v1", { ssl: {} }) { rest }
          expect(rest).to receive(:download).with(name, version)
          subject.try_download(source, name, version)
        end

        it "that are absolute and uses the given absolute URI" do
          allow(remote_cookbook).to receive(:location_path) { "http://localhost:8081/repository/chef-proxy/api/v1" }
          expect(CommunityREST).to receive(:new).with("http://localhost:8081/repository/chef-proxy/api/v1", { ssl: {} }) { rest }
          expect(rest).to receive(:download).with(name, version)
          subject.try_download(source, name, version)
        end
      end

      context "with an artifactory source" do
        it "supports the 'opscode' location type" do
          allow(source).to receive(:type) { :artifactory }
          allow(source).to receive(:options) { { api_key: "secret", ssl: {} } }
          allow(remote_cookbook).to receive(:location_type) { :opscode }
          allow(remote_cookbook).to receive(:location_path) { "http://artifactory/" }
          rest = double("community-rest")
          expect(CommunityREST).to receive(:new).with("http://artifactory/", { ssl: {}, headers: { "X-Jfrog-Art-Api" => "secret" } }) { rest }
          expect(rest).to receive(:download).with(name, version)
          subject.try_download(source, name, version)
        end

        it "supports the 'supermarket' location type" do
          allow(source).to receive(:type) { :artifactory }
          allow(source).to receive(:options) { { api_key: "secret", ssl: {} } }
          allow(remote_cookbook).to receive(:location_type) { :supermarket }
          allow(remote_cookbook).to receive(:location_path) { "http://artifactory/" }
          rest = double("community-rest")
          expect(CommunityREST).to receive(:new).with("http://artifactory/", { ssl: {}, headers: { "X-Jfrog-Art-Api" => "secret" } }) { rest }
          expect(rest).to receive(:download).with(name, version)
          subject.try_download(source, name, version)
        end
      end

      describe "chef_server location type" do
        let(:chef_server_url) { "http://configured-chef-server/" }
        let(:ridley_client) do
          instance_double(Berkshelf::RidleyCompat)
        end
        let(:chef_config) do
          double(Berkshelf::ChefConfigCompat,
            node_name: "fake-client",
            client_key: "client-key",
            chef_server_url: chef_server_url,
            validation_client_name: "validator",
            validation_key: "validator.pem",
            artifactory_api_key: "secret",
            cookbook_copyright: "user",
            cookbook_email: "user@example.com",
            cookbook_license: "apachev2",
            trusted_certs_dir: self_signed_crt_path)
        end

        let(:berkshelf_config) do
          double(Config,
            ssl:  double(verify: true),
            chef: chef_config)
        end

        before do
          allow(Berkshelf).to receive(:config).and_return(berkshelf_config)
          allow(subject).to receive(:ssl_policy).and_return(ssl_policy)
          allow(remote_cookbook).to receive(:location_type) { :chef_server }
          allow(remote_cookbook).to receive(:location_path) { chef_server_url }
          allow(source).to receive(:options) { { read_timeout: 30, open_timeout: 3, ssl: { verify: true, cert_store: cert_store } } }
        end

        it "uses the berkshelf config and provides a custom cert_store" do
          credentials = {
            server_url: chef_server_url,
            client_name: chef_config.node_name,
            client_key: chef_config.client_key,
            ssl: {
              verify: berkshelf_config.ssl.verify,
              cert_store: cert_store,
            },
          }
          expect(Berkshelf::RidleyCompat).to receive(:new_client).with(credentials) { ridley_client }
          subject.try_download(source, name, version)
        end

        context "with a source option for client_name" do
          before do
            allow(source).to receive(:options) { { client_name: "other-client", read_timeout: 30, open_timeout: 3, ssl: { verify: true, cert_store: cert_store } } }
          end
          it "uses the override" do
            credentials = {
              server_url: chef_server_url,
              client_name: "other-client",
              client_key: chef_config.client_key,
              ssl: {
                verify: berkshelf_config.ssl.verify,
                cert_store: cert_store,
              },
            }
            expect(Berkshelf::RidleyCompat).to receive(:new_client).with(credentials) { ridley_client }
            subject.try_download(source, name, version)
          end
        end

        context "with a source option for client_key" do
          before do
            allow(source).to receive(:options) { { client_key: "other-key", read_timeout: 30, open_timeout: 3, ssl: { verify: true, cert_store: cert_store } } }
          end
          it "uses the override" do
            credentials = {
              server_url: chef_server_url,
              client_name: chef_config.node_name,
              client_key: "other-key",
              ssl: {
                verify: berkshelf_config.ssl.verify,
                cert_store: cert_store,
              },
            }
            expect(Berkshelf::RidleyCompat).to receive(:new_client).with(credentials) { ridley_client }
            subject.try_download(source, name, version)
          end
        end
      end

      context "the 'github' location type" do
        # These exercise the branch that picks which configured GitHub endpoint a
        # cookbook is fetched through, and the two separate places SSL
        # verification is derived. Sending the wrong endpoint's token, or
        # defaulting verification off, are both silent failures.
        let(:dotcom_config) { { "access_token" => "dotcom-token" } }
        let(:enterprise_config) do
          {
            "api_endpoint" => "https://github.example.com/api/v3",
            "web_endpoint" => "https://github.example.com",
            "access_token" => "enterprise-token",
          }
        end

        # Enterprise first, so a passing test proves the endpoint is selected by
        # matching rather than by happening to be first in the list.
        let(:github_config) { [enterprise_config, dotcom_config] }

        let(:octokit_client) { double("octokit-client") }

        # Stop after the archive request so these examples stay on the endpoint
        # and SSL logic rather than tarball extraction. A null double is not a
        # Net::HTTPSuccess, so try_download returns nil.
        let(:http) { double("net-http").as_null_object }

        before do
          require "octokit"
          allow(remote_cookbook).to receive(:location_type) { :github }
          allow(Berkshelf::Config).to receive(:instance) { double("config", github: github_config) }
          allow(Octokit::Client).to receive(:new) { octokit_client }
          allow(octokit_client).to receive(:archive_link) { "https://codeload.github.com/chef/fake/tar.gz/v1.0.0" }
          allow(Net::HTTP).to receive(:new) { http }
        end

        context "when the cookbook lives on github.com" do
          before { allow(remote_cookbook).to receive(:location_path) { "https://github.com/chef/fake" } }

          it "authenticates with the entry that has no web_endpoint" do
            expect(Octokit::Client).to receive(:new)
              .with(hash_including(access_token: "dotcom-token")) { octokit_client }
            subject.try_download(source, name, version)
          end

          it "does not send an enterprise api_endpoint to github.com" do
            expect(Octokit::Client).to receive(:new)
              .with(hash_including(api_endpoint: nil, web_endpoint: nil)) { octokit_client }
            subject.try_download(source, name, version)
          end

          it "requests the archive for the v-prefixed version tag" do
            expect(octokit_client).to receive(:archive_link)
              .with("chef/fake", ref: "v1.0.0") { "https://codeload.github.com/chef/fake/tar.gz/v1.0.0" }
            subject.try_download(source, name, version)
          end

          it "returns nil when the token is rejected" do
            allow(octokit_client).to receive(:archive_link).and_raise(Octokit::Unauthorized)
            expect(subject.try_download(source, name, version)).to be_nil
          end

          it "returns nil when the archive request is not successful" do
            expect(subject.try_download(source, name, version)).to be_nil
          end
        end

        context "when the cookbook lives on a GitHub Enterprise host" do
          before { allow(remote_cookbook).to receive(:location_path) { "https://github.example.com/chef/fake" } }

          it "authenticates with the entry whose web_endpoint matches the host" do
            expect(Octokit::Client).to receive(:new).with(
              hash_including(
                access_token: "enterprise-token",
                api_endpoint: "https://github.example.com/api/v3",
                web_endpoint: "https://github.example.com"
              )
            ) { octokit_client }
            subject.try_download(source, name, version)
          end

          it "raises ConfigurationError naming the host when nothing matches" do
            allow(remote_cookbook).to receive(:location_path) { "https://ghe.unconfigured.test/chef/fake" }
            expect { subject.try_download(source, name, version) }
              .to raise_error(Berkshelf::ConfigurationError, /ghe\.unconfigured\.test/)
          end
        end

        context "SSL verification" do
          before { allow(remote_cookbook).to receive(:location_path) { "https://github.com/chef/fake" } }

          context "when ssl_verify is not configured" do
            it "verifies the octokit connection" do
              expect(Octokit::Client).to receive(:new)
                .with(hash_including(connection_options: { ssl: { verify: true } })) { octokit_client }
              subject.try_download(source, name, version)
            end

            it "verifies the archive download" do
              subject.try_download(source, name, version)
              expect(http).to have_received(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
            end
          end

          context "when ssl_verify is disabled" do
            let(:dotcom_config) { { "access_token" => "dotcom-token", "ssl_verify" => false } }

            it "does not verify the octokit connection" do
              expect(Octokit::Client).to receive(:new)
                .with(hash_including(connection_options: { ssl: { verify: false } })) { octokit_client }
              subject.try_download(source, name, version)
            end

            it "does not verify the archive download" do
              subject.try_download(source, name, version)
              # nosemgrep: ruby.lang.security.ssl-mode-no-verify -- asserts the
              # opt-out reaches Net::HTTP; it does not disable verification.
              expect(http).to have_received(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
            end
          end
        end
      end

      it "supports the 'file_store' location type" do
        skip
      end
    end
  end
end
