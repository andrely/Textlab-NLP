require 'json'
require 'deep_merge'

##
# Global functions for managing the location of external components.

module TextlabNLP
  ##
  # Error type for malformed config files or values.
  class ConfigError < StandardError; end

  # Location of file containing config defaults
  CONFIG_DEFAULT_FN = 'lib/config_default.json'
  # Default location of file containing default config overrides.
  CONFIG_FN = 'lib/config.json'

  ##
  # Returns the absolute path to the project root directory.
  #
  # @return [String]
  def TextlabNLP.root_path()
    root = File.join(File.dirname(__FILE__), "..")
    root = File.absolute_path(root)

    return root
  end

  ##
  # Reads JSON based config file into a Hash instance.
  #
  # @param [IO] file JSON formatted config file with a single JSON object
  # @return [Hash] Hash based on the JSON config.
  # @raise [ConfigError] if unable to parse the config file.
  def TextlabNLP.read_config_file(file)
    config = JSON.parse(file.read(), {:symbolize_names => true})

    # file should contain a single object parsed into a Hash
    raise(ConfigError, "Failed to parse config file") if not config.kind_of?(Hash)

    config
  end

  ##
  # Reads and returns a Hash instance with the default config.
  #
  # @return [Hash]
  def TextlabNLP.default_config()
    File.open(File.join(root_path, CONFIG_DEFAULT_FN), 'r') { |f| read_config_file(f) }
  end

  ##
  # Read config from specified file or default config location and merge with default config
  # values.
  #
  # @param [IO, String] file Path to file or IO object with single JSON object with config values.
  # @return [Hash] Hash instance with config values.
  def TextlabNLP.config(file=nil)
    if file.nil?
      file = File.join(root_path, CONFIG_FN)

      # if the default overrides does not exist just return the defaults
      return default_config unless File.exists?(file)
    end

    if file.kind_of?(String)
      config = File.open(file, 'r') { |f| read_config_file(f) }
    else
      config = read_config_file(file)
    end

    # merge overrides with defaults
    config.deep_merge(default_config)
  end
end
