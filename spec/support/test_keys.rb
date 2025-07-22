require "openssl"
require "fileutils"

module TestKeyHelper
  def self.generate_rsa_key(path)
    return if File.exist?(path) # Don't regenerate if already exists

    key = OpenSSL::PKey::RSA.new(2048)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, key.to_pem)
  end
end

# Generate the test keys
TestKeyHelper.generate_rsa_key("spec/config/berkshelf.pem")
TestKeyHelper.generate_rsa_key("spec/config/validator.pem")
