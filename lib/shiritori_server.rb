require 'shiritori_server/version'
require 'shiritori_server/error'
require 'shiritori_server/search_method'
require 'shiritori_server/shiritori_server'
require 'shiritori_server/convert'

module ShiritoriServer
  def self.env
    :production
  end
end
