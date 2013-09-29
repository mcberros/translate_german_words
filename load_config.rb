# encoding: UTF-8
require 'yaml'

class LoadConfig

  attr_reader :app_config

  def initialize(file = 'config.yml')
    @config_file = file
  end

  def read_config
    raw_config = File.read(@config_file)
    @app_config = YAML.load(raw_config)
  end
end
