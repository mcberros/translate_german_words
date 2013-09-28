# encoding: UTF-8
require 'yaml'

class LoadConfig

  attr_accessor :config_file

  def initialize(file = 'config.yml')
    @config_file = file
  end

  def read_config
    raw_config = File.read(@config_file)
    app_config = YAML.load(raw_config)
  end
end