require 'openssl'

module KeyGenerator
  def self.generate_key(file_path)
    full_path = File.expand_path(file_path)
    unless File.exist?(full_path)
      key = OpenSSL::PKey::RSA.new(2048)
      File.write(full_path, key.to_pem)
    end
  end
end